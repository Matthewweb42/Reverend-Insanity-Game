# Reverend Insanity Roguelike - Design Document

## Game Overview
A real-time with pause roguelike where you cultivate from Rank 1 mortal to Rank 9 Venerable. Each run lasts 30 minutes to a few hours. Time pressure through aging is a core mechanic. The game blends reactive event-driven gameplay with proactive goal-seeking, rewarding aggressive but risky play.

---

## Core Game Structure

### Win Condition
Reach Rank 9 Venerable

### Game Phases
1. **Mortal Stage (Rank 1-5)** - Clan-based cultivation, exploration, resource gathering
2. **Tribulation & Ascension (Rank 5→6)** - Earthly Calamity challenge
3. **Immortal Stage (Rank 6-8)** - Blessed land management, immortal politics, tribulations
4. **Venerable Ascension (Rank 8-9)** - Ultimate challenge and victory

### Roguelike Structure
- Permadeath with inheritance system
- Meta-progression through discovered Gu formulas, techniques, and resources
- Unlockable clans/tribes/sects for future runs
- Each death or completion creates an inheritance for the next run

---

## Time System

### Real-Time With Pause
- Game runs in real-time but can be paused at any moment
- Player can adjust game speed (1x, 2x, 5x, etc.)
- Time flows continuously - aging is constant pressure
- Days tick by visibly on screen

### Time Scaling
- Base time scale TBD (can adjust during development)
- Closed door cultivation accelerates time significantly
- Travel takes real in-game time (makes movement Gu valuable)
- Speed adjustable to player preference

### Event System
- Events trigger during real-time gameplay
- Notifications appear but game continues (Stellaris-style)
- Player reviews and responds when ready
- Events can occur during travel, cultivation, any activity

---

## Character Creation

### Region Selection
**Phase 1: Southern Border only**
- Other regions (Northern Plains tribes, Central Continent sects) unlock later

### Clan Selection
Each clan has:
- **Signature Paths** (2-3 specialized paths)
- **Unique Gu Pool** (5-10 exclusive Gu worms)
- **Clan Resources** (starting primeval stones, connections)
- **Clan Politics** (standing affects opportunities)

**Example Clans:**
- **Gu Yue Clan** - Moonlight path, balanced all-rounder
- **Bai Clan** - Bone path, aggressive combat
- **Shang Clan** - Enslavement path, political manipulation
- **Xiong Clan** - Strength path, straightforward power

### Aptitude Roll
- **A-grade** (5%) - 20% faster cultivation, -10% Gu costs
- **B-grade** (15%) - 10% faster cultivation, -5% Gu costs
- **C-grade** (30%) - Standard rates
- **D-grade** (50%) - 10% slower cultivation, +10% Gu costs

### Starting Position
- **Age** - Determines starting rank and time pressure
- **Family Wealth** - Affects starting resources
- **Connections** - Initial relationship cards with NPCs

---

## Mortal Stage Gameplay (Rank 1-5)

### Core Gameplay Loop

**Real-Time Activities:**
- **Active Cultivation** - Must be manually activated, drains resources continuously
- **Closed Door Cultivation** - Enter to focus purely on cultivation, time accelerates dramatically
- **Resource Management** - Balance primeval stones, materials, connections
- **Event Response** - React to opportunities, challenges, and emergencies as they appear
- **Goal-Directed Exploration** - Set objectives to influence event generation

**No Passive Cultivation:**
- Cultivation only progresses when actively chosen
- Resources drain during cultivation
- Must balance cultivation time with other activities (gathering, exploring, fighting)

### Goal-Directed System

**AI Event Generation Based on Player Intent:**
- Player sets goals via prompt or menu options:
  - "I'm seeking movement Gu"
  - "I need blood path resources and inheritances"
  - "I want to focus on political connections"
- AI generates events that naturally align with stated goals
- Simulates the feeling of actively searching for specific things
- More aggressive goal-seeking = more opportunities but more danger

### Key Activities

**Cultivation:**
- Active resource investment
- Progress toward next rank
- Risk of deviation if pushed too hard
- Can enter closed door cultivation (time skip with acceleration)

