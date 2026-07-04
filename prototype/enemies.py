"""Hardcoded enemy loadouts for the prototype.

Each enemy leans into a path (with matching attainment so its own synergies
fire) so fights feel distinct. Later these become AI-generated (Sprint 9).
"""

from __future__ import annotations

from cards import Card, GU
from combat import Combatant


def _enemy(name: str, hp: int, essence: int, loadout: list[str],
           attainment: dict[str, str]) -> Combatant:
    e = Combatant(name=name, max_hp=hp, hp=hp, essence=essence,
                  max_essence=essence, is_player=False, attainment=attainment)
    e.hand = [GU[k].copy() for k in loadout]
    return e


def wild_boar() -> Combatant:
    return _enemy("Wild Ravage Boar", 42, 60,
                  ["iron_fist", "rising_blow", "body_harden", "iron_fist"],
                  {"strength": "Adept"})


def blood_bandit() -> Combatant:
    return _enemy("Blood Path Bandit", 55, 80,
                  ["blood_frenzy", "vampiric_touch", "hemorrhage",
                   "iron_fist", "vampiric_touch"],
                  {"blood": "Master", "strength": "Ordinary"})


def poison_hermit() -> Combatant:
    return _enemy("Poison Marsh Hermit", 60, 90,
                  ["venom_bite", "creeping_rot", "wither", "corrosive_pool",
                   "shadow_dagger"],
                  {"poison": "Master", "dark": "Ordinary"})


def shadow_assassin() -> Combatant:
    return _enemy("Gu Yue Traitor", 58, 90,
                  ["shadow_veil", "shadow_dagger", "throat_slit",
                   "night_ambush", "smoke_step", "venom_bite"],
                  {"dark": "Master", "poison": "Ordinary"})


ENEMY_LADDER = [wild_boar, blood_bandit, poison_hermit, shadow_assassin]
