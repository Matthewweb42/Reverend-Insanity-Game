# Team handoff

Current numbers and text for design, writing, and audio. Generated from the live data files. If a number here and the game disagree, the game is wrong and this file is stale: regenerate with `node game/test/handoff.js`.

Combat resource is essence pips (3, then 4 at Rank 4, 5 at Rank 7), not the hundred-point pools in the design notes. Damage, block, poison, and costs below are what the resolver uses.

## Cards

### Primeval Bolt Gu
- id `primeval_bolt` · Rank 1 · Mortal · Offensive · Common · cost 1
- Deal 6 damage.
- Refined: Deal 9 damage.

### Steady Breath Gu
- id `steady_breath` · Rank 1 · Mortal · Defensive · Common · cost 1
- Gain 5 Block.
- Refined: Gain 8 Block.

### Mend Gu
- id `mend` · Rank 1 · Mortal · Defensive · Common · cost 1
- Heal 5. Exhaust.
- Refined: Heal 8. Exhaust.
- Exhausts.

### Desperate Lunge Gu
- id `desperate_lunge` · Rank 1 · Mortal · Offensive · Common · cost 0
- Lose 2 HP. Deal 8 damage.
- Refined: Lose 2 HP. Deal 11 damage.

### Swift Steps Gu
- id `swift_steps` · Rank 1 · Mortal · Utility · Uncommon · cost 1
- Gain 4 Block. Draw 1.
- Refined: Gain 6 Block. Draw 2.
- Aperture: While equipped, travel takes 25% fewer days.

### Gale Stride Gu
- id `gale_stride` · Rank 2 · Light · Utility · Uncommon · cost 1
- Gain 6 Block. Draw 1.
- Refined: Gain 9 Block. Draw 1.
- Aperture: While equipped, travel takes 45% fewer days.

### Iron Fist Gu
- id `iron_fist` · Rank 1 · Strength · Offensive · Common · cost 1
- Deal 5 damage. +3 for each attack you already played this turn.
- Refined: Deal 8 damage. +3 for each attack you already played this turn.

### Rising Blow Gu
- id `rising_blow` · Rank 1 · Strength · Offensive · Common · cost 1
- Deal 8 damage. Gain 1 Strength this combat.
- Refined: Deal 11 damage. Gain 2 Strength this combat.

### Body Harden Gu
- id `body_harden` · Rank 1 · Strength · Defensive · Common · cost 1
- Gain 6 Block. If you already attacked this turn, gain 3 more.
- Refined: Gain 9 Block. If you already attacked this turn, gain 3 more.

### War Cry Gu
- id `war_cry` · Rank 2 · Strength · Utility · Uncommon · cost 1
- Gain 2 Strength. Draw 1. Exhaust.
- Refined: Gain 3 Strength. Draw 1. Exhaust.
- Exhausts.

### Crushing Palm Gu
- id `crushing_palm` · Rank 2 · Strength · Offensive · Uncommon · cost 2
- Deal 10 damage. +6 for each attack you already played this turn.
- Refined: Deal 13 damage. +6 for each attack you already played this turn.

### Titan Grip Gu
- id `titan_grip` · Rank 3 · Strength · Offensive · Rare · cost 2
- Deal 16 damage. Apply 2 Vulnerable.
- Refined: Deal 20 damage. Apply 2 Vulnerable.

### Bone Blade Gu
- id `bone_blade` · Rank 1 · Strength · Offensive · Uncommon · cost 1 · bai only-weighted
- Deal 9 damage. Apply 2 Bleed.
- Refined: Deal 12 damage. Apply 3 Bleed.

### Bear Strength Gu
- id `bear_strength` · Rank 2 · Strength · Utility · Uncommon · cost 1 · xiong only-weighted
- Gain 2 Strength and 4 Block.
- Refined: Gain 3 Strength and 6 Block.

### Flame Fist Gu
- id `flame_fist` · Rank 2 · Strength · Offensive · Uncommon · cost 1 · chi only-weighted
- Deal 7 damage. Apply 3 Burn.
- Refined: Deal 10 damage. Apply 4 Burn.

### Blood Frenzy Gu
- id `blood_frenzy` · Rank 1 · Blood · Offensive · Common · cost 1 + 3 HP
- Lose 3 HP. Deal 10 damage, or 15 if you are below half HP.
- Refined: Lose 3 HP. Deal 13 damage, or 18 if you are below half HP.

### Blood Siphon Gu
- id `vampiric_touch` · Rank 1 · Blood · Offensive · Common · cost 1
- Deal 7 damage. Heal for the damage dealt.
- Refined: Deal 10 damage. Heal for the damage dealt.

### Open Vein Gu
- id `open_vein` · Rank 1 · Blood · Utility · Uncommon · cost 0 + 4 HP
- Lose 4 HP. Gain 2 Essence. Exhaust.
- Refined: Lose 4 HP. Gain 3 Essence. Exhaust.
- Exhausts.

