/** Run flow: map, events, shops, cultivation, inheritance. */

import { PATH_ORDER, STAGES, allCards, attainmentTier, getCard } from "./cards.js";
import { beginCombat, endTurn as endCombatTurn, lifeFraction, maxEnergy, playCard as playCombatCard, tryFlee as fleeCombat } from "./combat.js";
import { rngInt, rngNext } from "./rng.js";
import {
  ACTS, BLESSINGS, BURDENS, EVENTS, FORMULAS, ITEMS, LEGACY_SHOP, ORIGINS, RELICS, getEvent, getRelic,
} from "./world.js";

export const APT = {
  A: { cult: 1.5, br: 0.15, name: "A-grade" },
  B: { cult: 1.2, br: 0.08, name: "B-grade" },
  C: { cult: 1, br: 0, name: "C-grade" },
  D: { cult: 0.7, br: -0.1, name: "D-grade" },
};

const DICE_CAP = [2, 3, 4, 5, 6];
const BR_BASE = { 1: 0.74, 2: 0.64, 3: 0.54, 4: 0.46 };

export function newMeta() {
  return {
    points: 0, bonusStones: 0, bonusYears: 0, insight: 0, insightPath: null,
    startRelic: null, formulas: [], unlocks: [], friend: false, reroll: false,
    runs: 0, wins: 0, bestRank: 1, seen: [],
  };
}

export function rollAptitude(run) {
  const r = rngNext(run);
  if (r < 0.05) return "A";
  if (r < 0.2) return "B";
  if (r < 0.5) return "C";
  return "D";
}

export function slotMax(run) {
  return 12 + (run.rank - 1) * 2 + (run.slotBonus || 0);
}

export function ageYears(run) {
  return run.startAge + run.days / 365;
}

export function repName(n) {
  if (n >= 40) return "Righteous";
  if (n >= 15) return "Respected";
  if (n <= -40) return "Demonic";
  if (n <= -15) return "Feared";
  return "Neutral";
}

export function standingName(n) {
  return ["Outsider", "Probationary", "Member", "Core", "Elder"][Math.max(0, Math.min(4, n))] || "Member";
}

export function focusPath(run) {
  let best = (run.originPaths && run.originPaths[0]) || "strength";
  let n = -1;
  for (const p of PATH_ORDER) {
    const v = run.attainment[p] || 0;
    if (v > n) { n = v; best = p; }
  }
  return best;
}

function cultMod(run) {
  const p = lifeFraction(run);
  const age = p > 0.5 ? 1 : p > 0.3 ? 0.95 : p > 0.15 ? 0.85 : p > 0.05 ? 0.65 : 0.4;
  return age * (APT[run.aptitude]?.cult || 1);
}

function journal(run, text) {
  run.journal.unshift(text);
  run.journal.length = Math.min(18, run.journal.length);
}

function mint(run, id) {
  run.discoveries.push("card:" + id);
  return { uid: "c" + (run.uidCounter++), id, up: false, hunger: 0 };
}

function giveCard(run, id) {
  const inst = mint(run, id);
  const curse = getCard(id).curse;
  if (curse || run.deck.length < slotMax(run)) run.deck.push(inst);
  else run.stash.push(inst);
  return inst;
}

export function createRun(opts = {}) {
  const meta = opts.meta || newMeta();
  const origin = ORIGINS.find((o) => o.id === (opts.origin || "guyue")) || ORIGINS[0];
  const blessing = BLESSINGS.find((b) => b.id === opts.blessing) || BLESSINGS[0];
  const burden = BURDENS.find((b) => b.id === opts.burden) || BURDENS[0];
  const seed = opts.seed === undefined || opts.seed === null
    ? (((Date.now() ^ 0x9e3779b9) >>> 0) || 1)
    : (Number(opts.seed) >>> 0);
  const run = {
    version: 1,
    seed,
    rng: seed,
    name: (opts.name || "Shen Yuan").slice(0, 24),
    origin: origin.id,
    originName: origin.name,
    originKind: origin.kind,
    originPaths: origin.paths.slice(),
    blessing: blessing.id,
    burden: burden.id,
    aptitude: APT[opts.aptitude] ? opts.aptitude : "C",
    startAge: origin.age,
    deathAge: origin.deathAge + (blessing.years || 0) + (burden.years || 0) + (meta.bonusYears || 0),
    days: 0,
    rank: 1,
    stage: 0,
    progress: 0,
    breakthroughReady: false,
    hpBonus: (blessing.hp || 0) + (burden.hp || 0),
    stones: 0,
    immortalStones: 0,
    materials: 0,
    reputation: burden.reputation || 0,
    standing: blessing.standing ?? origin.standing ?? 2,
    energyBonus: 0,
    slotBonus: 0,
    discount: (origin.discount || 0) + (blessing.discount || 0),
    deck: [],
    stash: [],
    relics: [],
    items: { year_fruit: 0, healing_salve: 0, scout_report: 0, fodder: 0, minor_relic_gu: 0 },
    attainment: Object.fromEntries(PATH_ORDER.map((p) => [p, origin.attainment?.[p] || 0])),
    dao: Object.fromEntries(PATH_ORDER.map((p) => [p, 0])),
    goals: normalizeGoals(opts.goals, origin),
    flags: {},
    npcs: { elder_mo: 0, merchant_wang: 0, hunter_tie: 5, healer_qing: meta.friend ? 30 : 0, broker_lian: -5, rival_pei: -8 },
    intel: 0,
    scoutArmed: false,
    formulas: (meta.formulas || []).slice(),
    stats: { kills: 0, bosses: 0, nodes: 0, damage: 0, maxHit: 0, slewForge: false, poisonPlays: 0 },
    act: 0,
    map: null,
    phase: "map",
    journal: [],
    discoveries: [],
    uidCounter: 1,
    removeCost: 46,
    tutorial: (meta.runs || 0) === 0,
    bankedPoints: meta.points || 0,
    pendingFx: null,
    immortal: false,
    victory: false,
    paused: true,
    speed: 1,
    cultivating: null,
    cultPartial: 0,
    side: false,
    pendingAdvance: false,
    activeNode: null,
    event: null,
    shop: null,
    reward: null,
    treasure: null,
    blessed: { plots: [null, null, null], chamber: false, refinery: false, guest: false },
    startSummon: origin.startSummon ? { ...origin.startSummon, perm: true } : null,
    missionDone: {},
    recentEvents: [],
    death: null,
    legacyPool: 0,
    legacyBought: [],
    combat: null,
    combatOver: null,
  };
  if ((origin.npcBonus || 0) > 0) {
    run.npcs.merchant_wang += origin.npcBonus;
    run.npcs.broker_lian += 8;
  }
  const formula = 62 + run.rank * 10;
  run.hpMod = origin.hp - formula + run.hpBonus;
  run.maxHp = formula + run.hpMod;
  run.hp = run.maxHp;
  run.stones = Math.max(8, origin.stones + (blessing.stones || 0) + (burden.stones || 0) + (meta.bonusStones || 0));
  if (blessing.wisdom) run.attainment.wisdom += blessing.wisdom;
  if (meta.insight && meta.insightPath) run.attainment[meta.insightPath] = (run.attainment[meta.insightPath] || 0) + meta.insight;
  for (const id of origin.deck) run.deck.push(mint(run, id));
  if (burden.curse) run.deck.push(mint(run, burden.curse));
  if (blessing.nest) {
    const extra = allCards().filter((c) => c.pool === "reward" && c.rarity === "Uncommon" && c.path === origin.paths[0] && c.rank <= 2);
    if (extra.length) run.deck.push(mint(run, extra[rngInt(run, extra.length)].id));
  }
  if (burden.flag) run.flags[burden.flag] = 1;
  if (meta.startRelic && getRelic(meta.startRelic)) run.relics.push(meta.startRelic);
  run.map = { acts: ACTS.map((_, i) => genAct(run, i)) };
  journal(run, `${run.name} leaves ${origin.name} at age ${origin.age}. ${run.deck.length} Gu rest in the aperture.`);
  return run;
}

