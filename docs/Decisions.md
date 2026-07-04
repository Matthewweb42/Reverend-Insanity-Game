# Decision Log

This document tracks all significant technical and design decisions made during planning and development.

---

## How to Use This Document

When making a decision:
1. Add entry with date and context
2. List options considered
3. Document the choice and rationale
4. Note any trade-offs accepted

Format:
```markdown
### DEC-XXX: [Brief Title]
**Date:** YYYY-MM-DD
**Status:** DECIDED | REVISIT | SUPERSEDED by DEC-XXX
**Context:** Why this decision needed to be made
**Options:**
1. Option A - pros/cons
2. Option B - pros/cons
**Decision:** What we chose
**Rationale:** Why we chose it
**Trade-offs:** What we're accepting
```

---

## Decisions

### DEC-001: Game Engine Choice
**Date:** 2025-01-22
**Status:** DECIDED

**Context:** Need to choose a game engine/framework for development.

**Options:**
1. **Godot 4** - Free, GDScript is accessible, good 2D/UI, learning it in class
2. **Unity** - Large ecosystem, C# support, but licensing concerns
3. **Web-based (React + Canvas)** - Very AI-friendly for coding, but not a "real" game engine
4. **Pygame** - Python native, but limited platform support

**Decision:** Godot 4 with GDScript

**Rationale:**
- Already learning it in a class (reduced ramp-up time)
- Good 2D and UI support for a text-heavy game
- Free and open source
- GDScript is simple enough for AI-assisted coding
- Exports to PC easily

**Trade-offs:**
- Smaller community than Unity
- GDScript has less AI training data than Python/JS

---

### DEC-002: AI Generation Architecture
**Date:** 2025-01-22
**Status:** DECIDED

**Context:** How to integrate AI generation into the game.

**Options:**
1. **Direct API calls from Godot** - Simpler, no middleware
2. **Python middleware server** - Better separation, caching, prompt management
3. **GDExtension with Python** - Complex, overkill

**Decision:** Python FastAPI server as middleware

**Rationale:**
- Keeps LLM logic separate from game code
- Python is better for prompt engineering iteration
- Can swap LLMs without touching Godot
- Easier caching and fallback logic
- Better async handling for API calls

**Trade-offs:**
- Must run two processes during development
- Extra complexity in deployment

---

### DEC-003: LLM Provider
**Date:** 2025-01-22
**Status:** DECIDED

**Context:** Which LLM to use for content generation.

**Options:**
1. **Claude API** - Good structured output, reasoning ability
2. **GPT-4** - Popular, good quality
3. **Local (Ollama/Llama)** - Free, private, but lower quality
4. **Hybrid** - Claude for complex, local for simple

**Decision:** Claude API for now

**Rationale:**
- Good at structured JSON output
- Strong reasoning for game balance
- Can experiment and see how far AI generation can go
- Cost is acceptable for development

**Trade-offs:**
- API costs during development
- Dependency on external service
- May need fallback strategy

**Future consideration:** Could add Ollama for development/testing to reduce costs

---

### DEC-004: Database Choice
**Date:** 2025-01-22
**Status:** DECIDED

**Context:** How to persist generated content, saves, and meta-progression.

**Options:**
1. **SQLite** - Simple, file-based, no setup
2. **PostgreSQL** - Powerful, but overkill for single-player
3. **JSON files** - Simplest, but harder to query
4. **MongoDB** - Document store, good for varied content

**Decision:** SQLite

**Rationale:**
- Zero configuration
- File-based works great for single-player
- SQL queries useful for balance analysis
- Easy to back up (just copy the file)
- Python has great SQLite support

**Trade-offs:**
- Would need migration for multiplayer
- Less flexible than document stores for varied schemas

---

### DEC-005: Generation Strategy
**Date:** 2025-01-22
**Status:** DECIDED

**Context:** When and how to generate content.

**Options:**
1. **Pure runtime** - Generate everything on demand
2. **Pre-generated pools** - Generate batches offline, draw from pool
3. **Hybrid** - Cache generated content, generate on cache miss

