import { allCards, getCard, KILLERS } from "../js/cards.js";
import { beginCombat } from "../js/combat.js";
import { availableNodes, createRun, dispatch, exportLegacy, legacyPoints, mergeMeta, newMeta } from "../js/run.js";
import { ACTS, ENEMIES, EVENTS, ORIGINS, RELICS, getEnemy, getEvent, getRelic } from "../js/world.js";

const errors = [];
function bad(msg) { errors.push(msg); }

for (const c of allCards()) {
  if (!c.name.endsWith("Gu") && c.id !== "primeval_brew") bad("name " + c.id);
  if (!c.effects) bad("effects " + c.id);
  for (const e of c.effects) if (!e.op) bad("op " + c.id);
}
for (const o of ORIGINS) {
  for (const id of o.deck) {
    try { getCard(id); } catch { bad("starter " + o.id + " " + id); }
  }
}
for (const a of ACTS) {
  for (const group of [...a.monsters, ...a.elites, a.bosses]) {
    for (const id of group) if (!ENEMIES[id]) bad("enemy " + id);
  }
}
for (const ev of EVENTS) {
  for (const ch of ev.choices) {
    for (const list of [ch.fx, ch.failFx]) {
      for (const step of list || []) {
        if (step.op === "gainCard" && step.id) {
          try { getCard(step.id); } catch { bad("event card " + step.id); }
        }
        if (step.op === "combat") for (const id of step.enemies) if (!ENEMIES[id]) bad("event enemy " + id);
      }
    }
  }
}
for (const k of KILLERS) if (!k.effects?.length) bad("killer " + k.id);

function fresh(seed, extra = {}) {
  return createRun({ name: "Test", origin: "guyue", blessing: "iron", burden: "debt", aptitude: "C", seed, goals: { primary: "path:light", secondary: ["lifespan"] }, ...extra });
}

function sandbox() {
  const run = fresh(3);
  run.rank = 5;
  run.hp = 200;
  run.maxHp = 200;
  run.attainment.light = 200;
  run.attainment.strength = 200;
  run.deck = allCards().filter((c) => c.pool !== "curse").map((c, i) => ({ uid: "s" + i, id: c.id, up: false, hunger: 0 }));
  let crashed = 0;
  for (const card of allCards()) {
    if (card.unplayable) continue;
    beginCombat(run, ["boar"], { env: "forest" });
    run.combat.hand = [{ uid: "only", id: card.id, up: false, hunger: 0, costMod: 0, bonus: 0 }];
    if (card.target === "hand") {
      run.combat.hand.push({ uid: "other", id: "primeval_bolt", up: false, hunger: 0, costMod: 0, bonus: 0 });
    }
    run.combat.hero.energy = 9;
    run.hp = 200;
    const target = card.target === "hand" ? "other" : run.combat.enemies[0].uid;
    try {
      const res = dispatch(run, { type: "playCard", uid: "only", target });
      if (!res.ok && res.error && !/Not enough|Cannot|limit|different|another/.test(res.error)) {
        /* playError refusals are fine */
      }
    } catch (err) {
      crashed++;
      bad("play " + card.id + " " + err.message);
    }
  }
  for (const k of KILLERS) {
    beginCombat(run, ["boar", "wolf"], { env: "plains" });
    run.combat.hero.energy = 9;
    run.hp = 200;
    try {
      dispatch(run, { type: "playCard", uid: "killer:" + k.id, target: run.combat.enemies[0].uid });
    } catch (err) {
      bad("killer " + k.id + " " + err.message);
    }
  }
  return crashed;
}

