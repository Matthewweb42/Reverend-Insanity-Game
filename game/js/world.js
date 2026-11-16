/** Enemies, treasures, events, origins, and the journey. */

export const ENVS = {
  forest: { id: "forest", name: "Bamboo Wilds", note: "Shade favors the Dark Path. Dark attacks deal +2.", dark: 2 },
  plains: { id: "plains", name: "Beast Plains", note: "Open ground favors Strength. Strength attacks deal +2.", strength: 2 },
  market: { id: "market", name: "Merchant City", note: "A bounty is posted. Victory pays +12 stones.", bounty: 12 },
  soul: { id: "soul", name: "Dang Hun Miasma", note: "Soul miasma deals 2 damage at the start of your turn.", miasma: 2 },
  ruins: { id: "ruins", name: "Three Kings Ruins", note: "Ancient dust. The first Refinement card you play each turn draws 1.", refineDraw: 1 },
  volcanic: { id: "volcanic", name: "Calamity Ash", note: "You begin the fight with 3 Burn.", startBurn: 3 },
  blessed: { id: "blessed", name: "Blessed Land", note: "The land mends you. Regenerate 2 at the start of your turn.", regen: 2 },
  heaven: { id: "heaven", name: "Heavenly Pressure", note: "Tribulation wind. Enemies begin with 8 Block.", enemyBlock: 8 },
  village: { id: "village", name: "Clan Village", note: "Familiar ground. Your first Block each turn is +2.", firstBlock: 2 },
};

export const ENEMIES = {};
function enemy(e) { ENEMIES[e.id] = e; }

enemy({ id: "boar", name: "Wild Ravage Boar", hp: 30, rank: 1, path: "strength", icon: "boar", stones: 18, moves: [
  { intent: "attack", dmg: 9 }, { intent: "attack", dmg: 6 }, { intent: "defend", block: 5 },
]});
enemy({ id: "wolf", name: "Mountain Wolf", hp: 24, rank: 1, path: "dark", icon: "wolf", evasion: 3, stones: 16, moves: [
  { intent: "attack", dmg: 6 }, { intent: "attack", dmg: 4, hits: 2 }, { intent: "attack", dmg: 8 },
]});
enemy({ id: "disciple", name: "Sparring Disciple", hp: 28, rank: 1, path: "strength", icon: "monk", stones: 17, moves: [
  { intent: "attack", dmg: 8 }, { intent: "debuff", dmg: 5, weak: 1 }, { intent: "defend", block: 6 },
]});
enemy({ id: "python", name: "Green Python", hp: 27, rank: 1, path: "poison", icon: "snake", stones: 18, moves: [
  { intent: "debuff", poison: 3 }, { intent: "attack", dmg: 7 }, { intent: "attack", dmg: 8 },
]});
enemy({ id: "bandit", name: "Road Bandit", hp: 16, rank: 1, path: "dark", icon: "hood", stones: 11, moves: [
  { intent: "attack", dmg: 5 }, { intent: "attack", dmg: 6 }, { intent: "defend", block: 4 },
]});
enemy({ id: "bone_veteran", name: "Bone Armored Veteran", hp: 52, rank: 2, path: "strength", icon: "skull", elite: true, stones: 42, evasion: 1, moves: [
  { intent: "attack", dmg: 12, killer: "Bone Split" }, { intent: "defend", block: 10 }, { intent: "attack", dmg: 7, vulnerable: 2 },
]});
enemy({ id: "clan_rival", name: "Clan Rival", hp: 76, rank: 2, path: "light", icon: "ninja", boss: true, stones: 62, moves: [
  { intent: "attack", dmg: 9 }, { intent: "defend", block: 8 }, { intent: "attack", dmg: 12 },
], phaseBelow: 0.5, phaseText: "The rival stops holding back.", moves2: [
  { intent: "buff", strength: 2 }, { intent: "attack", dmg: 13, killer: "Clan Secret" }, { intent: "attack", dmg: 8, hits: 2 },
]});

enemy({ id: "stag", name: "Ironhide Stag", hp: 44, rank: 2, path: "strength", icon: "bear", stones: 22, moves: [
  { intent: "attack", dmg: 13 }, { intent: "defend", block: 10 }, { intent: "attack", dmg: 8 },
]});
enemy({ id: "jackal", name: "Plains Jackal", hp: 22, rank: 2, path: "dark", icon: "wolf", evasion: 5, stones: 12, moves: [
  { intent: "attack", dmg: 7 }, { intent: "attack", dmg: 5, hits: 2 },
]});
enemy({ id: "cultist", name: "Blood Path Cultist", hp: 40, rank: 2, path: "blood", icon: "drop", stones: 24, moves: [
  { intent: "attack", dmg: 11 }, { intent: "debuff", bleed: 3, dmg: 4 }, { intent: "buff", strength: 2 },
]});
enemy({ id: "raider", name: "Beast Raider", hp: 38, rank: 2, path: "enslavement", icon: "paw2", stones: 22, moves: [
  { intent: "attack", dmg: 9 }, { intent: "attack", dmg: 6, hits: 2 }, { intent: "defend", block: 8 },
]});
enemy({ id: "rhino", name: "Armored Rhino King", hp: 72, rank: 3, path: "strength", icon: "boar", elite: true, stones: 48, moves: [
  { intent: "attack", dmg: 16, killer: "Trample" }, { intent: "defend", block: 14 }, { intent: "attack", dmg: 10, vulnerable: 1 },
]});
enemy({ id: "bounty_hunter", name: "Bounty Hunter", hp: 64, rank: 3, path: "dark", icon: "ninja", elite: true, stones: 50, evasion: 4, moves: [
  { intent: "attack", dmg: 12 }, { intent: "debuff", weak: 2, dmg: 8 }, { intent: "attack", dmg: 7, hits: 2, killer: "Marked Prey" },
]});
enemy({ id: "beast_king", name: "King of the Plains", hp: 110, rank: 3, path: "strength", icon: "bear", boss: true, stones: 70, moves: [
  { intent: "attack", dmg: 12 }, { intent: "defend", block: 12 }, { intent: "attack", dmg: 8, hits: 2 },
], phaseBelow: 0.55, phaseText: "The king roars and the plain shakes.", moves2: [
  { intent: "buff", strength: 3 }, { intent: "attack", dmg: 18, killer: "Earth-Splitter" }, { intent: "attack", dmg: 11 },
]});

