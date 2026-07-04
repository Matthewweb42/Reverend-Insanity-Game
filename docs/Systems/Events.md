# Event System [FINAL]

## Overview

Events are the primary way the game world interacts with the player. They present choices, opportunities, challenges, and consequences. Most events are AI-generated based on player context and goals.

---

## Event Philosophy

### Design Principles

1. **Meaningful Choices** - Every choice should matter
2. **Risk/Reward Tradeoffs** - Better rewards require more risk
3. **Goal Alignment** - Events should relate to player goals when possible
4. **Consequential Outcomes** - Choices should have lasting impact
5. **Fair Information** - Players should have enough info to make informed decisions

### Event Frequency

```
Target: 1-3 events per game day (at 1x speed)
- Minimum gap: 2 hours game time between events
- Maximum gap: 1 day without events
- Adjusted by location danger and player activity
```

---

## Event Types

### Opportunity Events
Present a chance to gain something valuable.

**Structure:**
- Clear reward visible
- Cost or risk involved
- Time-limited usually
- Can be ignored

**Example:**
```
"A Wandering Merchant"
A merchant offers a rare Fire Path Gu for sale.
Cost: 50 primeval stones

[Purchase] - Gain Fire Burst Gu
[Haggle] - 50% chance: pay 30 stones. 50% chance: merchant leaves
[Decline] - No effect
```

### Encounter Events
Meeting someone or something in the world.

**Structure:**
- NPC or creature interaction
- Multiple approaches possible
- Relationship implications
- May lead to combat

**Example:**
```
"A Familiar Face"
You encounter Li Wei, a fellow clan member. He seems nervous.

[Greet warmly] - +Relationship, may share information
[Demand explanation] - Learn what he's hiding, -Relationship
[Ignore and pass] - No effect
[Rob him] - Combat, loot if win, reputation hit
```

### Discovery Events
Finding something hidden or valuable.

**Structure:**
- Exploration reward
- May require action to claim
- Could be trapped/dangerous
- Location-based

**Example:**
```
"Hidden Cave"
You discover a concealed cave entrance behind a waterfall.

[Enter cautiously] - Explore safely, slower
[Rush in] - Faster, but trigger traps if present
[Mark for later] - Add to map, return anytime
[Ignore] - No effect
```

### Challenge Events
Obstacles that must be overcome.

**Structure:**
- Problem presented
- Multiple solutions
- Failure has consequences
- Success has rewards

**Example:**
```
"Blocked Path"
A rank 3 beast guards the mountain pass.

[Fight] - Combat encounter
[Sneak past] - Requires stealth Gu, 60% success
[Find alternate route] - Takes 3 extra days
[Wait for it to leave] - 1-5 days random
```

### Dilemma Events
Moral or strategic choices with no clear "right" answer.

**Structure:**
- Conflicting values/goals
- Trade-off between options
- No perfect solution
- Character-defining

**Example:**
```
"A Cry for Help"
A young cultivator is being attacked by bandits. You could save them, but revealing yourself might attract the bandits' boss.

[Intervene heroically] - Combat (3 bandits), +Righteous rep, potential ally
[Help secretly] - Combat (3 bandits), no rep change, no relationship
[Create distraction] - They escape, you escape, no combat
[Walk away] - +Demonic rep, haunted by decision (mood penalty)
```

### Chain Events
Multi-part events that span time.

**Structure:**
- Initial event sets up situation
- Follow-up events based on choices
- Long-term consequences
- Can span days or weeks

**Example:**
```
Part 1: "The Merchant's Request"
A merchant asks you to deliver a package to a nearby city.
[Accept] → Triggers Part 2 in 3 days

Part 2: "Suspicious Package"
On the road, you notice the package moving slightly...
[Open it] → Discover smuggled creature
[Deliver anyway] → Paid, but reputation consequences later
[Abandon it] → Merchant becomes hostile

Part 3: (varies based on Part 2 choice)
```

---

## Event Structure

### Data Model

