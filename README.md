# Reverend Insanity

A roguelike deckbuilder set on the Southern Border. Gu worms are cards. Your aperture is the deck. You cultivate from a Rank 1 mortal toward Rank 9, and the years you spend are part of the risk.

The design documents in `docs/` and `GameDesign.md` are unchanged planning. This branch is a playable desktop game built from them. Decisions that narrow those documents are in [DECISIONS.md](DECISIONS.md). Every card, enemy, treasure, event, and audio hook is listed with its current numbers in [docs/TEAM_HANDOFF.md](docs/TEAM_HANDOFF.md).

## Play on Windows

1. Install nothing else if you are on Windows 10 or 11. The game uses WebView2, which is already part of the system. If a window fails to open, install the [WebView2 runtime](https://developer.microsoft.com/microsoft-edge/webview2/).
2. Double-click:

```
build/ReverendInsanity/ReverendInsanity-win_x64.exe
```

The save is written to local storage and, in the desktop build, to a `save.json` file under the app data folder `ReverendInsanity`. Continue is on the title screen. Esc opens the menu, including Music and SFX sliders.

## Play from source

Any machine with Python 3:

```
python3 -m http.server 8765 --directory game
```

Then open `http://127.0.0.1:8765/`. Modules do not load from a `file://` URL, so use the server or the Windows exe.

```
node game/test/sim.js
```

runs a headless combat sandbox and several greedy runs. It does not need a window.

## What a run is

Choose a clan, tribe, or sect, an aptitude, a blessing, and a burden. Set what you are seeking. The road is five acts: clan wilds, the beast plains, the merchant road, Dang Hun Mountain, then the immortal stretch. Fights are turn-based. Between them you travel, cultivate, shop, rest, and answer events. Lifespan is short. Rank 6 is the Earthly Calamity. Rank 9 ends the run. Death writes an inheritance the next life can spend.

## Layout

```
build/ReverendInsanity/     Windows executable
game/                       The game (open index.html through a server)
game/js/cards.js            Gu cards and killer moves
game/js/world.js            Enemies, events, treasures, origins
game/js/combat.js           Battle resolver
game/js/run.js              Map, cultivation, shops, inheritance
game/js/ui.js               Screens
docs/                       Design documents
DECISIONS.md                Calls made for this build
CREDITS.md                  Asset licenses
```

## Design documents

- [GameDesign.md](GameDesign.md)
- [Documentation index](docs/README.md)
- [Combat](docs/Systems/Combat.md), [Cards](docs/Systems/Cards.md), [Cultivation](docs/Systems/Cultivation.md), [Time](docs/Systems/Time.md), [Events](docs/Systems/Events.md), [Economy](docs/Systems/Economy.md), [Inheritance](docs/Systems/Inheritance.md)
- [Paths](docs/Content/Paths.md), [Gu](docs/Content/Gu.md), [Clans](docs/Content/Clans.md), [Locations](docs/Content/Locations.md), [NPCs](docs/Content/NPCs.md)

## Rebuilding the Windows exe

The checked-in executable already contains the game. Rebuilding needs Node 18 or newer. The CLI is pinned to `@neutralinojs/neu@11.8.0`. It downloads the Neutralino 6.10 client named in `neutralino.config.json`. From the repo root:

```
npm install
npm run build
```

`npm run build` runs `neu update` and then `neu build --embed-resources`. `neu update` refreshes the binary cache. Do not replace `game/neutralino.js` unless you mean to bump the client. After a rebuild, keep `ReverendInsanity-win_x64.exe` and `HOW_TO_PLAY.txt` in `build/ReverendInsanity/` and drop any Linux or macOS binaries that the CLI also wrote. WebView2 is not bundled. Windows 10 and 11 usually already have it. The sha256 of the shipped exe is recorded below when the build is refreshed.

The desktop window is a single instance and uses `game/assets/icon.png`.

Shipped exe: `build/ReverendInsanity/ReverendInsanity-win_x64.exe`, 13,428,224 bytes, sha256 `20f940a99473d1f533cdc99c7d6eea0582d3d3c8763a2e589fc2958431c30155`. Built with `@neutralinojs/neu@11.8.0` and the Neutralino 6.10 client. WebView2 is still required on the Windows machine and is not inside the exe.

## License

Asset licenses are in [CREDITS.md](CREDITS.md). The project's own license is still unset.
