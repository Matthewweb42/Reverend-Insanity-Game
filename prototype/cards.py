"""Gu cards and the deep, synergistic Gu pool.

A card IS a Gu (DEC-039). Effects are a small structured list the combat resolver
interprets (docs/Systems/Cards.md 'Effect Model'), NOT free text.

Design goal (this pass): each PATH is a self-reinforcing engine, so a focused
1-2 path deck combos with itself while a grab-bag deck does not. Combined with
the attainment gate (DEC-026: attainment caps how many Gu of a path you may play
per turn), this makes committing to a path the core deck-building decision.

Path engines:
  Poison  - build stacks, spread them, payoffs scale with total stacks
  Blood   - spend HP for power, lifesteal back, 'when low HP' payoffs, bleed
  Strength- consecutive-hit combo counter, self-buffs, HP-scaling defense
  Light   - stack shields, cleanse, convert shield -> damage
  Dark    - stealth for burst, execute low/debuffed targets (pairs with Poison)
  Food    - essence/heal economy, 'consume' + feast buffs (bridge to economy layer)
"""

from __future__ import annotations

from dataclasses import dataclass, field, replace

from paths import PATHS, colorize, path_symbol


@dataclass
class Card:
    name: str
    rank: int
    path: str  # key into paths.PATHS
    type: str  # Offensive / Defensive / Utility / Economic
    essence_cost: int
    text: str  # human-readable rules text (display only)
    effects: list[dict] = field(default_factory=list)
    hp_cost: int = 0        # self-damage cost to play (Blood engine)
    tags: tuple[str, ...] = ()  # e.g. ("attack",) for combo counting

    @property
    def symbol(self) -> str:
        return path_symbol(self.path)

    @property
    def target_needed(self) -> bool:
        return any(e.get("target") == "enemy" for e in self.effects) or \
            any(self._branch_targets_enemy(e) for e in self.effects)

    @staticmethod
    def _branch_targets_enemy(e: dict) -> bool:
        if e.get("verb") != "conditional":
            return False
        for branch in ("then", "else"):
            for sub in e.get(branch, []):
                if sub.get("target") == "enemy":
                    return True
        return False

    def copy(self) -> "Card":
        return replace(self, effects=[_deep(e) for e in self.effects])

    def render(self, width: int = 34) -> list[str]:
        p = PATHS[self.path]
        sym = colorize(p.symbol, p.color)
        inner = width - 2

        def line(s: str) -> str:
            return "│" + s[:inner].ljust(inner) + "│"

        cost_bits = f"Cost: {self.essence_cost} ess"
        if self.hp_cost:
            cost_bits += f" + {self.hp_cost} HP"

        top = f"┌─ {sym} " + "─" * (width - 6) + "┐"
        lines = [top]
        lines.append(line(f" {self.name.upper()}  R{self.rank}"))
        lines.append(line(f" {p.name} · {self.type}"))
        lines.append(line(f" {cost_bits}"))
        lines.append("├" + "─" * inner + "┤")
        for wrapped in _wrap(self.text, inner - 1):
            lines.append(line(" " + wrapped))
        lines.append("└" + "─" * inner + "┘")
        return lines


def _deep(e: dict) -> dict:
    """Shallow+nested copy of an effect dict (handles conditional branches)."""
    out = dict(e)
    for branch in ("then", "else"):
        if branch in out:
            out[branch] = [_deep(x) for x in out[branch]]
    return out


def _wrap(text: str, width: int) -> list[str]:
    words = text.split()
    out: list[str] = []
    cur = ""
    for w in words:
        if len(cur) + len(w) + (1 if cur else 0) <= width:
            cur = f"{cur} {w}".strip()
        else:
            if cur:
                out.append(cur)
            cur = w
    if cur:
        out.append(cur)
    return out or [""]


# ===========================================================================
# THE GU POOL  — 6 deep paths, each an internal engine.
# `A` = attack-tagged (feeds the Strength combo counter and generic "attack" hooks)
# ===========================================================================

def _atk(*e):  # helper: mark a card as an attack for combo purposes
    return e


GU: dict[str, Card] = {}


def _add(key: str, card: Card) -> None:
    GU[key] = card


# ---------------------------------------------------------------- POISON ----
# Engine: stacks. Build -> spread -> payoff scales with total enemy stacks.
_add("venom_bite", Card(
    "Venom Bite Gu", 1, "poison", "Offensive", 8,
    "Deal 5 damage. Apply 2 Poison.",
    [{"verb": "damage", "amount": 5, "target": "enemy"},
     {"verb": "apply_status", "status": "poison", "stacks": 2, "duration": 5, "target": "enemy"}],
    tags=("attack",)))