```json
{
  "id": "evt_001",
  "title": "A Wandering Merchant",
  "type": "opportunity",

  "trigger_conditions": {
    "location_types": ["city", "trade_route"],
    "min_rank": 1,
    "max_rank": 4,
    "required_reputation": null,
    "required_flags": [],
    "forbidden_flags": ["merchant_banned"]
  },

  "description": "A merchant with unusual wares approaches you...",

  "choices": [
    {
      "id": "buy",
      "text": "Purchase the Gu",
      "requirements": {
        "min_primeval_stones": 50
      },
      "visible": true,
      "hint": "A fair price for this rarity"
    },
    {
      "id": "haggle",
      "text": "Try to negotiate",
      "requirements": null,
      "visible": true,
      "hint": null
    },
    {
      "id": "rob",
      "text": "Take it by force",
      "requirements": null,
      "visible": "reputation < 0",
      "hint": "Risky, but profitable"
    },
    {
      "id": "decline",
      "text": "No thank you",
      "requirements": null,
      "visible": true,
      "hint": null
    }
  ],

  "outcomes": {
    "buy": {
      "description": "The merchant hands over the Gu with a smile.",
      "effects": [
        {"type": "remove_resource", "resource": "primeval_stones", "amount": 50},
        {"type": "add_gu", "gu_id": "fire_burst_gu", "count": 1}
      ],
      "flags_set": ["bought_from_merchant_001"],
      "followup_event": null
    },
    "haggle": {
      "check": {
        "type": "random",
        "success_chance": 0.5
      },
      "success": {
        "description": "The merchant agrees to a lower price!",
        "effects": [
          {"type": "remove_resource", "resource": "primeval_stones", "amount": 30},
          {"type": "add_gu", "gu_id": "fire_burst_gu", "count": 1}
        ]
      },
      "failure": {
        "description": "Offended, the merchant packs up and leaves.",
        "effects": [],
        "flags_set": ["offended_merchant_001"]
      }
    },
    "rob": {
      "check": {
        "type": "combat",
        "enemy": "traveling_merchant",
        "enemy_rank": 2
      },
      "success": {
        "description": "The merchant flees, leaving their goods.",
        "effects": [
          {"type": "add_gu", "gu_id": "fire_burst_gu", "count": 1},
          {"type": "add_resource", "resource": "primeval_stones", "amount": 30},
          {"type": "change_reputation", "amount": -15}
        ]
      },
      "failure": {
        "description": "The merchant escapes and will remember this."
        "effects": [
          {"type": "change_reputation", "amount": -5}
        ],
        "flags_set": ["wanted_by_merchants"]
      }
    },
    "decline": {
      "description": "The merchant nods and moves on.",
      "effects": []
    }
  },

  "tags": ["trade", "merchant", "gu_acquisition"],
  "goal_alignment": ["seeking fire gu", "seeking gu", "need resources"],
  "cooldown_days": 5,
  "is_repeatable": true
}
```

---

## Goal-Directed Generation

### Player Goals

Players can set active goals that influence event generation:

```
Available Goal Types:
- "Seeking [path] Gu" - Fire, Blood, Wisdom, etc.
- "Seeking [type] Gu" - Movement, Combat, Utility, etc.
- "Need resources" - Primeval stones focus
- "Building connections" - NPC relationship events
- "Seeking information" - Intelligence and secrets
- "Path training" - Study opportunities
- "Looking for trouble" - Combat encounters
- "Exploring" - Discovery events
- "Seeking inheritance" - Rare finds
```

### Goal Influence

When generating events, AI considers:
1. Active player goals
2. Current location
3. Player rank and resources
4. Recent event history
5. NPC relationships

**Generation prompt includes:**
```
Player is actively seeking: [list of goals]
Generate an event that relates to at least one of these goals.
The event should feel like a natural result of the player's search.
```

### Goal Examples

**Goal: "Seeking movement Gu"**
Possible generated events:
- Merchant selling movement Gu
- Rumor of movement path inheritance
- Challenge with movement Gu reward
- NPC who knows movement techniques

**Goal: "Building connections"**
Possible generated events:
- Social gathering event
- NPC in need of help
- Faction recruitment opportunity
- Clan politics situation

---

## Event Triggers

### Trigger Types

**Time-Based:**
- Minimum time between events
- Random chance per time unit
- Scheduled events (annual, etc.)

**Location-Based:**
- Enter new location
- Location-specific event pools
- Discovery through exploration

**Condition-Based:**
- Player reaches rank threshold
- Resource drops below level
- Reputation changes significantly
- Flag is set from previous event

**Goal-Based:**
- Event matches active goal
- Higher priority when goal-aligned

### Trigger Flow

```
Every game day:
1. Check scheduled events
2. Check condition triggers
3. Calculate event chance based on:
   - Time since last event
   - Location danger level
   - Player activity
4. If event triggers:
   a. Filter eligible events (conditions met)
   b. Weight by goal alignment
   c. Select event
   d. Display to player
```

---

## Event Queue

### Queue Management

- Multiple events can be pending
- Displayed as notifications
- Player chooses when to address
- Some events expire

```
Event Queue:
1. ⚠️ "Ambush!" - Expires in 1 hour (urgent)
2. 📜 "A Letter Arrives" - No expiration
3. 🏪 "Merchant Passing Through" - Expires in 3 days
```

