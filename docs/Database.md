# Database Design [DRAFT]

## Overview

SQLite database for storing all generated content, player saves, and meta-progression data.

**Location:** `data/game.db`

---

## Schema

### Generated Content Tables

#### gu_cards
Stores all AI-generated Gu worms.

```sql
CREATE TABLE gu_cards (
    id TEXT PRIMARY KEY,                    -- UUID
    name TEXT NOT NULL,                     -- "Moonblade Gu"
    rank INTEGER NOT NULL CHECK (rank >= 1 AND rank <= 9),
    path TEXT NOT NULL,                     -- "strength", "blood", etc.
    type TEXT NOT NULL,                     -- "offensive", "defensive", "utility", "economic"
    rarity TEXT NOT NULL,                   -- "common", "uncommon", "rare", "legendary"

    -- Costs
    essence_cost INTEGER NOT NULL,          -- Primeval essence to activate
    material_cost_json TEXT,                -- JSON: materials needed to refine/feed

    -- Effects
    effect_summary TEXT NOT NULL,           -- Short description for UI
    effect_description TEXT NOT NULL,       -- Full flavor text
    effect_mechanics_json TEXT NOT NULL,    -- JSON: structured game mechanics

    -- Metadata
    clan_affiliation TEXT,                  -- NULL = universal, else clan-specific
    is_immortal BOOLEAN DEFAULT FALSE,      -- Rank 6+ Gu
    slot_size INTEGER DEFAULT 1,            -- Aperture slots consumed

    -- Generation context
    generation_context_json TEXT,           -- What prompted this generation
    generation_prompt_hash TEXT,            -- For debugging/iteration

    -- Usage tracking
    times_appeared INTEGER DEFAULT 0,       -- How often offered to players
    times_acquired INTEGER DEFAULT 0,       -- How often players took it
    times_used_in_combat INTEGER DEFAULT 0, -- Combat usage
    win_rate_when_used REAL,               -- Win rate in combats where used
    avg_rank_acquired REAL,                -- Average player rank when acquired

    -- Flags
    is_fallback BOOLEAN DEFAULT FALSE,      -- TRUE if from fallback pool
    is_approved BOOLEAN DEFAULT TRUE,       -- For manual review flagging

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_used_at TIMESTAMP
);

CREATE INDEX idx_gu_rank ON gu_cards(rank);
CREATE INDEX idx_gu_path ON gu_cards(path);
CREATE INDEX idx_gu_type ON gu_cards(type);
CREATE INDEX idx_gu_rarity ON gu_cards(rarity);
```

#### events
Stores all AI-generated events.

```sql
CREATE TABLE events (
    id TEXT PRIMARY KEY,                    -- UUID
    title TEXT NOT NULL,                    -- "A Mysterious Merchant Appears"

    -- Context requirements
    location_type TEXT,                     -- "merchant_city", "wilderness", etc.
    min_rank INTEGER DEFAULT 1,
    max_rank INTEGER DEFAULT 9,
    required_reputation TEXT,               -- "righteous", "demonic", NULL = any
    required_path TEXT,                     -- NULL = any path

    -- Content
    description TEXT NOT NULL,              -- Event narrative
    choices_json TEXT NOT NULL,             -- JSON array of choice objects

    -- Outcomes (per choice)
    outcomes_json TEXT NOT NULL,            -- JSON: maps choice_id to outcome

    -- Tags for filtering
    tags_json TEXT,                         -- ["combat", "trade", "social", etc.]
    goal_alignment_json TEXT,               -- What player goals this serves

    -- Generation context
    generation_context_json TEXT,
    generation_prompt_hash TEXT,

    -- Usage tracking
    times_triggered INTEGER DEFAULT 0,
    times_completed INTEGER DEFAULT 0,
    choice_distribution_json TEXT,          -- How often each choice picked

    -- Flags
    is_fallback BOOLEAN DEFAULT FALSE,
    is_approved BOOLEAN DEFAULT TRUE,
    is_repeatable BOOLEAN DEFAULT TRUE,     -- Can trigger multiple times per run
    cooldown_days INTEGER DEFAULT 0,        -- Minimum days between triggers

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_triggered_at TIMESTAMP
);

CREATE INDEX idx_events_location ON events(location_type);
CREATE INDEX idx_events_rank ON events(min_rank, max_rank);
```

#### npcs
Stores generated NPCs.

