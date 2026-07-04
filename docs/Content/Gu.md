# Gu Design [DRAFT]

## Overview

Gu worms are the core power system. Each Gu is a living creature that grants abilities. Players collect, maintain, and combine Gu to build their power.

---

## Gu Fundamentals

### What Is a Gu?

- Living magical insect/creature
- Grants specific ability when activated
- Requires feeding/maintenance
- Stored in the aperture (limited slots)
- Has rank matching cultivator ranks

### Gu Attributes

| Attribute | Description |
|-----------|-------------|
| **Name** | Evocative name ending in "Gu" |
| **Rank** | 1-9, determines power level |
| **Path** | Which cultivation path it belongs to (determines symbol + color, see [Cards](../Systems/Cards.md)) |
| **Symbol** | Glyph derived from path — pure visual identity (DEC-040) |
| **Type** | Offensive, Defensive, Utility, or Economic |
| **Rarity** | Common, Uncommon, Rare, Legendary |
| **Essence Cost** | Activation cost |
| **Slot Size** | Aperture slots consumed (usually 1) |
| **Effect** | What it does when activated |

---

## Gu Ranks

| Rank | Power Tier | Typical User | Essence Cost Range |
|------|------------|--------------|-------------------|
| 1 | Beginner | Rank 1 mortals | 5-15 |
| 2 | Intermediate | Rank 2-3 mortals | 10-25 |
| 3 | Advanced | Rank 3-4 mortals | 20-40 |
| 4 | Expert | Rank 4-5 mortals | 35-60 |
| 5 | Master | Rank 5 quasi-masters | 50-80 |
| 6 | Immortal | Rank 6 immortals | 100-200 |
| 7 | Venerable | Rank 7 venerables | 200-500 |
| 8 | Supreme | Rank 8 great grandmasters | 500-1000 |
| 9 | Ultimate | Rank 9 supreme | 1000+ |

### Using Higher/Lower Rank Gu

- **Higher Rank:** Cannot use Gu above your rank
- **Lower Rank:** Can use, but efficiency drops
  - 1 rank below: 90% effectiveness
  - 2 ranks below: 70% effectiveness
  - 3+ ranks below: 50% effectiveness, often not worth slot

---

## Gu Types

### Offensive Gu
Deal damage to enemies.

**Subtypes:**
- Direct damage (instant)
- Damage over time (DoT)
- Area of effect (AoE)
- Conditional damage (bonus in situations)

**Design Space:**
- Single target vs multi-target
- Element types (fire, ice, etc.)
- Scaling factors
- Secondary effects (debuffs)

### Defensive Gu
Protect the user.

**Subtypes:**
- Shields (absorb damage)
- Damage reduction (percentage)
- Evasion (chance to dodge)
- Healing (restore health)
- Cleansing (remove debuffs)

**Design Space:**
- Duration vs potency
- Conditional triggers
- Resource regeneration
- Counter-attack on block

### Utility Gu
Provide non-combat advantages.

**Subtypes:**
- Movement (travel, positioning)
- Information (detection, analysis)
- Stealth (hiding, disguise)
- Storage (inventory expansion)
- Crafting (refinement bonuses)

**Design Space:**
- Out-of-combat value
- Combat utility secondary
- Quality of life improvements
- Exploration enablers

### Economic Gu
Generate or manage resources.

**Subtypes:**
- Income generation
- Cost reduction
- Material production
- Trade advantages

**Design Space:**
- Passive vs active income
- Investment returns
- Maintenance reduction
- Rare but powerful effects

---

## Rarity Tiers

### Common
- Widely available
- Basic effects
- Low cost to acquire
- Frequently encountered

**Generation Weight:** 50%

### Uncommon
- Moderately available
- Enhanced effects or added utility
- Found in specific locations
- Worth collecting

**Generation Weight:** 30%

### Rare
- Hard to find
- Powerful effects
- Specific acquisition methods
- Build-defining potential

**Generation Weight:** 15%

### Legendary
- Extremely rare
- Game-changing effects
- Often unique per run
- Quest or boss rewards

**Generation Weight:** 5%

---

## Gu Design Patterns

### The "X Damage" Pattern
```
Simple damage dealing
- Scale damage with rank
- Add secondary effect at higher rarity
- Path themes affect delivery method
```

### The "Shield for X" Pattern
```
Defensive absorption
- Duration vs amount tradeoff
- Higher rank = better ratio
- Conditional bonuses at rare+
```

### The "Buff for X Turns" Pattern
```
Temporary enhancement
- Duration scales with rank
- Effect strength scales with rarity
- Stacking rules matter
```

### The "Convert X to Y" Pattern
```
Resource transformation
- Health to damage (blood path)
- Essence to shield (light path)
- Time to power (various)
```

### The "Conditional Bonus" Pattern
```
Situational power
- If health below X, bonus damage
- At night, bonus effect
- Against specific enemy type
```

---

## Balance Guidelines

### Rank 1 Gu
```
Essence Cost: 5-15
Damage (offensive): 10-20
Shield (defensive): 15-25
Duration (buffs): 1-2 turns
```

### Rank 2 Gu
```
Essence Cost: 10-25
Damage (offensive): 15-35
Shield (defensive): 25-45
Duration (buffs): 1-3 turns
```

### Rank 3 Gu
```
Essence Cost: 20-40
Damage (offensive): 30-60
Shield (defensive): 45-75
Duration (buffs): 2-4 turns
```

### Rank 4 Gu
```
Essence Cost: 35-60
Damage (offensive): 50-90
Shield (defensive): 70-110
Duration (buffs): 2-5 turns
```

### Rank 5 Gu
```
Essence Cost: 50-80
Damage (offensive): 80-130
Shield (defensive): 100-160
Duration (buffs): 3-6 turns
```

