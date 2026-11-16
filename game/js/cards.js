/** Gu cards, paths, killer moves, and attainment rules. */

export const PATHS = {
  strength: { id: "strength", name: "Strength", symbol: "Fist", color: "#c23b22", ink: "#d57867", glyph: "#c23b22", icon: "fist", engine: "Combo. Later attacks in a turn hit harder." },
  wisdom: { id: "wisdom", name: "Wisdom", symbol: "Eye", color: "#3d7ec9", ink: "#5e94d2", glyph: "#3b7ac3", icon: "brain", engine: "Draw, reveal, and set up a bigger hand." },
  blood: { id: "blood", name: "Blood", symbol: "Drop", color: "#8e1e2d", ink: "#bf7f87", glyph: "#8e1e2d", icon: "drop", engine: "Spend life, steal it back, and spike when wounded." },
  refinement: { id: "refinement", name: "Refinement", symbol: "Anvil", color: "#b87333", ink: "#c1844b", glyph: "#a7692e", icon: "anvil", engine: "Forge temporary Gu and empower the hand." },
  transformation: { id: "transformation", name: "Transformation", symbol: "Form", color: "#1f8a86", ink: "#459e9b", glyph: "#1e8481", icon: "yin-yang", engine: "Change form. Attacks gain bleed, poison, or thorns." },
  enslavement: { id: "enslavement", name: "Enslavement", symbol: "Chain", color: "#7a4ea3", ink: "#a385c0", glyph: "#7a4ea3", icon: "chains", engine: "Summon beasts that strike every turn." },
  poison: { id: "poison", name: "Poison", symbol: "Venom", color: "#6a8f3a", ink: "#7a9b50", glyph: "#608235", icon: "poison", engine: "Stack poison, then cash it in." },
  dark: { id: "dark", name: "Dark", symbol: "Moon", color: "#3c3a72", ink: "#908faf", glyph: "#3c3a72", icon: "eclipse", engine: "Stealth, then execute wounded foes." },
  light: { id: "light", name: "Light", symbol: "Sun", color: "#d4a24c", ink: "#d4a24c", glyph: "#947135", icon: "sun", engine: "Stack block, cleanse, then turn block into a blow." },
  food: { id: "food", name: "Food", symbol: "Feast", color: "#c47b2b", ink: "#c78236", glyph: "#a76925", icon: "meal", engine: "Heal, regenerate, and turn kills into stones." },
  mortal: { id: "mortal", name: "Mortal", symbol: "Breath", color: "#8a8175", ink: "#989086", glyph: "#7f776c", icon: "body", engine: "Plain techniques. They ignore attainment limits." },
};

export const PATH_ORDER = ["strength", "wisdom", "blood", "refinement", "transformation", "enslavement", "poison", "dark", "light", "food"];

export const STAGES = ["Initial", "Middle", "Upper", "Peak"];

export const RANK_TITLES = {
  1: "Rank 1 Gu Master",
  2: "Rank 2 Gu Master",
  3: "Rank 3 Gu Master",
  4: "Rank 4 Gu Master",
  5: "Rank 5 Gu Master",
  6: "Rank 6 Gu Immortal",
  7: "Rank 7 Gu Immortal",
  8: "Rank 8 Gu Immortal",
  9: "Rank 9 Venerable",
};

export const ESSENCE_COLORS = {
  1: "#7d9a6a",
  2: "#a64b3c",
  3: "#d9d3c7",
  4: "#e0b15a",
  5: "#9a78c4",
  6: "#7ec8c3",
  7: "#7ec8c3",
  8: "#f0e2b6",
  9: "#f0e2b6",
};

/** Compressed attainment curve so a focused run reaches Master before the calamity. */
export const ATTAIN = { adept: 30, expert: 80, master: 140, grand: 220 };

export function attainmentTier(v) {
  if (v >= ATTAIN.grand) return "Grandmaster";
  if (v >= ATTAIN.master) return "Master";
  if (v >= ATTAIN.expert) return "Expert";
  if (v >= ATTAIN.adept) return "Adept";
  return "Ordinary";
}

export function pathCap(v) {
  if (v >= ATTAIN.master) return 8;
  if (v >= ATTAIN.expert) return 5;
  if (v >= ATTAIN.adept) return 4;
  return 3;
}

export function pathPower(v) {
  if (v >= ATTAIN.grand) return 0.4;
  if (v >= ATTAIN.master) return 0.3;
  if (v >= ATTAIN.expert) return 0.2;
  if (v >= ATTAIN.adept) return 0.1;
  return 0;
}

const CARDS = {};

function add(c) {
  c.tags = c.tags || [];
  c.effects = c.effects || [];
  c.pool = c.pool || "reward";
  c.icon = c.icon || (PATHS[c.path] ? PATHS[c.path].icon : "scroll");
  CARDS[c.id] = c;
}