### Hemorrhage Gu
- id `hemorrhage` · Rank 2 · Blood · Offensive · Uncommon · cost 1
- Deal 6 damage. Apply 4 Bleed.
- Refined: Deal 8 damage. Apply 5 Bleed.

### Blood Bond Gu
- id `blood_bond` · Rank 2 · Blood · Utility · Uncommon · cost 1
- Heal 6. For the rest of combat, your attacks heal you for 3.
- Refined: Heal 9. For the rest of combat, your attacks heal you for 4.

### Sanguine End Gu
- id `sanguine_end` · Rank 3 · Blood · Offensive · Rare · cost 2 + 5 HP
- Lose 5 HP. Deal 8 damage + 1 for every missing HP (max 28).
- Refined: Lose 5 HP. Deal 10 damage + 1 for every missing HP (max 34).

### Venom Bite Gu
- id `venom_bite` · Rank 1 · Poison · Offensive · Common · cost 1
- Deal 4 damage. Apply 3 Poison.
- Refined: Deal 6 damage. Apply 4 Poison.

### Creeping Rot Gu
- id `creeping_rot` · Rank 1 · Poison · Utility · Common · cost 1
- Apply 4 Poison.
- Refined: Apply 6 Poison.

### Plague Spread Gu
- id `plague_spread` · Rank 2 · Poison · Utility · Uncommon · cost 1
- Double the target's Poison.
- Refined: Double the target's Poison, then apply 2 more.

### Corrosive Pool Gu
- id `corrosive_pool` · Rank 2 · Poison · Offensive · Uncommon · cost 1
- Deal damage equal to the target's Poison.
- Refined: Deal damage equal to the target's Poison + 4.

### Wither Gu
- id `wither` · Rank 2 · Poison · Utility · Uncommon · cost 1
- Apply 2 Vulnerable and 2 Poison.
- Refined: Apply 2 Vulnerable and 4 Poison.

### Epidemic Gu
- id `epidemic` · Rank 3 · Poison · Offensive · Rare · cost 2
- Deal 6 damage to all enemies and apply 3 Poison to each.
- Refined: Deal 9 damage to all enemies and apply 4 Poison to each.

### Crescent Ward Gu
- id `crescent_ward` · Rank 1 · Light · Defensive · Common · cost 1
- Gain 7 Block.
- Refined: Gain 10 Block.

### Moonlit Strike Gu
- id `moonlit_strike` · Rank 1 · Light · Offensive · Common · cost 1
- Deal 7 damage. At night, deal 10 instead.
- Refined: Deal 9 damage. At night, deal 13 instead.

### Purifying Light Gu
- id `purifying_light` · Rank 1 · Light · Utility · Uncommon · cost 1
- Cleanse yourself. Heal 3 for each stack removed.
- Refined: Cleanse yourself. Heal 5 for each stack removed.

### Light Shield Gu
- id `light_shield` · Rank 2 · Light · Defensive · Uncommon · cost 2
- Gain 13 Block. Retain.
- Refined: Gain 16 Block. Retain.
- Retain.

### Shield Burst Gu
- id `shield_burst` · Rank 2 · Light · Offensive · Uncommon · cost 1
- Deal damage equal to your Block, then lose all Block.
- Refined: Deal damage equal to your Block + 5, then lose all Block.

### Moonlight Gu
- id `moonlight_blade` · Rank 1 · Light · Offensive · Uncommon · cost 1 · guyue only-weighted
- Deal 8 damage. At night, gain 4 Block.
- Refined: Deal 11 damage. At night, gain 6 Block.

### Full Moon Gu
- id `full_moon` · Rank 3 · Light · Offensive · Rare · cost 2 · guyue only-weighted
- Deal 11 damage to all enemies. At night, deal 16 instead.
- Refined: Deal 14 damage to all enemies. At night, deal 20 instead.

### Shadow Cloak Gu
- id `shadow_cloak` · Rank 1 · Dark · Utility · Common · cost 1
- Your next attack deals +8. The next enemy attack has a 50% chance to miss.
- Refined: Your next attack deals +11. The next enemy attack has a 50% chance to miss.

### Shadow Dagger Gu
- id `shadow_dagger` · Rank 1 · Dark · Offensive · Common · cost 1
- Deal 7 damage. If you are hidden, deal 13 instead.
- Refined: Deal 9 damage. If you are hidden, deal 16 instead.

### Throat Slit Gu
- id `throat_slit` · Rank 2 · Dark · Offensive · Uncommon · cost 1
- Deal 7 damage. If the target is below 30% HP, deal 16 instead.
- Refined: Deal 9 damage. If the target is below 30% HP, deal 20 instead.

### Smoke Step Gu
- id `smoke_step` · Rank 1 · Dark · Defensive · Common · cost 1
- Gain 5 Block. Draw 1.
- Refined: Gain 8 Block. Draw 1.
- Aperture: Counts as a movement Gu for escape.