**Decision:** Generate on demand with caching (hybrid approach)

**Rationale:**
- Maximum context-awareness (considers player state)
- Cached content provides variety without repeated API calls
- Can warm cache in background during slow moments
- Fallback pool handles API failures

**Trade-offs:**
- Initial generation has latency
- API costs during gameplay
- Cache management complexity

---

### DEC-006: AI Generation Constraints
**Date:** 2025-01-22
**Status:** DECIDED

**Context:** How tightly to constrain AI generation.

**Options:**
1. **Strict** - Hard numeric bounds, limited creativity
2. **Loose** - General guidelines, more creative freedom
3. **Adaptive** - Start loose, tighten based on balance data

**Decision:** Start loose, tighten if necessary

**Rationale:**
- Want to see what AI can create
- Core experiment is pushing AI generation limits
- Can add constraints when balance problems appear
- Validation catches truly broken outputs

**Trade-offs:**
- May have more balance issues initially
- More variance in generated content quality

---

### DEC-007: Combat System Type
**Date:** 2025-01-22
**Status:** DECIDED

**Context:** Real-time or turn-based combat?

**Options:**
1. **Real-time with pause** - Consistent with main game
2. **Turn-based** - More tactical, clearer decisions
3. **Hybrid** - Real-time with turn-based resolution

**Decision:** Turn-based tactical combat

**Rationale:**
- Clearer tactical decisions
- Better suits card-based Gu system
- Preparation and counter-play require deliberate choices
- Separates combat mode from main game flow cleanly

**Trade-offs:**
- Breaks from real-time flow of main game
- May feel slower to some players

---

### DEC-008: Graphics Approach
**Date:** 2025-01-22
**Status:** DECIDED

**Context:** What visual style and how much art effort.

**Options:**
1. **Pixel art** - Classic roguelike feel
2. **Hand-drawn** - Distinctive but time-consuming
3. **AI-generated art** - Novel, fits the project theme
4. **Minimal/text-based** - Focus on systems, not visuals

**Decision:** Minimal/text-based with AI-generated tile maps

**Rationale:**
- Focus is on AI generation and systems
- Minimizes art workload
- Can always add art later
- Text-heavy games can be very engaging (Dwarf Fortress, Caves of Qud)

**Trade-offs:**
- Less visually appealing initially
- May limit audience appeal

---

### DEC-009: Target Platform
**Date:** 2025-01-22
**Status:** DECIDED

**Context:** What platform(s) to support.

**Options:**
1. **PC only** - Simplest
2. **PC + Web** - Broader reach
3. **PC + Mobile** - Different input paradigm

**Decision:** PC only (initially)

**Rationale:**
- Simplest development path
- Full keyboard/mouse support
- No platform-specific constraints
- Can port later if successful

**Trade-offs:**
- Limited initial audience
- No mobile market

---

### DEC-010: Version Control Strategy
**Date:** 2025-01-22
**Status:** DECIDED

**Context:** How to manage code changes.

**Options:**
1. **Main branch only** - Simple but risky
2. **Feature branches** - Standard practice
3. **Trunk-based** - Requires good CI/CD

**Decision:** Feature branches

**Rationale:**
- Clean separation of work
- Can experiment without breaking main
- Easy to review changes
- Standard practice

**Trade-offs:**
- Merge conflicts possible
- Need discipline to keep branches short-lived

---

### DEC-011: Godot Version
**Date:** 2025-01-23
**Status:** DECIDED

**Context:** Need to lock in specific Godot version.

**Decision:** Godot 4.5.1

**Rationale:** This is the version being used in the class.

---

### DEC-012: Time Scale
**Date:** 2025-01-23
**Status:** DECIDED

**Context:** How fast should game time flow relative to real time?

**Options:**
1. 1 second = 1 day (very fast)
2. 1 second = 5 days (fast)
3. 10 seconds = 1 day (slow, original estimate)

**Decision:** 1 real second = 5 game days at 1x speed

