# Credits

*Reverend Insanity: Path of the Gu Master* is a non-commercial fan project inspired by the web
novel *Reverend Insanity* (蛊真人) by Gu Zhen Ren. It is not affiliated with or endorsed by the
author or publishers. All game text, rules, numbers and code in this repository are original.

No AI-generated images, music or sound are used anywhere in this game.

## Engine

- **Godot Engine 4.5.1**: MIT licence, (c) Juan Linietsky, Ariel Manzur and Godot Engine
  contributors. https://godotengine.org/license

## Icons

All 244 icons in `game/assets/icons/` come from **game-icons.net**, by Lorc, Delapouite,
Skoll, sbed, Faithtoken, Willdabeast, Carl Olsen, Cathelineau, DarkZaitzev, Lord Berandas,
Viscious Speed, Zeromancer, Quoting, John Colburn, Felbrigg, Sparker, Priorblue, Caro Asercion
and the other game-icons.net contributors.

- Licence: **Creative Commons Attribution 3.0 Unported (CC BY 3.0)**,
  https://creativecommons.org/licenses/by/3.0/
- Source: https://game-icons.net and https://github.com/game-icons/icons, obtained through the
  `@iconify-json/game-icons` package (version 1.2.4).
- Changes: rendered from SVG to white-on-transparent PNG and recoloured at runtime by the game.
- The application icon (`app_icon.png`) is the lotus icon from the same set on a drawn disc.

Icons used: all-seeing-eye, angel-wings, anvil-impact, anvil, archery-target, backbone-shell, backpack, bear-face, bear-head, beehive, berries-bowl, beveled-star, biceps, big-wave, bleeding-heart, blood, bloody-sword, boar-tusks, boar, bone-knife, bone-mace, bowl-of-rice, brain-tentacle, brain, brainstorm, broken-bone, butterfly, byzantin-temple, cancel, card-pick, castle, cauldron, check-mark, checked-shield, chemical-drop, chest, circle, cloak-dagger, closed-doors, cog, coins-pile, coins, conversation, cracked-shield, crescent-blade, crossed-chains, crossed-swords, crown, crowned-skull, crystal-ball, crystal-bars, crystal-cluster, crystal-eye, crystal-growth, crystal-shine, crystal-shrine, death-skull, devil-mask, dice-six-faces-five, dinosaur-bones, direwolf, double-dragon, dragon-breath, dragon-head, dragon-spiral, drop, droplets, eagle-emblem, eagle-head, earth-worm, empty-hourglass, evil-minion, evil-moon, exit-door, eye-of-horus, eye-shield, eye-target, eyeball, falling-star, family-tree, fast-forward-button, fire-bowl, fire-dash, fire-gem, fire-ray, fire-tail, fire-wave, fish-scales, fist, flame, floating-crystal, floating-ghost, flower-twirl, fluffy-cloud, footprint, fox-head, fox-tail, fruit-bowl, fulguro-punch, furnace, gear-hammer, gem-pendant, gems, ghost-ally, ghost, gift-of-knowledge, goo-skull, grab, graveyard, hammer-drop, hand-bandage, hand-of-god, hanging-spider, health-potion, heart-drop, heart-plus, heart-tower, high-grass, honeypot, hood, hourglass, house, huts-village, info, island, knapsack, knocked-out-stars, laurel-crown, leather-armor, leeching-worm, lightning-dome, lightning-shadow, lightning-shout, lightning-storm, lightning-tear, lotus-flower, lotus, magic-shield, magnifying-glass, meat, medieval-village-01, meditation, mimic-chest, moon-claws, moon-orbit, moon, mountain-road, mountains, muscle-up, ninja-mask, open-book, padlock, pagoda, pause-button, pill-drop, pine-tree, pirate-skull, pizza-cutter, plain-dagger, play-button, poison-bottle, poison-cloud, poison-gas, poison, psychic-waves, punch-blast, punch, puppet, reaper-scythe, robber-hand, robber-mask, rock-golem, run, running-shoe, sacrificial-dagger, salamander, sands-of-time, save, scales, scorpion-tail, scroll-quill, scroll-unfurled, sewing-string, shambling-zombie, shard-sword, shield, shop, skeleton, skull-crossed-bones, skull-mask, snail, snake-bite, snake-spiral, snake, spear-feather, spell-book, spider-web, spiked-tail, sprout, star-cycle, star-formation, star-swirl, stone-block, stone-pile, stone-tower, sun-cloud, sun-priest, sun-radiations, sun-spear, sun, sunbeams, sundial, sunrise, swamp, swap-bag, sword-brandish, sword-clash, temple-gate, thor-fist, thor-hammer, thorny-vine, three-keys, tied-scroll, tiger-head, tiger, treasure-map, tree-roots, trophy-cup, village, volcano, vortex, walking-boot, warlock-eye, watchtower, water-drop, water-flask, werewolf, wheat, whirlwind, wizard-face, wolf-head, wolf-howl, wolf-trap, yin-yang.

## Fonts

All under the **SIL Open Font License 1.1** (licence texts in `game/assets/fonts/*-LICENSE.txt`):

- **Cinzel** by Natanael Gama (headings).
- **Noto Serif** by Google (body text).
- **Noto Sans Symbols** and **Noto Sans Symbols 2** by Google (path symbols and UI glyphs).
- **Noto Emoji** by Google, subset to a single glyph (the Strength path fist).

Obtained through the `@fontsource` packages and subset with fontTools.

## Music and sound effects

All music (menu, world, immortal, combat and tribulation themes) and every sound effect were
synthesized from scratch by `tools/gen_assets.py` in this repository (plucked-string,
drum, gong and noise synthesis, encoded to Ogg Vorbis). No samples or recordings are used. They
are released under CC0 along with the game.

## Visual effects and map

The ink-wash backdrop, mountains, map, routes, cards and panels are drawn at runtime by the game's
own shaders and code.

## Optional AI writing

If, and only if, a player pastes their own Anthropic API key in Settings, the game asks Claude
(Anthropic) for short flavour text: NPC lines, event openings and names for newly discovered Gu.
Without a key, all text comes from the authored and procedural content in `game/data/`.
