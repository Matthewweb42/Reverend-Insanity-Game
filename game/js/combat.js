/** Turn-based Gu combat. Mutates the run. The caller decides what a win means. */

import { ATTAIN, KILLERS, attainmentTier, getCard, killerById, needsEnemy, needsHandTarget, pathCap, pathPower, presentCard } from "./cards.js";
import { rngInt, rngNext, shuffle } from "./rng.js";
import { ENVS, NPCS, getEnemy, getRelic } from "./world.js";

const HAND_MAX = 10;
const OPENING = 5;

function hook(run, name) {
  return run.relics.some((id) => getRelic(id)?.hooks?.includes(name));
}

export function isNight(run) {
  return Math.floor(run.days / 10) % 2 === 1;
}

export function lifeFraction(run) {
  const span = Math.max(1, run.deathAge - run.startAge);
  const age = run.startAge + run.days / 365;
  return (run.deathAge - age) / span;
}

export function ageLabel(run) {
  const p = lifeFraction(run);
  if (p > 0.5) return "Prime";
  if (p > 0.3) return "First Signs";
  if (p > 0.15) return "Decline";
  if (p > 0.05) return "Severe";
  return "Death's Door";
}

function ageOut(run) {
  const p = lifeFraction(run);
  if (p > 0.5) return 1;
  if (p > 0.3) return 0.97;
  if (p > 0.15) return 0.9;
  if (p > 0.05) return 0.8;
  return 0.7;
}

export function maxEnergy(run) {
  let n = 3;
  if (run.rank >= 4) n = 4;
  if (run.rank >= 7) n = 5;
  n += run.energyBonus || 0;
  if (hook(run, "demonicEnergy") && run.reputation < 0) n += 1;
  return n;
}

function living(combat) {
  return combat.enemies.filter((e) => e.hp > 0);
}

function log(run, text) {
  run.combat.log.unshift(text);
  run.combat.log.length = Math.min(run.combat.log.length, 28);
}

function fx(run, entry) {
  run.combat.fx.push(entry);
}

function cloneEnemy(def, uid) {
  return {
    uid,
    id: def.id,
    name: def.name,
    hp: def.hp,
    maxHp: def.hp,
    rank: def.rank,
    path: def.path,
    icon: def.icon,
    evasion: def.evasion || 0,
    block: 0,
    strength: 0,
    weak: 0,
    vulnerable: 0,
    poison: 0,
    bleed: 0,
    burn: 0,
    shackle: 0,
    moves: def.moves.map((m) => ({ ...m })),
    moves2: def.moves2 ? def.moves2.map((m) => ({ ...m })) : null,
    moves3: def.moves3 ? def.moves3.map((m) => ({ ...m })) : null,
    phaseBelow: def.phaseBelow ?? null,
    phase3Below: def.phase3Below ?? null,
    phaseText: def.phaseText || "",
    phaseText3: def.phaseText3 || "",
    phase: 1,
    mi: 0,
    finale: !!def.finale,
    calamity: !!def.calamity,
    grantsRank: def.grantsRank || 0,
    boss: !!def.boss,
    elite: !!def.elite,
    fire: !!def.fire,
    stones: def.stones ?? 16,
  };
}

export function currentMove(enemy) {
  if (!enemy.moves.length) return { intent: "wait" };
  return enemy.moves[enemy.mi % enemy.moves.length];
}

export function intentInfo(move) {
  if (!move) return { icon: "hidden", label: "Wait", num: "", extra: "" };
  const extra = [
    move.poison ? `${move.poison} poison` : "",
    move.weak ? `${move.weak} weak` : "",
    move.vulnerable ? `${move.vulnerable} vulnerable` : "",
    move.bleed ? `${move.bleed} bleed` : "",
    move.burn ? `${move.burn} burn` : "",
    move.strength ? `+${move.strength} strength` : "",
  ].filter(Boolean).join(" · ");
  if (move.intent === "attack") {
    const hits = move.hits || 1;
    return { icon: "swords", label: move.killer || "Attack", num: hits > 1 ? `${move.dmg}×${hits}` : String(move.dmg || 0), extra };
  }
  if (move.intent === "defend") return { icon: "shield", label: "Defend", num: String(move.block || 0), extra };
  if (move.intent === "buff") return { icon: "muscle", label: "Bolster", num: move.strength ? `+${move.strength}` : String(move.block || ""), extra };
  if (move.intent === "debuff") return { icon: "skull", label: "Afflict", num: move.dmg ? String(move.dmg) : "", extra };
  return { icon: "hidden", label: "Wait", num: "", extra };
}

export function cardEnergy(run, inst) {
  const def = presentCard(inst);
  if (hook(run, "firstDarkFree") && def.path === "dark" && run.combat && !run.combat.hero.usedDarkFree) return 0;
  return def.cost;
}

function pathCount(run, path) {
  return run.deck.filter((c) => getCard(c.id).path === path).length;
}