function normalizeGoals(goals, origin) {
  const primary = goals?.primary || "path:" + origin.paths[0];
  let secondary = (goals?.secondary || []).filter((g) => g && g !== primary).slice(0, 4);
  if (!secondary.length) secondary = ["lifespan"];
  return { primary, secondary };
}

function genAct(run, index) {
  const def = ACTS[index];
  const rows = [];
  for (let r = 0; r < 6; r++) {
    const row = [];
    for (let i = 0; i < 3; i++) {
      row.push({
        id: `${index}-${r}-${i}`, row: r, i, x: [18, 50, 82][i],
        type: "monster", done: false, links: [],
      });
    }
    rows.push(row);
  }
  for (let r = 0; r < 5; r++) {
    for (const n of rows[r]) {
      for (const m of rows[r + 1]) if (Math.abs(n.i - m.i) <= 1) n.links.push(m.id);
    }
  }
  const boss = {
    id: `${index}-boss`, row: 6, i: 1, x: 50, type: "boss", done: false, links: [],
  };
  for (const n of rows[5]) n.links.push(boss.id);
  const flat = rows.flat();
  const bag = ["monster", "monster", "monster", "monster", "event", "event", "event", "shop", "rest", "cultivate", "elite", "treasure", "monster", "event", "monster", "rest", "monster", "event"];
  for (let i = bag.length - 1; i > 0; i--) {
    const j = rngInt(run, i + 1);
    [bag[i], bag[j]] = [bag[j], bag[i]];
  }
  flat.forEach((n, i) => { n.type = bag[i] || "monster"; });
  for (const n of flat) {
    if (n.row === 0 && n.type !== "monster" && n.type !== "event") n.type = "monster";
    if (n.row <= 2 && (n.type === "elite" || n.type === "treasure")) n.type = "monster";
  }
  const force = (pred, type) => {
    if (flat.some((n) => n.type === type)) return;
    const pool = flat.filter(pred);
    if (pool.length) pool[rngInt(run, pool.length)].type = type;
  };
  force((n) => n.row >= 1 && n.row <= 3, "shop");
  force((n) => n.row >= 2 && n.row <= 4, "rest");
  force((n) => n.row >= 3 && n.row <= 5, "elite");
  force((n) => n.row >= 1 && n.row <= 4, "cultivate");
  force((n) => n.row >= 2 && n.row <= 5, "treasure");
  if (def.forced) {
    for (const [row, type] of Object.entries(def.forced)) {
      for (const n of rows[+row] || []) n.type = type;
    }
  }
  if (index === 4) for (const n of rows[4]) n.type = "auction";
  return { index, id: def.id, name: def.name, blurb: def.blurb, env: def.env, region: def.region, rows, boss, current: null };
}

function actDef(run) { return ACTS[run.act]; }
function actState(run) { return run.map.acts[run.act]; }

export function findNode(act, id) {
  if (!act || !id) return null;
  if (act.boss.id === id) return act.boss;
  for (const row of act.rows) {
    const n = row.find((x) => x.id === id);
    if (n) return n;
  }
  return null;
}

export function availableNodes(run) {
  const act = actState(run);
  if (!act) return [];
  if (!act.current) return act.rows[0].map((n) => n.id);
  const cur = findNode(act, act.current);
  if (!cur || !cur.done) return [];
  return cur.links.slice();
}

function overfull(run) {
  return run.deck.length > slotMax(run);
}

export function dispatch(run, action) {
  if (!action || !action.type) return { ok: false, error: "No action." };
  switch (action.type) {
    case "chooseNode": return chooseNode(run, action.id);
    case "playCard": return combatAction(run, "play", action);
    case "endTurn": return combatAction(run, "end");
    case "flee": return combatAction(run, "flee");
    case "chooseReward": return chooseReward(run, action.index);
    case "continue": return continueOn(run);
    case "buy": return buy(run, action.kind, action.index);
    case "removeCard": return removeCard(run, action.uid);
    case "leave": return leave(run);
    case "rest": return rest(run, action);
    case "cultivate": return cultivate(run, action.mode || "standard");
    case "tick": return tick(run, action.ms || 0);
    case "stopCultivate": return stopCultivate(run);
    case "setSpeed": run.speed = [1, 2, 5].includes(action.speed) ? action.speed : 1; return { ok: true };
    case "pause": run.paused = action.paused !== false; return { ok: true };
    case "eventChoice": return eventChoice(run, action.id);
    case "takeRelic": return takeRelic(run, action.id);
    case "breakthrough": return breakthrough(run, action.spend || 0);
    case "equip": return equip(run, action.uid, true);
    case "unequip": return equip(run, action.uid, false);
    case "setGoals": run.goals = normalizeGoals(action.goals, { paths: run.originPaths }); return { ok: true };
    case "useItem": return useItem(run, action.id);
    case "openBlessed": return openBlessed(run);
    case "blessed": return blessedAct(run, action);
    case "craft": return craft(run, action.id);
    case "dismissTip": run.tutorial = false; return { ok: true };
    case "door": return doorChoice(run, action.id);
    case "retire": return die(run, "You lay the aperture down and let the road go on without you.");
    case "legacy": return legacyBuy(run, action);
    case "commitLegacy": return { ok: true, legacy: exportLegacy(run) };
    default: return { ok: false, error: "Unknown action." };
  }
}

function chooseNode(run, id) {
  if (run.phase !== "map") return { ok: false, error: "Finish what you are doing first." };
  if (overfull(run)) return { ok: false, error: "The aperture is overfull. Unequip a Gu." };
  if (run.breakthroughReady && run.rank < (DICE_CAP[run.act] || 6)) {
    /* allowed to travel while a breakthrough waits */
  }
  const act = actState(run);
  if (!availableNodes(run).includes(id)) return { ok: false, error: "That road is not open." };
  const node = findNode(act, id);
  run.prevNode = act.current;
  act.current = id;
  run.activeNode = id;
  const days = travelDays(run, node.type);
  addDays(run, days, true);
  journal(run, `${days} days on the road to ${nodeLabel(node)}.`);
  if (run.phase === "door") return { ok: true };
  enterNode(run, node);
  return { ok: true };
}

