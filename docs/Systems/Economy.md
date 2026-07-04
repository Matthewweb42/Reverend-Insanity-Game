# Economy System [DRAFT]

## Overview

The economy creates resource pressure that drives gameplay decisions. Players must balance immediate needs (cultivation, combat) against long-term investments (rare Gu, connections, path attainment).

---

## Resource Types

### Primary Currency

#### Primeval Stones
The universal mortal currency.

| Aspect | Value |
|--------|-------|
| Main use | Cultivation, trading, fees |
| Acquisition | Missions, events, trade, combat loot |
| Drain rate | 5-30 per day during cultivation |
| Typical reserves | 50-500 at any time |

**Value Scale:**
```
1 stone = A meal, minor consumable
10 stones = Basic Gu feeding (1 week)
50 stones = Common Gu purchase
100 stones = Uncommon Gu, significant service
500 stones = Rare Gu, major investment
1000+ stones = Legendary items, major bribes
```

### Secondary Resources

#### Primeval Essence
Internal energy for Gu activation.

| Aspect | Value |
|--------|-------|
| Main use | Combat, Gu abilities |
| Acquisition | Rest, regeneration Gu |
| Capacity | Scales with rank (100-700 mortal) |
| Regeneration | 10-50% per hour outside combat |

#### Materials
Crafting components for Gu refinement.

**Material Tiers:**
- Common (beast parts, herbs)
- Uncommon (refined materials)
- Rare (specific creature parts)
- Legendary (unique items)

**Material Categories:**
- Path-specific (fire materials, blood materials)
- Generic (universal catalysts)
- Rank-specific (rank 3 materials)

#### Information
Knowledge as currency.

**Types:**
- Gu formulas (recipes)
- Location intel
- NPC secrets
- Enemy weaknesses
- Hidden opportunities

#### Favors
Social currency from relationships.

**Uses:**
- Cash in for help
- Get discounts
- Access restricted areas
- Receive information

---

## Income Sources

### Clan Missions

Regular income tied to clan standing.

| Standing | Mission Availability | Reward Range |
|----------|---------------------|--------------|
| Probationary | Basic only | 5-20 stones |
| Member | Standard pool | 10-50 stones |
| Core | Advanced missions | 30-100 stones |
| Elder | Special missions | 50-200 stones |

**Mission Types:**
- Patrol (combat encounters)
- Delivery (travel time)
- Gathering (exploration)
- Investigation (social)
- Defense (combat challenge)

### Event Rewards

Events provide variable income:
- Combat victories: 10-100 stones + loot
- Discoveries: Materials, Gu, information
- Trade opportunities: Profit margins
- Quest completions: Set rewards

### Combat Loot

Defeating enemies yields:
- Primeval stones (based on enemy rank)
- Gu drops (chance based on enemy)
- Materials
- Equipment/items

**Loot Formula:**
```
Base Loot = Enemy Rank × 10 stones
Variance = ±50%
Gu Drop Chance = 10% + (Rank Difference × 5%)
```

### Trading

Buy low, sell high.
- Different locations have different prices
- Supply and demand fluctuation
- Special events affect markets
- Rare items have collectors

### Passive Income (Limited)

Some Gu generate resources:
- Stone-producing Gu (very rare)
- Interest from clan deposits
- Blessed land income (immortal only)

---

## Expenses

### Cultivation Costs

The primary resource drain.

| Intensity | Daily Cost | Progress Modifier |
|-----------|------------|-------------------|
| None | 0 | 0.5x |
| Minimal | 1 stone | 1.0x |
| Standard | 5 stones | 2.0x |
| Intensive | 15 stones | 3.5x |
| Maximum | 30 stones | 5.0x |

### Gu Maintenance

Gu require feeding to remain active.

| Gu Rank | Weekly Cost | Notes |
|---------|-------------|-------|
| Rank 1 | 2 stones | Or specific materials |
| Rank 2 | 5 stones | |
| Rank 3 | 12 stones | |
| Rank 4 | 30 stones | |
| Rank 5 | 75 stones | |

**Starving Gu:**
- After 2 weeks unfed: -50% effectiveness
- After 4 weeks: Gu may die
- Some Gu have special food requirements

### Services & Fees

| Service | Cost Range |
|---------|------------|
| Healing | 10-100 stones |
| Information | 5-500 stones |
| Training/tutoring | 20-200 stones |
| Clan protection | 10% of income |
| Market stall fee | 5 stones |
| Travel toll | 2-20 stones |
| Bribe (minor) | 10-50 stones |
| Bribe (major) | 100+ stones |

### Refinement Costs

Creating or upgrading Gu:

| Result Rank | Base Material Cost | Stone Cost |
|-------------|-------------------|------------|
| Rank 1 | Common × 3 | 20 stones |
| Rank 2 | Common × 5, Uncommon × 1 | 50 stones |
| Rank 3 | Uncommon × 3, Rare × 1 | 150 stones |
| Rank 4 | Rare × 3 | 400 stones |
| Rank 5 | Rare × 5, Legendary × 1 | 1000 stones |

---

## Market System

### Trading Venues