export function availableKillers(run) {
  if (!run.combat) return [];
  return KILLERS.filter((k) => {
    if (run.combat.hero.killerUsed[k.id]) return false;
    if ((run.attainment[k.path] || 0) < ATTAIN.master) return false;
    if (pathCount(run, k.path) < k.need) return false;
    return true;
  });
}

export function playError(run, uid, target) {
  const c = run.combat;
  if (!c) return "You are not in a fight.";
  if (run.combatOver) return "The fight is already over.";
  if (typeof uid === "string" && uid.startsWith("killer:")) {
    const k = killerById(uid.slice(7));
    if (!k) return "Unknown killer move.";
    if ((run.attainment[k.path] || 0) < ATTAIN.master) return "That killer move needs Master attainment.";
    if (c.hero.killerUsed[k.id]) return "Already used this battle.";
    if (pathCount(run, k.path) < k.need) return "Equip more Gu of that path.";
    if (k.cost > c.hero.energy) return "Not enough essence.";
    if (needsEnemy(k) && living(c).length > 1 && !target) return "Choose a target.";
    if (needsEnemy(k) && !living(c).length) return "No target.";
    return null;
  }
  const inst = c.hand.find((x) => x.uid === uid);
  if (!inst) return "That Gu is not in your hand.";
  const def = presentCard(inst);
  if (def.unplayable) return "This Gu cannot be played.";
  if (cardEnergy(run, inst) > c.hero.energy) return "Not enough essence.";
  if (def.path !== "mortal") {
    const used = c.hero.pathPlayed[def.path] || 0;
    const cap = pathCap(run.attainment[def.path] || 0);
    if (used >= cap) return `${attainmentTier(run.attainment[def.path] || 0)} limits you to ${cap} ${PATHNAME(def.path)} Gu this turn.`;
  }
  if ((def.hpCost || 0) >= run.hp) return "Not enough life.";
  if (needsHandTarget(def)) {
    const others = c.hand.filter((x) => x.uid !== uid);
    if (!others.length) return "You need another Gu in hand.";
    if (!target) return "Choose a Gu in hand.";
    if (target === uid || !c.hand.some((x) => x.uid === target)) return "Choose a different Gu in hand.";
  } else if (needsEnemy(def)) {
    const foes = living(c);
    if (!foes.length) return "No target.";
    if (foes.length > 1 && !target) return "Choose a target.";
    if (target && !foes.some((e) => e.uid === target)) return "Choose a living enemy.";
  }
  return null;
}

function PATHNAME(id) {
  return id.charAt(0).toUpperCase() + id.slice(1);
}

function targetEnemy(run, target) {
  const foes = living(run.combat);
  if (!foes.length) return null;
  if (target) return foes.find((e) => e.uid === target) || null;
  return foes.length === 1 ? foes[0] : null;
}

export function beginCombat(run, ids, opts = {}) {
  const enemies = ids.map((id, i) => cloneEnemy(getEnemy(id), "e" + i + "_" + id));
  const env = ENVS[opts.env] || ENVS.forest;
  const copies = run.deck.map((card) => ({
    uid: card.uid,
    id: card.id,
    up: !!card.up,
    hunger: card.hunger || 0,
    costMod: 0,
    bonus: 0,
  }));
  const revealed = !!(opts.revealed || ((opts.elite || enemies.some((e) => e.elite || e.boss)) && hook(run, "heavenGaze")));
  run.combat = {
    enemies,
    draw: shuffle(run, copies),
    hand: [],
    discard: [],
    exhaust: [],
    log: [],
    fx: [],
    env,
    revealed,
    elite: !!(opts.elite || enemies.some((e) => e.elite)),
    boss: enemies.some((e) => e.boss),
    source: opts.source || "road",
    pathCounts: {},
    hero: {
      block: 0,
      energy: 0,
      strength: 0,
      weak: 0,
      vulnerable: 0,
      poison: 0,
      bleed: 0,
      burn: env.startBurn || 0,
      regen: (env.regen || 0) + (hook(run, "startRegen") ? 2 : 0),
      thorns: 0,
      ghost: false,
      nextAttackBonus: 0,
      powers: {},
      pathPlayed: {},
      attacksThisTurn: 0,
      killerUsed: {},
      usedDarkFree: false,
      firstBlockUsed: false,
      refineDrawn: false,
      nextDraw: 0,
      summons: [],
      hpLossStr: 0,
      turn: 0,
    },
  };
  run.combatOver = null;
  if (env.enemyBlock) {
    for (const e of enemies) e.block += env.enemyBlock;
  }
  if (hook(run, "heavenGaze") && (run.combat.elite || run.combat.boss)) {
    run.combat.hero.strength += 1;
  }
  if (hook(run, "startSummon") || run.startSummon) {
    const s = run.startSummon || { name: "Whistle Wolf", dmg: 4, turns: 3, icon: "wolf" };
    run.combat.hero.summons.push({ ...s, perm: s.turns >= 90 });
  }
  if (run.combat.boss) {
    const ally = NPCS.find((n) => (run.npcs[n.id] || 0) >= 55);
    if (ally) {
      run.combat.hero.summons.push({ name: ally.name, dmg: 6, turns: 4, icon: "monk", perm: false });
      log(run, `${ally.name} steps into the fight beside you.`);
    }
  }
  const note = living(run.combat).length >= 2 ? " Outnumbered: enemy attacks deal +2." : "";
  log(run, `${env.name}. ${env.note}${note}`);
  startTurn(run, true);
}

