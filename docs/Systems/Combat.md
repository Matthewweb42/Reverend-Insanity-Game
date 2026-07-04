# Combat System [FINAL]

## Overview

Turn-based stat-based combat where players use Gu from their aperture to defeat enemies. Combat rewards preparation, intelligence gathering, and build optimization. No positioning - resolution is based on stats like accuracy, evasion, and various defenses.

---

## Combat Flow

```
┌─────────────────────────────────────────────────────────────┐
│                      COMBAT ENCOUNTER                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. TRIGGER                                                 │
│     └─ Event, travel encounter, or player-initiated        │
│                                                             │
│  2. SETUP                                                   │
│     └─ Load player aperture as hand                         │
│     └─ Generate/load enemy loadout                          │
│     └─ Apply preparation bonuses (if any)                   │
│                                                             │
│  3. COMBAT LOOP                                             │
│     ┌─────────────────────────────────────────────────┐    │
│     │  Player Turn                                     │    │
│     │  └─ View hand (Gu available)                     │    │
│     │  └─ Play Gu card(s) - costs essence              │    │
│     │  └─ Use killer moves (if available)              │    │
│     │  └─ End turn                                     │    │
│     │                                                  │    │
│     │  Enemy Turn                                      │    │
│     │  └─ AI selects action based on behavior          │    │
│     │  └─ Executes Gu abilities                        │    │
│     │  └─ Turn ends                                    │    │
│     │                                                  │    │
│     │  Check Win/Lose Conditions                       │    │
│     └─────────────────────────────────────────────────┘    │
│     └─ Repeat until resolution                              │
│                                                             │
│  4. RESOLUTION                                              │
│     └─ Victory: rewards, loot, reputation                   │
│     └─ Defeat: consequences (death, injury, loss)           │
│     └─ Escape: possible with certain Gu                     │
│                                                             │
│  5. RETURN                                                  │
│     └─ Back to main game flow                               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Core Mechanics

### Health & Resources

**Player:**
- **Health:** Based on rank and body cultivation
- **Primeval Essence:** Pool for activating Gu (regenerates between combats, not during)
- **Gu Hand:** All Gu in aperture available to use

**Enemy:**
- **Health:** Scaled by rank and type
- **Essence:** Their resource pool
- **Loadout:** AI-generated or pre-defined Gu set

### Turn Structure

Each turn consists of:
1. **Start Phase** - Trigger start-of-turn effects (DoTs, buffs tick down)
2. **Action Phase** - Play Gu cards, use items, use killer moves
3. **End Phase** - Trigger end-of-turn effects, pass to next combatant

**Action Economy:**
- Gu activations per turn limited by Path Attainment:
  - Ordinary: 1-2 Gu from this path per turn
  - Master: 3-4 Gu per turn + killer moves
  - Quasi-Grandmaster: 5 Gu per turn + advanced killer moves
  - Grandmaster: 6 Gu per turn + supreme killer moves
  - Quasi-Great Grandmaster+: 7+ Gu, unique abilities
- Also bounded by essence pool
- Some Gu are "quick" (don't count toward limit)
- Some Gu are "slow" (end turn immediately)
- Killer moves require Master+ attainment and consume the action phase

**Attainment Difficulty:**
- ~70% of cultivators remain at Ordinary
- ~25-30% reach Master with dedication
- The jump to Quasi-Grandmaster is immense (<1% of cultivators)
- Grandmaster is legendary (a handful per generation)
- Great Grandmaster is mythical (only ~4 ever in Refinement Path across all history)

### Playing Gu Cards

```
┌──────────────────────────────────────┐
│  MOONBLADE GU                        │
│  Rank 2 | Light Path | Offensive     │
├──────────────────────────────────────┤
│  Cost: 15 Essence                    │
│                                      │
│  Deal 25 damage to target enemy.     │
│  If used at night, deal 35 instead.  │
│                                      │
│  [Instant] [Single Target]           │
└──────────────────────────────────────┘
```

**To play a Gu:**
1. Select Gu from hand
2. Pay essence cost
3. Select target (if required)
4. Resolve effect
5. Gu goes on cooldown (if applicable)

### Hit Resolution (No Positioning)

Combat uses stat-based resolution instead of positioning. Every attack is resolved against appropriate defenses.

**Hit Roll Formula:**
```
Hit Roll = Attacker's Accuracy + Random(-10, +10)
vs
Dodge Roll = Defender's Evasion + Random(-10, +10)