enemy({ id: "enforcer", name: "City Enforcer", hp: 48, rank: 3, path: "light", icon: "shield", stones: 24, moves: [
  { intent: "attack", dmg: 12 }, { intent: "defend", block: 14 }, { intent: "attack", dmg: 9, weak: 1 },
]});
enemy({ id: "blade", name: "Hired Blade", hp: 42, rank: 3, path: "dark", icon: "dagger", evasion: 5, stones: 26, moves: [
  { intent: "attack", dmg: 14 }, { intent: "attack", dmg: 6, hits: 2 }, { intent: "debuff", poison: 3 },
]});
enemy({ id: "hu_beast", name: "Hu Land Moth", hp: 46, rank: 3, path: "transformation", icon: "bat", stones: 26, moves: [
  { intent: "debuff", weak: 2, vulnerable: 1 }, { intent: "attack", dmg: 11 }, { intent: "attack", dmg: 8, poison: 2 },
]});
enemy({ id: "forge_ghost", name: "Forge Ghost", hp: 68, rank: 4, path: "refinement", icon: "flame", elite: true, fire: true, stones: 52, moves: [
  { intent: "attack", dmg: 10, burn: 3, killer: "Cinder Brand" }, { intent: "defend", block: 12 }, { intent: "attack", dmg: 15 },
]});
enemy({ id: "grotto_guardian", name: "Grotto Guardian", hp: 125, rank: 4, path: "refinement", icon: "golem", boss: true, stones: 78, moves: [
  { intent: "defend", block: 16 }, { intent: "attack", dmg: 14 }, { intent: "attack", dmg: 9, hits: 2 },
], phaseBelow: 0.5, phaseText: "The guardian sheds its stone skin.", moves2: [
  { intent: "buff", strength: 2 }, { intent: "attack", dmg: 18, killer: "Mountain Bell" }, { intent: "attack", dmg: 12, burn: 2 },
]});

enemy({ id: "remnant", name: "Soul Remnant", hp: 50, rank: 4, path: "wisdom", icon: "ghost", stones: 28, moves: [
  { intent: "debuff", weak: 2, dmg: 8 }, { intent: "attack", dmg: 13 }, { intent: "attack", dmg: 7, poison: 3 },
]});
enemy({ id: "tomb_guard", name: "Tomb Guard", hp: 58, rank: 4, path: "strength", icon: "tomb", stones: 30, moves: [
  { intent: "attack", dmg: 15 }, { intent: "defend", block: 14 }, { intent: "attack", dmg: 10 },
]});
enemy({ id: "crawler", name: "Miasma Crawler", hp: 44, rank: 4, path: "poison", icon: "spider", stones: 28, moves: [
  { intent: "debuff", poison: 5 }, { intent: "attack", dmg: 9 }, { intent: "attack", dmg: 12 },
]});
enemy({ id: "wraith", name: "Dang Hun Wraith", hp: 78, rank: 5, path: "dark", icon: "spectre", elite: true, evasion: 6, stones: 55, moves: [
  { intent: "attack", dmg: 14, killer: "Soul Bite" }, { intent: "debuff", weak: 2, vulnerable: 2 }, { intent: "attack", dmg: 8, hits: 2 },
]});
enemy({ id: "calamity", name: "Earthly Calamity", hp: 150, rank: 5, path: "refinement", icon: "volcano", boss: true, calamity: true, stones: 90, moves: [
  { intent: "attack", dmg: 14 }, { intent: "defend", block: 16 }, { intent: "attack", dmg: 8, hits: 2, burn: 2 },
], phaseBelow: 0.6, phaseText: "Heaven, earth, and the crowd turn against you.", moves2: [
  { intent: "attack", dmg: 18, killer: "Heaven Tribulation" }, { intent: "debuff", weak: 2, vulnerable: 2, dmg: 6 }, { intent: "attack", dmg: 12, hits: 2 },
]});

enemy({ id: "soldier", name: "Immortal Soldier", hp: 62, rank: 6, path: "light", icon: "eagle", stones: 34, moves: [
  { intent: "attack", dmg: 14 }, { intent: "defend", block: 12 }, { intent: "attack", dmg: 9, hits: 2 },
]});
enemy({ id: "politician", name: "Immortal Politician", hp: 54, rank: 6, path: "wisdom", icon: "crown", stones: 36, moves: [
  { intent: "debuff", weak: 2, vulnerable: 1 }, { intent: "attack", dmg: 12 }, { intent: "buff", strength: 2, block: 8 },
]});
enemy({ id: "tribulation_cloud", name: "Heavenly Tribulation", hp: 130, rank: 7, path: "light", icon: "sun", boss: true, grantsRank: 7, stones: 40, moves: [
  { intent: "attack", dmg: 16, killer: "Bolt" }, { intent: "defend", block: 14 }, { intent: "attack", dmg: 10, hits: 2 },
], phaseBelow: 0.5, phaseText: "A second bolt gathers.", moves2: [
  { intent: "attack", dmg: 20 }, { intent: "debuff", vulnerable: 2, dmg: 10 },
]});
enemy({ id: "great_general", name: "Immortal General", hp: 145, rank: 8, path: "strength", icon: "dragon", boss: true, grantsRank: 8, stones: 48, moves: [
  { intent: "attack", dmg: 18 }, { intent: "buff", strength: 2 }, { intent: "attack", dmg: 12, hits: 2, killer: "Banner Fall" },
], phaseBelow: 0.45, phaseText: "The general draws a venerable blade.", moves2: [
  { intent: "attack", dmg: 24 }, { intent: "attack", dmg: 14, vulnerable: 2 },
]});
enemy({ id: "venerable", name: "Venerable Tribulation", hp: 220, rank: 9, path: "light", icon: "dragon", boss: true, finale: true, grantsRank: 9, stones: 0, moves: [
  { intent: "attack", dmg: 18 }, { intent: "defend", block: 18 }, { intent: "attack", dmg: 12, hits: 2 },
], phaseBelow: 0.66, phaseText: "The tribulation shows its second face.", moves2: [
  { intent: "attack", dmg: 22, killer: "Dao Collapse" }, { intent: "debuff", weak: 2, vulnerable: 2, dmg: 10 }, { intent: "buff", strength: 3 },
], phase3Below: 0.33, phaseText3: "Only the last heaven remains.", moves3: [
  { intent: "attack", dmg: 16, hits: 2, killer: "Supreme" }, { intent: "attack", dmg: 28 },
]});

