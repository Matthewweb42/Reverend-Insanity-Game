# Time System [FINAL]

## Overview

Real-time with pause is the core flow of the game. Time creates pressure through aging, travel costs, and opportunity windows. Players can pause anytime and adjust game speed.

---

## Core Concepts

### Real-Time Flow

- Game time flows continuously when unpaused
- Days tick by visibly on screen
- All activities happen within this time flow
- Events trigger during real-time (not turn-based)

### Pause Functionality

- Pause anytime with spacebar/button
- While paused:
  - Review information
  - Make decisions
  - Queue actions
  - Read events
- Unpause to execute and continue

### Time Speed

| Speed | Days per Real Second | Years per Real Minute | Use Case |
|-------|---------------------|----------------------|----------|
| 1x | 5 days | ~0.82 years | Careful play, reading events |
| 2x | 10 days | ~1.64 years | Normal gameplay |
| 5x | 25 days | ~4.1 years | Waiting, light activity |
| 10x | 50 days | ~8.2 years | Fast travel, time skips |
| Closed Door | 125 days (25x) | ~20.5 years | Pure cultivation focus |

---

## Time Units

### Game Time Structure

```
1 Game Year = 365 Days
1 Real Second = 5 Game Days (at 1x speed)

Real Time → Game Time (at 1x speed):
1 real second = 5 game days
1 real minute = 300 game days (~0.82 years)
1 real hour = ~49 game years
2 real hours = ~100 game years
```

### Display Format

```
Year 3, Day 47
Age: 18 years
Lifespan: 100 years (82 remaining)
[████████████████░░░░] 82%
```

---

## Run Timeline

### Full Run Structure

```
FULL SUCCESSFUL RUN: Rank 1 → Rank 9 (Venerable)
Total: ~600+ game years, ~6+ real hours (at average speed)

EARLY GAME (Mortal Stage): Rank 1-5
├── ~30-40 game years
├── ~45 real minutes (at ~5x average)
└── Goal: Survive, build foundation, prepare for tribulation

MID GAME (Immortal Stage): Rank 6-7
├── ~200-300 game years
├── ~2-3 real hours
└── Goal: Build power base, manage blessed land

LATE GAME (Venerable Path): Rank 8-9
├── ~300-400 game years
├── ~2-3 real hours
└── Goal: Achieve supreme power, reach Venerable
```

### Progression Milestones

| Milestone | Game Years | Real Time (5x avg) |
|-----------|------------|-------------------|
| Rank 1 → 2 | 5-10 years | 6-12 min |
| Rank 2 → 3 | 10-15 years | 12-18 min |
| Rank 3 → 4 | 15-25 years | 18-30 min |
| Rank 4 → 5 | 20-30 years | 24-36 min |
| **Mortal Complete** | **30-40 years** | **~45 min** |
| Tribulation + Rank 6 | 50-70 years | ~1 hour |
| **Immortal at** | **~100 years** | **~1.5 hours** |
| Rank 6 → 7 | 100-150 years | ~1 hour |
| Rank 7 → 8 | 150-200 years | ~1.5 hours |
| Rank 8 → 9 | 200-300 years | ~2 hours |
| **Venerable at** | **~600 years** | **~6 hours** |

---

## Lifespan System

### Core Rules

- **Base Lifespan:** 100 years for all cultivators
- **Starting Age:** 15 years old (default)
- **NO lifespan from rank advancement** - Must actively acquire extensions
- **Lifespan is a scarce resource** that must be managed

### Lifespan Extension Methods

#### Righteous Path: Lifespan Gu

Pure extensions with no drawbacks. Extremely valuable and rare.

| Gu Type | Years Added | Rarity | Typical Cost |
|---------|-------------|--------|--------------|
| Minor Lifespan Gu | +5 years | Uncommon | 200-400 stones |
| Lesser Lifespan Gu | +10 years | Rare | 800-1500 stones |
| Standard Lifespan Gu | +15 years | Rare | 2000-4000 stones |
| Greater Lifespan Gu | +50 years | Legendary | 15000+ stones |
| Supreme Lifespan Gu | +100 years | Legendary | Quest reward / 50000+ |

**Expected acquisition:**
- Mortal stage (~40 years): 1-2 small ones (+10-20 years if lucky)
- Early Immortal: 2-4 various (+30-80 years)
- Late Immortal: Access to larger ones through politics, blessed land

**Key trait:** NPCs desperately want these too. Having one makes you a target.

#### Demonic Path: Blood and Sacrifice

Higher availability but severe consequences.

**Aperture Plundering:**
```
Effect: Steal 20-50% of victim's remaining lifespan
Requirements: Kill Gu Master, Aperture Theft Gu, within 2 ranks
Consequences:
  - Reputation: -30 to -50
  - Victim's connections become hostile
  - 20% chance: Karmic backlash (random negative event)
  - Diminishing returns with repeated use
```

