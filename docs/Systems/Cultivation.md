# Cultivation System [FINAL]

## Overview

Cultivation is the core progression mechanic. Players actively cultivate to advance through ranks and stages, consuming resources and time. There is no passive cultivation - progress only happens when the player chooses to cultivate. Progress slowly decays when not cultivating, creating pressure to maintain momentum.

---

## Rank & Stage Structure

### Mortal Realm (Ranks 1-5)

Each rank contains four stages: **Initial → Middle → Upper → Peak**

| Rank | Title | Aperture Slots | Max Essence | Essence Color |
|------|-------|----------------|-------------|---------------|
| 1 | Initial Stage | 10 | 100 | Green Copper |
| 2 | Middle Stage | 20 | 200 | Red Steel |
| 3 | Upper Stage | 30 | 350 | White Silver |
| 4 | Peak Stage | 40 | 500 | Yellow Gold |
| 5 | Quasi-Master | 50 | 700 | Purple Crystal |

### Immortal Realm (Ranks 6-9)

Immortals no longer have sub-stages. Advancement depends on tribulations.

| Rank | Title | Aperture Slots | Max Essence | Notes |
|------|-------|----------------|-------------|-------|
| 6 | Gu Immortal | 100 | 2000 | Receives blessed land |
| 7 | Venerable | 150 | 5000 | Regional power |
| 8 | Great Grandmaster | 200 | 10000 | World-shaping |
| 9 | Supreme Venerable | 300 | 50000 | Victory condition |

### Full Progression Path

```
Rank 1: Initial → Middle → Upper → Peak → [Rank Breakthrough]
Rank 2: Initial → Middle → Upper → Peak → [Rank Breakthrough]
Rank 3: Initial → Middle → Upper → Peak → [Rank Breakthrough]
Rank 4: Initial → Middle → Upper → Peak → [Rank Breakthrough]
Rank 5: Initial → Middle → Upper → Peak → [Tribulation]
Rank 6-9: No sub-stages, tribulation-based advancement
```

**Total mortal transitions:** 20 stage advances (16 stage breakthroughs + 4 rank breakthroughs)

---

## Cultivation Progress

### Progress Points Per Stage

Each stage requires accumulating cultivation points. Earlier stages are fast; later stages take years.

| Rank | Init→Mid | Mid→Up | Up→Peak | Peak→Next Rank | Rank Total |
|------|----------|--------|---------|----------------|------------|
| 1 | 50 | 75 | 100 | 150 | 375 |
| 2 | 100 | 150 | 200 | 300 | 750 |
| 3 | 200 | 300 | 400 | 600 | 1,500 |
| 4 | 400 | 600 | 800 | 1,200 | 3,000 |
| 5 | 800 | 1,200 | 1,800 | Tribulation | 3,800 |

**Grand Total (Rank 1 Initial → Rank 5 Peak):** 9,425 points

### Timeline Estimates

At standard cultivation (1 point/day, C-grade aptitude):

| Rank | Points | Days | Years |
|------|--------|------|-------|
| 1 | 375 | 375 | ~1 |
| 2 | 750 | 750 | ~2 |
| 3 | 1,500 | 1,500 | ~4 |
| 4 | 3,000 | 3,000 | ~8 |
| 5 | 3,800 | 3,800 | ~10 |
| **Total** | **9,425** | **9,425** | **~26** |

**With real-world factors** (failures, breaks, resource issues): **~35-40 years**

---

## Daily Progress Formula

```
Daily Progress = Base Rate × Aptitude × Age Modifier × Gu Bonus
```

### Base Rate (Resource Tiers)

| Intensity | Stones/Day | Base Progress |
|-----------|------------|---------------|
| None | 0 | 0.25 points |
| Minimal | 2 | 0.5 points |
| Standard | 5 | 1.0 points |
| Intensive | 15 | 1.75 points |
| Maximum | 30+ | 2.5 points |

### Aptitude Modifier (Significant Impact)

| Aptitude | Modifier | Breakthrough Bonus | Distribution |
|----------|----------|-------------------|--------------|
| A-grade | 1.5x | +15% (rank), +5% (stage) | 5% |
| B-grade | 1.2x | +8% (rank), +3% (stage) | 15% |
| C-grade | 1.0x | +0% | 30% |
| D-grade | 0.7x | -10% (rank), -5% (stage) | 50% |

