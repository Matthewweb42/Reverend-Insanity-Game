# Inheritance System [DRAFT]

## Overview

The inheritance system provides meta-progression between runs. When a character dies or achieves victory, they leave behind knowledge, items, and unlocks that benefit future runs.

---

## Core Concept

### Roguelike Meta-Progression

```
Run 1: Die at Rank 3
  └─ Create inheritance: Fire Burst Gu formula

Run 2: Start with fire formula available
  └─ Reach Rank 4, die
  └─ Create inheritance: Killer move "Flame Strike"

Run 3: Start with formula + killer move knowledge
  └─ Progress further...
```

### Philosophy

1. **Every run teaches** - Failure still provides progress
2. **Knowledge persists** - Learned formulas and techniques carry over
3. **Unlocks expand options** - New clans, paths, starting positions
4. **Power doesn't persist** - Can't just accumulate power
5. **Skill improves** - Player gets better, plus meta-unlocks help

---

## Inheritance Creation

### When Inheritance Is Created

- Character death (any cause)
- Character victory (Rank 9 achieved)
- Character retirement (voluntary end)

### Inheritance Points

Points determine how much can be left behind.

**Point Calculation:**
```
Base Points = Highest Rank Reached × 100
Victory Bonus = +500 points
Time Bonus = Days Survived × 0.5
Achievement Bonus = Varies
```

**Example:**
```
Died at Rank 4
Base: 4 × 100 = 400 points
Days: 200 × 0.5 = 100 points
Achievements: Defeated boss (+50)
Total: 550 inheritance points
```

### Spending Inheritance Points

After run ends, spend points to create legacy:

| Inheritance Type | Cost | Effect |
|------------------|------|--------|
| Gu Formula | 50-200 | Formula available in future runs |
| Killer Move | 100-300 | Can learn move faster |
| Resource Cache | 50-150 | Hidden stash in world |
| Path Insight | 75-200 | Attainment boost at start |
| NPC Connection | 100-250 | Start with relationship |
| Location Knowledge | 50-100 | Reveal hidden locations |
| Reputation Seed | 75-150 | Start with reputation bias |

---

## Inheritance Types

### Gu Formula Inheritance

Discover a Gu's creation recipe.

**Effect:** In future runs, can craft this Gu if materials available.

**Access:**
- Formula appears in refinement menu
- Still need materials and refinement skill
- Reduces "discovery" barrier

**Cost Scaling:**
| Gu Rank | Inheritance Cost |
|---------|-----------------|
| Rank 1 | 50 points |
| Rank 2 | 75 points |
| Rank 3 | 125 points |
| Rank 4 | 175 points |
| Rank 5 | 250 points |

### Killer Move Inheritance

Pass down knowledge of a signature technique.

**Effect:** Future characters can learn this move faster.

**Access:**
- Move appears in "inherited techniques" list
- Still need path attainment requirement
- Still need component Gu
- Learning time reduced by 75%

**Cost:** 100 + (Move Rank × 50) points

### Resource Cache Inheritance

Hide resources for future selves.

**Effect:** A hidden cache exists in the world containing resources.

**Cache Contents:**
- Primeval stones (cost: 1 point per 2 stones)
- Materials (cost: varies by rarity)
- Gu worms (cost: same as formula)

**Access:**
- Cache location revealed at start
- Must travel there to claim
- Other NPCs don't know about it

### Path Insight Inheritance

Transfer understanding of a cultivation path.

**Effect:** Start with bonus path attainment.

**Levels:**
| Investment | Starting Attainment |
|------------|---------------------|
| 75 points | Novice (50) |
| 125 points | Adept start (100) |
| 200 points | Expert start (300) |

**Limit:** One path insight per run

### Connection Inheritance

Establish pre-existing NPC relationships.

**Effect:** Start with a friendly NPC connection.

**Options:**
- Merchant ally (trade discounts)
- Information broker (intel access)
- Elder supporter (clan standing help)
- Wandering cultivator (potential combat ally)

**Cost:** 100-250 points based on NPC usefulness

### Location Knowledge

Remember discovered locations.

**Effect:** Hidden locations revealed on map from start.

**Cost:** 50-100 points per location

### Reputation Seed

Carry over reputation tendencies.

**Effect:** Start with +/- reputation points.

**Cost:** 75 points per 10 reputation points

---

## Permanent Unlocks

Some achievements unlock content permanently (no point cost).

### Clan Unlocks

| Unlock Condition | Reward |
|------------------|--------|
| Reach Rank 3 as Gu Yue | Unlock Bai Clan option |
| Reach Rank 4 as any | Unlock Xiong Clan option |
| Reach Rank 5 as any | Unlock Shang Clan option |
| Defeat clan enemy | Unlock that clan |

### Region Unlocks

| Unlock Condition | Reward |
|------------------|--------|
| Reach Rank 5 | Unlock Northern Plains (tribe start) |
| Reach Rank 6 | Unlock Central Continent (sect start) |
| Achieve victory | Unlock random region feature |

### Starting Position Unlocks

| Unlock Condition | Reward |
|------------------|--------|
| Complete run with D-aptitude | Unlock "Prodigy" start (guaranteed B+) |
| Die of old age | Unlock "Young Start" (age 12) |
| Reach Rank 6 | Unlock "Reincarnator" start (memories) |

### Gu Pool Expansions

Certain achievements add Gu to the generation pool:

