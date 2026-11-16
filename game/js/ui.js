import { play, musicForPhase, setMuted, setVolume } from "./audio.js";
import {
  PATHS, PATH_ORDER, RANK_TITLES, STAGES, attainmentTier, getCard, needsEnemy, needsHandTarget, presentCard,
} from "./cards.js";
import {
  ageLabel, availableKillers, cardEnergy, currentMove, fleeChance, intentInfo, isNight, lifeFraction, maxEnergy, playError,
} from "./combat.js";
import {
  APT, adjustedChance, ageYears, availableNodes, breakthroughChance, chanceText, createRun, dispatch,
  exportLegacy, focusPath, legacyPoints, mergeMeta, newMeta, repName, reqReason, rollAptitude,
  slotMax, standingName, unlocked,
} from "./run.js";
import {
  ACTS, BLESSINGS, BURDENS, ENEMIES, EVENTS, FORMULAS, GOALS, ITEMS, LEGACY_SHOP, NPCS, ORIGINS, REGIONS, RELICS, getEvent, getRelic,
} from "./world.js";

const SAVE = "ri-run-v1";
const META = "ri-meta-v1";
const SET = "ri-settings-v1";

let run = null;
let meta = load(META, newMeta());
let settings = load(SET, { volume: 0.7, shake: true, mute: false });
let screen = "title";
let create = null;
let overlay = null;
let pending = null;
let toastText = "";
let lastPhase = "";

function load(key, fallback) {
  try {
    const raw = localStorage.getItem(key);
    return raw ? JSON.parse(raw) : fallback;
  } catch {
    return fallback;
  }
}
function saveRun() {
  if (run) localStorage.setItem(SAVE, JSON.stringify(run));
  localStorage.setItem(META, JSON.stringify(meta));
  localStorage.setItem(SET, JSON.stringify(settings));
}
function esc(s) {
  return String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
}
function icon(name) {
  const safe = String(name || "scroll").replace(/[^a-z0-9-]/g, "");
  return `<i class="gi" style="-webkit-mask-image:url(assets/icons/${safe}.svg);mask-image:url(assets/icons/${safe}.svg)"></i>`;
}
function toast(msg) {
  toastText = msg;
  setTimeout(() => { if (toastText === msg) { toastText = ""; paintToast(); } }, 2200);
}
function paintToast() {
  let el = document.getElementById("toast");
  if (!toastText) { el?.remove(); return; }
  if (!el) {
    el = document.createElement("div");
    el.id = "toast";
    el.className = "toast";
    document.getElementById("app").appendChild(el);
  }
  el.textContent = toastText;
}

export function boot() {
  setVolume(settings.volume ?? 0.7);
  setMuted(!!settings.mute);
  window.addEventListener("keydown", onKey);
  document.getElementById("root").addEventListener("click", onClick);
  document.getElementById("root").addEventListener("input", onInput);
  setInterval(() => {
    if (run?.cultivating && !run.paused && run.phase === "cultivate") {
      dispatch(run, { type: "tick", ms: 120 });
      render();
    }
  }, 120);
  render();
}

function onKey(e) {
  if (e.key === "Escape") { overlay = overlay ? null : "menu"; render(); }
  if (!run || run.phase !== "combat") return;
  if (e.key === "e" || e.key === "E") { e.preventDefault(); go({ type: "endTurn" }); }
  if (e.key >= "1" && e.key <= "9") {
    const card = run.combat.hand[Number(e.key) - 1];
    if (card) clickCard(card.uid);
  }
}

function onInput(e) {
  const t = e.target;
  if (t.dataset.field === "name" && create) create.name = t.value.slice(0, 24);
  if (t.dataset.field === "volume") {
    settings.volume = Number(t.value);
    setVolume(settings.volume);
    saveRun();
  }
}

function onClick(e) {
  const b = e.target.closest("[data-act]");
  if (!b) return;
  let data = {};
  try { data = JSON.parse(b.dataset.arg || "{}"); } catch { data = {}; }
  const type = b.dataset.act;
  if (type === "ui") return uiAct(data);
  if (type === "play") return clickCard(data.uid);
  if (type === "target") return clickEnemy(data.uid);
  go({ type, ...data });
}

function uiAct(data) {
  if (data.do === "new") {
    screen = "create";
    run = null;
    create = { step: 0, name: "Shen Yuan", region: "south", origin: "guyue", blessing: "iron", burden: "expectation", aptitude: null, rerolled: false, goals: ["path:light", "lifespan"] };
    const roller = { rng: (Date.now() ^ 0x123456) >>> 0 };
    create._rng = roller;
    overlay = null;
  } else if (data.do === "continue") {
    const saved = load(SAVE, null);
    if (saved && saved.version === 1) { run = saved; screen = "play"; }
    overlay = null;
  } else if (data.do === "title") {
    screen = "title";
    overlay = null;
  } else if (data.do === "step") create.step = data.n;
  else if (data.do === "pick") create[data.key] = data.value;
  else if (data.do === "goal") {
    const g = data.id;
    const list = create.goals.filter((x) => x !== g);
    if (create.goals.includes(g)) create.goals = list;
    else if (create.goals.length < 5) create.goals = [...create.goals, g];
  } else if (data.do === "roll") {
    if (!create._rng) create._rng = { rng: 1 };
    create.aptitude = rollAptitude(create._rng);
    if (data.reroll) create.rerolled = true;
  } else if (data.do === "begin") beginRun();
  else if (data.do === "overlay") overlay = data.id || null;
  else if (data.do === "abandon") {
    localStorage.removeItem(SAVE);
    run = null;
    screen = "title";
    overlay = null;
  } else if (data.do === "mute") {
    settings.mute = !settings.mute;
    setMuted(settings.mute);
    saveRun();
  } else if (data.do === "shake") settings.shake = !settings.shake;
  else if (data.do === "help") overlay = "help";
  else if (data.do === "compendium") overlay = "compendium";
  else if (data.do === "select") pending = data.uid;
  play("ui_click");
  render();
}