If Hit > Dodge + 20: Full damage (critical)
If Hit > Dodge: Partial damage (50-80%)
If Hit <= Dodge: Miss (0 damage)
```

**Defense Types:**
Different attacks target different defenses:
| Attack Type | Defense Stat |
|-------------|--------------|
| Physical | Physical Defense + Evasion |
| Soul | Soul Defense + Willpower |
| Mind | Mental Defense + Wisdom |
| Fire/Ice/etc | Elemental Resistance |
| Poison | Poison Resistance + Constitution |

### Damage Calculation

```
Base Damage = Gu Effect Value
Path Bonus = Base × (Path Attainment Bonus)
Rank Modifier = 1 + (Attacker Rank - Defender Rank) × 0.1
Hit Modifier = 1.0 (full), 0.5-0.8 (partial), 0 (miss)
Final Damage = (Base + Path Bonus) × Rank Modifier × Hit Modifier × Random(0.9, 1.1)
```

**Resistances:**
- Enemies may have path resistances
- Damage reduction from defensive Gu
- Elemental interactions (fire vs water, etc.)

---

## Gu Types in Combat

### Offensive
Deal damage to enemies.
- Single target, multi-target, AoE
- Instant damage vs DoT
- Conditional bonuses

### Defensive
Protect the player.
- Shields (absorb X damage)
- Damage reduction (reduce by %)
- Evasion (chance to dodge)
- Reflect (return damage to attacker)

### Utility
Manipulate the battlefield.
- Movement/positioning
- Vision/information
- Crowd control (stun, slow)
- Dispel enemy buffs

### Buff/Debuff
Modify stats over time.
- Increase/decrease damage
- Increase/decrease defense
- Speed modifications
- Status effects

---

## Status Effects

| Effect | Description | Duration |
|--------|-------------|----------|
| **Burning** | Take fire damage each turn | 2-4 turns |
| **Poisoned** | Take poison damage, healing reduced | 3-5 turns |
| **Bleeding** | Take damage when acting | Until healed |
| **Stunned** | Skip next turn | 1 turn |
| **Slowed** | Act last in turn order | 2-3 turns |
| **Weakened** | Deal 25% less damage | 2-4 turns |
| **Vulnerable** | Take 25% more damage | 2-4 turns |
| **Strengthened** | Deal 25% more damage | 2-4 turns |
| **Protected** | Take 25% less damage | 2-4 turns |
| **Rooted** | Cannot escape combat | 3 turns |

---

## Killer Moves

Unlocked at Master+ attainment. Combine multiple Gu for amplified effects.

### Requirements
- Master or Grandmaster attainment in the move's path
- All component Gu in aperture
- Sufficient essence (cost is sum of components + bonus)

### Example Killer Move

```
┌──────────────────────────────────────┐
│  MOONLIGHT DEVASTATION               │
│  Light Path | Killer Move            │
├──────────────────────────────────────┤
│  Requires: Moonblade Gu + Light      │
│            Burst Gu + Moon Shield Gu │
│                                      │
│  Cost: 60 Essence                    │
│  Cooldown: 3 turns                   │
│                                      │
│  Deal 80 damage to all enemies.      │
│  Gain a shield for 40 HP.            │
│  At night: damage increased to 120.  │
│                                      │
│  [Master Light Path Required]        │
└──────────────────────────────────────┘
```

### Killer Move Discovery

Options:
1. **Study to unlock** - Spend time studying to unlock known moves
2. **Experiment** - Combine Gu in combat, chance to discover
3. **Inheritance** - Learn from previous runs
4. **NPC teachers** - Pay to learn specific moves

---

## Preparation & Intelligence

### Pre-Combat Preparation

If player knows they'll face a specific enemy:

1. **Research** - Learn enemy's path and typical Gu
2. **Counter-selection** - Equip Gu that counter their style
3. **Consumables** - Prepare one-use items
4. **Allies** - Bring NPC backup if available

### Intelligence Gathering

- Events can reveal enemy information
- Wisdom path Gu can analyze enemies
- NPCs may sell intelligence
- Previous encounters inform future ones

### Preparation Bonuses

| Preparation Level | Bonus |
|-------------------|-------|
| None | Standard combat |
| Basic (know path) | See enemy's path, +5% damage |
| Moderate (know loadout) | See enemy Gu, +10% damage |
| Full (know strategy) | See enemy AI pattern, +15% damage, act first |

---

## Multi-Enemy Encounters

When facing multiple enemies, combat becomes more dangerous.

### Player Debuffs (Outnumbered)

| Situation | Player Penalties |
|-----------|-----------------|
| 2v1 | -10% evasion |
| 3v1 | -20% evasion, -10% accuracy |
| 4v1+ | -30% evasion, -20% accuracy |

### Enemy Coordination

- Enemies can assist each other's attacks (+10% accuracy per ally)
- Enemies may use combo attacks (two enemies attack simultaneously)
- Flanking bonuses when multiple enemies target same player

### Target Selection

- Player chooses targets for single-target Gu
- AoE Gu hit all enemies
- Some Gu can hit multiple specific targets
- Killing enemies removes their coordination bonuses

### Ally Support

If player has NPC allies:
- Reduces outnumbered penalties
- Allies act on their own turn with their own Gu
- Can coordinate attacks with player
- Allies have their own HP and can be defeated

---

## Environmental Effects

Combat environments are AI-generated based on location context. Each combat has 1-3 environmental effects.

### Example Environments

| Location | Possible Effects |
|----------|-----------------|
| **Forest** | +20% evasion for Dark Path, fire spreads between targets |
| **Swamp** | Poison DoT each turn, movement Gu effectiveness -50% |
| **Mountain Peak** | Wind effects (-10% ranged accuracy), flying Gu +25% damage |
| **Underground** | No light-based bonuses, AoE range reduced |
| **Near Water** | Water path +20% damage, fire path -20% damage |
| **Graveyard** | Soul attacks +15%, undead enemies heal slowly |
| **Ancient Ruins** | Random Gu effects may trigger, formation path bonuses |
| **Volcanic** | Fire damage over time, fire immunity negates |

### Environmental Interaction

- Some Gu can modify the environment
- Environments can change mid-combat (flood rising, fire spreading)
- Preparation includes scouting the combat location
- Wisdom path can reveal environmental effects before combat

---

## Enemy AI

### Behavior Types

**Aggressive** - Prioritizes damage, uses offensive Gu
**Defensive** - Prioritizes survival, uses shields/heals
**Tactical** - Adapts to player actions, uses counters
**Berserk** - Ignores defense, all-out attack
**Cautious** - Preserves resources, looks for openings

### AI Decision Making

Simple priority-based system:
```
1. If health < 20%, use healing/escape if available
2. If player has strong buff, use dispel if available
3. If can kill player this turn, go for lethal
4. If player is debuffed, capitalize with damage
5. Use strongest available offensive option
6. Pass/defend if nothing good available
```

### Generated Enemy Loadouts

AI generates enemy builds considering:
- Enemy's path (should have path-appropriate Gu)
- Enemy's rank (Gu ranks match)
- Synergy (Gu should work together)
- Challenge level (difficulty parameter)

### Enemy Killer Moves

Enemies can use killer moves based on their background and attainment:

| Enemy Type | Killer Move Chance | Max Moves |
|------------|-------------------|-----------|
| Mook/Random | 0% | 0 |
| Trained/Clan | 10% | 1 basic |
| Elite/Veteran | 50% | 1-2 |
| Boss/Named | 90% | 2-4 signature |

**Requirements for Enemy Killer Moves:**
- Must have Master+ attainment in relevant path
- Must have the component Gu in their loadout
- AI-generated enemies get killer moves based on their backstory
- Named NPCs have pre-defined signature moves

---

## Victory & Defeat

### Victory Conditions
- Reduce enemy health to 0
- Enemy surrenders (rare, based on morale)
- Enemy escapes (partial victory)

### Defeat Conditions
- Player health reaches 0
- Player surrenders/flees
- Turn limit exceeded (rare)

### Victory Rewards
- Primeval stones
- Gu drops (from enemy or loot)
- Reputation changes
- Quest progress
- Experience toward path attainment

### Defeat Consequences
- **Death** - Run ends (permadeath)
- **Injury** - Temporary stat penalties
- **Loss** - Lose resources, Gu stolen
- **Escape** - Lose resources, reputation hit

### Escape Mechanics

Can attempt escape if:
- Have movement Gu
- Not rooted/trapped
- Pay escape cost (essence)

**Escape Success:**
- Movement Gu rank vs enemy rank
- Player health (harder when low)
- Random factor
- Environmental effects may help or hinder

**Reputation Cost (Contextual):**

Based on relative strength comparison:

```
Strength Diff = (Enemy Rank × 10 + Enemy Stage) - (Player Rank × 10 + Player Stage)