### Night Ambush Gu
- id `night_ambush` · Rank 2 · Dark · Offensive · Uncommon · cost 2
- Deal 14 damage. If you are hidden, apply 2 Weak.
- Refined: Deal 18 damage. If you are hidden, apply 2 Weak.

### Assassinate Gu
- id `assassinate` · Rank 3 · Dark · Offensive · Rare · cost 2
- Deal 12 damage. If the target is below 30% HP, deal 28 instead.
- Refined: Deal 14 damage. If the target is below 30% HP, deal 34 instead.

### Insight Gu
- id `insight` · Rank 1 · Wisdom · Utility · Common · cost 1
- Draw 2 cards.
- Refined: Draw 3 cards.

### Calculated Strike Gu
- id `calculated_strike` · Rank 1 · Wisdom · Offensive · Common · cost 1
- Deal 4 damage for each card in your hand.
- Refined: Deal 5 damage for each card in your hand.

### Deduction Gu
- id `deduction` · Rank 2 · Wisdom · Utility · Uncommon · cost 1
- Reveal the enemy pattern. Apply 1 Weak. Draw 1.
- Refined: Reveal the enemy pattern. Apply 2 Weak. Draw 1.

### Memory Palace Gu
- id `memory_palace` · Rank 2 · Wisdom · Utility · Uncommon · cost 1
- Gain 1 Essence. Draw 1. Exhaust.
- Refined: Gain 2 Essence. Draw 2. Exhaust.
- Exhausts.

### Foresight Gu
- id `foresight` · Rank 1 · Wisdom · Utility · Uncommon · cost 0
- Retain. At the start of your next turn, draw 1.
- Refined: Retain. At the start of your next turn, draw 2.
- Retain.

### Strategic Mind Gu
- id `strategic_mind` · Rank 2 · Wisdom · Utility · Rare · cost 1
- Draw 2. Gain 5 Block.
- Refined: Draw 3. Gain 7 Block.

### Information Network Gu
- id `information_network` · Rank 2 · Wisdom · Utility · Uncommon · cost 1 · shang only-weighted
- Reveal the enemy pattern. Gain 10 stones.
- Refined: Reveal the enemy pattern. Gain 16 stones.
- Aperture: Shops are 10% cheaper while this is equipped.

### Enhance Gu
- id `enhance` · Rank 1 · Refinement · Utility · Common · cost 1
- A card in your hand costs 1 less this combat.
- Refined: A card in your hand costs 1 less and is empowered (+3) this combat.

### Forge Blade Gu
- id `forge_blade` · Rank 1 · Refinement · Utility · Common · cost 1
- Add a Forged Edge Gu to your hand. Exhaust.
- Refined: Add two Forged Edge Gu to your hand. Exhaust.
- Exhausts.

### Deconstruct Gu
- id `deconstruct` · Rank 2 · Refinement · Utility · Uncommon · cost 1
- Remove all Block from the target. It loses 2 Strength. Deal 6 damage.
- Refined: Remove all Block from the target. It loses 3 Strength. Deal 9 damage.

### Tempering Gu
- id `repair` · Rank 2 · Refinement · Utility · Uncommon · cost 1
- Empower a card in your hand by +4 this combat.
- Refined: Empower a card in your hand by +6 this combat.

### Masterwork Gu
- id `masterwork` · Rank 3 · Refinement · Offensive · Rare · cost 2
- Deal 12 damage. Add a Forged Edge Gu to your hand.
- Refined: Deal 16 damage. Add a Forged Edge Gu to your hand.

### Forged Edge Gu
- id `forged_edge` · Rank 1 · Refinement · Offensive · Common · cost 0
- Deal 10 damage. Exhaust.
- Exhausts.

### Wolf Form Gu
- id `wolf_form` · Rank 1 · Transformation · Utility · Common · cost 1
- For 3 turns, your attacks deal +3 and apply 2 Bleed.
- Refined: For 4 turns, your attacks deal +4 and apply 2 Bleed.

### Mirror Scale Gu
- id `mirror_scale` · Rank 1 · Transformation · Defensive · Common · cost 1
- Gain 6 Block. Gain 3 Thorns.
- Refined: Gain 9 Block. Gain 4 Thorns.

### Mimic Strike Gu
- id `mimic_strike` · Rank 2 · Transformation · Offensive · Uncommon · cost 1
- Deal 8 damage. Apply a random debuff (Weak, Vulnerable, or Poison).
- Refined: Deal 11 damage. Apply a random debuff (Weak, Vulnerable, or Poison).

### Hybrid Shell Gu
- id `hybrid_shell` · Rank 2 · Transformation · Defensive · Uncommon · cost 1
- Gain 5 Block and 1 Strength.
- Refined: Gain 8 Block and 2 Strength.

### Serpent Form Gu
- id `serpent_form` · Rank 2 · Transformation · Utility · Rare · cost 2
- For the rest of combat, your attacks apply 2 Poison.
- Refined: For the rest of combat, your attacks apply 3 Poison.