**A-grade vs D-grade:** 114% faster cultivation, 25% better breakthrough odds

### Age Modifier (Percentage-Based)

Uses lifespan percentage remaining, not absolute age.

| Life % Remaining | Status | Cultivation Modifier |
|------------------|--------|---------------------|
| 50%+ | Prime | 1.0x |
| 30-50% | First Signs | 0.95x |
| 15-30% | Decline | 0.85x |
| 5-15% | Severe | 0.65x |
| 0-5% | Death's Door | 0.4x |

### Gu Bonus

| Gu Type | Modifier |
|---------|----------|
| No cultivation Gu | 1.0x |
| Common cultivation Gu | 1.2x |
| Uncommon cultivation Gu | 1.5x |
| Rare cultivation Gu | 1.8x |
| Legendary cultivation Gu | 2.0x+ |

### Example Calculations

**C-grade, Standard resources, Prime age, No Gu:**
```
1.0 × 1.0 × 1.0 × 1.0 = 1.0 point/day
Rank 2 (750 points) = 750 days = ~2 years
```

**A-grade, Intensive resources, Prime age, Uncommon Gu:**
```
1.75 × 1.5 × 1.0 × 1.5 = 3.94 points/day
Rank 2 (750 points) = 190 days = ~6 months
```

**D-grade, Minimal resources, Decline age, No Gu:**
```
0.5 × 0.7 × 0.85 × 1.0 = 0.30 points/day
Rank 2 (750 points) = 2,500 days = ~7 years
```

---

## Cultivation Decay

When not actively cultivating, progress slowly decays.

| Activity State | Daily Decay |
|----------------|-------------|
| Idle (doing nothing) | -0.5 points |
| Active (travel, combat, events) | -0.25 points |
| With Preservation Gu | -0.1 points |
| Cultivating | No decay (gaining) |

### Decay Rules

- **Cannot drop stages:** Progress floors at 0 within current stage
- **Cannot lose ranks:** Once achieved, rank/stage is permanent
- **Creates pressure:** Must cultivate regularly or find preservation Gu

### Example

Player at Rank 2 Middle, 150/200 points toward Upper stage:
- Stops cultivating for 100 days while traveling (-25 points)
- Progress drops to 125/200
- **Cannot drop below 0/200** (stays at Middle stage)

---

## Cultivation States

### Idle
- Not cultivating
- No progress gained
- Decay applies
- Can do other activities freely

### Active Cultivation
- Manually activated
- Progress accumulates based on formula
- Resources consumed per day
- Can still respond to events
- Can be interrupted

### Closed Door Cultivation
- Deep focus state
- **25x time acceleration** (125 days per real second)
- Same progress rate per day (no bonus)
- No decay during closed door
- Events queue up (may expire)
- Cannot be interrupted except emergencies
- Exit manually or when resources depleted

**Trade-off:** Faster real-time progress, but miss events and age faster

---

## Breakthrough System

### When to Attempt

- Reach 100% progress in current stage
- Breakthrough attempt becomes available
- Can wait at 100% for preparation bonuses

### Stage Breakthroughs (Within Rank)

Advancing Initial→Middle, Middle→Upper, Upper→Peak

| Transition | Base Success |
|------------|--------------|
| Initial → Middle | 95% |
| Middle → Upper | 85% |
| Upper → Peak | 75% |

### Rank Breakthroughs (Major)

Advancing from Rank X Peak to Rank X+1 Initial

| Transition | Base Success |
|------------|--------------|
| Rank 1 → 2 | 70% |
| Rank 2 → 3 | 55% |
| Rank 3 → 4 | 40% |
| Rank 4 → 5 | 25% |
| Rank 5 → 6 | 10% + Tribulation |

### Breakthrough Modifiers

**Positive Modifiers:**

| Factor | Stage Bonus | Rank Bonus |
|--------|-------------|------------|
| A-grade aptitude | +5% | +15% |
| B-grade aptitude | +3% | +8% |
| Breakthrough Gu | +5-15% | +10-25% |
| Mentor guidance | +3-8% | +5-15% |
| Path attainment (per level) | +1% | +3% |
| Wait at 100% | +0.5%/month (max +5%) | +1%/month (max +10%) |
| Special resources | +3-10% | +5-15% |

**Negative Modifiers:**