**Blood Sacrifice Ritual:**
```
Effect: +5-15 years per ritual
Requirements: Blood Path Adept+, sacrifice materials
Consequences:
  - Reputation: -20 per ritual
  - Righteous factions may hunt you
  - Cultivation corruption: -5% breakthrough chance per use
  - Soul damage after 5+ uses
```

**Soul Consumption:**
```
Effect: +5-10 years per soul
Requirements: Soul Path Expert+, captured souls
Consequences:
  - Random madness events
  - Cumulative combat penalties
  - Soul instability
```

#### Demonic-Only Advanced Methods

For players deeply committed to the demonic path (reputation -50 or lower):

| Method | Years | Requirements |
|--------|-------|--------------|
| Mass Blood Harvest | +30-50 | Blood Path Master, major ritual |
| Venerable's Fragment | +50-100 | Find demonic inheritance |
| Life Gu Refinement | +20-40 | Refinement + Blood Expert |
| Heaven Defying Pill | +25 | Demonic faction rank reward |

#### Desperate Option: Zombie Transformation

```
Effect: Unlimited lifespan
Requirements: Zombie Gu (legendary), willingness to transform
Permanent Changes:
  - New "Zombie" status with different mechanics
  - Cannot use most healing
  - Social interactions severely limited
  - Some paths enhanced, others blocked
  - Righteous factions KOS
  - Essentially different playstyle
Note: Only used as absolute last resort
```

**Important:** Lifespan Gu ALWAYS works regardless of demonic methods used. Other factors may lock you into the demonic path, but pure Lifespan Gu remains available.

---

## Aging System

### Percentage-Based Penalties

Aging penalties scale with current maximum lifespan, not absolute age.

| Life % Remaining | Cultivation Penalty | Combat Penalty | Status |
|------------------|--------------------:|---------------:|--------|
| 50%+ | None | None | Prime Years |
| 30-50% | -5% | None | First Signs |
| 15-30% | -15% | -5% | Noticeable Decline |
| 5-15% | -35% | -15% | Severe Decline |
| 0-5% | -60% | -30% | Death's Door |

### Examples at Different Lifespans

**100 Year Lifespan (Base):**
| Age | Status | Penalties |
|-----|--------|-----------|
| 15-50 | Prime | None |
| 50-70 | First Signs | -5% cult |
| 70-85 | Decline | -15% cult, -5% combat |
| 85-95 | Severe | -35% cult, -15% combat |
| 95-100 | Death's Door | -60% cult, -30% combat |

**200 Year Lifespan (After Extensions):**
| Age | Status | Penalties |
|-----|--------|-----------|
| 15-100 | Prime | None |
| 100-140 | First Signs | -5% cult |
| 140-170 | Decline | -15% cult, -5% combat |
| 170-190 | Severe | -35% cult, -15% combat |
| 190-200 | Death's Door | -60% cult, -30% combat |

**600 Year Lifespan (Late Game):**
| Age | Status | Penalties |
|-----|--------|-----------|
| 15-300 | Prime | None |
| 300-420 | First Signs | -5% cult |
| 420-510 | Decline | -15% cult, -5% combat |
| 510-570 | Severe | -35% cult, -15% combat |
| 570-600 | Death's Door | -60% cult, -30% combat |

### Formula

```
remaining_percent = (max_lifespan - current_age) / max_lifespan

if remaining_percent > 0.50: status = "prime"
elif remaining_percent > 0.30: status = "first_signs"
elif remaining_percent > 0.15: status = "decline"
elif remaining_percent > 0.05: status = "severe"
else: status = "deaths_door"
```

---

## Death System

### Death's Door

When entering the final 5% of lifespan:

- Severe stat penalties (-60% cultivation, -30% combat)
- Visual warning (screen effects, UI indicator)
- Random "final decline" events:
  - Sudden weakness (temporary further debuff)
  - Moments of clarity (brief penalty removal)
  - Last regrets (story/character moments)
- Duration: 5% of max lifespan (5 years at 100, 30 years at 600)

### Final Event

When lifespan reaches exactly 0, death triggers a **Final Event**:

```
YOUR LIFE REACHES ITS END

[Narrative moment describing the character's final moments]

Options:
├── [Accept Death]
│   └── Proceed to inheritance creation, run ends
├── [Desperate Measure] (if Zombie Gu available)
│   └── Transform into zombie, continue with new mechanics
├── [Final Gambit] (if demonic method available)
│   └── One last attempt at life extension
└── [Rage Against Fate] (special conditions)
    └── Rare option for specific builds/items
```

Death is a meaningful narrative moment, not an abrupt end.

---

## Closed Door Cultivation

### Mechanics

- **Speed:** 25x normal time (125 days per real second)
- **Purpose:** Focused cultivation with accelerated progress
- **Trade-offs:**
  - Miss events (queued but may expire)
  - Age faster (time still passes)
  - Resource drain accelerated
  - Cannot respond to emergencies