### White Bone Gu
- id `white_bone` · Rank 3 · Transformation · Utility · Rare · cost 2 · bai only-weighted
- Gain 3 Strength and 3 Thorns. Lose 6 HP.
- Refined: Gain 4 Strength and 4 Thorns. Lose 6 HP.

### Beast Contract Gu
- id `beast_contract` · Rank 1 · Enslavement · Utility · Common · cost 1
- Summon a wolf that deals 5 damage at the end of your turn, for 4 turns.
- Refined: Summon a wolf that deals 7 damage at the end of your turn, for 4 turns.

### Puppet Strike Gu
- id `puppet_jab` · Rank 1 · Enslavement · Offensive · Common · cost 1
- Deal 6 damage. If you have a summon, deal 11 instead.
- Refined: Deal 8 damage. If you have a summon, deal 14 instead.

### Mind Shackle Gu
- id `mind_shackle` · Rank 2 · Enslavement · Utility · Uncommon · cost 2
- The target's next attack hits itself.
- Refined: The target's next attack hits itself. Apply 1 Weak.

### Dominating Presence Gu
- id `dominating_presence` · Rank 2 · Enslavement · Utility · Uncommon · cost 1
- Apply 2 Weak to all enemies. Gain 1 Strength.
- Refined: Apply 2 Weak to all enemies. Gain 2 Strength.

### Soul Contract Gu
- id `soul_contract` · Rank 2 · Enslavement · Utility · Rare · cost 1 · shang only-weighted
- Your summons deal +3 damage for the rest of combat. Summon a servant (4 damage, 4 turns).
- Refined: Your summons deal +4 damage for the rest of combat. Summon a servant (5 damage, 4 turns).

### Suggestion Gu
- id `suggestion` · Rank 1 · Enslavement · Utility · Common · cost 1 · shang only-weighted
- Apply 2 Weak. Draw 1.
- Refined: Apply 2 Weak. Draw 2.

### Chain Lash Gu
- id `chain_lash` · Rank 2 · Enslavement · Offensive · Uncommon · cost 1
- Deal 5 damage to all enemies.
- Refined: Deal 8 damage to all enemies.

### Hearty Bite Gu
- id `hearty_bite` · Rank 1 · Food · Defensive · Common · cost 1
- Heal 7.
- Refined: Heal 10.

### Nourishing Aura Gu
- id `nourishing_aura` · Rank 1 · Food · Utility · Common · cost 1
- Gain 3 Regeneration.
- Refined: Gain 4 Regeneration.

### Devouring Maw Gu
- id `devouring_maw` · Rank 2 · Food · Offensive · Uncommon · cost 1
- Deal 9 damage. If this kills, gain 18 stones.
- Refined: Deal 13 damage. If this kills, gain 24 stones.

### Feast Gu
- id `feast` · Rank 2 · Food · Utility · Uncommon · cost 1
- Exhaust another card in your hand. Heal 8. Draw 1.
- Refined: Exhaust another card in your hand. Heal 12. Draw 1.

### Liquor Worm
- id `primeval_brew` · Rank 1 · Food · Utility · Uncommon · cost 0
- Gain 2 Essence. Exhaust.
- Refined: Gain 3 Essence. Exhaust.
- Exhausts.

### Glutton Might Gu
- id `glutton_might` · Rank 2 · Food · Utility · Rare · cost 2
- Heal 6. Gain 3 Strength.
- Refined: Heal 8. Gain 4 Strength.

### Stone Harvest Gu
- id `stone_harvest` · Rank 1 · Food · Economic · Uncommon · cost 1
- Gain 14 stones. Exhaust.
- Refined: Gain 20 stones. Exhaust.
- Exhausts.

### Wound Gu
- id `curse_wound` · Rank 1 · Mortal · Curse · Common · cost 1
- Lose 3 HP. Exhaust.
- Exhausts.

### Debt Mark Gu
- id `curse_debt` · Rank 1 · Mortal · Curse · Common · cost 1
- Lose 8 stones. Exhaust.
- Exhausts.

### Haunting Gu
- id `curse_haunting` · Rank 1 · Dark · Curse · Common · cost 1
- Unplayable. A dead thing occupies the aperture.
- Unplayable.

## Killer moves

Each requires Master attainment in its path, at least 3 equipped Gu of that path, and can be used once per battle.