Strength Diff > 10:  No loss (sensible retreat from stronger foe)
Strength Diff 0-10:  -5 reputation
Strength Diff -5 to 0:  -10 reputation
Strength Diff -10 to -5:  -20 reputation
Strength Diff < -10:  -30 reputation + potential story event
```

**Additional Factors:**
- Public fight with witnesses: Reputation impact doubled
- Previous boasts/challenges: Additional -10 reputation
- Abandoning allies: Major reputation hit (-30 additional)

---

## Combat UI Layout

```
┌─────────────────────────────────────────────────────────────┐
│  ENEMY: Blood Path Gu Master (Rank 3)                       │
│  ████████████░░░░░░░░ HP: 60/100                           │
│  Status: [Bleeding]                                         │
│  Gu: [???] [???] [Blood Frenzy Gu] [???]                   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                    COMBAT LOG                               │
│  > You dealt 25 damage with Moonblade Gu                    │
│  > Enemy is now Bleeding                                    │
│  > Enemy used Blood Frenzy Gu, dealt 30 damage              │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│  PLAYER: [Your Name] (Rank 3)                               │
│  ██████████████████░░ HP: 85/100                           │
│  ████████░░░░░░░░░░░░ Essence: 45/100                      │
│  Status: [None]                                             │
├─────────────────────────────────────────────────────────────┤
│  YOUR GU:                                                   │
│  [Moonblade:15] [Light Shield:20] [Heal:25] [Flash:10]     │
│                                                             │
│  KILLER MOVES:                                              │
│  [Moonlight Devastation:60]                                │
│                                                             │
│  [End Turn]  [Flee]  [Inventory]                           │
└─────────────────────────────────────────────────────────────┘
```

---

## Combat Balance Targets

| Player Rank | Expected Combat Length | Win Rate (equal rank) |
|-------------|------------------------|----------------------|
| 1 | 4-6 turns | 65% |
| 2 | 5-8 turns | 60% |
| 3 | 6-10 turns | 55% |
| 4 | 8-12 turns | 50% |
| 5 | 10-15 turns | 45% |

**Difficulty Scaling:**
- Easy: Enemy 1 rank below, 80% win rate target
- Normal: Equal rank, per table above
- Hard: Enemy 1 rank above, 30% win rate target
- Boss: Enemy 2+ ranks above, 15% win rate target

---

## Resolved Questions

- [x] How many Gu can be played per turn? **Attainment-based + essence-limited**
- [x] Should there be positioning/movement in combat? **No - stat-based resolution**
- [x] How do multi-enemy encounters work? **Target selection, coordination bonuses, outnumbered penalties**
- [x] Can enemies use killer moves? **Yes - based on attainment and enemy type**
- [x] Are there environmental effects in combat? **Yes - AI-generated per encounter**
- [x] How does fleeing affect reputation? **Contextual based on relative strength**
