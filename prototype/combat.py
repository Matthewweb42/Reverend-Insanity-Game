"""Card combat: the aperture-as-deck loop (DEC-039).

Deck lifecycle per docs/Systems/Cards.md:
  aperture -> shuffled draw pile -> hand -> discard -> reshuffle when empty.

Combatants, the effect resolver, and a simple priority-based enemy AI live here.
Randomness is centralized through a passed-in `random.Random` so runs are
reproducible when seeded.
"""

from __future__ import annotations

from dataclasses import dataclass, field
import random

from cards import Card
from paths import path_tag, colorize


# --- Tunable combat/deck constants (docs/Systems/Cards.md) ------------------
HAND_SIZE = 5
DRAW_PER_TURN = 1
HAND_MAX = 8


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
    # Deck piles (players use their aperture; enemies use a fixed loadout).
    draw_pile: list[Card] = field(default_factory=list)
    hand: list[Card] = field(default_factory=list)
    discard: list[Card] = field(default_factory=list)

    @property
    def alive(self) -> bool:
        return self.hp > 0

    def hp_pct(self) -> float:
        return 100.0 * self.hp / self.max_hp if self.max_hp else 0.0


class Combat:
    def __init__(self, player: Combatant, enemy: Combatant,
                 rng: random.Random | None = None, log=print):
        self.player = player
        self.enemy = enemy
        self.rng = rng or random.Random()
        self.log = log
        self.turn = 0
        self.result: str | None = None  # "win" / "lose" / "flee"

    # -- deck operations ----------------------------------------------------
    def _shuffle_deck(self, c: Combatant, cards: list[Card]) -> None:
        c.draw_pile = [card.copy() for card in cards]
        c.hand = []
        c.discard = []
        self.rng.shuffle(c.draw_pile)

    def _draw(self, c: Combatant, n: int) -> list[Card]:
        drawn: list[Card] = []
        for _ in range(n):
            if len(c.hand) >= HAND_MAX:
                break  # hand full: stop drawing (prototype rule)
            if not c.draw_pile:
                if not c.discard:
                    break  # nothing left to draw
                c.draw_pile = c.discard
                c.discard = []
                self.rng.shuffle(c.draw_pile)
            card = c.draw_pile.pop()
            c.hand.append(card)
            drawn.append(card)
        return drawn

    # -- status / damage helpers -------------------------------------------
    def _apply_shield(self, c: Combatant, amount: int, duration: int) -> None:
        c.shield = max(c.shield, amount)
        c.shield_turns = max(c.shield_turns, duration)

    def _deal_damage(self, target: Combatant, amount: int, source_name: str) -> None:
        remaining = amount
        if target.shield > 0:
            absorbed = min(target.shield, remaining)
            target.shield -= absorbed
            remaining -= absorbed
            if absorbed:
                self.log(f"    {target.name}'s shield absorbs {absorbed}.")
        target.hp = max(0, target.hp - remaining)
        self.log(f"    {source_name} deals {remaining} to {target.name} "
                 f"({target.hp}/{target.max_hp}).")

    def _tick_start_of_turn(self, c: Combatant) -> None:
        # Poison damage
        pois = c.statuses.get("poison")
        if pois and pois.stacks > 0:
            dmg = 3 * pois.stacks
            c.hp = max(0, c.hp - dmg)
            self.log(f"    {c.name} suffers {dmg} poison ({c.hp}/{c.max_hp}).")
            pois.duration -= 1
            if pois.duration <= 0:
                del c.statuses["poison"]
        # Shield decay
        if c.shield_turns > 0:
            c.shield_turns -= 1
            if c.shield_turns == 0:
                c.shield = 0

    # -- effect resolver ----------------------------------------------------
    def _resolve_effects(self, effects: list[dict], user: Combatant,
                         target: Combatant, source_name: str) -> None:
        for e in effects:
            verb = e.get("verb")
            if verb == "damage":
                tgt = target if e.get("target") == "enemy" else user
                self._deal_damage(tgt, e["amount"], source_name)
            elif verb == "heal":
                before = user.hp
                user.hp = min(user.max_hp, user.hp + e["amount"])
                self.log(f"    {user.name} heals {user.hp - before} "
                         f"({user.hp}/{user.max_hp}).")
            elif verb == "shield":
                self._apply_shield(user, e["amount"], e.get("duration", 1))
                self.log(f"    {user.name} gains a {e['amount']} HP shield.")
            elif verb == "gain_essence":
                before = user.essence
                user.essence = min(user.max_essence, user.essence + e["amount"])
                self.log(f"    {user.name} restores {user.essence - before} essence.")
            elif verb == "apply_status":
                tgt = target if e.get("target") == "enemy" else user
                st = tgt.statuses.get(e["status"])
                if st:
                    st.stacks += e.get("stacks", 1)
                    st.duration = max(st.duration, e.get("duration", 1))
                else:
                    tgt.statuses[e["status"]] = Status(
                        e.get("stacks", 1), e.get("duration", 1))
                self.log(f"    {tgt.name} is afflicted with "
                         f"{e.get('stacks', 1)} {e['status']}.")
            elif verb == "cleanse":
                if e["status"] in user.statuses:
                    del user.statuses[e["status"]]
                    self.log(f"    {user.name} is cleansed of {e['status']}.")
            elif verb == "draw":
                if user.is_player:
                    drawn = self._draw(user, e.get("amount", 1))
                    self.log(f"    {user.name} draws {len(drawn)} card(s).")
            elif verb == "conditional":
                if self._check_condition(e["if"], user, target):
                    self._resolve_effects(e["then"], user, target, source_name)
                else:
                    self._resolve_effects(e.get("else", []), user, target, source_name)

    def _check_condition(self, cond: dict, user: Combatant, target: Combatant) -> bool:
        if "self_hp_below_pct" in cond:
            return user.hp_pct() < cond["self_hp_below_pct"]
        if "enemy_hp_below_pct" in cond:
            return target.hp_pct() < cond["enemy_hp_below_pct"]
        return False

    # -- playing cards ------------------------------------------------------
    def can_play(self, c: Combatant, card: Card) -> tuple[bool, str]:
        if c.essence < card.essence_cost:
            return False, "not enough essence"
        if card.hp_cost and c.hp <= card.hp_cost:
            return False, "not enough HP to pay the blood cost"
        return True, ""

    def play_card(self, user: Combatant, target: Combatant, card: Card) -> None:
        user.essence -= card.essence_cost
        if card.hp_cost:
            user.hp = max(1, user.hp - card.hp_cost)
        self.log(f"  {user.name} plays {path_tag(card.path)} {card.name}.")
        self._resolve_effects(card.effects, user, target, card.name)
        if card in user.hand:
            user.hand.remove(card)
        user.discard.append(card)

    # -- enemy AI (simple priority list, per Combat.md) ---------------------
    def enemy_take_turn(self) -> None:
        e, p = self.enemy, self.player
        # Enemies use their hand like the player; pick the "best" affordable card.
        playable = [c for c in e.hand if self.can_play(e, c)[0]]
        if not playable:
            self.log(f"  {e.name} has no affordable Gu and waits.")
            return
        # Priority: lethal > heal-when-low > highest-damage > anything.
        def est_damage(card: Card) -> int:
            total = 0
            for eff in card.effects:
                if eff.get("verb") == "damage" and eff.get("target") == "enemy":
                    total += eff["amount"]
                if eff.get("verb") == "conditional":
                    for branch in ("then", "else"):
                        for sub in eff.get(branch, []):
                            if sub.get("verb") == "damage":
                                total = max(total, sub["amount"])
            return total

        # Heal if low and has a heal card
        if e.hp_pct() < 35:
            heals = [c for c in playable
                     if any(x.get("verb") in ("heal", "shield") for x in c.effects)]
            if heals:
                self.play_card(e, p, heals[0])
                return
        best = max(playable, key=est_damage)
        self.play_card(e, p, best)
