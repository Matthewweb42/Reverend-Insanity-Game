"""Reverend Insanity — card RPG prototype (text/terminal).

Combat vertical slice per DEC-041, now with path focus + synergy:
  - deck-picker character creation (choose a path-focused starter deck)
  - aperture-as-deck (DEC-039)
  - attainment gate (DEC-026): your path attainment caps Gu/turn from that path
  - intra-path synergy engines + killer moves
  - path symbols (DEC-040)

Run:  py prototype/game.py            (interactive)
      py prototype/game.py --demo     (scripted auto-play, no input)
      py prototype/game.py --deck poison --seed 7

No AI generation yet — Gu are hardcoded (cards.py). AI comes after the loop is fun.
"""

from __future__ import annotations

import argparse
import random
import sys

import ui
from cards import (Card, KILLER_MOVES, STARTER_DECKS, build_deck)
from combat import (Combat, Combatant, HAND_SIZE, DRAW_PER_TURN, MAX_TURNS)
from enemies import ENEMY_LADDER
from paths import path_tag, PATHS


CLANS = {
    "1": ("Gu Yue Clan", "Balanced all-rounder"),
    "2": ("Bai Clan", "Aggressive combat"),
    "3": ("Shang Clan", "Manipulation"),
}
APTITUDES = {"A": 1.5, "B": 1.2, "C": 1.0, "D": 0.7}


class Player:
    def __init__(self, name: str, clan: str, aptitude: str, deck_key: str):
        self.name = name
        self.clan = clan
        self.aptitude = aptitude
        self.deck_key = deck_key
        self.max_hp = 100
        self.max_essence = 100
        self.aperture: list[Card] = build_deck(deck_key)  # aperture = deck (DEC-039)
        self.attainment: dict[str, str] = dict(STARTER_DECKS[deck_key]["attainment"])

    @property
    def equipped_keys(self) -> set[str]:
        return set(STARTER_DECKS[self.deck_key]["cards"])

    def make_combatant(self) -> Combatant:
        return Combatant(
            name=self.name, max_hp=self.max_hp, hp=self.max_hp,
            essence=self.max_essence, max_essence=self.max_essence,
            is_player=True, attainment=dict(self.attainment))


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


def choose_deck(io: Input, preset: str | None) -> str:
    if preset and preset in STARTER_DECKS:
        return preset
    print("\nChoose your cultivation path (your starting deck):")
    keys = list(STARTER_DECKS.keys())
    for i, k in enumerate(keys, 1):
        d = STARTER_DECKS[k]
        p = PATHS[k]
        print(f"  {i}) {path_tag(k)}  {d['name']}")
        print(f"       {d['blurb']}")
    choice = io.ask(f"Path [1-{len(keys)}, default 1]: ", "1")
    idx = int(choice) - 1 if choice.isdigit() and 0 < int(choice) <= len(keys) else 0
    return keys[idx]


def create_character(io: Input, preset_deck: str | None) -> Player:
    print(ui.rule())
    print("  REVEREND INSANITY — Card RPG Prototype")
    print(ui.rule())
    name = io.ask("Enter your name [Fang Yuan]: ", "Fang Yuan") or "Fang Yuan"

    print("\nChoose your clan:")
    for k, (cn, desc) in CLANS.items():
        print(f"  {k}) {cn} — {desc}")
    clan = CLANS.get(io.ask("Clan [1]: ", "1"), CLANS["1"])[0]

    deck_key = choose_deck(io, preset_deck)
    p = Player(name, clan, "C-grade", deck_key)

    print(f"\n{name} of the {clan}.")
    print(f"Path: {path_tag(deck_key)}  {STARTER_DECKS[deck_key]['name']}")
    print("Attainment:", ", ".join(
        f"{path_tag(k)} {v}" for k, v in p.attainment.items()))
    print(f"\nYour aperture (deck), {len(p.aperture)} Gu:")
    for c in p.aperture:
        print(f"   {path_tag(c.path)} {c.name}  ({c.essence_cost} ess)")
    kms = [km for km in KILLER_MOVES.values()
           if set(km.components).issubset(p.equipped_keys)
           and p.attainment.get(km.path, "Ordinary") in
           ("Master", "Quasi-Grandmaster", "Grandmaster")]
    if kms:
        print("\nKiller moves you can perform:")
        for km in kms:
            print(f"   {path_tag(km.path)} {km.name} — {km.text}")
    return p


def _wastes_on_no_stacks(effects, enemy) -> bool:
    """True if the card's payoff scales with a status the enemy lacks (would fizzle)."""
    for e in effects:
        v = e.get("verb")
        st = e.get("status")
        if v in ("multiply_status", "damage_per_stack") and st:
            cur = enemy.statuses.get(st)
            if not cur or cur.stacks <= 0:
                return True
    return False


def _auto_pick(combat: Combat, pc: Combatant, enemy: Combatant,
               killer_moves) -> str:
    """Smarter heuristic for --demo so results reflect the DECK, not a dumb pilot.

    Rules: don't fire stack-payoffs with no stacks up; only use a killer move if
    it won't fizzle; otherwise play the best affordable card (setup before
    payoff), and end the turn when nothing useful remains.
    """
    # Killer moves: only if they won't fizzle on missing stacks.
    for i, km in enumerate(killer_moves, 1):
        if combat.can_play_killer(pc, km)[0] and not _wastes_on_no_stacks(km.effects, enemy):
            # Save the big detonators for when there's real value (enemy hurt or stacked).
            if enemy.hp_pct() < 60 or enemy.is_debuffed():
                return f"k {i}"
    playable = [(i, c) for i, c in enumerate(pc.hand, 1)
                if combat.can_play(pc, c)[0]
                and not _wastes_on_no_stacks(c.effects, enemy)]
    if not playable:
        return "e"

    def score(item):
        _, c = item
        atk = "attack" in c.tags
        # Early: prefer setup/utility (build stacks/buffs). Low enemy: prefer attacks.
        prefer_attack = enemy.hp_pct() < 50
        return (atk if prefer_attack else not atk, c.essence_cost)

    playable.sort(key=score, reverse=True)
    return str(playable[0][0])


