import { getCard } from "../js/cards.js";
import { availableNodes, createRun, dispatch } from "../js/run.js";
import { EVENTS } from "../js/world.js";

const N = +(process.env.N || 400);
const ORIGIN = process.env.ORIGIN || "guyue";
function fresh(seed) {
  return createRun({ name: "Test", origin: ORIGIN, blessing: process.env.BLESS || "iron", burden: process.env.BURDEN || "debt", aptitude: "C", seed, goals: { primary: "path:" + (process.env.PATH_ || "light"), secondary: ["lifespan"] } });
}
function score(run, inst, incoming) {
  const def = getCard(inst.id);
  if (def.curse || def.unplayable) return 99;
  const block = def.tags?.includes("block") || /Block/.test(def.text);
  if (incoming > run.combat.hero.block + 4 && block) return -10;
  if (def.tags?.includes("attack")) return -5;
  return 0;
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
    if (process.env.FLEEBOT && !c.boss && c.hero.energy === c.hero._e0 && run.hp < run.maxHp * 0.35 && !c._fledTurn?.[c.hero.turn]) {
      (c._fledTurn ||= {})[c.hero.turn] = 1;
      const hp0 = run.hp; FS.tries++;
      const r = dispatch(run, { type: "flee" });
      if (run.phase !== "combat") { if (r.fled) FS.ok++; else FS.failLoss += hp0 - (run.phase === "death" ? 0 : run.hp), FS.fail++; break; }
      FS.fail++; FS.failLoss += hp0 - run.hp;
      continue;
    }
    c.hero._e0 ??= c.hero.energy;
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
  }
}
const fights = [];
const FS = { tries: 0, ok: 0, fail: 0, failLoss: 0 };
function greedyRun(seed) {
  const run = fresh(seed);
  let guard = 0;
  while (!["death", "victory", "legacy"].includes(run.phase) && guard++ < 400) {
    if (run.phase === "combat") {
      const rec = { act: run.act, type: run.combat.boss ? "boss" : run.combat.elite ? "elite" : run.combat.source === "event" ? "event" : "monster", ids: run.combat.enemies.map((e) => e.id).join("+"), hp0: run.hp, max: run.maxHp, rank: run.rank };
      heuristic(run);
      rec.lost = rec.hp0 - (run.phase === "death" ? 0 : run.hp);
      rec.died = run.phase === "death";
      if (!rec.died) rec.lost = rec.hp0 - run._hpEnd;
      fights.push(rec);
    }
    else if (run.phase === "reward") dispatch(run, { type: "chooseReward", index: 0 });
    else if (run.phase === "event") {
      const ev = EVENTS.find((e) => e.id === run.event.id);
      const choice = ev.choices.find((c) => !c.req || (c.req.stones || 0) <= run.stones) || ev.choices[ev.choices.length - 1];
      dispatch(run, { type: "eventChoice", id: choice.id });
      if (run.phase === "event" && run.event?.resolved) dispatch(run, { type: "continue" });
    } else if (run.phase === "shop") dispatch(run, { type: "leave" });
    else if (run.phase === "rest") dispatch(run, { type: "rest", mode: run.hp < run.maxHp * 0.7 ? "heal" : "study", path: process.env.PATH_ || "light" });
    else if (run.phase === "cultivate") dispatch(run, { type: "cultivate", mode: "standard" });
    else if (run.phase === "treasure") dispatch(run, { type: "takeRelic", id: run.treasure.relics[0] });
    else if (run.phase === "blessed") dispatch(run, { type: "leave" });
    else if (run.phase === "door") { run.doorHit = true; dispatch(run, { type: "door", id: "die" }); }
    else if (run.phase === "map") {
      if (run.breakthroughReady) dispatch(run, { type: "breakthrough", spend: Math.min(40, run.stones) });
      const ids = availableNodes(run);
      if (!ids.length) break;
      const act = run.map.acts[run.act];
      const nodes = ids.map((id) => id.endsWith("boss") ? act.boss : act.rows.flat().find((n) => n.id === id));
      const prefer = process.env.ELITE ? ["rest", "elite", "cultivate", "monster", "event", "shop", "treasure", "tribulation", "boss", "blessed", "auction", "tribulationFinal"] : ["rest", "cultivate", "monster", "event", "shop", "elite", "treasure", "tribulation", "boss", "blessed", "auction", "tribulationFinal"];
      nodes.sort((a, b) => prefer.indexOf(a.type) - prefer.indexOf(b.type));
      if (run.hp < run.maxHp * 0.45) {
        const rest = nodes.find((n) => n.type === "rest");
        if (rest) { dispatch(run, { type: "chooseNode", id: rest.id }); continue; }
      }
      dispatch(run, { type: "chooseNode", id: nodes[0].id });
    } else break;
  }
  return run;
}
let wins = 0; const actDeath = [0,0,0,0,0,0]; const killer = {}; const ranksAt = {}; let door = 0;
for (let s = 1; s <= N; s++) {
  const run = greedyRun(s);
  if (run.victory) wins++;
  else {
    actDeath[run.act]++;
    if (run.doorHit) door++;
    const last = fights[fights.length - 1];
    if (last && last.died) killer[last.ids] = (killer[last.ids] || 0) + 1;
  }
}
console.log(`origin ${ORIGIN} N ${N} wins ${wins} (${(100*wins/N).toFixed(1)}%) deathsByAct ${actDeath.join(",")} lifespanDoor ${door}`);
if (process.env.FLEEBOT) console.log(`flee tries ${FS.tries} ok ${FS.ok} (${(100*FS.ok/FS.tries).toFixed(0)}%) fails ${FS.fail} avgHpPerFail ${(FS.failLoss/FS.fail).toFixed(1)}`);
console.log("killers", Object.entries(killer).sort((a,b)=>b[1]-a[1]).map(([k,v])=>k+":"+v).join("  "));
const groups = {};
for (const f of fights) {
  const k = `A${f.act + 1} ${f.type.padEnd(7)} ${f.ids}`;
  const g = groups[k] ||= { n: 0, lost: 0, pct: 0, died: 0, rank: 0 };
  g.n++; g.lost += f.lost; g.pct += f.lost / f.max; g.died += f.died ? 1 : 0; g.rank += f.rank;
}
if (process.env.DETAIL) for (const [k, g] of Object.entries(groups).sort()) {
  if (g.n < 5) continue;
  console.log(`${k.padEnd(40)} n=${String(g.n).padStart(4)} avgLoss=${(g.lost/g.n).toFixed(1).padStart(5)} (${(100*g.pct/g.n).toFixed(0).padStart(3)}%maxHP) death=${(100*g.died/g.n).toFixed(0)}% rank=${(g.rank/g.n).toFixed(1)}`);
}
