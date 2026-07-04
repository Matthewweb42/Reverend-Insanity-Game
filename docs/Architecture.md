# Technical Architecture [DRAFT]

## Overview

The game uses a client-server architecture where Godot handles all game logic and rendering, while a Python server manages AI generation and content caching.

```
┌─────────────────────────────────────────────────────────────────┐
│                         PLAYER'S MACHINE                        │
│                                                                 │
│  ┌─────────────────┐         ┌─────────────────────────────┐   │
│  │   Godot Game    │◀──HTTP──▶   Python AI Server          │   │
│  │   (GDScript)    │  :8000  │   (FastAPI)                 │   │
│  │                 │         │                             │   │
│  │  - Game Logic   │         │  - Prompt Management        │   │
│  │  - UI/Rendering │         │  - Response Parsing         │   │
│  │  - Combat       │         │  - Caching Logic            │   │
│  │  - Save/Load    │         │  - Fallback Handling        │   │
│  └─────────────────┘         └──────────┬──────────────────┘   │
│                                         │                       │
│                              ┌──────────▼──────────┐            │
│                              │   SQLite Database   │            │
│                              │   (game.db)         │            │
│                              │                     │            │
│                              │  - Generated Gu     │            │
│                              │  - Generated Events │            │
│                              │  - Generated NPCs   │            │
│                              │  - Player Saves     │            │
│                              │  - Meta Progression │            │
│                              └─────────────────────┘            │
└─────────────────────────────────────────────────────────────────┘
                                         │
                                         │ HTTPS (API calls)
                                         ▼
                              ┌─────────────────────┐
                              │    Claude API       │
                              │    (Anthropic)      │
                              └─────────────────────┘
```

---

## Tech Stack

| Component | Technology | Version | Rationale |
|-----------|------------|---------|-----------|
| Game Engine | Godot | 4.x | Learning it, good 2D/UI, GDScript is accessible |
| Game Language | GDScript | - | Native to Godot, easy to iterate |
| AI Server | Python + FastAPI | 3.11+ | Best for prompt engineering, async support |
| Database | SQLite | 3 | Simple, file-based, no setup needed |
| LLM | Claude API | claude-3+ | Good structured output, reasoning ability |
| Version Control | Git | - | Feature branches workflow |

---

## Component Details

### Godot Game Client

**Responsibilities:**
- All game logic (cultivation, combat, time management)
- UI rendering and player input
- Local state management during gameplay
- Save/load coordination
- HTTP communication with AI server

**Does NOT handle:**
- AI prompt construction
- LLM API calls
- Content caching decisions

**Autoload Singletons (Global Scripts):**
```
GameState       - Current run state, player data
TimeManager     - Real-time with pause, speed control
AIClient        - HTTP interface to Python server
EventManager    - Event queue and processing
AudioManager    - Sound and music (future)
```

**Scene Structure:**
```
Main
├── UI
│   ├── HUD (always visible)
│   ├── PauseMenu (toggle)
│   ├── EventPopup (queue-based)
│   ├── InventoryScreen
│   └── MapScreen
├── World
│   └── CurrentLocation
└── Combat (instanced when needed)
```

### Python AI Server

**Responsibilities:**
- Construct prompts based on game context
- Call Claude API
- Parse and validate responses
- Cache generated content in SQLite
- Serve fallback content on API failure
- Track generation statistics

**API Endpoints:**
```
POST /generate/gu
POST /generate/event
POST /generate/npc
POST /generate/combat-loadout
GET  /cache/gu?filters=...
GET  /cache/events?filters=...
GET  /health
GET  /stats
```

**Request/Response Flow:**
```
1. Godot sends context (player rank, location, goals, etc.)
2. Server checks cache for suitable existing content
3. If cache miss, construct prompt and call Claude
4. Parse response into structured data
5. Validate against game rules
6. Store in SQLite
7. Return to Godot
```

### SQLite Database

**Purpose:**
- Persist all generated content
- Store player saves
- Track meta-progression (inheritance)
- Record usage statistics for balance analysis

**See [Database.md](./Database.md) for full schema**

---

## Data Flow Examples

### Example: Player Enters New Location

```
1. Player travels to "Merchant City"
2. Godot → Server: POST /generate/event
   {
     "location": "merchant_city",
     "player_rank": 3,
     "player_goals": ["seeking movement gu", "need primeval stones"],
     "reputation": "neutral",
     "current_connections": ["merchant_wang"]
   }
3. Server checks cache for matching events
4. Cache miss → Constructs prompt → Calls Claude
5. Claude returns event JSON
6. Server validates, stores in SQLite
7. Server → Godot: Event data
8. Godot displays event popup
```

### Example: Combat Encounter

```
1. Event triggers combat with "Rank 3 Blood Path Gu Master"
2. Godot → Server: POST /generate/combat-loadout
   {
     "enemy_type": "gu_master",
     "enemy_rank": 3,
     "enemy_path": "blood",
     "location": "wild_beast_plains",
     "context": "ambush while traveling"
   }
3. Server generates enemy's Gu loadout (5-8 Gu cards)
4. Each Gu either pulled from cache or generated fresh
5. Server → Godot: Complete enemy data
6. Godot enters turn-based combat mode
```

---

## Communication Protocol

### HTTP REST API

All communication uses JSON over HTTP REST.

**Base URL:** `http://localhost:8000`

**Standard Response Format:**
```json
{
  "success": true,
  "data": { ... },
  "cached": false,
  "generation_time_ms": 1234,
  "error": null
}
```