function beginRun() {
  if (!create.aptitude) create.aptitude = rollAptitude(create._rng || { rng: 1 });
  const primary = create.goals[0] || "path:light";
  run = createRun({
    name: create.name || "Shen Yuan",
    origin: create.origin,
    blessing: create.blessing,
    burden: create.burden,
    aptitude: create.aptitude,
    seed: (create._rng?.rng || Date.now()) >>> 0,
    meta,
    goals: { primary, secondary: create.goals.slice(1) },
  });
  screen = "play";
  saveRun();
  play("notify");
}

function go(action) {
  if (!run) return;
  overlay = null;
  const res = dispatch(run, action);
  if (!res.ok && res.error) toast(res.error);
  else pending = null;
  if (action.type === "playCard") play("card_play");
  if (action.type === "endTurn") play("ui_click");
  if (run.phase === "death" && lastPhase !== "death") play("death");
  if (run.phase === "victory" && lastPhase !== "victory") play("victory");
  if (run.phase === "legacy" && action.type === "commitLegacy") {
    meta = mergeMeta(meta, exportLegacy(run));
    localStorage.removeItem(SAVE);
    run = null;
    screen = "title";
    overlay = null;
    play("notify");
  }
  saveRun();
  render();
  reactFx(res.fx || []);
}

function clickCard(uid) {
  if (!run?.combat) return;
  const inst = run.combat.hand.find((c) => c.uid === uid);
  if (!inst) {
    if (String(uid).startsWith("killer:")) {
      const err = playError(run, uid, null);
      if (err && /target/i.test(err)) { pending = uid; render(); return; }
      go({ type: "playCard", uid, target: run.combat.enemies.find((e) => e.hp > 0)?.uid });
    }
    return;
  }
  const def = presentCard(inst);
  const foes = run.combat.enemies.filter((e) => e.hp > 0);
  if (needsHandTarget(def)) {
    if (!pending || pending === uid) { pending = uid; toast("Choose another Gu in hand."); render(); return; }
    go({ type: "playCard", uid: pending, target: uid });
    return;
  }
  if (foes.length > 1 && needsEnemy(def)) {
    pending = uid;
    render();
    return;
  }
  go({ type: "playCard", uid, target: foes[0]?.uid });
}
function clickEnemy(uid) {
  if (!pending) return;
  go({ type: "playCard", uid: pending, target: uid });
}

function reactFx(list) {
  if (!list?.length || settings.reduce) return;
  const app = document.getElementById("app");
  const mag = Math.max(0, ...list.filter((f) => f.t === "shake").map((f) => f.mag || 6));
  if (mag && settings.shake) {
    app.style.setProperty("--shake", Math.min(16, mag) + "px");
    app.classList.remove("shaking");
    void app.offsetWidth;
    app.classList.add("shaking");
    play(mag >= 12 ? "hit_big" : "hit");
  }
  const layer = document.getElementById("floats");
  for (const f of list) {
    if (f.t === "miss") play("miss");
    if (f.t === "heal") play("heal");
    if (f.t === "block") play("block");
    if (f.t === "dmg" && f.kind === "poison") play("poison");
    if (f.t === "dmg" && f.uid) document.querySelector(`[data-enemy="${f.uid}"]`)?.classList.add("flash");
    if (!["dmg", "heal", "block", "miss"].includes(f.t)) continue;
    const el = document.createElement("div");
    el.className = "float " + (f.t === "dmg" ? "dmg" : f.t);
    el.textContent = f.t === "miss" ? "Miss" : (f.t === "heal" ? "+" : f.t === "block" ? "" : "−") + (f.n ?? "");
    const anchor = f.uid ? document.querySelector(`[data-enemy="${f.uid}"]`) : document.querySelector(".you");
    const rect = anchor?.getBoundingClientRect();
    el.style.left = ((rect?.left || 400) + 40) + "px";
    el.style.top = ((rect?.top || 200) + 20) + "px";
    layer.appendChild(el);
    setTimeout(() => el.remove(), 800);
  }
}

function render() {
  const root = document.getElementById("root");
  const phase = run ? run.phase : screen;
  if (phase !== lastPhase) {
    musicForPhase(phase === "play" ? "map" : phase, !!(run?.combat?.boss));
    lastPhase = phase;
  }
  let html = "";
  if (!run && screen === "title") html = titleScreen();
  else if (!run && screen === "create") html = createScreen();
  else if (run) html = playScreen();
  root.innerHTML = html + (overlay ? overlayHtml() : "");
  paintToast();
  document.querySelectorAll(".hpbar > span").forEach((bar) => {
    const pct = bar.dataset.pct;
    bar.style.width = "0%";
    requestAnimationFrame(() => { bar.style.transition = "width .35s ease"; bar.style.width = pct + "%"; });
  });
}

function titleScreen() {
  const cont = load(SAVE, null);
  return `<div class="screen title-screen">
    <div class="seal">印</div>
    <h1>Reverend Insanity</h1>
    <p class="lede">A roguelike of Gu and appetite. Your aperture is your deck. The Southern Border does not wait while you hesitate, and neither does your lifespan.</p>
    <div class="row">
      <button class="btn" data-act="ui" data-arg='{"do":"new"}'>New cultivation</button>
      ${cont ? `<button class="btn gold" data-act="ui" data-arg='{"do":"continue"}'>Continue</button>` : ""}
      <button class="btn-ghost" data-act="ui" data-arg='{"do":"help"}'>How to play</button>
      <button class="btn-ghost" data-act="ui" data-arg='{"do":"compendium"}'>Records</button>
    </div>
    <p class="muted">Runs survived to the record: ${meta.wins || 0}. Best rank ${meta.bestRank || 1}. Inheritance points banked: ${meta.points || 0}.</p>
  </div>`;
}

