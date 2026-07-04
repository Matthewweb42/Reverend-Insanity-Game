"""Card combat: aperture-as-deck (DEC-039) + attainment gate (DEC-026) + synergy.

Deck lifecycle (docs/Systems/Cards.md):
  aperture -> shuffled draw pile -> hand -> discard -> reshuffle when empty.

Attainment gate: your attainment in a path caps how many Gu of that path you may
play per turn. A focused deck goes deep in 1-2 paths and plays its whole engine;
a grab-bag deck is throttled to ~1 card per path. This is what makes committing
to a path the core deck-building decision.

Effects are data (docs/Systems/Cards.md 'Effect Model'). The resolver below is
the single place that interprets them.
"""

from __future__ import annotations

from dataclasses import dataclass, field
import random

from cards import Card, KillerMove
from paths import path_tag


# --- Tunable combat/deck constants (docs/Systems/Cards.md) ------------------
HAND_SIZE = 5
DRAW_PER_TURN = 1
HAND_MAX = 8
# Essence regenerated at the start of each of your turns. Without this, a fixed
# pool with no regen lets long fights stall out once a side runs dry.
ESSENCE_REGEN = 12
# Hard cap on combat length; a fight this long is a stalemate -> the aggressor
# (more current HP%) is declared the winner, breaking infinite loops.
MAX_TURNS = 60

# Attainment tiers -> Gu of that path playable per turn (Combat.md / DEC-026).
ATTAINMENT_ACTIVATIONS = {
    "Ordinary": 1,
    "Adept": 2,
    "Master": 3,
    "Quasi-Grandmaster": 5,
    "Grandmaster": 6,
}
# Killer moves require at least this attainment in the move's path.
KILLER_MOVE_MIN = "Master"
_TIER_ORDER = list(ATTAINMENT_ACTIVATIONS.keys())


def tier_at_least(have: str, need: str) -> bool:
    try:
        return _TIER_ORDER.index(have) >= _TIER_ORDER.index(need)
    except ValueError:
        return False


@dataclass
class Status:
    stacks: int
    duration: int


@dataclass
class Combatant:
    name: str
    max_hp: int
    hp: int
    essence: int
    max_essence: int
    is_player: bool = False
    shield: int = 0
    shield_turns: int = 0
    statuses: dict[str, Status] = field(default_factory=dict)
    # Per-path attainment ("Ordinary".."Grandmaster"); missing => Ordinary.
    attainment: dict[str, str] = field(default_factory=dict)
    draw_pile: list[Card] = field(default_factory=list)
    hand: list[Card] = field(default_factory=list)
    discard: list[Card] = field(default_factory=list)
    # Per-turn bookkeeping
    path_plays: dict[str, int] = field(default_factory=dict)  # path -> plays used this turn
    attacks_this_turn: int = 0

    @property
    def alive(self) -> bool:
        return self.hp > 0

    def hp_pct(self) -> float:
        return 100.0 * self.hp / self.max_hp if self.max_hp else 0.0

    def path_budget(self, path: str) -> int:
        tier = self.attainment.get(path, "Ordinary")
        return ATTAINMENT_ACTIVATIONS.get(tier, 1)

    def path_used(self, path: str) -> int:
        return self.path_plays.get(path, 0)

    def has_status(self, name: str) -> bool:
        s = self.statuses.get(name)
        return bool(s and s.stacks > 0)

    def is_debuffed(self) -> bool:
        return any(self.has_status(s) for s in
                   ("poison", "bleed", "vulnerable", "marked"))

    def reset_turn(self) -> None:
        self.path_plays = {}
        self.attacks_this_turn = 0