// --- Mortal -----------------------------------------------------------------
add({ id: "primeval_bolt", name: "Primeval Bolt Gu", rank: 1, path: "mortal", type: "Offensive", rarity: "Common", cost: 1, icon: "lightning", tags: ["attack"], text: "Deal 6 damage.", textUp: "Deal 9 damage.", effects: [{ op: "damage", n: 6 }], plus: 3 });
add({ id: "steady_breath", name: "Steady Breath Gu", rank: 1, path: "mortal", type: "Defensive", rarity: "Common", cost: 1, icon: "body", tags: ["block"], text: "Gain 5 Block.", textUp: "Gain 8 Block.", effects: [{ op: "block", n: 5 }], plus: 3 });
add({ id: "mend", name: "Mend Gu", rank: 1, path: "mortal", type: "Defensive", rarity: "Common", cost: 1, icon: "heart", tags: [], text: "Heal 5. Exhaust.", textUp: "Heal 8. Exhaust.", effects: [{ op: "heal", n: 5 }], exhaust: true, plus: 3 });
add({ id: "desperate_lunge", name: "Desperate Lunge Gu", rank: 1, path: "mortal", type: "Offensive", rarity: "Common", cost: 0, icon: "dagger", tags: ["attack"], text: "Lose 2 HP. Deal 8 damage.", textUp: "Lose 2 HP. Deal 11 damage.", effects: [{ op: "loseHp", n: 2 }, { op: "damage", n: 8 }], plus: 3 });
add({ id: "swift_steps", name: "Swift Steps Gu", rank: 1, path: "mortal", type: "Utility", rarity: "Uncommon", cost: 1, icon: "boot", tags: ["movement", "block"], text: "Gain 4 Block. Draw 1.", textUp: "Gain 6 Block. Draw 2.", aperture: "While equipped, travel takes 25% fewer days.", effects: [{ op: "block", n: 4 }, { op: "draw", n: 1 }], effectsUp: [{ op: "block", n: 6 }, { op: "draw", n: 2 }] });
add({ id: "gale_stride", name: "Gale Stride Gu", rank: 2, path: "light", type: "Utility", rarity: "Uncommon", cost: 1, icon: "feather", tags: ["movement", "block"], text: "Gain 6 Block. Draw 1.", textUp: "Gain 9 Block. Draw 1.", aperture: "While equipped, travel takes 45% fewer days.", effects: [{ op: "block", n: 6 }, { op: "draw", n: 1 }], plus: 3 });

// --- Strength ---------------------------------------------------------------
add({ id: "iron_fist", name: "Iron Fist Gu", rank: 1, path: "strength", type: "Offensive", rarity: "Common", cost: 1, icon: "fist", tags: ["attack"], text: "Deal 5 damage. +3 for each attack you already played this turn.", textUp: "Deal 8 damage. +3 for each attack you already played this turn.", effects: [{ op: "combo", base: 5, step: 3 }], effectsUp: [{ op: "combo", base: 8, step: 3 }] });
add({ id: "rising_blow", name: "Rising Blow Gu", rank: 1, path: "strength", type: "Offensive", rarity: "Common", cost: 1, icon: "punch", tags: ["attack"], text: "Deal 8 damage. Gain 1 Strength this combat.", textUp: "Deal 11 damage. Gain 2 Strength this combat.", effects: [{ op: "damage", n: 8 }, { op: "strength", n: 1 }], effectsUp: [{ op: "damage", n: 11 }, { op: "strength", n: 2 }] });
add({ id: "body_harden", name: "Body Harden Gu", rank: 1, path: "strength", type: "Defensive", rarity: "Common", cost: 1, icon: "muscle", tags: ["block"], text: "Gain 6 Block. If you already attacked this turn, gain 3 more.", textUp: "Gain 9 Block. If you already attacked this turn, gain 3 more.", effects: [{ op: "block", n: 6 }, { op: "blockIfAttacked", n: 3 }], effectsUp: [{ op: "block", n: 9 }, { op: "blockIfAttacked", n: 3 }] });
add({ id: "war_cry", name: "War Cry Gu", rank: 2, path: "strength", type: "Utility", rarity: "Uncommon", cost: 1, icon: "muscle", tags: [], text: "Gain 2 Strength. Draw 1. Exhaust.", textUp: "Gain 3 Strength. Draw 1. Exhaust.", effects: [{ op: "strength", n: 2 }, { op: "draw", n: 1 }], effectsUp: [{ op: "strength", n: 3 }, { op: "draw", n: 1 }], exhaust: true });
add({ id: "crushing_palm", name: "Crushing Palm Gu", rank: 2, path: "strength", type: "Offensive", rarity: "Uncommon", cost: 2, icon: "punch", tags: ["attack"], text: "Deal 10 damage. +6 for each attack you already played this turn.", textUp: "Deal 13 damage. +6 for each attack you already played this turn.", effects: [{ op: "combo", base: 10, step: 6 }], effectsUp: [{ op: "combo", base: 13, step: 6 }] });
add({ id: "titan_grip", name: "Titan Grip Gu", rank: 3, path: "strength", type: "Offensive", rarity: "Rare", cost: 2, icon: "mailed-fist", tags: ["attack"], text: "Deal 16 damage. Apply 2 Vulnerable.", textUp: "Deal 20 damage. Apply 2 Vulnerable.", effects: [{ op: "damage", n: 16 }, { op: "vulnerable", n: 2 }], plus: 4 });
add({ id: "bone_blade", name: "Bone Blade Gu", rank: 1, path: "strength", type: "Offensive", rarity: "Uncommon", cost: 1, icon: "bone", tags: ["attack"], clan: "bai", text: "Deal 9 damage. Apply 2 Bleed.", textUp: "Deal 12 damage. Apply 3 Bleed.", effects: [{ op: "damage", n: 9 }, { op: "bleed", n: 2 }], effectsUp: [{ op: "damage", n: 12 }, { op: "bleed", n: 3 }] });
add({ id: "bear_strength", name: "Bear Strength Gu", rank: 2, path: "strength", type: "Utility", rarity: "Uncommon", cost: 1, icon: "bear", tags: [], clan: "xiong", text: "Gain 2 Strength and 4 Block.", textUp: "Gain 3 Strength and 6 Block.", effects: [{ op: "strength", n: 2 }, { op: "block", n: 4 }], effectsUp: [{ op: "strength", n: 3 }, { op: "block", n: 6 }] });
add({ id: "flame_fist", name: "Flame Fist Gu", rank: 2, path: "strength", type: "Offensive", rarity: "Uncommon", cost: 1, icon: "fire-punch", tags: ["attack", "fire"], clan: "chi", text: "Deal 7 damage. Apply 3 Burn.", textUp: "Deal 10 damage. Apply 4 Burn.", effects: [{ op: "damage", n: 7 }, { op: "burn", n: 3 }], effectsUp: [{ op: "damage", n: 10 }, { op: "burn", n: 4 }] });