function createScreen() {
  const c = create;
  const steps = ["Name", "Origin", "Aptitude", "Blessing", "Burden", "Goals", "Begin"];
  let body = "";
  if (c.step === 0) {
    body = `<h2>What are you called?</h2>
      <p><input data-field="name" value="${esc(c.name)}" maxlength="24" style="font-size:28px;background:transparent;border:0;border-bottom:1px solid var(--gold);width:min(420px,100%)"/></p>
      <div class="choices">${REGIONS.map((r) => {
        const locked = r.unlock && !unlocked(meta, r.unlock);
        return `<button class="choice ${c.region === r.id ? "on" : ""}" ${locked ? "disabled" : ""} data-act="ui" data-arg='${JSON.stringify({ do: "pick", key: "region", value: r.id })}'><h3>${esc(r.name)}</h3><p>${esc(r.text)}</p>${locked ? "<p class='muted'>Locked in the inheritance.</p>" : ""}</button>`;
      }).join("")}</div>`;
  } else if (c.step === 1) {
    const list = ORIGINS.filter((o) => o.region === c.region && (!o.unlock || unlocked(meta, o.unlock)));
    body = `<h2>Choose a banner</h2><div class="choices">${list.map((o) => `<button class="choice ${c.origin === o.id ? "on" : ""}" data-act="ui" data-arg='${JSON.stringify({ do: "pick", key: "origin", value: o.id })}'>
      <h3>${icon(o.icon)} ${esc(o.name)}</h3><p>${esc(o.blurb)}</p>
      <div class="path-pips">${o.paths.map((p) => `<span class="chip" style="color:${PATHS[p].color}">${esc(PATHS[p].name)}</span>`).join("")}</div>
      <p class="muted">Age ${o.age} · ${o.stones} stones · ${o.hp} HP</p></button>`).join("")}</div>`;
  } else if (c.step === 2) {
    if (!c.aptitude) c.aptitude = rollAptitude(c._rng || (c._rng = { rng: (Date.now() >>> 0) || 1 }));
    body = `<h2>The aperture is read</h2><div class="apt">${esc(c.aptitude)}</div>
      <p>${esc(APT[c.aptitude].name)}. Cultivation ×${APT[c.aptitude].cult}, breakthrough ${APT[c.aptitude].br >= 0 ? "+" : ""}${Math.round(APT[c.aptitude].br * 100)}%.</p>
      <p class="muted">The old odds: A 5%, B 15%, C 30%, D 50%. Talent matters. It is not the whole road.</p>
      <div class="row">${meta.reroll && !c.rerolled ? `<button class="btn" data-act="ui" data-arg='{"do":"roll","reroll":true}'>Second reading</button>` : ""}</div>`;
  } else if (c.step === 3) {
    body = `<h2>Take a blessing</h2><div class="choices">${BLESSINGS.map((b) => `<button class="choice ${c.blessing === b.id ? "on" : ""}" data-act="ui" data-arg='${JSON.stringify({ do: "pick", key: "blessing", value: b.id })}'><h3>${esc(b.name)}</h3><p>${esc(b.text)}</p></button>`).join("")}</div>`;
  } else if (c.step === 4) {
    body = `<h2>Accept a burden</h2><div class="choices">${BURDENS.map((b) => `<button class="choice ${c.burden === b.id ? "on" : ""}" data-act="ui" data-arg='${JSON.stringify({ do: "pick", key: "burden", value: b.id })}'><h3>${esc(b.name)}</h3><p>${esc(b.text)}</p></button>`).join("")}</div>`;
  } else if (c.step === 5) {
    body = `<h2>What are you seeking?</h2><p class="muted">Up to five. The first is primary and pulls the world harder.</p><div class="choices">${GOALS.map((g) => `<button class="choice ${c.goals.includes(g.id) ? "on" : ""}" data-act="ui" data-arg='${JSON.stringify({ do: "goal", id: g.id })}'><h3>${esc(g.label)}</h3><p class="muted">${c.goals[0] === g.id ? "Primary" : c.goals.includes(g.id) ? "Secondary" : ""}</p></button>`).join("")}</div>`;
  } else {
    const o = ORIGINS.find((x) => x.id === c.origin);
    body = `<h2>Step onto the road</h2>
      <p><strong>${esc(c.name)}</strong> of the ${esc(o?.name || "")}. ${esc(c.aptitude)}-grade. Blessing: ${esc(BLESSINGS.find((b) => b.id === c.blessing)?.name)}. Burden: ${esc(BURDENS.find((b) => b.id === c.burden)?.name)}.</p>
      <p class="muted">Death is the end of the run. What you learned can be written down afterward.</p>
      <button class="btn" data-act="ui" data-arg='{"do":"begin"}'>Open the aperture</button>`;
  }
  return `<div class="screen"><div class="topbar"><div class="brand">Character <small>Southern Border and beyond</small></div>
    <button class="btn-ghost" data-act="ui" data-arg='{"do":"title"}'>Back</button></div>
    <div class="create"><div class="steps">${steps.map((s, i) => `<button class="${i === c.step ? "on" : ""}" data-act="ui" data-arg='${JSON.stringify({ do: "step", n: i })}'>${i + 1}. ${s}</button>`).join("")}</div>
    <div class="panel" style="overflow:auto">${body}
      <div class="row" style="margin-top:14px">
        ${c.step > 0 ? `<button class="btn-ghost" data-act="ui" data-arg='${JSON.stringify({ do: "step", n: c.step - 1 })}'>Back</button>` : ""}
        ${c.step < 6 ? `<button class="btn" data-act="ui" data-arg='${JSON.stringify({ do: "step", n: c.step + 1 })}'>Continue</button>` : ""}
      </div></div></div></div>`;
}

function playScreen() {
  const phase = run.phase;
  return `${topbar()}<div class="screen" style="padding-top:10px">${
    phase === "map" ? mapScreen()
    : phase === "combat" ? combatScreen()
    : phase === "event" ? eventScreen()
    : phase === "shop" ? shopScreen()
    : phase === "rest" ? restScreen()
    : phase === "cultivate" ? cultivateScreen()
    : phase === "reward" ? rewardScreen()
    : phase === "treasure" ? treasureScreen()
    : phase === "blessed" ? blessedScreen()
    : phase === "door" ? doorScreen()
    : phase === "death" ? endScreen(false)
    : phase === "victory" ? endScreen(true)
    : phase === "legacy" ? legacyScreen()
    : `<p>…</p>`
  }</div>`;
}

