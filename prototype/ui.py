"""Terminal rendering helpers for the card prototype."""

from __future__ import annotations

import sys

import paths
from cards import Card
from combat import Combatant


def init_color() -> None:
    """Force UTF-8 output, disable color if not a tty, enable ANSI on Windows."""
    # The box-drawing and path glyphs need UTF-8; Windows consoles often default
    # to cp1252 which raises UnicodeEncodeError. Reconfigure stdout/stderr.
    for stream in (sys.stdout, sys.stderr):
        try:
            stream.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
        except Exception:
            pass

    if not sys.stdout.isatty():
        paths.COLOR_ENABLED = False
        return
    if sys.platform == "win32":
        # Enable ANSI escape processing on modern Windows terminals.
        try:
            import ctypes
            kernel32 = ctypes.windll.kernel32
            kernel32.SetConsoleMode(kernel32.GetStdHandle(-11), 7)
        except Exception:
            paths.COLOR_ENABLED = False


def hp_bar(cur: int, mx: int, width: int = 20) -> str:
    filled = int(width * cur / mx) if mx else 0
    return "█" * filled + "░" * (width - filled)


def status_str(c: Combatant) -> str:
    bits = []
    if c.shield > 0:
        bits.append(f"Shield {c.shield}")
    for name, st in c.statuses.items():
        bits.append(f"{name.capitalize()} x{st.stacks}")
    return ", ".join(bits) if bits else "None"


def render_combatant(c: Combatant) -> str:
    lines = [
        f"{c.name}",
        f"  HP  {hp_bar(c.hp, c.max_hp)} {c.hp}/{c.max_hp}",
    ]
    if c.is_player:
        lines.append(
            f"  Ess {hp_bar(c.essence, c.max_essence)} "
            f"{c.essence}/{c.max_essence}")
    lines.append(f"  Status: {status_str(c)}")
    return "\n".join(lines)


def render_hand(hand: list[Card]) -> str:
    """Render the hand as side-by-side boxed cards."""
    if not hand:
        return "  (empty hand)"
    rendered = [card.render() for card in hand]
    height = max(len(r) for r in rendered)
    # index labels above each card
    header_cells = []
    for i, card in enumerate(hand, 1):
        width = len(card.render()[0])
        label = f"[{i}]"
        header_cells.append(label.center(width))
    lines = ["  ".join(header_cells)]
    for row in range(height):
        cells = []
        for r in rendered:
            cells.append(r[row] if row < len(r) else " " * len(r[0]))
        lines.append("  ".join(cells))
    return "\n".join(lines)


def rule(char: str = "═", width: int = 70) -> str:
    return char * width