function startTurn(run, first) {
  const c = run.combat;
  const h = c.hero;
  if (run.combatOver) return;
  h.turn += 1;
  if (h.turn > 30) {
    const eh = living(c).reduce((s, e) => s + e.hp / e.maxHp, 0);
    const ph = run.hp / run.maxHp;
    if (ph >= eh) {
      for (const e of c.enemies) e.hp = 0;
      run.combatOver = { outcome: "win", reason: "The fight could not be settled. Your vitality holds." };
    } else {
      run.hp = 0;
      run.combatOver = { outcome: "dead", cause: "The fight dragged on until your strength failed." };
    }
    return;
  }
  if (c.env.miasma) {
    hurtPlayer(run, c.env.miasma, true, "miasma");
    if (!run.combatOver) log(run, `Miasma deals ${c.env.miasma}.`);
    if (run.combatOver) return;
  }
  if (!first) {
    tickDot(run, h, "you", true);
    if (run.hp <= 0 || run.combatOver) return;
    if (h.regen) heal(run, h.regen, "regeneration");
  }
  if (hook(run, "retainBlock")) h.block = Math.min(h.block, 6);
  else h.block = 0;
  h.pathPlayed = {};
  h.attacksThisTurn = 0;
  h.firstBlockUsed = false;
  h.refineDrawn = false;
  h.energy = maxEnergy(run);
  for (const key of Object.keys(h.powers)) {
    const p = h.powers[key];
    if (p && p.turns != null) {
      p.turns -= 1;
      if (p.turns <= 0) delete h.powers[key];
    }
  }
  let drawN = OPENING === 5 && first ? 5 : 5;
  if (first && hook(run, "turn1Draw")) drawN += 1;
  drawN += h.nextDraw || 0;
  h.nextDraw = 0;
  drawCards(run, drawN);
  log(run, first ? "Battle begins." : `Turn ${h.turn}.`);
}

function tickDot(run, who, label, isHero) {
  if (who.poison > 0) {
    const n = who.poison;
    if (isHero) hurtPlayer(run, n, true, "poison");
    else damageEnemy(run, who, n, { pierce: true, kind: "poison" });
    who.poison = Math.max(0, who.poison - 1);
    if (!run.combatOver) log(run, `${label} takes ${n} poison.`);
  }
  if (run.combatOver) return;
  if (who.bleed > 0) {
    const n = who.bleed;
    if (isHero) hurtPlayer(run, n, true, "bleed");
    else damageEnemy(run, who, n, { pierce: true, kind: "bleed" });
    who.bleed = Math.max(0, who.bleed - 1);
    if (!run.combatOver) log(run, `${label} takes ${n} bleed.`);
  }
}

function drawCards(run, n) {
  const c = run.combat;
  for (let i = 0; i < n; i++) {
    if (c.hand.length >= HAND_MAX) {
      log(run, "Your hand is full.");
      return;
    }
    if (!c.draw.length) {
      if (!c.discard.length) return;
      c.draw = shuffle(run, c.discard);
      c.discard = [];
      log(run, "The aperture reshuffles.");
    }
    c.hand.push(c.draw.pop());
  }
}

export function playCard(run, uid, target) {
  const err = playError(run, uid, target);
  run.combat.fx = [];
  if (err) return { ok: false, error: err, fx: [] };
  if (typeof uid === "string" && uid.startsWith("killer:")) return playKiller(run, uid.slice(7), target);
  const c = run.combat;
  const h = c.hero;
  const idx = c.hand.findIndex((x) => x.uid === uid);
  const inst = c.hand[idx];
  const def = presentCard(inst);
  const cost = cardEnergy(run, inst);
  h.energy -= cost;
  if (hook(run, "firstDarkFree") && def.path === "dark" && !h.usedDarkFree) h.usedDarkFree = true;
  if (def.hpCost) {
    run.hp = Math.max(1, run.hp - def.hpCost);
    fx(run, { t: "dmg", who: "hero", n: def.hpCost, kind: "blood" });
    log(run, `You pay ${def.hpCost} life.`);
    if (hook(run, "hpLossStrength") && h.hpLossStr < 4) {
      h.strength += 1;
      h.hpLossStr += 1;
      log(run, "The Blood Pearl warms. +1 Strength.");
    }
  }
  if (def.path !== "mortal") {
    h.pathPlayed[def.path] = (h.pathPlayed[def.path] || 0) + 1;
    c.pathCounts[def.path] = (c.pathCounts[def.path] || 0) + 1;
  }
  c.hand.splice(idx, 1);
  log(run, `You activate ${def.name}.`);
  const ctx = {
    handSize: c.hand.length + 1,
    hidden: !!(h.ghost || h.nextAttackBonus),
    path: def.path,
    tags: def.tags || [],
    didAttack: false,
  };
  resolveEffects(run, def.effects, target, ctx);
  if (ctx.didAttack) h.attacksThisTurn += 1;
  if (c.env.refineDraw && def.path === "refinement" && !h.refineDrawn && !run.combatOver) {
    h.refineDrawn = true;
    drawCards(run, 1);
    log(run, "Ancient dust answers the refinement. Draw 1.");
  }
  if (def.exhaust) c.exhaust.push(inst);
  else c.discard.push(inst);
  if (!run.combatOver && living(c).length === 0) run.combatOver = { outcome: "win" };
  return { ok: true, fx: c.fx.slice() };
}