// --- Blood ------------------------------------------------------------------
add({ id: "blood_frenzy", name: "Blood Frenzy Gu", rank: 1, path: "blood", type: "Offensive", rarity: "Common", cost: 1, hpCost: 3, icon: "drop", tags: ["attack"], text: "Lose 3 HP. Deal 10 damage, or 15 if you are below half HP.", textUp: "Lose 3 HP. Deal 13 damage, or 18 if you are below half HP.", effects: [{ op: "lowHp", normal: 10, low: 15, pct: 50 }], effectsUp: [{ op: "lowHp", normal: 13, low: 18, pct: 50 }] });
add({ id: "vampiric_touch", name: "Blood Siphon Gu", rank: 1, path: "blood", type: "Offensive", rarity: "Common", cost: 1, icon: "fangs", tags: ["attack"], text: "Deal 7 damage. Heal for the damage dealt.", textUp: "Deal 10 damage. Heal for the damage dealt.", effects: [{ op: "damage", n: 7, steal: 1 }], plus: 3 });
add({ id: "open_vein", name: "Open Vein Gu", rank: 1, path: "blood", type: "Utility", rarity: "Uncommon", cost: 0, hpCost: 4, icon: "bleeding-heart", tags: [], text: "Lose 4 HP. Gain 2 Essence. Exhaust.", textUp: "Lose 4 HP. Gain 3 Essence. Exhaust.", effects: [{ op: "energy", n: 2 }], effectsUp: [{ op: "energy", n: 3 }], exhaust: true });
add({ id: "hemorrhage", name: "Hemorrhage Gu", rank: 2, path: "blood", type: "Offensive", rarity: "Uncommon", cost: 1, icon: "internal-injury", tags: ["attack"], text: "Deal 6 damage. Apply 4 Bleed.", textUp: "Deal 8 damage. Apply 5 Bleed.", effects: [{ op: "damage", n: 6 }, { op: "bleed", n: 4 }], effectsUp: [{ op: "damage", n: 8 }, { op: "bleed", n: 5 }] });
add({ id: "blood_bond", name: "Blood Bond Gu", rank: 2, path: "blood", type: "Utility", rarity: "Uncommon", cost: 1, icon: "heart", tags: [], text: "Heal 6. For the rest of combat, your attacks heal you for 3.", textUp: "Heal 9. For the rest of combat, your attacks heal you for 4.", effects: [{ op: "heal", n: 6 }, { op: "power", key: "lifelink", n: 3 }], effectsUp: [{ op: "heal", n: 9 }, { op: "power", key: "lifelink", n: 4 }] });
add({ id: "sanguine_end", name: "Sanguine End Gu", rank: 3, path: "blood", type: "Offensive", rarity: "Rare", cost: 2, hpCost: 5, icon: "drop", tags: ["attack"], text: "Lose 5 HP. Deal 8 damage + 1 for every missing HP (max 28).", textUp: "Lose 5 HP. Deal 10 damage + 1 for every missing HP (max 34).", effects: [{ op: "missingHp", base: 8, per: 1, cap: 28 }], effectsUp: [{ op: "missingHp", base: 10, per: 1, cap: 34 }] });

// --- Poison -----------------------------------------------------------------
add({ id: "venom_bite", name: "Venom Bite Gu", rank: 1, path: "poison", type: "Offensive", rarity: "Common", cost: 1, icon: "fangs", tags: ["attack"], text: "Deal 4 damage. Apply 3 Poison.", textUp: "Deal 6 damage. Apply 4 Poison.", effects: [{ op: "damage", n: 4 }, { op: "poison", n: 3 }], effectsUp: [{ op: "damage", n: 6 }, { op: "poison", n: 4 }] });
add({ id: "creeping_rot", name: "Creeping Rot Gu", rank: 1, path: "poison", type: "Utility", rarity: "Common", cost: 1, icon: "virus", tags: [], text: "Apply 4 Poison.", textUp: "Apply 6 Poison.", effects: [{ op: "poison", n: 4 }], plus: 2 });
add({ id: "plague_spread", name: "Plague Spread Gu", rank: 2, path: "poison", type: "Utility", rarity: "Uncommon", cost: 1, icon: "spider", tags: [], text: "Double the target's Poison.", textUp: "Double the target's Poison, then apply 2 more.", effects: [{ op: "doublePoison" }], effectsUp: [{ op: "doublePoison" }, { op: "poison", n: 2 }] });
add({ id: "corrosive_pool", name: "Corrosive Pool Gu", rank: 2, path: "poison", type: "Offensive", rarity: "Uncommon", cost: 1, icon: "poison", tags: ["attack"], text: "Deal damage equal to the target's Poison.", textUp: "Deal damage equal to the target's Poison + 4.", effects: [{ op: "poisonPay", per: 1, flat: 0 }], effectsUp: [{ op: "poisonPay", per: 1, flat: 4 }] });
add({ id: "wither", name: "Wither Gu", rank: 2, path: "poison", type: "Utility", rarity: "Uncommon", cost: 1, icon: "claw", tags: [], text: "Apply 2 Vulnerable and 2 Poison.", textUp: "Apply 2 Vulnerable and 4 Poison.", effects: [{ op: "vulnerable", n: 2 }, { op: "poison", n: 2 }], effectsUp: [{ op: "vulnerable", n: 2 }, { op: "poison", n: 4 }] });
add({ id: "epidemic", name: "Epidemic Gu", rank: 3, path: "poison", type: "Offensive", rarity: "Rare", cost: 2, icon: "spider-face", tags: ["attack"], text: "Deal 6 damage to all enemies and apply 3 Poison to each.", textUp: "Deal 9 damage to all enemies and apply 4 Poison to each.", effects: [{ op: "damageAll", n: 6 }, { op: "poisonAll", n: 3 }], effectsUp: [{ op: "damageAll", n: 9 }, { op: "poisonAll", n: 4 }] });