### Rarity Modifiers
```
Common: Base values
Uncommon: +15% to primary effect
Rare: +30% to primary effect, add secondary effect
Legendary: +50% to primary effect, unique mechanic
```

---

## Example Gu Cards

### Rank 1 Examples

```
┌──────────────────────────────────────┐
│  BASIC FLAME GU                      │
│  Rank 1 | Fire Path | Offensive      │
│  Common                              │
├──────────────────────────────────────┤
│  Cost: 8 Essence                     │
│                                      │
│  Deal 15 fire damage to target.      │
│                                      │
│  "The simplest flame, but fire       │
│   still burns."                      │
│                                      │
│  [Instant] [Single Target]           │
└──────────────────────────────────────┘
```

```
┌──────────────────────────────────────┐
│  SWIFT STEPS GU                      │
│  Rank 1 | Movement | Utility         │
│  Uncommon                            │
├──────────────────────────────────────┤
│  Cost: 10 Essence                    │
│                                      │
│  Reduce travel time by 25%.          │
│  In combat: +10 speed for 2 turns.   │
│                                      │
│  "The journey of a thousand miles    │
│   begins with a swift step."         │
│                                      │
│  [Passive/Active] [Self]             │
└──────────────────────────────────────┘
```

### Rank 3 Examples

```
┌──────────────────────────────────────┐
│  MOONBLADE GU                        │
│  Rank 3 | Light Path | Offensive     │
│  Rare                                │
├──────────────────────────────────────┤
│  Cost: 35 Essence                    │
│                                      │
│  Deal 45 damage to target.           │
│  At night: Deal 65 damage instead.   │
│  Illuminates hidden enemies.         │
│                                      │
│  "Forged from condensed moonlight,   │
│   it cuts through darkness."         │
│                                      │
│  [Instant] [Single Target]           │
└──────────────────────────────────────┘
```

```
┌──────────────────────────────────────┐
│  BLOOD SACRIFICE GU                  │
│  Rank 3 | Blood Path | Utility       │
│  Rare                                │
├──────────────────────────────────────┤
│  Cost: 20 Essence + 30 Health        │
│                                      │
│  Restore 50 Essence.                 │
│  Your next attack deals +40% damage. │
│  Duration: This turn only.           │
│                                      │
│  "Power demands payment in the most  │
│   precious currency: life itself."   │
│                                      │
│  [Instant] [Self]                    │
└──────────────────────────────────────┘
```

### Rank 5 Example

```
┌──────────────────────────────────────┐
│  SOVEREIGN STRENGTH GU               │
│  Rank 5 | Strength Path | Offensive  │
│  Legendary                           │
├──────────────────────────────────────┤
│  Cost: 70 Essence                    │
│                                      │
│  Deal 100 damage to target.          │
│  Ignore 50% of target's defense.     │
│  If this kills, reset cooldown.      │
│  Cooldown: 3 turns                   │
│                                      │
│  "When the sovereign strikes, even   │
│   the heavens tremble."              │
│                                      │
│  [Instant] [Single Target]           │
└──────────────────────────────────────┘
```

---

## Gu Acquisition

### How Players Get Gu

1. **Purchase** - Buy from merchants, markets
2. **Loot** - Drop from enemies, found in locations
3. **Events** - Reward from event choices
4. **Refinement** - Craft from materials + formula
5. **Quest rewards** - Complete missions
6. **Inheritance** - Find caches from past runs
7. **Theft** - Steal from NPCs (demonic)

### Acquisition Rates

Target per game day (at normal activity):
- Common: 0.3-0.5 chances
- Uncommon: 0.1-0.2 chances
- Rare: 0.02-0.05 chances
- Legendary: 0.001-0.005 chances

---

## Gu Maintenance

### Feeding Requirements

Gu must be fed to remain active:

| Rank | Weekly Cost | Special Food |
|------|-------------|--------------|
| 1 | 2 stones | None |
| 2 | 5 stones | None |
| 3 | 12 stones | Path materials preferred |
| 4 | 30 stones | Path materials required |
| 5 | 75 stones | Specific materials |

### Starvation Effects

| Weeks Unfed | Effect |
|-------------|--------|
| 1 | Warning |
| 2 | -50% effectiveness |
| 3 | -75% effectiveness |
| 4 | Gu may die |

### Special Food

Some Gu have specific diet requirements:
- Fire Gu: Fire materials
- Blood Gu: Blood/life materials
- Rare Gu: Specific creature parts

---

## AI Generation Guidelines

### Prompt Requirements

When generating Gu, AI must consider:

1. **Rank-appropriate power**
   - Numbers within balance ranges
   - Complexity appropriate to rank

2. **Path consistency**
   - Themes match the path
   - Mechanics fit path identity
   - Names evoke path aesthetic

3. **Rarity justification**
   - Common = simple, clean effects
   - Legendary = unique, complex, powerful

4. **Interesting design**
   - Not just "deal X damage"
   - Conditional effects
   - Synergy potential
   - Interesting choices

5. **Weakness/limitation**
   - Cost vs benefit
   - Situational drawbacks
   - Counter-play opportunities

### Validation Rules

Generated Gu must pass:
- [ ] Name ends in "Gu"
- [ ] Rank 1-9
- [ ] Valid path name
- [ ] Valid type
- [ ] Cost within range for rank
- [ ] Effect values within range
- [ ] Has flavor text
- [ ] Has at least one weakness noted

---

## Open Questions

- [ ] How many Gu should exist per path per rank?
- [ ] Gu evolution/upgrading system?
- [ ] Gu breeding/combination outside killer moves?
- [ ] Named/unique Gu that appear once per world?
- [ ] Cursed Gu with major drawbacks?