function playKiller(run, id, target) {
  const k = killerById(id);
  const c = run.combat;
  const h = c.hero;
  h.energy -= k.cost;
  h.killerUsed[k.id] = true;
  h.pathPlayed[k.path] = (h.pathPlayed[k.path] || 0) + 1;
  c.pathCounts[k.path] = (c.pathCounts[k.path] || 0) + 1;
  const ctx = { handSize: c.hand.length, hidden: !!(h.ghost || h.nextAttackBonus), path: k.path, tags: ["attack"], didAttack: false };
  resolveEffects(run, k.effects, target, ctx);
  if (ctx.didAttack) h.attacksThisTurn += 1;
  log(run, `Killer move: ${k.name}.`);
  fx(run, { t: "shake", mag: 14 });
  if (!run.combatOver && living(c).length === 0) run.combatOver = { outcome: "win" };
  return { ok: true, fx: c.fx.slice() };
}

function resolveEffects(run, effects, target, ctx) {
  for (const effect of effects) {
    if (run.combatOver) return;
    applyOne(run, effect, target, ctx);
  }
}

function applyOne(run, e, target, ctx) {
  const c = run.combat;
  const h = c.hero;
  const foe = () => targetEnemy(run, target);
  switch (e.op) {
    case "damage":
    case "combo":
    case "lowHp":
    case "missingHp":
    case "nightStrike":
    case "stealthStrike":
    case "execute":
    case "executeOrHidden":
    case "poisonPay":
    case "shieldBurst":
    case "damagePerHand":
    case "summonStrike": {
      const enemy = foe();
      if (!enemy) return;
      ctx.steal = e.steal || 0;
      const n = amountFor(run, e, enemy, ctx);
      strikeEnemy(run, enemy, n, ctx);
      if (e.op === "shieldBurst") h.block = 0;
      ctx.steal = 0;
      if (e.bounty && enemy.hp <= 0) {
        run.stones += e.bounty;
        log(run, `Devoured. +${e.bounty} stones.`);
      }
      return;
    }
    case "damageAll":
    case "nightAll": {
      let n = e.op === "nightAll" ? (isNight(run) ? e.night : e.day) : e.n;
      for (const enemy of living(c)) {
        if (run.combatOver) return;
        strikeEnemy(run, enemy, n, ctx);
      }
      return;
    }
    case "block":
    case "blockIfAttacked": {
      if (e.op === "blockIfAttacked" && h.attacksThisTurn <= 0 && !ctx.didAttack) return;
      gainBlock(run, e.n, ctx);
      return;
    }
    case "nightBlock":
      if (isNight(run)) gainBlock(run, e.n, ctx);
      return;
    case "heal": {
      let n = e.n;
      if (ctx.path === "food" && hook(run, "foodHeal")) n += 3;
      heal(run, n, "healing");
      return;
    }
    case "loseHp":
      hurtPlayer(run, e.n, true, "cost");
      return;
    case "draw":
      drawCards(run, e.n);
      return;
    case "energy":
      h.energy += e.n;
      log(run, `+${e.n} essence.`);
      return;
    case "poison":
    case "poisonAll": {
      const list = e.op === "poisonAll" ? living(c) : [foe()].filter(Boolean);
      for (const enemy of list) {
        let n = e.n + (hook(run, "poisonBonus") ? 1 : 0);
        enemy.poison += n;
        log(run, `${enemy.name} takes ${n} poison (${enemy.poison}).`);
      }
      return;
    }
    case "doublePoison": {
      const enemy = foe();
      if (!enemy) return;
      enemy.poison *= 2;
      log(run, `${enemy.name}'s poison doubles to ${enemy.poison}.`);
      return;
    }
    case "weak": {
      const enemy = foe();
      if (enemy) { enemy.weak += e.n; log(run, `${enemy.name} is weak (${enemy.weak}).`); }
      return;
    }
    case "weakAll":
      for (const enemy of living(c)) enemy.weak += e.n;
      log(run, `All foes are weak.`);
      return;
    case "vulnerable": {
      const enemy = foe();
      if (enemy) { enemy.vulnerable += e.n; log(run, `${enemy.name} is vulnerable.`); }
      return;
    }
    case "bleed": {
      const enemy = foe();
      if (enemy) { enemy.bleed += e.n; log(run, `${enemy.name} bleeds (${enemy.bleed}).`); }
      return;
    }
    case "burn": {
      const enemy = foe();
      if (enemy) { enemy.burn += e.n; log(run, `${enemy.name} burns (${enemy.burn}).`); }
      return;
    }
    case "strength":
      h.strength += e.n;
      log(run, `+${e.n} Strength.`);
      return;
    case "strengthDown": {
      const enemy = foe();
      if (enemy) { enemy.strength -= e.n; log(run, `${enemy.name} loses ${e.n} Strength.`); }
      return;
    }
    case "stripBlock": {
      const enemy = foe();
      if (enemy && enemy.block) {
        log(run, `You strip ${enemy.block} block.`);
        enemy.block = 0;
      }
      return;
    }
    case "shackle": {
      const enemy = foe();
      if (enemy) { enemy.shackle = 1; log(run, `${enemy.name} will strike itself next.`); }
      return;
    }
    case "stealth":
      h.nextAttackBonus += e.n;
      h.ghost = true;
      log(run, `You sink into cover. Next attack +${e.n}.`);
      return;
    case "cleanse": {
      const stacks = h.weak + h.vulnerable + h.poison + h.bleed + h.burn;
      h.weak = h.vulnerable = h.poison = h.bleed = h.burn = 0;
      const healed = stacks * (e.per || 3);
      if (stacks) heal(run, healed, "cleansing");
      else log(run, "Nothing clings to you.");
      return;
    }
    case "reveal":
      c.revealed = true;
      log(run, "The enemy pattern lies open.");
      return;
    case "summon": {
      if (h.summons.length >= 3) h.summons.shift();
      h.summons.push({ name: e.name, dmg: e.dmg, turns: e.turns, icon: e.icon || "wolf", perm: e.turns >= 90 });
      log(run, `${e.name} answers the contract.`);
      return;
    }
    case "power":
      h.powers[e.key] = { turns: e.turns ?? 99, n: e.n || 0 };
      log(run, `Form shifts: ${e.key}.`);
      return;
    case "regen":
      h.regen += e.n;
      log(run, `Regeneration ${h.regen}.`);
      return;
    case "thorns":
      h.thorns += e.n;
      log(run, `Thorns ${h.thorns}.`);
      return;
    case "gainStones":
      run.stones = Math.max(0, run.stones + e.n);
      log(run, e.n >= 0 ? `+${e.n} stones.` : `${e.n} stones.`);
      return;
    case "nextDraw":
      h.nextDraw += e.n;
      log(run, "You will draw more next turn.");
      return;
    case "randomDebuff": {
      const enemy = foe();
      if (!enemy) return;
      const roll = rngInt(run, 3);
      if (roll === 0) { enemy.weak += 2; log(run, `${enemy.name} is weak.`); }
      else if (roll === 1) { enemy.vulnerable += 2; log(run, `${enemy.name} is vulnerable.`); }
      else { enemy.poison += 3 + (hook(run, "poisonBonus") ? 1 : 0); log(run, `${enemy.name} is poisoned.`); }
      return;
    }
    case "weakIfHidden": {
      if (!ctx.hidden) return;
      const enemy = foe();
      if (enemy) { enemy.weak += e.n; log(run, `${enemy.name} is weak.`); }
      return;
    }
    case "costDown":
    case "empower": {
      const card = c.hand.find((x) => x.uid === target);
      if (!card) return;
      if (e.op === "costDown") card.costMod = (card.costMod || 0) + e.n;
      else card.bonus = (card.bonus || 0) + e.n;
      log(run, e.op === "costDown" ? "A Gu in hand grows lighter." : "A Gu in hand is empowered.");
      return;
    }
    case "empowerHand":
      for (const card of c.hand) card.bonus = (card.bonus || 0) + e.n;
      log(run, "The hand is empowered.");
      return;
    case "exhaustOther": {
      const i = c.hand.findIndex((x) => x.uid === target);
      if (i >= 0) {
        const [card] = c.hand.splice(i, 1);
        c.exhaust.push(card);
        log(run, `${getCard(card.id).name} is exhausted.`);
      }
      return;
    }
    case "addCard": {
      const inst = { uid: "tmp" + (run.uidCounter++), id: e.id, up: false, hunger: 0, costMod: 0, bonus: 0, temp: true };
      if (e.dest === "hand" && c.hand.length < HAND_MAX) c.hand.push(inst);
      else c.discard.push(inst);
      log(run, `${getCard(e.id).name} is forged.`);
      return;
    }
    default:
      log(run, `(unresolved ${e.op})`);
  }
}

