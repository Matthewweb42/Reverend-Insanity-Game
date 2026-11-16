# MVP feature checklist

Every feature listed in GameDesign.md and the docs/ folder, with its status in the Godot build on
the `claude-build` branch. **In** means playable in the build; **Partial** means present in a
simpler form (the note says what is missing); **Out** means not in this build.

## Core structure

| Feature | Status | Notes |
|---|---|---|
| Win condition: Rank 9 Venerable | In | Three-stage Venerable tribulation; victory ends the life with a big legacy bonus |
| Mortal stage, Rank 1-5 (Initial/Middle/Upper/Peak) | In | |
| Rank 5 to 6 tribulation (heaven, earth, human) | In | Heaven is a battle, earth an offering of stones, human depends on allies; full, partial or failed ascension |
| Immortal stage, Rank 6-8 | In | Blessed land, factions, periodic tribulations, rank-up battles |
| Permadeath with inheritance | In | Points from every life, 16 legacies, pick up to 3 per life |
| Unlockable clans, starts, modes and regions | In | Unlocked by achievements and flags; Sandbox unlocks all |

## Time

| Feature | Status | Notes |
|---|---|---|
| Real-time with pause, adjustable speed | In | Pause, 1x/2x/4x; Space and 1/2/3 |
| Closed-door cultivation (time skip) | In | |
| Travel takes in-game time; movement Gu shorten it | In | |
| Aging and lifespan, death from old age | In | Lifespan Gu and immortality extend it |
| Events during any activity | In | |
| Stellaris-style notifications that keep time running | Partial | Events pause the game (DEC-045). Toasts for minor news never pause; arrival, full aperture and mission pauses are optional in Settings |

## Character creation

| Feature | Status | Notes |
|---|---|---|
| Region selection | In | Southern Border; Northern Plains and Central Continent unlock |
| Six clans with signature paths, Gu pools, killer moves, rivals | In | Gu Yue, Bai, Xiong, Shang, Wu, Chi |
| Aptitude roll A-D with design odds and effects | In | Two rerolls; catch-up nudges after repeated deaths |
| Starting position (age, wealth, connections) | In | Standard, Young, Prodigy, Reincarnator starts |
| Game modes | In | Normal, Hard, Speed Run, Path Challenge, Ironman |

## Mortal gameplay

| Feature | Status | Notes |
|---|---|---|
| Cultivation with intensity and deviation risk | In | Five intensities from free meditation to reckless |
| Breakthroughs: R2 check, R3 trial, R4 multi-stage, R5 specialization | In | Heart-demon battles; specialization shapes the ascension |
| Failure consequences | In | Lost progress, injuries, wasted stones |
| Goal-directed events | In | 10 goal types steer event selection and rewards |
| Clan missions by standing | In | Standing ranks, monthly stipend |
| Hunting, materials, merchants | In | |
| Exploration, hidden blessed lands, caches | In | Hu Immortal and Three Kings lands unlock through events and legacies |
| Study (path attainment) | In | Tutors, study activity, use in combat |
| Refinement and experimentation | In | 119 formulas; experiments can discover new ones; refine owned Gu further |
| Socialization: NPC relationships, intel, reputation | In | Talk, gift, ask info, ask help, mentor, spar, duel, threaten; righteous/demonic alignment |
| Relationship bands (allied to mortal enemy) | In | Seven bands |
| Locations with danger, resources, NPCs, events, travel time | In | 16 locations, 26 routes |
| Aperture slots that grow with rank; storage | In | |
| Gu upkeep (feeding) and starvation | In | |
| Path attainment tiers Novice to Grandmaster | In | Bonuses and per-turn play limits per tier |

## Combat

| Feature | Status | Notes |
|---|---|---|
| Turn-based card combat, Gu as cards | In | Essence costs, per-path play limits, hand and draw pile |
| Enemy intents and counter-play | In | 24 enemy types, 4 tiers, intents shown a turn ahead |
| Statuses, environments, forms, summons | In | 14 statuses, 14 environments, 5 transformation forms |
| Killer moves (Master+, combine Gu) | In | 14 killer moves |
| Practice lowers killer move cost | In | -3% essence per use, down to -30% |
| Killer moves inheritable | In | Legacy |
| Prior intelligence about enemies | In | Bought or learned intel reveals enemies before a fight |
| Fleeing | In | Chance shown; not allowed in trials and tribulations |
| Arena fights, beast hunts, clan conflicts | In | |

## Economy

| Feature | Status | Notes |
|---|---|---|
| Primeval stones | In | |
| Materials by rarity | In | 24 materials |
| Information as a tradeable resource | In | Buy market tips and intel |
| Favors from relationships | Partial | Allies help once ("ask for help"); no separate favor currency |
| Clan market, caravans, black market | In | Black market darkens reputation |
| Haggling | In | |
| Treasure Yellow Heaven (immortal auction) | In | Immortal essence stones |

## Immortal stage

| Feature | Status | Notes |
|---|---|---|
| Blessed land: size, dao marks, resource points, time flow, tribulation counter | In | |
| Plant materials, build structures, nurture, invite guests | In | Guests are NPCs, single-player only |
| Raise immortal beasts | In | Beast Pen; each beast softens tribulations |
| Immortal essence stones, dao marks, immortal Gu | In | |
| Periodic earthly and heavenly tribulations | In | |
| Factions | In | Righteous Alliance, Demonic Sect, Lone Immortal |
| Ancient inheritances (Rank 7+) | In | |
| Annexing grotto-heavens | In | |
| Immortal vendettas | Partial | Clan rivals and hostile NPCs persist; no dedicated immortal vendetta system |
| Influence zones, controlling mortal clans as resource bases | Out | |
| Rank 6-7 and 7-8 requirements (Gu, dao, grandmaster paths, rare materials) | In | |
| Venerable requirements and three-stage tribulation | In | |

## Meta-progression

| Feature | Status | Notes |
|---|---|---|
| Inheritance points from death or victory | In | DEC-043 formula |
| Mortal, immortal and venerable legacies | In | Formulas, caches, insights, contacts, locations, reputation, killer moves |
| Unlock clans, regions, starts, modes | In | |
| Achievements and records | In | 15 achievements, lifetime stats, past lives |

## AI systems

| Feature | Status | Notes |
|---|---|---|
| Procedural Gu, events, NPCs and quests offline | In | Default; no key needed |
| Goal-weighted event generation | In | |
| Live Claude writing with the player's own key | In | NPC lines, event openings, new Gu names; never changes rules |
| Dynamic balancing from play metrics | Partial | Local to one install (DEC-046); no shared database |
| Python FastAPI AI server and SQLite | Out (by design) | Replaced by in-game HTTPS and JSON saves (DEC-044) |

## Presentation and platform

| Feature | Status | Notes |
|---|---|---|
| Windows double-click build | In | Single exe, built by CI and by tools/build.sh or build.ps1 |
| Graphics | In | game-icons.net icons, shader backdrops, drawn map and cards; no AI images |
| Music and sound | In | Synthesized in-house |
| Save slots and autosave | In | Three slots plus monthly autosave; Ironman keeps one |
| Settings | In | Volumes, fullscreen, autopause, tutorial, sandbox, API key |
| Tutorial | In | Seven-page guide, optional on each new life |
| Controller support, localisation, Steam features | Out | |