export function getEnemy(id) { return ENEMIES[id]; }

export const RELICS = [
  { id: "spring_fragment", name: "Spring Autumn Fragment", icon: "hourglass", rarity: "Rare", text: "Once per run, a killing blow leaves you at 1 HP.", hooks: ["survive"] },
  { id: "moonstone", name: "Moonstone Seal", icon: "moon", rarity: "Uncommon", text: "At night, your attacks deal +3 damage.", hooks: ["nightBonus"] },
  { id: "marrow_cord", name: "Marrow Cord", icon: "bone", rarity: "Uncommon", text: "After you have already attacked this turn, attacks deal +3.", hooks: ["comboBonus"] },
  { id: "abacus", name: "Merchant's Abacus", icon: "scales", rarity: "Common", text: "Shops are 20% cheaper.", hooks: ["shopDiscount"] },
  { id: "venom_gland", name: "Venom Gland", icon: "poison", rarity: "Uncommon", text: "Whenever you apply Poison, apply 1 more.", hooks: ["poisonBonus"] },
  { id: "iron_gut", name: "Iron Gut", icon: "meal", rarity: "Uncommon", text: "Food heals +3. Start each combat with 2 Regeneration.", hooks: ["foodHeal", "startRegen"] },
  { id: "chain_oaths", name: "Chain of Oaths", icon: "chains", rarity: "Uncommon", text: "Summons deal +2 damage.", hooks: ["summonBonus"] },
  { id: "inkstone", name: "Scholar's Inkstone", icon: "book", rarity: "Common", text: "Draw 1 extra card on the first turn of combat.", hooks: ["turn1Draw"] },
  { id: "blood_pearl", name: "Blood Pearl", icon: "drop", rarity: "Rare", text: "Whenever a card costs you HP, gain 1 Strength this combat (max 4).", hooks: ["hpLossStrength"] },
  { id: "shadow_candle", name: "Shadow Candle", icon: "torch", rarity: "Uncommon", text: "The first Dark card you play each combat costs 0.", hooks: ["firstDarkFree"] },
  { id: "forge_bellows", name: "Forge Bellows", icon: "anvil", rarity: "Uncommon", text: "Refinement cards have +2 to their numeric effects.", hooks: ["refineBonus"] },
  { id: "beast_whistle", name: "Beast Whistle", icon: "eagle", rarity: "Uncommon", text: "Start each combat with a wolf (4 damage, 3 turns).", hooks: ["startSummon"] },
  { id: "dao_fragment", name: "Dao Mark Fragment", icon: "gems", rarity: "Rare", text: "All path bonuses are 10% stronger.", hooks: ["efficiency"] },
  { id: "clan_token", name: "Clan Token", icon: "coins", rarity: "Common", text: "Elites and bosses drop +18 stones.", hooks: ["eliteGold"] },
  { id: "lifespan_lotus", name: "Lifespan Lotus", icon: "lotus", rarity: "Rare", text: "When you clear an act, gain 1 year of lifespan.", hooks: ["yearsPerAct"] },
  { id: "heaven_gaze", name: "Heaven's Gaze", icon: "eye", rarity: "Uncommon", text: "Elite and boss patterns start revealed. Gain 1 Strength in those fights.", hooks: ["heavenGaze"] },
  { id: "cauldron_lid", name: "Cauldron Lid", icon: "cauldron", rarity: "Uncommon", text: "Keep up to 6 Block between turns.", hooks: ["retainBlock"] },
  { id: "demonic_mask", name: "Demonic Mask", icon: "hood", rarity: "Rare", text: "If your reputation is demonic, start each combat with +1 Essence.", hooks: ["demonicEnergy"] },
];

export function getRelic(id) { return RELICS.find((r) => r.id === id); }

export const ITEMS = {
  year_fruit: { id: "year_fruit", name: "Year-Fruit Gu", icon: "lotus", text: "Extend your death-age by 4 years.", price: 78 },
  healing_salve: { id: "healing_salve", name: "Healing Salve", icon: "potion2", text: "Heal 22 HP.", price: 28 },
  scout_report: { id: "scout_report", name: "Scout's Report", icon: "scroll", text: "Your next elite or boss is fully scouted (+1 Strength in that fight).", price: 32 },
  fodder: { id: "fodder", name: "Fodder Bundle", icon: "meat", text: "Feed every Gu. Hunger clears.", price: 18 },
  minor_relic_gu: { id: "minor_relic_gu", name: "Minor Relic Gu", icon: "upgrade", text: "Advance one stage inside your current rank. No effect at Peak.", price: 55 },
};

export const BLESSINGS = [
  { id: "heir", name: "Clan Heir", text: "+45 stones. You begin as a core member of the clan.", stones: 45, standing: 4 },
  { id: "year", name: "Hidden Year-Fruit", text: "Your lifespan is 6 years longer.", years: 6 },
  { id: "nest", name: "Wild Gu Nest", text: "Begin with an extra uncommon Gu of your main path.", nest: true },
  { id: "iron", name: "Iron Body", text: "+16 max HP.", hp: 16 },
  { id: "kin", name: "Merchant Kin", text: "+30 stones. Shops are 10% cheaper.", stones: 30, discount: 0.1 },
  { id: "keen", name: "Keen Mind", text: "+30 Wisdom attainment. You read odds more clearly.", wisdom: 30 },
];

export const BURDENS = [
  { id: "debt", name: "Clan Debt", text: "Begin 28 stones poorer.", stones: -28 },
  { id: "coveted", name: "Coveted Talent", text: "A bounty hunter joins the road in Act II.", flag: "coveted" },
  { id: "wound", name: "Old Wound", text: "−12 max HP.", hp: -12 },
  { id: "wick", name: "Short Wick", text: "Your lifespan is 4 years shorter.", years: -4 },
  { id: "infamous", name: "Infamous", text: "Begin at −25 reputation.", reputation: -25 },
  { id: "expectation", name: "Weight of Expectation", text: "A Debt Mark Gu starts in your aperture.", curse: "curse_debt" },
];

