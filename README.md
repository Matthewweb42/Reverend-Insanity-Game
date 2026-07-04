# Reverend Insanity Roguelike

A real-time with pause roguelike where you cultivate from Rank 1 mortal to Rank 9 Venerable. Based on the Reverend Insanity (Gu Zhen Ren) novel.

## Project Status

**Phase:** Playable text prototype

A terminal card-combat prototype is playable now (see [prototype/](prototype/)). This is a
throwaway/reference build to nail the fun of the card system before porting to Godot (DEC-041).
Design docs are otherwise complete (Sprint 0).

### Play the prototype

```
py prototype/game.py            # interactive
py prototype/game.py --demo     # scripted auto-play (no input)
py prototype/game.py --seed 7   # reproducible RNG
```

The game is a **card RPG**: your Gu worms are cards, and your aperture is your deck (DEC-039).
Each cultivation path has its own symbol (DEC-040).

## Quick Links

- [Game Design Document](GameDesign.md) - Core gameplay and mechanics
- [Documentation Index](docs/README.md) - All planning docs

## Tech Stack

| Component | Technology |
|-----------|------------|
| Game Engine | Godot 4 (GDScript) |
| AI Server | Python + FastAPI |
| Database | SQLite |
| AI Generation | Claude API |

## Key Features

- **Real-time with pause** gameplay (Stellaris-style)
- **AI-generated content** - Gu, events, NPCs, quests
- **10 cultivation paths** with distinct mechanics
- **Permadeath with inheritance** - meta-progression between runs
- **Goal-directed event system** - set objectives, world responds

## Project Structure

```
reverend-insanity-game/
├── prototype/               # Playable text card-RPG prototype (Python)
│   ├── game.py              # Entry point + character creation + game loop
│   ├── combat.py            # Aperture-as-deck combat + effect resolver
│   ├── cards.py             # Gu cards + starter pool
│   ├── enemies.py           # Hardcoded enemy loadouts
│   ├── paths.py             # 10 paths + symbols/colors
│   └── ui.py                # Terminal rendering
├── docs/                    # Planning documentation
│   ├── Architecture.md      # Technical architecture
│   ├── Database.md          # Database schema
│   ├── AIGeneration.md      # AI generation system
│   ├── Sprints.md           # Development sprints
│   ├── Decisions.md         # Decision log
│   ├── Systems/             # Detailed system docs
│   │   ├── Combat.md
│   │   ├── Cultivation.md
│   │   ├── Time.md
│   │   ├── Events.md
│   │   ├── Economy.md
│   │   └── Inheritance.md
│   ├── Content/             # Content design docs
│   │   ├── Paths.md
│   │   ├── Gu.md
│   │   ├── Clans.md
│   │   ├── Locations.md
│   │   └── NPCs.md
│   └── Glossary.md          # Terms and definitions
├── godot/                   # Godot project (not yet created)
├── server/                  # Python AI server (not yet created)
├── data/                    # Database and fallback content
├── GameDesign.md            # Master design document
└── README.md                # This file
```

## Getting Started

### Prerequisites

- Godot 4.x
- Python 3.11+
- Anthropic API key

### Setup (Coming Soon)

Implementation has not started yet. See [Sprints.md](docs/Sprints.md) for development roadmap.

## Documentation

All planning documentation is in the `docs/` folder:

### Core Documents
- **[GameDesign.md](GameDesign.md)** - High-level game design
- **[Architecture.md](docs/Architecture.md)** - System architecture
- **[Sprints.md](docs/Sprints.md)** - Development plan

### System Design
- **[Combat](docs/Systems/Combat.md)** - Turn-based tactical combat
- **[Cultivation](docs/Systems/Cultivation.md)** - Rank progression
- **[Time](docs/Systems/Time.md)** - Real-time mechanics
- **[Events](docs/Systems/Events.md)** - AI event generation
- **[Economy](docs/Systems/Economy.md)** - Resources and trading
- **[Inheritance](docs/Systems/Inheritance.md)** - Meta-progression

### Content Design
- **[Paths](docs/Content/Paths.md)** - The 10 cultivation paths
- **[Gu](docs/Content/Gu.md)** - Gu worm design
- **[Clans](docs/Content/Clans.md)** - Starting factions
- **[Locations](docs/Content/Locations.md)** - World map
- **[NPCs](docs/Content/NPCs.md)** - Character generation

## Contributing

This is currently a solo project in early planning stages.

## License

TBD

## Acknowledgments

- Inspired by the novel "Reverend Insanity" (Gu Zhen Ren) by Gu Zhen Ren
- Gameplay inspiration from Stellaris, Slay the Spire, Caves of Qud
