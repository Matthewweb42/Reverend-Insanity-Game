"""Gu cards and the starter Gu pool.

A card IS a Gu (DEC-039). Effects are a small structured list the combat resolver
interprets (see docs/Systems/Cards.md 'Effect Model'), NOT free text — this keeps
combat data-driven and lets the AI generator emit the same shape later.
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
    hp_cost: int = 0  # Blood-path style self-damage cost to play

    @property
    def symbol(self) -> str:
        return path_symbol(self.path)

    @property
    def target_needed(self) -> bool:
        """Does playing this card require choosing a single enemy target?"""
        for e in self.effects:
            if e.get("target") == "enemy":
                return True
        return False

    def copy(self) -> "Card":
        # Deep-ish copy so combat instances don't mutate the template.
        return replace(self, effects=[dict(e) for e in self.effects])

    def render(self, width: int = 34) -> list[str]:
        """Return the card as a list of lines (a boxed card)."""
        p = PATHS[self.path]
        sym = colorize(p.symbol, p.color)
        inner = width - 2

        def line(s: str) -> str:
            # pad/truncate to inner width (ignoring color codes length is fine here
            # because we only colorize the symbol on the top border)
            return "│" + s[:inner].ljust(inner) + "│"

        cost_bits = f"Cost: {self.essence_cost} essence"
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


# ---------------------------------------------------------------------------
# Starter Gu pool (hardcoded for the prototype; AI generation comes later).
# Kept small and readable. Values pulled from docs/Content/Paths.md examples.
# ---------------------------------------------------------------------------

STARTER_GU: dict[str, Card] = {
    # Strength
    "iron_fist": Card(
        "Iron Fist Gu", 1, "strength", "Offensive", 12,
        "Deal 18 damage to an enemy.",
        [{"verb": "damage", "amount": 18, "target": "enemy"}],
    ),
    "steel_body": Card(
        "Steel Body Gu", 1, "strength", "Defensive", 14,
        "Gain a 20 HP shield for 3 turns.",
        [{"verb": "shield", "amount": 20, "duration": 3}],
    ),
    # Blood
    "blood_frenzy": Card(
        "Blood Frenzy Gu", 1, "blood", "Offensive", 8,
        "Deal 20 damage. If you are below 50% HP, deal 30 instead.",
        [{"verb": "conditional",
          "if": {"self_hp_below_pct": 50},
          "then": [{"verb": "damage", "amount": 30, "target": "enemy"}],
          "else": [{"verb": "damage", "amount": 20, "target": "enemy"}]}],
        hp_cost=6,
    ),
    "vampiric_touch": Card(
        "Vampiric Touch Gu", 1, "blood", "Offensive", 12,
        "Deal 14 damage and heal for 10.",
        [{"verb": "damage", "amount": 14, "target": "enemy"},
         {"verb": "heal", "amount": 10}],
    ),
    # Poison
    "venom_strike": Card(
        "Venom Strike Gu", 1, "poison", "Offensive", 10,
        "Deal 6 damage and apply 2 Poison stacks (3 dmg/stack for 4 turns).",
        [{"verb": "damage", "amount": 6, "target": "enemy"},
         {"verb": "apply_status", "status": "poison", "stacks": 2,
          "duration": 4, "target": "enemy"}],
    ),
    # Light
    "light_shield": Card(
        "Light Shield Gu", 1, "light", "Defensive", 12,
        "Gain a 30 HP shield for 3 turns.",
        [{"verb": "shield", "amount": 30, "duration": 3}],
    ),
    "purifying_light": Card(
        "Purifying Light Gu", 1, "light", "Utility", 10,
        "Heal 18 and remove Poison from yourself.",
        [{"verb": "heal", "amount": 18},
         {"verb": "cleanse", "status": "poison"}],
    ),
    # Dark
    "shadow_strike": Card(
        "Shadow Strike Gu", 1, "dark", "Offensive", 14,
        "Deal 16 damage. If the enemy is below 30% HP, deal 40 instead.",
        [{"verb": "conditional",
          "if": {"enemy_hp_below_pct": 30},
          "then": [{"verb": "damage", "amount": 40, "target": "enemy"}],
          "else": [{"verb": "damage", "amount": 16, "target": "enemy"}]}],
    ),
    # Food
    "nourishing_aura": Card(
        "Nourishing Aura Gu", 1, "food", "Utility", 10,
        "Restore 15 essence and heal 8.",
        [{"verb": "gain_essence", "amount": 15},
         {"verb": "heal", "amount": 8}],
    ),
    # Wisdom
    "insight": Card(
        "Insight Gu", 1, "wisdom", "Utility", 8,
        "Draw 2 cards.",
        [{"verb": "draw", "amount": 2}],
    ),
}


def starter_deck() -> list[Card]:
    """A reasonable Rank-1 starter aperture/deck (10 slots, DEC-039).

    Damage core + sustain + a little utility, leaning Blood/Light per the
    deck-building guidance in docs/Systems/Cards.md.
    """
    picks = [
        "iron_fist", "iron_fist",
        "blood_frenzy", "blood_frenzy",
        "vampiric_touch",
        "venom_strike",
        "light_shield",
        "purifying_light",
        "nourishing_aura",
        "insight",
    ]
    return [STARTER_GU[k].copy() for k in picks]
