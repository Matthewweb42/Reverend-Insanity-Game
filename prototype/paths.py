"""Cultivation paths and their visual identity (DEC-040).

Path symbols are pure visual identity — a glyph + color per path so a hand of
cards is readable at a glance. No cost/resource mechanic is attached to them.
"""

from __future__ import annotations

from dataclasses import dataclass


# ANSI color codes (foreground). Kept simple; terminals that don't support
# color will just show the raw codes, so COLOR can be disabled globally.
_ANSI = {
    "crimson": "\033[91m",
    "azure": "\033[94m",
    "dark_red": "\033[31m",
    "bronze": "\033[33m",
    "teal": "\033[96m",
    "purple": "\033[95m",
    "green": "\033[92m",
    "indigo": "\033[34m",
    "gold": "\033[93m",
    "amber": "\033[33m",
    "reset": "\033[0m",
}


@dataclass(frozen=True)
class Path:
    key: str
    name: str
    symbol: str
    color: str  # key into _ANSI


PATHS: dict[str, Path] = {
    "strength": Path("strength", "Strength", "✊", "crimson"),
    "wisdom": Path("wisdom", "Wisdom", "◆", "azure"),
    "blood": Path("blood", "Blood", "◈", "dark_red"),
    "refinement": Path("refinement", "Refinement", "⚒", "bronze"),
    "transformation": Path("transformation", "Transformation", "☯", "teal"),
    "enslavement": Path("enslavement", "Enslavement", "⛓", "purple"),
    "poison": Path("poison", "Poison", "☠", "green"),
    "dark": Path("dark", "Dark", "☾", "indigo"),
    "light": Path("light", "Light", "✦", "gold"),
    "food": Path("food", "Food", "◍", "amber"),
}

# Whether to emit ANSI color codes. Toggled off automatically if stdout is not
# a tty (see ui.py).
COLOR_ENABLED = True


def colorize(text: str, color_key: str) -> str:
    if not COLOR_ENABLED:
        return text
    code = _ANSI.get(color_key, "")
    if not code:
        return text
    return f"{code}{text}{_ANSI['reset']}"


def path_symbol(path_key: str) -> str:
    p = PATHS.get(path_key)
    return p.symbol if p else "?"


def path_tag(path_key: str) -> str:
    """Colored '<symbol> <Name>' for headers."""
    p = PATHS.get(path_key)
    if not p:
        return path_key
    return colorize(f"{p.symbol} {p.name}", p.color)