_add("creeping_rot", Card(
    "Creeping Rot Gu", 1, "poison", "Utility", 7,
    "Apply 3 Poison. Poison on the enemy loses no duration this turn.",
    [{"verb": "apply_status", "status": "poison", "stacks": 3, "duration": 5, "target": "enemy"},
     {"verb": "refresh_status", "status": "poison", "target": "enemy"}]))
_add("plague_spread", Card(
    "Plague Spread Gu", 2, "poison", "Offensive", 12,
    "Double the enemy's current Poison stacks.",
    [{"verb": "multiply_status", "status": "poison", "factor": 2, "target": "enemy"}]))
_add("corrosive_pool", Card(
    "Corrosive Pool Gu", 2, "poison", "Offensive", 14,
    "Deal damage equal to the enemy's Poison stacks x2.",
    [{"verb": "damage_per_stack", "status": "poison", "per": 2, "target": "enemy"}],
    tags=("attack",)))
_add("wither", Card(
    "Wither Gu", 2, "poison", "Debuff", 11,
    "Enemy becomes Vulnerable (25% more damage) for 3 turns. Apply 2 Poison.",
    [{"verb": "apply_status", "status": "vulnerable", "stacks": 1, "duration": 3, "target": "enemy"},
     {"verb": "apply_status", "status": "poison", "stacks": 2, "duration": 5, "target": "enemy"}]))
_add("epidemic", Card(
    "Epidemic Gu", 3, "poison", "Offensive", 20,
    "Deal damage equal to enemy Poison x3, then apply 4 Poison.",
    [{"verb": "damage_per_stack", "status": "poison", "per": 3, "target": "enemy"},
     {"verb": "apply_status", "status": "poison", "stacks": 4, "duration": 5, "target": "enemy"}],
    tags=("attack",)))

# ---------------------------------------------------------------- BLOOD -----
# Engine: HP is a resource. Spend it, get it back via lifesteal, payoff when low.
_add("blood_frenzy", Card(
    "Blood Frenzy Gu", 1, "blood", "Offensive", 6,
    "Pay 6 HP. Deal 18 damage, or 30 if you are below 50% HP.",
    [{"verb": "conditional", "if": {"self_hp_below_pct": 50},
      "then": [{"verb": "damage", "amount": 30, "target": "enemy"}],
      "else": [{"verb": "damage", "amount": 18, "target": "enemy"}]}],
    hp_cost=6, tags=("attack",)))
_add("vampiric_touch", Card(
    "Vampiric Touch Gu", 1, "blood", "Offensive", 10,
    "Deal 14 damage and heal for the damage dealt.",
    [{"verb": "damage", "amount": 14, "target": "enemy", "lifesteal": 1.0}],
    tags=("attack",)))
_add("open_vein", Card(
    "Open Vein Gu", 1, "blood", "Utility", 5,
    "Pay 10 HP. Gain 25 essence.",
    [{"verb": "gain_essence", "amount": 25}],
    hp_cost=10))
_add("hemorrhage", Card(
    "Hemorrhage Gu", 2, "blood", "Offensive", 9,
    "Deal 8 damage and apply 3 Bleed (enemy takes damage when it acts).",
    [{"verb": "damage", "amount": 8, "target": "enemy"},
     {"verb": "apply_status", "status": "bleed", "stacks": 3, "duration": 4, "target": "enemy"}],
    tags=("attack",)))
_add("blood_bond", Card(
    "Blood Bond Gu", 2, "blood", "Utility", 12,
    "Heal 18. For 2 turns, your attacks heal you for 40% of damage dealt.",
    [{"verb": "heal", "amount": 18},
     {"verb": "apply_status", "status": "lifelink", "stacks": 1, "duration": 2, "target": "self"}]))
_add("sanguine_end", Card(
    "Sanguine End Gu", 3, "blood", "Offensive", 14,
    "Pay 15 HP. Deal 20 damage +1 for each 1 HP you are missing (capped 60).",
    [{"verb": "damage_by_missing_hp", "base": 20, "cap": 60, "target": "enemy"}],
    hp_cost=15, tags=("attack",)))

# --------------------------------------------------------------- STRENGTH ---
# Engine: combo counter. Nth consecutive attack this turn ramps. Self-buff.
_add("iron_fist", Card(
    "Iron Fist Gu", 1, "strength", "Offensive", 9,
    "Deal 14 damage. +6 for each attack you've already played this turn.",
    [{"verb": "damage_by_combo", "base": 14, "per_prior_attack": 6, "target": "enemy"}],
    tags=("attack",)))
