/** Procedural audio. Every id is a hook an audio team can replace. */

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
  { id: "music_title", kind: "music", desc: "Slow D pentatonic drone for the title. Placeholder theme." },
  { id: "music_map", kind: "music", desc: "Sparse G pentatonic travel bed for the road." },
  { id: "music_combat", kind: "music", desc: "Tighter E minor pulse for ordinary fights." },
  { id: "music_boss", kind: "music", desc: "Lower drone and a slow pulse for bosses and tribulations." },
  { id: "music_blessed", kind: "music", desc: "Airy A pentatonic for the blessed land." },
];

let ctx;
let master;
let musicGain;
let timer;
let currentMusic;
let volume = 0.7;
let muted = false;

function ac() {
  if (!ctx) {
    const AC = window.AudioContext || window.webkitAudioContext;
    if (!AC) return null;
    ctx = new AC();
    master = ctx.createGain();
    master.gain.value = muted ? 0 : volume;
    master.connect(ctx.destination);
    musicGain = ctx.createGain();
    musicGain.gain.value = 0.18;
    musicGain.connect(master);
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

function tone(freq, dur, type, gain, at, dest) {
  const a = ac();
  if (!a) return;
  const o = a.createOscillator();
  const g = a.createGain();
  o.type = type;
  o.frequency.value = freq;
  g.gain.setValueAtTime(gain, at);
  g.gain.exponentialRampToValueAtTime(0.001, at + dur);
  o.connect(g);
  g.connect(dest || master);
  o.start(at);
  o.stop(at + dur + 0.02);
}

export function play(id) {
  const a = ac();
  if (!a || muted || volume <= 0) return;
  const t = a.currentTime;
  switch (id) {
    case "ui_click":
      tone(520, 0.05, "triangle", 0.08, t);
      break;
    case "card_play":
      tone(340, 0.07, "square", 0.05, t);
      tone(680, 0.09, "triangle", 0.06, t + 0.02);
      break;
    case "hit":
      tone(140, 0.12, "sawtooth", 0.08, t);
      tone(90, 0.14, "square", 0.04, t);
      break;
    case "hit_big":
      tone(90, 0.22, "sawtooth", 0.12, t);
      tone(180, 0.16, "square", 0.06, t + 0.01);
      break;
    case "block":
      tone(640, 0.06, "square", 0.05, t);
      tone(420, 0.08, "triangle", 0.04, t);
      break;
    case "heal":
      tone(660, 0.12, "sine", 0.06, t);
      tone(880, 0.16, "sine", 0.04, t + 0.05);
      break;
    case "poison":
      tone(220, 0.08, "triangle", 0.05, t);
      break;
    case "miss":
      tone(900, 0.05, "sine", 0.03, t);
      break;
    case "notify":
      tone(740, 0.1, "sine", 0.06, t);
      break;
    case "death":
      tone(180, 0.4, "sine", 0.08, t);
      tone(110, 0.6, "triangle", 0.06, t + 0.1);
      break;
    case "victory":
      [523, 659, 784, 880, 1046].forEach((f, i) => tone(f, 0.22, "triangle", 0.07, t + i * 0.12));
      break;
    default:
      break;
  }
}

const BEDS = {
  music_title: { root: 146, scale: [0, 3, 5, 7, 10], step: 0.85 },
  music_map: { root: 196, scale: [0, 2, 4, 7, 9], step: 0.7 },
  music_combat: { root: 164, scale: [0, 3, 5, 7, 10], step: 0.42 },
  music_boss: { root: 98, scale: [0, 1, 5, 7, 8], step: 0.55 },
  music_blessed: { root: 220, scale: [0, 2, 4, 7, 11], step: 0.9 },
};

export function music(id) {
  if (currentMusic === id) return;
  currentMusic = id;
  if (timer) { clearInterval(timer); timer = null; }
  const bed = BEDS[id];
  if (!bed) return;
  let i = 0;
  const tick = () => {
    const a = ac();
    if (!a || muted) return;
    const semi = bed.scale[i % bed.scale.length];
    const freq = bed.root * Math.pow(2, semi / 12);
    tone(freq, bed.step * 0.85, "sine", 0.08, a.currentTime, musicGain);
    if (i % 4 === 0) tone(bed.root / 2, bed.step * 1.5, "triangle", 0.05, a.currentTime, musicGain);
    i++;
  };
  tick();
  timer = setInterval(tick, bed.step * 1000);
}

export function musicForPhase(phase, boss) {
  if (phase === "combat") return music(boss ? "music_boss" : "music_combat");
  if (phase === "blessed") return music("music_blessed");
  if (phase === "death") return music("music_title");
  if (phase === "victory") return music("music_title");
  if (!phase || phase === "title" || phase === "create") return music("music_title");
  return music("music_map");
}