function nodeLabel(node) {
  return ({
    monster: "a fight", elite: "an elite", event: "a meeting", shop: "a market",
    rest: "a rest", cultivate: "a quiet hall", treasure: "a cache", boss: "the act's end",
    blessed: "your blessed land", auction: "Treasure Yellow Heaven", tribulation: "a tribulation",
    tribulationFinal: "a greater tribulation",
  })[node.type] || "the next place";
}

function travelDays(run, type) {
  const base = { monster: 96, elite: 120, event: 78, shop: 42, rest: 50, cultivate: 28, treasure: 70, boss: 88, blessed: 36, auction: 40, tribulation: 100, tribulationFinal: 110 }[type] || 80;
  let n = base + rngInt(run, 24);
  if (hasTag(run, "movement")) n = Math.round(n * (hasCard(run, "gale_stride") ? 0.55 : 0.75));
  return n;
}

function hasTag(run, tag) {
  return run.deck.some((c) => (getCard(c.id).tags || []).includes(tag));
}
function hasCard(run, id) {
  return run.deck.some((c) => c.id === id) || run.stash.some((c) => c.id === id);
}

function addDays(run, n, travel) {
  void travel;
  run.days += Math.max(0, Math.round(n));
  if (run.progress > 0 && run.stage < 3) run.progress = Math.max(0, run.progress - 2);
  checkDoor(run);
}

export function travelPreview(run, type) {
  const base = { monster: 96, elite: 120, event: 78, shop: 42, rest: 50, cultivate: 28, treasure: 70, boss: 88, blessed: 36, auction: 40, tribulation: 100, tribulationFinal: 110 }[type] || 80;
  if (hasTag(run, "movement")) return Math.round(base * (hasCard(run, "gale_stride") ? 0.55 : 0.75));
  return base;
}

function checkDoor(run) {
  if (ageYears(run) >= run.deathAge && !["death", "door", "combat", "legacy", "victory"].includes(run.phase)) {
    run.doorFrom = "map";
    run.phase = "door";
    journal(run, "Your lifespan runs out. The world holds its breath.");
  }
}

function enterNode(run, node) {
  const def = actDef(run);
  if (node.type === "monster" || node.type === "elite" || node.type === "boss" || node.type === "tribulation" || node.type === "tribulationFinal") {
    if (!node.encounter) node.encounter = rollEncounter(run, node);
    const elite = node.type === "elite";
    const opts = {
      env: envFor(run, node),
      elite,
      revealed: !!run.scoutArmed && (elite || node.type === "boss" || node.type.startsWith("tribulation")),
      source: node.type,
    };
    if (opts.revealed) {
      run.scoutArmed = false;
      run._scoutBuff = true;
    }
    beginCombat(run, node.encounter, opts);
    if (run._scoutBuff && run.combat) {
      run.combat.hero.strength += 1;
      run._scoutBuff = false;
    }
    for (const e of node.encounter) run.discoveries.push("enemy:" + e);
    run.phase = "combat";
    return;
  }
  if (node.type === "event") {
    if (!node.eventId) node.eventId = pickEvent(run).id;
    openEvent(run, node.eventId, node.id);
    return;
  }
  if (node.type === "shop" || node.type === "auction") {
    run.shop = buildShop(run, node.type === "auction" ? "immortal" : "stones");
    run.phase = "shop";
    return;
  }
  if (node.type === "rest") { run.phase = "rest"; return; }
  if (node.type === "cultivate") { run.phase = "cultivate"; run.cultivating = null; return; }
  if (node.type === "treasure") {
    run.treasure = { relics: rollRelics(run, 3) };
    run.phase = "treasure";
    return;
  }
  if (node.type === "blessed") {
    run.phase = "blessed";
    run.side = false;
    run.immortal = true;
    return;
  }
  run.phase = "map";
}

function envFor(run, node) {
  if (node.type === "boss" && run.act === 3) return "volcanic";
  if (node.type === "tribulation" || node.type === "tribulationFinal" || (node.type === "boss" && run.act === 4)) return "heaven";
  return actDef(run).env;
}

function rollEncounter(run, node) {
  const def = actDef(run);
  if (node.type === "boss") return def.bosses.slice();
  if (node.type === "tribulation") return ["tribulation_cloud"];
  if (node.type === "tribulationFinal") return ["great_general"];
  if (node.type === "elite") {
    if (run.flags.coveted && run.act === 1 && !run.flags.bountyDone) {
      run.flags.bountyDone = 1;
      return ["bounty_hunter"];
    }
    const pool = def.elites;
    return pool[rngInt(run, pool.length)].slice();
  }
  const pool = def.monsters;
  return pool[rngInt(run, pool.length)].slice();
}

function combatAction(run, kind, action) {
  if (run.phase !== "combat" || !run.combat) return { ok: false, error: "No battle." };
  let res;
  if (kind === "play") res = playCombatCard(run, action.uid, action.target);
  else if (kind === "end") res = endCombatTurn(run);
  else res = fleeCombat(run);
  if (run.combatOver) settleCombat(run);
  return res || { ok: true };
}