_add("rising_blow", Card(
    "Rising Blow Gu", 1, "strength", "Offensive", 7,
    "Deal 10 damage. This counts as an attack (builds your combo).",
    [{"verb": "damage", "amount": 10, "target": "enemy"}],
    tags=("attack",)))
_add("body_harden", Card(
    "Body Hardening Gu", 1, "strength", "Defensive", 10,
    "Gain a shield equal to 15% of your current HP (3 turns).",
    [{"verb": "shield_pct_self_hp", "pct": 15, "duration": 3}]))
_add("war_cry", Card(
    "War Cry Gu", 1, "strength", "Buff", 8,
    "Gain Strengthened (deal 25% more damage) for 3 turns.",
    [{"verb": "apply_status", "status": "strengthened", "stacks": 1, "duration": 3, "target": "self"}]))
_add("overpower", Card(
    "Overpower Gu", 2, "strength", "Offensive", 14,
    "Deal 22 damage that ignores shields.",
    [{"verb": "damage", "amount": 22, "target": "enemy", "pierce": True}],
    tags=("attack",)))
_add("titan_smash", Card(
    "Titan Smash Gu", 3, "strength", "Offensive", 18,
    "Deal 20 damage. If this is your 3rd+ attack this turn, deal 45 instead.",
    [{"verb": "conditional", "if": {"combo_at_least": 2},
      "then": [{"verb": "damage", "amount": 45, "target": "enemy"}],
      "else": [{"verb": "damage", "amount": 20, "target": "enemy"}]}],
    tags=("attack",)))

# ----------------------------------------------------------------- LIGHT ----
# Engine: shields. Stack them, cleanse, then spend shield as damage.
_add("light_shield", Card(
    "Light Shield Gu", 1, "light", "Defensive", 9,
    "Gain a 22 HP shield (3 turns).",
    [{"verb": "shield", "amount": 22, "duration": 3}]))
_add("radiant_ward", Card(
    "Radiant Ward Gu", 1, "light", "Defensive", 12,
    "Add 18 to your shield. If you already had a shield, also heal 8.",
    [{"verb": "add_shield", "amount": 18, "duration": 3, "bonus_if_shielded":
      [{"verb": "heal", "amount": 8}]}]))
_add("cleansing_ray", Card(
    "Cleansing Ray Gu", 1, "light", "Utility", 8,
    "Remove all Poison and Bleed from yourself. Heal 6 per effect removed.",
    [{"verb": "cleanse_all", "heal_per": 6}]))
_add("revelation", Card(
    "Revelation Gu", 2, "light", "Utility", 10,
    "Reveal the enemy's next Gu and make it Vulnerable for 2 turns.",
    [{"verb": "apply_status", "status": "vulnerable", "stacks": 1, "duration": 2, "target": "enemy"},
     {"verb": "reveal", "amount": 1}]))
_add("mirror_barrier", Card(
    "Mirror Barrier Gu", 2, "light", "Defensive", 13,
    "Gain a 20 shield. Next time it absorbs damage, reflect half to the enemy.",
    [{"verb": "shield", "amount": 20, "duration": 3},
     {"verb": "apply_status", "status": "reflect", "stacks": 1, "duration": 3, "target": "self"}]))
_add("radiant_burst", Card(
    "Radiant Burst Gu", 3, "light", "Offensive", 15,
    "Deal damage equal to your current shield. Your shield is consumed.",
    [{"verb": "damage_equal_shield", "target": "enemy"}],
    tags=("attack",)))

# ------------------------------------------------------------------ DARK ----
# Engine: stealth + execute. Burst from stealth; bonus vs debuffed/low targets.
# (Pairs with Poison: poisoned enemies are 'debuffed'.)
_add("shadow_veil", Card(
    "Shadow Veil Gu", 1, "dark", "Utility", 8,
    "Enter Stealth. Your next attack from stealth deals +20 damage.",
    [{"verb": "apply_status", "status": "stealth", "stacks": 1, "duration": 2, "target": "self"}]))
_add("shadow_dagger", Card(
    "Shadow Dagger Gu", 1, "dark", "Offensive", 9,
    "Deal 12 damage. If the enemy is debuffed (Poison/Bleed/Vulnerable), +10.",
    [{"verb": "damage", "amount": 12, "target": "enemy", "bonus_if_enemy_debuffed": 10}],
    tags=("attack",)))
