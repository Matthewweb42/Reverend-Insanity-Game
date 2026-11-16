/** Seeded RNG stored on the run so saves can resume it. */

export function rngNext(run) {
  let a = run.rng | 0;
  a = (a + 0x6d2b79f5) | 0;
  let t = Math.imul(a ^ (a >>> 15), 1 | a);
  t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
  run.rng = a >>> 0;
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
}

export function rngInt(run, n) {
  if (n <= 0) return 0;
  return Math.floor(rngNext(run) * n);
}

export function rngPick(run, arr) {
  return arr[rngInt(run, arr.length)];
}

export function shuffle(run, arr) {
  const a = arr.slice();
  for (let i = a.length - 1; i > 0; i--) {
    const j = rngInt(run, i + 1);
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}