function settleCombat(run) {
  const outcome = run.combatOver;
  const combat = run.combat;
  run.combatOver = null;
  if (!outcome || !combat) return;
  for (const [p, n] of Object.entries(combat.pathCounts || {})) {
    run.attainment[p] = (run.attainment[p] || 0) + n * 2;
    if (p === "poison") run.stats.poisonPlays += n;
  }
  if (outcome.outcome === "dead") {
    run.combat = null;
    die(run, outcome.cause || "Slain in battle.");
    return;
  }
  if (outcome.outcome === "flee") {
    run.pendingFx = null;
    journal(run, outcome.rep ? `You flee. Reputation −${outcome.rep}.` : "You flee a stronger foe. No one blames you.");
    run.combat = null;
    const act = actState(run);
    if (act) act.current = run.prevNode || null;
    run.phase = "map";
    checkDoor(run);
    return;
  }
  const dead = combat.enemies.filter((e) => e.hp <= 0);
  run.stats.kills += dead.length;
  if (dead.some((e) => e.boss)) run.stats.bosses += 1;
  if (dead.some((e) => e.fire)) run.stats.slewForge = true;
  let stones = dead.reduce((s, e) => s + (e.stones || 0), 0);
  if (combat.env && combat.env.bounty) stones += combat.env.bounty;
  if (run.relics.includes("clan_token") && dead.some((e) => e.elite || e.boss)) stones += 18;
  run.stones += stones;
  for (const card of run.deck) {
    if (getCard(card.id).path !== "food") card.hunger = Math.min(5, (card.hunger || 0) + 1);
  }
  addProgress(run, dead.some((e) => e.boss) ? 120 : dead.some((e) => e.elite) ? 56 : 32);
  let rankNote = "";
  if (dead.some((e) => e.calamity)) {
    rankUp(run, Math.max(run.rank, 6));
    run.immortal = true;
    run.dao[dead[0].path] = (run.dao[dead[0].path] || 0) + 1;
    rankNote = "The calamity breaks. You are a Gu Immortal. A blessed land opens inside you.";
    journal(run, rankNote);
  }
  for (const e of dead) {
    if (e.grantsRank) {
      rankUp(run, Math.max(run.rank, e.grantsRank));
      run.dao[e.path] = (run.dao[e.path] || 0) + 1;
      rankNote = e.finale ? "The last heaven fails. You are Rank 9." : `Tribulation weathered. You stand at Rank ${run.rank}.`;
      journal(run, rankNote);
    }
  }
  if (dead.some((e) => e.finale)) run.victory = true;
  run._hpEnd = run.hp;
  if (outcome.outcome === "win" && run.pendingFx) {
    const rest = run.pendingFx;
    run.pendingFx = null;
    applyFx(run, rest);
  } else run.pendingFx = null;
  if (dead.some((e) => e.boss || e.grantsRank || e.calamity)) run.hp = run.maxHp;
  let relic = null;
  if (dead.some((e) => e.elite || e.boss) || rngNext(run) < 0.06) relic = rollRelics(run, 1)[0] || null;
  if (relic) {
    run.relics.push(relic);
    run.discoveries.push("relic:" + relic);
  }
  if (dead.some((e) => e.elite || e.boss)) run.materials += 1;
  run.reward = { cards: offerCards(run, 3), stones, relic, materials: dead.some((e) => e.elite || e.boss) ? 1 : 0, rankNote, victory: run.victory };
  for (const id of run.reward.cards) run.discoveries.push("card:" + id);
  run.combat = null;
  run.phase = "reward";
  finishNode(run);
  run.tutorial = false;
}

function openLegacy(run) {
  if (run.legacyOpened) return;
  run.legacyOpened = true;
  run.legacyPool = legacyPoints(run) + (run.bankedPoints || 0);
  run.legacyBought = [];
}

function die(run, cause) {
  run.pendingFx = null;
  run.phase = "death";
  run.death = { cause, rank: run.rank, days: run.days, age: Math.floor(ageYears(run)) };
  openLegacy(run);
  journal(run, cause);
  return { ok: true };
}

export function legacyPoints(run) {
  let p = run.rank * 100;
  if (run.victory) p += 500;
  p += Math.floor(run.days * 0.12);
  p += (run.stats.bosses || 0) * 40;
  if ((run.attainment[focusPath(run)] || 0) >= 140) p += 40;
  return p;
}

function finishNode(run) {
  const act = actState(run);
  if (!act?.current) return;
  const node = findNode(act, act.current);
  if (!node || node.done) return;
  node.done = true;
  run.stats.nodes += 1;
  if (node.type === "boss" && !run.victory) run.pendingAdvance = true;
}

function chooseReward(run, index) {
  if (run.phase !== "reward" || !run.reward) return { ok: false, error: "Nothing to take." };
  if (index >= 0 && run.reward.cards[index]) {
    const id = run.reward.cards[index];
    giveCard(run, id);
    journal(run, `You take ${getCard(id).name}.`);
  } else journal(run, "You leave the Gu where they are.");
  run.reward.taken = true;
  return continueOn(run);
}

function continueOn(run) {
  if (run.phase === "reward") {
    const victory = run.victory;
    run.reward = null;
    if (victory) {
      run.phase = "victory";
      openLegacy(run);
      return { ok: true };
    }
    return { ok: true, ...toMap(run) };
  }
  if (run.phase === "event" && run.event?.resolved) {
    run.event = null;
    finishNode(run);
    return { ok: true, ...toMap(run) };
  }
  if (run.phase === "victory" || run.phase === "death") {
    run.phase = "legacy";
    if (!run.legacyPool) run.legacyPool = legacyPoints(run);
    return { ok: true };
  }
  return { ok: false, error: "Nothing to continue." };
}

function toMap(run) {
  if (run.pendingAdvance) {
    run.pendingAdvance = false;
    return advanceAct(run);
  }
  run.phase = "map";
  checkDoor(run);
  return {};
}

function advanceAct(run) {
  if (run.relics.includes("lifespan_lotus")) {
    run.deathAge += 1;
    journal(run, "The Lifespan Lotus grants a year.");
  }
  for (const plot of run.blessed.plots) if (plot && !plot.ready) plot.ready = true;
  run.hp = run.maxHp;
  run.act += 1;
  if (run.stage === 3 && run.progress >= 100) run.breakthroughReady = nextRankAllowed(run);
  if (run.act >= ACTS.length) {
    run.victory = true;
    run.phase = "victory";
    return {};
  }
  const epoch = { 2: "competition", 3: "verdant", 4: "ancient" }[run.act];
  journal(run, `Act ${run.act + 1}: ${ACTS[run.act].name}.`);
  if (epoch) {
    openEvent(run, epoch, null);
    return {};
  }
  run.phase = "map";
  return {};
}

function offerCards(run, n) {
  const pool = allCards().filter((c) => c.pool === "reward" && c.rank <= run.rank + 1);
  const picked = [];
  const used = new Set();
  while (picked.length < n) {
    const choice = weighted(run, pool.filter((c) => !used.has(c.id)), (c) => cardWeight(run, c));
    if (!choice) break;
    used.add(choice.id);
    picked.push(choice.id);
  }
  return picked;
}

function cardWeight(run, c) {
  let w = c.rarity === "Rare" ? 2.4 : c.rarity === "Uncommon" ? 6 : 10;
  if (c.clan && c.clan !== run.origin) w *= 0.22;
  if (c.clan && c.clan === run.origin) w *= 2.3;
  if (c.rank > run.rank) w *= 0.6;
  const goals = [run.goals.primary, ...run.goals.secondary];
  goals.forEach((g, i) => {
    const mult = i === 0 ? 3 : 1.6;
    if (g === "path:" + c.path) w *= mult;
    if (g === "movement" && (c.tags || []).includes("movement")) w *= mult;
    if (g === "killer" && c.rarity === "Rare") w *= 1.4;
  });
  return w;
}

function weighted(run, items, fn) {
  if (!items.length) return null;
  let total = 0;
  const ws = items.map((it) => {
    const w = Math.max(0.001, fn(it));
    total += w;
    return w;
  });
  let r = rngNext(run) * total;
  for (let i = 0; i < items.length; i++) {
    r -= ws[i];
    if (r <= 0) return items[i];
  }
  return items[items.length - 1];
}

