import { musicForPhase, play, setBus, setMuted, setVolume } from "./audio.js";
import {
  PATHS, PATH_ORDER, RANK_TITLES, STAGES, attainmentTier, getCard, needsEnemy, needsHandTarget, presentCard,
} from "./cards.js";
import {
  ageLabel, availableKillers, cardEnergy, currentMove, fleeOdds, intentDamage, intentInfo, isNight, lifeFraction, maxEnergy, playError,
} from "./combat.js";
import {
  APT, adjustedChance, ageYears, availableNodes, breakthroughChance, chanceText, createRun, dispatch,
  exportLegacy, focusPath, legacyPoints, mergeMeta, newMeta, repName, reqReason, rollAptitude,
  slotMax, standingName, travelPreview, unlocked,
} from "./run.js";
import {
  ACTS, BLESSINGS, BURDENS, ENEMIES, EVENTS, FORMULAS, GOALS, ITEMS, LEGACY_SHOP, NPCS, ORIGINS, REGIONS, RELICS, getEvent, getRelic,
} from "./world.js";

const SAVE = "ri-run-v1";
const META = "ri-meta-v1";
const SET = "ri-settings-v1";

let run = null;
let meta = load(META, newMeta());
let settings = load(SET, { volume: 0.7, music: 1, sfx: 1, shake: true, mute: false, reduce: false });
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
function validRun(r) {
  return !!(r && r.version === 1 && typeof r.rng === "number" && r.phase && r.map && Array.isArray(r.deck) && typeof r.hp === "number" && typeof r.maxHp === "number" && r.attainment);
}
function saveRun() {
  try {
    if (run) localStorage.setItem(SAVE, JSON.stringify(run));
    localStorage.setItem(META, JSON.stringify(meta));
    localStorage.setItem(SET, JSON.stringify(settings));
  } catch (err) {
    toast("Could not save: " + (err.message || "storage blocked"));
  }
  mirrorFile();
}
let fileDir = "";
async function mirrorFile() {
  if (!window.NL_PORT || !window.Neutralino?.filesystem) return;
  try {
    if (!fileDir) {
      const base = await Neutralino.os.getPath("data");
      fileDir = base.replace(/\\/g, "/") + "/ReverendInsanity";
      try { await Neutralino.filesystem.createDirectory(fileDir); } catch { /* exists */ }
    }
    const body = JSON.stringify({ savedAt: Date.now(), run, meta, settings });
    await Neutralino.filesystem.writeFile(fileDir + "/save.json", body);
  } catch (err) {
    toast("Save file failed: " + (err.message || "disk"));
  }
}
async function loadFile() {
  if (!window.NL_PORT || !window.Neutralino?.filesystem) return null;
  try {
    if (!fileDir) {
      const base = await Neutralino.os.getPath("data");
      fileDir = base.replace(/\\/g, "/") + "/ReverendInsanity";
    }
    const text = await Neutralino.filesystem.readFile(fileDir + "/save.json");
    return JSON.parse(text);
  } catch {
    return null;
  }
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

export async function boot() {
  if (window.matchMedia?.("(prefers-reduced-motion: reduce)").matches) settings.reduce = true;
  setVolume(settings.volume ?? 0.7);
  setMuted(!!settings.mute);
  setBus("music", settings.music ?? 1);
  setBus("sfx", settings.sfx ?? 1);
  if (window.NL_PORT && window.Neutralino) {
    try { Neutralino.init(); } catch { /* browser */ }
    const file = await loadFile();
    if (file?.run && validRun(file.run)) {
      localStorage.setItem(SAVE, JSON.stringify(file.run));
      if (file.meta) meta = file.meta;
      if (file.settings) settings = { ...settings, ...file.settings };
    }
  }
  window.addEventListener("keydown", onKey);
  window.addEventListener("beforeunload", () => { try { saveRun(); } catch { /* ignore */ } });
  window.addEventListener("visibilitychange", () => { if (document.hidden) saveRun(); });
  document.getElementById("root").addEventListener("click", onClick);
  document.getElementById("root").addEventListener("input", onInput);
  document.getElementById("root").addEventListener("pointerover", (e) => {
    const card = e.target.closest?.(".hand .card");
    if (!card) return;
    const cards = [...card.parentElement.querySelectorAll(".card")];
    layoutHand(cards.indexOf(card));
  });
  document.getElementById("root").addEventListener("pointerout", (e) => {
    if (e.target.closest?.(".hand .card")) layoutHand(-1);
  });
  window.addEventListener("resize", () => layoutHand(-1));
  let cultSave = 0;
  setInterval(() => {
    if (run?.cultivating && !run.paused && run.phase === "cultivate") {
      dispatch(run, { type: "tick", ms: 250 });
      if (Date.now() - cultSave > 1000) { saveRun(); cultSave = Date.now(); }
      render();
    }
  }, 250);
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
  if (e.key === "0") {
    const card = run.combat.hand[9];
    if (card) clickCard(card.uid);
  }
}

function onInput(e) {
  const t = e.target;
  if (t.dataset.field === "name" && create) create.name = t.value.slice(0, 24);
  if (t.dataset.field === "volume" || t.dataset.field === "music" || t.dataset.field === "sfx") {
    settings[t.dataset.field] = Number(t.value);
    if (t.dataset.field === "volume") setVolume(settings.volume);
    if (t.dataset.field === "music") setBus("music", settings.music);
    if (t.dataset.field === "sfx") setBus("sfx", settings.sfx);
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
    if (validRun(saved)) { run = saved; screen = "play"; }
    else toast("That save could not be read.");
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
    if (run && ["death", "victory", "legacy"].includes(run.phase)) meta = mergeMeta(meta, exportLegacy(run));
    try { localStorage.removeItem(SAVE); } catch { /* ignore */ }
    run = null;
    screen = "title";
    overlay = null;
    saveRun();
  } else if (data.do === "mute") {
    settings.mute = !settings.mute;
    setMuted(settings.mute);
    saveRun();
  } else if (data.do === "shake") { settings.shake = !settings.shake; saveRun(); }
  else if (data.do === "reduce") { settings.reduce = !settings.reduce; saveRun(); }
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
  const snap = JSON.parse(JSON.stringify(run));
  let res = { ok: false, fx: [] };
  try {
    res = dispatch(run, action) || res;
  } catch (err) {
    run = snap;
    toast(err.message || "That action failed.");
    safeRender();
    return;
  }
  if (!res.ok && res.error) toast(res.error);
  else pending = null;
  if (action.type === "playCard" && res.ok) play("card_play");
  if (action.type === "endTurn") play("ui_click");
  if (run.phase === "death" && lastPhase !== "death") play("death");
  if (run.phase === "victory" && lastPhase !== "victory") play("victory");
  if (run.phase === "legacy" && action.type === "commitLegacy") {
    meta = mergeMeta(meta, exportLegacy(run));
    try { localStorage.removeItem(SAVE); } catch { /* ignore */ }
    run = null;
    screen = "title";
    overlay = null;
    play("notify");
  }
  saveRun();
  safeRender();
  reactFx(res.fx || []);
}
function safeRender() {
  try { render(); }
  catch (err) {
    toast("The screen failed. Returned to the title.");
    run = null;
    screen = "title";
    overlay = null;
    try { render(); } catch { document.getElementById("root").textContent = "The screen failed."; }
  }
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
    el.style.left = ((rect?.left || 400) + (rect?.width || 80) / 2) + "px";
    el.style.top = ((rect?.top || 200) + (rect?.height || 40) * 0.35) + "px";
    el.style.fontSize = (f.n >= 10 ? 34 : 28) + "px";
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
  document.getElementById("app")?.classList.toggle("reduce", !!settings.reduce);
  document.querySelectorAll(".hpbar > span, .pbar > span").forEach((bar) => {
    const pct = bar.dataset.pct;
    if (pct == null) return;
    bar.style.width = pct + "%";
  });
  layoutHand(-1);
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
    <p class="muted" style="font-size:14px">Runs survived: <span style="color:var(--paper)">${meta.wins || 0}</span>. Best rank <span style="color:var(--paper)">${meta.bestRank || 1}</span>. Banked points <span style="color:var(--paper)">${meta.points || 0}</span>.</p>
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
      <div class="path-pips">${o.paths.map((p) => `<span class="chip" style="color:${PATHS[p].ink};border-color:${PATHS[p].color}66">${icon(PATHS[p].icon)} ${esc(PATHS[p].name)}</span>`).join("")}</div>
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
      <span class="chip">${esc(ageLabel(run))} ${Math.round(pct)} <span class="life" title="${left.toFixed(1)} years left"><span style="width:${pct}%"></span></span></span>
      <span class="chip">HP <strong>${run.hp}/${run.maxHp}</strong></span>
      <span class="chip">${icon("coins")} <strong>${Math.floor(run.stones)}</strong></span>
      ${run.immortal ? `<span class="chip">${icon("gems")} <strong>${run.immortalStones}</strong></span>` : ""}
      <span class="chip rep" title="Reputation">Align: ${esc(repName(run.reputation))}</span>
      <span class="chip standing" title="Clan standing">Clan: ${esc(standingName(run.standing))}</span>
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
  const reach = new Set();
  const q = [...avail];
  while (q.length) {
    const id = q.pop();
    if (reach.has(id)) continue;
    reach.add(id);
    (nodes.find((n) => n.id === id)?.links || []).forEach((l) => q.push(l));
  }
  const stateOf = (n) => n.id === act.current && n.done ? "current" : avail.has(n.id) ? "avail" : n.done ? "done" : reach.has(n.id) ? "reach" : "dead";
  const edge = (a, b) => {
    const sa = stateOf(nodes.find((n) => n.id === a) || {}), sb = stateOf(nodes.find((n) => n.id === b) || {});
    if ((sa === "done" || sa === "current") && (sb === "done" || sb === "current" || sb === "avail")) return "taken";
    if (sb === "avail" && (sa === "current" || sa === "done" || !act.current)) return "next";
    if (sa === "dead" || sb === "dead") return "dead";
    return "future";
  };
  const paint = { dead: 'stroke="rgba(226,182,92,.18)" stroke-width="1.5"', future: 'stroke="rgba(226,182,92,.55)" stroke-width="2"', taken: 'stroke="#e2b65c" stroke-width="3"', next: 'stroke="#e2b65c" stroke-width="3" stroke-dasharray="6 6"' };
  const buckets = { dead: [], future: [], taken: [], next: [] };
  for (const n of nodes) for (const id of n.links) {
    const a = pos[n.id], b = pos[id];
    if (!a || !b) continue;
    buckets[edge(n.id, id)].push(`<line x1="${a.x}%" y1="${a.y}%" x2="${b.x}%" y2="${b.y}%" ${paint[edge(n.id, id)]} stroke-linecap="round"/>`);
  }
  const lines = [...buckets.dead, ...buckets.future, ...buckets.taken, ...buckets.next];
  const buttons = nodes.map((n) => {
    const p = pos[n.id];
    const st = stateOf(n);
    const open = avail.has(n.id);
    const shape = n.type === "boss" ? "boss" : n.type === "elite" ? "elite" : n.type === "event" ? "event" : n.type === "rest" ? "rest" : n.type === "cultivate" ? "cultivate" : n.type === "shop" || n.type === "auction" ? "shop" : n.type === "treasure" ? "treasure" : "fight";
    return `<button class="node shape-${shape} ${st} ${n.type === "boss" ? "boss" : ""}" style="left:${p.x}%;top:${p.y}%" ${open ? "" : "disabled"} title="${esc(nodeName(n.type))} · about ${travelPreview(run, n.type)} days" data-act="chooseNode" data-arg='${JSON.stringify({ id: n.id })}'>${icon(nodeIcon(n.type))}<span>${esc(nodeName(n.type))}</span></button>`;
  }).join("");
  const progress = Math.floor(run.progress);
  const goal = GOALS.find((g) => g.id === run.goals.primary);
  const goalPath = goal?.path ? PATHS[goal.path] : null;
  return `<div class="map-wrap"><div class="map"><svg>${lines.join("")}</svg>${buttons}</div>
    <div class="side panel">
      <p class="muted">${esc(def.region)} · Act ${run.act + 1} of ${ACTS.length}</p>
      <h2>${esc(def.name)}</h2>
      <p>${esc(def.blurb)}</p>
      <p>Cultivation <strong>${progress}/100</strong>${run.breakthroughReady ? " · bottleneck" : ""}</p>
      <div class="cultbar"><span style="width:${progress}%"></span></div>
      ${run.breakthroughReady ? `<button class="btn" data-act="ui" data-arg='{"do":"overlay","id":"break"}'>Attempt breakthrough</button>` : ""}
      <p class="muted">Seeking ${goalPath ? icon(goalPath.icon) : ""} ${esc((goalLabel(run.goals.primary) || "").replace(/^Seek /, ""))}.</p>
      <div class="row">
        ${run.immortal ? `<button class="btn-ghost" data-act="openBlessed">Blessed land</button>` : ""}
        <button class="btn-ghost" data-act="ui" data-arg='{"do":"overlay","id":"items"}'>Items</button>
        <button class="btn-ghost" data-act="ui" data-arg='{"do":"overlay","id":"goals"}'>Goals</button>
      </div>
      <div class="legend">${["Fight", "Elite", "Event", "Rest", "Cultivate", "Market", "Cache", "Boss"].map((name) => `<span>${icon(nodeIcon(name === "Fight" ? "monster" : name === "Market" ? "shop" : name === "Cache" ? "treasure" : name === "Boss" ? "boss" : name.toLowerCase()))} ${name}</span>`).join("")}</div>
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
  const foes = c.enemies.filter((e) => e.hp > 0);
  const energy = c.hero.energy;
  const cap = maxEnergy(run);
  const env = c.env;
  const incoming = foes.reduce((s, e) => s + (intentDamage(run, e, currentMove(e))?.total || 0), 0);
  const take = Math.max(0, incoming - c.hero.block);
  const fo = fleeOdds(run);
  const pct = Math.round((fo?.chance || 0) * 100);
  const tier = pct >= 60 ? "good" : pct >= 35 ? "mid" : "bad";
  const ready = c.hand.every((card) => playError(run, card.uid, foes[0]?.uid)) && energy === 0;
  return `<div class="combat">
    <div class="row" style="justify-content:space-between">
      <div><strong>${esc(env.name)}</strong> <span class="chip">${esc(env.note)}</span>${foes.length > 1 ? ` <span class="chip">Outnumbered: attacks +1</span>` : ""}</div>
      <div class="muted">Turn ${c.hero.turn}${run.tutorial ? " · Play a card, then press E. Block a large intent." : ""}</div>
    </div>
    <div class="arena">
      <div class="log">${c.log.slice(0, 4).map((l) => `<div>${esc(l)}</div>`).join("")}</div>
      ${c.enemies.map((e) => enemyHtml(e, c)).join("")}
    </div>
    <div class="you">
      <div class="plate ${c.hero.block ? "blocking" : ""}">
        <div class="orb ${energy ? "" : "empty"}" style="--essence:${essenceColor()}" title="Essence"><b>${energy}</b><small>/${cap}</small></div>
        <div>
          <div class="pbar" data-hero><span style="width:${Math.max(0, run.hp / run.maxHp * 100)}%"></span><em>${run.hp}/${run.maxHp}</em></div>
          <div class="pips">${Array.from({ length: cap }, (_, i) => `<i class="pip ${i < energy ? "on" : ""}" style="--essence:${essenceColor()}"></i>`).join("")}</div>
          <div>${c.hero.block ? `<span class="blk">${icon("shield")}${c.hero.block}</span>` : ""}${c.hero.strength ? statusChip("fist", "#e2b65c", c.hero.strength, "Strength adds to each attack.") : ""}${statusLine(c.hero)}</div>
        </div>
      </div>
      <div>${c.hero.summons.length ? `<div class="summons">${c.hero.summons.map((s) => `<span class="summon">${icon(s.icon)} ${esc(s.name)} ${s.dmg}</span>`).join("")}</div>` : ""}${pending ? `<p class="muted">Choose a target.</p>` : ""}</div>
      <div class="actions">
        ${availableKillers(run).map((k) => `<button class="btn gold" data-act="play" data-arg='${JSON.stringify({ uid: "killer:" + k.id })}'>${esc(k.name)} · ${k.cost}</button>`).join("")}
        ${incoming ? `<div class="incoming">Incoming ${incoming} · Block ${c.hero.block} → take ${take}</div>` : ""}
        <button class="btn end ${ready ? "ready" : ""}" data-act="endTurn">End turn <kbd>E</kbd></button>
        <button class="btn-ghost flee ${tier}" data-act="flee">Flee <b>${pct}%</b>
          <span class="tip">${(fo?.mods || []).map((m) => `<span>${esc(m.label)}</span><span>${m.d > 0 && m !== fo.mods[0] ? "+" : ""}${Math.round(m.d * 100)}%</span>`).join("")}<span>If you fail</span><span>lose the turn, take ${fo?.fail || 0}</span><span>Reputation</span><span>${fo?.rep ? "−" + fo.rep : "none"}</span></span>
        </button>
      </div>
    </div>
    <div class="hand">
      <span class="chip pile left">Draw ${c.draw.length}</span>
      ${c.hand.map((card, i) => cardButton(card, pending === card.uid, i)).join("")}
      <span class="chip pile right">Discard ${c.discard.length} · Exhaust ${c.exhaust.length}</span>
    </div>
  </div>`;
}
function essenceColor() {
  return ["#7d9a6a", "#a64b3c", "#d9d3c7", "#e0b15a", "#9a78c4", "#7ec8c3", "#7ec8c3", "#f0e2b6", "#f0e2b6"][run.rank - 1] || "#e2b65c";
}
function enemyHtml(e, c) {
  const mv = currentMove(e);
  const info = intentInfo(mv);
  const dmg = intentDamage(run, e, mv);
  const dead = e.hp <= 0;
  const pct = Math.max(0, e.hp / e.maxHp * 100);
  const kind = mv?.intent || "wait";
  const num = dmg ? (dmg.hits > 1 ? `${dmg.per}×${dmg.hits}` : String(dmg.per)) : (info.num || "");
  return `<button class="enemy ${pending && !dead ? "targetable" : ""}" data-enemy="${esc(e.uid)}" data-act="target" data-arg='${JSON.stringify({ uid: e.uid })}' ${dead ? "disabled" : ""}>
    ${dead ? "" : `<div class="intent ${esc(kind)}" title="${esc(info.label)} ${esc(info.extra || "")}">${icon(info.icon)} ${esc(num)}</div><div class="muted">${esc(info.label)}</div>`}
    <div class="portrait">${icon(e.icon)}</div>
    <strong>${esc(e.name)}</strong>
    ${info.extra && !dead ? `<div>${statusLine({ poison: mv.poison, bleed: mv.bleed, burn: mv.burn, weak: mv.weak, vulnerable: mv.vulnerable })}</div>` : ""}
    <div class="hpbar"><span data-pct="${pct.toFixed(1)}"></span></div>
    <div class="muted">${Math.max(0, e.hp)}/${e.maxHp} ${e.block ? `<span class="blk">${icon("shield")}${e.block}</span>` : ""}</div>
    <div>${statusLine(e)}</div>
  </button>`;
}
function statusChip(ic, color, n, title) {
  return `<span class="st" style="color:${color}" title="${esc(title)}">${icon(ic)}${n}</span>`;
}
function statusLine(o) {
  const bits = [];
  if (o.poison) bits.push(statusChip("virus", "#a6c46e", o.poison, "Loses this much HP at turn start, then the stack falls by 1."));
  if (o.bleed) bits.push(statusChip("drop", "#e07a86", o.bleed, "Loses this much HP at turn start, then the stack falls by 1."));
  if (o.burn) bits.push(statusChip("flame", "#f0a05a", o.burn, "Takes this much damage at turn end, then the stack falls by 1."));
  if (o.weak) bits.push(statusChip("feather", "#c9b9a1", o.weak, "Deals 25% less attack damage."));
  if (o.vulnerable) bits.push(statusChip("eye", "#ff8f7a", o.vulnerable, "Takes 25% more attack damage."));
  if (o.regen) bits.push(statusChip("lotus", "#a6c46e", o.regen, "Heals this much at turn start."));
  if (o.thorns) bits.push(statusChip("claw", "#c9b9a1", o.thorns, "Deals this much back when hit."));
  if (o.shackle) bits.push(statusChip("hood", "#c39ae6", "", "Its next attack hits itself."));
  return bits.join("");
}
function cardButton(inst, selected, index) {
  const def = presentCard(inst);
  const cost = run?.combat ? cardEnergy(run, inst) : def.cost;
  const foe = run?.combat?.enemies?.find((e) => e.hp > 0)?.uid;
  const err = run?.combat && !String(inst.uid).startsWith("reward") && !String(inst.uid).startsWith("shop") ? playError(run, inst.uid, foe) : null;
  const path = PATHS[def.path] || PATHS.mortal;
  const rare = (def.rarity || "common").toLowerCase();
  const key = index == null ? "" : index < 9 ? String(index + 1) : index === 9 ? "0" : "";
  const rules = esc(def.text).replace(/\b(\d+)\b/g, "<b>$1</b>");
  const shop = String(inst.uid).startsWith("shop");
  const act = String(inst.uid).startsWith("reward") ? "chooseReward" : "play";
  const arg = String(inst.uid).startsWith("reward") ? { index: Number(String(inst.uid).split("-")[1]) } : { uid: inst.uid };
  const tag = shop ? "div" : "button";
  const attrs = shop ? "" : ` data-act="${act}" data-arg='${JSON.stringify(arg)}'`;
  return `<${tag} class="card ${rare} ${def.up ? "up" : ""} ${def.curse ? "curse" : ""} ${selected ? "selected" : ""} ${err ? "dim" : ""}" style="--path:${path.glyph}"${attrs} title="${esc(err || def.text)}">
    <span class="face">
      <span class="cost">${cost}</span>
      <span class="artwin"><i class="gi art" style="-webkit-mask-image:url(assets/icons/${def.icon}.svg);mask-image:url(assets/icons/${def.icon}.svg)"></i></span>
      <span class="cname">${esc(def.name)}${def.up ? '<span class="plus">+</span>' : ""}</span>
      <span class="cmeta">${icon(path.icon)} ${esc(path.name)} · ${esc(def.type)} · Rank ${def.rank}</span>
      <span class="ctext">${rules}</span>
      ${(inst.hunger || 0) >= 3 ? `<span class="cmeta">Starving</span>` : ""}
      ${key ? `<span class="key">${key}</span>` : ""}
    </span>
  </${tag}>`;
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
  const purse = s.currency === "immortal" ? run.immortalStones : run.stones;
  const tile = (item, kind, i, body) => {
    const short = Math.max(0, item.price - purse);
    const poor = !item.sold && short > 0;
    return `<div class="shop-item ${poor ? "poor" : ""} ${item.sold ? "sold" : ""}">
      ${body}
      <button class="btn" style="margin-top:8px" ${item.sold ? "disabled" : ""} ${poor ? 'aria-disabled="true"' : ""} data-act="buy" data-arg='${JSON.stringify({ kind, index: i })}'>${item.sold ? "Sold" : poor ? `Need ${short} more` : `${item.price} ${unit}`}</button>
    </div>`;
  };
  return `<div class="panel" style="overflow:auto"><div class="row" style="justify-content:space-between"><h2>${s.currency === "immortal" ? "Treasure Yellow Heaven" : "Market"}</h2><span class="chip">Stones <strong style="color:var(--gold)">${purse}</strong></span><button class="btn" data-act="leave">Leave</button></div>
    <h3>Gu</h3>
    <div class="shop-grid">${s.cards.map((it, i) => tile(it, "cards", i, cardButton({ uid: "shop-" + i, id: it.id, up: false, hunger: 0 }, false))).join("")}</div>
    <h3>Treasures</h3>
    <div class="shop-grid">${s.relics.map((it, i) => tile(it, "relics", i, `<div class="panel"><strong>${esc(getRelic(it.id).name)}</strong><p>${esc(getRelic(it.id).text)}</p></div>`)).join("")}</div>
    <h3>Supplies</h3>
    <div class="shop-grid">${s.items.map((it, i) => tile(it, "items", i, `<div class="panel"><strong>${esc(ITEMS[it.id].name)}</strong><p>${esc(ITEMS[it.id].text)}</p></div>`)).join("")}</div>
    <h3>Remove a Gu · ${s.removeCost} stones</h3>
    <div class="row">${[...run.deck, ...run.stash].map((c) => `<button class="btn-ghost" data-act="ui" data-arg='${JSON.stringify({ do: "overlay", id: "rm:" + c.uid })}'>${esc(getCard(c.id).name)}</button>`).join("")}</div>
  </div>`;
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
    <p>${win ? "You are a Rank 9 Venerable. The Southern Border will tell this wrong, and that is fine." : esc(run.death?.cause || "The road ends.")}</p>
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
      <p>Seed ${run ? run.seed : "—"}. The game saves itself.</p>
      <p class="muted">Master <input data-field="volume" type="range" min="0" max="1" step="0.05" value="${settings.volume}"/></p>
      <p class="muted">Music <input data-field="music" type="range" min="0" max="1" step="0.05" value="${settings.music ?? 1}"/></p>
      <p class="muted">SFX <input data-field="sfx" type="range" min="0" max="1" step="0.05" value="${settings.sfx ?? 1}"/></p>
      <div class="row">
        <button class="btn-ghost" data-act="ui" data-arg='{"do":"mute"}'>${settings.mute ? "Unmute" : "Mute"}</button>
        <button class="btn-ghost" data-act="ui" data-arg='{"do":"shake"}'>Shake ${settings.shake ? "on" : "off"}</button>
        <button class="btn-ghost" data-act="ui" data-arg='{"do":"reduce"}'>Reduce motion ${settings.reduce ? "on" : "off"}</button>
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
  if (overlay?.startsWith("rm:")) return removeConfirm(overlay.slice(3));
  return "";
}
function removeConfirm(uid) {
  const card = [...run.deck, ...run.stash].find((c) => c.uid === uid);
  if (!card) return "";
  return `<div class="overlay"><div class="panel"><h2>Remove ${esc(getCard(card.id).name)}?</h2>
    <p>This costs ${run.shop?.removeCost || 0} stones and destroys the Gu.</p>
    <div class="row">
      <button class="btn" data-act="removeCard" data-arg='${JSON.stringify({ uid })}'>Destroy it</button>
      <button class="btn-ghost" data-act="ui" data-arg='{"do":"overlay"}'>Keep it</button>
    </div></div></div>`;
}

function helpOverlay() {
  return `<div class="overlay"><div class="panel"><h2>How the road works</h2>
    <p>This is a deckbuilder. Gu are cards. The aperture is the deck you draw in battle. Essence refills every turn. Block fades unless a treasure says otherwise.</p>
    <p>Each path is an engine. Strength wants several attacks in a turn. Poison wants stacks. Blood spends life. Light turns block into a blow. Focus, and Master attainment opens a killer move.</p>
    <p>Between fights the map is the Southern Border. Cultivation spends stones and days to push your rank. Lifespan is short. Year-Fruit Gu and a few treasures buy time. Old age makes your strikes weaker.</p>
    <p>Ranks 1 through 5 are Gu Masters. Ranks 6 through 8 are Gu Immortals. Rank 9 is Venerable. Rank 6 is the Earthly Calamity. After that, the blessed land and two tribulations stand between you and Rank 9.</p>
    <p>Flee shows an exact chance. Failing it loses the turn: the hand is discarded and every living enemy resolves. A fight that lasts 30 turns with no damage is a loss. When you die or win, spend inheritance points. The next life starts a little less blind. Keys: E ends the turn, Esc opens this menu, 1–9 and 0 play cards.</p>
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

const FAN = { W0: 148, gap: 8, minShow: 0.42, minScale: 0.72, maxRot: 3, spread: 24, arc: 18, maxWidth: 1000, pad: 48 };
function layoutHand(hover = -1) {
  document.querySelectorAll(".hand").forEach((hand) => {
    const cards = [...hand.querySelectorAll(":scope > .card")];
    const n = cards.length;
    if (!n) return;
    const H = Math.min(Math.max(120, hand.clientWidth - FAN.pad), FAN.maxWidth);
    let s = 1;
    let step = FAN.W0 + FAN.gap;
    if (n > 1 && n * FAN.W0 + (n - 1) * FAN.gap > H) {
      step = (H - FAN.W0) / (n - 1);
      if (step < FAN.W0 * FAN.minShow) {
        s = Math.max(FAN.minScale, H / (FAN.W0 * (1 + FAN.minShow * (n - 1))));
        step = (H - FAN.W0 * s) / (n - 1);
      }
    }
    const x0 = (hand.clientWidth - (FAN.W0 * s + step * Math.max(0, n - 1))) / 2;
    const rotStep = n > 1 ? Math.min(FAN.maxRot, FAN.spread / (n - 1)) : 0;
    const delta = Math.max(0, Math.min(40, FAN.W0 * s * 1.12 - step));
    cards.forEach((el, i) => {
      const c = i - (n - 1) / 2;
      const t = n > 1 ? c / ((n - 1) / 2) : 0;
      let push = 0;
      if (hover >= 0 && i !== hover) {
        const dist = Math.abs(i - hover);
        const mag = dist === 1 ? delta : dist === 2 ? delta * 0.4 : 0;
        push = i < hover ? -mag : mag;
      }
      el.style.setProperty("--x", (x0 + i * step + push).toFixed(1) + "px");
      el.style.setProperty("--rot", (c * rotStep).toFixed(2) + "deg");
      el.style.setProperty("--dy", (FAN.arc * t * t).toFixed(1) + "px");
      el.style.setProperty("--s", s.toFixed(3));
      el.style.zIndex = String(i + 1);
    });
  });
}

void ENEMIES;
void NPCS;
void focusPath;