_add("throat_slit", Card(
    "Throat Slit Gu", 2, "dark", "Offensive", 12,
    "Deal 14 damage, or 42 if the enemy is below 35% HP.",
    [{"verb": "conditional", "if": {"enemy_hp_below_pct": 35},
      "then": [{"verb": "damage", "amount": 42, "target": "enemy"}],
      "else": [{"verb": "damage", "amount": 14, "target": "enemy"}]}],
    tags=("attack",)))
_add("smoke_step", Card(
    "Smoke Step Gu", 1, "dark", "Defensive", 7,
    "Gain Evasion: the enemy's next attack has a high chance to miss.",
    [{"verb": "apply_status", "status": "evasion", "stacks": 1, "duration": 2, "target": "self"}]))
_add("night_ambush", Card(
    "Night Ambush Gu", 2, "dark", "Offensive", 13,
    "Deal 16 damage. If you are in Stealth, deal 40 and apply Vulnerable.",
    [{"verb": "conditional", "if": {"self_has_status": "stealth"},
      "then": [{"verb": "damage", "amount": 40, "target": "enemy"},
               {"verb": "apply_status", "status": "vulnerable", "stacks": 1, "duration": 2, "target": "enemy"}],
      "else": [{"verb": "damage", "amount": 16, "target": "enemy"}]}],
    tags=("attack",)))
_add("death_mark", Card(
    "Death Mark Gu", 3, "dark", "Debuff", 16,
    "Mark the enemy. For 3 turns your attacks deal +8 and execute below 40% HP.",
    [{"verb": "apply_status", "status": "marked", "stacks": 1, "duration": 3, "target": "enemy"}]))

# ------------------------------------------------------------------ FOOD ----
# Engine: essence/heal economy + consume. Sustains long fights, funds big turns.
_add("nourish", Card(
    "Nourishing Aura Gu", 1, "food", "Utility", 6,
    "Restore 14 essence and heal 6.",
    [{"verb": "gain_essence", "amount": 14},
     {"verb": "heal", "amount": 6}]))
_add("devour", Card(
    "Devouring Maw Gu", 1, "food", "Offensive", 10,
    "Deal 16 damage. If this kills the enemy, gain 20 essence.",
    [{"verb": "damage", "amount": 16, "target": "enemy", "on_kill_essence": 20}],
    tags=("attack",)))
_add("second_helping", Card(
    "Second Helping Gu", 1, "food", "Utility", 8,
    "Draw 2 cards.",
    [{"verb": "draw", "amount": 2}]))
_add("slow_digest", Card(
    "Slow Digestion Gu", 2, "food", "Buff", 11,
    "For 3 turns, regenerate 6 HP and 8 essence at the start of your turn.",
    [{"verb": "apply_status", "status": "digest", "stacks": 1, "duration": 3, "target": "self"}]))
_add("feast", Card(
    "Grand Feast Gu", 2, "food", "Buff", 14,
    "Heal 20, gain 20 essence, and gain Strengthened for 2 turns.",
    [{"verb": "heal", "amount": 20},
     {"verb": "gain_essence", "amount": 20},
     {"verb": "apply_status", "status": "strengthened", "stacks": 1, "duration": 2, "target": "self"}]))
_add("gluttony", Card(
    "Gluttony Gu", 3, "food", "Offensive", 16,
    "Deal damage equal to 30% of your current essence, then lose that essence.",
    [{"verb": "damage_pct_essence", "pct": 30, "target": "enemy"}],
    tags=("attack",)))


# ===========================================================================
# KILLER MOVES  — require Master+ attainment in the path AND the component Gu
# equipped in the aperture. They are a separate combat action (docs/Systems/Cards.md).
# ===========================================================================

@dataclass
class KillerMove:
    name: str
    path: str
    essence_cost: int
    components: tuple[str, ...]  # keys into GU that must be equipped
    text: str
    effects: list[dict]

    @property
    def symbol(self) -> str:
        return path_symbol(self.path)


