# NPCs & Relationships [DRAFT]

## Overview

NPCs populate the world, providing services, information, quests, and relationships. Most NPCs are AI-generated based on context, but maintain consistency once created.

---

## NPC Fundamentals

### NPC Attributes

| Attribute | Description |
|-----------|-------------|
| **Name** | Generated or preset |
| **Rank** | Cultivation rank |
| **Path** | Primary cultivation path |
| **Occupation** | Role in the world |
| **Location** | Where they can be found |
| **Clan/Faction** | Affiliation |
| **Personality** | Core traits |
| **Disposition** | Attitude toward player |
| **Services** | What they offer |
| **Desires** | What they want |
| **Secret** | Hidden information |

---

## Disposition System

### Disposition Levels

| Level | Value Range | Description |
|-------|-------------|-------------|
| Mortal Enemy | -100 to -75 | Will attack on sight |
| Hostile | -74 to -50 | Actively opposes you |
| Unfriendly | -49 to -25 | Reluctant to help |
| Neutral | -24 to 24 | Standard interactions |
| Friendly | 25 to 49 | Willing to help |
| Allied | 50 to 74 | Goes out of way to help |
| Devoted | 75 to 100 | Will risk life for you |

### Disposition Changes

| Action | Typical Change |
|--------|----------------|
| Complete quest for them | +10 to +25 |
| Gift valuable item | +5 to +15 |
| Help in combat | +15 to +30 |
| Save their life | +30 to +50 |
| Betray them | -30 to -50 |
| Kill their ally | -20 to -40 |
| Refuse reasonable request | -5 to -15 |
| Insult them | -5 to -20 |
| Rob them | -40 to -60 |

### Reputation Influence

Your overall reputation affects starting dispositions:

| Your Reputation | Righteous NPC | Demonic NPC |
|-----------------|---------------|-------------|
| Very Righteous (+50) | +15 start | -15 start |
| Righteous (+25) | +10 start | -5 start |
| Neutral (0) | 0 | 0 |
| Demonic (-25) | -10 start | +5 start |
| Very Demonic (-50) | -20 start | +15 start |

---

## NPC Archetypes

### Merchants

**Role:** Trade goods and services

**Common Traits:**
- Profit-motivated
- Information-aware
- Neutral to most factions

**Services:**
- Buy/sell Gu
- Buy/sell materials
- Special orders
- Price information

**Generation Parameters:**
```json
{
  "archetype": "merchant",
  "rank_range": [1, 4],
  "paths": ["any", "food", "refinement"],
  "disposition_base": 0,
  "services": ["trade"],
  "desire_types": ["profit", "rare_items", "connections"]
}
```

**Example:**
```
Name: Merchant Wang
Rank: 2
Path: Food Path
Personality: Shrewd, fair-dealing, gossip-loving
Disposition: Neutral (0)
Services: General Gu trade, material trade
Desires: Rare cooking ingredients, trade routes
Secret: Has connections to black market
```

---

### Elders

**Role:** Authority figures, quest givers

**Common Traits:**
- Power-focused
- Clan-loyal
- Knowledge holders

**Services:**
- Assign missions
- Teach techniques
- Mediate disputes
- Grant permissions

**Generation Parameters:**
```json
{
  "archetype": "elder",
  "rank_range": [4, 6],
  "paths": ["clan_signature_paths"],
  "disposition_base": "based_on_clan_standing",
  "services": ["missions", "teaching", "authority"],
  "desire_types": ["clan_prosperity", "personal_legacy", "rivals_downfall"]
}
```

---

### Fellow Cultivators

**Role:** Peers, rivals, potential allies

**Common Traits:**
- Similar rank to player
- Own goals and ambitions
- Potential long-term relationships

**Services:**
- Information sharing
- Combat assistance
- Trade
- Rivalry

**Generation Parameters:**
```json
{
  "archetype": "cultivator",
  "rank_range": [player_rank - 1, player_rank + 1],
  "paths": ["any"],
  "disposition_base": "random",
  "services": ["alliance", "competition", "trade"],
  "desire_types": ["power", "resources", "reputation", "revenge"]
}
```

---

### Information Brokers

**Role:** Sell knowledge

**Common Traits:**
- Wisdom path affinity
- Neutral allegiance
- Know many secrets

**Services:**
- Location information
- NPC secrets
- Enemy weaknesses
- Event tips

**Generation Parameters:**
```json
{
  "archetype": "broker",
  "rank_range": [3, 5],
  "paths": ["wisdom", "dark"],
  "disposition_base": 0,
  "services": ["information"],
  "desire_types": ["secrets", "payment", "favors_owed"]
}
```

---

### Beast Tamers

**Role:** Provide beast-related services

**Common Traits:**
- Enslavement path focus
- Live in wilderness
- Connect to beast resources

**Services:**
- Beast materials
- Beast companions
- Beast information
- Taming assistance

---

### Wanderers

**Role:** Random encounters, temporary allies

**Common Traits:**
- No fixed location
- Varied backgrounds
- Unique stories

**Services:**
- Temporary combat help
- One-time trades
- Unique information

---

### Antagonists

**Role:** Obstacles and enemies

**Common Traits:**
- Hostile disposition
- Block player goals
- Recurring threats

**Services:** None (obstacles)

**Generation Parameters:**
```json
{
  "archetype": "antagonist",
  "rank_range": [player_rank, player_rank + 2],
  "paths": ["any"],
  "disposition_base": -50,
  "motivation": ["revenge", "competition", "orders", "greed"],
  "threat_level": "based_on_context"
}
```

---

## NPC Persistence

### Generated NPCs

Once generated, NPCs persist:
- Stored in database with full attributes
- Appear in same location (or travel)
- Remember past interactions
- Disposition evolves over time