function topbar() {
  const age = ageYears(run);
  const left = Math.max(0, run.deathAge - age);
  const pct = Math.max(0, Math.min(100, lifeFraction(run) * 100));
  return `<div class="topbar">
    <div class="brand">${esc(run.name)} <small>${esc(RANK_TITLES[run.rank] || "")} · ${STAGES[run.stage] || ""}</small></div>
    <div class="stats">
      <span class="chip">Age <strong>${age.toFixed(1)}</strong></span>
      <span class="chip">${esc(ageLabel(run))} <span class="life" title="${left.toFixed(1)} years left"><span style="width:${pct}%"></span></span></span>
      <span class="chip">HP <strong>${run.hp}/${run.maxHp}</strong></span>
      <span class="chip">${icon("coins")} <strong>${Math.floor(run.stones)}</strong></span>
      ${run.immortal ? `<span class="chip">${icon("gems")} <strong>${run.immortalStones}</strong></span>` : ""}
      <span class="chip">${esc(repName(run.reputation))}</span>
      <span class="chip">${esc(standingName(run.standing))}</span>
      <span class="chip">Day ${run.days}${isNight(run) ? " · Night" : " · Day"}</span>
    </div>
    <div class="row">
      <button class="iconbtn" data-act="ui" data-arg='{"do":"overlay","id":"aperture"}'>Aperture ${run.deck.length}/${slotMax(run)}</button>
      <button class="iconbtn" data-act="ui" data-arg='{"do":"overlay","id":"menu"}'>Menu</button>
    </div>
  </div>`;
}

function mapScreen() {
  const act = run.map.acts[run.act];
  const def = ACTS[run.act];
  const avail = new Set(availableNodes(run));
  const rows = [...act.rows, [act.boss]];
  const nodes = rows.flat();
  const pos = {};
  rows.forEach((row, r) => {
    const y = 88 - (r / (rows.length - 1)) * 78;
    row.forEach((n) => { pos[n.id] = { x: n.x, y }; });
  });
  const lines = [];
  for (const n of nodes) for (const id of n.links) {
    const a = pos[n.id], b = pos[id];
    if (a && b) lines.push(`<line x1="${a.x}%" y1="${a.y}%" x2="${b.x}%" y2="${b.y}%" stroke="rgba(226,182,92,.35)" stroke-width="2"/>`);
  }
  const buttons = nodes.map((n) => {
    const p = pos[n.id];
    const open = avail.has(n.id);
    const cls = [n.type === "boss" ? "boss" : "", n.done ? "done" : "", open ? "avail" : ""].join(" ");
    return `<button class="node ${cls}" style="left:${p.x}%;top:${p.y}%" ${open ? "" : "disabled"} data-act="chooseNode" data-arg='${JSON.stringify({ id: n.id })}'>${icon(nodeIcon(n.type))}<span>${esc(nodeName(n.type))}</span></button>`;
  }).join("");
  const progress = run.stage === 3 ? `${run.progress}/100 bottleneck` : `${Math.floor(run.progress)}/100`;
  return `<div class="map-wrap"><div class="map"><svg>${lines.join("")}</svg>${buttons}</div>
    <div class="side panel">
      <p class="muted">${esc(def.region)} · Act ${run.act + 1} of ${ACTS.length}</p>
      <h2>${esc(def.name)}</h2>
      <p>${esc(def.blurb)}</p>
      <p>Cultivation <strong>${progress}</strong>. ${run.breakthroughReady ? `<button class="btn" data-act="ui" data-arg='{"do":"overlay","id":"break"}'>Attempt breakthrough</button>` : ""}</p>
      <p class="muted">Seeking: ${esc(goalLabel(run.goals.primary))}.</p>
      <div class="row">
        ${run.immortal ? `<button class="btn-ghost" data-act="openBlessed">Blessed land</button>` : ""}
        <button class="btn-ghost" data-act="ui" data-arg='{"do":"overlay","id":"items"}'>Items</button>
        <button class="btn-ghost" data-act="ui" data-arg='{"do":"overlay","id":"goals"}'>Goals</button>
      </div>
      <h3 style="margin-top:12px">Recent</h3>
      <div class="journal">${run.journal.slice(0, 6).map((l) => `<div>${esc(l)}</div>`).join("") || "<div>The road is quiet.</div>"}</div>
    </div></div>`;
}
function nodeIcon(t) {
  return { monster: "swords", elite: "skull", event: "conversation", shop: "shop", rest: "campfire", cultivate: "lotus", treasure: "treasure", boss: "crown", blessed: "pagoda", auction: "scales", tribulation: "lightning", tribulationFinal: "dragon" }[t] || "compass";
}
function nodeName(t) {
  return { monster: "Fight", elite: "Elite", event: "Event", shop: "Market", rest: "Rest", cultivate: "Cultivate", treasure: "Cache", boss: "Boss", blessed: "Land", auction: "Auction", tribulation: "Heaven", tribulationFinal: "General" }[t] || t;
}
function goalLabel(id) { return GOALS.find((g) => g.id === id)?.label || id; }