export const GOALS = [
  { id: "path:strength", label: "Seek Strength Gu", kind: "path", path: "strength" },
  { id: "path:wisdom", label: "Seek Wisdom Gu", kind: "path", path: "wisdom" },
  { id: "path:blood", label: "Seek Blood Gu", kind: "path", path: "blood" },
  { id: "path:refinement", label: "Seek Refinement Gu", kind: "path", path: "refinement" },
  { id: "path:transformation", label: "Seek Transformation Gu", kind: "path", path: "transformation" },
  { id: "path:enslavement", label: "Seek Enslavement Gu", kind: "path", path: "enslavement" },
  { id: "path:poison", label: "Seek Poison Gu", kind: "path", path: "poison" },
  { id: "path:dark", label: "Seek Dark Gu", kind: "path", path: "dark" },
  { id: "path:light", label: "Seek Light Gu", kind: "path", path: "light" },
  { id: "path:food", label: "Seek Food Gu", kind: "path", path: "food" },
  { id: "lifespan", label: "Seek lifespan", kind: "life" },
  { id: "stones", label: "Seek primeval stones", kind: "gold" },
  { id: "killer", label: "Seek killer moves", kind: "killer" },
  { id: "righteous", label: "Walk a righteous road", kind: "rep", side: 1 },
  { id: "demonic", label: "Walk a demonic road", kind: "rep", side: -1 },
  { id: "movement", label: "Seek movement Gu", kind: "movement" },
];

export const NPCS = [
  { id: "elder_mo", name: "Elder Mo", role: "Clan elder", path: "light", righteous: true, text: "A stern elder who still remembers your childhood name." },
  { id: "merchant_wang", name: "Merchant Wang", role: "Traveling merchant", path: "food", righteous: false, text: "Smiles with his whole face and charges with the other hand." },
  { id: "hunter_tie", name: "Hunter Tie Shan", role: "Beast hunter", path: "strength", righteous: true, text: "Smells of hide, iron, and rain." },
  { id: "healer_qing", name: "Healer Qing", role: "Traveling healer", path: "light", righteous: true, text: "Carries more salves than weapons, and uses both." },
  { id: "broker_lian", name: "Broker Lian", role: "Shadow broker", path: "dark", righteous: false, text: "Sells names, routes, and other people's secrets." },
  { id: "rival_pei", name: "Rival Pei", role: "Clan rival", path: "strength", righteous: true, text: "Wants the same inheritance you do, and says so." },
];

export const ORIGINS = [
  { id: "guyue", region: "south", kind: "Clan", name: "Gu Yue Clan", paths: ["light", "refinement", "wisdom"], icon: "moon",
    blurb: "Moonlight and balance. A clean place to learn the aperture.",
    age: 15, stones: 50, hp: 70, deathAge: 32, standing: 2, attainment: { light: 12 },
    deck: ["moonlit_strike", "moonlit_strike", "crescent_ward", "crescent_ward", "primeval_bolt", "steady_breath", "steady_breath", "insight", "mend", "moonlight_blade"] },
  { id: "bai", region: "south", kind: "Clan", name: "Bai Clan", paths: ["strength", "blood", "transformation"], icon: "bone",
    blurb: "Bone and aggression. More blood on the road, more power in the fist.",
    age: 16, stones: 36, hp: 82, deathAge: 32, standing: 2, attainment: { strength: 14 },
    deck: ["iron_fist", "iron_fist", "body_harden", "bone_blade", "blood_frenzy", "primeval_bolt", "steady_breath", "steady_breath", "mend", "vampiric_touch"] },
  { id: "shang", region: "south", kind: "Clan", name: "Shang Clan", paths: ["enslavement", "wisdom", "dark"], icon: "chains",
    blurb: "Contracts, rumors, and other people's hands.",
    age: 16, stones: 72, hp: 66, deathAge: 33, standing: 2, attainment: { enslavement: 12 }, discount: 0.1, npcBonus: 12,
    deck: ["suggestion", "puppet_jab", "puppet_jab", "shadow_dagger", "steady_breath", "steady_breath", "primeval_bolt", "primeval_bolt", "insight", "mend"] },
  { id: "xiong", region: "south", kind: "Clan", name: "Xiong Clan", paths: ["strength", "food", "enslavement"], icon: "bear",
    blurb: "Straightforward power. Eat, strike, and do not apologize.",
    age: 17, stones: 42, hp: 88, deathAge: 34, standing: 2, attainment: { strength: 16 },
    deck: ["iron_fist", "iron_fist", "body_harden", "body_harden", "hearty_bite", "beast_contract", "primeval_bolt", "primeval_bolt", "steady_breath", "mend"] },
  { id: "wu", region: "south", kind: "Clan", name: "Wu Clan", paths: ["poison", "dark", "blood"], icon: "poison", unlock: "clan:wu",
    blurb: "Assassins of the southern marshes. Unlock by reaching Expert Poison, or buy the record.",
    age: 16, stones: 40, hp: 68, deathAge: 31, standing: 2, attainment: { poison: 18 },
    deck: ["venom_bite", "venom_bite", "creeping_rot", "shadow_cloak", "steady_breath", "steady_breath", "primeval_bolt", "primeval_bolt", "hemorrhage", "mend"] },
  { id: "chi", region: "south", kind: "Clan", name: "Chi Clan", paths: ["refinement", "strength"], icon: "flame", unlock: "clan:chi",
    blurb: "Forge-clan. Unlock by defeating the Forge Ghost, or buy the record.",
    age: 16, stones: 44, hp: 74, deathAge: 32, standing: 2, attainment: { refinement: 16 },
    deck: ["iron_fist", "iron_fist", "forge_blade", "flame_fist", "steady_breath", "steady_breath", "primeval_bolt", "primeval_bolt", "rising_blow", "mend"] },
  { id: "huangjin", region: "plains", kind: "Tribe", name: "Huang Jin Tribe", paths: ["enslavement", "light"], icon: "eagle", unlock: "region:plains",
    blurb: "Golden eagle riders of the Northern Plains. A beast fights beside you.",
    age: 16, stones: 38, hp: 74, deathAge: 33, standing: 2, attainment: { enslavement: 10 },
    startSummon: { name: "Golden Eagle", dmg: 4, turns: 99, icon: "eagle" },
    deck: ["beast_contract", "moonlit_strike", "moonlit_strike", "crescent_ward", "gale_stride", "steady_breath", "primeval_bolt", "primeval_bolt", "steady_breath", "mend"] },
  { id: "heilou", region: "plains", kind: "Tribe", name: "Hei Lou Tribe", paths: ["dark", "strength"], icon: "wolf", unlock: "region:plains",
    blurb: "Dark wolf tribe. They strike from the grass and do not announce it.",
    age: 17, stones: 36, hp: 76, deathAge: 32, standing: 2, attainment: { dark: 12 },
    deck: ["shadow_dagger", "iron_fist", "iron_fist", "shadow_cloak", "steady_breath", "steady_breath", "primeval_bolt", "primeval_bolt", "wolf_form", "mend"] },
  { id: "swordsect", region: "central", kind: "Sect", name: "Heavenly Sword Sect", paths: ["strength", "light"], icon: "swords", unlock: "region:central",
    blurb: "Central Continent sword sect. Forms, drills, and very little patience.",
    age: 15, stones: 48, hp: 72, deathAge: 33, standing: 2, attainment: { strength: 10, light: 8 },
    deck: ["moonlit_strike", "moonlit_strike", "iron_fist", "iron_fist", "crescent_ward", "rising_blow", "steady_breath", "steady_breath", "primeval_bolt", "mend"] },
  { id: "mysterysect", region: "central", kind: "Sect", name: "Profound Mystery Sect", paths: ["wisdom", "refinement"], icon: "book", unlock: "region:central",
    blurb: "A sect of formulas. They would rather solve a fight than swing first.",
    age: 15, stones: 55, hp: 66, deathAge: 34, standing: 2, attainment: { wisdom: 16 },
    deck: ["insight", "insight", "deduction", "enhance", "forge_blade", "steady_breath", "steady_breath", "primeval_bolt", "primeval_bolt", "mend"] },
];

