# Credits

## Game code

The playable game on this branch was written for the Reverend Insanity project. Design documents in `docs/` and `GameDesign.md` are the project's own planning and remain the source for the setting.

## Icons

Card, enemy, and interface icons are from [game-icons.net](https://game-icons.net/), used under [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/).

Authors whose icons are included: Lorc, Delapouite, Carl Olsen, Skoll, Zeromancer, Willdabeast, DarkZaitzev, Faithtoken, Caro Asercion, sbed, and Sparker.

The black background rectangle shipped with those SVGs was removed so the glyph can be tinted. The drawings themselves are unchanged.

## Type

- Cormorant Garamond, by Christian Thalmann. SIL Open Font License 1.1.
- Source Sans 3, by Paul D. Hunt and the Adobe font team. SIL Open Font License 1.1.

Both are stored under `game/assets/fonts/`.

## Pictures that are not files

The mountain wash, card frames, seal, and road are CSS. They are not downloaded art and not generated images.

## Audio

Every sound and the music beds are synthesized in `game/js/audio.js`. They are original and not taken from a sound pack. Hook ids for a later recording pass are listed in `docs/TEAM_HANDOFF.md`.

## Desktop shell

The Windows build embeds the game in Neutralinojs 6.10 (MIT). The client library is `game/neutralino.js`. WebView2, which Windows 10 and 11 already provide, draws the window.