**Error Response:**
```json
{
  "success": false,
  "data": null,
  "cached": false,
  "generation_time_ms": 0,
  "error": {
    "code": "API_TIMEOUT",
    "message": "Claude API request timed out",
    "fallback_used": true
  }
}
```

### Why Not WebSocket?

REST is sufficient because:
- Requests are discrete (generate X, return X)
- No need for server-pushed updates
- Simpler to implement and debug
- Can add WebSocket later if needed for real-time features

---

## Error Handling Strategy

### API Failures

| Failure Type | Response |
|--------------|----------|
| API timeout | Return random fallback content |
| API error (500) | Retry once, then fallback |
| Rate limited | Queue request, return fallback |
| Invalid response | Log error, return fallback |
| Network error | Return fallback, notify player |

### Fallback Content

Pre-authored JSON files for each content type:
- `fallback/gu_rank1.json` through `fallback/gu_rank5.json`
- `fallback/events_generic.json`
- `fallback/npcs_generic.json`

Fallback content is tagged so it doesn't get stored as "generated."

---

## File Structure

```
reverend-insanity-game/
├── godot/                      # Godot 4 project
│   ├── project.godot
│   ├── scenes/
│   │   ├── main.tscn
│   │   ├── ui/
│   │   │   ├── hud.tscn
│   │   │   ├── gu_card_display.tscn
│   │   │   ├── event_popup.tscn
│   │   │   ├── pause_menu.tscn
│   │   │   ├── inventory.tscn
│   │   │   └── map.tscn
│   │   └── combat/
│   │       ├── combat_arena.tscn
│   │       └── combat_card.tscn
│   ├── scripts/
│   │   ├── autoload/
│   │   │   ├── game_state.gd
│   │   │   ├── time_manager.gd
│   │   │   ├── ai_client.gd
│   │   │   ├── event_manager.gd
│   │   │   └── audio_manager.gd
│   │   ├── player/
│   │   │   ├── player.gd
│   │   │   ├── aperture.gd
│   │   │   └── cultivation.gd
│   │   ├── gu/
│   │   │   ├── gu_card.gd
│   │   │   └── gu_database.gd
│   │   ├── combat/
│   │   │   ├── combat_manager.gd
│   │   │   └── combat_ai.gd
│   │   ├── events/
│   │   │   └── event_handler.gd
│   │   └── world/
│   │       ├── location.gd
│   │       └── travel.gd
│   ├── resources/
│   │   ├── themes/
│   │   └── fonts/
│   └── assets/
│       ├── ui/
│       └── audio/
│
├── server/                     # Python FastAPI server
│   ├── main.py                 # FastAPI app entry point
│   ├── config.py               # Configuration and env vars
│   ├── database.py             # SQLite operations
│   ├── models.py               # Pydantic models for validation
│   ├── generators/
│   │   ├── __init__.py
│   │   ├── base.py             # Base generator class
│   │   ├── gu_generator.py
│   │   ├── event_generator.py
│   │   ├── npc_generator.py
│   │   └── combat_generator.py
│   ├── prompts/
│   │   ├── __init__.py
│   │   ├── gu_prompts.py
│   │   ├── event_prompts.py
│   │   └── npc_prompts.py
│   ├── cache/
│   │   ├── __init__.py
│   │   └── cache_manager.py
│   ├── fallback/
│   │   ├── __init__.py
│   │   └── fallback_manager.py
│   ├── routes/
│   │   ├── __init__.py
│   │   ├── generate.py
│   │   ├── cache.py
│   │   └── health.py
│   ├── tests/
│   │   └── ...
│   └── requirements.txt
│
├── data/
│   ├── game.db                 # SQLite database (gitignored)
│   ├── fallback/               # Fallback JSON content
│   │   ├── gu_rank1.json
│   │   ├── gu_rank2.json
│   │   ├── gu_rank3.json
│   │   ├── gu_rank4.json
│   │   ├── gu_rank5.json
│   │   ├── events_generic.json
│   │   └── npcs_generic.json
│   └── seeds/                  # Initial seed data
│       └── ...
│
├── docs/                       # Documentation
│   └── ...
│
├── GameDesign.md
├── README.md
├── .gitignore
└── .env.example                # Environment variables template
```

---

## Development Workflow

### Running Locally

1. Start Python server: `cd server && uvicorn main:app --reload`
2. Open Godot project: `godot/project.godot`
3. Run game from Godot editor
4. Server runs on `localhost:8000`, Godot connects automatically

### Environment Variables

```env
# .env
ANTHROPIC_API_KEY=sk-ant-...
DATABASE_PATH=../data/game.db
FALLBACK_PATH=../data/fallback/
LOG_LEVEL=DEBUG
CACHE_ENABLED=true
```

---

## Security Considerations

- API key stored in `.env`, never committed
- Server only runs locally (no auth needed for MVP)
- SQLite file in `.gitignore`
- No sensitive data in generated content

---

## Future Considerations

### Multiplayer (Eventually)
- Would need to move server to cloud
- Add authentication
- Sync game state between players
- Shared blessed land instances

### Modding (Eventually)
- Expose Gu/event JSON schemas
- Allow custom fallback content
- Custom prompt templates?

---

## Open Questions

- [ ] Exact Godot version to target?
- [ ] Should generated content be shareable between players?
- [ ] How to handle AI generation during combat without breaking flow?
- [ ] Pre-generate content pools on game start vs. pure on-demand?