function amountFor(run, e, enemy, ctx) {
  const h = run.combat.hero;
  if (e.op === "combo") return e.base + e.step * h.attacksThisTurn;
  if (e.op === "lowHp") return run.hp / run.maxHp < e.pct / 100 ? e.low : e.normal;
  if (e.op === "missingHp") return Math.min(e.cap, e.base + e.per * (run.maxHp - run.hp));
  if (e.op === "nightStrike") return isNight(run) ? e.night : e.day;
  if (e.op === "stealthStrike") return ctx.hidden ? e.hidden : e.open;
  if (e.op === "execute") return enemy.hp / enemy.maxHp < e.below / 100 ? e.base + e.bonus : e.base;
  if (e.op === "executeOrHidden") return ctx.hidden || enemy.hp / enemy.maxHp < e.below / 100 ? e.base + e.bonus : e.base;
  if (e.op === "poisonPay") return enemy.poison * (e.per || 1) + (e.flat || 0);
  if (e.op === "shieldBurst") return h.block + (e.flat || 0);
  if (e.op === "damagePerHand") return e.n * ctx.handSize;
  if (e.op === "summonStrike") return h.summons.length ? e.pack : e.solo;
  return e.n || 0;
}

function strikeEnemy(run, enemy, base, ctx) {
  const c = run.combat;
  const h = c.hero;
  let n = Math.round(base);
  if (c.env.strength && ctx.path === "strength") n += c.env.strength;
  if (c.env.dark && ctx.path === "dark") n += c.env.dark;
  if (isNight(run) && hook(run, "nightBonus")) n += 3;
  if (h.attacksThisTurn > 0 && hook(run, "comboBonus")) n += 3;
  if (ctx.path === "refinement" && hook(run, "refineBonus")) n += 2;
  n += h.strength;
  if (h.powers.wolf) n += h.powers.wolf.n;
  if (h.nextAttackBonus) {
    n += h.nextAttackBonus;
    h.nextAttackBonus = 0;
  }
  if (h.weak > 0) n = Math.round(n * 0.75);
  const power = pathPower(run.attainment[ctx.path] || 0) + ((run.dao && run.dao[ctx.path]) || 0) * 0.05 + (hook(run, "efficiency") ? 0.1 : 0);
  if (ctx.path !== "mortal") n = Math.round(n * (1 + power));
  n = Math.round(n * ageOut(run));
  if (c.env.id === "mountain") n -= 1;
  if (enemy.vulnerable > 0) n = Math.round(n * 1.25);
  n = Math.max(0, n);
  ctx.didAttack = true;
  const hit = rollHit(run, enemy.evasion);
  if (hit === "miss") {
    log(run, `${enemy.name} evades.`);
    fx(run, { t: "miss", uid: enemy.uid });
    return;
  }
  if (hit === "crit") {
    n = Math.round(n * 1.25);
    fx(run, { t: "shake", mag: 10 });
  } else if (n >= 12) fx(run, { t: "shake", mag: 6 });
  const dealt = damageEnemy(run, enemy, n, { kind: hit });
  if (h.powers.lifelink && dealt > 0) heal(run, h.powers.lifelink.n, "blood");
  if (ctx.steal && dealt > 0) heal(run, Math.round(dealt * ctx.steal), "blood");
  if (enemy.hp > 0 && h.powers.wolf) enemy.bleed += 2;
  if (enemy.hp > 0 && h.powers.serpent) enemy.poison += h.powers.serpent.n + (hook(run, "poisonBonus") ? 1 : 0);
}