#### Clan Markets
- Limited selection
- Stable prices
- Clan-specific Gu available
- Standing affects access

#### Merchant Caravans
- Random inventory
- Negotiable prices
- Rare items possible
- Time-limited presence

#### Black Markets
- Demonic path Gu
- Stolen goods
- Risky but valuable
- Reputation consequences

#### Treasure Yellow Heaven (Immortal)
- Auction format
- Immortal resources only
- Inter-region trading

### Price Factors

Base prices modified by:
- Location (cities cheaper, wilderness expensive)
- Supply (recent events affect availability)
- Demand (common goals increase prices)
- Reputation (discounts/markups)
- Negotiation (haggle success)

**Price Variance:**
```
Final Price = Base Price × Location Mod × Supply Mod × Rep Mod × Negotiation
Typical range: 70% - 150% of base price
```

### Negotiation

Some transactions allow haggling:
- Success chance based on: Charisma Gu, reputation, NPC disposition
- Success: 10-30% discount
- Critical success: 40-50% discount
- Failure: No discount
- Critical failure: Price increase or refused service

---

## Economic Pressure Design

### Early Game (Rank 1-2)
```
Income: ~20-40 stones/week
Expenses: ~15-25 stones/week (minimal cultivation)
Buffer: Tight, must complete missions
Key tension: Cultivation vs Gu feeding vs saving
```

### Mid Game (Rank 3-4)
```
Income: ~50-100 stones/week
Expenses: ~40-80 stones/week
Buffer: Moderate, can save for purchases
Key tension: Upgrade Gu vs intensive cultivation
```

### Late Mortal (Rank 5)
```
Income: ~100-200 stones/week
Expenses: ~80-150 stones/week
Buffer: Building reserves for immortal ascension
Key tension: Tribulation preparation vs current power
```

### Scarcity Sources

1. **Cultivation drain** - Constant resource consumption
2. **Gu feeding** - More Gu = more upkeep
3. **Opportunity costs** - Better options require more
4. **Time pressure** - Can't grind forever
5. **RNG variance** - Income isn't guaranteed

### Relief Valves

1. **Scalable cultivation** - Can reduce intensity
2. **Mission availability** - Always some income option
3. **Sellable items** - Can liquidate assets
4. **Favor economy** - Non-monetary options

---

## Inventory Management

### Storage Limits

| Storage Type | Capacity | Notes |
|--------------|----------|-------|
| Carried | 100 weight units | Affected by strength |
| Clan storage | 500 units | Safe, accessible in clan |
| Personal cache | 200 units | Hidden, risk of loss |
| Storage Gu | Varies | Special Gu extend capacity |

### Item Weight

| Item Type | Weight |
|-----------|--------|
| Primeval stone | 0.01 |
| Common material | 1 |
| Uncommon material | 2 |
| Rare material | 3 |
| Gu worm | 0 (in aperture) |
| Equipment | 5-20 |

---

## Economic Events

### Market Events

- **Supply shortage** - Specific materials cost +50%
- **Merchant festival** - All prices -20%
- **Bandit activity** - Caravans rare, prices up
- **Discovery** - New Gu type floods market

### Personal Events

- **Windfall** - Find treasure, bonus income
- **Robbery** - Lose percentage of carried wealth
- **Investment opportunity** - Risk stones for return
- **Debt collection** - NPC calls in favor

---

## UI Elements

### Resource Display

```
┌─────────────────────────────────────────┐
│  RESOURCES                              │
├─────────────────────────────────────────┤
│  💎 Primeval Stones: 156               │
│  ⚡ Essence: 280/350                    │
│                                         │
│  📦 Materials:                          │
│     Common: 12                          │
│     Uncommon: 3                         │
│     Rare: 1                             │
│                                         │
│  📊 Weekly Flow:                        │
│     Income: ~45 stones                  │
│     Expenses: ~35 stones                │
│     Net: +10 stones/week                │
└─────────────────────────────────────────┘
```

### Market Interface

```
┌─────────────────────────────────────────────────────────────┐
│  MERCHANT WANG'S SHOP                                       │
├─────────────────────────────────────────────────────────────┤
│  FOR SALE:                                                  │
│                                                             │
│  [Fire Burst Gu]        Rank 2, Offensive    45 stones     │
│  [Basic Shield Gu]      Rank 1, Defensive    20 stones     │
│  [Common Fire Material] Material             8 stones      │
│                                                             │
│  YOUR ITEMS:                                                │
│                                                             │
│  [Old Strength Gu]      Rank 1, Utility      Sell: 12      │
│  [Common Material ×5]   Material             Sell: 3 each  │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│  Your stones: 156                        [Exit Shop]        │
└─────────────────────────────────────────────────────────────┘
```

---

## Balance Metrics

Track during development:
- Average stones at each rank
- Time spent resource-negative
- Most purchased items
- Price to actual acquisition rate
- Mission completion vs income

---

## Open Questions

- [ ] Should there be a loan/debt system?
- [ ] How to prevent hoarding/grinding exploits?
- [ ] Insurance/protection for carried wealth?
- [ ] Inflation over game time?
- [ ] Shared economy in multiplayer?