### Urgency Levels

| Level | Behavior |
|-------|----------|
| Immediate | Pauses game, must address now |
| Urgent | Shows prominently, expires soon |
| Normal | Standard notification |
| Background | Can be easily dismissed |

---

## Event Effects

### Effect Types

```python
# Resource effects
{"type": "add_resource", "resource": "primeval_stones", "amount": 50}
{"type": "remove_resource", "resource": "primeval_stones", "amount": 50}

# Gu effects
{"type": "add_gu", "gu_id": "fire_burst_gu"}
{"type": "add_gu", "gu_pool": "fire_rank2_offensive"}  # Random from pool
{"type": "remove_gu", "gu_id": "..."}

# Combat
{"type": "trigger_combat", "enemy_type": "bandit", "enemy_rank": 2, "count": 3}

# Travel
{"type": "travel_to", "location": "merchant_city"}
{"type": "reveal_location", "location": "hidden_cave"}

# Relationships
{"type": "add_connection", "npc_id": "merchant_wang", "disposition": "friendly"}
{"type": "change_relationship", "npc_id": "...", "amount": 10}

# Reputation
{"type": "change_reputation", "amount": -10}  # Negative = demonic

# Stats
{"type": "take_damage", "amount": 20}
{"type": "heal", "amount": 20}
{"type": "cultivation_boost", "amount": 50}  # Progress points

# Information
{"type": "gain_information", "info_type": "npc_secret", "content": "..."}
{"type": "learn_gu_formula", "gu_id": "..."}

# Time
{"type": "time_skip", "days": 3}

# Flags
{"type": "set_flag", "flag": "helped_merchant"}
{"type": "remove_flag", "flag": "..."}
```

---

## AI Generation Prompts

### Event Generation Request

```json
{
  "request_type": "generate_event",
  "context": {
    "location": "merchant_city",
    "location_type": "city",
    "player_rank": 3,
    "player_goals": ["seeking movement gu", "building connections"],
    "player_reputation": 5,
    "player_resources": {"primeval_stones": 120},
    "known_npcs": ["merchant_wang", "elder_li"],
    "recent_events": ["completed_trade", "fought_bandits"],
    "flags": ["helped_merchant_guild"],
    "time": {"day": 47, "month": 2, "year": 3}
  }
}
```

### Event Validation

After generation, validate:
- All required fields present
- Choice requirements are achievable
- Effects reference valid resources/Gu
- Outcomes don't break game state
- Difficulty appropriate for rank

---

## UI Design

### Event Popup

```
┌─────────────────────────────────────────────────────────────┐
│  A WANDERING MERCHANT                                       │
│  [Opportunity] [Trade]                                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  A weathered merchant with a heavy pack approaches you.     │
│  His eyes gleam when he sees your cultivation base.         │
│                                                             │
│  "Young friend, I have something special today. A Fire      │
│  Burst Gu, rank 2, excellent quality. Only 50 stones."      │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│  CHOICES:                                                   │
│                                                             │
│  ▶ [Purchase the Gu]                                        │
│    Cost: 50 primeval stones                                 │
│    "A fair price for this rarity"                           │
│                                                             │
│  ▶ [Try to negotiate]                                       │
│    "Perhaps I can get a better deal..."                     │
│                                                             │
│  ▶ [Decline politely]                                       │
│    "Maybe another time"                                     │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│  Your resources: 120 primeval stones                        │
└─────────────────────────────────────────────────────────────┘
```

### Outcome Display

```
┌─────────────────────────────────────────────────────────────┐
│  OUTCOME                                                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  The merchant hands over the Gu with a satisfied smile.     │
│  "A pleasure doing business. Find me again if you need      │
│  more rare wares."                                          │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│  EFFECTS:                                                   │
│  • -50 primeval stones                                      │
│  • +1 Fire Burst Gu (Rank 2)                               │
│                                                             │
│  [Continue]                                                 │
└─────────────────────────────────────────────────────────────┘
```

---

## Storyline System

Events can be part of ongoing storylines that evolve over time.

### Storyline Types

| Type | Decisions | Duration | Max Active |
|------|-----------|----------|------------|
| **Short** | 1 | Immediate | Unlimited |
| **Medium** | 3-5 | Months to years | 3-5 |
| **Long** | 10+ | Decades | 1-2 |

### Storyline Management

AI manages storyline progression by evaluating:
1. "Did the player do something that changes the next step?"
2. "What's the most likely next step given current state?"
3. "Is the storyline close to resolution?"
4. "Where are related NPCs in their part of the story?"