// --- Light ------------------------------------------------------------------
add({ id: "crescent_ward", name: "Crescent Ward Gu", rank: 1, path: "light", type: "Defensive", rarity: "Common", cost: 1, icon: "shield", tags: ["block", "moon"], text: "Gain 7 Block.", textUp: "Gain 10 Block.", effects: [{ op: "block", n: 7 }], plus: 3 });
add({ id: "moonlit_strike", name: "Moonlit Strike Gu", rank: 1, path: "light", type: "Offensive", rarity: "Common", cost: 1, icon: "moon", tags: ["attack", "moon"], text: "Deal 7 damage. At night, deal 10 instead.", textUp: "Deal 9 damage. At night, deal 13 instead.", effects: [{ op: "nightStrike", day: 7, night: 10 }], effectsUp: [{ op: "nightStrike", day: 9, night: 13 }] });
add({ id: "purifying_light", name: "Purifying Light Gu", rank: 1, path: "light", type: "Utility", rarity: "Uncommon", cost: 1, icon: "sun", tags: [], text: "Cleanse yourself. Heal 3 for each stack removed.", textUp: "Cleanse yourself. Heal 5 for each stack removed.", effects: [{ op: "cleanse", per: 3 }], effectsUp: [{ op: "cleanse", per: 5 }] });
add({ id: "light_shield", name: "Light Shield Gu", rank: 2, path: "light", type: "Defensive", rarity: "Uncommon", cost: 2, icon: "shield-reflect", tags: ["block"], text: "Gain 13 Block. Retain.", textUp: "Gain 16 Block. Retain.", effects: [{ op: "block", n: 13 }], plus: 3, retain: true });
add({ id: "shield_burst", name: "Shield Burst Gu", rank: 2, path: "light", type: "Offensive", rarity: "Uncommon", cost: 1, icon: "sun", tags: ["attack"], text: "Deal damage equal to your Block, then lose all Block.", textUp: "Deal damage equal to your Block + 5, then lose all Block.", effects: [{ op: "shieldBurst", flat: 0 }], effectsUp: [{ op: "shieldBurst", flat: 5 }] });
add({ id: "moonlight_blade", name: "Moonlight Gu", rank: 1, path: "light", type: "Offensive", rarity: "Uncommon", cost: 1, icon: "winged-sword", tags: ["attack", "moon"], clan: "guyue", text: "Deal 8 damage. At night, gain 4 Block.", textUp: "Deal 11 damage. At night, gain 6 Block.", effects: [{ op: "damage", n: 8 }, { op: "nightBlock", n: 4 }], effectsUp: [{ op: "damage", n: 11 }, { op: "nightBlock", n: 6 }] });
add({ id: "full_moon", name: "Full Moon Gu", rank: 3, path: "light", type: "Offensive", rarity: "Rare", cost: 2, icon: "moon", tags: ["attack", "moon"], clan: "guyue", text: "Deal 11 damage to all enemies. At night, deal 16 instead.", textUp: "Deal 14 damage to all enemies. At night, deal 20 instead.", effects: [{ op: "nightAll", day: 11, night: 16 }], effectsUp: [{ op: "nightAll", day: 14, night: 20 }] });

// --- Dark -------------------------------------------------------------------
add({ id: "shadow_cloak", name: "Shadow Cloak Gu", rank: 1, path: "dark", type: "Utility", rarity: "Common", cost: 1, icon: "hood", tags: [], text: "Your next attack deals +8. The next enemy attack has a 50% chance to miss.", textUp: "Your next attack deals +11. The next enemy attack has a 50% chance to miss.", effects: [{ op: "stealth", n: 8 }], plus: 3 });
add({ id: "shadow_dagger", name: "Shadow Dagger Gu", rank: 1, path: "dark", type: "Offensive", rarity: "Common", cost: 1, icon: "dagger", tags: ["attack"], text: "Deal 7 damage. If you are hidden, deal 13 instead.", textUp: "Deal 9 damage. If you are hidden, deal 16 instead.", effects: [{ op: "stealthStrike", open: 7, hidden: 13 }], effectsUp: [{ op: "stealthStrike", open: 9, hidden: 16 }] });
add({ id: "throat_slit", name: "Throat Slit Gu", rank: 2, path: "dark", type: "Offensive", rarity: "Uncommon", cost: 1, icon: "dagger", tags: ["attack"], text: "Deal 7 damage. If the target is below 30% HP, deal 16 instead.", textUp: "Deal 9 damage. If the target is below 30% HP, deal 20 instead.", effects: [{ op: "execute", base: 7, bonus: 9, below: 30 }], effectsUp: [{ op: "execute", base: 9, bonus: 11, below: 30 }] });
add({ id: "smoke_step", name: "Smoke Step Gu", rank: 1, path: "dark", type: "Defensive", rarity: "Common", cost: 1, icon: "hidden", tags: ["block", "movement"], text: "Gain 5 Block. Draw 1.", textUp: "Gain 8 Block. Draw 1.", aperture: "Counts as a movement Gu for escape.", effects: [{ op: "block", n: 5 }, { op: "draw", n: 1 }], plus: 3 });
add({ id: "night_ambush", name: "Night Ambush Gu", rank: 2, path: "dark", type: "Offensive", rarity: "Uncommon", cost: 2, icon: "ninja", tags: ["attack"], text: "Deal 14 damage. If you are hidden, apply 2 Weak.", textUp: "Deal 18 damage. If you are hidden, apply 2 Weak.", effects: [{ op: "damage", n: 14 }, { op: "weakIfHidden", n: 2 }], plus: 4 });
add({ id: "assassinate", name: "Assassinate Gu", rank: 3, path: "dark", type: "Offensive", rarity: "Rare", cost: 2, icon: "hood", tags: ["attack"], text: "Deal 12 damage. If the target is below 30% HP, deal 28 instead.", textUp: "Deal 14 damage. If the target is below 30% HP, deal 34 instead.", effects: [{ op: "execute", base: 12, bonus: 16, below: 30 }], effectsUp: [{ op: "execute", base: 14, bonus: 20, below: 30 }] });

