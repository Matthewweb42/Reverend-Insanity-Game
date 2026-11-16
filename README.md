# Reverend Insanity: Path of the Gu Master

A roguelike deckbuilder for Windows, inspired by the web novel *Reverend Insanity* by Gu Zhen Ren
(fan project, not affiliated with the author or publishers).

You are a young Gu Master with one mortal lifespan. Time runs on its own, with pause and speed
controls. Your equipped Gu worms are your deck. Cultivate from Rank 1, survive bandits, beasts,
rivals and heart demons, refine new Gu, climb your clan's ranks, face the immortal tribulation,
manage a blessed land, and try to become a Rank 9 Venerable before age or a blade ends you. Death
is permanent, but every life earns inheritance points for the next.

Built with Godot 4.5 (GDScript). Runs fully offline. Live AI writing through the Claude API is
optional and only switches on if you paste your own API key in Settings.

---

## Play it

### Option 1: download the build (no tools needed)

1. Open the repository on GitHub, go to **Actions**, then **Build Windows**, and open the latest
   green run on the `claude-build` branch.
2. Under **Artifacts**, download **ReverendInsanity-windows** and unzip it.
3. Double-click `build/windows/ReverendInsanity.exe`.

It is one self-contained file (about 95 MB). Windows SmartScreen may warn that the app is
unrecognised because it isn't code-signed: choose **More info**, then **Run anyway**.

### Option 2: build it yourself

On Windows (PowerShell):

```powershell
powershell -ExecutionPolicy Bypass -File tools\build.ps1
```

On Linux or macOS:

```bash
tools/build.sh          # build only
tools/build.sh test     # run every test first, then build
```

Both scripts download Godot 4.5.1 and its Windows export templates on first run (the templates
are about 1 GB, once), then write `build/windows/ReverendInsanity.exe`.

If you already have Godot 4.5.1 with export templates installed, you can also open `game/` in
the editor and use **Project > Export > Windows Desktop**, or run:

```bash
godot --headless --path game --export-release "Windows Desktop" ../build/windows/ReverendInsanity.exe
```

### Run from source without building

Open `game/project.godot` in Godot 4.5 and press F5.

---

## How to play

- **New Life:** pick a name, region, clan, start and mode, roll your aptitude (two rerolls) and
  carry up to three legacies from the vault.
- **Time:** Space pauses, 1/2/3 set speed. Events and battles pause automatically.
- **Cultivate tab:** pick an activity (cultivate, closed-door, rest, study a path) and an intensity.
  Higher intensity is faster and burns primeval stones. When the aperture is full press **B** to
  break through. Rank breakthroughs from Rank 3 on summon a heart demon to fight.
- **Aperture tab:** your equipped Gu are your combat deck. Every Gu must be fed each week or it
  starves and dies. Click a Gu to equip, refine further, use or sell it.
- **Map:** click a place to travel. Markets, the black market, caravans, refineries, the clan hall,
  the arena, tutors and inns depend on where you are.
- **Combat:** click an enemy to target it, click cards (or press 1-9) to activate Gu, Tab cycles
  targets. Essence pays for cards; your attainment in each path limits plays of that path per turn.
  Killer moves combine several Gu and get cheaper with practice.
- **Goals tab:** set goals ("Seeking Light Gu", "Need Resources", "Preparing for the Great Beast Tide")
  and events lean toward them.
- **Immortal tab:** after the Rank 5 tribulation, manage your blessed land, join a faction, raise
  beasts, build structures, survive periodic tribulations and climb to Rank 8, then face the
  three-stage Venerable tribulation.
- **Auto** (or A) lets the game play itself, which is handy for seeing late-game systems.
- F11 toggles fullscreen. Esc closes dialogs. Menu saves (three slots plus a monthly autosave).

Sandbox mode in Settings unlocks every clan, start and mode at once.

Saves, settings and legacy progress live in `%APPDATA%\ReverendInsanity`.

### Optional: live AI writing

Settings > Live AI writing. Paste an Anthropic API key and press **Test connection**. Claude then
writes fresh NPC lines, event openings and names for newly discovered Gu. Rules and numbers never
change, nothing is needed to play, and the key is stored only on your computer in the folder above.

---

## Repository layout

```
game/                 Godot 4.5 project (open project.godot)
  autoload/           Data, Meta (legacy and settings), Sfx, Game (state and rules), AIGen
  core/               combat, cultivation, world (NPCs, goals, missions), events, economy,
                      immortal stage, procedural generation, auto-play bot
  ui/                 every screen and dialog, built in code
  data/               all content as JSON (Gu, clans, events, enemies, locations, ...)
  assets/             icons, fonts, synthesized audio, shaders
  tests/              run_tests.gd, playthrough.gd, ui_smoke.gd (dev/ holds debugging scripts)
  export_presets.cfg  Windows export (single exe, data embedded)
tools/                build.sh, build.ps1, gen_assets.py (rebuilds icons, fonts, audio),
                      content/ (content generators)
docs/                 design docs; docs/MVP-Checklist.md lists every feature and its status
.github/workflows/    build-windows.yml: tests + Windows exe artifact on every push
GameDesign.md         the design document this build follows
CREDITS.md            every third-party asset and its licence
```

## Tests

```bash
godot --headless --path game --script res://tests/run_tests.gd              # 400+ logic checks
godot --headless --path game --script res://tests/playthrough.gd -- 6 1000  # bot plays 6 whole lives
godot --headless --path game --script res://tests/ui_smoke.gd -- "" 20      # opens every screen, auto-plays
```

The logic suite covers every system, including the immortal ascension, an immortal rank-up and a
full Venerable victory. The GitHub Actions workflow runs all three before exporting.

## Credits

See [CREDITS.md](CREDITS.md). Icons from game-icons.net (CC BY 3.0); fonts under the SIL Open
Font License; music and sound effects synthesized for this project. No AI-generated images.