### NPC States

| State | Description |
|-------|-------------|
| Active | Normal, can interact |
| Traveling | Away temporarily |
| Injured | Limited services |
| Hiding | Must be found |
| Dead | Permanently gone |
| Ascended | Became immortal (rare) |

### NPC Death

NPCs can die from:
- Combat with player
- Combat with others (off-screen)
- Old age
- Events
- Player choices

Death is permanent and affects:
- Related NPCs (grief, revenge)
- Available services
- Quest availability
- World state

---

## Relationships

### Relationship Types

| Type | Description | Max Disposition |
|------|-------------|-----------------|
| Stranger | No relationship | ±25 |
| Acquaintance | Met before | ±50 |
| Contact | Regular interaction | ±75 |
| Connection | Meaningful relationship | ±100 |

### Building Relationships

Progression requires:
- Multiple positive interactions
- Time investment
- Shared experiences
- Meeting their desires

```
Stranger → Acquaintance: 3 positive interactions
Acquaintance → Contact: 5 more + quest completion
Contact → Connection: 10 more + significant event
```

### Relationship Benefits

| Level | Benefits |
|-------|----------|
| Acquaintance | Basic information, fair prices |
| Contact | Price discounts, quest access |
| Connection | Major assistance, secrets shared |

---

## NPC Dialogue

### Dialogue Generation

AI generates dialogue considering:
- NPC personality
- Disposition toward player
- Current situation
- Recent events
- NPC's desires and secrets

### Dialogue Format

```
[NPC reacts to situation]
"Dialogue line that fits personality."

[Player choices]
1. [Friendly response]
2. [Neutral response]
3. [Aggressive response]
4. [Path-specific option] (if applicable)
```

### Speech Styles

| Personality | Speech Pattern |
|-------------|----------------|
| Scholarly | Formal, references, quotes |
| Merchant | Price talk, deals, flattery |
| Warrior | Direct, challenge-focused |
| Cunning | Hints, double meanings |
| Simple | Straightforward, honest |

---

## NPC AI Behavior

### Decision Making

NPCs make decisions based on:
1. Primary desire
2. Self-preservation
3. Faction loyalty
4. Relationships
5. Recent events

### NPC Goals

Each NPC has goals they work toward:
- **Short-term:** Immediate desires
- **Long-term:** Life ambitions
- **Reactive:** Response to events

### Off-Screen Activity

NPCs continue existing when not interacted with:
- May change locations
- Rank up over time
- Build relationships with other NPCs
- Acquire resources
- Potentially die

---

## Faction System

### Faction Types

| Type | Examples |
|------|----------|
| Clans | Gu Yue, Bai, Xiong, Shang |
| Organizations | Merchant Guild, Hunters |
| Informal | Criminal networks, cults |

### Faction Reputation

Separate from personal disposition:
- Affects all faction member interactions
- Changes through actions against/for faction
- Can become KOS (kill on sight)

### Faction Relations

Factions have relations with each other:
```
Gu Yue ←[Rival]→ Bai
Merchant Guild ←[Allied]→ All clans
Criminal Network ←[Hostile]→ Law-abiding
```

---

## UI Elements

### NPC Interaction Panel

```
┌─────────────────────────────────────────────────────────────┐
│  MERCHANT WANG                                              │
│  Rank 2 | Food Path | Merchant                             │
├─────────────────────────────────────────────────────────────┤
│  Disposition: Friendly (+35) [████████░░]                  │
│  Relationship: Contact                                      │
│                                                             │
│  "Ah, my favorite customer! I have something special        │
│   today. A rare movement Gu, just arrived from the          │
│   Northern Plains. Interested?"                             │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│  [Trade]  [Talk]  [Ask for Information]  [Leave]           │
└─────────────────────────────────────────────────────────────┘
```

### Relationship Overview

```
┌─────────────────────────────────────────────────────────────┐
│  KNOWN NPCS                                                 │
├─────────────────────────────────────────────────────────────┤
│  ALLIED                                                     │
│  • Merchant Wang (Contact, +35, Merchant City)             │
│  • Elder Chen (Acquaintance, +28, Gu Yue Village)          │
│                                                             │
│  NEUTRAL                                                    │
│  • Hunter Li (Stranger, +5, Wild Plains)                   │
│  • Broker Chen (Acquaintance, -10, Merchant City)          │
│                                                             │
│  HOSTILE                                                    │
│  • Bai Warrior (Stranger, -45, Bai Territory)              │
│                                                             │
│  [Filter: All | Location | Disposition]                    │
└─────────────────────────────────────────────────────────────┘
```

---

## AI Generation Guidelines

### NPC Generation Prompt Context

```json
{
  "location": "merchant_city",
  "needed_role": "information_broker",
  "player_rank": 3,
  "player_reputation": 10,
  "existing_npcs": ["merchant_wang", "elder_li"],
  "current_goals": ["seeking movement gu"]
}
```

### Required Output

```json
{
  "name": "Generated name",
  "rank": 3,
  "path": "wisdom",
  "occupation": "information_broker",
  "personality": {
    "traits": ["cautious", "greedy", "knowledgeable"],
    "speech_style": "cryptic and hinting"
  },
  "disposition": 0,
  "services": ["sell_information", "buy_secrets"],
  "desires": ["rare secrets", "payment"],
  "secret": "Actually works for the Shang clan",
  "appearance": "Brief physical description"
}
```

---

## Open Questions

- [ ] How many NPCs should exist per location?
- [ ] NPC schedule/routine systems?
- [ ] Romance/deeper relationships?
- [ ] NPC permadeath toggle?
- [ ] NPC inheritance (children, students)?
