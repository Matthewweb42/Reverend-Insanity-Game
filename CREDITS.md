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
- Cinzel, by Natanael Gama. SIL Open Font License 1.1. Used for titles.
- Noto Serif SC, by Adobe and Google. SIL Open Font License 1.1. Used for the title seal.

The OFL notices for Cinzel and Noto Serif SC sit beside the files in `game/assets/fonts/`. Cormorant and Source Sans notices were already stored with those files.

## Pictures that are not files

The mountain wash, card frames, seal, and road are CSS. They are not downloaded art and not generated images.

## Audio

All sixteen hooks play CC0 recordings in `game/assets/audio/`. Full file names and edits are in `game/assets/audio/LICENSES.md`.

- Kenney Interface Sounds, Casino Audio, Impact Sounds, and Music Jingles. CC0. https://kenney.nl
- Rubberduck. 40 CC0 water, splash, and slime sounds. https://opengameart.org/content/40-cc0-water-splash-slime-sfx
- Sadiquecat. Stick whooshes (Freesound 802465, 802466, 802467). CC0.
- Pufermufin. Lovely Chinese Guzheng Bowed (Freesound 396903). CC0. Trimmed to a 75 second loop starting at 1:30.
- iamoneabe. Fool's Philosophy. CC0. https://opengameart.org/content/fools-philosophy
- Centurion_of_war. Last One Standing. CC0. https://opengameart.org/content/last-one-standing
- qubodup and yd. Dark Shrine Loop. CC0. https://opengameart.org/content/dark-shrine-loop
- Tozan. RpJian. CC0. https://opengameart.org/content/rpjian

Loudness was matched with ffmpeg loudnorm. The blessed-land bed is a little quieter than the road. Death and victory are single takes with no pitch jitter.

## Desktop shell

The Windows build embeds the game in Neutralinojs 6.10 (MIT). The client library is `game/neutralino.js`. WebView2, which Windows 10 and 11 already provide, draws the window.