def run_combat(player: Player, enemy: Combatant, io: Input,
               rng: random.Random, auto: bool) -> str:
    pc = player.make_combatant()
    combat = Combat(pc, enemy, rng=rng)
    combat.shuffle_deck(pc, player.aperture)
    combat.draw(pc, HAND_SIZE)

    killer_moves = combat.available_killer_moves(
        pc, player.equipped_keys, KILLER_MOVES)

    print("\n" + ui.rule("━"))
    print(f"  COMBAT!  {enemy.name} appears.")
    print(ui.rule("━"))

    while True:
        combat.turn += 1
        if combat.turn > MAX_TURNS:
            # Stalemate: whoever holds more HP% wins (breaks infinite loops).
            print(f"\n  The battle drags on ({MAX_TURNS} turns)...")
            return "win" if pc.hp_pct() >= enemy.hp_pct() else "lose"
        combat.tick_start_of_turn(pc)
        if not pc.alive:
            return "lose"
        combat.on_act_bleed(pc)
        combat.draw(pc, DRAW_PER_TURN)

        print(f"\n── Turn {combat.turn} ─────────────────────────────")
        print(ui.render_combatant(enemy))
        if enemy.attainment:
            print(ui.render_attainment(enemy))
        print("-" * 50)
        print(ui.render_combatant(pc))
        print(ui.render_attainment(pc))
        print("\nYour hand:")
        print(ui.render_hand(pc.hand, combat, pc))
        km_txt = ui.render_killer_moves(killer_moves, combat, pc)
        if km_txt:
            print("\n" + km_txt)

        safety = 0
        turn_over = False
        while not turn_over:
            safety += 1
            if safety > 200:  # demo runaway guard
                turn_over = True
                break
            if auto:
                cmd = _auto_pick(combat, pc, enemy, killer_moves)
                print(f"\n> [auto] {cmd}")
                if cmd == "e":
                    turn_over = True
                    continue
            else:
                cmd = io.ask("\n> play #, (k # killer), (e)nd, (f)lee: ", "e").lower()
                if cmd in ("e", "end", ""):
                    turn_over = True
                    continue
                if cmd in ("f", "flee"):
                    print("You flee the battle.")
                    return "flee"

            # killer move: "k 2"
            if cmd.startswith("k"):
                rest = cmd[1:].strip()
                if rest.isdigit() and 1 <= int(rest) <= len(killer_moves):
                    km = killer_moves[int(rest) - 1]
                    ok, why = combat.can_play_killer(pc, km)
                    if not ok:
                        print(f"  Can't use {km.name}: {why}.")
                        if auto:
                            turn_over = True
                        continue
                    combat.play_killer(pc, enemy, km)
                    if not enemy.alive:
                        return "win"
                    if not auto:
                        _reprint_hand(pc, combat, killer_moves)
                    continue
                print("  Usage: k <number>")
                continue

            # play card by number
            idx_str = cmd.replace("play", "").strip()
            if not idx_str.isdigit():
                print("  Enter a card number, 'k #', 'e', or 'f'.")
                continue
            idx = int(idx_str) - 1
            if not (0 <= idx < len(pc.hand)):
                print("  No card at that slot.")
                continue
            card = pc.hand[idx]
            ok, why = combat.can_play(pc, card)
            if not ok:
                print(f"  Can't play {card.name}: {why}.")
                if auto:
                    turn_over = True
                continue
            combat.play_card(pc, enemy, card)
            if not enemy.alive:
                return "win"
            if not auto:
                _reprint_hand(pc, combat, killer_moves)

        # enemy turn
        combat.tick_start_of_turn(enemy)
        if not enemy.alive:
            return "win"
        print(f"\n{enemy.name}'s turn:")
        combat.enemy_take_turn()
        if not pc.alive:
            return "lose"


def _reprint_hand(pc, combat, killer_moves):
    print("\n" + ui.render_attainment(pc))
    print("Your hand:")
    print(ui.render_hand(pc.hand, combat, pc))
    km_txt = ui.render_killer_moves(killer_moves, combat, pc)
    if km_txt:
        print(km_txt)


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--seed", type=int, default=None)
    parser.add_argument("--deck", default=None,
                        help="starter deck key: " + ", ".join(STARTER_DECKS))
    parser.add_argument("--demo", action="store_true",
                        help="auto-play (no input needed)")
    args = parser.parse_args(argv)

    ui.init_color()
    rng = random.Random(args.seed)

    if args.demo:
        io = Input(scripted=["", "1"])  # name, clan; deck comes from --deck or default
    else:
        io = Input()

    player = create_character(io, args.deck)

    wins = 0
    for make_enemy in ENEMY_LADDER:
        enemy = make_enemy()
        result = run_combat(player, enemy, io, rng, auto=args.demo)
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
    else:
        print("\n  You cleared the ladder! The path to Venerable is long...")

    print(f"\nFinal: {wins}/{len(ENEMY_LADDER)} enemies defeated.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