- **Mountain Crushing Fist** (Strength, 2 essence): Deal 24 damage. Apply 2 Weak.
- **Heavenly Calculation** (Wisdom, 1 essence): Draw 3. Gain 2 Essence. Reveal the enemy pattern.
- **Crimson Reversal** (Blood, 2 essence): Lose 6 HP. Deal 26 damage. Heal 10.
- **Grand Forge** (Refinement, 2 essence): Add two Forged Edge Gu to your hand. Empower your hand by +3.
- **Chimera Ascendant** (Transformation, 2 essence): Gain 3 Strength, 3 Thorns, and 3 Regeneration.
- **Absolute Dominion** (Enslavement, 2 essence): The target's next attack hits itself. Deal 10 damage. Summon a beast (8 damage, 3 turns).
- **Plague Sutra** (Poison, 2 essence): Double Poison, apply 4 more, then deal damage equal to twice the target's Poison.
- **Midnight Execution** (Dark, 2 essence): Deal 18 damage. If the target is below 40% HP or you are hidden, deal 32 instead.
- **Moonlight Devastation** (Light, 2 essence): Deal 12 damage to all enemies and gain 12 Block. At night, deal 20 instead.
- **Great Feast** (Food, 2 essence): Heal 16. Gain 3 Strength. Draw 2.

## Enemies

### Wild Ravage Boar
- id `boar` · HP 40 · Rank 1 · strength · 18 stones
- attack 12 / attack 8 / attack 6 block 6

### Mountain Wolf
- id `wolf` · HP 32 · Rank 1 · dark · evasion 3 · 16 stones
- attack 8 / attack 6×2 / attack 11

### Sparring Disciple
- id `disciple` · HP 38 · Rank 1 · strength · 17 stones
- attack 11 / debuff 7 weak 1 / attack 6 block 6

### Green Python
- id `python` · HP 36 · Rank 1 · poison · 18 stones
- debuff poison 4 / attack 9 / attack 11

### Road Bandit
- id `bandit` · HP 22 · Rank 1 · dark · 11 stones
- attack 6 / attack 7 / defend block 4

### Bone Armored Veteran
- id `bone_veteran` · HP 60 · Rank 2 · strength · evasion 1 · 42 stones · elite
- attack 14 "Bone Split" / defend block 10 / attack 7 vulnerable 2

### Clan Rival
- id `clan_rival` · HP 86 · Rank 2 · light · 62 stones · boss
- attack 10 / defend block 8 / attack 13
- Below 50%: The rival stops holding back. buff +2 str / attack 13 "Clan Secret" / attack 8×2

### Ironhide Stag
- id `stag` · HP 44 · Rank 2 · strength · 22 stones
- attack 13 / defend block 10 / attack 8

### Plains Jackal
- id `jackal` · HP 20 · Rank 2 · dark · evasion 3 · 12 stones
- attack 7 / attack 4×2

### Blood Path Gu Master
- id `cultist` · HP 40 · Rank 2 · blood · 24 stones
- attack 11 / debuff 4 bleed 3 / buff +2 str

### Beast Raider
- id `raider` · HP 38 · Rank 2 · enslavement · 22 stones
- attack 9 / attack 6×2 / defend block 8

### Armored Rhino King
- id `rhino` · HP 72 · Rank 3 · strength · 48 stones · elite
- attack 16 "Trample" / defend block 14 / attack 10 vulnerable 1

### Bounty Hunter
- id `bounty_hunter` · HP 64 · Rank 3 · dark · evasion 4 · 50 stones · elite
- attack 12 / debuff 8 weak 2 / attack 7×2 "Marked Prey"

### Thousand Beast King
- id `beast_king` · HP 110 · Rank 3 · strength · 70 stones · boss
- attack 12 / defend block 12 / attack 8×2
- Below 55%: The king roars and the plain shakes. buff +3 str / attack 18 "Earth-Splitter" / attack 11

### City Enforcer
- id `enforcer` · HP 48 · Rank 3 · light · 24 stones
- attack 12 / defend block 14 / attack 9 weak 1

### Hired Blade
- id `blade` · HP 42 · Rank 3 · dark · evasion 5 · 26 stones
- attack 14 / attack 6×2 / debuff poison 3

### Hu Land Moth
- id `hu_beast` · HP 46 · Rank 3 · transformation · 26 stones
- debuff weak 2 vulnerable 1 / attack 11 / attack 8 poison 2

### Forge Ghost
- id `forge_ghost` · HP 68 · Rank 4 · refinement · 52 stones · elite
- attack 10 burn 3 "Cinder Brand" / defend block 12 / attack 15

### Grotto Guardian
- id `grotto_guardian` · HP 125 · Rank 4 · refinement · 78 stones · boss
- defend block 16 / attack 14 / attack 9×2
- Below 50%: The guardian sheds its stone skin. buff +2 str / attack 18 "Mountain Bell" / attack 12 burn 2

### Soul Remnant
- id `remnant` · HP 50 · Rank 4 · wisdom · 28 stones
- debuff 8 weak 2 / attack 13 / attack 7 poison 3

### Tomb Guard
- id `tomb_guard` · HP 58 · Rank 4 · strength · 30 stones
- attack 15 / defend block 14 / attack 10

### Miasma Crawler
- id `crawler` · HP 44 · Rank 4 · poison · 28 stones
- debuff poison 4 / attack 9 / attack 12

### Soul Wisp
- id `wisp` · HP 18 · Rank 4 · wisdom · 14 stones
- attack 5 / debuff 3 poison 2