**Key Features:**
- All storylines have early exit/resolution points
- NPCs have their own storyline involvement tracked
- Player actions can accelerate, delay, or redirect storylines
- Storylines can intersect (NPC in multiple storylines)

### Storyline State

```json
{
  "storyline_id": "merchant_guild_conspiracy",
  "type": "long",
  "current_step": 4,
  "total_steps_estimate": 12,
  "involved_npcs": ["merchant_wang", "elder_chen", "shadow_figure"],
  "player_knowledge": ["guild_is_corrupt", "chen_is_involved"],
  "possible_resolutions": ["expose_conspiracy", "join_conspiracy", "ignore"],
  "next_trigger_conditions": ["visit_merchant_city", "talk_to_wang"],
  "time_since_last_step": 45
}
```

---

## Epoch Events

Predetermined world events that happen regardless of player action. ~12 Epoch Events are set at game start.

### Characteristics

- Happen at fixed times (with some variance)
- Player can engage, ignore, or exploit
- Buildup through rumors and smaller events
- Create living world feeling
- Never force player outcomes

### Example Epoch Events

| Event | Timing | Buildup Signs |
|-------|--------|---------------|
| **Verdant Great Inheritance** | Year 50-70 | Ancient texts mention it, treasure hunters gather |
| **Southern Border Competition** | Every 100 years | Clans begin selecting candidates, training intensifies |
| **Demonic Alliance War** | Year 200-300 | Border skirmishes, refugees, political tension |
| **Ancient Immortal Awakens** | Year 400-500 | Blessed land disturbances, prophecies circulate |
| **Heavenly Tribulation Storm** | Year 150 | Weather anomalies, divination Gu go haywire |

### Player Interaction

Players can:
- **Participate** - Join the event directly
- **Exploit** - Take advantage of chaos/distraction
- **Prepare** - Position themselves for aftermath
- **Ignore** - Focus on personal cultivation
- **Interfere** - Try to change the outcome (difficult)

---

## Success Chance Display

Success chances are shown based on player's Wisdom stat.

### Wisdom Thresholds

| Wisdom | Display Format | Example |
|--------|---------------|---------|
| < 20 | No information | "You have no idea what might happen" |
| 20-40 | Vague descriptors | "Seems risky" / "Looks promising" |
| 40-60 | General assessment | "About even odds" / "Good chance" |
| 60-80 | Approximate % | "~65% success" |
| 80+ | Exact % | "67.3% success" |

### Implementation

```gdscript
func get_chance_display(actual_chance: float, wisdom: int) -> String:
    if wisdom < 20:
        return "Unknown outcome"
    elif wisdom < 40:
        if actual_chance > 0.7: return "Looks very promising"
        elif actual_chance > 0.5: return "Seems favorable"
        elif actual_chance > 0.3: return "Risky proposition"
        else: return "Extremely dangerous"
    elif wisdom < 60:
        if actual_chance > 0.6: return "Good chance of success"
        elif actual_chance > 0.4: return "About even odds"
        else: return "More likely to fail"
    elif wisdom < 80:
        var approx = round(actual_chance * 10) * 10
        return "~%d%% success" % approx
    else:
        return "%.1f%% success" % (actual_chance * 100)
```

---

## Goal System

Players can set 3-5 active goals that influence event generation.

### Goal Priority

| Priority | Weight | Description |
|----------|--------|-------------|
| Primary (1) | 50% | Main focus, half of relevant events |
| Secondary (2-4) | 50% split | Supporting goals share remaining weight |

### Goal Management

- Goals can be reordered anytime
- Completed goals free up slots
- Some goals auto-complete when conditions met
- Goals can be abandoned with no penalty

### Available Goal Types

```
- "Seeking [path] Gu" - Fire, Blood, Wisdom, etc.
- "Seeking [type] Gu" - Movement, Combat, Utility
- "Need resources" - Primeval stones focus
- "Building connections" - NPC relationships
- "Seeking information" - Intelligence, secrets
- "Path training" - Study, attainment
- "Looking for trouble" - Combat encounters
- "Exploring" - Discovery events
- "Seeking inheritance" - Rare finds
- "Preparing for [event]" - Epoch event focus
```

---

## Resolved Questions

- [x] How visible should success chances be? **Tiered by Wisdom stat**
- [x] Should players be able to save-scum events? **Yes - save anywhere**
- [x] How to handle event chains? **Active storyline system with AI management**
- [x] Should events force outcomes? **Never - but Epoch Events happen in world**
- [x] How many concurrent goals? **3-5 active goals**
