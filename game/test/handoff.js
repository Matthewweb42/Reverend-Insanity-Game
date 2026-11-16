import { writeFileSync } from "fs";
import { CARDS, KILLERS, PATHS } from "../js/cards.js";
import { AUDIO_HOOKS } from "../js/audio.js";
import { ENEMIES, EVENTS, ITEMS, RELICS } from "../js/world.js";

const lines = [];
const w = (s = "") => lines.push(s);

w("# Team handoff");
w();
w("Current numbers and text for design, writing, and audio. Generated from the live data files. If a number here and the game disagree, the game is wrong and this file is stale: regenerate with `node game/test/handoff.js`.");
w();
w("Combat resource is essence pips (3, then 4 at Rank 4, 5 at Rank 7), not the hundred-point pools in the design notes. Damage, block, poison, and costs below are what the resolver uses.");
w();

w("## Cards");
w();
for (const c of Object.values(CARDS)) {
  w(`### ${c.name}`);
  w(`- id \`${c.id}\` · Rank ${c.rank} · ${PATHS[c.path]?.name || c.path} · ${c.type} · ${c.rarity} · cost ${c.cost}${c.hpCost ? ` + ${c.hpCost} HP` : ""}${c.clan ? ` · ${c.clan} only-weighted` : ""}`);
  w(`- ${c.text}`);
  if (c.textUp) w(`- Refined: ${c.textUp}`);
  if (c.aperture) w(`- Aperture: ${c.aperture}`);
  if (c.exhaust) w("- Exhausts.");
  if (c.retain) w("- Retain.");
  if (c.unplayable) w("- Unplayable.");
  w();
}

w("## Killer moves");
w();
w("Each requires Master attainment in its path, at least 3 equipped Gu of that path, and can be used once per battle.");
w();
for (const k of KILLERS) {
  w(`- **${k.name}** (${PATHS[k.path].name}, ${k.cost} essence): ${k.text}`);
}
w();

w("## Enemies");
w();
function moves(list) {
  return (list || []).map((m) => {
    const bits = [m.intent];
    if (m.dmg) bits.push(m.hits > 1 ? `${m.dmg}×${m.hits}` : String(m.dmg));
    if (m.block) bits.push(`block ${m.block}`);
    if (m.poison) bits.push(`poison ${m.poison}`);
    if (m.weak) bits.push(`weak ${m.weak}`);
    if (m.vulnerable) bits.push(`vulnerable ${m.vulnerable}`);
    if (m.bleed) bits.push(`bleed ${m.bleed}`);
    if (m.burn) bits.push(`burn ${m.burn}`);
    if (m.strength) bits.push(`+${m.strength} str`);
    if (m.killer) bits.push(`"${m.killer}"`);
    return bits.join(" ");
  }).join(" / ");
}
for (const e of Object.values(ENEMIES)) {
  const tags = [e.elite ? "elite" : "", e.boss ? "boss" : "", e.calamity ? "calamity" : "", e.finale ? "finale" : ""].filter(Boolean).join(", ");
  w(`### ${e.name}`);
  w(`- id \`${e.id}\` · HP ${e.hp} · Rank ${e.rank} · ${e.path}${e.evasion ? ` · evasion ${e.evasion}` : ""} · ${e.stones} stones${tags ? ` · ${tags}` : ""}`);
  w(`- ${moves(e.moves)}`);
  if (e.moves2) w(`- Below ${Math.round(e.phaseBelow * 100)}%: ${e.phaseText} ${moves(e.moves2)}`);
  if (e.moves3) w(`- Below ${Math.round(e.phase3Below * 100)}%: ${e.phaseText3} ${moves(e.moves3)}`);
  w();
}

w("## Treasures");
w();
for (const r of RELICS) {
  w(`- **${r.name}** (${r.rarity}): ${r.text}`);
}
w();

w("## Items");
w();
for (const item of Object.values(ITEMS)) {
  w(`- **${item.name}** (${item.price} stones): ${item.text}`);
}
w();

w("## Events");
w();
for (const ev of EVENTS) {
  w(`### ${ev.title}`);
  if (ev.epoch) w("- Epoch event.");
  if (ev.requiresFlag) w(`- Requires flag \`${ev.requiresFlag}\`.`);
  w(ev.text);
  for (const ch of ev.choices) {
    const chance = ch.chance != null ? ` (${Math.round(ch.chance * 100)}% before Wisdom)` : "";
    w(`- **${ch.label}**${chance}: ${ch.result || ""}`);
    if (ch.failResult) w(`  - If it fails: ${ch.failResult}`);
  }
  w();
}

w("## Sound and music hooks");
w();
w("These ids are the ones `play()` and `music()` accept. The recordings live in `game/assets/audio/` and are credited in `CREDITS.md` and `game/assets/audio/LICENSES.md`. Elites use `music_combat`. Bosses and tribulations use `music_boss`.");
w();
for (const h of AUDIO_HOOKS) {
  w(`- \`${h.id}\` (${h.kind}): ${h.desc}`);
}
w();

writeFileSync(new URL("../../docs/TEAM_HANDOFF.md", import.meta.url), lines.join("\n"));
console.log("wrote", lines.length, "lines");