function damageEnemy(run, enemy, amount, opts = {}) {
  if (enemy.hp <= 0) return 0;
  amount = Math.max(0, Math.round(amount));
  if (!opts.pierce && enemy.block > 0) {
    const use = Math.min(enemy.block, amount);
    enemy.block -= use;
    amount -= use;
    if (use) fx(run, { t: "block", who: "enemy", uid: enemy.uid, n: use });
  }
  enemy.hp -= amount;
  if (enemy.hp < 0) enemy.hp = 0;
  if (amount > 0) {
    fx(run, { t: "dmg", who: "enemy", uid: enemy.uid, n: amount, kind: opts.kind || "hit" });
    run.stats = run.stats || { damage: 0, maxHit: 0 };
    run.stats.damage += amount;
    if (amount > (run.stats.maxHit || 0)) run.stats.maxHit = amount;
  }
  checkPhase(run, enemy);
  if (living(run.combat).length === 0 && !run.combatOver) run.combatOver = { outcome: "win" };
  return amount;
}

function checkPhase(run, e) {
  if (e.hp <= 0) return;
  if (e.phase === 1 && e.moves2 && e.phaseBelow != null && e.hp <= e.maxHp * e.phaseBelow) {
    e.phase = 2;
    e.moves = e.moves2;
    e.mi = 0;
    log(run, e.phaseText || `${e.name} changes.`);
    fx(run, { t: "shake", mag: 12 });
  } else if (e.phase === 2 && e.moves3 && e.phase3Below != null && e.hp <= e.maxHp * e.phase3Below) {
    e.phase = 3;
    e.moves = e.moves3;
    e.mi = 0;
    log(run, e.phaseText3 || `${e.name} changes again.`);
    fx(run, { t: "shake", mag: 14 });
  }
}