### Dang Hun Wraith
- id `wraith` · HP 74 · Rank 5 · dark · evasion 4 · 55 stones · elite
- attack 14 "Soul Bite" / debuff weak 2 vulnerable 2 / attack 8×2

### Earthly Calamity
- id `calamity` · HP 160 · Rank 5 · refinement · 90 stones · boss, calamity
- attack 14 / defend block 16 / attack 8×2 burn 2
- Below 60%: Heaven, earth, and the crowd turn against you. attack 18 "Calamity Descends" / debuff 6 weak 2 vulnerable 1 / attack 11×2

### Immortal Soldier
- id `soldier` · HP 84 · Rank 6 · light · 34 stones
- attack 18 / defend block 14 / attack 11×2

### Immortal Schemer
- id `politician` · HP 72 · Rank 6 · wisdom · 36 stones
- debuff weak 2 vulnerable 1 / attack 16 / buff block 8 +2 str

### Heavenly Tribulation
- id `tribulation_cloud` · HP 165 · Rank 7 · light · 40 stones · boss
- attack 16 "Tribulation Bolt" / defend block 14 / attack 10×2
- Below 50%: A second bolt gathers. attack 24 / debuff 12 vulnerable 2

### Immortal General
- id `great_general` · HP 185 · Rank 8 · strength · 48 stones · boss
- attack 18 / buff +2 str / attack 12×2 "Banner Fall"
- Below 45%: The general draws an immortal blade. attack 28 / attack 16 vulnerable 2

### Venerable Tribulation
- id `venerable` · HP 300 · Rank 9 · light · 0 stones · boss, finale
- attack 18 / defend block 18 / attack 12×2
- Below 66%: The tribulation shows its second face. attack 22 "Dao Collapse" / debuff 10 weak 2 vulnerable 2 / buff +3 str
- Below 33%: Only the last heaven remains. attack 18×2 "Heavenly Will" / attack 32

## Treasures

- **Spring Autumn Fragment** (Rare): Once per run, a killing blow leaves you at 1 HP.
- **Moonstone Seal** (Uncommon): At night, your attacks deal +3 damage.
- **Marrow Cord** (Uncommon): After you have already attacked this turn, attacks deal +3.
- **Merchant's Abacus** (Common): Shops are 20% cheaper.
- **Venom Gland** (Uncommon): Whenever you apply Poison, apply 1 more.
- **Iron Gut** (Uncommon): Food heals +3. Start each combat with 2 Regeneration.
- **Chain of Oaths** (Uncommon): Summons deal +2 damage.
- **Scholar's Inkstone** (Common): Draw 1 extra card on the first turn of combat.
- **Blood Pearl** (Rare): Whenever a card costs you HP, gain 1 Strength this combat (max 4).
- **Shadow Candle** (Uncommon): The first Dark card you play each combat costs 0.
- **Forge Bellows** (Uncommon): Refinement cards have +2 to their numeric effects.
- **Beast Whistle** (Uncommon): Start each combat with a wolf (4 damage, 3 turns).
- **Dao Mark Fragment** (Rare): All path bonuses are 10% stronger.
- **Clan Token** (Common): Elites and bosses drop +18 stones.
- **Lifespan Lotus** (Rare): When you clear an act, gain 1 year of lifespan.
- **Heaven's Gaze** (Uncommon): Elite and boss patterns start revealed. Gain 1 Strength in those fights.
- **Cauldron Lid** (Uncommon): Keep up to 6 Block between turns.
- **Demonic Mask** (Rare): If your reputation is demonic, start each combat with +1 Essence.

## Items

- **Year-Fruit Gu** (78 stones): Extend your death-age by 4 years.
- **Healing Salve** (28 stones): Heal 22 HP.
- **Scout's Report** (32 stones): Your next elite or boss is fully scouted (+1 Strength in that fight).
- **Fodder Bundle** (18 stones): Feed every Gu. Hunger clears.
- **Minor Relic Gu** (55 stones): Advance one stage inside your current rank. No effect at Peak.

## Events

### A Wandering Merchant
Merchant Wang spreads a cloth on a flat stone. He swears the Gu among his jars is sound. Merchants swear to everything.
- **Pay his price (48 stones)**: The stones change hands. The Gu is yours to refine and feed.
- **Press him on the price** (55% before Wisdom): He weighs your patience against his road and takes thirty.
  - If it fails: He folds the cloth and leaves. He will remember your face at the next market.
- **Decline**: You bow and walk on. Stones kept can still be spent elsewhere.

### A Familiar Face
Elder Mo stands on the path as if by chance. The dust on his sleeves says he has waited some time. An elder who waits wants something.
- **Greet him properly**: He presses a small purse into your hand and names the ridge to avoid. An elder's kindness is an investment, and he will expect a return.
- **Press him for what he knows**: He names the habits of the next elite you will face. He also notes that you questioned him before you greeted him.
- **Take the purse by force**: A clan disciple steps in to defend him. Whatever happens next, the clan will hear of it, and the clan does not forget.
- **Walk on**: You pass him without a word. He does not call after you.

