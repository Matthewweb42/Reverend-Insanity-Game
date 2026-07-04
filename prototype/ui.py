"""Terminal rendering helpers for the card prototype."""

from __future__ import annotations

import sys

import paths
from cards import Card, KillerMove
from combat import Combatant
from paths import PATHS, colorize


def init_color() -> None:
    """Force UTF-8 output, disable color if not a tty, enable ANSI on Windows."""
    for stream in (sys.stdout, sys.stderr):
        try:
            stream.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
        except Exception:
            pass
    if not sys.stdout.isatty():
        paths.COLOR_ENABLED = False
        return
    if sys.platform == "win32":
        try:
            import ctypes
            kernel32 = ctypes.windll.kernel32
            kernel32.SetConsoleMode(kernel32.GetStdHandle(-11), 7)
        except Exception:
            paths.COLOR_ENABLED = False


def hp_bar(cur: int, mx: int, width: int = 20) -> str:
    filled = int(width * cur / mx) if mx else 0
    filled = max(0, min(width, filled))
    return "█" * filled + "░" * (width - filled)


def status_str(c: Combatant) -> str:
    bits = []
    if c.shield > 0:
        bits.append(f"Shield {c.shield}")
    for name, st in c.statuses.items():
        if st.stacks > 0:
            bits.append(f"{name.capitalize()} x{st.stacks}")
    return ", ".join(bits) if bits else "None"


def render_combatant(c: Combatant) -> str:
    lines = [
        f"{c.name}",
        f"  HP  {hp_bar(c.hp, c.max_hp)} {c.hp}/{c.max_hp}",
    ]
    if c.is_player:
        lines.append(f"  Ess {hp_bar(c.essence, c.max_essence)} "
                     f"{c.essence}/{c.max_essence}")
    lines.append(f"  Status: {status_str(c)}")
    return "\n".join(lines)


def render_attainment(c: Combatant) -> str:
    """Show per-path attainment and how much of each budget is spent this turn."""
    cells = []
    for path, tier in c.attainment.items():
        p = PATHS[path]
        used = c.path_used(path)
        budget = c.path_budget(path)
        tag = colorize(f"{p.symbol}{p.name}", p.color)
        cells.append(f"{tag} {tier} [{used}/{budget}]")
    return "  Attainment: " + " · ".join(cells) if cells else ""


def render_hand(hand: list[Card], combat=None, actor=None) -> str:
    """Render the hand as side-by-side boxed cards.

    If combat+actor are given, cards that cannot currently be played are dimmed
    with a leading '×' on their index label.
    """
    if not hand:
        return "  (empty hand)"
    rendered = [card.render() for card in hand]
    height = max(len(r) for r in rendered)
    header_cells = []
    for i, card in enumerate(hand, 1):
        width = len(card.render()[0])
        playable = True
        if combat and actor:
            playable = combat.can_play(actor, card)[0]
        label = f"[{i}]" if playable else f"×[{i}]"
        header_cells.append(label.center(width))
    lines = ["  ".join(header_cells)]
    for row in range(height):
        cells = []
        for r in rendered:
            cells.append(r[row] if row < len(r) else " " * len(r[0]))
        lines.append("  ".join(cells))
    return "\n".join(lines)


def render_killer_moves(moves: list[KillerMove], combat=None, actor=None) -> str:
    if not moves:
        return ""
    lines = ["Killer Moves (type 'k #'):"]
    for i, km in enumerate(moves, 1):
        p = PATHS[km.path]
        tag = colorize(f"{p.symbol} {km.name}", p.color)
        ok = combat.can_play_killer(actor, km)[0] if (combat and actor) else True
        prefix = f"  k{i}" if ok else f"  ×k{i}"
        lines.append(f"{prefix}) {tag}  [{km.essence_cost} ess] — {km.text}")
    return "\n".join(lines)


def rule(char: str = "═", width: int = 70) -> str:
    return char * width