function gainBlock(run, n, ctx) {
  const h = run.combat.hero;
  let v = n;
  if (ctx && ctx.path === "refinement" && hook(run, "refineBonus")) v += 2;
  const power = ctx && ctx.path && ctx.path !== "mortal"
    ? pathPower(run.attainment[ctx.path] || 0) + ((run.dao && run.dao[ctx.path]) || 0) * 0.05 + (hook(run, "efficiency") ? 0.1 : 0)
    : 0;
  v = Math.round(v * (1 + power));
  if (run.combat.env.firstBlock && !h.firstBlockUsed) {
    v += run.combat.env.firstBlock;
    h.firstBlockUsed = true;
  }
  h.block += Math.max(0, v);
  fx(run, { t: "block", who: "hero", n: v });
  log(run, `Block ${h.block}.`);
}

function heal(run, n, why) {
  n = Math.max(0, Math.round(n));
  if (!n) return;
  const before = run.hp;
  run.hp = Math.min(run.maxHp, run.hp + n);
  const got = run.hp - before;
  if (got > 0) {
    fx(run, { t: "heal", n: got });
    log(run, `Heal ${got}${why ? ` (${why})` : ""}.`);
  }
}

function hurtPlayer(run, amount, pierce, kind) {
  const h = run.combat.hero;
  amount = Math.max(0, Math.round(amount));
  if (!amount) return 0;
  if (!pierce && h.block > 0) {
    const use = Math.min(h.block, amount);
    h.block -= use;
    amount -= use;
    if (use) fx(run, { t: "block", who: "hero", n: use });
  }
  if (amount > 0 && run.combat.env.id === "soul" && kind === "miasma") {
    /* already the amount */
  }
  run.hp -= amount;
  if (amount > 0) fx(run, { t: "dmg", who: "hero", n: amount, kind: kind || "hit" });
  if (run.hp <= 0) {
    run.flags = run.flags || {};
    if (hook(run, "survive") && !run.flags.springUsed) {
      run.hp = 1;
      run.flags.springUsed = true;
      log(run, "The Spring Autumn Fragment cracks. You stay at 1 HP.");
      fx(run, { t: "shake", mag: 16 });
    } else {
      run.hp = 0;
      run.combatOver = { outcome: "dead", cause: "Slain in battle." };
      log(run, "You fall.");
    }
  } else if (amount >= 8) fx(run, { t: "shake", mag: 8 });
  return amount;
}

function rollHit(run, evasion) {
  const miss = Math.min(0.42, (evasion || 0) * 0.045);
  const r = rngNext(run);
  if (r < miss) return "miss";
  if (r > 0.9) return "crit";
  return "hit";
}

export function endTurn(run) {
  const c = run.combat;
  if (!c) return { ok: false, error: "You are not in a fight." };
  c.fx = [];
  if (run.combatOver) return { ok: true, fx: [] };
  const h = c.hero;
  const kept = [];
  for (const card of c.hand) {
    const def = presentCard(card);
    if (def.retain) kept.push(card);
    else c.discard.push(card);
  }
  c.hand = kept;
  summonsAct(run);
  if (h.burn > 0 && !run.combatOver) {
    const n = h.burn;
    hurtPlayer(run, n, true, "burn");
    h.burn = Math.max(0, h.burn - 1);
    if (!run.combatOver) log(run, `Burn deals ${n}.`);
  }
  if (h.weak > 0) h.weak -= 1;
  if (h.vulnerable > 0) h.vulnerable -= 1;
  if (!run.combatOver) enemyPhase(run);
  if (!run.combatOver && living(c).length === 0) run.combatOver = { outcome: "win" };
  if (!run.combatOver) startTurn(run, false);
  return { ok: true, fx: c.fx.slice() };
}

function summonsAct(run) {
  const h = run.combat.hero;
  for (const s of h.summons) {
    if (run.combatOver) return;
    const foes = living(run.combat);
    if (!foes.length) return;
    const tgt = foes.slice().sort((a, b) => a.hp - b.hp)[0];
    let dmg = s.dmg + (h.powers.summonBoost ? h.powers.summonBoost.n : 0);
    if (hook(run, "summonBonus")) dmg += 2;
    damageEnemy(run, tgt, dmg, { pierce: false, kind: "summon" });
    log(run, `${s.name} strikes ${tgt.name} for ${dmg}.`);
    if (!s.perm) s.turns -= 1;
  }
  h.summons = h.summons.filter((s) => s.perm || s.turns > 0);
}

function enemyPhase(run) {
  for (const enemy of run.combat.enemies) {
    if (run.combatOver) return;
    if (enemy.hp <= 0) continue;
    tickDot(run, enemy, enemy.name, false);
    if (run.combatOver || enemy.hp <= 0) continue;
    const move = currentMove(enemy);
    resolveEnemyMove(run, enemy, move);
    if (enemy.burn > 0 && enemy.hp > 0 && !run.combatOver) {
      const n = enemy.burn;
      damageEnemy(run, enemy, n, { pierce: true, kind: "burn" });
      enemy.burn = Math.max(0, enemy.burn - 1);
      log(run, `${enemy.name} burns for ${n}.`);
    }
    if (enemy.weak > 0) enemy.weak -= 1;
    if (enemy.vulnerable > 0) enemy.vulnerable -= 1;
    enemy.mi += 1;
  }
}