function combatScreen() {
  const c = run.combat;
  const foes = c.enemies;
  const energy = c.hero.energy;
  const cap = maxEnergy(run);
  const env = c.env;
  return `<div class="combat">
    <div class="row" style="justify-content:space-between">
      <div><strong>${esc(env.name)}</strong> <span class="muted">${esc(env.note)}</span>${foes.filter((e) => e.hp > 0).length > 1 ? ` <span class="chip">Outnumbered: attacks +2</span>` : ""}</div>
      <div class="muted">Turn ${c.hero.turn}${run.tutorial ? " · Play a card, then press E to end the turn. Block when the intent is large." : ""}</div>
    </div>
    <div class="arena">${foes.map((e) => enemyHtml(e, c)).join("")}</div>
    <div class="you">
      <div>
        <div class="pips">${Array.from({ length: cap }, (_, i) => `<i class="pip ${i < energy ? "on" : ""}" style="--essence:${essenceColor()}"></i>`).join("")}</div>
        <div>HP ${run.hp}/${run.maxHp} · Block ${c.hero.block} · Str ${c.hero.strength}</div>
        <div>${statusLine(c.hero)}</div>
        ${c.hero.summons.length ? `<div class="summons">${c.hero.summons.map((s) => `<span class="summon">${icon(s.icon)} ${esc(s.name)} ${s.dmg}${s.perm ? "" : " · " + s.turns}</span>`).join("")}</div>` : ""}
      </div>
      <div class="log">${c.log.slice(0, 5).map((l) => `<div>${esc(l)}</div>`).join("")}</div>
      <div class="row">
        ${availableKillers(run).map((k) => `<button class="btn gold" data-act="play" data-arg='${JSON.stringify({ uid: "killer:" + k.id })}'>${esc(k.name)} · ${k.cost}</button>`).join("")}
        <button class="btn" data-act="endTurn">End turn</button>
        <button class="btn-ghost" data-act="flee">Flee${chanceText(run, fleeChance(run)) === "Unclear" ? "" : " · " + esc(chanceText(run, fleeChance(run)))}</button>
      </div>
    </div>
    ${pending ? `<p class="muted">Choose a target for the readied Gu.</p>` : ""}
    <div class="hand">${c.hand.map((card) => cardButton(card, pending === card.uid)).join("")}</div>
  </div>`;
}
function essenceColor() {
  return ["#7d9a6a", "#a64b3c", "#d9d3c7", "#e0b15a", "#9a78c4", "#7ec8c3", "#7ec8c3", "#f0e2b6", "#f0e2b6"][run.rank - 1] || "#e2b65c";
}
function enemyHtml(e, c) {
  const mv = currentMove(e);
  const info = intentInfo(mv);
  const dead = e.hp <= 0;
  const pct = Math.max(0, e.hp / e.maxHp * 100);
  return `<button class="enemy ${pending && !dead ? "targetable" : ""}" data-enemy="${esc(e.uid)}" data-act="target" data-arg='${JSON.stringify({ uid: e.uid })}' ${dead ? "disabled" : ""}>
    <div class="portrait">${icon(e.icon)}</div>
    <strong>${esc(e.name)}</strong>
    <div class="muted">${dead ? "Fallen" : esc(info.label)}</div>
    ${dead ? "" : `<div class="intent">${icon(info.icon)} ${esc(info.num)}</div>`}
    ${info.extra && !dead ? `<div class="muted">${esc(info.extra)}</div>` : ""}
    <div class="hpbar"><span data-pct="${pct.toFixed(1)}"></span></div>
    <div class="muted">${Math.max(0, e.hp)}/${e.maxHp}${e.block ? ` · ${e.block} block` : ""}</div>
    <div>${statusLine(e)}</div>
    ${c.revealed && !dead ? `<div class="muted">${e.moves.map((m, i) => (i === e.mi % e.moves.length ? "▸" : "") + (intentInfo(m).num || intentInfo(m).label)).join(" ")}</div>` : ""}
  </button>`;
}
function statusLine(o) {
  const bits = [];
  if (o.poison) bits.push(`Poison ${o.poison}`);
  if (o.bleed) bits.push(`Bleed ${o.bleed}`);
  if (o.burn) bits.push(`Burn ${o.burn}`);
  if (o.weak) bits.push(`Weak ${o.weak}`);
  if (o.vulnerable) bits.push(`Vulnerable ${o.vulnerable}`);
  if (o.strength > 0 && o.maxHp) bits.push(`Str ${o.strength}`);
  if (o.regen) bits.push(`Regen ${o.regen}`);
  if (o.thorns) bits.push(`Thorns ${o.thorns}`);
  if (o.shackle) bits.push("Shackled");
  return bits.map((b) => `<span class="chip">${esc(b)}</span>`).join(" ");
}
function cardButton(inst, selected) {
  const def = presentCard(inst);
  const cost = run.combat ? cardEnergy(run, inst) : def.cost;
  const err = run.combat ? playError(run, inst.uid, run.combat.enemies.find((e) => e.hp > 0)?.uid) : null;
  const path = PATHS[def.path] || PATHS.mortal;
  return `<button class="card ${def.up ? "up" : ""} ${def.curse ? "curse" : ""} ${selected ? "selected" : ""} ${err && !selected ? "dim" : ""}" style="--path:${path.color}" data-act="play" data-arg='${JSON.stringify({ uid: inst.uid })}' title="${esc(err || def.text)}">
    <span class="cost">${cost}</span>
    <i class="gi art" style="-webkit-mask-image:url(assets/icons/${def.icon}.svg);mask-image:url(assets/icons/${def.icon}.svg)"></i>
    <span class="cname">${esc(def.name.replace(/ Gu$/, ""))}</span>
    <span class="cmeta">${esc(path.name)} · ${esc(def.type)} · R${def.rank}</span>
    <span class="ctext">${esc(def.text)}</span>
    ${(inst.hunger || 0) >= 3 ? `<span class="cmeta">Starving</span>` : ""}
  </button>`;
}

function eventScreen() {
  const ev = getEvent(run.event.id);
  if (run.event.resolved) {
    return `<div class="panel"><h2>${esc(ev.title)}</h2><p>${esc(run.event.resolved)}</p><button class="btn" data-act="continue">Continue</button></div>`;
  }
  return `<div class="panel"><p class="muted">${icon(ev.icon)} On the road</p><h2>${esc(ev.title)}</h2><p>${esc(ev.text)}</p>
    <div class="choices">${ev.choices.map((ch) => {
      const why = reqReason(run, ch.req);
      const p = adjustedChance(run, ch);
      const hint = p == null ? "" : chanceText(run, p);
      return `<button class="choice" ${why ? "disabled" : ""} data-act="eventChoice" data-arg='${JSON.stringify({ id: ch.id })}'><h3>${esc(ch.label)}</h3>${hint ? `<p>${esc(hint)}</p>` : ""}${why ? `<p class="muted">${esc(why)}</p>` : ""}</button>`;
    }).join("")}</div></div>`;
}

