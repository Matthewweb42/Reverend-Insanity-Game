# AI Generation System [DRAFT]

## Overview

The AI generation system is the heart of this project - using Claude to dynamically create game content based on player context. This document covers prompt engineering, generation strategies, validation, and caching.

---

## Generation Philosophy

### Core Principles

1. **Context-Aware**: Generation considers player rank, location, goals, reputation, and history
2. **Bounded Creativity**: AI is creative within game-rule constraints
3. **Cacheable**: Generated content can be reused when context matches
4. **Fallback-Safe**: Always have hand-crafted alternatives if AI fails
5. **Balance-Trackable**: All generated content gets usage metrics

### What Gets Generated

| Content Type | Generation Trigger | Caching Strategy |
|--------------|-------------------|------------------|
| Gu Cards | On demand when needed | Cache by rank+path+type |
| Events | Entering locations, time passing | Cache by location+rank range |
| NPCs | Event needs, location population | Cache, reuse named NPCs |
| Enemy Loadouts | Combat encounters | Generate fresh, cache Gu used |
| Killer Moves | Player experiments/discovers | Cache permanently |
| Dialogue | NPC interactions | Generate fresh, short-term cache |

---

## Prompt Architecture

### Prompt Components

Every generation prompt follows this structure:

```
[SYSTEM CONTEXT]
- Game rules and constraints
- Current balance guidelines
- Output format requirements

[GENERATION CONTEXT]
- Player state (rank, path, goals)
- Location/situation
- What's being requested

[EXAMPLES]
- 2-3 examples of good output
- Shows expected format and quality

[CONSTRAINTS]
- Specific numeric bounds
- Required fields
- Forbidden elements

[OUTPUT INSTRUCTION]
- Exact JSON schema
- Validation rules
```

### Prompt Templates

Stored in `server/prompts/` as Python files with string templates.

---

## Gu Generation

### Request Context

```json
{
  "rank": 3,
  "path": "fire",
  "type": "offensive",
  "rarity": "uncommon",
  "player_context": {
    "current_rank": 3,
    "clan": "gu_yue",
    "current_goals": ["seeking fire path gu"],
    "known_gu": ["basic_flame_gu", "heat_shield_gu"]
  },
  "situation": "reward from defeating fire beast"
}
```

### Prompt Template

```python
GU_GENERATION_PROMPT = """
You are generating Gu worms for a cultivation roguelike game based on Reverend Insanity.

## Game Context
- Gu are magical insects that grant abilities
- Each Gu has a rank (1-9), path (cultivation school), and type
- Higher rank = more powerful but costs more essence
- Paths have distinct themes and mechanics

## Balance Guidelines for Rank {rank}
- Essence cost: {min_cost}-{max_cost}
- Damage (if offensive): {min_damage}-{max_damage}
- Effect duration: {min_duration}-{max_duration} turns

## The {path} Path
{path_description}
Common themes: {path_themes}
Mechanical tendencies: {path_mechanics}

## Current Request
Generate a {rarity} {type} Gu of Rank {rank} in the {path} path.
Situation: {situation}

## Requirements
1. Name should be evocative and match the path theme
2. Effect should be mechanically interesting, not just "deal X damage"
3. Include a weakness or limitation
4. Flavor text should hint at lore/origin
5. Must be distinct from: {known_gu}

## Output Format
Return ONLY valid JSON matching this schema:
```json
{{
  "name": "string - evocative name ending in Gu",
  "rank": {rank},
  "path": "{path}",
  "type": "{type}",
  "rarity": "{rarity}",
  "essence_cost": "integer within balance range",
  "effect_summary": "string - one line for UI display",
  "effect_description": "string - full flavor text, 2-3 sentences",
  "effect_mechanics": {{
    "activation": "instant|sustained|passive",
    "target": "self|single_enemy|all_enemies|area",
    "effects": [
      {{
        "type": "damage|heal|buff|debuff|utility",
        "value": "integer",
        "duration": "integer or null",
        "special": "string or null"
      }}
    ],
    "weakness": "string - situational drawback",
    "synergies": ["array of path names or gu types that combo well"],
    "counters": ["array of what counters this"]
  }},
  "slot_size": 1
}}
```

## Examples of Good Rank 3 Fire Path Offensive Gu:

{examples}

Now generate the Gu:
"""
```

