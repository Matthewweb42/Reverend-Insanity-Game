/** Sample playback for the 16 AUDIO_HOOKS. Files live under assets/audio/. */

export const AUDIO_HOOKS = [
  { id: "ui_click", kind: "sfx", desc: "Soft woodblock tick for buttons and map seals." },
  { id: "card_play", kind: "sfx", desc: "Paper snap when a Gu card is activated." },
  { id: "hit", kind: "sfx", desc: "Dull impact for ordinary damage." },
  { id: "hit_big", kind: "sfx", desc: "Heavier impact for crits and killer moves." },
  { id: "block", kind: "sfx", desc: "Ceramic clack when block absorbs a hit." },
  { id: "heal", kind: "sfx", desc: "High soft chime for healing." },
  { id: "poison", kind: "sfx", desc: "Quiet wet tick for poison and bleed." },
  { id: "miss", kind: "sfx", desc: "Short air swipe when an attack misses." },
  { id: "notify", kind: "sfx", desc: "Small bell for events, rank-ups, and rewards." },
  { id: "death", kind: "sfx", desc: "Low falling tone when a run ends." },
  { id: "victory", kind: "sfx", desc: "Five-note rise when Rank 9 is reached." },
  { id: "music_title", kind: "music", desc: "Guzheng bed for the title." },
  { id: "music_map", kind: "music", desc: "Travel bed for the road." },
  { id: "music_combat", kind: "music", desc: "Pulse for ordinary fights and elites." },
  { id: "music_boss", kind: "music", desc: "Lower bed for bosses and tribulations." },
  { id: "music_blessed", kind: "music", desc: "Koto bed for the blessed land." },
];

const FILES = {
  ui_click: [1, 2, 3].map((n) => `assets/audio/sfx/sfx_ui_click_0${n}.ogg`),
  card_play: [1, 2, 3].map((n) => `assets/audio/sfx/sfx_card_play_0${n}.ogg`),
  hit: [1, 2, 3].map((n) => `assets/audio/sfx/sfx_hit_0${n}.ogg`),
  hit_big: [1, 2, 3].map((n) => `assets/audio/sfx/sfx_hit_big_0${n}.ogg`),
  block: [1, 2, 3].map((n) => `assets/audio/sfx/sfx_block_0${n}.ogg`),
  heal: [1, 2, 3].map((n) => `assets/audio/sfx/sfx_heal_0${n}.ogg`),
  poison: [1, 2, 3].map((n) => `assets/audio/sfx/sfx_poison_0${n}.ogg`),
  miss: [1, 2, 3].map((n) => `assets/audio/sfx/sfx_miss_0${n}.ogg`),
  notify: [1, 2, 3].map((n) => `assets/audio/sfx/sfx_notify_0${n}.ogg`),
  death: ["assets/audio/sfx/sfx_death.ogg"],
  victory: ["assets/audio/sfx/sfx_victory.ogg"],
  music_title: ["assets/audio/bgm/bgm_title.ogg"],
  music_map: ["assets/audio/bgm/bgm_map.ogg"],
  music_combat: ["assets/audio/bgm/bgm_combat.ogg"],
  music_boss: ["assets/audio/bgm/bgm_boss.ogg"],
  music_blessed: ["assets/audio/bgm/bgm_blessed.ogg"],
};

let ctx;
let master;
let musicGain;
let sfxGain;
let currentMusic;
let musicNodes = [];
let volume = 0.7;
let muted = false;
let musicBus = 1;
let sfxBus = 1;
const raw = new Map();
const buffers = new Map();

function ac() {
  if (!ctx) {
    const AC = window.AudioContext || window.webkitAudioContext;
    if (!AC) return null;
    ctx = new AC();
    master = ctx.createGain();
    master.gain.value = muted ? 0 : volume;
    master.connect(ctx.destination);
    musicGain = ctx.createGain();
    musicGain.gain.value = 0.18 * musicBus;
    musicGain.connect(master);
    sfxGain = ctx.createGain();
    sfxGain.gain.value = sfxBus;
    sfxGain.connect(master);
  }
  if (ctx.state === "suspended") ctx.resume();
  return ctx;
}

export function setVolume(v) {
  volume = v;
  if (master && !muted) master.gain.value = v;
}

export function setMuted(m) {
  muted = m;
  if (master) master.gain.value = m ? 0 : volume;
}

export function setBus(bus, v) {
  const n = Math.max(0, Math.min(1, Number(v) || 0));
  if (bus === "music") {
    musicBus = n;
    if (musicGain) musicGain.gain.value = 0.18 * musicBus;
  } else {
    sfxBus = n;
    if (sfxGain) sfxGain.gain.value = sfxBus;
  }
}

function prefetch(url) {
  if (raw.has(url)) return raw.get(url);
  const job = fetch(url).then((res) => (res.ok ? res.arrayBuffer() : null)).catch(() => null);
  raw.set(url, job);
  return job;
}

async function bufferFor(url) {
  if (buffers.has(url)) return buffers.get(url);
  const a = ac();
  const data = await prefetch(url);
  if (!a || !data) { buffers.set(url, null); return null; }
  try {
    const buf = await a.decodeAudioData(data.slice(0));
    buffers.set(url, buf);
    return buf;
  } catch {
    buffers.set(url, null);
    return null;
  }
}

for (const list of Object.values(FILES)) for (const url of list) prefetch(url);

export function play(id) {
  const a = ac();
  const list = FILES[id];
  if (!a || !list || muted || volume <= 0 || sfxBus <= 0) return;
  const url = list[Math.floor(Math.random() * list.length)];
  bufferFor(url).then((buf) => {
    if (!buf || !ctx) return;
    const src = ctx.createBufferSource();
    src.buffer = buf;
    if (id !== "death" && id !== "victory") src.playbackRate.value = 0.97 + Math.random() * 0.06;
    src.connect(sfxGain);
    src.start();
  }).catch(() => {});
}

function stopMusic(node, fade) {
  if (!node || !ctx) return;
  const now = ctx.currentTime;
  try {
    node.gain.gain.cancelScheduledValues(now);
    node.gain.gain.setValueAtTime(node.gain.gain.value, now);
    node.gain.gain.linearRampToValueAtTime(0, now + fade);
    node.src.stop(now + fade + 0.02);
  } catch { /* already stopped */ }
}

export function music(id) {
  if (currentMusic === id) return;
  currentMusic = id;
  const a = ac();
  const url = FILES[id]?.[0];
  if (!a || !url) return;
  const fading = musicNodes.slice();
  musicNodes = [];
  for (const node of fading) stopMusic(node, 0.5);
  bufferFor(url).then((buf) => {
    if (!buf || currentMusic !== id || !ctx) return;
    const src = ctx.createBufferSource();
    src.buffer = buf;
    src.loop = true;
    const gain = ctx.createGain();
    const now = ctx.currentTime;
    gain.gain.setValueAtTime(0, now);
    gain.gain.linearRampToValueAtTime(1, now + 0.5);
    src.connect(gain);
    gain.connect(musicGain);
    src.start();
    const node = { src, gain };
    musicNodes.push(node);
    src.onended = () => { musicNodes = musicNodes.filter((n) => n !== node); };
  }).catch(() => {});
}

export function musicForPhase(phase, boss) {
  if (phase === "combat") return music(boss ? "music_boss" : "music_combat");
  if (phase === "blessed") return music("music_blessed");
  if (phase === "death" || phase === "victory") return music("music_title");
  if (!phase || phase === "title" || phase === "create") return music("music_title");
  return music("music_map");
}
