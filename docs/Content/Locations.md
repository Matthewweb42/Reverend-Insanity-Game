# Locations & World Map [DRAFT]

## Overview

The world is divided into regions, each containing multiple locations. Travel between locations takes time and may trigger events. Each location has distinct features, dangers, and opportunities.

---

## World Structure

```
WORLD
├── Southern Border (Starting Region)
│   ├── Clan Villages
│   ├── Wild Areas
│   ├── Cities
│   └── Special Locations
├── Northern Plains (Unlockable)
│   └── ...
├── Central Continent (Unlockable)
│   └── ...
├── Eastern Sea (Future)
│   └── ...
└── Western Desert (Future)
    └── ...
```

---

## Location Attributes

Each location has:

| Attribute | Description |
|-----------|-------------|
| **Name** | Location identifier |
| **Type** | Category (village, city, wilderness, etc.) |
| **Danger Level** | 1-10 mortality risk |
| **Rank Range** | Recommended cultivator ranks |
| **Resources** | What can be found here |
| **NPCs** | Who lives/visits here |
| **Events** | Location-specific event pool |
| **Travel Time** | From major hubs |

---

## Southern Border Locations

### Clan Villages

#### Gu Yue Village
**Type:** Clan Village (Starting Location)

**Danger Level:** 1

**Rank Range:** 1-3

**Description:**
A modest village nestled in a valley, home to the Gu Yue clan. The village center features a cultivation hall and small market.

**Features:**
- Clan cultivation hall
- Basic market (limited selection)
- Mission board
- Elder's residence
- Training grounds

**Available Resources:**
- Basic primeval stones
- Common materials
- Clan-specific Gu (limited)

**NPCs:**
- Clan elders
- Fellow clan members
- Occasional merchants

**Event Pool:**
- Clan missions
- Training opportunities
- Internal politics
- Merchant visits

**Travel Times:**
- Adjacent wilderness: 1 day
- Merchant City: 5 days
- Other clan villages: 3-7 days

---

#### Bai Clan Territory
**Type:** Clan Village

**Danger Level:** 2

**Rank Range:** 1-4

**Description:**
A fortified settlement known for its bone-white architecture. The Bai clan values strength above all.

**Features:**
- Combat arena
- Bone refinement workshop
- Hunting lodge
- War council hall

**Available Resources:**
- Bone materials
- Beast parts
- Strength path Gu

**NPCs:**
- Warrior elders
- Hunters
- Arena challengers

---

### Cities

#### Merchant City
**Type:** Trade Hub

**Danger Level:** 3

**Rank Range:** 2-5

**Description:**
The largest trading center in Southern Border. Merchants from all regions gather here. Anything can be bought for the right price.

**Features:**
- Grand marketplace
- Auction house
- Multiple inns
- Information brokers
- Black market (hidden)

**Available Resources:**
- Wide Gu selection
- Rare materials
- Information for sale
- Services (healing, crafting)

**NPCs:**
- Merchants of all types
- Travelers
- Information brokers
- Thieves and criminals

**Event Pool:**
- Trading opportunities
- Auctions
- Theft/crime events
- Rare item appearances
- Social encounters

**Travel Times:**
- Most villages: 3-5 days
- Wild areas: 2-4 days
- Special locations: 5-10 days

---

### Wilderness Areas

#### Wild Beast Plains
**Type:** Hunting Grounds

**Danger Level:** 4

**Rank Range:** 2-4

**Description:**
Vast grasslands roamed by wild beasts. Dangerous but rich in materials and wild Gu.

**Features:**
- Beast territories
- Hidden caves
- Ancient ruins (scattered)
- Temporary camps

**Available Resources:**
- Beast materials (all types)
- Wild Gu (various)
- Primeval stone deposits

**NPCs:**
- Hunters (temporary)
- Beast tamers
- Rival cultivators

**Event Pool:**
- Beast encounters
- Rare beast hunts
- Territory disputes
- Discovery events
- Ambushes

**Dangers:**
- Random beast attacks
- Stronger beasts in deep areas
- Weather hazards
- Rival hunters

---

#### Dang Hun Mountain
**Type:** Dangerous Zone

**Danger Level:** 7

**Rank Range:** 4-6

**Description:**
A mountain shrouded in soul-damaging miasma. Rich in soul path resources but extremely dangerous for the unprepared.

**Features:**
- Soul damaging environment
- Ancient tombs
- Rare soul Gu habitats
- Inheritance sites

**Available Resources:**
- Soul path materials
- Soul path Gu
- Ancient artifacts
- Inheritance opportunities

**NPCs:**
- Soul path cultivators (rare)
- Ghosts/spirits
- Treasure hunters

**Event Pool:**
- Soul attacks
- Ghost encounters
- Tomb discoveries
- Madness events
- Powerful inheritances

**Special Mechanics:**
- Soul damage over time without protection
- Vision-based events
- Memory alteration possibilities

---

### Special Locations

#### Three Kings Blessed Land
**Type:** Inheritance Site

**Danger Level:** 8

**Rank Range:** 5-6

**Description:**
A hidden grotto heaven left by three ancient Gu Immortals. Contains incredible treasures but deadly trials.