### Balance Parameters by Rank

```python
GU_BALANCE = {
    1: {"essence_cost": (5, 15), "damage": (10, 20), "duration": (1, 2)},
    2: {"essence_cost": (10, 25), "damage": (15, 35), "duration": (1, 3)},
    3: {"essence_cost": (20, 40), "damage": (30, 60), "duration": (2, 4)},
    4: {"essence_cost": (35, 60), "damage": (50, 90), "duration": (2, 5)},
    5: {"essence_cost": (50, 80), "damage": (80, 130), "duration": (3, 6)},
    # Immortal ranks have different scaling
    6: {"essence_cost": (100, 200), "damage": (200, 400), "duration": (3, 8)},
    7: {"essence_cost": (200, 500), "damage": (500, 1000), "duration": (4, 10)},
    8: {"essence_cost": (500, 1000), "damage": (1000, 2500), "duration": (5, 12)},
}
```

### Path Descriptions

```python
PATH_INFO = {
    "strength": {
        "description": "Direct physical power and bodily enhancement",
        "themes": ["muscles", "force", "impact", "endurance", "physical might"],
        "mechanics": ["high single-target damage", "self-buffs", "resistance"],
    },
    "fire": {
        "description": "Flames, heat, and explosive destruction",
        "themes": ["flames", "burning", "heat", "explosions", "ash"],
        "mechanics": ["DoT effects", "area damage", "destruction", "can backfire"],
    },
    "blood": {
        "description": "Life force manipulation, sacrifice, and vitality",
        "themes": ["blood", "life force", "sacrifice", "vampiric", "wounds"],
        "mechanics": ["life steal", "self-damage for power", "healing", "debuffs"],
    },
    # ... etc for all 10 paths
}
```

---

## Event Generation

### Request Context

```json
{
  "location": "merchant_city",
  "player": {
    "rank": 3,
    "reputation": "neutral",
    "goals": ["seeking movement gu", "need primeval stones"],
    "connections": ["merchant_wang"],
    "recent_events": ["completed_trade_quest"]
  },
  "time": {
    "days_in_location": 5,
    "days_since_last_event": 2,
    "urgency": "low"
  }
}
```

### Prompt Template

```python
EVENT_GENERATION_PROMPT = """
You are generating events for a cultivation roguelike game.

## Event Design Principles
1. Events present meaningful choices with trade-offs
2. Outcomes should feel consequential but fair
3. Player goals should influence opportunities
4. Events can be positive, negative, or mixed
5. Some choices should have hidden risks

## Current Situation
Location: {location} - {location_description}
Player Rank: {rank}
Reputation: {reputation}
Active Goals: {goals}
Known NPCs here: {connections}

## Player is seeking: {goals}
Generate an event that RELATES to at least one of these goals.
The event should feel like a natural consequence of actively pursuing these goals.

## Event Types
- Opportunity: Chance to gain something (with cost or risk)
- Encounter: Meet someone interesting
- Discovery: Find something hidden
- Challenge: Obstacle to overcome
- Dilemma: Moral or strategic choice

## Output Format
Return ONLY valid JSON:
```json
{{
  "title": "string - short, evocative title",
  "type": "opportunity|encounter|discovery|challenge|dilemma",
  "description": "string - 2-4 sentences setting the scene",
  "choices": [
    {{
      "id": "choice_1",
      "text": "string - what player chooses to do",
      "requirements": {{
        "min_primeval_stones": null,
        "min_rank": null,
        "required_gu": null,
        "reputation_requirement": null
      }},
      "hint": "string or null - subtle hint about consequences"
    }}
  ],
  "outcomes": {{
    "choice_1": {{
      "success_chance": 1.0,
      "success": {{
        "description": "string - what happens",
        "effects": [
          {{"type": "effect_type", "params": {{}}}}
        ],
        "reputation_change": 0,
        "goal_progress": "which goal this advances"
      }},
      "failure": null
    }}
  }},
  "tags": ["array", "of", "tags"],
  "goal_alignment": ["which player goals this serves"]
}}
```

## Effect Types
- add_gu: {{gu_rank, gu_path, gu_type}}
- remove_gu: {{gu_id}}
- add_resource: {{resource, amount}}
- remove_resource: {{resource, amount}}
- change_reputation: {{amount}}
- add_connection: {{npc_type, disposition}}
- trigger_combat: {{enemy_type, enemy_rank, count}}
- gain_information: {{info_type, content}}
- travel_to: {{location}}
- time_skip: {{days}}
- cultivation_boost: {{amount}}
- take_damage: {{amount}}

Generate an event now:
"""
```