**Rationale:**
- 100 years (natural lifespan) = ~2 hours real time
- Full run to Venerable (~600 years) = ~6 hours at average speed
- Allows meaningful time pressure without excessive waiting
- Speed controls (1x-10x) give player flexibility

**Derived values:**
- 1x speed: 5 days/second
- 2x speed: 10 days/second
- 5x speed: 25 days/second
- 10x speed: 50 days/second
- Closed door: 125 days/second (25x multiplier)

---

### DEC-013: Generation Timing
**Date:** 2025-01-23
**Status:** DECIDED

**Context:** When to generate AI content - pre-generate pools or on-demand?

**Decision:** Pure on-demand generation with caching

**Rationale:**
- Maximum context awareness
- No generation during combat (pre-generate enemy loadout when combat starts)
- Cache generated content for potential reuse
- Fallback pool for API failures

**Trade-offs:**
- Potential latency on first generation
- API costs during gameplay

---

### DEC-014: Lifespan from Rank Advancement
**Date:** 2025-01-23
**Status:** DECIDED

**Context:** Should ranking up extend lifespan automatically?

**Options:**
1. Yes - each rank adds years (original assumption)
2. No - must acquire lifespan extensions actively

**Decision:** NO lifespan from rank advancement

**Rationale:**
- Matches source material (Reverend Insanity novel)
- Creates meaningful resource pressure
- Lifespan Gu become valuable quest objectives
- Enables righteous vs demonic path choices
- More interesting gameplay than automatic extensions

**Impact:**
- Players must actively seek Lifespan Gu
- Demonic methods become tempting alternatives
- Time pressure is real throughout the game

---

### DEC-015: Aging Penalty System
**Date:** 2025-01-23
**Status:** DECIDED

**Context:** How should aging penalties work?

**Options:**
1. Fixed age thresholds (40, 50, 60, etc.)
2. Percentage-based (scales with max lifespan)

**Decision:** Percentage-based aging penalties

**Rationale:**
- A 600-year-old with 600 year lifespan is "young"
- Penalties should reflect % of life remaining, not absolute age
- More intuitive as lifespan extends
- Pressure stacks toward end of life, not arbitrarily

**Thresholds:**
- 50%+ remaining: Prime (no penalties)
- 30-50% remaining: First Signs (-5% cult)
- 15-30% remaining: Decline (-15% cult, -5% combat)
- 5-15% remaining: Severe (-35% cult, -15% combat)
- 0-5% remaining: Death's Door (-60% cult, -30% combat)

---

### DEC-016: Closed Door Cultivation Speed
**Date:** 2025-01-23
**Status:** DECIDED

**Context:** How much should time accelerate during closed door cultivation?

**Options:**
1. 10x (mild)
2. 25x (moderate)
3. 50x (extreme)

**Decision:** 25x multiplier

**Rationale:**
- 1 real minute = ~2 game years in closed door
- Significant commitment but not instant
- Meaningful trade-off (miss events, age faster)
- Allows focused cultivation sessions

---

### DEC-017: Death Trigger
**Date:** 2025-01-23
**Status:** DECIDED

**Context:** What happens when lifespan reaches zero?

**Options:**
1. Instant death
2. Death's door period then death
3. Final narrative event

**Decision:** Triggers final narrative event

**Rationale:**
- Death should be meaningful, not abrupt
- Allows last-ditch options (zombie transformation, etc.)
- Creates narrative closure
- Player has agency even at the end

**Implementation:**
- Game pauses when lifespan = 0
- Present narrative moment
- Offer options based on available resources
- Proceed to inheritance creation

---

### DEC-018: Demonic Path Lifespan Gu Access
**Date:** 2025-01-23
**Status:** DECIDED

**Context:** Should demonic life extension methods block Lifespan Gu usage?

**Decision:** NO - Lifespan Gu always works

**Rationale:**
- Other consequences lock players into demonic path (reputation, enemies)
- Pure Lifespan Gu should remain the "clean" option
- Doesn't make sense mechanically to block it
- Demonic methods have their own drawbacks

---