**Access Requirements:**
- Rank 5 minimum
- Special key item
- Discovery through events/information

**Features:**
- Trial chambers
- Treasure vaults
- Inheritance tests
- Time-dilated interior

**Available Resources:**
- Immortal-level Gu formulas
- Rare Rank 5 Gu
- Ancient techniques
- Blessed land seed (victory reward)

**Dangers:**
- Deadly trials
- Guardian constructs
- Time traps
- Competing cultivators

---

#### Hu Immortal Blessed Land
**Type:** Hidden Grotto

**Danger Level:** 6

**Rank Range:** 4-5

**Description:**
A secret blessed land disguised as ordinary wilderness. Contains a living ecosystem and unique Gu.

**Access Requirements:**
- Discover entrance
- Pass concealment barrier

**Features:**
- Unique ecosystem
- Rare beast species
- Gu cultivation grounds
- Safe haven (once found)

**Available Resources:**
- Unique Gu species
- Rare materials
- Safe cultivation space
- Beast companions

---

## Location Types

### Villages
- Low danger
- Limited resources
- Social focus
- Clan mechanics

### Cities
- Moderate danger
- Trading focus
- Wide selection
- Political intrigue

### Wilderness
- High danger
- Resource gathering
- Combat encounters
- Exploration rewards

### Special Locations
- Very high danger
- Unique rewards
- One-time opportunities
- Story content

### Blessed Lands (Immortal)
- Personal territory
- Resource generation
- Time manipulation
- Late-game content

---

## Travel System

### Travel Mechanics

```
Travel Time = Base Distance × Speed Modifier × Random Events

Speed Modifiers:
- No movement Gu: 1.0
- Rank 1 movement Gu: 0.75
- Rank 2 movement Gu: 0.5
- Rank 3 movement Gu: 0.33
- Higher rank: Further reduction
```

### Travel Events

While traveling, events may occur:
- Ambushes (combat)
- Discoveries (loot)
- Encounters (NPCs)
- Weather (delays)
- Shortcuts (time save)

**Event Chance:** ~20% per day of travel

### Travel Safety

| Route Type | Danger | Event Chance |
|------------|--------|--------------|
| Main roads | Low | 10% |
| Back paths | Medium | 25% |
| Wilderness | High | 40% |
| Unexplored | Very High | 60% |

---

## Map UI

### World Map View

```
┌─────────────────────────────────────────────────────────────┐
│  SOUTHERN BORDER                                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│        [Dang Hun Mountain]                                  │
│              ▲ (7)                                          │
│             /                                               │
│    [Bai]   /     [Three Kings]                              │
│     ● ───────────── ★ (8)                                   │
│    (2)    \                                                 │
│            \   [Merchant City]                              │
│     [Gu Yue]  ────  ◆ (3)                                  │
│        ●           /                                        │
│       (1)         /                                         │
│                  /                                          │
│    [Wild Plains] ▲ (4)                                     │
│                                                             │
│  Legend: ● Village  ◆ City  ▲ Wilderness  ★ Special        │
│          (N) = Danger Level                                 │
│                                                             │
│  Current Location: [Gu Yue Village]                         │
│  [Travel]  [Location Info]  [Known NPCs]                   │
└─────────────────────────────────────────────────────────────┘
```

### Location Info Panel

```
┌─────────────────────────────────────────────────────────────┐
│  MERCHANT CITY                                              │
├─────────────────────────────────────────────────────────────┤
│  Type: Trade Hub                                            │
│  Danger: 3/10                                               │
│  Recommended Rank: 2-5                                      │
│                                                             │
│  Travel Time: 5 days (3 days with Swift Steps Gu)          │
│                                                             │
│  Known Features:                                            │
│  • Large marketplace                                        │
│  • Auction house (weekly)                                   │
│  • Information brokers                                      │
│  • ??? (undiscovered)                                       │
│                                                             │
│  Known NPCs:                                                │
│  • Merchant Wang (Friendly)                                 │
│  • Broker Chen (Neutral)                                    │
│                                                             │
│  [Travel Here]  [Back to Map]                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Discovery Mechanics

### Revealing Locations

Locations can be:
- **Known from start** - Clan village, nearby areas
- **Discovered through events** - NPCs reveal locations
- **Found while exploring** - Random discovery
- **Purchased as information** - Buy from brokers
- **Inherited** - From previous runs

### Hidden Features

Even known locations have secrets:
- Hidden shops
- Secret NPCs
- Underground areas
- Special events

Discovery requires:
- High enough rank
- Right path attainment
- Specific Gu
- Random chance
- NPC information

---

## AI Generation for Locations

When generating location-specific content:

### Events must consider:
- Location type
- Danger level
- Available resources
- Present NPCs
- Time of year

### NPCs must fit:
- Location's character
- Economic role
- Danger appropriate
- Consistent with lore

### Rewards must match:
- Location's resources
- Appropriate rank
- Rarity scaled to danger

---

## Open Questions

- [ ] How many locations at launch?
- [ ] Dynamic location events (sieges, disasters)?
- [ ] Player-built locations?
- [ ] Season effects on locations?
- [ ] Instanced vs shared locations for multiplayer?