function rollRelics(run, n) {
  const pool = RELICS.filter((r) => !run.relics.includes(r.id));
  const out = [];
  const bag = pool.slice();
  while (out.length < n && bag.length) {
    const i = rngInt(run, bag.length);
    out.push(bag.splice(i, 1)[0].id);
    run.discoveries.push("relic:" + out[out.length - 1]);
  }
  return out;
}

function openEvent(run, id, nodeId) {
  const ev = getEvent(id);
  run.event = { id, nodeId, resolved: null };
  run.phase = "event";
  run.discoveries.push("event:" + id);
  run.recentEvents.push(id);
  run.recentEvents = run.recentEvents.slice(-4);
}

function pickEvent(run) {
  if (run.flags.package && !run.recentEvents.includes("package2")) return getEvent("package2");
  const pool = EVENTS.filter((e) => !e.epoch && !e.requiresFlag && (e.minAct || 0) <= run.act && !run.recentEvents.includes(e.id));
  return weighted(run, pool.length ? pool : EVENTS.filter((e) => !e.epoch), (e) => {
    let w = 1;
    const goals = [run.goals.primary, ...run.goals.secondary];
    if ((e.goals || []).some((g) => goals.includes(g) || goals.includes("path:" + g))) w += 2.2;
    if ((e.goals || []).includes(run.goals.primary)) w += 2;
    return w;
  }) || EVENTS[0];
}

export function adjustedChance(run, choice) {
  if (choice.chance == null) return null;
  const bonus = Math.min(0.12, (run.attainment.wisdom || 0) / 900);
  return Math.max(0.05, Math.min(0.92, choice.chance + bonus));
}

export function chanceText(run, p) {
  if (p == null) return "";
  const w = run.attainment.wisdom || 0;
  if (w >= 100) return `${Math.round(p * 100)}%`;
  if (w >= 50) return p >= 0.7 ? "Likely" : p >= 0.48 ? "Even odds" : "Risky";
  if (w >= 20) return p >= 0.6 ? "Looks promising" : "Seems risky";
  return "Unclear";
}

export function reqReason(run, req) {
  if (!req) return null;
  if (req.stones && run.stones < req.stones) return `Need ${req.stones} stones`;
  if (req.movement && !hasTag(run, "movement")) return "Need a movement Gu equipped";
  if (req.pathCard && !run.deck.some((c) => getCard(c.id).path === req.pathCard)) return `Need a ${req.pathCard} Gu equipped`;
  if (req.notRep != null && run.reputation >= req.notRep) return "Your reputation is too clean";
  return null;
}

function eventChoice(run, id) {
  if (run.phase !== "event" || !run.event) return { ok: false, error: "No event." };
  const ev = getEvent(run.event.id);
  const choice = ev.choices.find((c) => c.id === id);
  if (!choice) return { ok: false, error: "No such choice." };
  const why = reqReason(run, choice.req);
  if (why) return { ok: false, error: why };
  let fx = choice.fx || [];
  let text = choice.result || "Done.";
  if (choice.chance != null) {
    const p = adjustedChance(run, choice);
    if (rngNext(run) > p) {
      fx = choice.failFx || [];
      text = choice.failResult || "It goes badly.";
    }
  }
  const started = applyFx(run, fx);
  if (run.phase === "death" || run.phase === "door") return { ok: true };
  if (started) {
    run.event = null;
    return { ok: true };
  }
  run.event.resolved = text;
  journal(run, text);
  return { ok: true };
}

function scaleEncounter(run, ids) {
  const weak = new Set(["disciple", "bandit", "boar"]);
  if (!ids.every((id) => weak.has(id)) || run.act <= 0) return ids;
  const group = actDef(run).monsters[0];
  return group ? group.slice() : ids;
}

function applyFx(run, list) {
  const steps = list || [];
  let combat = false;
  for (let i = 0; i < steps.length; i++) {
    const step = steps[i];
    if (step.op === "combat") {
      if (run.phase === "death") return combat;
      run.pendingFx = steps.slice(i + 1);
      beginCombat(run, scaleEncounter(run, step.enemies), { env: actDef(run).env, source: "event" });
      run.phase = "combat";
      return true;
    }
    if (step.op === "stones") run.stones = Math.max(0, run.stones + step.n);
    else if (step.op === "hp") {
      run.hp = Math.max(0, run.hp + step.n);
      if (run.hp <= 0) die(run, "The road itself kills you.");
    } else if (step.op === "heal") run.hp = Math.min(run.maxHp, run.hp + step.n);
    else if (step.op === "healPct") run.hp = Math.min(run.maxHp, run.hp + Math.round(run.maxHp * step.n));
    else if (step.op === "reputation") run.reputation = clamp(run.reputation + step.n, -100, 100);
    else if (step.op === "standing") run.standing = clamp(run.standing + step.n, 0, 4);
    else if (step.op === "days") addDays(run, step.n, false);
    else if (step.op === "attain") {
      const path = step.path === "focus" ? focusPath(run) : step.path;
      if (run.attainment[path] != null) run.attainment[path] += step.n;
    } else if (step.op === "progress") addProgress(run, step.n);
    else if (step.op === "gainCard") {
      if (step.id) giveCard(run, step.id);
      else {
        const want = (step.pool || "common").toLowerCase();
        const pool = allCards().filter((c) => c.pool === "reward" && c.rarity.toLowerCase() === want && c.rank <= run.rank + 1);
        const bag = pool.length ? pool : allCards().filter((c) => c.pool === "reward" && c.rank <= run.rank + 1);
        const card = weighted(run, bag, (c) => cardWeight(run, c));
        if (card) giveCard(run, card.id);
      }
    } else if (step.op === "gainRelic") {
      const id = rollRelics(run, 1)[0];
      if (id) run.relics.push(id);
    } else if (step.op === "item") run.items[step.id] = (run.items[step.id] || 0) + (step.n || 1);
    else if (step.op === "material") run.materials += step.n || 1;
    else if (step.op === "intel") run.intel += step.n || 1;
    else if (step.op === "feed") for (const c of run.deck) c.hunger = 0;
    else if (step.op === "hunger") for (const c of run.deck) if (getCard(c.id).path !== "food") c.hunger = Math.min(5, (c.hunger || 0) + step.n);
    else if (step.op === "flag") run.flags[step.key] = step.v;
    else if (step.op === "disposition" && run.npcs[step.npc] != null) run.npcs[step.npc] = clamp((run.npcs[step.npc] || 0) + step.n, -100, 100);
    if (run.phase === "death" || run.phase === "door") return combat;
  }
  return combat;
}

function clamp(n, a, b) { return Math.max(a, Math.min(b, n)); }