function heuristic(run) {
  const c = run.combat;
  const foes = c.enemies.filter((e) => e.hp > 0);
  let guard = 0;
  while (run.phase === "combat" && guard++ < 500) {
    const incoming = foes.reduce((s, e) => {
      if (e.hp <= 0) return s;
      const m = e.moves[e.mi % e.moves.length];
      if (m.intent === "attack" || m.dmg) return s + (m.dmg || 0) * (m.hits || 1);
      return s;
    }, 0);
    let played = false;
    const hand = c.hand.slice().sort((a, b) => score(run, a, incoming) - score(run, b, incoming));
    for (const card of hand) {
      const target = (c.enemies.find((e) => e.hp > 0) || {}).uid;
      const handTarget = c.hand.find((h) => h.uid !== card.uid)?.uid;
      const res = dispatch(run, { type: "playCard", uid: card.uid, target: getCard(card.id).target === "hand" ? handTarget : target });
      if (res.ok) { played = true; break; }
    }
    if (run.phase !== "combat") break;
    if (!played) dispatch(run, { type: "endTurn" });
    if (run.phase !== "combat") break;
  }
  if (run.phase === "combat") bad("stalemate turn " + (run.combat?.hero?.turn));
}

function score(run, inst, incoming) {
  const def = getCard(inst.id);
  if (def.curse || def.unplayable) return 99;
  const block = def.tags?.includes("block") || /Block/.test(def.text);
  if (incoming > run.combat.hero.block + 4 && block) return -10;
  if (def.tags?.includes("attack")) return -5;
  return 0;
}

function act1() {
  let wins = 0;
  let fights = 0;
  for (let s = 1; s <= 60; s++) {
    const run = fresh(s);
    const node = run.map.acts[0].rows[0].find((n) => n.type === "monster");
    if (!node) continue;
    dispatch(run, { type: "chooseNode", id: node.id });
    if (run.phase !== "combat") continue;
    fights++;
    heuristic(run);
    if (run.phase === "reward") wins++;
  }
  return { wins, fights, rate: fights ? wins / fights : 0 };
}

function greedyRun(seed, record) {
  const run = fresh(seed);
  let guard = 0;
  while (!["death", "victory", "legacy"].includes(run.phase) && guard++ < 400) {
    if (run.phase === "combat") {
      const rec = record ? { boss: !!run.combat.boss, ids: run.combat.enemies.map((e) => e.id).join("+") } : null;
      heuristic(run);
      if (rec) { rec.died = run.phase === "death"; record.push(rec); }
    }
    else if (run.phase === "reward") dispatch(run, { type: "chooseReward", index: 0 });
    else if (run.phase === "event") {
      const ev = EVENTS.find((e) => e.id === run.event.id);
      const choice = ev.choices.find((c) => !c.req || (c.req.stones || 0) <= run.stones) || ev.choices[ev.choices.length - 1];
      dispatch(run, { type: "eventChoice", id: choice.id });
      if (run.phase === "event" && run.event?.resolved) dispatch(run, { type: "continue" });
    } else if (run.phase === "shop") dispatch(run, { type: "leave" });
    else if (run.phase === "rest") dispatch(run, { type: "rest", mode: run.hp < run.maxHp * 0.7 ? "heal" : "study", path: "light" });
    else if (run.phase === "cultivate") dispatch(run, { type: "cultivate", mode: "standard" });
    else if (run.phase === "treasure") dispatch(run, { type: "takeRelic", id: run.treasure.relics[0] });
    else if (run.phase === "blessed") dispatch(run, { type: "leave" });
    else if (run.phase === "door") dispatch(run, { type: "door", id: "die" });
    else if (run.phase === "map") {
      if (run.breakthroughReady) dispatch(run, { type: "breakthrough", spend: Math.min(40, run.stones) });
      const ids = availableNodes(run);
      if (!ids.length) { bad("no nodes seed " + seed + " act " + run.act); break; }
      const act = run.map.acts[run.act];
      const nodes = ids.map((id) => id.endsWith("boss") ? act.boss : act.rows.flat().find((n) => n.id === id));
      const prefer = ["rest", "cultivate", "monster", "event", "shop", "elite", "treasure", "tribulation", "boss", "blessed", "auction", "tribulationFinal"];
      nodes.sort((a, b) => prefer.indexOf(a.type) - prefer.indexOf(b.type));
      if (run.hp < run.maxHp * 0.45) {
        const rest = nodes.find((n) => n.type === "rest");
        if (rest) { dispatch(run, { type: "chooseNode", id: rest.id }); continue; }
      }
      dispatch(run, { type: "chooseNode", id: nodes[0].id });
    } else bad("stuck " + run.phase);
  }
  return run;
}