### Hidden Cave
Behind a thread of waterfall, the stone is wrong. Someone carved a door and then tried to forget it.
- **Enter carefully**: You test every step. It costs days, but you leave with a Gu and a pouch of materials.
- **Rush in** (60% before Wisdom): A sealed niche gives way under your hand. Whoever hid this treasure never came back for it.
  - If it fails: A ward snaps shut on your arm. You crawl out bleeding, with nothing to show for it.
- **Mark it and study**: You copy the ward-marks and study how they were built. The next ward you meet will cost you less.

### Blocked Path
A rank 2 beast has claimed the pass. The long way around costs months, and months are lifespan.
- **Kill it**: You take the pass by force and step over the carcass.
- **Slip past with a movement Gu** (70% before Wisdom): Your movement Gu carries you through the grass. The beast never lifts its head.
  - If it fails: A twig breaks under your foot. The beast turns, and the pass becomes a fight after all.
- **Take the long road (+140 days)**: Months later you come out the other side unhurt. The beast cost you nothing but time, and time is the one resource you cannot refine.

### A Cry for Help
A young Gu Master is backed against a cart by two bandits. None of them have seen you yet.
- **Step in openly**: The bandits fall. Word of it reaches the next village before you do, and a good name is a tool like any other.
- **Kill them and leave unnamed**: You leave before anyone can ask your name. No debt is owed, and no favor is earned.
- **Walk away**: The cry follows you a short way, then stops. Someone saw you turn away, and the story travels.

### The Merchant's Request
Merchant Wang wants a sealed crate carried to the next market. The pay is good, which is the first warning. Something inside the crate shifts.
- **Accept the delivery**: He pays half now and the rest on delivery. The crate is heavier than it should be.
- **Refuse**: He finds someone else before you reach the ridge. He will remember that you refused.

### Suspicious Package
- Requires flag `package`.
On the road, something scratches inside the crate. The seal bears the Shang clan's mark.
- **Break the seal**: A young beast blinks at the light. You keep the Gu that bound it and let the animal go. A broken seal is a broken contract, and word of it spreads.
- **Deliver it sealed**: Merchant Wang pays the rest without counting it. What was in the crate is no longer your concern.

### The Year-Fruit Tree
A stunted tree grows out of a grave-mound. One fruit shines like a coin. The roots drink from the mound.
- **Take the fruit**: You pick the fruit. The dead have no use for years, and you do.
- **Leave stones at the roots (30)**: You leave stones at the roots for whoever tends the grave, and take the fruit with clean hands.
- **Leave it**: You study the leaves and the soil and leave the fruit. Someone hungrier will take it.

### Ancient Stele
A broken stele lists a killer move in a hand you half know. Copying it will cost days.
- **Study (+28 attainment)**: Days pass over the characters. When you rise, the method is yours, and the stele is only stone.
- **Chip off a relic fragment** (50% before Wisdom): A piece comes away clean.
  - If it fails: A residual ward lashes out. Your hand bleeds and stays numb until morning.
- **Leave it to the moss**: You leave the stele as you found it. Days saved are days of life.

### Black Market Stall
Under a wineshop, Broker Lian sells Gu the clan markets will not name.
- **Buy a forbidden Gu (55 stones)**: The Gu comes wrapped in black cloth. Someone in the room will remember that you bought it.
- **Buy a report (32 stones)**: She describes the next elite as if she raised it.
- **Climb back to the street**: You climb back to the street with your stones and your name intact.

### Injured Beast
A wolf hangs in a hunter's wire, more angry than afraid. Hunter Tie Shan set this wire, and he would call the wolf a gift.
- **Enslave it**: The wolf bites once before it yields. The enslavement Gu settles into your aperture, and the wolf is yours.
- **Cut it free**: It vanishes into the grass. You bind your scratches and walk on, and the villages hear of the mercy.
- **Kill it for materials**: You take the hide and teeth. The hunter will find his wire empty and guess who emptied it.

### Moonlit Duel
Rival Pei waits in a moonlit clearing. He wants a duel, and he wants it witnessed.
- **Accept the duel**: You beat him under the moon. He will return when he is stronger, so you must be stronger too.
- **Share a drink instead**: The wine and talk run on for days. A rival who drinks with you is a rival you can measure.
- **Refuse**: He laughs loudly enough for the whole clearing to hear. The story he tells will not be kind.

### Poison Marsh
The path sinks into green water. Every breath tastes of copper and rot.
- **Wade through**: You come out sick, but you understand the poison better than you did.
- **Use a Light Gu to clear the way**: A pale light opens the way. The marsh hisses and closes behind you.
- **Go around (+80 days)**: The long bank is dull and safe, and it costs you days.