function buildShop(run, currency) {
  const cards = offerCards(run, currency === "immortal" ? 4 : 5).map((id) => ({
    id, price: priceOf(run, cardPrice(id), currency), sold: false,
  }));
  const relics = rollRelics(run, 2).map((id) => ({
    id, price: priceOf(run, getRelic(id).rarity === "Rare" ? 168 : getRelic(id).rarity === "Uncommon" ? 128 : 96, currency), sold: false,
  }));
  const itemIds = currency === "immortal" ? ["year_fruit", "minor_relic_gu"] : ["healing_salve", "fodder", "scout_report", "year_fruit"];
  const items = itemIds.map((id) => ({
    id, price: priceOf(run, ITEMS[id].price, currency), sold: false,
  }));
  return { currency, cards, relics, items, removeCost: priceOf(run, run.removeCost, "stones") };
}

function cardPrice(id) {
  const c = getCard(id);
  if (c.rarity === "Rare") return 118;
  if (c.rarity === "Uncommon") return 72;
  return 44;
}

function priceOf(run, base, currency) {
  if (currency === "immortal") return Math.max(1, Math.round(base / 70));
  const aptPrice = { A: -0.1, B: -0.05, C: 0, D: 0.1 }[run.aptitude] || 0;
  let p = base * (1 + run.act * 0.08) * (1 + aptPrice);
  let off = run.discount || 0;
  if (run.relics.includes("abacus")) off += 0.2;
  if (run.deck.some((c) => c.id === "information_network")) off += 0.1;
  if (run.reputation >= 30) off += 0.08;
  if (run.reputation <= -30) off += 0.05;
  return Math.max(1, Math.round(p * (1 - Math.min(0.45, off))));
}

function wallet(run, shop) {
  return shop.currency === "immortal" ? run.immortalStones : run.stones;
}
function pay(run, shop, n) {
  if (shop.currency === "immortal") run.immortalStones -= n;
  else run.stones -= n;
}

function buy(run, kind, index) {
  if (run.phase !== "shop" || !run.shop) return { ok: false, error: "No shop." };
  const list = run.shop[kind];
  const item = list && list[index];
  if (!item || item.sold) return { ok: false, error: "Already gone." };
  if (wallet(run, run.shop) < item.price) {
    const name = kind === "cards" ? getCard(item.id).name : kind === "relics" ? getRelic(item.id).name : (ITEMS[item.id]?.name || "that");
    const short = item.price - wallet(run, run.shop);
    return { ok: false, error: `Need ${short} more for ${name}.` };
  }
  pay(run, run.shop, item.price);
  item.sold = true;
  if (kind === "cards") giveCard(run, item.id);
  else if (kind === "relics") run.relics.push(item.id);
  else run.items[item.id] = (run.items[item.id] || 0) + 1;
  journal(run, "Bought.");
  return { ok: true };
}

function removeCard(run, uid) {
  if (run.phase !== "shop") return { ok: false, error: "The merchant will not do that here." };
  const cost = run.shop.removeCost;
  if (run.stones < cost) return { ok: false, error: "Removal costs " + cost + " stones." };
  const all = run.deck.length + run.stash.length;
  if (all <= 5) return { ok: false, error: "You must keep at least five Gu." };
  const di = run.deck.findIndex((c) => c.uid === uid);
  const si = run.stash.findIndex((c) => c.uid === uid);
  if (di < 0 && si < 0) return { ok: false, error: "That Gu is not yours." };
  if (di >= 0 && run.deck.length <= 5) return { ok: false, error: "Keep at least five Gu equipped." };
  if (di >= 0) run.deck.splice(di, 1);
  else run.stash.splice(si, 1);
  run.stones -= cost;
  run.removeCost += 22;
  run.shop.removeCost = priceOf(run, run.removeCost, "stones");
  return { ok: true };
}

function leave(run) {
  if (run.phase === "shop" || run.phase === "rest" || run.phase === "treasure" || run.phase === "cultivate" || run.phase === "blessed") {
    if (run.side) {
      run.side = false;
      run.phase = "map";
      run.cultivating = null;
      return { ok: true };
    }
    finishNode(run);
    run.cultivating = null;
    run.shop = null;
    run.treasure = null;
    return { ok: true, ...toMap(run) };
  }
  return { ok: false, error: "You cannot leave." };
}

function rest(run, action) {
  if (run.phase !== "rest") return { ok: false, error: "You are not resting." };
  if (action.mode === "heal") {
    const n = Math.round(run.maxHp * 0.32);
    run.hp = Math.min(run.maxHp, run.hp + n);
    journal(run, `You rest and recover ${n} HP.`);
    if (run.blessed.refinery && action.alsoUid) refineCard(run, action.alsoUid);
    return leave(run);
  }
  if (action.mode === "study") {
    const path = action.path || focusPath(run);
    if (!run.attainment[path] && run.attainment[path] !== 0) return { ok: false, error: "Unknown path." };
    run.attainment[path] += 16;
    addDays(run, 18, false);
    journal(run, `You study ${path}. Attainment is now ${attainmentTier(run.attainment[path])}.`);
    return leave(run);
  }
  if (action.mode === "refine") {
    const res = refineCard(run, action.uid);
    if (!res.ok) return res;
    return leave(run);
  }
  if (action.mode === "feed") {
    const hungry = run.deck.filter((c) => (c.hunger || 0) > 0 && getCard(c.id).path !== "food");
    const cost = Math.max(8, hungry.length * 2);
    if (run.stones < cost) return { ok: false, error: `Feeding costs ${cost} stones.` };
    run.stones -= cost;
    for (const c of run.deck) c.hunger = 0;
    journal(run, "Every Gu eats.");
    return leave(run);
  }
  if (action.mode === "mission") {
    if (run.missionDone[run.act]) return { ok: false, error: "The board is empty until the next act." };
    run.missionDone[run.act] = 1;
    openEvent(run, "clan_mission", run.activeNode);
    return { ok: true };
  }
  return { ok: false, error: "Rest how?" };
}

function refineCard(run, uid) {
  const card = run.deck.find((c) => c.uid === uid) || run.stash.find((c) => c.uid === uid);
  if (!card) return { ok: false, error: "Choose a Gu to refine." };
  const def = getCard(card.id);
  if (def.noUpgrade || card.up) return { ok: false, error: "That Gu cannot be refined further." };
  card.up = true;
  journal(run, `${def.name} is refined.`);
  return { ok: true };
}

function cultivate(run, mode) {
  if (run.phase !== "cultivate") return { ok: false, error: "You are not in seclusion." };
  if (mode === "closed") {
    const per = 1.55 * cultMod(run);
    run.cultivating = { mode: "closed", perDayProgress: Math.max(1.2, per), perDayStones: 1 };
    run.paused = false;
    run.speed = 1;
    run.cultPartial = 0;
    return { ok: true };
  }
  const plan = mode === "intensive"
    ? { days: 40, stones: 36, progress: 200, dev: 0.12 }
    : { days: 36, stones: 24, progress: 140, dev: 0 };
  if (run.stones < plan.stones) return { ok: false, error: `This session costs ${plan.stones} stones.` };
  run.stones -= plan.stones;
  addDays(run, plan.days, false);
  let progress = Math.round(plan.progress * cultMod(run));
  if (run.blessed.chamber) progress += 20;
  if (plan.dev && rngNext(run) < plan.dev) {
    run.hp = Math.max(1, run.hp - 8);
    progress = Math.round(progress * 0.7);
    if (rngNext(run) < 0.5) run.attainment[focusPath(run)] += 8;
    journal(run, "Deviation. The aperture kicks. You keep most of the progress and lose blood.");
  } else journal(run, `You cultivate for ${plan.days} days.`);
  const ups = addProgress(run, progress);
  if (ups.length) journal(run, "Stage deepens: " + ups.join(", ") + ".");
  if (run.phase === "door") return { ok: true };
  return leave(run);
}