function shopScreen() {
  const s = run.shop;
  const unit = s.currency === "immortal" ? "immortal stones" : "stones";
  const block = (title, kind, list, label) => `<h3>${title}</h3><div class="choices">${list.map((item, i) => `<button class="choice" ${item.sold ? "disabled" : ""} data-act="buy" data-arg='${JSON.stringify({ kind, index: i })}'><h3>${esc(label(item))}</h3><p>${item.sold ? "Sold" : item.price + " " + unit}</p><p class="muted">${esc(blurb(kind, item))}</p></button>`).join("")}</div>`;
  return `<div class="panel" style="overflow:auto"><div class="row" style="justify-content:space-between"><h2>${s.currency === "immortal" ? "Treasure Yellow Heaven" : "Market"}</h2><button class="btn" data-act="leave">Leave</button></div>
    ${block("Gu", "cards", s.cards, (it) => getCard(it.id).name)}
    ${block("Treasures", "relics", s.relics, (it) => getRelic(it.id).name)}
    ${block("Supplies", "items", s.items, (it) => ITEMS[it.id].name)}
    <h3>Remove a Gu · ${s.removeCost} stones</h3>
    <div class="grid-cards">${[...run.deck, ...run.stash].map((c) => `<button class="btn-ghost" data-act="removeCard" data-arg='${JSON.stringify({ uid: c.uid })}'>${esc(getCard(c.id).name)}</button>`).join("")}</div>
  </div>`;
}
function blurb(kind, item) {
  if (kind === "cards") return getCard(item.id).text;
  if (kind === "relics") return getRelic(item.id).text;
  return ITEMS[item.id].text;
}

function restScreen() {
  const feedCost = Math.max(8, run.deck.filter((c) => (c.hunger || 0) > 0 && getCard(c.id).path !== "food").length * 2);
  return `<div class="panel"><h2>A place to stop</h2><p class="muted">One choice, then the road.</p>
    <div class="choices">
      <button class="choice" data-act="rest" data-arg='{"mode":"heal"}'><h3>Rest</h3><p>Heal ${Math.round(run.maxHp * 0.32)} HP.</p></button>
      <button class="choice" data-act="ui" data-arg='{"do":"overlay","id":"study"}'><h3>Study</h3><p>+16 attainment in a path. A few days pass.</p></button>
      <button class="choice" data-act="ui" data-arg='{"do":"overlay","id":"refine"}'><h3>Refine</h3><p>Upgrade one Gu.</p></button>
      <button class="choice" data-act="rest" data-arg='{"mode":"feed"}'><h3>Feed the aperture</h3><p>${feedCost} stones. Clears hunger.</p></button>
      ${run.missionDone[run.act] ? "" : `<button class="choice" data-act="rest" data-arg='{"mode":"mission"}'><h3>Clan board</h3><p>A mission, if the clan still claims you.</p></button>`}
    </div>
    ${craftBlock()}
  </div>`;
}
function craftBlock() {
  if (!run.formulas.length) return "";
  return `<h3>Formulas</h3><div class="row">${run.formulas.map((id) => {
    const f = FORMULAS.find((x) => x.id === id);
    return `<button class="btn-ghost" data-act="craft" data-arg='${JSON.stringify({ id })}'>${esc(getCard(id).name)} · ${f.materials} mat · ${f.stones} stones</button>`;
  }).join("")}</div>`;
}

function cultivateScreen() {
  if (run.cultivating) {
    return `<div class="panel"><h2>Closed door</h2>
      <p>Days fall like rain. Age ${ageYears(run).toFixed(2)}. Stones ${Math.floor(run.stones)}. Progress ${Math.floor(run.progress)}.</p>
      <div class="life"><span style="width:${Math.min(100, run.progress)}%"></span></div>
      <div class="row">
        <button class="btn" data-act="pause" data-arg='${JSON.stringify({ paused: !run.paused })}'>${run.paused ? "Resume" : "Pause"}</button>
        ${[1, 2, 5].map((s) => `<button class="btn-ghost" data-act="setSpeed" data-arg='${JSON.stringify({ speed: s })}'>${s}×</button>`).join("")}
        <button class="btn gold" data-act="stopCultivate">Open the door</button>
      </div>
      <p class="muted">At 1×, about eight days pass each second. The world notices a long absence.</p>
    </div>`;
  }
  return `<div class="panel"><h2>Cultivation hall</h2>
    <p>Rank ${run.rank} ${STAGES[run.stage]}. Progress ${Math.floor(run.progress)}/100. Aptitude ${run.aptitude}.</p>
    <div class="choices">
      <button class="choice" data-act="cultivate" data-arg='{"mode":"standard"}'><h3>Standard session</h3><p>24 stones, about a month. Steady progress.</p></button>
      <button class="choice" data-act="cultivate" data-arg='{"mode":"intensive"}'><h3>Intensive</h3><p>36 stones. Faster, with a chance of deviation.</p></button>
      <button class="choice" data-act="cultivate" data-arg='{"mode":"closed"}'><h3>Closed door</h3><p>Time runs until you stop or the stones do. You can pause.</p></button>
    </div>
    <button class="btn-ghost" data-act="leave">Leave</button>
  </div>`;
}

function rewardScreen() {
  const r = run.reward;
  return `<div class="panel"><h2>${r.victory ? "The heavens go quiet" : "The fight is over"}</h2>
    <p>+${r.stones} stones.${r.materials ? " Materials +1." : ""} ${r.relic ? `Treasure: ${esc(getRelic(r.relic).name)}. ${esc(getRelic(r.relic).text)}` : ""}</p>
    ${r.rankNote ? `<p>${esc(r.rankNote)}</p>` : ""}
    <p>Choose a Gu, or leave them.</p>
    <div class="hand">${r.cards.map((id, i) => cardButton({ uid: "reward-" + i, id, up: false, hunger: 0 }, false).replace('data-act="play"', 'data-act="chooseReward"').replace(/\{"uid":"reward-\d+"\}/, JSON.stringify({ index: i }))).join("")}</div>
    <button class="btn-ghost" data-act="chooseReward" data-arg='{"index":-1}'>Skip</button>
  </div>`;
}

function treasureScreen() {
  return `<div class="panel"><h2>A sealed cache</h2><div class="choices">${run.treasure.relics.map((id) => {
    const r = getRelic(id);
    return `<button class="choice" data-act="takeRelic" data-arg='${JSON.stringify({ id })}'><h3>${icon(r.icon)} ${esc(r.name)}</h3><p>${esc(r.text)}</p></button>`;
  }).join("")}</div><button class="btn-ghost" data-act="takeRelic" data-arg="{}">Take 24 stones instead</button></div>`;
}

