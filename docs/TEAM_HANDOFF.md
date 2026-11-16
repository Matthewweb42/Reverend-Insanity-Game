# Team handoff

Current numbers and text for design, writing, and audio. Generated from the live data files. If a number here and the game disagree, regenerate with `node game/test/handoff.js`. The game data is the source.

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
- Deal 5 damage. +4 for each attack you already played this turn.
- Refined: Deal 8 damage. +4 for each attack you already played this turn.

### Rising Blow Gu
- id `rising_blow` · Rank 1 · Strength · Offensive · Common · cost 1
- Deal 8 damage. Gain 1 Strength this combat.
- Refined: Deal 11 damage. Gain 2 Strength this combat.

### Body Harden Gu
- id `body_harden` · Rank 1 · Strength · Defensive · Common · cost 1
- Gain 7 Block. If you already attacked this turn, gain 3 more.
- Refined: Gain 10 Block. If you already attacked this turn, gain 3 more.

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

### Vampiric Touch Gu
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
- Gain 8 Block.
- Refined: Gain 11 Block.

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

### Moonlight Blade Gu
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

### Repair Gu
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
- Refined: Deal 11 damage. Apply a random debuff.

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
- Summon a wolf that deals 5 damage at the end of your turn, for 3 turns.
- Refined: Summon a wolf that deals 7 damage at the end of your turn, for 3 turns.

### Puppet Jab Gu
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

### Primeval Brew Gu
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
- id `boar` · HP 30 · Rank 1 · strength · 18 stones
- attack 9 / attack 6 / defend block 5

### Mountain Wolf
- id `wolf` · HP 24 · Rank 1 · dark · evasion 3 · 16 stones
- attack 6 / attack 4×2 / attack 8

### Sparring Disciple
- id `disciple` · HP 28 · Rank 1 · strength · 17 stones
- attack 8 / debuff 5 weak 1 / defend block 6

### Green Python
- id `python` · HP 27 · Rank 1 · poison · 18 stones
- debuff poison 3 / attack 7 / attack 8

### Road Bandit
- id `bandit` · HP 16 · Rank 1 · dark · 11 stones
- attack 5 / attack 6 / defend block 4

### Bone Armored Veteran
- id `bone_veteran` · HP 52 · Rank 2 · strength · evasion 1 · 42 stones · elite
- attack 12 "Bone Split" / defend block 10 / attack 7 vulnerable 2

### Clan Rival
- id `clan_rival` · HP 76 · Rank 2 · light · 62 stones · boss
- attack 9 / defend block 8 / attack 12
- Below 50%: The rival stops holding back. buff +2 str / attack 13 "Clan Secret" / attack 8×2

### Ironhide Stag
- id `stag` · HP 44 · Rank 2 · strength · 22 stones
- attack 13 / defend block 10 / attack 8

### Plains Jackal
- id `jackal` · HP 22 · Rank 2 · dark · evasion 5 · 12 stones
- attack 7 / attack 5×2

### Blood Path Cultist
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

### King of the Plains
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
- debuff poison 5 / attack 9 / attack 12

### Dang Hun Wraith
- id `wraith` · HP 78 · Rank 5 · dark · evasion 6 · 55 stones · elite
- attack 14 "Soul Bite" / debuff weak 2 vulnerable 2 / attack 8×2

### Earthly Calamity
- id `calamity` · HP 150 · Rank 5 · refinement · 90 stones · boss, calamity
- attack 14 / defend block 16 / attack 8×2 burn 2
- Below 60%: Heaven, earth, and the crowd turn against you. attack 18 "Heaven Tribulation" / debuff 6 weak 2 vulnerable 2 / attack 12×2

### Immortal Soldier
- id `soldier` · HP 62 · Rank 6 · light · 34 stones
- attack 14 / defend block 12 / attack 9×2

### Immortal Politician
- id `politician` · HP 54 · Rank 6 · wisdom · 36 stones
- debuff weak 2 vulnerable 1 / attack 12 / buff block 8 +2 str

### Heavenly Tribulation
- id `tribulation_cloud` · HP 130 · Rank 7 · light · 40 stones · boss
- attack 16 "Bolt" / defend block 14 / attack 10×2
- Below 50%: A second bolt gathers. attack 20 / debuff 10 vulnerable 2

### Immortal General
- id `great_general` · HP 145 · Rank 8 · strength · 48 stones · boss
- attack 18 / buff +2 str / attack 12×2 "Banner Fall"
- Below 45%: The general draws a venerable blade. attack 24 / attack 14 vulnerable 2