### DEC-019: Stage Structure
**Date:** 2025-01-26
**Status:** DECIDED

**Context:** How to structure progress within each rank?

**Options:**
1. Single bar per rank (simple)
2. Multiple stages with different mechanics
3. Four stages matching source material

**Decision:** 4 stages per rank: Initial → Middle → Upper → Peak

**Rationale:**
- Matches source material (Reverend Insanity novel)
- Provides granular sense of progress
- Creates natural milestone moments
- Each stage can unlock new capabilities
- Stage breakthroughs are deterministic (reach threshold)
- Rank breakthroughs remain the high-stakes moments

---

### DEC-020: Progress Decay System
**Date:** 2025-01-26
**Status:** DECIDED

**Context:** Should cultivation progress decay when not actively cultivating?

**Options:**
1. No decay (progress is permanent)
2. Full decay (can lose stages/ranks)
3. Partial decay (cannot drop stages)

**Decision:** Progress decays slowly but cannot drop below current stage floor

**Rationale:**
- Creates meaningful time pressure
- Rewards consistent cultivation
- Prevents indefinite stalling
- Protects hard-earned milestones (no losing stages)
- -0.5 points/day idle, -0.25 points/day active but not cultivating

**Trade-offs:**
- Adds complexity to time management
- May feel punishing to some players

---

### DEC-021: Aptitude Impact
**Date:** 2025-01-26
**Status:** DECIDED

**Context:** How much should aptitude (talent grade) affect cultivation?

**Options:**
1. Minor impact (10-20% difference)
2. Moderate impact (30-50% difference)
3. Significant impact (50%+ difference)

**Decision:** Significant impact - aptitude matters greatly

**Rationale:**
- Matches source material (aptitude is destiny-defining)
- Creates meaningful character builds
- A-grade: 1.5x cultivation speed, +15% breakthrough
- B-grade: 1.2x cultivation speed, +8% breakthrough
- C-grade: 1.0x baseline
- D-grade: 0.7x cultivation speed, -10% breakthrough
- Low aptitude can be overcome but requires more resources/time

**Trade-offs:**
- D-grade runs are significantly harder
- May feel unfair to RNG-sensitive players
- Blessings/Burdens system can offset

---

### DEC-022: Breakthrough Mechanics
**Date:** 2025-01-26
**Status:** DECIDED

**Context:** How should rank breakthroughs work?

**Options:**
1. Automatic (reach requirement, advance)
2. Pure RNG (dice roll)
3. Prepared dice roll (bonuses from preparation)

**Decision:** Prepared dice roll with multiple attempts allowed

**Rationale:**
- Stage breakthroughs are automatic (reach points, advance)
- Rank breakthroughs are dice rolls with preparation bonuses
- Factors: aptitude, resources stockpiled, Gu equipped, age
- Failed attempts cost resources but allow retry
- Creates tension and meaningful preparation
- No cooldown between attempts (just resource cost)

**Base success rates:**
- Rank 1→2: 70%
- Rank 2→3: 60%
- Rank 3→4: 50%
- Rank 4→5: 40%
- Rank 5→6: 25% (tribulation)

---

### DEC-023: Closed Door Cultivation Mode
**Date:** 2025-01-26
**Status:** DECIDED

**Context:** Should closed door cultivation provide progress bonuses?

**Options:**
1. Progress bonus (2x cultivation speed)
2. Time skip only (no bonus)
3. Both bonus and time skip

**Decision:** Time skip only - no cultivation progress bonus

**Rationale:**
- 25x time acceleration is already significant
- ~2 game years per real minute
- Trade-off is missing events and aging faster
- No additional cultivation bonus needed
- Keeps the mechanic simple and understandable
- Main benefit is uninterrupted focus time

---

### DEC-024: Character Creation System
**Date:** 2025-01-26
**Status:** DECIDED

**Context:** How should character creation work?

**Options:**
1. Point-buy system
2. Random generation
3. Blessings & Burdens (advantages balanced by disadvantages)

**Decision:** Blessings & Burdens system