export const REGIONS = [
  { id: "south", name: "Southern Border", text: "Clan villages, beast plains, and the road to the calamity. Always open." },
  { id: "plains", name: "Northern Plains", text: "Tribes and beast partners. Unlocked between runs.", unlock: "region:plains" },
  { id: "central", name: "Central Continent", text: "Sects and stricter hierarchies. Unlocked between runs.", unlock: "region:central" },
];

export const ACTS = [
  { id: "clan", name: "Clan Wilds", region: "Southern Border", env: "village",
    blurb: "The hills outside your home. Wolves, disciples, and one rival who knows your name.",
    monsters: [["boar"], ["wolf"], ["disciple"], ["python"], ["bandit", "bandit"]],
    elites: [["bone_veteran"]], bosses: ["clan_rival"] },
  { id: "plains", name: "Wild Beast Plains", region: "Southern Border", env: "plains",
    blurb: "Grass to the horizon. Everything here has horns, fangs, or a contract.",
    monsters: [["stag"], ["jackal", "jackal"], ["cultist"], ["raider"], ["boar"]],
    elites: [["rhino"], ["bounty_hunter"]], bosses: ["beast_king"] },
  { id: "market", name: "Merchant Road", region: "Southern Border", env: "market",
    blurb: "Coin, contracts, and the hidden mouth of Hu Immortal's land.",
    monsters: [["enforcer"], ["blade"], ["hu_beast"], ["cultist"], ["raider"]],
    elites: [["forge_ghost"], ["bone_veteran"]], bosses: ["grotto_guardian"] },
  { id: "danghun", name: "Dang Hun Mountain", region: "Southern Border", env: "soul",
    blurb: "Soul-miasma and old tombs. At the summit, the Earthly Calamity waits.",
    monsters: [["remnant"], ["tomb_guard"], ["crawler"], ["blade"], ["remnant", "crawler"]],
    elites: [["wraith"]], bosses: ["calamity"] },
  { id: "heaven", name: "Immortal Heaven", region: "Blessed Land", env: "blessed",
    blurb: "Your blessed land, the auction of immortals, and the heavens that want you dead.",
    monsters: [["soldier"], ["politician"], ["soldier", "politician"], ["enforcer"]],
    elites: [["wraith"]], bosses: ["venerable"],
    forced: { 1: "blessed", 3: "tribulation", 5: "tribulationFinal" } },
];