### Time Impact

| Real Time in Closed Door | Game Time Passed |
|-------------------------|------------------|
| 1 minute | ~2 years |
| 5 minutes | ~10 years |
| 10 minutes | ~20 years |
| 30 minutes | ~60 years |

### Exit Conditions

- Manual exit by player
- Resources depleted
- Emergency event (can force exit for critical events)
- Lifespan danger threshold reached

---

## Time-Consuming Activities

### Cultivation

```
Base cultivation: Variable progress per day based on resources
Closed door: 25x time acceleration, focused progress
No passive cultivation - must be actively chosen
```

### Travel

| Journey Type | Base Time | With Movement Gu |
|--------------|-----------|------------------|
| Within location | Instant | Instant |
| Adjacent locations | 3-5 days | 1-2 days |
| Distant locations | 10-20 days | 3-7 days |
| Across regions | 30-60 days | 10-20 days |

Events can trigger during travel - traveling is not safe.

### Study (Path Attainment)

```
Study session: 1-7 days per session
Longer sessions = more efficient gains
Requires materials or teachers for best results
```

### Refinement

```
Rank 1-2 Gu: 1-3 days
Rank 3 Gu: 3-7 days
Rank 4 Gu: 7-14 days
Rank 5 Gu: 14-30 days
Success not guaranteed
```

---

## Event Timing

### Event Frequency

Target: 1-3 meaningful events per game day at 1x speed

At higher speeds, events queue rather than interrupt constantly.

### Event Windows

Some events have time limits:
```
"A merchant caravan is passing through."
[Expires in: 3 days]
```

Expired events are lost opportunities.

### Event Queue

During closed door cultivation or fast speeds:
- Events accumulate in queue
- Player reviews when available
- Critical events may force attention
- Some events expire if not addressed

---

## UI Elements

### Time Display (HUD)

```
┌────────────────────────────────────────┐
│  ▶ Year 3, Day 47              [5x]   │
│  Age: 18 | Lifespan: 100              │
│  [████████████████░░░░] 82 years left │
│  [1x] [2x] [5x] [10x] [⏸]            │
└────────────────────────────────────────┘
```

### Closed Door Panel

```
┌────────────────────────────────────────┐
│  ⚡ CLOSED DOOR CULTIVATION            │
│  Time Scale: 25x                       │
│  Session: 3 years elapsed              │
│                                        │
│  Cultivation Progress: +145 points     │
│  Resources Consumed: 230 stones        │
│  Events Queued: 4                      │
│                                        │
│  [Exit Closed Door]                    │
└────────────────────────────────────────┘
```

### Death's Door Warning

```
┌────────────────────────────────────────┐
│  ⚠️ DEATH'S DOOR                       │
│  Lifespan: 3 years remaining           │
│                                        │
│  Your body fails. Time runs short.     │
│  Seek lifespan extension immediately.  │
│                                        │
│  Penalties: -60% Cult, -30% Combat     │
└────────────────────────────────────────┘
```

---

## Implementation Notes

### TimeManager State

```gdscript
# TimeManager.gd (Autoload)

var current_day: int = 1
var current_year: int = 1

var days_per_second: float = 5.0  # Base rate at 1x
var time_scale: float = 1.0  # 1x, 2x, 5x, 10x
var is_paused: bool = true
var is_closed_door: bool = false
var closed_door_multiplier: float = 25.0

var accumulated_time: float = 0.0

signal day_passed(day, year)
signal year_passed(year)
signal time_paused
signal time_unpaused
signal entered_deaths_door
signal lifespan_zero
```

### Core Loop

```gdscript
func _process(delta: float) -> void:
    if is_paused:
        return

    var effective_rate = days_per_second * time_scale
    if is_closed_door:
        effective_rate *= closed_door_multiplier

    accumulated_time += delta * effective_rate

    while accumulated_time >= 1.0:  # 1 day
        accumulated_time -= 1.0
        advance_day()

func advance_day() -> void:
    current_day += 1

    if current_day > 365:
        current_day = 1
        advance_year()

    emit_signal("day_passed", current_day, current_year)
    check_events()
    process_daily_activities()

func advance_year() -> void:
    current_year += 1
    emit_signal("year_passed", current_year)
    GameState.player.age += 1
    check_lifespan_status()
```

---

## Resolved Questions

- [x] Time scale: 5 days per real second at 1x
- [x] Full run length: ~6+ hours real time
- [x] Lifespan from rank: None - must acquire extensions
- [x] Aging penalties: Percentage-based, scales with max lifespan
- [x] Closed door speed: 25x multiplier
- [x] Death handling: Triggers final narrative event

## Remaining Questions

- [ ] Night/day cycle effects on gameplay?
- [ ] Seasonal effects (spring/summer/autumn/winter)?
- [ ] How does multiplayer affect time flow?
- [ ] Calendar events (annual festivals, competitions)?