| Factor | Stage Penalty | Rank Penalty |
|--------|---------------|--------------|
| D-grade aptitude | -5% | -10% |
| Age (Decline+) | -3% | -5% |
| Injured | -10% | -15% |

### Breakthrough Outcomes

**Success:**
- Advance to next stage/rank
- If rank up: Aperture expands, essence cap increases
- Possible celebration event

**Stage Failure:**
- Progress reset to 70% of requirement
- Can retry immediately
- No other penalties

**Rank Failure:**
- Progress reset to 50% of requirement
- 25% chance of injury
- 30-day cooldown before retry
- If injured: must heal before next attempt

**Critical Failure (5% of all failures):**
- Progress reset to 25% of requirement
- Injury guaranteed
- 10% chance: lose 1-2 aperture slots permanently
- 1% chance: death

### Breakthrough UI

```
┌─────────────────────────────────────────┐
│  BREAKTHROUGH TO RANK 3                 │
├─────────────────────────────────────────┤
│  Current: Rank 2 Peak (100%)            │
│  Base Success Rate: 55%                 │
│                                         │
│  Modifiers:                             │
│  + B-grade Aptitude: +8%                │
│  + Breakthrough Gu: +12%                │
│  + Waited 2 months: +2%                 │
│  - Age (First Signs): -0%               │
│                                         │
│  Final Success Rate: 77%                │
│                                         │
│  [Attempt Breakthrough]  [Wait Longer]  │
└─────────────────────────────────────────┘
```

---

## Special Cultivation Items

### Relic Gu

Instantly advance one stage within current rank.

| Gu | Effect | Rarity |
|----|--------|--------|
| Rank 1 Relic Gu | +1 stage in Rank 1 | Rare |
| Rank 2 Relic Gu | +1 stage in Rank 2 | Rare |
| Rank 3 Relic Gu | +1 stage in Rank 3 | Very Rare |
| Rank 4 Relic Gu | +1 stage in Rank 4 | Legendary |
| Rank 5 Relic Gu | +1 stage in Rank 5 | Legendary |

**Rules:**
- Can be used in succession (3 Relics = Initial → Peak)
- **Cannot cross rank boundaries** (cannot go Rank 2 Peak → Rank 3 Initial)
- Still need breakthrough attempt for rank advancement
- Skips cultivation time, not breakthrough risk
- Extremely valuable - NPCs will kill for these

### Cultivation Gu

| Gu | Effect | Rarity |
|----|--------|--------|
| Essence Gathering Gu | +20% cultivation progress | Common |
| Focus Mind Gu | Reduce decay by 50% | Uncommon |
| Breakthrough Assistance Gu | +15% breakthrough success | Rare |
| Aptitude Enhancement Gu | Temporarily improve aptitude one grade | Legendary |
| Cultivation Acceleration Gu | +50% cultivation progress | Rare |

### Preservation Gu

| Gu | Effect | Rarity |
|----|--------|--------|
| Progress Shield Gu | Reduce decay to -0.1/day | Uncommon |
| Stasis Gu | No decay while equipped | Rare |

---

## Character Creation: Blessings & Burdens

Before the game starts, players choose their starting situation. Better starts come with obligations and enemies.

### Wealth Options

| Choice | Stones | Starting Gu | Burden |
|--------|--------|-------------|--------|
| Destitute | 10 | None | None |
| Poor | 30 | 1 common | None |
| Modest | 75 | 2 common | Monthly tribute (5 stones) |
| Comfortable | 150 | 3 common, 1 uncommon | Mission quota, tribute |
| Wealthy | 300 | 4 common, 2 uncommon | Heavy quota, rivals |
| Heir | 500 | 5 common, 3 uncommon, 1 rare | Political enemies, assassination risk |

### Connection Options

| Choice | Starting Relationships | Burden |
|--------|----------------------|--------|
| Orphan | None | None - invisible |
| Loner | 1 neutral contact | None |
| Known | 2 contacts, 1 friendly | Minor expectations |
| Connected | 3 contacts, 2 friendly | Social obligations |
| Prominent | 4 contacts, 3 friendly, mentor | Expectations, 1 rival |
| Famous | 5+ contacts, mentor, patron | Spotlight, 2+ rivals |

### Starting Progress Options