```sql
CREATE TABLE npcs (
    id TEXT PRIMARY KEY,                    -- UUID
    name TEXT NOT NULL,                     -- "Elder Wang"

    -- Basic info
    rank INTEGER NOT NULL,
    path TEXT,                              -- Primary cultivation path
    clan_affiliation TEXT,
    occupation TEXT,                        -- "merchant", "elder", "wanderer"

    -- Personality
    personality_summary TEXT,               -- Brief description
    personality_traits_json TEXT,           -- ["greedy", "cautious", "honorable"]
    speech_style TEXT,                      -- How they talk

    -- Relationships
    default_disposition TEXT,               -- Starting attitude to player
    faction_affiliations_json TEXT,

    -- Capabilities
    gu_loadout_json TEXT,                   -- Their Gu for combat
    services_json TEXT,                     -- What they can offer (trade, info, etc.)

    -- Generation context
    generation_context_json TEXT,

    -- Usage tracking
    times_encountered INTEGER DEFAULT 0,
    relationship_outcomes_json TEXT,        -- Track how relationships evolved

    -- Flags
    is_fallback BOOLEAN DEFAULT FALSE,
    is_unique BOOLEAN DEFAULT FALSE,        -- One-per-game NPCs
    is_alive BOOLEAN DEFAULT TRUE,          -- Can die in events/combat

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_encountered_at TIMESTAMP
);

CREATE INDEX idx_npcs_rank ON npcs(rank);
CREATE INDEX idx_npcs_clan ON npcs(clan_affiliation);
```

#### killer_moves
Generated killer move combinations.