**Resource Gathering:**
- Clan missions (based on standing)
- Hunt wild beasts for materials
- Trade with merchants
- Complete generated quests/events

**Exploration:**
- Travel to different locations (takes real in-game time)
- Discover inheritances, wild Gu, secrets
- Events can trigger during travel
- Higher rank movement Gu reduces travel time significantly

**Study:**
- Increase path attainment
- Improves Gu effectiveness in that path
- Time investment but crucial for power

**Refinement:**
- Create/upgrade Gu worms
- Requires materials + recipes
- Can experiment to discover new formulas

**Socialization:**
- Build connections with NPCs
- Gather intelligence and information
- Open new opportunities
- Manage reputation (Righteous vs Demonic)

**Combat:**
- Turn-based tactical battles (separate from real-time flow)
- Arena fights, beast hunting, clan conflicts
- Strategic Gu selection and counter-play
- Can prepare specific Gu to counter known enemies

### Combat System

**Turn-Based Tactical Combat:**
- When combat triggers, enter turn-based mode
- Play Gu cards with specific abilities
- Counter-play and tactical decision-making
- Victory depends on:
  - Gu collection and preparation
  - Path attainment levels
  - Tactical execution during battle
  - Prior intelligence about enemy (allows counter-preparation)

**Preparation Phase:**
- If you know you'll face a specific enemy, you can:
  - Research their weaknesses
  - Gather appropriate counter Gu
  - Practice relevant killer moves
  - Form alliances for backup

### AI-Generated City Events

**Dynamic Event Creation:**
- Each location generates unique events
- Specific rewards for completing specific challenges
- Fight particular enemies for unique drops
- Events tailored to:
  - Player's current rank
  - Active goals
  - Location type
  - Reputation
  - Time in game

### Aperture Management
- **Limited Slots** - Expands with rank
  - Rank 1: 10 slots
  - Rank 5: 50 slots
- **Strategic Choices** - Balance combat vs. utility vs. economic Gu
- Each Gu occupies space
- Must make hard choices about what to keep

### Path Attainment System
Gain experience through study, experimentation, and usage:
- **Novice** (0-100) - Basic Gu usage
- **Adept** (100-300) - 10% efficiency boost
- **Expert** (300-600) - 20% boost, unlock advanced techniques
- **Master** (600-1000) - 30% boost, create killer moves
- **Grandmaster** (1000+) - 40% boost, signature moves

### Killer Moves
- Unlocked at Master+ attainment
- Combine 2-5 Gu for amplified effects
- Must practice to reduce essence cost
- Can be inherited to future runs

### Connections System

**NPC Relationship Cards:**
- **Allied** - Help in emergencies, share information
- **Friendly** - Trade benefits, occasional assistance
- **Neutral** - Standard interactions
- **Hostile** - Actively oppose you, may attack
- **Mortal Enemy** - Dedicated to your destruction

**Reputation Spectrum:**
- Righteous ←→ Demonic
- Affects NPC interactions
- Opens different quest lines
- Some inheritances require specific reputation

### Location System

**Starting: Your Clan Village**
- Safe cultivation zone
- Limited market, basic missions
- Tutorial area
- Must eventually leave to progress

**Southern Border Locations:**
- **Three Kings Blessed Land** - High-level inheritance
- **Merchant City** - Trading hub, rare Gu
- **Hu Immortal Blessed Land** - Hidden grotto
- **Dang Hun Mountain** - Soul path resources, dangerous
- **Wild Beast Plains** - Hunting grounds, beast materials

**Each Location Has:**
- Danger level (mortality risk)
- Available resource types
- Discoverable Gu worms
- NPC encounters
- Event pool for AI generation
- Travel time from other locations

### Rank Advancement

**Breakthrough Challenges:**
- **Rank 2** - Minor bottleneck, simple cultivation check
- **Rank 3** - First real challenge, combat or puzzle
- **Rank 4** - Significant barrier, multi-stage challenge
- **Rank 5** - Major bottleneck, choose specialization (affects Rank 6 ascension)

