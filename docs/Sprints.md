# Sprint Plans [DRAFT]

## Overview

This document outlines the development sprints from planning through MVP and beyond. Each sprint has clear deliverables and acceptance criteria.

**Sprint Duration:** Flexible (feature-based, not time-boxed)

---

## Pre-Development Phase

### Sprint 0: Planning & Documentation
**Status:** IN PROGRESS

**Goals:**
- Complete all design documentation
- Nail down every system before writing code
- Have clear answers to all open questions

**Deliverables:**
- [ ] Complete GameDesign.md review and refinement
- [ ] Architecture.md - finalize tech decisions
- [ ] Database.md - complete schema design
- [ ] AIGeneration.md - prompt templates drafted
- [ ] All Systems/*.md docs completed
- [ ] All Content/*.md docs completed
- [ ] Decisions.md populated with all choices made
- [ ] This sprint plan reviewed and approved

**Exit Criteria:**
- Every system has a dedicated document
- No "TBD" or "???" left in critical sections
- Could hand docs to another developer and they could build it

---

## Phase 1: Foundation

### Sprint 1: Project Scaffolding
**Status:** NOT STARTED

**Goals:**
- Set up all project infrastructure
- Verify Godot ↔ Python communication works
- Database operational

**Tasks:**
- [ ] Initialize Godot 4 project with folder structure
- [ ] Initialize Python FastAPI server with folder structure
- [ ] Set up SQLite database with initial schema
- [ ] Create .gitignore, .env.example, README.md
- [ ] Implement basic HTTP communication (Godot → Python)
- [ ] Create health check endpoint
- [ ] Test round-trip: Godot requests → Python responds → Godot receives

**Deliverables:**
- Working Godot project that can call Python server
- Python server that responds to requests
- SQLite database that can store/retrieve data
- Git repo properly configured

**Acceptance Criteria:**
- Can run both Godot and Python server locally
- Godot can make HTTP request and display response
- Can write to and read from database

---

### Sprint 2: Basic AI Generation Pipeline
**Status:** NOT STARTED

**Goals:**
- Claude API integration working
- Can generate a single Gu card
- Can store and retrieve generated content

**Tasks:**
- [ ] Set up Anthropic SDK in Python server
- [ ] Implement basic Gu generation prompt
- [ ] Create /generate/gu endpoint
- [ ] Implement response validation
- [ ] Store generated Gu in database
- [ ] Implement basic fallback (return hardcoded Gu on failure)
- [ ] Create Godot UI to display a Gu card
- [ ] Wire up: button press → generate Gu → display card

**Deliverables:**
- Working Gu generation with Claude
- Gu card display in Godot
- Database storing generated content

**Acceptance Criteria:**
- Click button in Godot, see AI-generated Gu card
- Generated Gu passes validation
- Gu persists in database after generation
- Fallback works when API unavailable

---

### Sprint 3: Core Game State
**Status:** NOT STARTED

**Goals:**
- Player character data structure
- Basic game state management
- Save/load functionality

**Tasks:**
- [ ] Define Player data model (GDScript class)
- [ ] Implement GameState autoload singleton
- [ ] Create character creation flow (clan, aptitude)
- [ ] Implement Aperture system (Gu slots)
- [ ] Basic resource tracking (primeval stones, essence)
- [ ] Save game to database
- [ ] Load game from database
- [ ] Basic HUD showing player stats

**Deliverables:**
- Player can be created with clan/aptitude
- Player state persists between sessions
- HUD displays current stats

**Acceptance Criteria:**
- Create character, close game, reopen, character is there
- Can add/remove Gu from aperture
- Resources display correctly on HUD

---

## Phase 2: Core Loop

### Sprint 4: Time System
**Status:** NOT STARTED

**Goals:**
- Real-time with pause working
- Time speed controls
- Aging mechanic functional

**Tasks:**
- [ ] Implement TimeManager autoload
- [ ] Pause/unpause functionality
- [ ] Speed controls (1x, 2x, 5x, 10x)
- [ ] Day/night cycle (visual or just counter)
- [ ] Age progression tied to time
- [ ] Lifespan tracking
- [ ] Death from old age trigger
- [ ] UI for time controls and display

**Deliverables:**
- Time flows when unpaused
- Player ages over time
- Can control game speed
- Game ends when lifespan exceeded

**Acceptance Criteria:**
- Pause stops all time progression
- Speed changes are noticeable
- Age increments correctly with time
- Old age death triggers game over

---

### Sprint 5: Basic Cultivation
**Status:** NOT STARTED

**Goals:**
- Active cultivation mechanic
- Resource consumption
- Rank progression

**Tasks:**
- [ ] Implement Cultivation system
- [ ] Active cultivation state (player chooses to cultivate)
- [ ] Essence regeneration when cultivating
- [ ] Primeval stone consumption
- [ ] Cultivation progress bar
- [ ] Rank up logic (Rank 1 → 2 → 3 → 4 → 5)
- [ ] Rank up effects (more aperture slots, higher essence cap)
- [ ] Closed door cultivation (time acceleration)

**Deliverables:**
- Player can actively cultivate
- Resources drain during cultivation
- Can progress through ranks

**Acceptance Criteria:**
- Cultivation only happens when activated
- Resources deplete appropriately
- Rank ups feel meaningful
- Closed door cultivation speeds up time

---

### Sprint 6: Event System Foundation
**Status:** NOT STARTED

**Goals:**
- Events can trigger and display
- Player can make choices
- Outcomes apply to game state

**Tasks:**
- [ ] Implement EventManager autoload
- [ ] Event popup UI
- [ ] Choice selection UI
- [ ] Event outcome processing
- [ ] Connect events to game state changes
- [ ] Create 5-10 hardcoded test events
- [ ] Event queue (multiple pending events)
- [ ] Event timing (trigger based on conditions)

**Deliverables:**
- Events appear as popups
- Choices lead to different outcomes
- Outcomes modify player state

**Acceptance Criteria:**
- Events trigger at appropriate times
- Choices are clearly presented
- Outcomes feel impactful
- Multiple events can queue up

---

### Sprint 7: AI Event Generation
**Status:** NOT STARTED

**Goals:**
- Events generated by AI based on context
- Goal-directed generation working
- Events stored and reusable

**Tasks:**
- [ ] Implement /generate/event endpoint
- [ ] Event generation prompt template
- [ ] Context gathering (player state, location, goals)
- [ ] Goal input UI (player states what they're seeking)
- [ ] Event validation
- [ ] Event caching strategy
- [ ] Fallback events
- [ ] Wire AI events into EventManager

**Deliverables:**
- Events generated based on player context
- Player goals influence event generation
- Events cached for reuse

**Acceptance Criteria:**
- Set goal "seeking fire gu" → events relate to fire gu
- Generated events pass validation
- Cached events can be retrieved
- Fallback works on API failure

---

## Phase 3: Combat & Challenge

### Sprint 8: Turn-Based Combat Foundation
**Status:** NOT STARTED

**Goals:**
- Basic turn-based combat functional
- Gu cards playable in combat
- Win/lose conditions

**Tasks:**
- [ ] Combat scene setup
- [ ] Turn order system
- [ ] Player hand (Gu from aperture)
- [ ] Play Gu card mechanic
- [ ] Basic enemy with health/actions
- [ ] Damage calculation
- [ ] Combat resolution (win/lose)
- [ ] Return to main game after combat
- [ ] Combat rewards

**Deliverables:**
- Functional turn-based combat
- Can play Gu cards
- Can defeat enemies or lose

**Acceptance Criteria:**
- Combat is turn-based and understandable
- Gu abilities work as described
- Winning grants rewards
- Losing has consequences

---

### Sprint 9: Enemy Generation
**Status:** NOT STARTED

**Goals:**
- AI generates enemy loadouts
- Enemies have coherent builds
- Difficulty scaling works

**Tasks:**
- [ ] Implement /generate/combat-loadout endpoint
- [ ] Enemy loadout prompt template
- [ ] Enemy AI behavior in combat
- [ ] Difficulty parameters
- [ ] Enemy variety by path
- [ ] Boss enemy generation
- [ ] Integrate with event system (events trigger combat)

**Deliverables:**
- Enemies generated with full Gu loadouts
- Enemy AI makes reasonable decisions
- Difficulty scales with player rank

**Acceptance Criteria:**
- Generated enemies have synergistic builds
- Combat feels appropriately challenging
- Higher rank = harder enemies

---

### Sprint 10: Advanced Combat
**Status:** NOT STARTED

**Goals:**
- Killer moves functional
- Combat depth increased
- Preparation matters

**Tasks:**
- [ ] Killer move system
- [ ] Combo mechanics (Gu synergies)
- [ ] Status effects (buffs, debuffs, DoTs)
- [ ] Counter-play mechanics
- [ ] Pre-combat preparation phase
- [ ] Intelligence gathering (learn enemy weaknesses)
- [ ] Path attainment combat bonuses

**Deliverables:**
- Killer moves add strategic depth
- Preparation influences combat
- Combat has meaningful decisions

**Acceptance Criteria:**
- Killer moves feel powerful and earned
- Knowing enemy build helps win
- Path attainment bonuses are noticeable

---

## Phase 4: World & Progression

### Sprint 11: Location System
**Status:** NOT STARTED

**Goals:**
- Multiple locations exist
- Travel between locations
- Locations have distinct content

**Tasks:**
- [ ] Location data structure
- [ ] Map UI
- [ ] Travel mechanic (takes time)
- [ ] Location-specific event pools
- [ ] 5+ distinct locations for Southern Border
- [ ] Movement Gu affect travel time
- [ ] Location discovery

**Deliverables:**
- Player can travel between locations
- Each location feels different
- Travel has time cost

**Acceptance Criteria:**
- Map shows available locations
- Travel time varies by distance
- Movement Gu reduce travel time
- Locations have unique events

---

### Sprint 12: NPC System
**Status:** NOT STARTED

**Goals:**
- NPCs generated and persistent
- Relationship system functional
- NPCs provide services

**Tasks:**
- [ ] NPC data structure
- [ ] /generate/npc endpoint
- [ ] Relationship tracking (allied to enemy)
- [ ] Reputation system (righteous/demonic)
- [ ] NPC services (trade, info, quests)
- [ ] NPC dialogue generation
- [ ] Recurring NPCs across events

**Deliverables:**
- NPCs feel like characters
- Relationships evolve over time
- NPCs offer meaningful interactions

**Acceptance Criteria:**
- NPCs remember past interactions
- Reputation affects NPC reactions
- Can build allies and make enemies

---

### Sprint 13: Economy & Resources
**Status:** NOT STARTED

**Goals:**
- Full resource economy working
- Trading functional
- Resource gathering activities

**Tasks:**
- [ ] Resource types defined and tracked
- [ ] Clan missions for resources
- [ ] Trading with NPCs
- [ ] Market price variation
- [ ] Gu feeding/maintenance costs
- [ ] Resource scarcity pressure
- [ ] Inventory management UI

**Deliverables:**
- Resources feel meaningful
- Multiple ways to acquire resources
- Must manage economy carefully

**Acceptance Criteria:**
- Running out of resources is dangerous
- Trading feels fair but strategic
- Can sustain long-term with good management

---

### Sprint 14: Path Attainment System
**Status:** NOT STARTED

**Goals:**
- Path attainment tracking
- Study mechanic
- Attainment benefits in gameplay

**Tasks:**
- [ ] Path attainment data structure
- [ ] Study activity (increase attainment)
- [ ] Attainment bonuses to Gu effectiveness
- [ ] Killer move unlock at Master+
- [ ] Attainment UI
- [ ] Multi-path attainment tracking
- [ ] Experimentation discovery mechanic

**Deliverables:**
- Can specialize in paths
- Higher attainment = stronger in that path
- Killer moves unlocked through mastery

**Acceptance Criteria:**
- Study increases attainment
- Bonuses feel noticeable
- Master attainment unlocks killer moves

---

## Phase 5: Full Mortal Experience

### Sprint 15: Rank Advancement Challenges
**Status:** NOT STARTED

**Goals:**
- Rank up is a challenge, not automatic
- Different challenges per rank
- Failure has consequences

**Tasks:**
- [ ] Rank 2 breakthrough (minor challenge)
- [ ] Rank 3 breakthrough (combat or puzzle)
- [ ] Rank 4 breakthrough (multi-stage)
- [ ] Rank 5 breakthrough (major, specialization choice)
- [ ] Breakthrough failure consequences
- [ ] Preparation benefits breakthrough

**Deliverables:**
- Each rank up is an event
- Challenges feel distinct
- Risk/reward for breakthrough attempts

**Acceptance Criteria:**
- Can fail breakthroughs
- Preparation helps success rate
- Each breakthrough feels like an achievement

---

### Sprint 16: Clan System
**Status:** NOT STARTED

**Goals:**
- Multiple clans playable
- Clans have unique content
- Clan politics affect gameplay

**Tasks:**
- [ ] 4 clans with distinct Gu pools
- [ ] Clan-specific starting bonuses
- [ ] Clan standing mechanic
- [ ] Clan missions and rewards
- [ ] Inter-clan politics
- [ ] Clan selection at character creation

**Deliverables:**
- Each clan plays differently
- Clan choice matters strategically
- Clan dynamics create events

**Acceptance Criteria:**
- Clans have 5-10 unique Gu each
- Clan standing affects opportunities
- Replayability from clan variety

---

### Sprint 17: Polish & Balance
**Status:** NOT STARTED

**Goals:**
- Complete mortal experience playable
- Balance pass on all systems
- Bug fixes and polish

**Tasks:**
- [ ] Full playthrough testing
- [ ] Balance adjustments based on data
- [ ] UI polish
- [ ] Tutorial/onboarding
- [ ] Settings menu
- [ ] Performance optimization
- [ ] Bug fixing

**Deliverables:**
- Mortal stage feels complete
- Game is balanced and fair
- New players can learn the game

**Acceptance Criteria:**
- Can play full Rank 1-5 run
- Win rate is challenging but fair
- No major bugs or crashes

---

## Phase 6: Meta & Beyond (Future)

### Sprint 18: Inheritance System
- Death creates inheritance
- Inheritance points
- Unlocks for future runs
- Meta-progression feels rewarding

### Sprint 19: Tribulation & Rank 6
- Earthly Calamity challenge
- Immortal ascension
- Blessed land basics

### Sprint 20: Immortal Content
- Blessed land management
- Immortal Gu
- Tribulation system
- Immortal politics

### Sprint 21+: Venerable & Endgame
- Rank 7-8 content
- Venerable ascension
- True ending
- New Game+

---

## Sprint Template

```markdown
### Sprint N: [Name]
**Status:** NOT STARTED | IN PROGRESS | COMPLETE

**Goals:**
- Goal 1
- Goal 2

**Tasks:**
- [ ] Task 1
- [ ] Task 2

**Deliverables:**
- Deliverable 1
- Deliverable 2

**Acceptance Criteria:**
- Criteria 1
- Criteria 2

**Notes:**
- Any learnings or blockers
```

---

## Progress Tracking

| Sprint | Status | Start Date | End Date | Notes |
|--------|--------|------------|----------|-------|
| 0 - Planning | IN PROGRESS | - | - | |
| 1 - Scaffolding | NOT STARTED | | | |
| 2 - AI Pipeline | NOT STARTED | | | |
| 3 - Game State | NOT STARTED | | | |
| ... | | | | |

---

## Definition of Done

For any sprint to be considered complete:
- [ ] All tasks checked off
- [ ] All acceptance criteria met
- [ ] Code committed and pushed
- [ ] Relevant docs updated
- [ ] No known critical bugs
- [ ] Tested end-to-end
