"""Hardcoded enemy loadouts for the prototype.

Later these become AI-generated (Sprint 9). For now, a few hand-built foes that
each lean into a path so combat feels distinct.
"""

from __future__ import annotations

from cards import Card, STARTER_GU
from combat import Combatant


def _enemy(name: str, hp: int, essence: int, loadout: list[Card]) -> Combatant:
    e = Combatant(name=name, max_hp=hp, hp=hp, essence=essence,
                  max_essence=essence, is_player=False)
    # Enemies "draw" their whole loadout into hand up front (small loadouts).
    e.hand = [c.copy() for c in loadout]
    return e


def wild_boar() -> Combatant:
    return _enemy("Wild Ravage Boar", 45, 60, [
        STARTER_GU["iron_fist"], STARTER_GU["iron_fist"],
        STARTER_GU["steel_body"],
    ])


def blood_bandit() -> Combatant:
    return _enemy("Blood Path Bandit", 55, 70, [
        STARTER_GU["blood_frenzy"], STARTER_GU["vampiric_touch"],
        STARTER_GU["iron_fist"],
    ])


def poison_hermit() -> Combatant:
    return _enemy("Poison Marsh Hermit", 50, 80, [
        STARTER_GU["venom_strike"], STARTER_GU["venom_strike"],
        STARTER_GU["shadow_strike"],
    ])


ENEMY_LADDER = [wild_boar, blood_bandit, poison_hermit]