### Soul Whisper
On Dang Hun Mountain the air speaks in a voice that could almost be yours. It offers a memory that belongs to someone long dead.
- **Listen** (65% before Wisdom): The memory is a technique. You keep the useful part.
  - If it fails: Something follows you out and settles into your aperture. It does not leave.
- **Shut your aperture and run**: You do not look back. The voice becomes wind.

### Hu Immortal's Threshold
The hillside looks ordinary. The grass grows in a perfect circle, and the circle is a door into a blessed land.
- **Cross the concealment**: Inside, the air is rich with essence. You rest, take a cutting, and leave before the land spirit takes notice.
- **Camp outside and cultivate**: You cultivate in the doorway's draft. Progress comes easier, and the days pass just as easily.
- **Pretend you saw nothing**: You walk on. An unknown door is a risk with no price attached, and you do not pay blind.

### Three Kings' Riddle
A stone king asks: which is heavier, a promise, a grudge, or a year? The door behind him is the reward.
- **A year**: The king nods. 'Only a year can eat the other two.' The door opens.
- **A grudge**: The king takes offense on behalf of the dead. A tomb guard rises to answer for him.
- **A promise**: The king grants a lesser prize. He respects a promise kept, even one made to stone.

### Hungry Aperture
Your Gu are restless. A hungry Gu fights poorly, and a starving one is a liability. A traveler sells fodder from a cart that smells of a kitchen and a barn.
- **Buy fodder (18 stones)**: The aperture quiets. Everything in it eats.
- **Share your own rations**: You go hungry so they will not. Your body is the cheaper resource.
- **Let them go hungry**: Their hunger will show in the next fight.

### Healer Qing
Healer Qing has set a kettle on a stone. She looks at your posture the way other people look at wounds.
- **Accept treatment (20 stones)**: The kettle steams. You leave walking like a younger person.
- **Ask about lifespan**: She tells you that year-fruit trees favor graves, and which graves. You note each one.
- **Thank her and go**: The kettle keeps singing.

### Southern Border Competition
- Epoch event.
Once in a generation the clans set a ring on the plain. They call the winner a symbol, and the symbol takes the prizes.
- **Enter the ring**: You leave the ring with bruises, stones, and a name the clans will repeat.
- **Watch and learn**: You watch others make mistakes and pay for them. Their lessons cost you only days.
- **Ignore the noise**: The cheering fades behind a ridge.

### Rumor of an Inheritance
- Epoch event.
Every inn is telling the same story: an inheritance has opened in the hills, and half the region is already lying about having found it.
- **Seek it** (55% before Wisdom): You find a side-chamber the crowd missed.
  - If it fails: You find only the crowd's leftovers, and the wraith that fed on the last searchers.
- **Sell the rumor (gain 25 stones)**: Others can risk their lives on the rumor. You take payment for it.
- **Let it pass**: Inheritances draw crowds, and crowds draw killers. You let it pass.

### An Ancient Stirring
- Epoch event.
The sky goes the color of old paper. An immortal who should have stayed asleep turns over in a mountain. The pressure ages flowers where they stand.
- **Endure and comprehend**: You lose days and a little blood to the pressure. What you comprehend is worth more than either.
- **Hide in closed meditation**: You seal yourself in closed meditation and wait. When the pressure lifts, your cultivation has advanced.
- **Flee the region for a time**: Distance keeps you safe. The months spent on the road do not come back.

### Clan Mission Board
The hall board holds three mission slips nobody has taken. Slips nobody wants pay badly or kill.
- **Patrol (safe stones)**: You walk the boundary for weeks. Nothing attacks, and the clan pays.
- **Hunt a nuisance beast**: You kill the beast and collect the bounty. The clan notes your name.
- **Leave the slips**: You leave the slips for someone with fewer plans.

## Sound and music hooks

These ids are the ones `play()` and `music()` accept. The recordings live in `game/assets/audio/` and are credited in `CREDITS.md` and `game/assets/audio/LICENSES.md`. Elites use `music_combat`. Bosses and tribulations use `music_boss`.

- `ui_click` (sfx): Soft woodblock tick for buttons and map seals.
- `card_play` (sfx): Paper snap when a Gu card is activated.
- `hit` (sfx): Dull impact for ordinary damage.
- `hit_big` (sfx): Heavier impact for crits and killer moves.
- `block` (sfx): Ceramic clack when block absorbs a hit.
- `heal` (sfx): High soft chime for healing.
- `poison` (sfx): Quiet wet tick for poison and bleed.
- `miss` (sfx): Short air swipe when an attack misses.
- `notify` (sfx): Small bell for events, rank-ups, and rewards.
- `death` (sfx): Low falling tone when a run ends.
- `victory` (sfx): Five-note rise when Rank 9 is reached.
- `music_title` (music): Guzheng bed for the title.
- `music_map` (music): Travel bed for the road.
- `music_combat` (music): Pulse for ordinary fights and elites.
- `music_boss` (music): Lower bed for bosses and tribulations.
- `music_blessed` (music): Koto bed for the blessed land.