| Achievement | New Gu Added |
|-------------|--------------|
| First Rank 3 | 5 new Rank 2 Gu types |
| First Rank 5 | 10 new Rank 3-4 Gu types |
| First immortal | Immortal Gu pool unlocked |
| Path mastery | Unique path Gu unlocked |

---

## Inheritance Storage

### Inheritance Vault

Between runs, player has an "Inheritance Vault" showing:

```
┌─────────────────────────────────────────────────────────────┐
│  INHERITANCE VAULT                                          │
├─────────────────────────────────────────────────────────────┤
│  ACCUMULATED LEGACY:                                        │
│                                                             │
│  Gu Formulas Known: 12                                     │
│  ├─ Fire Burst Gu (Rank 2)                                 │
│  ├─ Moonblade Gu (Rank 2)                                  │
│  ├─ Swift Steps Gu (Rank 1)                                │
│  └─ ... [View All]                                         │
│                                                             │
│  Killer Moves: 3                                           │
│  ├─ Flame Strike (Fire, Master)                            │
│  └─ ... [View All]                                         │
│                                                             │
│  Resource Caches: 2 active                                 │
│  Path Insights Available: Blood (Adept)                    │
│                                                             │
│  PERMANENT UNLOCKS:                                         │
│  ├─ Clans: Gu Yue, Bai, Xiong                             │
│  ├─ Regions: Southern Border, Northern Plains              │
│  └─ Special Starts: Young Start, Prodigy                   │
│                                                             │
│  STATISTICS:                                                │
│  ├─ Total Runs: 15                                         │
│  ├─ Victories: 1                                           │
│  ├─ Highest Rank: 7                                        │
│  └─ Total Days Survived: 4,523                             │
└─────────────────────────────────────────────────────────────┘
```

### New Run Selection

When starting new run:

```
┌─────────────────────────────────────────────────────────────┐
│  NEW RUN - SELECT INHERITANCE                               │
├─────────────────────────────────────────────────────────────┤
│  CHARACTER SETUP:                                           │
│  Clan: [Gu Yue ▼]                                          │
│  Region: [Southern Border ▼]                                │
│  Special Start: [Normal ▼]                                  │
│                                                             │
│  INHERITANCE SELECTION:                                     │
│  (Select up to 3 inheritance bonuses)                       │
│                                                             │
│  [ ] Fire Burst Gu Formula                                  │
│  [✓] Swift Steps Gu Formula                                 │
│  [✓] Blood Path Insight (Adept)                            │
│  [ ] Resource Cache #1 (50 stones)                         │
│  [✓] Merchant Wang connection                               │
│  [ ] Flame Strike killer move                               │
│                                                             │
│  Selected: 3/3                                              │
│                                                             │
│  [Start Run]                                                │
└─────────────────────────────────────────────────────────────┘
```

---

## Victory Inheritance

Achieving Rank 9 grants special inheritance options:

### Venerable Legacy

- Unique Gu formula only Venerables can create
- Special starting scenario option
- Venerable-tier killer move inheritance
- +1000 bonus inheritance points

### New Game+ Options

After victory, unlock:
- **Hard Mode** - Enemies scale faster
- **Speed Run Mode** - Reduced time, increased rewards
- **Path Challenge** - Must use specific path
- **Ironman Mode** - No pause, no save-scum

---

## Balance Considerations

### Power Curve Protection

Inheritance should help, not trivialize:

| Protection | Method |
|------------|--------|
| No direct power transfer | Can't inherit Gu items, only formulas |
| Still need materials | Formulas require crafting |
| Attainment caps | Can't start too high |
| Cache limits | Limited resources in caches |
| Slot limits | Can only select 3 per run |

### Catch-Up Mechanics

For struggling players:
- More inheritance points on repeated failures
- "Pity" unlocks after X deaths at same rank
- Tutorial improvements unlock automatically

### Veteran Challenges

For experienced players:
- Challenge modes that disable inheritance
- Achievements for "no inheritance" runs
- Leaderboards by category

---

## Database Schema

```sql
-- Permanent unlocks
CREATE TABLE unlocks (
    id TEXT PRIMARY KEY,
    unlock_type TEXT NOT NULL,  -- 'clan', 'region', 'start', 'gu_pool'
    unlock_id TEXT NOT NULL,
    unlocked_at TIMESTAMP,
    unlock_source TEXT  -- Which run unlocked this
);

-- Available inheritances
CREATE TABLE inheritance_pool (
    id TEXT PRIMARY KEY,
    inheritance_type TEXT NOT NULL,
    data_json TEXT NOT NULL,
    created_by_run TEXT,  -- Save ID that created this
    times_used INTEGER DEFAULT 0
);

-- Run statistics
CREATE TABLE run_history (
    id TEXT PRIMARY KEY,
    character_name TEXT,
    clan TEXT,
    final_rank INTEGER,
    days_survived INTEGER,
    death_cause TEXT,
    inheritance_points_earned INTEGER,
    inheritance_points_spent INTEGER,
    achievements_json TEXT,
    created_at TIMESTAMP,
    ended_at TIMESTAMP
);

-- Cross-run statistics
CREATE TABLE meta_stats (
    key TEXT PRIMARY KEY,
    value TEXT
);
```

---

## Open Questions

- [ ] How many inheritance slots per run?
- [ ] Should inheritance decay over time/runs?
- [ ] Can players "respec" inheritance choices?
- [ ] Sharing inheritances in multiplayer?
- [ ] Achievement-based inheritance bonuses?