**Rationale:**
- Choose advantages (better aptitude, starting Gu, clan position)
- Must balance with equal disadvantages (enemies, debts, obligations)
- Creates unique starting situations
- Encourages varied playstyles
- Matches roguelike tradition (e.g., DCSS backgrounds)
- More interesting than pure point-buy

**Examples:**
- Blessing: "Clan Heir" (+resources, +standing)
- Burden: "Expected to Succeed" (clan missions, scrutiny)
- Blessing: "A-Grade Aptitude" (faster cultivation)
- Burden: "Coveted Talent" (recruitment attempts, kidnapping risk)

---

### DEC-025: Relic Gu System
**Date:** 2025-01-26
**Status:** DECIDED

**Context:** Can Gu directly advance cultivation stages?

**Options:**
1. No direct advancement (must earn all progress)
2. Full advancement (can skip stages and ranks)
3. Limited advancement (stages only, not ranks)

**Decision:** Relic Gu can advance stages within current rank only

**Rationale:**
- Matches source material (certain Gu boost cultivation)
- Creates valuable quest objectives
- Cannot cross rank boundaries (would skip tribulations)
- Cannot be used at Peak stage (must do breakthrough normally)
- Rare and valuable - strategic choice when to use

**Example Relic Gu:**
- Minor Relic: Advance 1 stage (uncommon)
- Major Relic: Advance 2 stages (rare)
- Cannot use at Peak (no effect)

---

### DEC-026: Combat Action Economy
**Date:** 2025-01-26
**Status:** DECIDED

**Context:** How many Gu can be played per turn?

**Options:**
1. Essence-limited only (play as many as you can afford)
2. Fixed limit (e.g., 2-3 Gu per turn) + essence cost
3. Action points system
4. Attainment-based limit + essence cost

**Decision:** Attainment-based limit + essence cost

**Rationale:**
- Path Attainment determines max Gu activations per turn for that path
- Higher attainment = more simultaneous Gu usage
- Still bounded by essence pool
- Creates meaningful progression within paths
- Rewards specialization over generalization

**Attainment Levels (from source material):**
- Ordinary: Baseline understanding
- Master: Deep expertise, unlocks killer moves
- Quasi-Grandmaster: Exceptional mastery
- Grandmaster: Pinnacle of mortal understanding
- Quasi-Great Grandmaster: Legendary, immortal-level insight
- Great Grandmaster: Supreme mastery (only ~4 ever achieved in Refinement Path)

**Implementation (Gu per turn from this path):**
- Ordinary: 1-2 Gu per turn
- Master: 3-4 Gu per turn + killer moves
- Quasi-Grandmaster: 5 Gu per turn + advanced killer moves
- Grandmaster: 6 Gu per turn + supreme killer moves
- Quasi-Great Grandmaster+: 7+ Gu, unique abilities

**Note:** Attainment is extremely difficult to raise. Most cultivators never reach Master in any path. Grandmaster is legendary. Great Grandmaster is practically mythical.

---

### DEC-027: Combat Positioning System
**Date:** 2025-01-26
**Status:** DECIDED

**Context:** Should there be positioning/movement in combat?

**Options:**
1. No positioning (abstract)
2. Simple ranges (melee/ranged zones)
3. Grid-based tactical

**Decision:** No positioning - stat-based resolution

**Rationale:**
- Combat resolution based on stats, not board position
- Evasion vs Attack determines hit/miss/partial
- Different defense types for different attack types:
  - Physical attacks vs Physical Defense/Evasion
  - Soul attacks vs Soul Defense/Willpower
  - Mind attacks vs Mental Defense/Wisdom
  - Elemental attacks vs appropriate resistances
- Preparation and build matter more than tactical movement
- Simpler to implement, faster combat flow
- Focus on Gu selection and resource management

**Resolution Formula:**
```
Hit Roll = Attacker's Accuracy + Random(-10, +10)
vs
Dodge Roll = Defender's Evasion + Random(-10, +10)

If Hit > Dodge + 20: Full damage
If Hit > Dodge: Partial damage (50-80%)
If Hit <= Dodge: Miss (0 damage)
```