// --- Wisdom -----------------------------------------------------------------
add({ id: "insight", name: "Insight Gu", rank: 1, path: "wisdom", type: "Utility", rarity: "Common", cost: 1, icon: "eye", tags: [], text: "Draw 2 cards.", textUp: "Draw 3 cards.", effects: [{ op: "draw", n: 2 }], effectsUp: [{ op: "draw", n: 3 }] });
add({ id: "calculated_strike", name: "Calculated Strike Gu", rank: 1, path: "wisdom", type: "Offensive", rarity: "Common", cost: 1, icon: "brain", tags: ["attack"], text: "Deal 4 damage for each card in your hand.", textUp: "Deal 5 damage for each card in your hand.", effects: [{ op: "damagePerHand", n: 4 }], effectsUp: [{ op: "damagePerHand", n: 5 }] });
add({ id: "deduction", name: "Deduction Gu", rank: 2, path: "wisdom", type: "Utility", rarity: "Uncommon", cost: 1, icon: "book", tags: [], text: "Reveal the enemy pattern. Apply 1 Weak. Draw 1.", textUp: "Reveal the enemy pattern. Apply 2 Weak. Draw 1.", effects: [{ op: "reveal" }, { op: "weak", n: 1 }, { op: "draw", n: 1 }], effectsUp: [{ op: "reveal" }, { op: "weak", n: 2 }, { op: "draw", n: 1 }] });
add({ id: "memory_palace", name: "Memory Palace Gu", rank: 2, path: "wisdom", type: "Utility", rarity: "Uncommon", cost: 1, icon: "book", tags: [], text: "Gain 1 Essence. Draw 1. Exhaust.", textUp: "Gain 2 Essence. Draw 2. Exhaust.", effects: [{ op: "energy", n: 1 }, { op: "draw", n: 1 }], effectsUp: [{ op: "energy", n: 2 }, { op: "draw", n: 2 }], exhaust: true });
add({ id: "foresight", name: "Foresight Gu", rank: 1, path: "wisdom", type: "Utility", rarity: "Uncommon", cost: 0, icon: "eye", tags: [], text: "Retain. At the start of your next turn, draw 1.", textUp: "Retain. At the start of your next turn, draw 2.", effects: [{ op: "nextDraw", n: 1 }], effectsUp: [{ op: "nextDraw", n: 2 }], retain: true });
add({ id: "strategic_mind", name: "Strategic Mind Gu", rank: 2, path: "wisdom", type: "Utility", rarity: "Rare", cost: 1, icon: "quill", tags: [], text: "Draw 2. Gain 5 Block.", textUp: "Draw 3. Gain 7 Block.", effects: [{ op: "draw", n: 2 }, { op: "block", n: 5 }], effectsUp: [{ op: "draw", n: 3 }, { op: "block", n: 7 }] });
add({ id: "information_network", name: "Information Network Gu", rank: 2, path: "wisdom", type: "Utility", rarity: "Uncommon", cost: 1, icon: "scroll", tags: [], clan: "shang", text: "Reveal the enemy pattern. Gain 10 stones.", textUp: "Reveal the enemy pattern. Gain 16 stones.", aperture: "Shops are 10% cheaper while this is equipped.", effects: [{ op: "reveal" }, { op: "gainStones", n: 10 }], effectsUp: [{ op: "reveal" }, { op: "gainStones", n: 16 }] });

// --- Refinement -------------------------------------------------------------
add({ id: "enhance", name: "Enhance Gu", rank: 1, path: "refinement", type: "Utility", rarity: "Common", cost: 1, icon: "upgrade", tags: [], target: "hand", text: "A card in your hand costs 1 less this combat.", textUp: "A card in your hand costs 1 less and is empowered (+3) this combat.", effects: [{ op: "costDown", n: 1 }], effectsUp: [{ op: "costDown", n: 1 }, { op: "empower", n: 3 }] });
add({ id: "forge_blade", name: "Forge Blade Gu", rank: 1, path: "refinement", type: "Utility", rarity: "Common", cost: 1, icon: "anvil", tags: [], text: "Add a Forged Edge Gu to your hand. Exhaust.", textUp: "Add two Forged Edge Gu to your hand. Exhaust.", effects: [{ op: "addCard", id: "forged_edge", dest: "hand" }], effectsUp: [{ op: "addCard", id: "forged_edge", dest: "hand" }, { op: "addCard", id: "forged_edge", dest: "hand" }], exhaust: true });
add({ id: "deconstruct", name: "Deconstruct Gu", rank: 2, path: "refinement", type: "Utility", rarity: "Uncommon", cost: 1, icon: "anvil", tags: [], text: "Remove all Block from the target. It loses 2 Strength. Deal 6 damage.", textUp: "Remove all Block from the target. It loses 3 Strength. Deal 9 damage.", effects: [{ op: "stripBlock" }, { op: "strengthDown", n: 2 }, { op: "damage", n: 6 }], effectsUp: [{ op: "stripBlock" }, { op: "strengthDown", n: 3 }, { op: "damage", n: 9 }] });
add({ id: "repair", name: "Tempering Gu", rank: 2, path: "refinement", type: "Utility", rarity: "Uncommon", cost: 1, icon: "anvil", tags: [], target: "hand", text: "Empower a card in your hand by +4 this combat.", textUp: "Empower a card in your hand by +6 this combat.", effects: [{ op: "empower", n: 4 }], effectsUp: [{ op: "empower", n: 6 }] });
add({ id: "masterwork", name: "Masterwork Gu", rank: 3, path: "refinement", type: "Offensive", rarity: "Rare", cost: 2, icon: "gems", tags: ["attack"], text: "Deal 12 damage. Add a Forged Edge Gu to your hand.", textUp: "Deal 16 damage. Add a Forged Edge Gu to your hand.", effects: [{ op: "damage", n: 12 }, { op: "addCard", id: "forged_edge", dest: "hand" }], plus: 4 });
add({ id: "forged_edge", name: "Forged Edge Gu", rank: 1, path: "refinement", type: "Offensive", rarity: "Common", cost: 0, icon: "swords", tags: ["attack"], pool: "token", noUpgrade: true, text: "Deal 10 damage. Exhaust.", effects: [{ op: "damage", n: 10 }], exhaust: true, temp: true });