| Choice | Starting Point | Age | Burden |
|--------|---------------|-----|--------|
| Fresh Start | Rank 1 Initial, 0% | 15 | None |
| Some Training | Rank 1 Middle, 50% | 16 | None |
| Clan Youth | Rank 1 Peak, 75% | 18 | Clan obligations |
| Junior | Rank 2 Initial, 25% | 20 | Mission quota |
| Established | Rank 2 Upper, 50% | 28 | Heavy obligations |
| Veteran | Rank 3 Initial, 0% | 35 | Serious obligations, enemies |

### Aptitude Options

| Choice | Effect | Burden |
|--------|--------|--------|
| Roll Randomly | 50% D, 30% C, 15% B, 5% A | None |
| Guarantee C | C-grade | None |
| Guarantee B | B-grade | 1 jealous rival |
| Guarantee A | A-grade | 2 rivals, clan pressure, high expectations |

---

## Immortal Cultivation (Rank 6+)

### Rank 5 → 6: Tribulation

Reaching Rank 5 Peak does not automatically allow immortal ascension. Must face the **Earthly Calamity**.

**Tribulation Components:**
1. **Heaven Tribulation** - Combat/survival challenge
2. **Earth Tribulation** - Resource/endurance test
3. **Human Tribulation** - Social/political challenge

**Success Requirements:**
- Rank 5 Peak with 100% progress
- Massive resource preparation
- Path specialization choice
- Survive all three tribulation phases

**Outcomes:**
- **Success:** Become Rank 6 Immortal, receive blessed land
- **Failure:** Death (run ends, inheritance triggers)
- **Partial:** Survive damaged, weakened immortal start

### Immortal Advancement

| Transition | Requirements |
|------------|--------------|
| Rank 6 → 7 | ~300 years, survive 3 heavenly tribulations |
| Rank 7 → 8 | ~300 years, survive 3 grand tribulations |
| Rank 8 → 9 | Special conditions, ultimate tribulation |

---

## Path Attainment

Attainment represents mastery of a cultivation path's principles and techniques. Unlike rank, attainment is extremely difficult to raise and most cultivators remain at Ordinary their entire lives.

### Attainment Levels

| Level | Description | Rarity |
|-------|-------------|--------|
| **Ordinary** | Basic understanding of path principles | ~70% of cultivators |
| **Master** | Deep expertise, can create killer moves | ~25-30% of cultivators |
| **Quasi-Grandmaster** | Exceptional mastery, approaching pinnacle | <1% of cultivators |
| **Grandmaster** | Pinnacle of mortal understanding | A handful per generation |
| **Quasi-Great Grandmaster** | Legendary, immortal-level insight | Extremely rare |
| **Great Grandmaster** | Supreme mastery, unparalleled | ~4 ever in Refinement Path |

**Note:** The jump from Master to Quasi-Grandmaster is immense. Many Masters spend centuries trying and never succeed.

### Attainment Benefits

| Level | Combat Bonus | Gu/Turn | Special Abilities |
|-------|-------------|---------|-------------------|
| Ordinary | None | 1-2 | Basic Gu usage |
| Master | +10% path damage | 3-4 | Killer moves |
| Quasi-Grandmaster | +20% path damage | 5 | Advanced killer moves |
| Grandmaster | +35% path damage | 6 | Supreme killer moves, create new techniques |
| Quasi-Great Grandmaster | +50% path damage | 7 | Unique abilities, inspire others |
| Great Grandmaster | +75% path damage | 8+ | Path-defining abilities |

### Raising Attainment

Attainment increases through:
- **Study** - Reading path manuals, analyzing techniques
- **Practice** - Using path Gu in combat and refinement
- **Insight** - Rare breakthrough moments from experience
- **Inheritance** - Learning from attainment-boosting legacies
- **Time** - Years of dedication to a single path

**Expected Timeline:**
- Ordinary → Master: 10-30 years of focused study (many never achieve)
- Master → Quasi-Grandmaster: 50-100 years, exceptional talent required
- Quasi-Grandmaster → Grandmaster: 100+ years, legendary achievement
- Beyond Grandmaster: Measured in centuries, often requires immortality

### Multiple Paths

Players can have attainment in multiple paths, but:
- Time investment splits between paths
- Most successful cultivators focus on 1-2 primary paths
- Jack-of-all-trades rarely reach Master in any path
- Some paths synergize (e.g., Refinement + any path)

---

## Primeval Essence

### Aperture Essence Pool