---

## NPC Generation

### Request Context

```json
{
  "role": "merchant",
  "rank_range": [2, 4],
  "location": "merchant_city",
  "purpose": "can sell movement gu",
  "player_reputation": "neutral"
}
```

### Prompt (abbreviated)

```python
NPC_GENERATION_PROMPT = """
Generate an NPC for a cultivation world.

Role: {role}
Rank: {rank_range}
Location: {location}
Purpose in story: {purpose}

NPCs should have:
1. A distinctive personality trait
2. A motivation/goal of their own
3. Something they can offer the player
4. Something they want from the player
5. A secret or hidden depth (optional)

Output JSON with: name, rank, path, personality, speech_style, services, desires, secret
"""
```

---

## Enemy Loadout Generation

For combat encounters, generate enemy Gu loadouts:

```python
COMBAT_LOADOUT_PROMPT = """
Generate a Gu loadout for an enemy cultivator.

Enemy: Rank {rank} {path} Path Gu Master
Context: {encounter_context}
Difficulty: {difficulty}  # easy/medium/hard/boss

Generate {gu_count} Gu that:
1. Fit the enemy's path
2. Have synergy with each other
3. Present an interesting tactical challenge
4. Match the difficulty level

For each Gu, either:
- Reference an existing Gu ID if suitable: {available_gu_ids}
- Generate a new Gu inline

Output format:
{{
  "enemy_name": "string",
  "strategy_hint": "how they fight",
  "gu_loadout": [
    {{"existing_id": "gu_id"}} OR {{"generated": {{full gu object}}}}
  ],
  "killer_moves": [optional array if rank 4+],
  "weakness": "tactical hint for player"
}}
"""
```

---

## Response Validation

All AI responses go through validation:

```python
class GuValidator:
    def validate(self, gu_data: dict) -> tuple[bool, list[str]]:
        errors = []

        # Required fields
        required = ["name", "rank", "path", "type", "essence_cost", "effect_mechanics"]
        for field in required:
            if field not in gu_data:
                errors.append(f"Missing required field: {field}")

        # Rank bounds
        if not 1 <= gu_data.get("rank", 0) <= 9:
            errors.append("Rank must be 1-9")

        # Balance check
        balance = GU_BALANCE.get(gu_data["rank"], {})
        cost_range = balance.get("essence_cost", (0, 9999))
        if not cost_range[0] <= gu_data.get("essence_cost", 0) <= cost_range[1]:
            errors.append(f"Essence cost out of range for rank {gu_data['rank']}")

        # Path validation
        if gu_data.get("path") not in VALID_PATHS:
            errors.append(f"Invalid path: {gu_data.get('path')}")

        # Effect structure
        mechanics = gu_data.get("effect_mechanics", {})
        if "effects" not in mechanics or not mechanics["effects"]:
            errors.append("Must have at least one effect")

        return len(errors) == 0, errors
```

### Retry Strategy

```python
async def generate_with_retry(prompt: str, validator: Validator, max_retries: int = 3):
    for attempt in range(max_retries):
        response = await call_claude(prompt)

        try:
            data = json.loads(response)
            valid, errors = validator.validate(data)

            if valid:
                return data

            # Add errors to prompt for retry
            prompt += f"\n\nPrevious attempt had errors: {errors}\nPlease fix and try again."

        except json.JSONDecodeError:
            prompt += "\n\nPrevious response was not valid JSON. Return ONLY JSON."

    # All retries failed, use fallback
    return None
```

---

## Caching Strategy

### Cache Keys

```python
def gu_cache_key(rank: int, path: str, type: str, rarity: str) -> str:
    return f"gu:{rank}:{path}:{type}:{rarity}"

def event_cache_key(location: str, rank_range: str, goals_hash: str) -> str:
    return f"event:{location}:{rank_range}:{goals_hash}"
```