---

### DEC-028: Multi-Enemy Encounters
**Date:** 2025-01-26
**Status:** DECIDED

**Context:** How do multi-enemy encounters work?

**Options:**
1. Focus fire one at a time
2. AoE vs single-target selection
3. Formation system (front/back rows)

**Decision:** Target selection with group bonuses/penalties, no formations

**Rationale:**
- Player chooses targets for single-target Gu
- AoE Gu hit all enemies
- Enemies can coordinate attacks for bonuses
- Player gets debuffs when outnumbered:
  - 2v1: -10% evasion
  - 3v1: -20% evasion, -10% accuracy
  - 4v1+: -30% evasion, -20% accuracy
- Enemies get coordination bonuses when grouped
- No physical positioning - abstract combat space
- Encourages preparation and picking fights wisely

---

### DEC-029: Enemy Killer Moves
**Date:** 2025-01-26
**Status:** DECIDED

**Context:** Can enemies use killer moves?

**Options:**
1. No - player exclusive
2. Yes - bosses/elites only
3. Yes - any enemy with Master+ attainment

**Decision:** Yes - based on enemy background and attainment

**Rationale:**
- Enemies with sufficient attainment and Gu can use killer moves
- Low-level random encounters: No killer moves
- Elite enemies with deep foundations: May have 1-2 killer moves
- Bosses: Likely have signature killer moves
- Named NPCs: Based on their established attainment
- Creates meaningful threat escalation
- Rewards intelligence gathering ("this enemy knows X killer move")

**Enemy Killer Move Tiers:**
- Mook/Random: 0% chance
- Trained/Clan: 10% chance of basic killer move
- Elite/Veteran: 50% chance, 1-2 moves
- Boss/Named: 90% chance, 2-4 signature moves

---

### DEC-030: Environmental Combat Effects
**Date:** 2025-01-26
**Status:** DECIDED

**Context:** Are there environmental effects in combat?

**Options:**
1. No - keep combat simple
2. Yes - location-based (static per area)
3. Yes - AI-generated per encounter

**Decision:** Yes - AI-generated based on location context

**Rationale:**
- Environment generated based on map location and context
- Examples:
  - Forest: +20% evasion for Dark Path users, fire spreads
  - Swamp: Poison damage over time, movement Gu less effective
  - Mountain peak: Wind effects, flying Gu bonuses
  - Underground: No light-based bonuses, cramped (AoE reduced)
  - Near water: Water path bonuses, fire path penalties
- Adds tactical layer without positioning complexity
- Rewards preparation (know the terrain)
- AI generates 1-3 environmental effects per combat

---

### DEC-031: Fleeing Reputation Cost
**Date:** 2025-01-26
**Status:** DECIDED

**Context:** How does fleeing affect reputation?

**Options:**
1. No cost (tactical retreat)
2. Fixed cost (-5 to -10)
3. Contextual based on relative strength

**Decision:** Contextual based on relative strength comparison

**Rationale:**
- Fleeing stronger enemy: No reputation loss to you, +reputation to them
- Fleeing equal enemy: Small reputation loss (-5 to -10)
- Fleeing weaker enemy: Significant reputation loss (-15 to -25)
- Fleeing much weaker: Major reputation loss (-30+), story consequences

**Formula:**
```
Strength Diff = (Enemy Rank × 10 + Enemy Stage) - (Player Rank × 10 + Player Stage)

If Strength Diff > 10: No loss (sensible retreat)
If Strength Diff 0-10: -5 reputation
If Strength Diff -5 to 0: -10 reputation
If Strength Diff -10 to -5: -20 reputation
If Strength Diff < -10: -30 reputation, potential story event
```

**Additional factors:**
- Public vs private fight (witnesses = more reputation impact)
- Previous boasts/challenges (backing down after talking big = worse)
- Protecting others (fleeing while abandoning allies = much worse)

---

### DEC-033: Success Chance Visibility
**Date:** 2025-01-26
**Status:** DECIDED