class Combat:
    def __init__(self, player: Combatant, enemy: Combatant,
                 rng: random.Random | None = None, log=print):
        self.player = player
        self.enemy = enemy
        self.rng = rng or random.Random()
        self.log = log
        self.turn = 0
        self.result: str | None = None

    # -- deck operations ----------------------------------------------------
    def shuffle_deck(self, c: Combatant, cards: list[Card]) -> None:
        c.draw_pile = [card.copy() for card in cards]
        c.hand = []
        c.discard = []
        self.rng.shuffle(c.draw_pile)

    def draw(self, c: Combatant, n: int) -> list[Card]:
        drawn: list[Card] = []
        for _ in range(n):
            if len(c.hand) >= HAND_MAX:
                break
            if not c.draw_pile:
                if not c.discard:
                    break
                c.draw_pile = c.discard
                c.discard = []
                self.rng.shuffle(c.draw_pile)
            c.hand.append(c.draw_pile.pop())
            drawn.append(c.hand[-1])
        return drawn

    # -- status / damage helpers -------------------------------------------
    def _apply_shield(self, c: Combatant, amount: int, duration: int) -> None:
        c.shield = max(c.shield, amount)
        c.shield_turns = max(c.shield_turns, duration)

    def _add_shield(self, c: Combatant, amount: int, duration: int) -> None:
        c.shield += amount
        c.shield_turns = max(c.shield_turns, duration)

    def _deal_damage(self, attacker: Combatant, target: Combatant,
                     amount: int, source_name: str,
                     pierce: bool = False, lifesteal: float = 0.0) -> int:
        # Attacker damage buffs
        if attacker.has_status("strengthened"):
            amount = int(amount * 1.25)
        # Target damage-taken modifiers
        if target.has_status("vulnerable"):
            amount = int(amount * 1.25)

        # Evasion: target's next incoming attack likely misses.
        if target.has_status("evasion"):
            del target.statuses["evasion"]
            if self.rng.random() < 0.75:
                self.log(f"    {target.name} evades the attack!")
                return 0

        remaining = amount
        reflected = 0
        if not pierce and target.shield > 0:
            absorbed = min(target.shield, remaining)
            target.shield -= absorbed
            remaining -= absorbed
            if absorbed:
                self.log(f"    {target.name}'s shield absorbs {absorbed}.")
                if target.has_status("reflect"):
                    del target.statuses["reflect"]
                    reflected = absorbed // 2

        target.hp = max(0, target.hp - remaining)
        self.log(f"    {source_name} deals {remaining} to {target.name} "
                 f"({target.hp}/{target.max_hp}).")

        if lifesteal and remaining > 0:
            healed = int(remaining * lifesteal)
            before = attacker.hp
            attacker.hp = min(attacker.max_hp, attacker.hp + healed)
            if attacker.hp > before:
                self.log(f"    {attacker.name} drains {attacker.hp - before} HP.")
        # Lifelink status (Blood Bond)
        if attacker.has_status("lifelink") and remaining > 0:
            healed = int(remaining * 0.4)
            attacker.hp = min(attacker.max_hp, attacker.hp + healed)
            if healed:
                self.log(f"    {attacker.name} lifelinks {healed} HP.")

        if reflected:
            self.log(f"    {target.name}'s barrier reflects {reflected}!")
            self._deal_damage(target, attacker, reflected, "Reflected light")
        return remaining

    def _apply_status(self, tgt: Combatant, status: str, stacks: int, duration: int) -> None:
        st = tgt.statuses.get(status)
        if st:
            st.stacks += stacks
            st.duration = max(st.duration, duration)
        else:
            tgt.statuses[status] = Status(stacks, duration)
        self.log(f"    {tgt.name} gains {stacks} {status}.")

    def tick_start_of_turn(self, c: Combatant) -> None:
        c.reset_turn()
        # Essence regen (keeps engines running in long fights)
        if c.essence < c.max_essence:
            c.essence = min(c.max_essence, c.essence + ESSENCE_REGEN)
        # Poison
        pois = c.statuses.get("poison")
        if pois and pois.stacks > 0:
            dmg = 3 * pois.stacks
            c.hp = max(0, c.hp - dmg)
            self.log(f"    {c.name} suffers {dmg} poison ({c.hp}/{c.max_hp}).")
            pois.duration -= 1
            if pois.duration <= 0:
                del c.statuses["poison"]
        # Digest (Food regen)
        if c.has_status("digest"):
            c.hp = min(c.max_hp, c.hp + 6)
            c.essence = min(c.max_essence, c.essence + 8)
            self.log(f"    {c.name} digests: +6 HP, +8 essence.")
            self._decay_status(c, "digest")
        # Shield decay
        if c.shield_turns > 0:
            c.shield_turns -= 1
            if c.shield_turns == 0:
                c.shield = 0
        # Decay timed buffs/debuffs
        for s in ("strengthened", "vulnerable", "lifelink", "stealth",
                  "marked", "reflect", "evasion"):
            self._decay_status(c, s)

    def _decay_status(self, c: Combatant, name: str) -> None:
        st = c.statuses.get(name)
        if st:
            st.duration -= 1
            if st.duration <= 0:
                del c.statuses[name]

    def on_act_bleed(self, c: Combatant) -> None:
        """Bleed deals damage when the combatant acts (plays a card)."""
        bl = c.statuses.get("bleed")
        if bl and bl.stacks > 0:
            dmg = 2 * bl.stacks
            c.hp = max(0, c.hp - dmg)
            self.log(f"    {c.name} bleeds for {dmg} ({c.hp}/{c.max_hp}).")

    # -- effect resolver ----------------------------------------------------
    def resolve(self, effects: list[dict], user: Combatant,
                target: Combatant, source: str) -> None:
        for e in effects:
            self._one(e, user, target, source)

    def _one(self, e: dict, user: Combatant, target: Combatant, source: str) -> None:
        verb = e.get("verb")

        if verb == "damage":
            tgt = target if e.get("target") == "enemy" else user
            amt = e["amount"]
            if e.get("bonus_if_enemy_debuffed") and tgt.is_debuffed():
                amt += e["bonus_if_enemy_debuffed"]
            if user.has_status("marked") is False and tgt.has_status("marked"):
                amt += 8  # Death Mark: our attacks hit marked enemy harder
            dealt = self._deal_damage(user, tgt, amt, source,
                                      pierce=e.get("pierce", False),
                                      lifesteal=e.get("lifesteal", 0.0))
            if e.get("on_kill_essence") and not tgt.alive:
                user.essence = min(user.max_essence,
                                   user.essence + e["on_kill_essence"])
                self.log(f"    {user.name} feeds: +{e['on_kill_essence']} essence.")
            # Marked execute threshold
            if tgt.has_status("marked") and 0 < tgt.hp <= int(tgt.max_hp * 0.40):
                tgt.hp = 0
                self.log(f"    Death Mark executes {tgt.name}!")

        elif verb == "damage_by_combo":
            amt = e["base"] + e["per_prior_attack"] * user.attacks_this_turn
            self._deal_damage(user, target, amt, source)

        elif verb == "damage_per_stack":
            st = target.statuses.get(e["status"])
            stacks = st.stacks if st else 0
            self._deal_damage(user, target, stacks * e["per"], source)

        elif verb == "damage_by_missing_hp":
            missing = user.max_hp - user.hp
            amt = min(e["cap"], e["base"] + missing)
            self._deal_damage(user, target, amt, source)

        elif verb == "damage_equal_shield":
            amt = user.shield
            user.shield = 0
            user.shield_turns = 0
            self._deal_damage(user, target, amt, source)

        elif verb == "damage_pct_essence":
            amt = int(user.essence * e["pct"] / 100)
            user.essence -= amt
            self._deal_damage(user, target, amt, source)

        elif verb == "execute":
            target.hp = 0
            self.log(f"    {source} executes {target.name}!")

        elif verb == "heal":
            before = user.hp
            user.hp = min(user.max_hp, user.hp + e["amount"])
            self.log(f"    {user.name} heals {user.hp - before}.")

        elif verb == "shield":
            self._apply_shield(user, e["amount"], e.get("duration", 1))
            self.log(f"    {user.name} gains a {e['amount']} shield.")

        elif verb == "add_shield":
            had = user.shield > 0
            self._add_shield(user, e["amount"], e.get("duration", 1))
            self.log(f"    {user.name}'s shield grows by {e['amount']}.")
            if had and e.get("bonus_if_shielded"):
                self.resolve(e["bonus_if_shielded"], user, target, source)

        elif verb == "shield_pct_self_hp":
            amt = int(user.hp * e["pct"] / 100)
            self._apply_shield(user, amt, e.get("duration", 1))
            self.log(f"    {user.name} hardens: {amt} shield.")

        elif verb == "gain_essence":
            before = user.essence
            user.essence = min(user.max_essence, user.essence + e["amount"])
            self.log(f"    {user.name} restores {user.essence - before} essence.")

        elif verb == "apply_status":
            tgt = target if e.get("target") == "enemy" else user
            self._apply_status(tgt, e["status"], e.get("stacks", 1), e.get("duration", 1))

        elif verb == "refresh_status":
            tgt = target if e.get("target") == "enemy" else user
            st = tgt.statuses.get(e["status"])
            if st:
                st.duration += 1  # offsets this turn's decay

        elif verb == "multiply_status":
            tgt = target if e.get("target") == "enemy" else user
            st = tgt.statuses.get(e["status"])
            if st and st.stacks > 0:
                st.stacks *= e["factor"]
                self.log(f"    {tgt.name}'s {e['status']} multiplied to {st.stacks}.")
            else:
                self.log(f"    {tgt.name} has no {e['status']} to multiply.")

        elif verb == "cleanse":
            if e["status"] in user.statuses:
                del user.statuses[e["status"]]
                self.log(f"    {user.name} is cleansed of {e['status']}.")

        elif verb == "cleanse_all":
            removed = 0
            for s in ("poison", "bleed"):
                if s in user.statuses:
                    del user.statuses[s]
                    removed += 1
            heal = removed * e.get("heal_per", 0)
            if heal:
                user.hp = min(user.max_hp, user.hp + heal)
            self.log(f"    {user.name} purifies {removed} effect(s), heals {heal}.")

        elif verb == "reveal":
            self.log(f"    {user.name} reveals the enemy's intent.")

        elif verb == "draw":
            if user.is_player:
                drawn = self.draw(user, e.get("amount", 1))
                self.log(f"    {user.name} draws {len(drawn)} card(s).")

        elif verb == "conditional":
            branch = "then" if self._check(e["if"], user, target) else "else"
            self.resolve(e.get(branch, []), user, target, source)

    def _check(self, cond: dict, user: Combatant, target: Combatant) -> bool:
        if "self_hp_below_pct" in cond:
            return user.hp_pct() < cond["self_hp_below_pct"]
        if "enemy_hp_below_pct" in cond:
            return target.hp_pct() < cond["enemy_hp_below_pct"]
        if "combo_at_least" in cond:
            return user.attacks_this_turn >= cond["combo_at_least"]
        if "self_has_status" in cond:
            return user.has_status(cond["self_has_status"])
        return False

    # -- playing cards ------------------------------------------------------
    def can_play(self, c: Combatant, card: Card) -> tuple[bool, str]:
        if c.essence < card.essence_cost:
            return False, "not enough essence"
        if card.hp_cost and c.hp <= card.hp_cost:
            return False, "not enough HP for the blood cost"
        if c.path_used(card.path) >= c.path_budget(card.path):
            tier = c.attainment.get(card.path, "Ordinary")
            return False, (f"{card.path.capitalize()} attainment ({tier}) "
                           f"allows only {c.path_budget(card.path)} this turn")
        return True, ""

    def play_card(self, user: Combatant, target: Combatant, card: Card) -> None:
        user.essence -= card.essence_cost
        if card.hp_cost:
            user.hp = max(1, user.hp - card.hp_cost)
        user.path_plays[card.path] = user.path_used(card.path) + 1
        self.log(f"  {user.name} plays {path_tag(card.path)} {card.name}.")
        self.resolve(card.effects, user, target, card.name)
        if "attack" in card.tags:
            user.attacks_this_turn += 1
        if card in user.hand:
            user.hand.remove(card)
        user.discard.append(card)

    # -- killer moves -------------------------------------------------------
    def available_killer_moves(self, c: Combatant, equipped_keys: set[str],
                               moves: dict[str, KillerMove]) -> list[KillerMove]:
        out = []
        for km in moves.values():
            if not tier_at_least(c.attainment.get(km.path, "Ordinary"), KILLER_MOVE_MIN):
                continue
            if not set(km.components).issubset(equipped_keys):
                continue
            out.append(km)
        return out

    def can_play_killer(self, c: Combatant, km: KillerMove) -> tuple[bool, str]:
        if c.essence < km.essence_cost:
            return False, "not enough essence"
        if c.path_used(km.path) >= c.path_budget(km.path):
            return False, f"{km.path.capitalize()} activation budget spent"
        return True, ""

    def play_killer(self, user: Combatant, target: Combatant, km: KillerMove) -> None:
        user.essence -= km.essence_cost
        user.path_plays[km.path] = user.path_used(km.path) + 1
        self.log(f"  {user.name} unleashes KILLER MOVE {path_tag(km.path)} {km.name}!")
        self.resolve(km.effects, user, target, km.name)
        user.attacks_this_turn += 1

    # -- enemy AI (priority list, Combat.md) --------------------------------
    def enemy_take_turn(self) -> None:
        e, p = self.enemy, self.player
        self.on_act_bleed(e)
        if not e.alive:
            return
        acted = True
        while acted and e.alive and p.alive:
            acted = False
            playable = [c for c in e.hand if self.can_play(e, c)[0]]
            if not playable:
                break

            def est_damage(card: Card) -> int:
                total = 0
                for eff in card.effects:
                    if eff.get("verb", "").startswith("damage") and eff.get("target") == "enemy":
                        total += eff.get("amount", eff.get("base", 12))
                    if eff.get("verb") == "conditional":
                        for br in ("then", "else"):
                            for sub in eff.get(br, []):
                                total = max(total, sub.get("amount", 0))
                return total

            if e.hp_pct() < 35:
                sustain = [c for c in playable if any(
                    x.get("verb") in ("heal", "shield") for x in c.effects)]
                if sustain:
                    self.play_card(e, p, sustain[0])
                    acted = True
                    continue
            best = max(playable, key=est_damage)
            self.play_card(e, p, best)
            acted = True