```sql
CREATE TABLE killer_moves (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,                     -- "Moonlight Slash"

    -- Requirements
    required_gu_json TEXT NOT NULL,         -- JSON array of Gu IDs/types needed
    min_attainment_level TEXT NOT NULL,     -- "master", "grandmaster"
    path TEXT NOT NULL,

    -- Effects
    effect_description TEXT NOT NULL,
    effect_mechanics_json TEXT NOT NULL,
    essence_cost INTEGER NOT NULL,
    cooldown_turns INTEGER DEFAULT 0,

    -- Generation
    generation_context_json TEXT,

    -- Tracking
    times_learned INTEGER DEFAULT 0,
    times_used INTEGER DEFAULT 0,
    effectiveness_rating REAL,

    is_fallback BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

### Player Data Tables

#### saves
Current run save data.

```sql
CREATE TABLE saves (
    id TEXT PRIMARY KEY,                    -- Save slot ID
    save_name TEXT,                         -- Player-given name

    -- Character
    character_name TEXT NOT NULL,
    clan TEXT NOT NULL,
    aptitude TEXT NOT NULL,                 -- "A", "B", "C", "D"

    -- Progression
    current_rank INTEGER NOT NULL,
    cultivation_progress REAL,              -- 0.0 to 1.0 toward next rank
    current_age INTEGER NOT NULL,
    max_lifespan INTEGER NOT NULL,

    -- Location
    current_location TEXT NOT NULL,

    -- Resources
    primeval_stones INTEGER DEFAULT 0,
    primeval_essence INTEGER DEFAULT 0,     -- Current essence pool
    max_essence INTEGER DEFAULT 100,

    -- State
    player_state_json TEXT NOT NULL,        -- Full player object
    world_state_json TEXT NOT NULL,         -- World/time state
    aperture_json TEXT NOT NULL,            -- Current Gu loadout
    connections_json TEXT,                  -- NPC relationships

    -- Content references
    encountered_gu_ids TEXT,                -- Comma-separated Gu IDs seen this run
    encountered_event_ids TEXT,
    encountered_npc_ids TEXT,

    -- Meta
    playtime_seconds INTEGER DEFAULT 0,
    in_game_days INTEGER DEFAULT 0,

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Run state
    is_active BOOLEAN DEFAULT TRUE,         -- FALSE if run ended
    end_reason TEXT,                        -- "death", "old_age", "victory"
    end_rank INTEGER
);
```

#### inheritance
Meta-progression unlocks persisting between runs.

```sql
CREATE TABLE inheritance (
    id TEXT PRIMARY KEY,

    -- Unlock type
    unlock_type TEXT NOT NULL,              -- "gu_formula", "killer_move", "clan", "location", etc.
    unlock_id TEXT NOT NULL,                -- Reference to what was unlocked

    -- Source
    source_run_id TEXT,                     -- Save ID that created this
    source_character TEXT,
    source_rank_achieved INTEGER,

    -- Unlock data
    unlock_data_json TEXT,                  -- Type-specific data

    -- Requirements to access
    min_rank_to_access INTEGER DEFAULT 1,
    is_immortal_only BOOLEAN DEFAULT FALSE,

    -- Timestamps
    unlocked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_inheritance_type ON inheritance(unlock_type);
```

#### meta_stats
Overall player statistics across all runs.

```sql
CREATE TABLE meta_stats (
    id TEXT PRIMARY KEY DEFAULT 'global',   -- Single row table

    -- Run stats
    total_runs INTEGER DEFAULT 0,
    total_victories INTEGER DEFAULT 0,
    highest_rank_achieved INTEGER DEFAULT 1,

    -- Aggregates
    total_playtime_seconds INTEGER DEFAULT 0,
    total_gu_acquired INTEGER DEFAULT 0,
    total_enemies_defeated INTEGER DEFAULT 0,
    total_events_completed INTEGER DEFAULT 0,

    -- Per-clan stats (JSON)
    clan_stats_json TEXT,                   -- {"gu_yue": {"runs": 5, "wins": 1}, ...}

    -- Per-path stats
    path_stats_json TEXT,                   -- Most used paths, effectiveness

    -- Timestamps
    first_played_at TIMESTAMP,
    last_played_at TIMESTAMP
);
```

---

### Balance Tracking Tables

#### balance_snapshots
Periodic snapshots for analysis.

```sql
CREATE TABLE balance_snapshots (
    id TEXT PRIMARY KEY,
    snapshot_date DATE NOT NULL,

    -- Aggregated data
    gu_usage_json TEXT,                     -- Which Gu are over/underused
    path_performance_json TEXT,             -- Win rates by path
    clan_performance_json TEXT,             -- Win rates by clan
    death_distribution_json TEXT,           -- Where/when players die
    event_completion_json TEXT,             -- Event success rates

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## JSON Schemas

### effect_mechanics_json (Gu)

```json
{
  "activation": "instant | sustained | passive",
  "target": "self | single_enemy | all_enemies | area",
  "effects": [
    {
      "type": "damage | heal | buff | debuff | utility",
      "value": 25,
      "scaling": "rank * 5",
      "duration": 3,
      "element": "fire"
    }
  ],
  "synergies": ["fire_path", "explosion_gu"],
  "counters": ["water_path", "ice_gu"]
}
```

### choices_json (Events)

```json
[
  {
    "id": "choice_1",
    "text": "Accept the merchant's offer",
    "requirements": {
      "min_primeval_stones": 50,
      "reputation": null
    },
    "visible_if": null
  },
  {
    "id": "choice_2",
    "text": "Attempt to rob the merchant",
    "requirements": null,
    "visible_if": "reputation == 'demonic'"
  }
]
```

### outcomes_json (Events)

```json
{
  "choice_1": {
    "description": "The merchant hands over the Gu...",
    "effects": [
      {"type": "remove_resource", "resource": "primeval_stones", "amount": 50},
      {"type": "add_gu", "gu_pool": "movement_rank2", "count": 1}
    ],
    "reputation_change": 0,
    "followup_event": null
  },
  "choice_2": {
    "success_chance": 0.4,
    "success": {
      "description": "You successfully intimidate the merchant...",
      "effects": [
        {"type": "add_gu", "gu_pool": "movement_rank2", "count": 1},
        {"type": "add_resource", "resource": "primeval_stones", "amount": 30}
      ],
      "reputation_change": -10
    },
    "failure": {
      "description": "The merchant's guards overwhelm you...",
      "effects": [
        {"type": "trigger_combat", "enemy_type": "guards", "count": 3}
      ],
      "reputation_change": -5
    }
  }
}
```

---

## Migration Strategy

For schema changes during development:

1. Version the schema in code
2. On startup, check schema version
3. Run migrations if needed
4. Keep migrations in `server/migrations/`

```python
# Example migration
MIGRATIONS = {
    1: "ALTER TABLE gu_cards ADD COLUMN slot_size INTEGER DEFAULT 1",
    2: "CREATE INDEX idx_gu_clan ON gu_cards(clan_affiliation)",
}
```

---

## Backup Strategy

- SQLite file copied on each game save
- Keep last 5 backups: `game.db.bak.1` through `game.db.bak.5`
- Meta-progression (inheritance) also exported to JSON for safety

---

## Queries Reference

### Find suitable Gu for player
```sql
SELECT * FROM gu_cards
WHERE rank <= ?
  AND (clan_affiliation IS NULL OR clan_affiliation = ?)
  AND is_approved = TRUE
ORDER BY RANDOM()
LIMIT 3;
```

### Find matching events
```sql
SELECT * FROM events
WHERE (location_type IS NULL OR location_type = ?)
  AND min_rank <= ?
  AND max_rank >= ?
  AND (required_reputation IS NULL OR required_reputation = ?)
  AND is_approved = TRUE
  AND (cooldown_days = 0 OR last_triggered_at IS NULL
       OR julianday('now') - julianday(last_triggered_at) >= cooldown_days)
ORDER BY RANDOM()
LIMIT 1;
```

### Balance check: underused Gu
```sql
SELECT name, path, times_appeared, times_acquired,
       CAST(times_acquired AS REAL) / NULLIF(times_appeared, 0) as acquisition_rate
FROM gu_cards
WHERE times_appeared > 10
ORDER BY acquisition_rate ASC
LIMIT 20;
```

---

## Open Questions

- [ ] How long to retain unused generated content?
- [ ] Should we deduplicate similar Gu (name/effect matching)?
- [ ] Version generated content for balance patches?
- [ ] Export format for sharing seeds/content between players?