- Essence is the resource for Gu activation
- Regenerates outside of combat
- Does NOT regenerate during combat
- Capacity increases with rank

### Essence Regeneration

| State | Regen Rate |
|-------|------------|
| Idle | 10% of max per hour |
| Resting | 20% of max per hour |
| With Gu | Up to 50% of max per hour |
| In Combat | 0% |

**Full regeneration:** 2-10 hours depending on bonuses

---

## UI Elements

### Cultivation Panel

```
┌─────────────────────────────────────────┐
│  CULTIVATION                            │
├─────────────────────────────────────────┤
│  Rank 3 - Upper Stage                   │
│  Progress: ████████████░░░░░░ 285/400   │
│                                         │
│  Daily Rate: 1.8 points/day             │
│  Est. to 100%: 64 days                  │
│                                         │
│  Aperture: 24/30 slots                  │
│  Essence: 280/350                       │
│                                         │
│  Decay if idle: -0.5/day                │
├─────────────────────────────────────────┤
│  [Cultivate]  [Closed Door]             │
└─────────────────────────────────────────┘
```

### Active Cultivation Display

```
┌─────────────────────────────────────────┐
│  ⚡ CULTIVATING                          │
│  +1.8 points/day                        │
│  -5 primeval stones/day                 │
│                                         │
│  Session: 12 days elapsed               │
│  Progress gained: +21.6 points          │
│                                         │
│  [Stop Cultivation]                     │
└─────────────────────────────────────────┘
```

### Closed Door Display

```
┌─────────────────────────────────────────┐
│  🔒 CLOSED DOOR CULTIVATION             │
│  Time: 25x speed                        │
│  Session: 2.3 years elapsed             │
│                                         │
│  Progress gained: +1,512 points         │
│  Resources consumed: 4,200 stones       │
│  Events queued: 7                       │
│                                         │
│  [Exit Closed Door]                     │
└─────────────────────────────────────────┘
```

---

## Implementation Notes

### CultivationManager State

```gdscript
# Player cultivation data
var current_rank: int = 1
var current_stage: int = 0  # 0=Initial, 1=Middle, 2=Upper, 3=Peak
var stage_progress: float = 0.0
var stage_requirement: float = 50.0  # Points needed for current stage

var aptitude: String = "C"  # A, B, C, D
var cultivation_intensity: int = 2  # 0-4 (none to maximum)
var is_cultivating: bool = false
var is_closed_door: bool = false

# Calculated values
func get_daily_progress() -> float:
    var base = [0.25, 0.5, 1.0, 1.75, 2.5][cultivation_intensity]
    var apt_mod = {"A": 1.5, "B": 1.2, "C": 1.0, "D": 0.7}[aptitude]
    var age_mod = get_age_modifier()
    var gu_mod = get_cultivation_gu_modifier()
    return base * apt_mod * age_mod * gu_mod

func get_daily_decay() -> float:
    if is_cultivating or is_closed_door:
        return 0.0
    var base_decay = 0.5 if is_idle else 0.25
    return base_decay * get_preservation_modifier()
```

### Stage Requirement Lookup

```gdscript
const STAGE_REQUIREMENTS = {
    1: [50, 75, 100, 150],    # Rank 1 stages
    2: [100, 150, 200, 300],  # Rank 2 stages
    3: [200, 300, 400, 600],  # Rank 3 stages
    4: [400, 600, 800, 1200], # Rank 4 stages
    5: [800, 1200, 1800, 0],  # Rank 5 stages (0 = tribulation)
}

func get_stage_requirement(rank: int, stage: int) -> float:
    return STAGE_REQUIREMENTS[rank][stage]
```

---

## Resolved Questions

- [x] Progress points vs percentage: Points internally, display as percentage
- [x] Stage requirements: Scaling difficulty (50 → 1800)
- [x] Decay: -0.5/day idle, cannot drop stages
- [x] Aptitude impact: Significant (0.7x to 1.5x)
- [x] Breakthrough: Dice roll with preparation bonuses
- [x] Closed door: 25x time skip, no progress bonus
- [x] Relic Gu: Instant stage advance, cannot cross ranks
- [x] Character creation: Blessings & Burdens system

## Remaining Questions

- [ ] Exact immortal tribulation mechanics
- [ ] Path specialization details at Rank 5
- [ ] Multiplayer cultivation interactions