KILLER_MOVES: dict[str, KillerMove] = {
    "plague_apocalypse": KillerMove(
        "Plague Apocalypse", "poison", 30,
        ("plague_spread", "epidemic"),
        "Double enemy Poison, then deal Poison x4 damage.",
        [{"verb": "multiply_status", "status": "poison", "factor": 2, "target": "enemy"},
         {"verb": "damage_per_stack", "status": "poison", "per": 4, "target": "enemy"}]),
    "exsanguinate": KillerMove(
        "Exsanguinate", "blood", 28,
        ("sanguine_end", "vampiric_touch"),
        "Pay 20 HP. Deal 50 damage and heal for all of it.",
        [{"verb": "damage", "amount": 50, "target": "enemy", "lifesteal": 1.0}]),
    "avatar_of_war": KillerMove(
        "Avatar of War", "strength", 26,
        ("titan_smash", "war_cry"),
        "Gain Strengthened and deal 30 damage; +12 per prior attack this turn.",
        [{"verb": "apply_status", "status": "strengthened", "stacks": 1, "duration": 3, "target": "self"},
         {"verb": "damage_by_combo", "base": 30, "per_prior_attack": 12, "target": "enemy"}]),
    "dawnbreaker": KillerMove(
        "Dawnbreaker", "light", 26,
        ("radiant_burst", "mirror_barrier"),
        "Gain a 30 shield, then deal damage equal to your shield.",
        [{"verb": "shield", "amount": 30, "duration": 3},
         {"verb": "damage_equal_shield", "target": "enemy"}]),
    "reaping_shadow": KillerMove(
        "Reaping Shadow", "dark", 24,
        ("throat_slit", "shadow_veil"),
        "Enter Stealth and deal 30 damage; execute the enemy if below 50% HP.",
        [{"verb": "apply_status", "status": "stealth", "stacks": 1, "duration": 1, "target": "self"},
         {"verb": "conditional", "if": {"enemy_hp_below_pct": 50},
          "then": [{"verb": "execute", "target": "enemy"}],
          "else": [{"verb": "damage", "amount": 30, "target": "enemy"}]}]),
}


# ===========================================================================
# STARTER DECKS  — path-focused, so the player starts with a real engine.
# ===========================================================================

STARTER_DECKS: dict[str, dict] = {
    "poison": {
        "name": "Rot Weaver (Poison)",
        "blurb": "Stack poison, spread it, detonate. Patient and inevitable.",
        "cards": ["venom_bite", "venom_bite", "creeping_rot", "wither",
                  "plague_spread", "corrosive_pool", "corrosive_pool",
                  "epidemic", "shadow_dagger", "nourish"],
        "attainment": {"poison": "Master", "dark": "Ordinary", "food": "Ordinary"},
    },
    "blood": {
        "name": "Crimson Gambler (Blood)",
        "blurb": "Spend your life for power; heal it back with lifesteal.",
        "cards": ["blood_frenzy", "blood_frenzy", "vampiric_touch", "vampiric_touch",
                  "open_vein", "hemorrhage", "blood_bond", "sanguine_end",
                  "iron_fist", "nourish"],
        "attainment": {"blood": "Master", "strength": "Ordinary", "food": "Ordinary"},
    },
    "strength": {
        "name": "War Titan (Strength)",
        "blurb": "Chain attacks in one turn to ramp into a huge finisher.",
        "cards": ["rising_blow", "rising_blow", "iron_fist", "iron_fist",
                  "war_cry", "body_harden", "overpower", "titan_smash",
                  "vampiric_touch", "nourish"],
        "attainment": {"strength": "Master", "blood": "Ordinary", "food": "Ordinary"},
    },
    "light": {
        "name": "Radiant Warden (Light)",
        "blurb": "Outlast behind shields, then convert your ward into a blast.",
        "cards": ["light_shield", "light_shield", "radiant_ward", "cleansing_ray",
                  "revelation", "mirror_barrier", "radiant_burst",
                  "iron_fist", "nourish", "second_helping"],
        "attainment": {"light": "Master", "strength": "Ordinary", "food": "Ordinary"},
    },
    "dark": {
        "name": "Night Reaper (Dark)",
        "blurb": "Strike from stealth and execute the weakened. Loves poison.",
        "cards": ["shadow_veil", "shadow_dagger", "shadow_dagger", "smoke_step",
                  "throat_slit", "night_ambush", "death_mark",
                  "venom_bite", "wither", "nourish"],
        "attainment": {"dark": "Master", "poison": "Ordinary", "food": "Ordinary"},
    },
    "food": {
        "name": "Endless Glutton (Food)",
        "blurb": "Fuel a huge essence economy, then dump it all into one blow.",
        "cards": ["nourish", "nourish", "devour", "second_helping",
                  "slow_digest", "feast", "gluttony",
                  "iron_fist", "vampiric_touch", "body_harden"],
        "attainment": {"food": "Master", "strength": "Ordinary", "blood": "Ordinary"},
    },
}


def build_deck(deck_key: str) -> list[Card]:
    return [GU[k].copy() for k in STARTER_DECKS[deck_key]["cards"]]


# Back-compat name used by earlier code paths.
STARTER_GU = GU