// --- Transformation ---------------------------------------------------------
add({ id: "wolf_form", name: "Wolf Form Gu", rank: 1, path: "transformation", type: "Utility", rarity: "Common", cost: 1, icon: "wolf", tags: [], text: "For 3 turns, your attacks deal +3 and apply 2 Bleed.", textUp: "For 4 turns, your attacks deal +4 and apply 2 Bleed.", effects: [{ op: "power", key: "wolf", turns: 3, n: 3 }], effectsUp: [{ op: "power", key: "wolf", turns: 4, n: 4 }] });
add({ id: "mirror_scale", name: "Mirror Scale Gu", rank: 1, path: "transformation", type: "Defensive", rarity: "Common", cost: 1, icon: "shield", tags: ["block"], text: "Gain 6 Block. Gain 3 Thorns.", textUp: "Gain 9 Block. Gain 4 Thorns.", effects: [{ op: "block", n: 6 }, { op: "thorns", n: 3 }], effectsUp: [{ op: "block", n: 9 }, { op: "thorns", n: 4 }] });
add({ id: "mimic_strike", name: "Mimic Strike Gu", rank: 2, path: "transformation", type: "Offensive", rarity: "Uncommon", cost: 1, icon: "cycle", tags: ["attack"], text: "Deal 8 damage. Apply a random debuff (Weak, Vulnerable, or Poison).", textUp: "Deal 11 damage. Apply a random debuff (Weak, Vulnerable, or Poison).", effects: [{ op: "damage", n: 8 }, { op: "randomDebuff" }], plus: 3 });
add({ id: "hybrid_shell", name: "Hybrid Shell Gu", rank: 2, path: "transformation", type: "Defensive", rarity: "Uncommon", cost: 1, icon: "yin-yang", tags: ["block"], text: "Gain 5 Block and 1 Strength.", textUp: "Gain 8 Block and 2 Strength.", effects: [{ op: "block", n: 5 }, { op: "strength", n: 1 }], effectsUp: [{ op: "block", n: 8 }, { op: "strength", n: 2 }] });
add({ id: "serpent_form", name: "Serpent Form Gu", rank: 2, path: "transformation", type: "Utility", rarity: "Rare", cost: 2, icon: "snake", tags: [], text: "For the rest of combat, your attacks apply 2 Poison.", textUp: "For the rest of combat, your attacks apply 3 Poison.", effects: [{ op: "power", key: "serpent", turns: 99, n: 2 }], effectsUp: [{ op: "power", key: "serpent", turns: 99, n: 3 }] });
add({ id: "white_bone", name: "White Bone Gu", rank: 3, path: "transformation", type: "Utility", rarity: "Rare", cost: 2, icon: "skull", tags: [], clan: "bai", text: "Gain 3 Strength and 3 Thorns. Lose 6 HP.", textUp: "Gain 4 Strength and 4 Thorns. Lose 6 HP.", effects: [{ op: "loseHp", n: 6 }, { op: "strength", n: 3 }, { op: "thorns", n: 3 }], effectsUp: [{ op: "loseHp", n: 6 }, { op: "strength", n: 4 }, { op: "thorns", n: 4 }] });

// --- Enslavement ------------------------------------------------------------
add({ id: "beast_contract", name: "Beast Contract Gu", rank: 1, path: "enslavement", type: "Utility", rarity: "Common", cost: 1, icon: "paw", tags: ["summon"], text: "Summon a wolf that deals 5 damage at the end of your turn, for 4 turns.", textUp: "Summon a wolf that deals 7 damage at the end of your turn, for 4 turns.", effects: [{ op: "summon", name: "Contract Wolf", dmg: 5, turns: 4, icon: "wolf" }], effectsUp: [{ op: "summon", name: "Contract Wolf", dmg: 7, turns: 4, icon: "wolf" }] });
add({ id: "puppet_jab", name: "Puppet Strike Gu", rank: 1, path: "enslavement", type: "Offensive", rarity: "Common", cost: 1, icon: "chains", tags: ["attack"], text: "Deal 6 damage. If you have a summon, deal 11 instead.", textUp: "Deal 8 damage. If you have a summon, deal 14 instead.", effects: [{ op: "summonStrike", solo: 6, pack: 11 }], effectsUp: [{ op: "summonStrike", solo: 8, pack: 14 }] });
add({ id: "mind_shackle", name: "Mind Shackle Gu", rank: 2, path: "enslavement", type: "Utility", rarity: "Uncommon", cost: 2, icon: "chains", tags: [], text: "The target's next attack hits itself.", textUp: "The target's next attack hits itself. Apply 1 Weak.", effects: [{ op: "shackle" }], effectsUp: [{ op: "shackle" }, { op: "weak", n: 1 }] });
add({ id: "dominating_presence", name: "Dominating Presence Gu", rank: 2, path: "enslavement", type: "Utility", rarity: "Uncommon", cost: 1, icon: "crown", tags: [], text: "Apply 2 Weak to all enemies. Gain 1 Strength.", textUp: "Apply 2 Weak to all enemies. Gain 2 Strength.", effects: [{ op: "weakAll", n: 2 }, { op: "strength", n: 1 }], effectsUp: [{ op: "weakAll", n: 2 }, { op: "strength", n: 2 }] });
add({ id: "soul_contract", name: "Soul Contract Gu", rank: 2, path: "enslavement", type: "Utility", rarity: "Rare", cost: 1, icon: "scroll", tags: ["summon"], clan: "shang", text: "Your summons deal +3 damage for the rest of combat. Summon a servant (4 damage, 4 turns).", textUp: "Your summons deal +4 damage for the rest of combat. Summon a servant (5 damage, 4 turns).", effects: [{ op: "power", key: "summonBoost", n: 3, turns: 99 }, { op: "summon", name: "Soul Servant", dmg: 4, turns: 4, icon: "ghost" }], effectsUp: [{ op: "power", key: "summonBoost", n: 4, turns: 99 }, { op: "summon", name: "Soul Servant", dmg: 5, turns: 4, icon: "ghost" }] });
add({ id: "suggestion", name: "Suggestion Gu", rank: 1, path: "enslavement", type: "Utility", rarity: "Common", cost: 1, icon: "conversation", tags: [], clan: "shang", text: "Apply 2 Weak. Draw 1.", textUp: "Apply 2 Weak. Draw 2.", effects: [{ op: "weak", n: 2 }, { op: "draw", n: 1 }], effectsUp: [{ op: "weak", n: 2 }, { op: "draw", n: 2 }] });
add({ id: "chain_lash", name: "Chain Lash Gu", rank: 2, path: "enslavement", type: "Offensive", rarity: "Uncommon", cost: 1, icon: "chains", tags: ["attack"], text: "Deal 5 damage to all enemies.", textUp: "Deal 8 damage to all enemies.", effects: [{ op: "damageAll", n: 5 }], plus: 3 });