**Failure Consequences:**
- Lost cultivation progress
- Potential aperture damage
- Wasted resources
- Time lost (aging continues)

### Aging & Time Pressure

**Lifespan Management:**
- Mortals have limited lifespans
- Aging is continuous and visible
- Finding lifespan-extending Gu is critical
- Death from old age = run failure (but triggers inheritance)
- Creates tension: cultivate quickly vs. prepare thoroughly

---

## Economy System

### Mortal Economy

**Primary Currency:**
- **Primeval Stones** - Common currency for mortals
- Used for cultivation, trades, missions
- Range: 1-100 per transaction typically

**Other Tradeable Resources:**
- **Gu Materials** - Crafting components (varying rarity)
- **Information** - Recipes, location intel, NPC secrets
- **Favors** - Connection-based currency from relationships

**Trading Venues:**
- **Clan Markets** - Limited selection, clan-specific Gu
- **Merchant Caravans** - Random inventory, good deals
- **Black Markets** - Demonic path Gu, risky, affects reputation

**Financial Management:**
- Moderate pacing with many small decisions
- Balance immediate needs vs. long-term investments
- Resource drains during cultivation
- Opportunity costs (spend on Gu vs. materials vs. information)

---

## Immortal Stage Overview (Rank 6-8)

### Tribulation & Rank 6 Ascension

**The Earthly Calamity:**
When ready to ascend (typically 50-100 years old):

**Tribulation Components:**
- **Heaven Tribulation** - Combat challenge
- **Earth Tribulation** - Resource management test
- **Human Tribulation** - Social/political challenge

**Success Rate Based On:**
- Preparation (collected special Gu)
- Path attainment levels
- Allied assistance
- Resource investment

**Possible Outcomes:**
- **Success** - Become Rank 6 Immortal, receive blessed land
- **Failure** - Death (run ends, inheritance triggers)
- **Partial Success** - Survive but damaged/weakened start

### Blessed Land Management

**Your Personal Dimension:**
Upon ascension, receive a blessed land with:
- **Size** - Resource capacity
- **Dao Marks** - Path affiliations, affects cultivation options
- **Resource Nodes** - Generate immortal materials over time
- **Time Flow** - Usually 1:20 or 1:30 vs. outside world
- **Tribulation Counter** - Time until next tribulation

**Blessed Land Activities:**
- Plant immortal materials (long-term investment)
- Raise immortal beasts (combat resources)
- Build structures (refinement rooms, cultivation chambers)
- Nurture resource points (improve land quality)
- Invite guests (other Immortals, potential co-op)

### Immortal Gameplay Changes

**New Resources:**
- **Immortal Essence Stones** - Immortal currency (much more valuable)
- **Dao Marks** - Permanent path attainment upgrades
- **Immortal Gu** - Rank 6+ Gu (significantly more powerful)
- **Tribulation Points** - Countdown to next tribulation

**Tribulation System:**
- Every 50-100 turns: face tribulation
- **Earthly Tribulation** - Every tribulation
- **Heavenly Tribulation** - Every 5 tribulations
- Must prepare defenses, Gu, strategies
- Failure = death OR severe damage + resource loss

**Immortal Politics:**
- Join or create immortal factions
- Trade at Treasure Yellow Heaven (immortal auction house)
- Access ancient inheritances (Rank 7+ difficulty)
- Face immortal vendettas (much more dangerous rivals)

**Territory Expansion:**
- Annex grotto heavens
- Establish influence zones
- Control mortal clans/sects as resource bases
- High-stakes immortal battles

### Immortal Progression Path

**Rank 6 → 7:**
- Requires vast resources
- Must refine Rank 7 Immortal Gu
- Face major tribulation
- Choose path specialization direction

**Rank 7 → 8:**
- Requires rare immortal materials
- Multiple grandmaster path attainments
- Create signature killer moves
- Establish dao foundation

**Rank 8 → 9:**
- Gather resources for Venerable attempt
- Research rarest Gu (love, fate, etc.)
- Build alliances or eliminate rivals
- Prepare for ultimate tribulation

---

## Venerable Ascension (Rank 9)