export const EVENTS = [
  { id: "wandering_merchant", title: "A Wandering Merchant", icon: "shop", goals: ["stones", "movement"],
    text: "Merchant Wang spreads a cloth on a stone. Among the jars is a Gu he swears is honest.",
    choices: [
      { id: "buy", label: "Buy it (48 stones)", req: { stones: 48 }, fx: [{ op: "stones", n: -48 }, { op: "gainCard", pool: "uncommon" }], result: "The cloth is folded. The Gu is yours." },
      { id: "haggle", label: "Haggle", hint: true, chance: 0.55, fx: [{ op: "stones", n: -30 }, { op: "gainCard", pool: "uncommon" }], failFx: [{ op: "disposition", npc: "merchant_wang", n: -8 }], result: "He grumbles and takes thirty.", failResult: "He snaps the cloth shut and leaves." },
      { id: "leave", label: "Decline", fx: [], result: "You bow. The road continues." },
    ] },
  { id: "familiar_face", title: "A Familiar Face", icon: "conversation", goals: ["righteous"],
    text: "Elder Mo is on the path, pretending he is not waiting for you. His sleeves are dusty. That is new.",
    choices: [
      { id: "greet", label: "Greet him properly", fx: [{ op: "disposition", npc: "elder_mo", n: 18 }, { op: "stones", n: 15 }, { op: "standing", n: 1 }], result: "He presses a small purse into your hand and tells you which ridge to avoid." },
      { id: "demand", label: "Ask what he is hiding", fx: [{ op: "disposition", npc: "elder_mo", n: -6 }, { op: "intel", n: 1 }], result: "He sighs and names the next elite's habit. The warmth between you cools." },
      { id: "rob", label: "Take the purse", req: { notRep: 40 }, fx: [{ op: "combat", enemies: ["disciple"] }, { op: "reputation", n: -15 }, { op: "disposition", npc: "elder_mo", n: -40 }], result: "Steel answers. The clan will hear of this." },
      { id: "pass", label: "Walk on", fx: [], result: "You pass. He lets you." },
    ] },
  { id: "hidden_cave", title: "Hidden Cave", icon: "mountain", goals: ["killer"],
    text: "Behind a thread of waterfall, the stone is wrong. Someone carved a door and then tried to forget it.",
    choices: [
      { id: "careful", label: "Enter carefully", fx: [{ op: "material", n: 1 }, { op: "gainCard", pool: "common" }, { op: "days", n: 25 }], result: "You move slowly and leave with a Gu and a pouch of materials." },
      { id: "rush", label: "Rush in", hint: true, chance: 0.6, fx: [{ op: "gainRelic", random: true }], failFx: [{ op: "hp", n: -12 }], result: "A sealed niche opens under your hand. The treasure is still warm.", failResult: "A ward snaps. You crawl out bleeding and wiser." },
      { id: "mark", label: "Mark it and study", fx: [{ op: "attain", path: "wisdom", n: 12 }, { op: "days", n: 10 }], result: "You copy the ward-marks. Wisdom settles in like ink." },
    ] },
  { id: "blocked_path", title: "Blocked Path", icon: "boar", goals: ["movement"],
    text: "A rank 2 beast has decided the pass belongs to it. The long way around costs months.",
    choices: [
      { id: "fight", label: "Fight", fx: [{ op: "combat", enemies: ["stag"] }], result: "You take the pass by force." },
      { id: "sneak", label: "Sneak, if you have movement Gu", req: { movement: true }, hint: true, chance: 0.7, fx: [{ op: "stones", n: 10 }], failFx: [{ op: "combat", enemies: ["stag"] }], result: "Swift Steps carries you through the grass. The beast never lifts its head.", failResult: "A twig. A roar. The pass is a fight after all." },
      { id: "detour", label: "Take the long road (+140 days)", fx: [{ op: "days", n: 140 }, { op: "healPct", n: 0.15 }], result: "Months later you come out the other side, older and unhurt." },
    ] },
  { id: "cry_help", title: "A Cry for Help", icon: "heart", goals: ["righteous", "demonic"],
    text: "A young cultivator is backed against a cart by two bandits. They have not seen you yet.",
    choices: [
      { id: "hero", label: "Step in", fx: [{ op: "combat", enemies: ["bandit", "bandit"] }, { op: "reputation", n: 12 }, { op: "disposition", npc: "healer_qing", n: 10 }], result: "The bandits fall. Word of it walks faster than you do." },
      { id: "quiet", label: "Help without a name", fx: [{ op: "combat", enemies: ["bandit", "bandit"] }], result: "You leave before anyone asks who you were." },
      { id: "walk", label: "Walk away", fx: [{ op: "reputation", n: -10 }], result: "The cry follows you for a day. Then it stops." },
    ] },
  { id: "package", title: "The Merchant's Request", icon: "treasure", goals: ["stones"], chain: true,
    text: "Merchant Wang wants a sealed crate walked to the next market. The pay is good. The crate ticks.",
    choices: [
      { id: "accept", label: "Accept the delivery", fx: [{ op: "flag", key: "package", v: 1 }, { op: "stones", n: 20 }], result: "He pays half now. The crate is heavier than wood." },
      { id: "refuse", label: "Refuse", fx: [{ op: "disposition", npc: "merchant_wang", n: -4 }], result: "He finds someone else before you reach the ridge." },
    ] },
  { id: "package2", title: "Suspicious Package", icon: "cage", goals: ["demonic"], requiresFlag: "package",
    text: "On the road the crate scratches from the inside. The seal is Shang-made.",
    choices: [
      { id: "open", label: "Open it", fx: [{ op: "flag", key: "package", v: 0 }, { op: "gainCard", id: "beast_contract" }, { op: "reputation", n: -6 }], result: "A young contract-beast blinks at the sun. You keep the Gu that bound it and let the beast go." },
      { id: "deliver", label: "Deliver it sealed", fx: [{ op: "flag", key: "package", v: 0 }, { op: "stones", n: 35 }, { op: "disposition", npc: "merchant_wang", n: 14 }], result: "You are paid the rest. Somewhere behind you, something is unpacked." },
    ] },
  { id: "lifespan_tree", title: "The Year-Fruit Tree", icon: "lotus", goals: ["lifespan"],
    text: "A stunted tree grows out of a grave-mound. One fruit shines like a coin. The roots drink from the mound.",
    choices: [
      { id: "take", label: "Take the fruit", fx: [{ op: "item", id: "year_fruit", n: 1 }, { op: "reputation", n: -4 }], result: "The fruit is warm. The mound looks poorer." },
      { id: "pay", label: "Leave stones at the roots (30)", req: { stones: 30 }, fx: [{ op: "stones", n: -30 }, { op: "item", id: "year_fruit", n: 1 }, { op: "reputation", n: 6 }], result: "You pay the dead. The fruit comes free of guilt, or close enough." },
      { id: "leave", label: "Leave it", fx: [{ op: "attain", path: "wisdom", n: 6 }], result: "You memorize the leaves. Someone hungrier will come." },
    ] },
  { id: "stele", title: "Ancient Stele", icon: "scroll", goals: ["killer"],
    text: "A broken stele lists a killer move in a hand you half know. Copying it will cost days.",
    choices: [
      { id: "study", label: "Study (+28 attainment)", fx: [{ op: "attain", path: "focus", n: 28 }, { op: "days", n: 40 }], result: "The characters settle into your path like stones into a river." },
      { id: "chip", label: "Chip off a relic fragment", hint: true, chance: 0.5, fx: [{ op: "gainRelic", random: true }], failFx: [{ op: "hp", n: -8 }], result: "A piece comes away clean.", failResult: "The stele bites. Your hand is numb until tomorrow." },
      { id: "leave", label: "Leave it to the moss", fx: [], result: "Moss is the better scholar." },
    ] },
  { id: "black_market", title: "Black Market Stall", icon: "hood", goals: ["demonic"],
    text: "Under a wineshop, Broker Lian sells Gu the clan markets will not name.",
    choices: [
      { id: "buy", label: "Buy a forbidden Gu (55 stones)", req: { stones: 55 }, fx: [{ op: "stones", n: -55 }, { op: "gainCard", pool: "rare" }, { op: "reputation", n: -12 }, { op: "disposition", npc: "broker_lian", n: 12 }], result: "The Gu is wrapped in black cloth. Your reputation walks the other way." },
      { id: "intel", label: "Buy a report (32 stones)", req: { stones: 32 }, fx: [{ op: "stones", n: -32 }, { op: "intel", n: 1 }, { op: "reputation", n: -4 }], result: "She describes the next elite as if she raised it." },
      { id: "leave", label: "Climb back to the street", fx: [], result: "Daylight feels thinner than it did." },
    ] },
  { id: "injured_beast", title: "Injured Beast", icon: "wolf", goals: ["path:enslavement"],
    text: "A wolf is caught in a hunter's wire. It is more angry than afraid. Hunter Tie Shan would call this a gift.",
    choices: [
      { id: "bind", label: "Offer a contract", fx: [{ op: "gainCard", id: "beast_contract" }, { op: "disposition", npc: "hunter_tie", n: 8 }], result: "The wolf bites once, then accepts the terms. A contract Gu condenses in your palm." },
      { id: "mercy", label: "Cut it free", fx: [{ op: "reputation", n: 8 }, { op: "heal", n: 6 }], result: "It vanishes into the grass. You feel, briefly, unbitten." },
      { id: "kill", label: "Take the materials", fx: [{ op: "material", n: 2 }, { op: "reputation", n: -6 }], result: "Hide, teeth, and a little shame." },
    ] },
  { id: "moon_duel", title: "Moonlit Duel", icon: "moon", goals: ["path:light", "righteous"],
    text: "Rival Pei is waiting in a clearing because the moon is good tonight and he wants witnesses, even if the witnesses are owls.",
    choices: [
      { id: "duel", label: "Accept the duel", fx: [{ op: "combat", enemies: ["disciple"] }, { op: "disposition", npc: "rival_pei", n: -8 }, { op: "reputation", n: 6 }], result: "You settle it under the moon. He will try again when he is stronger." },
      { id: "toast", label: "Share a drink instead", fx: [{ op: "disposition", npc: "rival_pei", n: 16 }, { op: "days", n: 15 }], result: "You lose a night and gain something like a truce." },
      { id: "refuse", label: "Refuse", fx: [{ op: "reputation", n: -8 }, { op: "disposition", npc: "rival_pei", n: -12 }], result: "He laughs too loudly. The story will not be kind." },
    ] },
  { id: "swamp", title: "Poison Marsh", icon: "poison", goals: ["path:poison"],
    text: "The path sinks into green water. Every breath tastes like a coin left in a mouth.",
    choices: [
      { id: "wade", label: "Wade through", fx: [{ op: "hp", n: -8 }, { op: "attain", path: "poison", n: 14 }], result: "You come out sick and educated." },
      { id: "cleanse", label: "Burn a Light Gu's patience", req: { pathCard: "light" }, fx: [{ op: "attain", path: "light", n: 10 }], result: "A pale light opens the way. The marsh hisses and closes behind you." },
      { id: "around", label: "Go around (+80 days)", fx: [{ op: "days", n: 80 }], result: "The long bank is dull and safe." },
    ] },
  { id: "soul_whisper", title: "Soul Whisper", icon: "ghost", goals: ["path:wisdom"], minAct: 3,
    text: "On Dang Hun the air speaks in a voice you have not used yet. It offers a memory that is not yours.",
    choices: [
      { id: "listen", label: "Listen", hint: true, chance: 0.65, fx: [{ op: "attain", path: "wisdom", n: 22 }, { op: "gainCard", pool: "uncommon" }], failFx: [{ op: "hp", n: -10 }, { op: "gainCard", id: "curse_haunting" }], result: "The memory is a technique. You keep the useful part.", failResult: "Something follows you out. It takes a slot in the aperture and will not introduce itself." },
      { id: "shut", label: "Shut your aperture and run", fx: [{ op: "days", n: 20 }], result: "You do not look back. The voice becomes wind." },
    ] },
  { id: "hu_gate", title: "Hu Immortal's Threshold", icon: "waterfall", goals: ["killer"], minAct: 2,
    text: "A perfectly ordinary hillside is a lie. The grass grows in a circle, and the circle is a door.",
    choices: [
      { id: "cross", label: "Cross the concealment", fx: [{ op: "flag", key: "huFound", v: 1 }, { op: "healPct", n: 0.25 }, { op: "material", n: 1 }], result: "Inside, time feels polite. You rest, take a cutting, and leave before the land notices." },
      { id: "camp", label: "Camp outside and cultivate", fx: [{ op: "progress", n: 35 }, { op: "days", n: 40 }], result: "You cultivate in the doorway's draft. Progress comes easier. So do the days." },
      { id: "leave", label: "Pretend you saw nothing", fx: [], result: "A wise kind of cowardice." },
    ] },
  { id: "riddle", title: "Three Kings' Riddle", icon: "crown", goals: ["path:wisdom"], minAct: 3,
    text: "A stone king asks: which is heavier, a promise, a grudge, or a year? The door behind him is the reward.",
    choices: [
      { id: "year", label: "A year", fx: [{ op: "gainRelic", random: true }, { op: "days", n: 10 }], result: "The king nods. 'Only a year can eat the other two.' The door opens." },
      { id: "grudge", label: "A grudge", fx: [{ op: "combat", enemies: ["tomb_guard"] }, { op: "reputation", n: -4 }], result: "The king is insulted on behalf of the dead." },
      { id: "promise", label: "A promise", fx: [{ op: "disposition", npc: "elder_mo", n: 8 }, { op: "stones", n: 20 }], result: "A lesser prize. The king respects manners." },
    ] },
  { id: "feeding", title: "Hungry Aperture", icon: "meal", goals: ["path:food"],
    text: "Your Gu are restless. A traveler sells fodder from a cart that smells like a kitchen and a barn.",
    choices: [
      { id: "feed", label: "Buy fodder (18 stones)", req: { stones: 18 }, fx: [{ op: "stones", n: -18 }, { op: "feed" }], result: "The aperture quiets. Everything in it eats." },
      { id: "share", label: "Share your own rations", fx: [{ op: "hp", n: -6 }, { op: "feed" }], result: "You go hungry so they will not." },
      { id: "ignore", label: "Let them sulk", fx: [{ op: "hunger", n: 1 }], result: "They will remember this in the next fight." },
    ] },
  { id: "healer", title: "Healer Qing", icon: "heart", goals: ["righteous", "lifespan"],
    text: "Healer Qing has set a kettle on a stone. She looks at your posture the way other people look at wounds.",
    choices: [
      { id: "heal", label: "Accept treatment (20 stones)", req: { stones: 20 }, fx: [{ op: "stones", n: -20 }, { op: "healPct", n: 0.45 }, { op: "disposition", npc: "healer_qing", n: 12 }], result: "The kettle steams. You leave walking like a younger person." },
      { id: "talk", label: "Ask about lifespan", fx: [{ op: "disposition", npc: "healer_qing", n: 6 }, { op: "flag", key: "knowFruit", v: 1 }], result: "She tells you where year-fruit trees favor graves. You wish she had not been so specific." },
      { id: "leave", label: "Thank her and go", fx: [], result: "The kettle keeps singing." },
    ] },
  { id: "competition", title: "Southern Border Competition", icon: "trophy", epoch: true, goals: ["righteous"],
    text: "Once in a generation the clans set a ring on the plain and pretend the winner is only a symbol. The symbol is allowed to take prizes.",
    choices: [
      { id: "enter", label: "Enter the ring", fx: [{ op: "combat", enemies: ["bone_veteran"] }, { op: "reputation", n: 10 }, { op: "stones", n: 40 }], result: "You leave the ring with bruises, stones, and a story the clans will repeat wrong." },
      { id: "watch", label: "Watch and learn", fx: [{ op: "attain", path: "focus", n: 16 }, { op: "days", n: 20 }], result: "Other people's mistakes are a fine textbook." },
      { id: "ignore", label: "Ignore the noise", fx: [], result: "The cheering fades behind a ridge." },
    ] },
  { id: "verdant", title: "Rumor of an Inheritance", icon: "ruins", epoch: true, goals: ["killer"],
    text: "Every inn is telling the same story: an inheritance has opened in the hills, and half the region is already lying about having found it.",
    choices: [
      { id: "seek", label: "Seek it", hint: true, chance: 0.55, fx: [{ op: "gainRelic", random: true }, { op: "days", n: 30 }], failFx: [{ op: "combat", enemies: ["wraith"] }], result: "You find a side-chamber the crowd missed.", failResult: "You find the crowd's leftovers, and they are angry." },
      { id: "sell", label: "Sell the rumor (gain 25 stones)", fx: [{ op: "stones", n: 25 }, { op: "reputation", n: -4 }], result: "Someone else can be brave. You will be paid." },
      { id: "ignore", label: "Let it pass", fx: [], result: "Rumors are a kind of weather." },
    ] },
  { id: "ancient", title: "An Ancient Stirring", icon: "dragon", epoch: true, goals: ["lifespan"], minAct: 4,
    text: "The sky goes the color of old paper. An immortal who should have stayed asleep turns over in a mountain. The pressure ages flowers where they stand.",
    choices: [
      { id: "endure", label: "Endure and comprehend", fx: [{ op: "attain", path: "focus", n: 30 }, { op: "days", n: 60 }, { op: "hp", n: -6 }], result: "You lose hair, days, and a little blood. What you gain does not fit in a purse." },
      { id: "hide", label: "Hide in closed meditation", fx: [{ op: "progress", n: 40 }, { op: "days", n: 20 }], result: "You close the aperture and wait. The sky eventually remembers its job." },
      { id: "flee", label: "Flee the region for a time", fx: [{ op: "days", n: 100 }], result: "Distance helps. Time does not." },
    ] },
  { id: "clan_mission", title: "Clan Mission Board", icon: "village", goals: ["stones", "righteous"],
    text: "The board in the hall has three slips that have not been taken, which tells you something about the slips.",
    choices: [
      { id: "patrol", label: "Patrol (safe stones)", fx: [{ op: "stones", n: 22 }, { op: "standing", n: 1 }, { op: "days", n: 30 }], result: "You walk the boundary. Nothing eats you. The clan pays." },
      { id: "hunt", label: "Hunt a nuisance beast", fx: [{ op: "combat", enemies: ["boar"] }, { op: "stones", n: 18 }, { op: "standing", n: 1 }], result: "The nuisance is removed. So is a piece of your sleeve." },
      { id: "skip", label: "Leave the slips", fx: [], result: "Someone else can be dutiful." },
    ] },
];