### Venerable Tribulation
- id `venerable` · HP 220 · Rank 9 · light · 0 stones · boss, finale
- attack 18 / defend block 18 / attack 12×2
- Below 66%: The tribulation shows its second face. attack 22 "Dao Collapse" / debuff 10 weak 2 vulnerable 2 / buff +3 str
- Below 33%: Only the last heaven remains. attack 16×2 "Supreme" / attack 28

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
Merchant Wang spreads a cloth on a stone. Among the jars is a Gu he swears is honest.
- **Buy it (48 stones)**: The cloth is folded. The Gu is yours.
- **Haggle** (55% before Wisdom): He grumbles and takes thirty.
  - If it fails: He snaps the cloth shut and leaves.
- **Decline**: You bow. The road continues.

### A Familiar Face
Elder Mo is on the path, pretending he is not waiting for you. His sleeves are dusty. That is new.
- **Greet him properly**: He presses a small purse into your hand and tells you which ridge to avoid.
- **Ask what he is hiding**: He sighs and names the next elite's habit. The warmth between you cools.
- **Take the purse**: Steel answers. The clan will hear of this.
- **Walk on**: You pass. He lets you.

### Hidden Cave
Behind a thread of waterfall, the stone is wrong. Someone carved a door and then tried to forget it.
- **Enter carefully**: You move slowly and leave with a Gu and a pouch of materials.
- **Rush in** (60% before Wisdom): A sealed niche opens under your hand. The treasure is still warm.
  - If it fails: A ward snaps. You crawl out bleeding and wiser.
- **Mark it and study**: You copy the ward-marks. Wisdom settles in like ink.

### Blocked Path
A rank 2 beast has decided the pass belongs to it. The long way around costs months.
- **Fight**: You take the pass by force.
- **Sneak, if you have movement Gu** (70% before Wisdom): Swift Steps carries you through the grass. The beast never lifts its head.
  - If it fails: A twig. A roar. The pass is a fight after all.
- **Take the long road (+140 days)**: Months later you come out the other side, older and unhurt.

### A Cry for Help
A young cultivator is backed against a cart by two bandits. They have not seen you yet.
- **Step in**: The bandits fall. Word of it walks faster than you do.
- **Help without a name**: You leave before anyone asks who you were.
- **Walk away**: The cry follows you for a day. Then it stops.

### The Merchant's Request
Merchant Wang wants a sealed crate walked to the next market. The pay is good. The crate ticks.
- **Accept the delivery**: He pays half now. The crate is heavier than wood.
- **Refuse**: He finds someone else before you reach the ridge.

### Suspicious Package
- Requires flag `package`.
On the road the crate scratches from the inside. The seal is Shang-made.
- **Open it**: A young contract-beast blinks at the sun. You keep the Gu that bound it and let the beast go.
- **Deliver it sealed**: You are paid the rest. Somewhere behind you, something is unpacked.

### The Year-Fruit Tree
A stunted tree grows out of a grave-mound. One fruit shines like a coin. The roots drink from the mound.
- **Take the fruit**: The fruit is warm. The mound looks poorer.
- **Leave stones at the roots (30)**: You pay the dead. The fruit comes free of guilt, or close enough.
- **Leave it**: You memorize the leaves. Someone hungrier will come.

### Ancient Stele
A broken stele lists a killer move in a hand you half know. Copying it will cost days.
- **Study (+28 attainment)**: The characters settle into your path like stones into a river.
- **Chip off a relic fragment** (50% before Wisdom): A piece comes away clean.
  - If it fails: The stele bites. Your hand is numb until tomorrow.
- **Leave it to the moss**: Moss is the better scholar.

### Black Market Stall
Under a wineshop, Broker Lian sells Gu the clan markets will not name.
- **Buy a forbidden Gu (55 stones)**: The Gu is wrapped in black cloth. Your reputation walks the other way.
- **Buy a report (32 stones)**: She describes the next elite as if she raised it.
- **Climb back to the street**: Daylight feels thinner than it did.

### Injured Beast
A wolf is caught in a hunter's wire. It is more angry than afraid. Hunter Tie Shan would call this a gift.
- **Offer a contract**: The wolf bites once, then accepts the terms. A contract Gu condenses in your palm.
- **Cut it free**: It vanishes into the grass. You feel, briefly, unbitten.
- **Take the materials**: Hide, teeth, and a little shame.