### The Ultimate Challenge

**Requirements:**
- Multiple Rank 8 Immortal Gu
- Grandmaster attainment in 3+ paths
- Massive resource stockpile
- Complex tribulation preparation
- Often requires unique innovative method

**Venerable Tribulation:**
- Multi-stage, extremely difficult
- Tests everything you've built over the run
- Can take multiple turns to resolve
- Creative solutions rewarded

**Victory:**
- Achieve Rank 9 Venerable
- Game complete for this run
- Unlock major inheritance bonuses
- New game+ options available

---

## Inheritance System (Meta-Progression)

### Creating Inheritances

**Upon Death or Completion:**
Leave behind resources for future runs:

**Inheritance Types:**

**Mortal Inheritances (Rank 1-5):**
- Easier to create
- Accessible early in next run
- Moderate benefits
- Examples:
  - Gu formula inheritances (unlock specific Gu)
  - Killer move inheritances (start knowing techniques)
  - Resource caches (hidden in specific locations)

**Immortal Inheritances (Rank 6+):**
- Require Rank 6 to access
- Major benefits
- Locked until immortal ascension
- Examples:
  - Connection inheritances (start with positive NPC relations)
  - Blessed land seeds (better starting blessed lands)
  - Attainment insights (head start on paths)

**Venerable Inheritances:**
- Unlock entirely new game modes
- Start with unique advantages
- Access forbidden techniques
- Permanent unlocks (new clans, regions, etc.)

### Spending Inheritance Points

**Between Runs:**
- Unlock new clans/tribes in different regions
- Improve aptitude roll chances
- Unlock special starting positions
- Discover new locations
- Add unique Gu to generation pool

---

## AI Systems

### Card Generation System

**Gu Cards (Rank 1-5 Mortal):**
```
Parameters:
- Rank: 1-5
- Path: One of 10 main paths
- Type: Offensive/Defensive/Utility/Economic
- Rarity: Common/Uncommon/Rare/Legendary
- Clan affiliation: Affects theme/name
```

**Immortal Gu (Rank 6-8):**
```
Additional parameters:
- Immortal material requirements
- Tribulation resistance bonuses
- Dao mark generation
- Multi-path synergies
```

**Event Cards:**
```
Parameters:
- Location type
- Player's current rank
- Reputation (Righteous/Demonic)
- Active connections
- Time progression in game
- Player's stated goals
```

**Mission/Quest Cards:**
```
Parameters:
- Clan/faction affiliation
- Difficulty tier
- Reward types
- Success/failure consequences
- Current player objectives
```

### Goal-Directed Event Generation

**Player Intent System:**
- Player can specify goals via:
  - Natural language prompt ("I want to find inheritance related to fire path")
  - Menu selections ("Focus: Movement Gu", "Focus: Blood Path", etc.)
- AI weights event generation toward player goals
- Creates feeling of active searching and agency
- More specific goals = more targeted events

**Generation Examples:**
- Goal: "Looking for movement Gu"
  - Generate merchants with movement Gu
  - Events about movement path inheritances
  - NPCs who know movement techniques
  - Challenges that reward movement Gu

- Goal: "Need blood path resources"
  - Blood path beast hunting opportunities
  - Blood path expert NPCs appear
  - Blood path inheritance sites
  - Blood path material gathering events

### Dynamic Balancing

**Metrics to Track:**
- Win rate per starting clan
- Average death rank
- Most used Gu types and paths
- Most successful killer moves
- Bottleneck identification (where do players die most?)
- Event completion rates
- Resource bottlenecks

**Adjustment Systems:**
- If paths dominate → buff underused paths
- If clans have low win rates → improve starting bonuses
- If tribulations too hard/easy → adjust difficulty curves
- Generate new Gu to counter dominant strategies
- Balance event rewards based on completion difficulty

**Balance Database Schema:**
```json
{
  "card_id": "flame_burst_gu_001",
  "rank": 3,
  "path": "fire",
  "essence_cost": 15,
  "effect_power": 25,
  "times_used": 147,
  "win_rate_when_used": 0.58,
  "avg_turn_acquired": 45,
  "synergy_cards": ["heat_vision_gu", "explosion_gu"]
}
```

