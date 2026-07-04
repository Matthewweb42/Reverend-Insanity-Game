# Cards & Deck System [FINAL]

## Overview

The game is a **card RPG**. Gu worms ARE cards. Building your Gu loadout IS deck-building.
This document defines how the aperture-as-deck model works and how it feeds combat.

Related decisions: DEC-039 (Aperture = deck), DEC-040 (Path symbols), DEC-041 (text prototype first).
See also: [Combat](Combat.md), [Gu](../Content/Gu.md), [Paths](../Content/Paths.md).

---

## Core Model: Aperture = Deck

There is no separate "deck" object. The Gu slotted into your **aperture** are your deck.

```
  Collection (every Gu you own)
        │  equip into aperture slots (limited)
        ▼
  Aperture / Deck   (Rank 1: 10 slots → Rank 5: 50 slots)
        │  each combat, becomes the draw pile
        ▼
  Draw Pile ──draw──▶ Hand ──play──▶ Discard Pile
        ▲                                 │
        └──────── reshuffle when empty ───┘
```

- **Reorganizing your aperture between combats = rebuilding your deck.**
- The strategic tension is the aperture slot cap: you cannot bring every Gu, so you choose a coherent set.
- Aperture slot count is defined by rank (see [Cultivation](Cultivation.md) / GameDesign aperture section).

---

## Deck Lifecycle in Combat

1. **Setup** — All equipped aperture Gu are copied into a **draw pile** and shuffled.
2. **Opening hand** — Draw `HAND_SIZE` cards (default 5).
3. **Each player turn** — Draw `DRAW_PER_TURN` cards (default 1) at start of turn.
4. **Play** — Playing a Gu moves its card from hand to the **discard pile** and pays its essence cost.
5. **Reshuffle** — When the draw pile is empty and you must draw, shuffle the discard pile into a new draw pile.
6. **Hand cap** — Max hand size `HAND_MAX` (default 8); excess draws are discarded (or draw stops — prototype: stop drawing).
7. **End of combat** — Piles are discarded; the aperture is unchanged (Gu are not consumed).

### Tunable Constants (prototype defaults)

| Constant | Default | Notes |
|----------|---------|-------|
| `HAND_SIZE` | 5 | Opening hand |
| `DRAW_PER_TURN` | 1 | Cards drawn at start of each player turn |
| `HAND_MAX` | 8 | Hand cap |
| `RESHUFFLE` | true | Discard reshuffles into draw pile when empty |

These live in one config block so combat feel can be tuned quickly.

---

## Cards Are Gu

A card's data is exactly a Gu's data (see [Gu](../Content/Gu.md)). Combat-relevant fields:

| Field | Use in combat |
|-------|---------------|
| `name` | Card title |
| `rank` | Power tier |
| `path` | Determines symbol + color (DEC-040) |
| `type` | Offensive / Defensive / Utility / Economic |
| `essence_cost` | Paid from essence pool to play |
| `effect` | Structured effect the resolver applies |
| `symbol` | Derived from path (glyph shown on card) |

**Duplicates:** If the player owns multiple copies of the same Gu, each occupies its own aperture slot and appears as a separate card in the draw pile. (A Gu is one card = one slot.)

---

## Path Symbols (DEC-040)

Each path has a glyph + color used purely for card readability. No cost/resource mechanic.

| Path | Symbol | Color |
|------|--------|-------|
| Strength | ✊ | Crimson |
| Wisdom | ◆ | Azure |
| Blood | ◈ | Dark Red |
| Refinement | ⚒ | Bronze |
| Transformation | ☯ | Teal |
| Enslavement | ⛓ | Purple |
| Poison | ☠ | Sickly Green |
| Dark | ☾ | Indigo |
| Light | ✦ | Gold |
| Food | ◍ | Amber |

In the text prototype these are unicode glyphs. In Godot/web they become generated icons but keep the same color mapping.

---

## Card Rendering (Text Prototype)

```
┌─ ◈ ─────────────────────────┐
│ BLOOD FRENZY GU     R2  ◈   │   ◈ = Blood path symbol
│ Blood · Offensive           │
│ Cost: 10 essence + 15 HP    │
│─────────────────────────────│
│ Deal 45 damage. If below    │
│ 50% HP, deal 65 instead.    │
└─────────────────────────────┘
```

Hand is shown as a numbered list; the player picks a card by number, then a target if needed.

---

## Effect Model

To keep combat data-driven (and later AI-generatable), each Gu effect is a small structured
object the resolver interprets, not free text. Minimum viable effect verbs for the prototype:

| Verb | Params | Meaning |
|------|--------|---------|
| `damage` | `amount`, `target` (`enemy`/`all_enemies`) | Deal damage (goes through hit resolution) |
| `heal` | `amount` | Heal self |
| `shield` | `amount`, `duration` | Gain damage-absorbing shield |
| `apply_status` | `status`, `stacks`, `duration`, `target` | Apply a status effect (see Combat.md) |
| `self_damage` | `amount` | Pay HP as a cost (Blood path) |
| `gain_essence` | `amount` | Restore essence |
| `buff` / `debuff` | `stat`, `amount`, `duration`, `target` | Modify a stat temporarily |
| `conditional` | `if`, `then`, `else` | Branch on a condition (e.g. self HP < 50%) |

A card may carry a list of effects resolved in order. This is deliberately small; it grows as
new Gu need new verbs, and the AI generator (later sprint) emits the same structure.

---

## Deck-Building Guidance (surfaced to player)

Because the aperture is limited, a "good deck" tends to:
- Have a **damage core** (enough offensive Gu to actually kill things)
- Include **sustain or defense** (heal/shield) so long fights are survivable
- Lean into **1–2 paths** for attainment synergy and killer-move enablement
- Keep **essence curve** reasonable (not all high-cost Gu, or you draw unplayable hands)

The game does not enforce these — they emerge from the aperture cap and essence economy.

---

## Relationship to Long-Term Godot Client

The prototype implements this model in Python/terminal (DEC-041). When ported to Godot:
- The draw/hand/discard logic maps directly to a `Deck` helper on the combat scene
- Cards become `Control` nodes rendering the same fields
- Path symbols become generated icon textures (same color map)
- The structured effect model is engine-agnostic and carries over unchanged

---

## Open Questions

- [ ] Should some Gu be "exhaust" (single-use per combat) vs reshuffling? (Prototype: all reshuffle)
- [ ] Do killer moves draw their component Gu out of hand, or exist as separate cards? (Prototype: separate action, requires components equipped)
- [ ] Per-turn essence regen during combat, or fixed pool? (Prototype: fixed pool per DEC — revisit for feel)