function tick(run, ms) {
  if (!run.cultivating || run.paused) return { ok: true, idle: true };
  const rate = 8 * (run.speed || 1);
  run.cultPartial += (ms / 1000) * rate;
  let guard = 0;
  while (run.cultPartial >= 1 && guard++ < 40) {
    run.cultPartial -= 1;
    const cost = run.cultivating.perDayStones;
    if (run.stones < cost) {
      journal(run, "The stones run out. Seclusion ends.");
      return stopCultivate(run);
    }
    run.stones -= cost;
    run.days += 1;
    let prog = run.cultivating.perDayProgress;
    if (run.blessed.chamber) prog += 0.35;
    addProgress(run, prog);
    if (ageYears(run) >= run.deathAge) {
      stopCultivate(run, true);
      run.doorFrom = "map";
      run.phase = "door";
      journal(run, "Seclusion ends because your life does.");
      return { ok: true };
    }
  }
  return { ok: true };
}

function stopCultivate(run, silent) {
  if (run.cultivating && !silent && rngNext(run) < 0.3) {
    run.reputation = clamp(run.reputation - 3, -100, 100);
    journal(run, "The world moved while you were gone. A small story paints you as absent.");
  }
  run.cultivating = null;
  run.paused = true;
  if (run.phase === "door") return { ok: true };
  return leave(run);
}

export function addProgress(run, n) {
  if (n <= 0) return [];
  run.progress += n;
  const ups = [];
  while (run.progress >= 100 && run.stage < 3) {
    run.progress -= 100;
    run.stage += 1;
    ups.push(STAGES[run.stage]);
  }
  if (run.stage === 3 && run.progress >= 100) {
    run.progress = 100;
    run.breakthroughReady = nextRankAllowed(run);
  }
  return ups;
}

function nextRankAllowed(run) {
  const next = run.rank + 1;
  if (next >= 6) return false;
  return next <= (DICE_CAP[run.act] ?? 6);
}

export function breakthroughChance(run, spend = 0) {
  const base = BR_BASE[run.rank] ?? 0.4;
  const prep = Math.min(0.22, spend / 180);
  const know = (run.attainment[focusPath(run)] || 0) >= 80 ? 0.08 : 0;
  const old = lifeFraction(run) < 0.3 ? -0.08 : 0;
  return clamp(base + (APT[run.aptitude]?.br || 0) + prep + know + old, 0.06, 0.95);
}

function breakthrough(run, spend) {
  if (run.phase !== "map") return { ok: false, error: "Breakthroughs are attempted on the road, not mid-fight." };
  if (!run.breakthroughReady) return { ok: false, error: "You are not at a bottleneck." };
  spend = Math.max(0, Math.min(spend, run.stones, 80));
  const chance = breakthroughChance(run, spend);
  run.stones -= spend;
  run._lastChance = chance;
  if (rngNext(run) < chance) {
    rankUp(run, run.rank + 1);
    journal(run, `Breakthrough. You are Rank ${run.rank}.`);
    return { ok: true, success: true, chance };
  }
  run.hp = Math.max(1, run.hp - 10);
  run.progress = 72;
  journal(run, "The bottleneck holds. You lose stones, blood, and a little progress.");
  return { ok: true, success: false, chance };
}

function rankUp(run, to) {
  if (to <= run.rank) {
    run.stage = 0;
    run.progress = 0;
    run.breakthroughReady = false;
    return;
  }
  run.rank = to;
  run.stage = 0;
  run.progress = 0;
  run.breakthroughReady = false;
  const hp = 62 + run.rank * 10 + (run.hpMod || 0);
  if (hp > run.maxHp) run.maxHp = hp;
  run.hp = Math.min(run.maxHp, run.hp + Math.round(run.maxHp * 0.35));
  if (run.rank >= run.statsBest) void 0;
}

function takeRelic(run, id) {
  if (run.phase !== "treasure" || !run.treasure) return { ok: false, error: "No cache." };
  if (id && run.treasure.relics.includes(id) && !run.relics.includes(id)) run.relics.push(id);
  else if (!id) run.stones += 24;
  run.treasure = null;
  return leave(run);
}

function equip(run, uid, on) {
  if (run.phase === "combat") return { ok: false, error: "Not during battle." };
  if (on) {
    const i = run.stash.findIndex((c) => c.uid === uid);
    if (i < 0) return { ok: false, error: "Not in the stash." };
    if (run.deck.length >= slotMax(run)) return { ok: false, error: "No aperture slot free." };
    run.deck.push(run.stash.splice(i, 1)[0]);
  } else {
    const i = run.deck.findIndex((c) => c.uid === uid);
    if (i < 0) return { ok: false, error: "Not equipped." };
    if (run.deck.length <= 5) return { ok: false, error: "Keep at least five Gu equipped." };
    run.stash.push(run.deck.splice(i, 1)[0]);
  }
  return { ok: true };
}

function useItem(run, id) {
  if (!run.items[id]) return { ok: false, error: "You do not have that." };
  if (id === "healing_salve") {
    run.items[id] -= 1;
    run.hp = Math.min(run.maxHp, run.hp + 22);
    return { ok: true };
  }
  if (id === "year_fruit") {
    run.items[id] -= 1;
    run.deathAge += 4;
    journal(run, "Four years return to you.");
    if (run.phase === "door") {
      run.phase = run.doorFrom || "map";
      run.doorFrom = null;
    }
    return { ok: true };
  }
  if (id === "fodder") {
    run.items[id] -= 1;
    for (const c of run.deck) c.hunger = 0;
    return { ok: true };
  }
  if (id === "scout_report") {
    if (run.phase === "combat") return { ok: false, error: "Scout before the fight, not during it." };
    run.items[id] -= 1;
    run.scoutArmed = true;
    journal(run, "The next elite or boss is scouted.");
    return { ok: true };
  }
  if (id === "minor_relic_gu") {
    if (run.stage >= 3) return { ok: false, error: "Relic Gu cannot cross a rank. You are already at Peak." };
    run.items[id] -= 1;
    run.stage += 1;
    run.progress = Math.min(run.progress, 99);
    if (run.stage >= 3) run.breakthroughReady = nextRankAllowed(run);
    journal(run, "A stage falls away.");
    return { ok: true };
  }
  return { ok: false, error: "Nothing happens." };
}