---

## The 10 Main Paths

Each path has distinctive mechanics and playstyle:

1. **Strength Path** - Direct damage, high essence cost, straightforward effects
2. **Wisdom Path** - Card draw, information gathering, deduction mechanics
3. **Blood Path** - Life manipulation, sacrifice effects, healing
4. **Refinement Path** - Gu creation/modification, meta-mechanics
5. **Transformation Path** - Flexibility, adaptation, form changes
6. **Enslavement Path** - Control effects, stealing, manipulation
7. **Poison Path** - Damage over time, debuffs, area denial
8. **Dark Path** - Stealth, assassination, surprise mechanics
9. **Light Path** - Defense, protection, revelation
10. **Food Path** - Resource generation, sustainability, economy

---

## Core Design Pillars

### 1. Time Pressure is Real
- Aging is constant and visible
- Lifespan Gu are valuable and rare
- Every decision has opportunity cost in time
- Rush vs. prepare is core tension

### 2. Aggressive Play is Rewarded (But Risky)
- Taking risks opens better opportunities
- Playing safe is slower but more stable
- Player chooses their risk tolerance
- High risk = high reward (but high mortality)

### 3. Reactive + Proactive Gameplay
- Events happen to you (reactive)
- You set goals and seek them out (proactive)
- Blend creates dynamic, engaging experience
- Neither purely random nor purely controlled

### 4. Preparation Matters
- Combat is tactical and turn-based
- Can prepare counter-Gu for known enemies
- Intelligence gathering is valuable
- Strategic planning pays off

### 5. Every Run Teaches
- Inheritance system ensures progress
- Discover new strategies each run
- Unlock new options and starting positions
- Meta-progression feels meaningful

### 6. Depth Through Simplicity
- Real-time with pause = intuitive
- Moderate pacing prevents overwhelm
- Many small financial decisions create texture
- Complex strategies emerge from simple rules

---

## Development Priorities

### Phase 1: Mortal Stage Prototype
- Real-time with pause system
- Basic cultivation mechanics
- Simple combat system
- A few Gu examples per path
- One clan to start
- Basic event generation
- Core time/aging pressure

### Phase 2: Event & AI Systems
- Goal-directed event generation
- AI Gu card generation with balancing
- Multiple clans with unique Gu
- Expanded location system
- Travel mechanics
- NPC connection system

### Phase 3: Full Mortal Experience
- All 10 paths fleshed out
- Killer move system
- Comprehensive event library
- Reputation system
- Advanced combat tactics
- Rank advancement challenges

### Phase 4: Immortal Stage
- Tribulation system
- Blessed land management
- Immortal Gu and resources
- Immortal politics and factions
- Territory expansion

### Phase 5: Endgame & Meta
- Venerable ascension
- Inheritance system implementation
- Meta-progression unlocks
- New regions (Northern Plains, Central Continent)
- Balancing and polish

---

## Technical Considerations

### Time Scale Variables (To Be Determined)
- Real seconds to in-game days ratio
- Cultivation acceleration rates
- Travel time scaling
- Closed door cultivation speedup multiplier

### Notification System
- Event importance thresholds
- Notification UI design
- Queue management
- Player attention management

### Save System
- Pause-anywhere save capability
- Run persistence
- Inheritance data storage
- Balance tracking database

### AI Integration
- LLM for event/Gu generation
- Prompt templates for consistency
- Balance feedback loops
- Performance optimization

---

## Open Questions for Future Development

1. Specific time scaling numbers (seconds to days)
2. Exact Gu stats and balance formulas
3. Combat system detailed mechanics
4. UI/UX flow and screen layouts
5. Specific clan bonuses and unique Gu
6. Event probability distributions
7. Inheritance point economy
8. Co-op possibilities (blessed land guests)

---

## Next Steps

1. Prototype basic real-time with pause system
2. Implement simple cultivation mechanics
3. Create a few example Gu per path
4. Build basic event notification system
5. Test time pressure and aging mechanics
6. Iterate on pacing and decision frequency