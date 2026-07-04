"""Reverend Insanity — card RPG prototype (text/terminal).

Fastest-to-playable slice per DEC-041:
  - minimal character creation (clan + aptitude)
  - aperture-as-deck (DEC-039)
  - card combat loop with path symbols (DEC-040)

Run:  py prototype/game.py            (interactive)
      py prototype/game.py --demo     (scripted auto-play, no input)
      py prototype/game.py --seed 7   (reproducible RNG)

No AI generation yet — Gu are hardcoded (see cards.py). AI comes after the loop
is proven fun.
"""

from __future__ import annotations

import argparse
import random
import sys

import ui
from cards import Card, starter_deck
from combat import (Combat, Combatant, HAND_SIZE, DRAW_PER_TURN)
from enemies import ENEMY_LADDER
from paths import path_tag


# --- minimal clans/aptitude for creation (subset of docs/Content/Clans.md) --
CLANS = {
    "1": ("Gu Yue Clan", "Balanced all-rounder (Moonlight/Light lean)"),
    "2": ("Bai Clan", "Aggressive combat (Bone/Strength lean)"),
    "3": ("Shang Clan", "Manipulation (Enslavement lean)"),
}

APTITUDES = {
    "A": ("A-grade", 1.5),
    "B": ("B-grade", 1.2),
    "C": ("C-grade", 1.0),
    "D": ("D-grade", 0.7),
}


class Player:
    def __init__(self, name: str, clan: str, aptitude: str):
        self.name = name
        self.clan = clan
        self.aptitude = aptitude
        self.max_hp = 100
        self.max_essence = 100
        # Aperture = deck (DEC-039). Starter 10-slot deck.
        self.aperture: list[Card] = starter_deck()

    def make_combatant(self) -> Combatant:
        return Combatant(
            name=self.name, max_hp=self.max_hp, hp=self.max_hp,
            essence=self.max_essence, max_essence=self.max_essence,
            is_player=True)


# ---------------------------------------------------------------------------
# Input abstraction: interactive vs scripted (--demo) so the whole game can be
# auto-played for testing without a human at the keyboard.
# ---------------------------------------------------------------------------
class Input:
    def __init__(self, scripted: list[str] | None = None):
        self.scripted = scripted
        self.auto = scripted is not None

    def ask(self, prompt: str, default: str = "") -> str:
        if self.auto:
            val = self.scripted.pop(0) if self.scripted else default
            print(f"{prompt}{val}")
            return val
        try:
            return input(prompt).strip() or default
        except EOFError:
            return default


def create_character(io: Input) -> Player:
    print(ui.rule())
    print("  REVEREND INSANITY — Card RPG Prototype")
    print(ui.rule())
    name = io.ask("Enter your name [Fang Yuan]: ", "Fang Yuan") or "Fang Yuan"

    print("\nChoose your clan:")
    for k, (cn, desc) in CLANS.items():
        print(f"  {k}) {cn} — {desc}")
    choice = io.ask("Clan [1]: ", "1")
    clan = CLANS.get(choice, CLANS["1"])[0]

    # Aptitude: roll or pick. Prototype lets you pick for testing.
    print("\nAptitude grade (higher = faster cultivation):")
    for k, (an, mult) in APTITUDES.items():
        print(f"  {k}) {an} (x{mult} cultivation)")
    apt = io.ask("Aptitude [C]: ", "C").upper()
    aptitude = APTITUDES.get(apt, APTITUDES["C"])[0]

    p = Player(name, clan, aptitude)
    print(f"\n{name} of the {clan} — {aptitude}. Rank 1 mortal.")
    print(f"Aperture (your deck), {len(p.aperture)} Gu:")
    for c in p.aperture:
        print(f"   {path_tag(c.path)} {c.name}  ({c.essence_cost} ess)")
    return p


def run_combat(player: Player, enemy: Combatant, io: Input,
               rng: random.Random) -> str:
    pc = player.make_combatant()
    combat = Combat(pc, enemy, rng=rng)

    # Build the player's draw pile from the aperture (DEC-039) and draw opening hand.
    combat._shuffle_deck(pc, player.aperture)
    combat._draw(pc, HAND_SIZE)

    print("\n" + ui.rule("━"))
    print(f"  COMBAT!  {enemy.name} appears.")
    print(ui.rule("━"))

    while True:
        combat.turn += 1
        # ---- Player turn ----
        combat._tick_start_of_turn(pc)
        if not pc.alive:
            return "lose"
        combat._draw(pc, DRAW_PER_TURN)

        print(f"\n── Turn {combat.turn} ─────────────────────────────")
        print(ui.render_combatant(enemy))
        print("-" * 40)
        print(ui.render_combatant(pc))
        print("\nYour hand:")
        print(ui.render_hand(pc.hand))

        turn_over = False
        while not turn_over:
            cmd = io.ask("\n> play #, (e)nd turn, (f)lee: ", "e").lower()
            if cmd in ("e", "end", ""):
                turn_over = True
            elif cmd in ("f", "flee"):
                print("You flee the battle.")
                return "flee"
            elif cmd.startswith("play") or cmd.isdigit():
                idx_str = cmd.replace("play", "").strip()
                if not idx_str.isdigit():
                    print("  Which card? e.g. 'play 1' or just '1'.")
                    continue
                idx = int(idx_str) - 1
                if not (0 <= idx < len(pc.hand)):
                    print("  No card at that slot.")
                    continue
                card = pc.hand[idx]
                ok, why = combat.can_play(pc, card)
                if not ok:
                    print(f"  Can't play {card.name}: {why}.")
                    continue
                combat.play_card(pc, enemy, card)
                if not enemy.alive:
                    return "win"
                # refresh hand view after playing
                print("\nYour hand:")
                print(ui.render_hand(pc.hand))
            else:
                print("  Commands: a number to play a card, 'e' to end, 'f' to flee.")

        # ---- Enemy turn ----
        combat._tick_start_of_turn(enemy)
        if not enemy.alive:
            return "win"
        print(f"\n{enemy.name}'s turn:")
        combat.enemy_take_turn()
        if not pc.alive:
            return "lose"


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--seed", type=int, default=None)
    parser.add_argument("--demo", action="store_true",
                        help="auto-play a scripted run (no input needed)")
    args = parser.parse_args(argv)

    ui.init_color()
    rng = random.Random(args.seed)

    if args.demo:
        # Scripted: default name/clan/aptitude, then fight the ladder by
        # spamming the first playable card each turn.
        script = ["", "1", "C"]
        io = Input(scripted=script)
    else:
        io = Input()

    player = create_character(io)

    wins = 0
    for i, make_enemy in enumerate(ENEMY_LADDER, 1):
        enemy = make_enemy()
        if args.demo:
            # Feed a simple auto-play: play card 1 until it can't, then end;
            # repeated enough times to carry a full fight.
            io.scripted = (["1", "1", "1", "e"] * 40) + ["e"] * 40
        result = run_combat(player, enemy, io, rng)
        print("\n" + ui.rule())
        if result == "win":
            wins += 1
            print(f"  VICTORY over {enemy.name}!  ({wins}/{len(ENEMY_LADDER)})")
        elif result == "lose":
            print(f"  You were slain by {enemy.name}. Run over.")
            print(ui.rule())
            break
        else:
            print(f"  You escaped {enemy.name}.")
        print(ui.rule())
        if result == "lose":
            break
    else:
        print("\n  You cleared the ladder! The path to Venerable is long...")

    print(f"\nFinal: {wins}/{len(ENEMY_LADDER)} enemies defeated.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
