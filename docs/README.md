# Documentation Index

This folder contains all planning and design documentation for the Reverend Insanity Roguelike project.

## Document Structure

### Core Design
- [GameDesign.md](../GameDesign.md) - Master game design document (gameplay, mechanics, progression)

### Technical Architecture
- [Architecture.md](./Architecture.md) - System architecture, tech stack, data flow
- [Database.md](./Database.md) - Database schema, data models, storage strategy
- [AIGeneration.md](./AIGeneration.md) - AI generation system, prompts, caching strategy

### Implementation Planning
- [Sprints.md](./Sprints.md) - Sprint plans, milestones, task breakdowns
- [Decisions.md](./Decisions.md) - Decision log for technical and design choices

### Game Systems (Detailed)
- [Systems/Cards.md](./Systems/Cards.md) - Card / deck system (aperture = deck, path symbols)
- [Systems/Combat.md](./Systems/Combat.md) - Turn-based combat mechanics
- [Systems/Cultivation.md](./Systems/Cultivation.md) - Cultivation and progression
- [Systems/Time.md](./Systems/Time.md) - Real-time with pause, aging, time pressure
- [Systems/Events.md](./Systems/Events.md) - Event system, goal-directed generation
- [Systems/Economy.md](./Systems/Economy.md) - Resources, trading, costs
- [Systems/Inheritance.md](./Systems/Inheritance.md) - Meta-progression, unlocks

### Content Design
- [Content/Paths.md](./Content/Paths.md) - The 10 cultivation paths in detail
- [Content/Gu.md](./Content/Gu.md) - Gu card design, examples, generation rules
- [Content/Clans.md](./Content/Clans.md) - Clan designs, bonuses, unique Gu
- [Content/Locations.md](./Content/Locations.md) - World map, location details
- [Content/NPCs.md](./Content/NPCs.md) - NPC archetypes, relationship system

### Reference
- [Glossary.md](./Glossary.md) - Terms and definitions from the source material
- [SourceMaterial.md](./SourceMaterial.md) - Notes on Reverend Insanity novel for reference

---

## How to Use This Documentation

1. **Start with GameDesign.md** for the high-level vision
2. **Check Architecture.md** for technical decisions
3. **Review Sprints.md** before starting any implementation work
4. **Update Decisions.md** when making significant choices
5. **Refer to Systems/** docs for detailed mechanics when implementing

## Status Legend

Throughout these docs:
- `[DRAFT]` - Initial ideas, needs review
- `[REVIEW]` - Ready for feedback/iteration
- `[FINAL]` - Locked in, ready to implement
- `[IMPLEMENTED]` - Done and in code