### Moonlit Duel
Rival Pei is waiting in a clearing because the moon is good tonight and he wants witnesses, even if the witnesses are owls.
- **Accept the duel**: You settle it under the moon. He will try again when he is stronger.
- **Share a drink instead**: You lose a night and gain something like a truce.
- **Refuse**: He laughs too loudly. The story will not be kind.

### Poison Marsh
The path sinks into green water. Every breath tastes like a coin left in a mouth.
- **Wade through**: You come out sick and educated.
- **Burn a Light Gu's patience**: A pale light opens the way. The marsh hisses and closes behind you.
- **Go around (+80 days)**: The long bank is dull and safe.

### Soul Whisper
On Dang Hun the air speaks in a voice you have not used yet. It offers a memory that is not yours.
- **Listen** (65% before Wisdom): The memory is a technique. You keep the useful part.
  - If it fails: Something follows you out. It takes a slot in the aperture and will not introduce itself.
- **Shut your aperture and run**: You do not look back. The voice becomes wind.

### Hu Immortal's Threshold
A perfectly ordinary hillside is a lie. The grass grows in a circle, and the circle is a door.
- **Cross the concealment**: Inside, time feels polite. You rest, take a cutting, and leave before the land notices.
- **Camp outside and cultivate**: You cultivate in the doorway's draft. Progress comes easier. So do the days.
- **Pretend you saw nothing**: A wise kind of cowardice.

### Three Kings' Riddle
A stone king asks: which is heavier, a promise, a grudge, or a year? The door behind him is the reward.
- **A year**: The king nods. 'Only a year can eat the other two.' The door opens.
- **A grudge**: The king is insulted on behalf of the dead.
- **A promise**: A lesser prize. The king respects manners.

### Hungry Aperture
Your Gu are restless. A traveler sells fodder from a cart that smells like a kitchen and a barn.
- **Buy fodder (18 stones)**: The aperture quiets. Everything in it eats.
- **Share your own rations**: You go hungry so they will not.
- **Let them sulk**: They will remember this in the next fight.

### Healer Qing
Healer Qing has set a kettle on a stone. She looks at your posture the way other people look at wounds.
- **Accept treatment (20 stones)**: The kettle steams. You leave walking like a younger person.
- **Ask about lifespan**: She tells you where year-fruit trees favor graves. You wish she had not been so specific.
- **Thank her and go**: The kettle keeps singing.

### Southern Border Competition
- Epoch event.
Once in a generation the clans set a ring on the plain and pretend the winner is only a symbol. The symbol is allowed to take prizes.
- **Enter the ring**: You leave the ring with bruises, stones, and a story the clans will repeat wrong.
- **Watch and learn**: Other people's mistakes are a fine textbook.
- **Ignore the noise**: The cheering fades behind a ridge.

### Rumor of an Inheritance
- Epoch event.
Every inn is telling the same story: an inheritance has opened in the hills, and half the region is already lying about having found it.
- **Seek it** (55% before Wisdom): You find a side-chamber the crowd missed.
  - If it fails: You find the crowd's leftovers, and they are angry.
- **Sell the rumor (gain 25 stones)**: Someone else can be brave. You will be paid.
- **Let it pass**: Rumors are a kind of weather.

### An Ancient Stirring
- Epoch event.
The sky goes the color of old paper. An immortal who should have stayed asleep turns over in a mountain. The pressure ages flowers where they stand.
- **Endure and comprehend**: You lose hair, days, and a little blood. What you gain does not fit in a purse.
- **Hide in closed meditation**: You close the aperture and wait. The sky eventually remembers its job.
- **Flee the region for a time**: Distance helps. Time does not.

### Clan Mission Board
The board in the hall has three slips that have not been taken, which tells you something about the slips.
- **Patrol (safe stones)**: You walk the boundary. Nothing eats you. The clan pays.
- **Hunt a nuisance beast**: The nuisance is removed. So is a piece of your sleeve.
- **Leave the slips**: Someone else can be dutiful.

## Sound and music hooks

All of these play today as short original synthesis. None of them are final recordings. Replace the body of `play()` / `music()` in `game/js/audio.js` and keep the ids.

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
- `music_title` (music): Slow D pentatonic drone for the title. Placeholder theme.
- `music_map` (music): Sparse G pentatonic travel bed for the road.
- `music_combat` (music): Tighter E minor pulse for ordinary fights.
- `music_boss` (music): Lower drone and a slow pulse for bosses and tribulations.
- `music_blessed` (music): Airy A pentatonic for the blessed land.