function blessedScreen() {
  const b = run.blessed;
  return `<div class="panel"><h2>Blessed land</h2><p class="muted">Time inside runs kindly. Outside, the tribulation calendar does not.</p>
    <div class="choices">${b.plots.map((p, i) => `<div class="choice"><h3>Plot ${i + 1}</h3><p>${p ? (p.ready ? "Ripe." : "Growing. It ripens when the act turns.") : "Empty."}</p>
      ${p?.ready ? `<button class="btn" data-act="blessed" data-arg='${JSON.stringify({ mode: "harvest", index: i })}'>Harvest</button>` : ""}
      ${!p ? `<button class="btn-ghost" data-act="blessed" data-arg='${JSON.stringify({ mode: "plant", index: i })}'>Plant · 24 stones</button>` : ""}
    </div>`).join("")}</div>
    <div class="row" style="margin-top:10px">
      ${[["chamber", "Cultivation chamber", "Cultivate deeper. 36 stones."], ["refinery", "Refinement room", "36 stones."], ["guest", "Guest hall", "Healer Qing thinks better of you. 24 stones."]].map(([key, name, text]) =>
        `<button class="btn-ghost" ${b[key] ? "disabled" : ""} data-act="blessed" data-arg='${JSON.stringify({ mode: "build", key })}'>${b[key] ? name + " built" : name + " · " + text}</button>`).join("")}
      <button class="btn" data-act="leave">Leave</button>
    </div>
    <p>Dao marks: ${PATH_ORDER.filter((p) => run.dao[p]).map((p) => `${PATHS[p].name} ${run.dao[p]}`).join(", ") || "none yet"}.</p>
  </div>`;
}

function doorScreen() {
  return `<div class="panel"><h2>Death's door</h2>
    <p>The lifespan is spent. There is still a moment in which to answer.</p>
    <div class="choices">
      ${run.items.year_fruit ? `<button class="choice" data-act="door" data-arg='{"id":"fruit"}'><h3>Eat the Year-Fruit</h3><p>Four years. The clean answer.</p></button>` : ""}
      ${run.reputation <= -20 ? `<button class="choice" data-act="door" data-arg='{"id":"cling"}'><h3>Cling</h3><p>A demonic year. The body shrinks. Reputation falls further.</p></button>` : ""}
      <button class="choice" data-act="door" data-arg='{"id":"die"}'><h3>Let go</h3><p>The run ends. An inheritance can be written.</p></button>
    </div></div>`;
}

function endScreen(win) {
  return `<div class="panel"><h2>${win ? "Rank 9" : "The aperture closes"}</h2>
    <p>${win ? "You are a Supreme Venerable. The Southern Border will tell this wrong, and that is fine." : esc(run.death?.cause || "The road ends.")}</p>
    <p>Rank ${run.rank}. ${Math.floor(run.days / 365)} years on the road. Inheritance worth ${legacyPoints(run)}.</p>
    <button class="btn" data-act="continue">Write the inheritance</button></div>`;
}

function legacyScreen() {
  const bought = new Set(run.legacyBought.map((b) => b.id));
  return `<div class="panel" style="overflow:auto"><h2>Inheritance</h2><p>Points left: <strong>${run.legacyPool}</strong>. Unspent points stay in the bank.</p>
    <div class="choices">${LEGACY_SHOP.map((item) => `<button class="choice" ${bought.has(item.id) && !["insight", "formula", "relic"].includes(item.id) ? "disabled" : ""} data-act="ui" data-arg='${JSON.stringify({ do: "overlay", id: "leg:" + item.id })}'><h3>${esc(item.name)}</h3><p>${item.cost} pts</p><p class="muted">${esc(item.text)}</p></button>`).join("")}</div>
    <button class="btn" data-act="commitLegacy">Seal the record</button></div>`;
}

function overlayHtml() {
  if (overlay === "menu") {
    return `<div class="overlay"><div class="panel"><h2>Paused</h2>
      <p>The game saves itself. Volume <input data-field="volume" type="range" min="0" max="1" step="0.05" value="${settings.volume}"/></p>
      <div class="row">
        <button class="btn-ghost" data-act="ui" data-arg='{"do":"mute"}'>${settings.mute ? "Unmute" : "Mute"}</button>
        <button class="btn-ghost" data-act="ui" data-arg='{"do":"shake"}'>Shake ${settings.shake ? "on" : "off"}</button>
        <button class="btn-ghost" data-act="ui" data-arg='{"do":"help"}'>How to play</button>
        <button class="btn-ghost" data-act="retire">Lay down this life</button>
        <button class="btn-ghost" data-act="ui" data-arg='{"do":"abandon"}'>Abandon save</button>
        <button class="btn" data-act="ui" data-arg='{"do":"overlay"}'>Close</button>
      </div></div></div>`;
  }
  if (overlay === "help") return helpOverlay();
  if (overlay === "compendium") return compendium();
  if (overlay === "aperture") return apertureOverlay();
  if (overlay === "items") return itemsOverlay();
  if (overlay === "goals") return goalsOverlay();
  if (overlay === "break") return breakOverlay();
  if (overlay === "study") return pathPick("study");
  if (overlay === "refine") return refineOverlay();
  if (overlay?.startsWith("leg:")) return legacyPick(overlay.slice(4));
  return "";
}