### Cache Lookup Flow

```python
async def get_or_generate_gu(request: GuRequest) -> Gu:
    # 1. Check cache for exact match
    cached = await db.find_gu(
        rank=request.rank,
        path=request.path,
        type=request.type,
        rarity=request.rarity,
        exclude_ids=request.player_known_gu  # Don't repeat what player has
    )

    if cached and len(cached) >= 3:
        # Have enough variety, pick randomly
        return random.choice(cached)

    # 2. Generate new
    generated = await generate_gu(request)

    if generated:
        await db.store_gu(generated)
        return generated

    # 3. Fallback
    return await fallback.get_gu(request.rank, request.path)
```

### Cache Warming

On game start, optionally pre-generate content:

```python
async def warm_cache(player_rank: int, player_path: str):
    """Pre-generate likely needed content in background."""

    tasks = []

    # Generate Gu at player's rank and one above
    for rank in [player_rank, player_rank + 1]:
        for path in [player_path, "universal"]:
            for type in ["offensive", "defensive", "utility"]:
                tasks.append(ensure_cached_gu(rank, path, type, count=3))

    # Generate events for nearby locations
    for location in get_nearby_locations():
        tasks.append(ensure_cached_events(location, player_rank, count=5))

    await asyncio.gather(*tasks)
```

---

## Cost Management

### Tracking API Usage

```python
class UsageTracker:
    def __init__(self):
        self.session_tokens = 0
        self.session_cost = 0.0

    def record(self, input_tokens: int, output_tokens: int):
        self.session_tokens += input_tokens + output_tokens
        # Claude pricing (adjust as needed)
        self.session_cost += (input_tokens * 0.003 + output_tokens * 0.015) / 1000

    def get_stats(self) -> dict:
        return {
            "tokens_used": self.session_tokens,
            "estimated_cost": f"${self.session_cost:.4f}"
        }
```

### Cost Reduction Strategies

1. **Aggressive caching**: Reuse content when context is similar enough
2. **Batch generation**: Generate 3-5 Gu at once instead of one at a time
3. **Shorter prompts**: Trim examples after initial testing
4. **Haiku for simple tasks**: Use Claude Haiku for dialogue, Sonnet for complex generation
5. **Local fallback**: Use Ollama/local model for non-critical generation during dev

---

## Prompt Iteration Workflow

1. **Draft prompt** in `prompts/` file
2. **Test standalone** with test script
3. **Review outputs** for quality and variety
4. **Adjust constraints** if outputs are unbalanced
5. **Add examples** of good/bad outputs
6. **Version the prompt** when stable

```python
# prompts/gu_prompts.py

GU_PROMPT_V1 = """..."""  # Original
GU_PROMPT_V2 = """..."""  # Added more balance constraints
GU_PROMPT_V3 = """..."""  # Better examples

CURRENT_GU_PROMPT = GU_PROMPT_V3
```

---

## Testing Generation

### Test Script

```python
# server/test_generation.py

async def test_gu_generation():
    """Generate sample Gu and print for review."""

    test_cases = [
        {"rank": 1, "path": "fire", "type": "offensive", "rarity": "common"},
        {"rank": 3, "path": "blood", "type": "utility", "rarity": "rare"},
        {"rank": 5, "path": "wisdom", "type": "defensive", "rarity": "legendary"},
    ]

    for case in test_cases:
        print(f"\n=== Generating: {case} ===")
        result = await generate_gu(case)
        print(json.dumps(result, indent=2))
        print(f"Valid: {validate_gu(result)}")
```

### Quality Checklist

For generated Gu:
- [ ] Name fits the path theme
- [ ] Effect is mechanically interesting
- [ ] Numbers are within balance range
- [ ] Has a meaningful weakness
- [ ] Distinct from similar Gu in cache

For generated events:
- [ ] Choices are meaningfully different
- [ ] Outcomes feel proportional to risk
- [ ] Relates to player goals
- [ ] Fits the location
- [ ] No broken/impossible requirements

---

## Open Questions

- [ ] How to handle generation during combat without lag?
- [ ] Should players be able to "seed" generation with preferences?
- [ ] How much should generated content reference existing generated content?
- [ ] Version control for prompts - how to track what generated what?
- [ ] A/B testing different prompt versions?