export function getEvent(id) { return EVENTS.find((e) => e.id === id); }

export const FORMULAS = [
  { id: "venom_bite", materials: 1, stones: 20 },
  { id: "crescent_ward", materials: 1, stones: 20 },
  { id: "beast_contract", materials: 1, stones: 24 },
  { id: "forge_blade", materials: 2, stones: 28 },
  { id: "hearty_bite", materials: 1, stones: 16 },
];

export const LEGACY_SHOP = [
  { id: "insight", cost: 80, name: "Path Insight", text: "Start the next run with +24 attainment in a path you used most." },
  { id: "cache", cost: 60, name: "Stone Cache", text: "+30 starting stones, forever stacked." },
  { id: "years", cost: 90, name: "Lifespan Seed", text: "+2 years of lifespan on future runs." },
  { id: "reroll", cost: 100, name: "Second Reading", text: "You may reroll aptitude once during creation." },
  { id: "formula", cost: 70, name: "Gu Formula", text: "A formula you found is written into the family record." },
  { id: "relic", cost: 140, name: "Heirloom", text: "Choose a common or uncommon treasure to start with." },
  { id: "plains", cost: 150, name: "Northern Plains Map", text: "Unlock the Huang Jin and Hei Lou tribes." },
  { id: "central", cost: 150, name: "Central Continent Seal", text: "Unlock the Heavenly Sword and Profound Mystery sects." },
  { id: "wu", cost: 120, name: "Wu Clan Record", text: "Unlock the Wu Clan." },
  { id: "chi", cost: 120, name: "Chi Clan Record", text: "Unlock the Chi Clan." },
  { id: "connection", cost: 70, name: "Old Friend", text: "Healer Qing begins the next run already fond of you." },
];