function helpOverlay() {
  return `<div class="overlay"><div class="panel"><h2>How the road works</h2>
    <p>This is a deckbuilder. Gu are cards. The aperture is the deck you draw in battle. Essence refills every turn. Block fades unless a treasure says otherwise.</p>
    <p>Each path is an engine. Strength wants several attacks in a turn. Poison wants stacks. Blood spends life. Light turns block into a blow. Focus, and Master attainment opens a killer move.</p>
    <p>Between fights the map is the Southern Border. Cultivation spends stones and days to push your rank. Lifespan is short. Year-Fruit Gu and a few treasures buy time. Old age makes your strikes weaker.</p>
    <p>Rank 6 is the Earthly Calamity. After that, the blessed land and two tribulations stand between you and Rank 9.</p>
    <p>When you die or win, spend inheritance points. The next life starts a little less blind. Keys: E ends the turn, Esc opens this menu, 1–9 play cards.</p>
    <button class="btn" data-act="ui" data-arg='{"do":"overlay"}'>Close</button></div></div>`;
}
function compendium() {
  const seen = new Set(meta.seen || []);
  return `<div class="overlay"><div class="panel"><h2>Records</h2>
    <p class="muted">Gu you have met. The rest stay unnamed.</p>
    <div class="journal">${[...seen].slice(0, 80).map((s) => `<div>${esc(s)}</div>`).join("") || "<div>Nothing recorded yet.</div>"}</div>
    <button class="btn" data-act="ui" data-arg='{"do":"overlay"}'>Close</button></div></div>`;
}
function apertureOverlay() {
  const cardRow = (list, on) => list.map((c) => `<div>${cardButton(c, false)}<button class="btn-ghost" data-act="${on ? "unequip" : "equip"}" data-arg='${JSON.stringify({ uid: c.uid })}'>${on ? "Unequip" : "Equip"}</button></div>`).join("");
  return `<div class="overlay"><div class="panel"><h2>Aperture ${run.deck.length}/${slotMax(run)}</h2>
    <p class="muted">Only equipped Gu are drawn. Stash is safe and hungry for a slot.</p>
    <h3>Equipped</h3><div class="grid-cards">${cardRow(run.deck, true)}</div>
    <h3>Stash</h3><div class="grid-cards">${cardRow(run.stash, false) || "<p>Empty.</p>"}</div>
    <h3>Attainment</h3><p>${PATH_ORDER.map((p) => `${PATHS[p].name} ${attainmentTier(run.attainment[p] || 0)} (${run.attainment[p] || 0})`).join(" · ")}</p>
    <h3>Treasures</h3><p>${run.relics.map((id) => getRelic(id)?.name).join(", ") || "None."}</p>
    <button class="btn" data-act="ui" data-arg='{"do":"overlay"}'>Close</button></div></div>`;
}
function itemsOverlay() {
  return `<div class="overlay"><div class="panel"><h2>Pack</h2><div class="choices">${Object.entries(ITEMS).map(([id, item]) => `<button class="choice" ${(run.items[id] || 0) ? "" : "disabled"} data-act="useItem" data-arg='${JSON.stringify({ id })}'><h3>${icon(item.icon)} ${esc(item.name)} × ${run.items[id] || 0}</h3><p>${esc(item.text)}</p></button>`).join("")}</div>
    <p>Materials ${run.materials}. Intel reports armed: ${run.scoutArmed ? "yes" : "no"}.</p>
    <button class="btn" data-act="ui" data-arg='{"do":"overlay"}'>Close</button></div></div>`;
}
function goalsOverlay() {
  return `<div class="overlay"><div class="panel"><h2>Goals</h2><p>Primary: ${esc(goalLabel(run.goals.primary))}. Change them any time; the road listens.</p>
    <div class="choices">${GOALS.map((g) => `<button class="choice" data-act="setGoals" data-arg='${JSON.stringify({ goals: { primary: g.id, secondary: run.goals.secondary } })}'><h3>${esc(g.label)}</h3></button>`).join("")}</div>
    <button class="btn" data-act="ui" data-arg='{"do":"overlay"}'>Close</button></div></div>`;
}
function breakOverlay() {
  const spend = Math.min(40, run.stones);
  const chance = breakthroughChance(run, spend);
  return `<div class="overlay"><div class="panel"><h2>Bottleneck</h2>
    <p>Rank ${run.rank} Peak. ${esc(chanceText(run, chance) || "")} ${ (run.attainment.wisdom || 0) >= 100 ? `(${Math.round(chance * 100)}%)` : ""}</p>
    <button class="btn" data-act="breakthrough" data-arg='${JSON.stringify({ spend })}'>Spend ${spend} stones and attempt</button>
    <button class="btn-ghost" data-act="breakthrough" data-arg='{"spend":0}'>Attempt with no extra stones</button>
    <button class="btn-ghost" data-act="ui" data-arg='{"do":"overlay"}'>Not yet</button>
  </div></div>`;
}
function pathPick(mode) {
  return `<div class="overlay"><div class="panel"><h2>Which path?</h2><div class="row">${PATH_ORDER.map((p) => `<button class="btn-ghost" data-act="rest" data-arg='${JSON.stringify({ mode, path: p })}'>${esc(PATHS[p].name)}</button>`).join("")}</div>
    <button class="btn" data-act="ui" data-arg='{"do":"overlay"}'>Close</button></div></div>`;
}
function refineOverlay() {
  const list = [...run.deck, ...run.stash].filter((c) => !c.up && !getCard(c.id).noUpgrade);
  return `<div class="overlay"><div class="panel"><h2>Refine</h2><div class="row">${list.map((c) => `<button class="btn-ghost" data-act="rest" data-arg='${JSON.stringify({ mode: "refine", uid: c.uid })}'>${esc(getCard(c.id).name)}</button>`).join("") || "<p>Nothing left to refine.</p>"}</div>
    <button class="btn" data-act="ui" data-arg='{"do":"overlay"}'>Close</button></div></div>`;
}
function legacyPick(id) {
  const item = LEGACY_SHOP.find((s) => s.id === id);
  let extra = `<button class="btn" data-act="legacy" data-arg='${JSON.stringify({ id })}'>Spend ${item.cost}</button>`;
  if (id === "insight") extra = `<div class="row">${PATH_ORDER.map((p) => `<button class="btn-ghost" data-act="legacy" data-arg='${JSON.stringify({ id, path: p })}'>${esc(PATHS[p].name)}</button>`).join("")}</div>`;
  if (id === "formula") extra = `<div class="row">${FORMULAS.map((f) => `<button class="btn-ghost" data-act="legacy" data-arg='${JSON.stringify({ id, card: f.id })}'>${esc(getCard(f.id).name)}</button>`).join("")}</div>`;
  if (id === "relic") {
    const opts = RELICS.filter((r) => r.rarity !== "Rare");
    extra = `<div class="row">${opts.map((r) => `<button class="btn-ghost" data-act="legacy" data-arg='${JSON.stringify({ id, relic: r.id })}'>${esc(r.name)}</button>`).join("")}</div>`;
  }
  return `<div class="overlay"><div class="panel"><h2>${esc(item.name)}</h2><p>${esc(item.text)}</p>${extra}<button class="btn" data-act="ui" data-arg='{"do":"overlay"}'>Close</button></div></div>`;
}

void ENEMIES;
void NPCS;
void focusPath;