// --- Food -------------------------------------------------------------------
add({ id: "hearty_bite", name: "Hearty Bite Gu", rank: 1, path: "food", type: "Defensive", rarity: "Common", cost: 1, icon: "meat", tags: [], text: "Heal 7.", textUp: "Heal 10.", effects: [{ op: "heal", n: 7 }], plus: 3 });
add({ id: "nourishing_aura", name: "Nourishing Aura Gu", rank: 1, path: "food", type: "Utility", rarity: "Common", cost: 1, icon: "cooking", tags: [], text: "Gain 3 Regeneration.", textUp: "Gain 4 Regeneration.", effects: [{ op: "regen", n: 3 }], plus: 1 });
add({ id: "devouring_maw", name: "Devouring Maw Gu", rank: 2, path: "food", type: "Offensive", rarity: "Uncommon", cost: 1, icon: "fangs", tags: ["attack"], text: "Deal 9 damage. If this kills, gain 18 stones.", textUp: "Deal 13 damage. If this kills, gain 24 stones.", effects: [{ op: "damage", n: 9, bounty: 18 }], effectsUp: [{ op: "damage", n: 13, bounty: 24 }] });
add({ id: "feast", name: "Feast Gu", rank: 2, path: "food", type: "Utility", rarity: "Uncommon", cost: 1, icon: "meal", tags: [], target: "hand", text: "Exhaust another card in your hand. Heal 8. Draw 1.", textUp: "Exhaust another card in your hand. Heal 12. Draw 1.", effects: [{ op: "exhaustOther" }, { op: "heal", n: 8 }, { op: "draw", n: 1 }], effectsUp: [{ op: "exhaustOther" }, { op: "heal", n: 12 }, { op: "draw", n: 1 }] });
add({ id: "primeval_brew", name: "Liquor Worm", rank: 1, path: "food", type: "Utility", rarity: "Uncommon", cost: 0, icon: "potion", tags: [], text: "Gain 2 Essence. Exhaust.", textUp: "Gain 3 Essence. Exhaust.", effects: [{ op: "energy", n: 2 }], effectsUp: [{ op: "energy", n: 3 }], exhaust: true });
add({ id: "glutton_might", name: "Glutton Might Gu", rank: 2, path: "food", type: "Utility", rarity: "Rare", cost: 2, icon: "meal", tags: [], text: "Heal 6. Gain 3 Strength.", textUp: "Heal 8. Gain 4 Strength.", effects: [{ op: "heal", n: 6 }, { op: "strength", n: 3 }], effectsUp: [{ op: "heal", n: 8 }, { op: "strength", n: 4 }] });
add({ id: "stone_harvest", name: "Stone Harvest Gu", rank: 1, path: "food", type: "Economic", rarity: "Uncommon", cost: 1, icon: "coins", tags: [], text: "Gain 14 stones. Exhaust.", textUp: "Gain 20 stones. Exhaust.", effects: [{ op: "gainStones", n: 14 }], effectsUp: [{ op: "gainStones", n: 20 }], exhaust: true });

// --- Curses -----------------------------------------------------------------
add({ id: "curse_wound", name: "Wound Gu", rank: 1, path: "mortal", type: "Curse", rarity: "Common", cost: 1, icon: "internal-injury", tags: [], pool: "curse", curse: true, noUpgrade: true, text: "Lose 3 HP. Exhaust.", effects: [{ op: "loseHp", n: 3 }], exhaust: true });
add({ id: "curse_debt", name: "Debt Mark Gu", rank: 1, path: "mortal", type: "Curse", rarity: "Common", cost: 1, icon: "coins", tags: [], pool: "curse", curse: true, noUpgrade: true, text: "Lose 8 stones. Exhaust.", effects: [{ op: "gainStones", n: -8 }], exhaust: true });
add({ id: "curse_haunting", name: "Haunting Gu", rank: 1, path: "dark", type: "Curse", rarity: "Common", cost: 1, icon: "ghost", tags: [], pool: "curse", curse: true, noUpgrade: true, unplayable: true, text: "Unplayable. A dead thing occupies the aperture.", effects: [] });