sandbox();
const wr = act1();
const runs = [];
for (const s of [1, 2, 7, 11, 21]) {
  try {
    const run = greedyRun(s);
    runs.push(`${s}: ${run.phase} rank ${run.rank} act ${run.act} hp ${run.hp} stones ${Math.round(run.stones)}`);
    const meta = mergeMeta(newMeta(), exportLegacy(run));
    if (!meta.runs) bad("meta");
    JSON.parse(JSON.stringify(run));
  } catch (err) {
    bad("run " + s + " " + (err.stack || err.message));
  }
}

const zero = createRun({ name: "Test", origin: "guyue", blessing: "iron", burden: "debt", aptitude: "C", seed: 0, goals: { primary: "path:light", secondary: ["lifespan"] } });
if (zero.seed !== 0) bad("seed 0 was rewritten");
const zeroAgain = createRun({ name: "Test", origin: "guyue", blessing: "iron", burden: "debt", aptitude: "C", seed: 0, goals: { primary: "path:light", secondary: ["lifespan"] } });
if (zeroAgain.seed !== 0 || zeroAgain.rng !== zero.rng) bad("seed 0 not deterministic");
const bankMeta = newMeta();
bankMeta.points = 250;
const banked = createRun({ name: "Test", origin: "guyue", blessing: "iron", burden: "debt", aptitude: "C", seed: 3, meta: bankMeta, goals: { primary: "path:light", secondary: ["lifespan"] } });
if (banked.bankedPoints !== 250) bad("banked points missing");
dispatch(banked, { type: "retire" });
if (banked.legacyPool !== legacyPoints(banked) + 250) bad("banked points not spendable");
const once = mergeMeta(newMeta(), exportLegacy(banked));
const twice = mergeMeta(once, exportLegacy(banked));
if (twice.points !== once.points) bad("mergeMeta added points");
const door = fresh(1);
door.days = Math.ceil((door.deathAge - door.startAge) * 365) - 5;
const doorNode = availableNodes(door)[0];
dispatch(door, { type: "chooseNode", id: doorNode });
if (door.phase !== "door" || door.combat) bad("travel past death age entered the node");
const snap = JSON.parse(JSON.stringify(fresh(9)));
if (snap.seed !== 9 || !Array.isArray(snap.deck) || typeof snap.rng !== "number") bad("json roundtrip");
const a = greedyRun(4);
const b = greedyRun(4);
if (a.phase !== b.phase || a.hp !== b.hp || a.rank !== b.rank || a.days !== b.days || a.rng !== b.rng) bad("seed 4 not deterministic");
try { getEnemy("no-such-enemy"); bad("getEnemy did not throw"); } catch { /* expected */ }
try { getRelic("no-such-relic"); bad("getRelic did not throw"); } catch { /* expected */ }
try { getEvent("no-such-event"); bad("getEvent did not throw"); } catch { /* expected */ }

const fights = [];
let guyueWins = 0;
const GATE = +(process.env.GATE || 300);
for (let s = 1; s <= GATE; s++) {
  const run = greedyRun(s, fights);
  if (run.victory) guyueWins++;
}
const winRate = guyueWins / GATE;
if (!process.env.NO_GATE && (winRate < 0.3 || winRate > 0.5)) bad(`Gu Yue greedy win rate ${winRate.toFixed(3)} left 30–50%`);
const groups = {};
for (const f of fights) {
  if (f.boss) continue;
  const g = groups[f.ids] ||= { n: 0, died: 0 };
  g.n++;
  if (f.died) g.died++;
}
for (const [id, g] of Object.entries(groups)) {
  if (g.n >= 8 && g.died / g.n > 0.15) bad(`encounter ${id} killed ${(100 * g.died / g.n).toFixed(0)}% of ${g.n}`);
}

console.log("act1", wr.wins + "/" + wr.fights, wr.rate.toFixed(2));
console.log(runs.join("\n"));
console.log("legacy sample", legacyPoints(fresh(1)));
console.log("guyue", guyueWins + "/" + GATE, winRate.toFixed(3));
if (errors.length) {
  console.log("ERRORS", errors.length);
  console.log(errors.slice(0, 40).join("\n"));
  process.exit(1);
}
console.log("ok");