function openBlessed(run) {
  if (!run.immortal) return { ok: false, error: "You have no blessed land yet." };
  if (run.phase !== "map") return { ok: false, error: "Open it from the road." };
  run.phase = "blessed";
  run.side = true;
  return { ok: true };
}

function blessedAct(run, action) {
  if (run.phase !== "blessed") return { ok: false, error: "Not in the blessed land." };
  if (action.mode === "plant") {
    const i = action.index;
    if (run.blessed.plots[i]) return { ok: false, error: "That plot is taken." };
    if (run.stones < 24) return { ok: false, error: "Planting costs 24 stones." };
    run.stones -= 24;
    run.blessed.plots[i] = { ready: false };
    return { ok: true };
  }
  if (action.mode === "harvest") {
    const plot = run.blessed.plots[action.index];
    if (!plot?.ready) return { ok: false, error: "Not ripe." };
    run.blessed.plots[action.index] = null;
    run.immortalStones += 1;
    run.materials += 1;
    journal(run, "You harvest an immortal essence stone.");
    return { ok: true };
  }
  if (action.mode === "build") {
    const costs = { chamber: 36, refinery: 36, guest: 24 };
    const key = action.key;
    if (run.blessed[key]) return { ok: false, error: "Already built." };
    if (run.stones < (costs[key] || 99)) return { ok: false, error: "Too costly." };
    run.stones -= costs[key];
    run.blessed[key] = true;
    if (key === "guest") run.npcs.healer_qing = clamp(run.npcs.healer_qing + 20, -100, 100);
    return { ok: true };
  }
  return { ok: false, error: "The land does not understand." };
}

function craft(run, id) {
  if (!["rest", "map", "blessed"].includes(run.phase)) return { ok: false, error: "Refine between battles." };
  const formula = FORMULAS.find((f) => f.id === id);
  if (!formula) return { ok: false, error: "No such formula." };
  if (!run.formulas.includes(id)) return { ok: false, error: "You have not learned that formula." };
  if (run.materials < formula.materials || run.stones < formula.stones) return { ok: false, error: "Need materials and stones." };
  run.materials -= formula.materials;
  run.stones -= formula.stones;
  giveCard(run, id);
  journal(run, `Refined ${getCard(id).name}.`);
  return { ok: true };
}

function doorChoice(run, id) {
  if (run.phase !== "door") return { ok: false, error: "Your life has not run out." };
  if (id === "fruit" && run.items.year_fruit > 0) return useItem(run, "year_fruit");
  if (id === "cling" && run.reputation <= -20) {
    run.deathAge += 1.2;
    run.maxHp = Math.max(20, run.maxHp - 8);
    run.hp = Math.min(run.hp, run.maxHp);
    run.reputation = clamp(run.reputation - 12, -100, 100);
    run.phase = run.doorFrom === "door" ? "map" : (run.doorFrom || "map");
    if (!["map", "shop", "rest", "event", "reward", "cultivate", "blessed", "treasure"].includes(run.phase)) run.phase = "map";
    journal(run, "You cling to life the demonic way. A year, barely, and the body is less than it was.");
    return { ok: true };
  }
  if (id === "die") return die(run, "Old age takes the aperture back.");
  return { ok: false, error: "That door is shut." };
}

function legacyBuy(run, action) {
  if (run.phase !== "legacy") return { ok: false, error: "The inheritance is not open." };
  const item = LEGACY_SHOP.find((s) => s.id === action.id);
  if (!item) return { ok: false, error: "No such inheritance." };
  if (run.legacyBought.some((b) => b.id === action.id && action.id !== "insight" && action.id !== "formula")) {
    return { ok: false, error: "Already written down." };
  }
  if (run.legacyPool < item.cost) return { ok: false, error: "Not enough inheritance." };
  if (action.id === "insight" && !PATH_ORDER.includes(action.path)) return { ok: false, error: "Choose a path." };
  if (action.id === "formula" && !action.card) return { ok: false, error: "Choose a formula." };
  if (action.id === "relic" && !action.relic) return { ok: false, error: "Choose an heirloom." };
  run.legacyPool -= item.cost;
  run.legacyBought.push({ id: action.id, path: action.path, card: action.card, relic: action.relic });
  return { ok: true };
}

export function exportLegacy(run) {
  const meta = newMeta();
  meta.points = run.legacyPool;
  for (const b of run.legacyBought) {
    if (b.id === "cache") meta.bonusStones += 30;
    if (b.id === "years") meta.bonusYears += 2;
    if (b.id === "insight") { meta.insight += 24; meta.insightPath = b.path; }
    if (b.id === "reroll") meta.reroll = true;
    if (b.id === "formula" && b.card) meta.formulas.push(b.card);
    if (b.id === "relic" && b.relic) meta.startRelic = b.relic;
    if (b.id === "plains") meta.unlocks.push("region:plains");
    if (b.id === "central") meta.unlocks.push("region:central");
    if (b.id === "wu") meta.unlocks.push("clan:wu");
    if (b.id === "chi") meta.unlocks.push("clan:chi");
    if (b.id === "connection") meta.friend = true;
  }
  if ((run.attainment.poison || 0) >= 80) meta.unlocks.push("clan:wu");
  if (run.stats.slewForge) meta.unlocks.push("clan:chi");
  meta.wins = run.victory ? 1 : 0;
  meta.bestRank = run.rank;
  meta.seen = run.discoveries.slice();
  meta.runs = 1;
  return meta;
}

export function mergeMeta(base, add) {
  const meta = { ...newMeta(), ...(base || {}) };
  if (!add) return meta;
  meta.points = add.points || 0;
  meta.bonusStones = (meta.bonusStones || 0) + (add.bonusStones || 0);
  meta.bonusYears = (meta.bonusYears || 0) + (add.bonusYears || 0);
  if ((add.insight || 0) >= (meta.insight || 0)) {
    meta.insight = add.insight;
    meta.insightPath = add.insightPath;
  }
  if (add.reroll) meta.reroll = true;
  if (add.friend) meta.friend = true;
  if (add.startRelic) meta.startRelic = add.startRelic;
  meta.formulas = Array.from(new Set([...(meta.formulas || []), ...(add.formulas || [])]));
  meta.unlocks = Array.from(new Set([...(meta.unlocks || []), ...(add.unlocks || [])]));
  meta.runs = (meta.runs || 0) + (add.runs || 0);
  meta.wins = (meta.wins || 0) + (add.wins || 0);
  meta.bestRank = Math.max(meta.bestRank || 1, add.bestRank || 1);
  meta.seen = Array.from(new Set([...(meta.seen || []), ...(add.seen || [])]));
  return meta;
}

export function unlocked(meta, id) {
  return (meta?.unlocks || []).includes(id);
}

export { maxEnergy, FORMULAS, ITEMS };