**Context:** How visible should success chances be to the player?

**Options:**
1. Hidden (pure roleplay, no numbers)
2. Vague hints ("likely", "risky")
3. Exact percentages shown
4. Tiered based on Wisdom stat

**Decision:** Tiered visibility based on Wisdom/Intelligence stat

**Rationale:**
- Low Wisdom: No numbers, just narrative hints
- Medium Wisdom: Vague descriptors ("likely to succeed", "very risky")
- High Wisdom: Approximate percentages (60-70%)
- Very High Wisdom: Exact percentages
- Rewards Wisdom Path investment
- Creates meaningful stat interaction
- Players can choose to build toward more information

**Implementation:**
- Wisdom < 20: "You have no idea what might happen"
- Wisdom 20-40: "Seems risky" / "Looks promising"
- Wisdom 40-60: "About even odds" / "Good chance"
- Wisdom 60-80: "~65% success"
- Wisdom 80+: "67.3% success"

---

### DEC-034: Save System
**Date:** 2025-01-26
**Status:** DECIDED

**Context:** Should players be able to save-scum events?

**Options:**
1. Save anywhere (standard roguelike)
2. Ironman only (auto-save after decisions)
3. Both modes available

**Decision:** Standard save anywhere

**Rationale:**
- This is a single-player game
- Players should play how they want
- Ironman mode can be added later as optional
- Focus on making the game fun, not punishing
- Runs are long (~6 hours) - save protection matters

---

### DEC-035: Event Chain System (Storylines)
**Date:** 2025-01-26
**Status:** DECIDED

**Context:** How to handle event chains across long time periods?

**Options:**
1. Events resolve immediately, no long chains
2. Flags track state, events reference later
3. Active "storylines" that persist and evolve

**Decision:** Active storyline system with AI management

**Rationale:**
- Limited number of concurrent active storylines
- Three storyline lengths:
  - **Short**: 1 decision, resolves immediately
  - **Medium**: 3-5 decisions over months/years
  - **Long**: 10+ decisions over decades
- All storylines have early exit/resolution points
- AI manages storyline progression by asking:
  - "Did the player do something that changes the next step?"
  - "What's the most likely next step?"
  - "Is the storyline close to resolution?"
  - "Where are related NPCs in their part of the story?"
- NPCs have their own storyline involvement tracked

**Storyline Limits:**
- 1-2 Long storylines active
- 3-5 Medium storylines active
- Unlimited Short events

---

### DEC-036: Scripted/Forced Events
**Date:** 2025-01-26
**Status:** DECIDED

**Context:** Should events ever force specific outcomes?

**Options:**
1. Never - always player choice
2. Rarely - major story beats only
3. Yes - some events are consequences

**Decision:** Never force outcomes, but have predetermined world events

**Rationale:**
- Player always has agency in their personal decisions
- However, the world has ~12 predetermined "Epoch Events":
  - Massive inheritances opening
  - Region-wide competitions
  - Catastrophes or wars
  - Ancient beings awakening
- These events happen regardless of player action
- Player can engage, ignore, or try to exploit them
- Events have buildup (rumors, smaller events leading up)
- Creates living world feeling without removing player agency

**Epoch Event Examples:**
- "The Verdant Great Inheritance opens after 500 years"
- "The Demonic Path Alliance declares war on Central Continent"
- "An ancient Rank 8 Gu Immortal emerges from seclusion"
- "The once-in-a-century Southern Border Competition begins"

---

### DEC-037: Concurrent Goals Limit
**Date:** 2025-01-26
**Status:** DECIDED

**Context:** How many concurrent goals can players have?

**Options:**
1. 1 primary goal only
2. 2-3 active goals
3. 3-5 active goals
4. Unlimited with diminishing AI focus

**Decision:** 3-5 active goals

**Rationale:**
- Enough variety to have multiple pursuits
- Not so many that AI loses focus
- Subject to adjustment based on AI model capabilities
- Goals influence event generation
- Can reprioritize goals anytime
- Completed goals free up slots