export function getCard(id) {
  const c = CARDS[id];
  if (!c) throw new Error("Unknown Gu: " + id);
  return c;
}

export function allCards() {
  return Object.values(CARDS);
}

export { CARDS };

const NUM_KEYS = ["n", "day", "night", "normal", "low", "base", "bonus", "heal", "step", "flat", "open", "hidden", "solo", "pack", "per", "dmg"];

export function presentCard(inst) {
  const base = getCard(inst.id);
  let effects = base.effects.map((e) => ({ ...e }));
  let text = base.text;
  let cost = base.cost;
  if (inst.up) {
    if (base.effectsUp) effects = base.effectsUp.map((e) => ({ ...e }));
    else if (base.plus) effects = effects.map((e) => bump(e, base.plus));
    text = base.textUp || base.text;
    if (base.costUp != null) cost = base.costUp;
  }
  const bonus = inst.bonus || 0;
  const starving = (inst.hunger || 0) >= 3;
  if (bonus || starving) {
    effects = effects.map((e) => {
      const o = { ...e };
      for (const k of NUM_KEYS) {
        if (typeof o[k] !== "number") continue;
        let v = o[k] + (k === "per" || k === "below" ? 0 : bonus);
        if (starving && !["turns", "per", "below", "pct"].includes(k)) v = Math.max(1, Math.round(v * 0.7));
        o[k] = v;
      }
      return o;
    });
    if (starving) text += " (Starving)";
    if (bonus) text += " (Empowered)";
  }
  return { ...base, cost: Math.max(0, cost - (inst.costMod || 0)), text, effects, retain: base.retain, exhaust: base.exhaust, hpCost: base.hpCost || 0 };
}

function bump(e, plus) {
  const o = { ...e };
  for (const k of ["n", "day", "night", "normal", "low", "base", "open", "hidden", "solo", "pack", "flat"]) {
    if (typeof o[k] === "number") o[k] += plus;
  }
  return o;
}

export function needsEnemy(def) {
  if (def.target === "hand") return false;
  return def.effects.some((e) => ENEMY_OPS.has(e.op));
}

export function needsHandTarget(def) {
  return def.target === "hand";
}

const ENEMY_OPS = new Set(["damage", "poison", "weak", "vulnerable", "bleed", "burn", "doublePoison", "poisonPay", "execute", "combo", "lowHp", "missingHp", "nightStrike", "stealthStrike", "shieldBurst", "shackle", "stripBlock", "strengthDown", "randomDebuff", "summonStrike", "damagePerHand"]);

export const KILLERS = [
  { id: "mountain_fist", path: "strength", name: "Mountain Crushing Fist", cost: 2, need: 3, icon: "punch", text: "Deal 24 damage. Apply 2 Weak.", effects: [{ op: "damage", n: 24 }, { op: "weak", n: 2 }] },
  { id: "heaven_calc", path: "wisdom", name: "Heavenly Calculation", cost: 1, need: 3, icon: "brain", text: "Draw 3. Gain 2 Essence. Reveal the enemy pattern.", effects: [{ op: "draw", n: 3 }, { op: "energy", n: 2 }, { op: "reveal" }] },
  { id: "crimson_reversal", path: "blood", name: "Crimson Reversal", cost: 2, need: 3, icon: "drop", text: "Lose 6 HP. Deal 26 damage. Heal 10.", effects: [{ op: "loseHp", n: 6 }, { op: "damage", n: 26 }, { op: "heal", n: 10 }] },
  { id: "grand_forge", path: "refinement", name: "Grand Forge", cost: 2, need: 3, icon: "anvil", text: "Add two Forged Edge Gu to your hand. Empower your hand by +3.", effects: [{ op: "addCard", id: "forged_edge", dest: "hand" }, { op: "addCard", id: "forged_edge", dest: "hand" }, { op: "empowerHand", n: 3 }] },
  { id: "chimera", path: "transformation", name: "Chimera Ascendant", cost: 2, need: 3, icon: "yin-yang", text: "Gain 3 Strength, 3 Thorns, and 3 Regeneration.", effects: [{ op: "strength", n: 3 }, { op: "thorns", n: 3 }, { op: "regen", n: 3 }] },
  { id: "absolute_dominion", path: "enslavement", name: "Absolute Dominion", cost: 2, need: 3, icon: "crown", text: "The target's next attack hits itself. Deal 10 damage. Summon a beast (8 damage, 3 turns).", effects: [{ op: "shackle" }, { op: "damage", n: 10 }, { op: "summon", name: "Dominated Beast", dmg: 8, turns: 3, icon: "wolf" }] },
  { id: "plague_sutra", path: "poison", name: "Plague Sutra", cost: 2, need: 3, icon: "poison", text: "Double Poison, apply 4 more, then deal damage equal to twice the target's Poison.", effects: [{ op: "doublePoison" }, { op: "poison", n: 4 }, { op: "poisonPay", per: 2, flat: 0 }] },
  { id: "midnight_execution", path: "dark", name: "Midnight Execution", cost: 2, need: 3, icon: "dagger", text: "Deal 18 damage. If the target is below 40% HP or you are hidden, deal 32 instead.", effects: [{ op: "executeOrHidden", base: 18, bonus: 14, below: 40 }] },
  { id: "moonlight_devastation", path: "light", name: "Moonlight Devastation", cost: 2, need: 3, icon: "moon", text: "Deal 12 damage to all enemies and gain 12 Block. At night, deal 20 instead.", effects: [{ op: "nightAll", day: 12, night: 20 }, { op: "block", n: 12 }] },
  { id: "great_feast", path: "food", name: "Great Feast", cost: 2, need: 3, icon: "meal", text: "Heal 16. Gain 3 Strength. Draw 2.", effects: [{ op: "heal", n: 16 }, { op: "strength", n: 3 }, { op: "draw", n: 2 }] },
];

export function killerById(id) {
  return KILLERS.find((k) => k.id === id);
}
