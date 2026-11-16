# Decisions for this build

Matthew asked for every call to be made without stopping to ask. These are the calls, and the places this build is deliberately smaller than the design documents.

## Engine

The playable game is a local web app (HTML, CSS, and JavaScript) wrapped as a Windows desktop program with Neutralino 6.10. Double-click `build/ReverendInsanity/ReverendInsanity-win_x64.exe`. It uses the WebView2 runtime that ships with Windows 10 and 11.

Godot 4.5.1 is the long-term choice in `docs/Decisions.md` (DEC-001). This competition build does not use it. A single desktop executable that can be tested in a browser, with no export-template install and no second process, was the reliable way to ship a polished run. The rules are plain data files, so a later Godot port can keep the same cards.

There is no Python server and no Claude API. The game has to run offline the moment it is double-clicked. Goal-weighted Gu and events are chosen from authored pools with the same inputs the design named (rank, path, rarity, goals, reputation, location). That is the fallback the architecture doc already required when the API is absent.

## What kind of game this is

Moment to moment it is a Slay the Spire-style deckbuilder: a branching road, fights, elites, events, shops, rests, and bosses. The Reverend Insanity systems sit on that road instead of replacing it.

A full venerable run is meant to be one sitting. The design's six-hour, 600-year simulation is the long-term shape. Here, days are spent in visible chunks when you travel, rest, study, or cultivate, and lifespan is short enough that dawdling and closed-door seclusion can kill you.

## Combat

- Essence is 3 pips a turn (4 at Rank 4, 5 at Rank 7). The design's 100-to-50,000 pools made the text prototype stall. Pips keep a turn to a handful of cards.
- Attacks hit, crit, or miss. Evasion raises the miss chance. The partial-damage band from the combat doc is not used; three clear results read better on a card.
- Poison and bleed deal their stacks at the start of the afflicted turn, then drop by 1. Burn ticks at the end of that turn. They ignore block.
- Block clears at the start of your turn unless Cauldron Lid keeps some.
- Ordinary attainment allows 3 Gu of a path each turn, Adept 4, Expert 5, Master 8. Mortal techniques are exempt. The design's "1 Gu at Ordinary" would have made the opening deck unable to spend its essence.
- Attainment thresholds are 30 / 80 / 140 / 220 so a focused run can reach Master and a killer move before the calamity. The novel's "almost nobody reaches Master" curve does not fit one sitting.
- Killer moves are a once-per-battle action. They cost essence and do not end the turn.
- Enemy signature attacks are named intents. They are not a second copy of the player's killer-move resolver.
- Summons strike the weakest enemy at the end of your turn. They do not have a separate health bar to target.

## Time, rank, and the map

- Five acts: Clan Wilds, Wild Beast Plains, Merchant Road, Dang Hun Mountain, Immortal Heaven.
- Travel spends days. A movement Gu in the aperture shortens that. The day/night flag flips every ten days and powers moon cards.
- Closed door is the real-time mode: about eight game days a second at 1×, with pause and 2× / 5×. That is slower than DEC-012's 125 days a second, which would finish a stage before the number could be read.
- Each rank has four stages. Filling a stage is 100 progress, not the multi-year point tables. Fights, bosses, and cultivation sessions are the sources.
- Dice breakthroughs follow the design's shape (aptitude, stones spent, attainment, age) and cannot skip to Rank 6 or beyond. Rank 6 is the Earthly Calamity. Ranks 7, 8, and 9 are tribulation fights.
- Aperture size starts at 12 and grows by 2 per rank. The design's 10-to-300 range would never force a cut in a deckbuilder run.
- Lifespan is a mortal fuse of roughly fifteen years of road, not a hundred-year clock. Year-Fruit Gu, the Lifespan Lotus, and Death's Door are how you bargain for more. Aging still weakens your strikes as the fuse burns down.
- Rank does not grant lifespan (DEC-014).

## World systems that are in, and how they were cut to fit

- Four starting clans, plus Wu and Chi, the Huang Jin and Hei Lou tribes, and two Central Continent sects. The tribes and sects, and Wu and Chi, unlock through play or the inheritance shop. They change your start, not the whole map.
- Goals (one primary, up to four secondary) weight card rewards and events.
- Reputation, clan standing, and six persistent NPCs. An allied NPC joins a boss fight.
- Shops, a black-market event, card removal, and Treasure Yellow Heaven for immortal stones.
- Blessed land: three plots, three buildings, dao marks, a tribulation calendar that is "the next act."
- Gu hunger. Food-path Gu feed themselves. Starving Gu are weaker until you pay to feed them.
- A few Gu formulas can be crafted at rest once learned or inherited.
- Inheritance points are spent after death or Rank 9 and persist in local save data.
- Wisdom attainment reveals odds as unclear, a vague word, or a percent.

## Art and audio

- No generated images. Icons are game-icons.net (CC BY 3.0). Type is Cormorant Garamond and Source Sans 3 (OFL). Frames, mountains, and the seal are drawn in CSS. Credits are in `CREDITS.md`.
- Sound is original synthesis hooked by id, so a later pass can drop in recordings without renaming calls. The list is in `docs/TEAM_HANDOFF.md`.

## Content

No sexual, ecchi, or fanservice content. Blood path spends hit points. That is the whole of it.

## What I would not pretend is finished

The design's live model of the world (notifications while time runs at 5 days a second, an AI writing new Gu during play, immortal politics as a long campaign, separate maps for the plains and the continent) is not this build. The road contains a working version of each system so a run can touch it. The numbers a design pass should change are in `docs/TEAM_HANDOFF.md`.