**Goal Priority System:**
- Primary goal (1): 50% event generation weight
- Secondary goals (2-4): Remaining 50% split
- Goals can be reordered anytime

---

### DEC-039: Card / Deck-Building as Core Framing
**Date:** 2026-07-03
**Status:** DECIDED

**Context:** The game needs a concrete moment-to-moment interaction model. Decided to frame the whole game as a card RPG where Gu worms ARE cards and building your Gu loadout is deck-building.

**Options:**
1. Aperture = deck (equipped Gu are your deck, draw a hand each combat)
2. Collection + multiple built decks (swap decks per fight)
3. Draft/roguelike single run-deck that grows over a run

**Decision:** Aperture = deck

**Rationale:**
- Simplest model; one collection → aperture → deck, no separate deck-builder UI
- Matches existing docs (Combat.md already loads "aperture as hand")
- The strategic choice is *which Gu to slot into limited aperture slots* — that IS the deck-building decision
- Aperture slot count (10 at Rank 1 → 50 at Rank 5) naturally bounds deck size

**Implementation:**
- Equipped aperture Gu form the draw pile each combat
- Draw an opening hand, draw 1+ per turn, discard/reshuffle when pile empties
- No separate "deck" object — the aperture list is the deck
- Between combats: reorganize aperture = rebuild deck

**Trade-offs:**
- Less deck variety than a build-multiple-decks model (can revisit if aperture feels too small)

---

### DEC-040: Path Symbols (Visual Identity)
**Date:** 2026-07-03
**Status:** DECIDED

**Context:** Each of the 10 paths should be instantly recognizable on a card.

**Options:**
1. Mana/cost identity (MTG-style colored resource)
2. Visual identity only (a glyph/color per path, no cost mechanic)
3. Attunement gating (symbols tied to attainment)

**Decision:** Visual identity only — each path has a symbol (glyph) + color

**Rationale:**
- Keeps the cost system simple (essence remains the only resource — see existing combat docs)
- Symbol + color lets the player read their hand at a glance
- No new balancing surface introduced; purely presentational
- In the text prototype, symbols are unicode glyphs; in Godot/web they can be generated icons

**Path Symbol Assignments (prototype):**
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

**Trade-offs:**
- No mechanical depth from symbols (acceptable; essence + attainment already provide it)

---

### DEC-041: First Build Target (Text Prototype)
**Date:** 2026-07-03
**Status:** DECIDED

**Context:** "Playable soon" — need the fastest path to a fun, testable core loop before investing in Godot.

**Options:**
1. Godot vertical slice (matches long-term plan, slower to playable)
2. Text/terminal Python prototype (fastest to playable, iterate on fun)
3. Web (HTML/JS) prototype

**Decision:** Text/terminal Python prototype first, then port the proven design to Godot

**Rationale:**
- Fastest route to a playable, iterable card-combat loop
- Reuses the planned Python stack (server logic can grow out of it)
- Nails the FUN of the card system before committing to Godot UI work
- Godot (DEC-001) remains the long-term client; this prototype is throwaway/reference for feel

**Scope of prototype:**
- Character creation (clan + aptitude, minimal)
- Aperture-as-deck with a starter set of hardcoded Gu
- Card combat loop (draw, play, target, enemy AI, win/lose)
- Path symbols rendered as glyphs
- No AI generation yet (hardcoded Gu pool); AI comes after loop is fun

**Trade-offs:**
- Prototype code is not the final game; some rework porting to Godot (intentional)

---

## Pending Decisions

### DEC-038: Combat AI Behavior System
**Status:** PENDING

**Context:** How should enemy AI make decisions in combat?

**Options:**
1. Simple priority list
2. AI-generated strategy per enemy
3. Behavior trees

**Notes:** Depends on combat complexity - decide during Sprint 9.

---

## Superseded Decisions

(None yet)

---

## Decision Review Schedule

Revisit these decisions after:
- [ ] Sprint 2 complete - Review AI generation approach
- [ ] Sprint 8 complete - Review combat system
- [ ] Sprint 17 complete - Full architecture review before immortal content