function resolveEnemyMove(run, enemy, move) {
  const label = move.killer ? `${enemy.name} uses ${move.killer}` : `${enemy.name}`;
  if ((move.intent === "attack" || (move.dmg && move.intent === "debuff")) && move.dmg) {
    const hits = move.hits || 1;
    if (enemy.shackle) {
      for (let i = 0; i < hits; i++) {
        const n = scaleEnemy(run, enemy, move.dmg);
        damageEnemy(run, enemy, n, { kind: "shackle" });
        log(run, `${enemy.name} is shackled and hits itself for ${n}.`);
      }
      enemy.shackle = 0;
    } else {
      for (let i = 0; i < hits; i++) attackPlayer(run, enemy, move.dmg, label);
    }
  } else if (move.intent === "defend") {
    log(run, `${label} defends.`);
  } else if (move.intent === "buff") {
    log(run, `${label} gathers strength.`);
  } else {
    log(run, `${label} acts.`);
  }
  if (move.block) enemy.block += move.block;
  if (move.strength) enemy.strength += move.strength;
  const h = run.combat.hero;
  if (move.weak) h.weak += move.weak;
  if (move.vulnerable) h.vulnerable += move.vulnerable;
  if (move.poison) h.poison += move.poison;
  if (move.bleed) h.bleed += move.bleed;
  if (move.burn) h.burn += move.burn;
}

function scaleEnemy(run, enemy, base) {
  let n = base + (enemy.strength || 0);
  if (enemy.weak > 0) n = Math.round(n * 0.75);
  if (living(run.combat).length >= 2) n += 2;
  if (run.combat.env.id === "mountain") n -= 1;
  return Math.max(1, n);
}

function attackPlayer(run, enemy, base, label) {
  const h = run.combat.hero;
  if (h.ghost) {
    h.ghost = false;
    if (rngNext(run) < 0.5) {
      log(run, `You vanish. ${enemy.name} misses.`);
      fx(run, { t: "miss", who: "hero" });
      return;
    }
  }
  let n = scaleEnemy(run, enemy, base);
  if (h.vulnerable > 0) n = Math.round(n * 1.25);
  const hit = rollHit(run, 0);
  if (hit === "miss") {
    log(run, `${enemy.name} misses.`);
    fx(run, { t: "miss", who: "hero" });
    return;
  }
  if (hit === "crit") {
    n = Math.round(n * 1.25);
    fx(run, { t: "shake", mag: 9 });
  }
  hurtPlayer(run, n, false, hit);
  if (!run.combatOver && h.thorns > 0) {
    damageEnemy(run, enemy, h.thorns, { pierce: true, kind: "thorns" });
    log(run, `Thorns bite ${enemy.name}.`);
  }
  if (!run.combatOver) log(run, `${label} hits you for ${n}.`);
}

export function tryFlee(run) {
  const c = run.combat;
  if (!c) return { ok: false, error: "You are not in a fight." };
  c.fx = [];
  if (run.combatOver) return { ok: false, error: "The fight is already over." };
  const boss = c.enemies.some((e) => e.boss);
  let chance = boss ? 0.08 : 0.42;
  if (run.deck.some((card) => (getCard(card.id).tags || []).includes("movement"))) chance += 0.22;
  if (run.hp < run.maxHp * 0.3) chance -= 0.12;
  chance = Math.max(0.05, Math.min(0.9, chance));
  run._lastFlee = chance;
  if (rngNext(run) < chance) {
    const loss = fleeRep(run);
    run.reputation -= loss;
    run.combatOver = { outcome: "flee", rep: loss };
    log(run, loss ? `You break away. Reputation ${loss > 0 ? "−" + loss : "holds"}.` : "You break away. No one calls it cowardice.");
    return { ok: true, fled: true, fx: c.fx.slice() };
  }
  log(run, "You fail to break away.");
  const enemy = living(c)[0];
  if (enemy) {
    const mv = currentMove(enemy);
    if (mv.dmg) attackPlayer(run, enemy, mv.dmg, enemy.name);
  }
  return { ok: true, fled: false, fx: c.fx.slice(), error: run.combatOver ? null : "Escape failed." };
}

function fleeRep(run) {
  const foe = Math.max(...run.combat.enemies.map((e) => e.rank));
  const diff = foe - run.rank;
  if (diff >= 2) return 0;
  if (diff >= 0) return 5;
  if (diff >= -1) return 12;
  return 22;
}

export function fleeChance(run) {
  if (!run.combat) return 0;
  const boss = run.combat.enemies.some((e) => e.boss);
  let chance = boss ? 0.08 : 0.42;
  if (run.deck.some((card) => (getCard(card.id).tags || []).includes("movement"))) chance += 0.22;
  if (run.hp < run.maxHp * 0.3) chance -= 0.12;
  return Math.max(0.05, Math.min(0.9, chance));
}

/** Fix shield burst so the block is spent and steal works. Patched by wrapping amount. */
export function _wireSteal(run, enemy, dealt, steal) {
  if (steal && dealt > 0) heal(run, Math.round(dealt * steal), "blood");
}
