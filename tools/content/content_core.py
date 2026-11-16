"""Core content tables: paths, statuses, Gu, killer moves, materials.

Run tools/content/build_content.py to regenerate game/data/*.json.
Numbers follow docs/Content/Gu.md 'Balance Guidelines' (per-rank cost, damage,
shield ranges) and the rarity modifiers (+15% / +30% / +50% primary effect).
"""
import re

# --- Paths (DEC-040 symbol + colour) -----------------------------------------
PATHS = [
    # id, name, symbol, colour, engine blurb, icon
    ("strength", "Strength", "✊", "#DC2F45", "Build a combo with every attack, then cash it in.", "fist"),
    ("wisdom", "Wisdom", "◆", "#3A8EE6", "Draw, reveal intent, cheapen your next Gu.", "brain"),
    ("blood", "Blood", "◈", "#B3122A", "Pay in HP, drink it back, hit harder when wounded.", "blood"),
    ("refinement", "Refinement", "⚒", "#CD7F32", "Forge temporary Gu mid-fight and upgrade your hand.", "anvil"),
    ("transformation", "Transformation", "☯", "#20B2AA", "Take on forms and mimic your foe.", "yin-yang"),
    ("enslavement", "Enslavement", "⛓", "#9B59B6", "Summon beasts, control and steal.", "crossed-chains"),
    ("poison", "Poison", "☠", "#9ACD32", "Stack venom, multiply it, detonate it.", "poison"),
    ("dark", "Dark", "☾", "#6A5ACD", "Vanish into stealth and execute the weakened.", "evil-moon"),
    ("light", "Light", "✦", "#FFD34D", "Layer shields of light, then release them as a burst.", "sun"),
    ("food", "Food", "◍", "#FFB000", "Feast on essence and turn plenty into power.", "bowl-of-rice"),
    ("fire", "Fire", "♨", "#FF6A2A", "Kindle burning stacks that rage then fade (Chi clan).", "flame"),
    ("none", "Neutral", "○", "#B8AFA2", "Utility Gu with no path. Not limited by attainment.", "circle"),
]

STATUSES = {
    "burn": {"name": "Burning", "icon": "flame", "debuff": True, "desc": "Takes 3 damage per stack each turn; loses 1 stack per turn."},
    "poison": {"name": "Poisoned", "icon": "poison-bottle", "debuff": True, "desc": "Takes 1 damage per stack each turn. Stacks do not fade on their own."},
    "bleed": {"name": "Bleeding", "icon": "droplets", "debuff": True, "desc": "Takes 2 damage per stack each turn; loses 1 stack per turn."},
    "stun": {"name": "Stunned", "icon": "knocked-out-stars", "debuff": True, "desc": "Skips its next action."},
    "slow": {"name": "Slowed", "icon": "snail", "debuff": True, "desc": "Draws one fewer card; enemies deal 15% less."},
    "weak": {"name": "Weakened", "icon": "broken-bone", "debuff": True, "desc": "Deals 25% less damage."},
    "vuln": {"name": "Vulnerable", "icon": "cracked-shield", "debuff": True, "desc": "Takes 25% more damage."},
    "root": {"name": "Rooted", "icon": "tree-roots", "debuff": True, "desc": "Cannot flee; -15 evasion."},
    "strong": {"name": "Strengthened", "icon": "biceps", "debuff": False, "desc": "Deals 25% more damage."},
    "prot": {"name": "Protected", "icon": "checked-shield", "debuff": False, "desc": "Takes 25% less damage."},
    "stealth": {"name": "Stealthed", "icon": "cloak-dagger", "debuff": False, "desc": "+40 evasion. Next attack deals +50% and breaks stealth."},
    "regen": {"name": "Regenerating", "icon": "heart-plus", "debuff": False, "desc": "Heals 3 per stack each turn."},
    "thorns": {"name": "Thorned", "icon": "thorny-vine", "debuff": False, "desc": "Attackers take damage equal to stacks."},
    "control": {"name": "Controlled", "icon": "puppet", "debuff": True, "desc": "Its next action strikes its own ally (or nothing)."},
}

FORMS = {
    "beast": {"name": "Beast Form", "desc": "+30% damage, -10 evasion"},
    "stone": {"name": "Stone Form", "desc": "Takes 40% less damage, rooted"},
    "wind": {"name": "Wind Form", "desc": "+30 evasion, draw +1 each turn"},
    "blood": {"name": "Blood Form", "desc": "Heal 20% of damage dealt"},
    "bone": {"name": "Bone Form", "desc": "Attackers take 4 x rank damage"},
}

RARITY_MULT = {"common": 1.0, "uncommon": 1.15, "rare": 1.3, "legendary": 1.5}
FEED_COST = {1: 2, 2: 5, 3: 12, 4: 30, 5: 75, 6: 150, 7: 300, 8: 600, 9: 1200}
BASE_VALUE = {1: 30, 2: 90, 3: 260, 4: 700, 5: 1800, 6: 5000, 7: 12000, 8: 30000, 9: 80000}


def slug(name):
    s = name.lower().replace("'", "")
    s = re.sub(r"[^a-z0-9]+", "_", s).strip("_")
    return s[:-3] if s.endswith("_gu") else s


GU = []


def gu(name, path, rank, rarity, cost, eff, kind="attack", flags=None, icon=None,
       flavor="", clan=None, tags=None, passive=None, consumable=None, target="enemy",
       pool=True):
    mult = RARITY_MULT[rarity]
    out = []
    for e in eff:
        e = dict(e)
        if "n" in e and e.get("v") in ("damage", "heal", "shield") and not e.get("raw"):
            e["n"] = int(round(e["n"] * mult))
        e.pop("raw", None)
        out.append(e)
    g = {
        "id": slug(name), "name": name, "path": path, "rank": rank, "rarity": rarity,
        "cost": cost, "effects": out, "kind": kind, "flags": flags or [],
        "icon": icon or "crystal-growth", "flavor": flavor, "target": target,
        "tags": tags or [], "feed": FEED_COST[rank],
        "value": int(BASE_VALUE[rank] * mult),
        "pool": pool,
    }
    if clan:
        g["clan"] = clan
        g["pool"] = False
    if passive:
        g["passive"] = passive
    if consumable:
        g["consumable"] = consumable
    GU.append(g)
    return g


# effect helpers -------------------------------------------------------------
def D(n, **k): return dict(v="damage", n=n, **k)
def H(n, **k): return dict(v="heal", n=n, **k)
def S(n, **k): return dict(v="shield", n=n, **k)
def ST(s, stacks, turns=3, t="enemy"): return dict(v="status", s=s, stacks=stacks, turns=turns, t=t)
def BUFF(s, stacks=1, turns=2): return ST(s, stacks, turns, "self")
def E(v, **k):
    d = dict(v=v)
    d.update(k)
    return d


# ===================== STRENGTH (combo engine) ===============================
gu("Iron Fist Gu", "strength", 1, "common", 7, [D(13), E("combo", n=1)], icon="fist", tags=["fist"],
   flavor="Plain iron, plainly applied.", clan="xiong")
gu("Bone Spike Gu", "strength", 1, "common", 8, [D(12), ST("bleed", 1, 3), E("combo", n=1)], icon="bone-knife",
   tags=["bone"], flavor="A spur of bone driven out through the palm.", clan="bai")
gu("Brute Force Gu", "strength", 1, "common", 6, [D(11), E("combo", n=1)], icon="punch", tags=["fist"],
   flavor="Some answers need no subtlety.")
gu("Black Boar Gu", "strength", 1, "uncommon", 9, [BUFF("strong", 1, 2), E("combo", n=1)], kind="support",
   icon="boar", tags=["beast"], flavor="The strength of a black boar, borrowed for a moment.", target="self")
gu("Rolling Fist Gu", "strength", 2, "common", 14, [E("dmg_combo", base=14, per=6)], icon="fulguro-punch",
   tags=["fist"], flavor="Every blow you have landed rides behind this one.")
gu("White Boar Gu", "strength", 2, "uncommon", 16, [D(24), BUFF("strong", 1, 2), E("combo", n=1)], icon="boar-tusks",
   tags=["beast"], flavor="Pale bristles, iron hide.")
gu("Bear Strength Gu", "strength", 2, "uncommon", 15, [BUFF("strong", 1, 3), E("combo", n=2)], kind="support",
   icon="bear-head", clan="xiong", target="self", flavor="A bear's patience; a bear's arms.")
gu("Thick Skin Gu", "strength", 2, "common", 12, [S(32), BUFF("prot", 1, 2)], kind="defense", icon="leather-armor",
   clan="xiong", target="self", flavor="Hide like old leather.")
gu("Bone Armor Gu", "strength", 2, "uncommon", 14, [S(36), BUFF("thorns", 4, 3)], kind="defense", icon="backbone-shell",
   clan="bai", tags=["bone"], target="self", flavor="Armour grown from your own skeleton.")
gu("Bone Blade Gu", "strength", 2, "uncommon", 16, [D(28), ST("bleed", 2, 3), E("combo", n=1)], icon="bone-mace",
   clan="bai", tags=["bone"], flavor="Grow the weapon you need.")
gu("Hundred Strikes Gu", "strength", 3, "rare", 30, [D(14, times=3), E("combo", n=3)], icon="punch-blast",
   tags=["fist"], flavor="Not one hundred. But it feels like it.")
gu("Mountain Stance Gu", "strength", 3, "uncommon", 26, [S(60), BUFF("prot", 1, 3), E("combo", n=1)], kind="defense",
   icon="mountain-road", clan="xiong", target="self", flavor="Plant your feet like the roots of a mountain.")
gu("Skeletal Reinforcement Gu", "strength", 3, "rare", 28, [BUFF("strong", 2, 3), S(40)], kind="support",
   icon="skeleton", clan="bai", tags=["bone"], target="self", flavor="Bones like bronze.")
gu("Dragon Strength Gu", "strength", 4, "rare", 45, [E("dmg_combo", base=55, per=10), E("combo", n=1)],
   icon="dragon-head", tags=["fist", "beast"], flavor="One dragon's might. Few bodies can hold it.")
gu("Titan's Grip Gu", "strength", 4, "rare", 48, [D(70), ST("stun", 1, 1), E("combo", n=1)], icon="grab",
   clan="xiong", flavor="Grab. Crush. Done.")
gu("Sovereign Strength Gu", "strength", 5, "legendary", 70, [D(100, pierce=True), E("combo", n=2)],
   icon="thor-fist", tags=["fist"], flavor="When the sovereign strikes, even the heavens tremble.")

# ===================== WISDOM (draw / reveal / discount) =====================
gu("Insight Gu", "wisdom", 1, "common", 6, [E("draw", n=1), E("reveal", n=2)], kind="support", icon="eyeball",
   target="self", flavor="See a little more than you did.")
gu("Wise Thought Gu", "wisdom", 1, "common", 8, [D(10), E("draw", n=1)], icon="brain", flavor="A thought sharp enough to cut.")
gu("Suggestion Gu", "enslavement", 1, "common", 8, [ST("weak", 1, 2), E("draw", n=1)], kind="support", icon="psychic-waves",
   clan="shang", tags=["control"], flavor="You were going to do that anyway.")
gu("Clear Mind Gu", "wisdom", 2, "uncommon", 12, [E("draw", n=2), E("cheapen", n=1)], kind="support", icon="brainstorm",
   target="self", flavor="Clarity costs less than confusion.")
gu("Thought Spear Gu", "wisdom", 2, "common", 16, [D(26), E("reveal", n=1)], icon="spear-feather",
   flavor="Read the gap; strike it.")
gu("Information Network Gu", "wisdom", 3, "rare", 24, [E("draw", n=2), E("reveal", n=3), BUFF("strong", 1, 2)],
   kind="support", icon="spider-web", clan="shang", target="self", flavor="Whispers from a hundred mouths.")
gu("Myriad Thoughts Gu", "wisdom", 3, "uncommon", 30, [D(30), E("draw", n=2), E("cheapen", n=1)], icon="brain-tentacle",
   flavor="Ten thousand thoughts, all of them yours.")
gu("Lunar Reflection Gu", "wisdom", 3, "rare", 28, [S(55), BUFF("thorns", 8, 2)], kind="defense", icon="crystal-shine",
   clan="gu_yue", tags=["moon"], target="self", flavor="The moon returns what you give it.")
gu("Heaven's Calculation Gu", "wisdom", 4, "rare", 42, [D(60), E("draw", n=2), E("reveal", n=3)], icon="crystal-ball",
   flavor="The dao is arithmetic, if you are patient.")
gu("Star Thought Gu", "wisdom", 5, "legendary", 60, [D(90), E("draw", n=3), E("cheapen", n=2)], icon="star-swirl",
   flavor="A thought as bright as a falling star.")

# ===================== BLOOD (pay HP, lifesteal, low-HP) =====================
gu("Blood Drop Gu", "blood", 1, "common", 5, [E("self_damage", n=5), D(16)], icon="droplets",
   flavor="One drop; one blow.")
gu("Blood Leech Gu", "blood", 1, "common", 8, [D(12, lifesteal=0.5)], icon="leeching-worm", flavor="It drinks, so you may.")
gu("Blood Qi Gu", "blood", 2, "uncommon", 14, [E("self_damage", n=8), BUFF("strong", 1, 2), E("essence", n=10)],
   kind="support", icon="heart-drop", target="self", flavor="Burn your blood for a moment's power.")
gu("Blood Moon Blade Gu", "blood", 2, "common", 15, [D(24), ST("bleed", 2, 3)], icon="bloody-sword",
   flavor="It cuts twice: once going in, once coming out.")
gu("Wound Drinker Gu", "blood", 3, "rare", 26, [E("dmg_missing_hp", pct=0.35, base=20)], icon="bleeding-heart",
   flavor="The closer you are to death, the more it gives.")
gu("Blood Sacrifice Gu", "blood", 3, "rare", 20, [E("self_damage", n=30), E("essence", n=50), BUFF("strong", 2, 1)],
   kind="support", icon="sacrificial-dagger", target="self",
   flavor="Power demands payment in the most precious currency: life itself.")
gu("Crimson Tide Gu", "blood", 4, "rare", 44, [D(64, lifesteal=0.4), ST("bleed", 3, 3)], icon="big-wave",
   flavor="A red tide, and it is rising.")
gu("Blood Skull Gu", "blood", 5, "legendary", 66, [E("self_damage", n=40), D(120, lifesteal=0.5)], icon="crowned-skull",
   flavor="The fiend's own treasure.")

# ===================== REFINEMENT (forge temp Gu, upgrade hand) ==============
gu("Spark Forge Gu", "refinement", 1, "common", 8, [E("create", card="ember_spark", n=2)], kind="support",
   icon="anvil", target="self", flavor="Two sparks off the anvil, each with a bite.")
gu("Tempering Gu", "refinement", 1, "common", 7, [E("upgrade_hand", pct=0.15), S(10)], kind="support",
   icon="anvil-impact", target="self", flavor="Heat, hammer, quench.")
gu("Smelting Gu", "refinement", 2, "uncommon", 14, [D(22), E("create", card="ember_spark", n=1)],
   icon="cauldron", flavor="Melt the enemy's guard into slag.")
gu("Gu Refining Furnace Gu", "refinement", 3, "rare", 26, [E("create", card="forged_blade", n=2), E("upgrade_hand", pct=0.2)],
   kind="support", icon="furnace", target="self", flavor="A furnace small enough to carry.")
gu("Moon Smith Gu", "refinement", 3, "uncommon", 28, [D(42), E("upgrade_hand", pct=0.1)], icon="hammer-drop",
   tags=["moon"], flavor="Moonlight, hammered thin.")
gu("Ten Thousand Forgings Gu", "refinement", 4, "rare", 46, [E("create", card="forged_blade", n=3), E("upgrade_hand", pct=0.3)],
   kind="support", icon="gear-hammer", target="self", flavor="Every Gu Master's dream workshop.")
gu("Heaven Forge Gu", "refinement", 5, "legendary", 64, [D(95), E("create", card="heaven_spear", n=1), E("upgrade_hand", pct=0.3)],
   icon="thor-hammer", flavor="It forged the stars, they say.")
# temporary cards created mid-fight (never in pools)
gu("Ember Spark Gu", "refinement", 1, "common", 0, [D(8)], icon="fire-ray", flags=["temporary", "quick"], pool=False,
   flavor="Here and gone.")
gu("Forged Blade Gu", "refinement", 3, "common", 0, [D(26)], icon="shard-sword", flags=["temporary", "quick"], pool=False,
   flavor="Still hot.")
gu("Heaven Spear Gu", "refinement", 5, "common", 0, [D(70, pierce=True)], icon="sun-spear", flags=["temporary"], pool=False,
   flavor="A spear of white-hot light.")

# ===================== TRANSFORMATION (forms, mimic) =========================
gu("Beast Skin Gu", "transformation", 1, "common", 9, [E("form", form="beast", turns=3), D(8)], icon="wolf-head",
   flavor="Fur, fang and appetite.")
gu("Stone Skin Gu", "transformation", 1, "common", 8, [E("form", form="stone", turns=2), S(14)], kind="defense",
   icon="stone-block", target="self", flavor="For a while, you are a boulder.")
gu("Wind Body Gu", "transformation", 2, "uncommon", 14, [E("form", form="wind", turns=3), D(14)], icon="whirlwind",
   flavor="Hard to hit what is mostly air.")
gu("Mimic Gu", "transformation", 2, "rare", 12, [E("mimic")], kind="support", icon="mimic-chest", target="self",
   flavor="Watch closely. Then do it back.")
gu("Blood Wolf Form Gu", "transformation", 3, "uncommon", 28, [E("form", form="blood", turns=3), D(40)], icon="werewolf",
   flavor="The wolf drinks deep.")
gu("White Bone Transformation Gu", "transformation", 4, "rare", 44, [E("form", form="bone", turns=4), S(60), D(40)],
   icon="dinosaur-bones", clan="bai", tags=["bone"], flavor="Become the white bone beast.")
gu("Thousand Shapes Gu", "transformation", 4, "rare", 48, [E("form", form="beast", turns=3), E("form", form="wind", turns=3), D(55)],
   icon="dragon-spiral", flavor="No shape holds you long.")
gu("Myriad Transformations Gu", "transformation", 5, "legendary", 66, [E("form", form="beast", turns=4), E("form", form="stone", turns=2), D(100)],
   icon="double-dragon", flavor="Every form, all at once.")

# ===================== ENSLAVEMENT (summons, control, steal) =================
gu("Wolf Slave Gu", "enslavement", 1, "common", 10, [E("summon", name="Grey Wolf", hp=22, atk=6, icon="wolf-head", turns=4)],
   kind="support", icon="wolf-howl", tags=["control", "beast"], target="self", flavor="A wolf that answers to you.")
gu("Essence Thief Gu", "enslavement", 1, "uncommon", 6, [D(8), E("steal_essence", n=8)], icon="robber-hand",
   flavor="What's yours is mine.")
gu("Puppet Thread Gu", "enslavement", 2, "uncommon", 16, [ST("control", 1, 1), D(14)], icon="puppet", clan="shang",
   tags=["control"], flavor="Dance.")
gu("Soul Contract Gu", "enslavement", 2, "rare", 14, [ST("weak", 2, 3), ST("vuln", 1, 2), E("steal_essence", n=10)],
   kind="support", icon="scroll-quill", clan="shang", tags=["control"], flavor="Sign here. And here. And here.")
gu("Beast Tide Gu", "enslavement", 3, "uncommon", 30, [E("summon", name="Thunder Wolf", hp=55, atk=16, icon="direwolf", turns=4)],
   kind="support", icon="wolf-trap", tags=["control", "beast"], target="self", flavor="Call, and the pack comes.")
gu("Bone Puppet Gu", "enslavement", 3, "rare", 28, [E("summon", name="Bone Puppet", hp=70, atk=14, icon="skeleton", turns=5), BUFF("thorns", 4, 3)],
   kind="support", icon="skeleton", clan="bai", tags=["bone", "control"], target="self", flavor="Bones that walk at your word.")
gu("Dominating Presence Gu", "enslavement", 3, "rare", 26, [ST("weak", 2, 3), ST("stun", 1, 1)], kind="support",
   icon="crown", clan="xiong", tags=["control"], flavor="Kneel.")
gu("Shadow Servant Gu", "enslavement", 3, "rare", 28, [E("summon", name="Shadow Servant", hp=40, atk=22, icon="ghost", turns=4), BUFF("stealth", 1, 1)],
   kind="support", icon="ghost-ally", clan="shang", tags=["control"], target="self", flavor="It is always one step behind you.")
gu("Master's Voice Gu", "enslavement", 4, "rare", 46, [ST("control", 1, 2), ST("weak", 2, 3), E("steal_essence", n=25)],
   kind="support", icon="lightning-shout", clan="shang", tags=["control"], flavor="One voice, and they obey.")
gu("Beast King Gu", "enslavement", 4, "rare", 50, [E("summon", name="Beast King", hp=140, atk=30, icon="tiger-head", turns=5)],
   kind="support", icon="tiger", tags=["control", "beast"], target="self", flavor="Even beast kings need a master.")
gu("Myriad Slaves Gu", "enslavement", 5, "legendary", 70, [E("summon", name="Beast Horde", hp=220, atk=45, icon="direwolf", turns=5), ST("control", 1, 1)],
   kind="support", icon="crossed-chains", tags=["control", "beast"], target="self", flavor="An army on a chain.")

# ===================== POISON (stacks / multiply / detonate) =================
gu("Venom Needle Gu", "poison", 1, "common", 6, [D(6), ST("poison", 3, 6)], icon="spiked-tail", flavor="Small. Patient. Fatal.")
gu("Toxic Cloud Gu", "poison", 1, "common", 9, [ST("poison", 4, 6, "all")], icon="poison-cloud", target="all",
   flavor="Breathe deep.")
gu("Rot Spreading Gu", "poison", 2, "uncommon", 14, [E("multiply_status", s="poison", x=2)], kind="support",
   icon="goo-skull", flavor="What is rotten makes more rot.")
gu("Scorpion Tail Gu", "poison", 2, "common", 15, [D(18), ST("poison", 5, 6)], icon="scorpion-tail", flavor="Sting, then wait.")
gu("Plague Detonation Gu", "poison", 3, "rare", 26, [E("detonate", s="poison", mult=2.5)], icon="poison-gas",
   flavor="All of it, at once.")
gu("Myriad Venom Gu", "poison", 3, "uncommon", 28, [D(20), ST("poison", 9, 6), ST("weak", 1, 2)], icon="snake-bite",
   flavor="Ten thousand bites, one at a time.")
gu("Seven-Step Poison Gu", "poison", 4, "rare", 46, [ST("poison", 16, 7), ST("slow", 1, 2), D(30)], icon="poison-bottle",
   flavor="Take seven steps. You won't take an eighth.")
gu("Ten Thousand Venoms Gu", "poison", 5, "legendary", 66, [ST("poison", 22, 8, "all"), E("multiply_status", s="poison", x=2)],
   icon="snake-spiral", target="all", flavor="The air itself turns to venom.")

# ===================== DARK (stealth / execute) ==============================
gu("Shadow Step Gu", "dark", 1, "common", 7, [BUFF("stealth", 1, 2), E("draw", n=1)], kind="support", icon="cloak-dagger",
   target="self", flags=["quick"], flavor="Step out of the light.")
gu("Night Blade Gu", "dark", 1, "common", 8, [D(12, bd=0.5)], icon="plain-dagger", flavor="Twice as sharp against the hurt.")
gu("Darkness Shroud Gu", "dark", 2, "uncommon", 14, [BUFF("stealth", 1, 2), ST("vuln", 1, 2)], kind="support",
   icon="hood", flavor="Your foe cannot see where the blow comes from.")
gu("Reaper's Mark Gu", "dark", 2, "uncommon", 16, [E("execute", pct=0.2, n=20)], icon="reaper-scythe",
   flavor="When they falter, finish it.")
gu("Moonless Night Gu", "dark", 3, "rare", 28, [D(36, bd=0.6), ST("weak", 1, 2)], icon="evil-moon", flavor="No moon. No mercy.")
gu("Soul Shadow Gu", "dark", 3, "uncommon", 26, [BUFF("stealth", 1, 2), D(32)], icon="lightning-shadow", flavor="A shadow with teeth.")
gu("Abyss Gu", "dark", 4, "rare", 46, [E("execute", pct=0.25, n=60), ST("vuln", 2, 2)], icon="vortex", flavor="Look into it, if you dare.")
gu("Eternal Night Gu", "dark", 5, "legendary", 68, [BUFF("stealth", 2, 2), E("execute", pct=0.3, n=95)], icon="death-skull",
   flavor="Night that never ends.")

# ===================== LIGHT (shields -> burst) ==============================
gu("Moonlight Gu", "light", 1, "common", 8, [D(14)], icon="moon", tags=["moon"], clan="gu_yue",
   flavor="Pale light, sharp edge.")
gu("Light Shield Gu", "light", 1, "common", 7, [S(18)], kind="defense", icon="magic-shield", target="self",
   flavor="A thin skin of radiance.")
gu("Sunray Gu", "light", 1, "common", 9, [D(10), S(8)], icon="sunbeams", flavor="Warm on one side, scorching on the other.")
gu("Radiant Burst Gu", "light", 2, "uncommon", 14, [E("dmg_shield", mult=1.0, consume=True), S(6)], icon="sun-radiations",
   flavor="Everything you held back, released.")
gu("Moonlight Blade Gu", "light", 2, "uncommon", 16, [D(26)], icon="crescent-blade", clan="gu_yue", tags=["moon"],
   flavor="The clan's signature edge.")
gu("Crescent Shield Gu", "light", 2, "uncommon", 13, [S(34), E("shield_pct_hp", pct=0.05)], kind="defense",
   icon="moon-orbit", clan="gu_yue", tags=["moon"], target="self", flavor="Brighter at night.")
gu("Moon Phase Gu", "light", 3, "rare", 26, [S(40), D(30)], icon="moon-claws", clan="gu_yue", tags=["moon"],
   flavor="Wax, wane, strike.")
gu("Moonblade Gu", "light", 3, "rare", 35, [D(46), E("reveal", n=1)], icon="crescent-blade", tags=["moon"],
   flavor="Forged from condensed moonlight, it cuts through darkness.")
gu("Golden Light Gu", "light", 3, "uncommon", 24, [E("shield_pct_hp", pct=0.25), BUFF("prot", 1, 2)], kind="defense",
   icon="sunrise", target="self", flavor="A wall of dawn.")
gu("Full Moon Gu", "light", 4, "rare", 50, [D(75), E("dmg_shield", mult=0.5, consume=False)], icon="moon", clan="gu_yue",
   tags=["moon"], flavor="Massive power beneath the full moon.")
gu("Dawn Bulwark Gu", "light", 4, "uncommon", 40, [S(90), E("shield_pct_hp", pct=0.1)], kind="defense", icon="sun-cloud",
   target="self", flavor="The sun rises on your side of the field.")
gu("Heavenly Light Gu", "light", 5, "legendary", 66, [S(120), E("dmg_shield", mult=1.2, consume=True)], icon="sun",
   flavor="Light from beyond the heavens.")

# ===================== FOOD (essence economy) ================================
gu("Liquor Worm Gu", "food", 1, "common", 4, [E("essence", n=14), H(4)], kind="support", icon="earth-worm", target="self",
   flavor="It likes wine. It refines essence. Everyone wins.")
gu("Feast Gu", "food", 1, "uncommon", 10, [E("dmg_essence", pct=0.2, base=6)], icon="meat", flavor="Strength from plenty.")
gu("Honey Gu", "food", 2, "common", 12, [H(26), BUFF("regen", 2, 3)], kind="support", icon="beehive", target="self",
   flavor="Sweet, golden, healing.")
gu("Rice Bag Gu", "food", 2, "uncommon", 8, [E("essence", n=28), E("draw", n=1)], kind="support", icon="bowl-of-rice",
   target="self", flags=["quick"], flavor="Never go hungry.")
gu("Gluttony Gu", "food", 3, "rare", 26, [E("dmg_essence", pct=0.3, base=20), E("essence", n=15)], icon="pizza-cutter",
   flavor="Eat. Then eat them.")
gu("Spring Autumn Feast Gu", "food", 4, "rare", 40, [E("essence", n=70), H(50), BUFF("regen", 3, 3)], kind="support",
   icon="berries-bowl", target="self", flavor="A banquet for every season.")
gu("Heaven's Banquet Gu", "food", 5, "legendary", 60, [E("dmg_essence", pct=0.35, base=40), E("essence", n=60), H(60)],
   icon="fruit-bowl", flavor="The heavens set a table for you.")

# ===================== FIRE (Chi clan unlock) ================================
gu("Basic Flame Gu", "fire", 1, "common", 8, [D(12), ST("burn", 2, 3)], icon="flame", flavor="The simplest flame, but fire still burns.")
gu("Fire Bowl Gu", "fire", 2, "uncommon", 15, [ST("burn", 4, 4, "all"), D(10)], icon="fire-bowl", target="all",
   flavor="Pour it out.")
gu("Flame Lotus Gu", "fire", 3, "rare", 28, [D(36), ST("burn", 5, 4)], icon="lotus-flower", flavor="It blooms in ash.")
gu("Firestorm Gu", "fire", 4, "rare", 46, [D(40), E("detonate", s="burn", mult=4.0)], icon="fire-wave", flavor="Fan the flames, then let them roar.")
gu("Phoenix Fire Gu", "fire", 5, "legendary", 66, [D(90), ST("burn", 8, 4, "all"), H(30)], icon="fire-tail", flavor="It rises from its own ashes.")

# ===================== NEUTRAL utility / passive / consumable ================
gu("Swift Steps Gu", "none", 1, "uncommon", 10, [BUFF("stealth", 1, 1), E("draw", n=1)], kind="support", icon="running-shoe",
   target="self", flags=["quick"], passive={"travel_mult": 0.75, "flee": 10},
   flavor="The journey of a thousand miles begins with a swift step.")
gu("Jade Skin Gu", "none", 1, "common", 6, [S(16)], kind="defense", icon="beveled-star", target="self",
   flavor="Smooth, cool, hard.")
gu("Cloud Walker Gu", "none", 3, "rare", 24, [BUFF("stealth", 1, 2), E("draw", n=1)], kind="support", icon="fluffy-cloud",
   target="self", flags=["quick"], passive={"travel_mult": 0.5, "flee": 20}, flavor="Walk on clouds; arrive before word of you does.")
gu("Starlight Wings Gu", "none", 5, "legendary", 40, [BUFF("stealth", 2, 2), E("draw", n=2)], kind="support", icon="angel-wings",
   target="self", flags=["quick"], passive={"travel_mult": 0.33, "flee": 35}, flavor="Wings of starlight. Distance means nothing.")
# passive-only Gu (occupy an aperture slot, never drawn)
gu("Spring Autumn Cicada Gu", "none", 2, "rare", 0, [], kind="passive", icon="butterfly", flags=["passive"],
   passive={"cult_bonus": 1.5}, flavor="It remembers the springs and autumns of a hundred lives.")
gu("Primeval Moss Gu", "none", 1, "common", 0, [], kind="passive", icon="flower-twirl", flags=["passive"],
   passive={"cult_bonus": 1.2}, flavor="Soaks up primeval essence in the corners of your aperture.")
gu("Heaven Earth Lotus Gu", "none", 4, "legendary", 0, [], kind="passive", icon="lotus", flags=["passive"],
   passive={"cult_bonus": 2.0}, flavor="Its petals open and the dao pours in.")
gu("Stillwater Gu", "none", 1, "uncommon", 0, [], kind="passive", icon="water-drop", flags=["passive"],
   passive={"decay": 0.1}, flavor="Keeps your aperture calm while you are away.")
gu("Gourmand Pouch Gu", "food", 2, "uncommon", 0, [], kind="passive", icon="knapsack", flags=["passive"],
   passive={"feed_mult": 0.75}, flavor="Feeds your other Gu from leftovers.")
gu("Soul Guard Gu", "none", 3, "rare", 0, [], kind="passive", icon="eye-shield", flags=["passive"],
   passive={"soul_guard": True}, flavor="Keeps the miasma of Dang Hun Mountain out of your head.")
gu("Treasure Pouch Gu", "none", 1, "common", 0, [], kind="passive", icon="swap-bag", flags=["passive"],
   passive={"storage": 10, "carry": 40}, flavor="Bigger on the inside.")
gu("Heavenly Eye Gu", "wisdom", 2, "rare", 0, [], kind="passive", icon="all-seeing-eye", flags=["passive"],
   passive={"wisdom": 25}, flavor="See the odds behind every choice.")
# consumables (used from storage, not equipped)
gu("Relic Gu", "none", 1, "rare", 0, [], kind="consumable", icon="gem-pendant", flags=["consumable"],
   consumable={"kind": "relic"}, flavor="Advances your cultivation by one stage. Cannot cross a rank.")
gu("Longevity Gu", "none", 2, "rare", 0, [], kind="consumable", icon="hourglass", flags=["consumable"],
   consumable={"kind": "lifespan", "years": 5}, flavor="Five more years of life.")
gu("Ten Years Longevity Gu", "none", 3, "rare", 0, [], kind="consumable", icon="empty-hourglass", flags=["consumable"],
   consumable={"kind": "lifespan", "years": 10}, flavor="A decade, in a shell the size of a walnut.")
gu("Fifteen Years Longevity Gu", "none", 4, "legendary", 0, [], kind="consumable", icon="sundial", flags=["consumable"],
   consumable={"kind": "lifespan", "years": 15}, flavor="Fifteen years. Treat it like a fortune.")
gu("Fifty Years Longevity Gu", "none", 6, "legendary", 0, [], kind="consumable", icon="sands-of-time", flags=["consumable"],
   consumable={"kind": "lifespan", "years": 50}, flavor="An immortal treasure. Half a lifetime.")
gu("Hundred Years Longevity Gu", "none", 7, "legendary", 0, [], kind="consumable", icon="star-cycle", flags=["consumable"],
   consumable={"kind": "lifespan", "years": 100}, flavor="A century of life. Wars are fought over these.")
gu("Breakthrough Pill Gu", "none", 1, "uncommon", 0, [], kind="consumable", icon="pill-drop", flags=["consumable"],
   consumable={"kind": "breakthrough", "bonus": 10}, flavor="+10% to your next breakthrough attempt.")
gu("Dao Insight Gu", "none", 3, "rare", 0, [], kind="consumable", icon="gift-of-knowledge", flags=["consumable"],
   consumable={"kind": "breakthrough", "bonus": 20}, flavor="+20% to your next breakthrough attempt.")
gu("Healing Spring Gu", "none", 1, "common", 0, [], kind="consumable", icon="health-potion", flags=["consumable"],
   consumable={"kind": "heal_injury"}, flavor="Mends an injury overnight.")
gu("Three Kings Key Gu", "none", 5, "legendary", 0, [], kind="consumable", icon="three-keys", flags=["consumable", "key"],
   consumable={"kind": "key"}, pool=False, flavor="Opens the way into the Three Kings Blessed Land.")

# ===================== IMMORTAL Gu (rank 6-8) ================================
gu("Immortal Moonlight Gu", "light", 6, "legendary", 240, [D(320), S(200)], icon="moon", tags=["moon"], flavor="A Gu Immortal's moon.")
gu("Immortal Strength Gu", "strength", 6, "legendary", 230, [E("dmg_combo", base=280, per=40), E("combo", n=2)], icon="thor-fist",
   tags=["fist"], flavor="Strength that cracks mountains.")
gu("Immortal Venom Gu", "poison", 6, "legendary", 230, [ST("poison", 80, 8, "all"), D(120)], icon="snake-spiral", target="all",
   flavor="Rivers of venom.")
gu("Immortal Blood Gu", "blood", 6, "legendary", 220, [E("self_damage", n=100), D(420, lifesteal=0.5)], icon="crowned-skull",
   flavor="Blood path at the immortal level.")
gu("Immortal Shadow Gu", "dark", 6, "legendary", 230, [BUFF("stealth", 2, 2), E("execute", pct=0.3, n=330)], icon="death-skull",
   flavor="The shadow that ate a sect.")
gu("Immortal Insight Gu", "wisdom", 6, "legendary", 200, [D(260), E("draw", n=3), E("cheapen", n=2)], icon="crystal-ball",
   flavor="It knew you would read this.")
gu("Immortal Feast Gu", "food", 6, "legendary", 180, [E("essence", n=400), E("dmg_essence", pct=0.3, base=120), H(200)], icon="fruit-bowl",
   flavor="Eat the heavens.")
gu("Immortal Forge Gu", "refinement", 6, "legendary", 230, [D(300), E("create", card="heaven_spear", n=2), E("upgrade_hand", pct=0.3)],
   icon="thor-hammer", flavor="A furnace the size of a fist that never cools.")
gu("Immortal Form Gu", "transformation", 6, "legendary", 230, [E("form", form="beast", turns=4), E("form", form="stone", turns=2), D(330)],
   icon="double-dragon", flavor="Change your shape; change your fate.")
gu("Immortal Dominion Gu", "enslavement", 6, "legendary", 240, [E("summon", name="Immortal Beast", hp=900, atk=130, icon="dragon-head", turns=5), ST("control", 1, 1)],
   kind="support", icon="crossed-chains", target="self", flavor="A beast the size of a hill, on a leash.")
gu("Immortal Phoenix Gu", "fire", 6, "legendary", 230, [D(300), ST("burn", 25, 4, "all")], icon="fire-tail", flavor="It burns the sky.")
gu("Dao Sundering Gu", "none", 7, "legendary", 400, [D(800, pierce=True)], icon="lightning-tear", flavor="It cuts the dao itself.")
gu("Heaven Defying Shield Gu", "none", 7, "legendary", 380, [S(900), BUFF("prot", 2, 3)], kind="defense", icon="lightning-dome",
   target="self", flavor="Even tribulation lightning bends around it.")
gu("Venerable Will Gu", "none", 8, "legendary", 700, [D(1600, pierce=True), BUFF("strong", 2, 3)], icon="hand-of-god",
   flavor="The will of a Venerable, briefly borrowed.")


# ===================== KILLER MOVES ==========================================
KILLER_MOVES = [
    {"id": "moonlight_devastation", "name": "Moonlight Devastation", "path": "light", "need_tier": "Master",
     "components": {"tag": "moon", "count": 3}, "cost": 45, "clan": "gu_yue",
     "effects": [D(60, raw=True, rankscale=True, times=1), E("dmg_shield", mult=1.0, consume=True)],
     "desc": "Massive light damage that also releases your shields. Stronger at night.", "night_bonus": 0.4},
    {"id": "bone_storm", "name": "Bone Storm", "path": "strength", "need_tier": "Master",
     "components": {"tag": "bone", "count": 2}, "cost": 40, "clan": "bai",
     "effects": [dict(v="damage", n=34, rankscale=True, t="all"), ST("vuln", 2, 2, "all"), ST("bleed", 4, 3, "all")],
     "desc": "A storm of bone shards hits every enemy and shreds their armour."},
    {"id": "mountain_crushing_fist", "name": "Mountain Crushing Fist", "path": "strength", "need_tier": "Master",
     "components": {"path": "strength", "count": 2}, "cost": 40, "clan": "xiong",
     "effects": [E("dmg_combo", base=70, per=12, rankscale=True), ST("stun", 1, 1)],
     "desc": "One massive blow that grows with your combo, and stuns."},
    {"id": "absolute_dominion", "name": "Absolute Dominion", "path": "enslavement", "need_tier": "Master",
     "components": {"tag": "control", "count": 3}, "cost": 45, "clan": "shang",
     "effects": [ST("control", 1, 2), ST("stun", 1, 2), E("steal_essence", n=30)],
     "desc": "Fully control the enemy for 2 turns."},
    {"id": "plague_apocalypse", "name": "Plague Apocalypse", "path": "poison", "need_tier": "Master",
     "components": {"path": "poison", "count": 3}, "cost": 40,
     "effects": [E("multiply_status", s="poison", x=3, t="all"), E("detonate", s="poison", mult=1.0, t="all", keep=True)],
     "desc": "Triple every enemy's poison, then make it burst for its full value."},
    {"id": "exsanguinate", "name": "Exsanguinate", "path": "blood", "need_tier": "Master",
     "components": {"path": "blood", "count": 3}, "cost": 35,
     "effects": [E("self_damage", n=20, rankscale=True), E("dmg_missing_hp", pct=0.6, base=40, rankscale=True, lifesteal=0.5)],
     "desc": "Pour your own life into a strike that drinks it all back."},
    {"id": "avatar_of_war", "name": "Avatar of War", "path": "strength", "need_tier": "Master",
     "components": {"path": "strength", "count": 3}, "cost": 45,
     "effects": [E("dmg_combo", base=40, per=15, rankscale=True), BUFF("strong", 2, 3), E("combo", n=3)],
     "desc": "Become war itself: a combo-fuelled blow and three turns of strength."},
    {"id": "dawnbreaker", "name": "Dawnbreaker", "path": "light", "need_tier": "Master",
     "components": {"path": "light", "count": 3}, "cost": 40,
     "effects": [E("dmg_shield", mult=2.0, consume=True), E("shield_pct_hp", pct=0.15)],
     "desc": "Release all shields as damage twice over, then raise a fresh one."},
    {"id": "reaping_shadow", "name": "Reaping Shadow", "path": "dark", "need_tier": "Master",
     "components": {"path": "dark", "count": 3}, "cost": 40,
     "effects": [BUFF("stealth", 1, 1), E("execute", pct=0.35, n=60, rankscale=True)],
     "desc": "Vanish, then reap: executes enemies below 35% health."},
    {"id": "myriad_thoughts_cascade", "name": "Myriad Thoughts Cascade", "path": "wisdom", "need_tier": "Master",
     "components": {"path": "wisdom", "count": 3}, "cost": 35,
     "effects": [E("draw", n=3), E("cheapen", n=3), E("reveal", n=3)],
     "desc": "Draw 3, your next 3 Gu cost half, and every intent is revealed."},
    {"id": "furnace_of_ten_thousand", "name": "Furnace of Ten Thousand Refinements", "path": "refinement", "need_tier": "Master",
     "components": {"path": "refinement", "count": 3}, "cost": 40,
     "effects": [E("create", card="forged_blade", n=3), E("upgrade_hand", pct=0.4)],
     "desc": "Forge three blades and empower your whole hand."},
    {"id": "thousand_transformations", "name": "Thousand Transformations", "path": "transformation", "need_tier": "Master",
     "components": {"path": "transformation", "count": 3}, "cost": 40,
     "effects": [E("form", form="beast", turns=3), E("form", form="wind", turns=3), E("form", form="blood", turns=3), D(40, raw=True, rankscale=True)],
     "desc": "Take beast, wind and blood forms at once, and strike."},
    {"id": "feast_of_heaven", "name": "Feast of Heaven", "path": "food", "need_tier": "Master",
     "components": {"path": "food", "count": 3}, "cost": 20,
     "effects": [E("essence", n=50, rankscale=True), H(40, raw=True, rankscale=True), E("dmg_essence", pct=0.4, base=20, rankscale=True)],
     "desc": "Gorge on essence, heal, and hit for a share of everything you hold."},
    {"id": "inferno_furnace", "name": "Inferno Furnace", "path": "fire", "need_tier": "Master",
     "components": {"path": "fire", "count": 3}, "cost": 40,
     "effects": [ST("burn", 8, 4, "all"), E("detonate", s="burn", mult=3.0, t="all", keep=True)],
     "desc": "Set every enemy ablaze and stoke it into an inferno."},
]

# ===================== MATERIALS ============================================
MATERIALS = [
    # id, name, tier, path, icon, value
    ("primeval_grass", "Primeval Grass", "common", None, "high-grass", 4),
    ("beast_bone", "Beast Bone", "common", None, "broken-bone", 5),
    ("spirit_water", "Spirit Water", "common", None, "water-flask", 5),
    ("iron_sand", "Iron Sand", "uncommon", None, "stone-pile", 18),
    ("moon_orchid", "Moon Orchid", "uncommon", "light", "lotus", 22),
    ("beast_core", "Beast Core", "uncommon", None, "gems", 20),
    ("star_fragment", "Star Fragment", "rare", None, "falling-star", 80),
    ("ancient_amber", "Ancient Amber", "rare", None, "crystal-cluster", 90),
    ("thunder_crystal", "Thunder Crystal", "rare", None, "crystal-bars", 95),
    ("heavens_tear", "Heaven's Tear", "legendary", None, "water-drop", 400),
    ("dao_shard", "Dao Shard", "legendary", None, "floating-crystal", 450),
    ("bear_sinew", "Bear Sinew", "uncommon", "strength", "muscle-up", 20),
    ("thought_pearl", "Thought Pearl", "uncommon", "wisdom", "crystal-eye", 24),
    ("crimson_essence", "Crimson Essence", "uncommon", "blood", "heart-drop", 22),
    ("refining_ember", "Refining Ember", "uncommon", "refinement", "fire-gem", 22),
    ("shifting_scale", "Shifting Scale", "uncommon", "transformation", "fish-scales", 22),
    ("binding_thread", "Binding Thread", "uncommon", "enslavement", "sewing-string", 22),
    ("venom_sac", "Venom Sac", "uncommon", "poison", "chemical-drop", 20),
    ("shade_silk", "Shade Silk", "uncommon", "dark", "spider-web", 24),
    ("dawn_dew", "Dawn Dew", "uncommon", "light", "drop", 22),
    ("sweet_nectar", "Sweet Nectar", "uncommon", "food", "honeypot", 18),
    ("phoenix_ash", "Phoenix Ash", "uncommon", "fire", "fire-bowl", 24),
    ("soul_jade", "Soul Jade", "rare", "dark", "crystal-shrine", 110),
    ("immortal_stone", "Immortal Essence Stone", "legendary", None, "crystal-growth", 1000),
]

# refinement costs (docs/Systems/Economy.md)
REFINE_COST = {
    1: {"stones": 20, "mats": {"common": 3}, "days": 3},
    2: {"stones": 60, "mats": {"common": 3, "uncommon": 1}, "days": 5},
    3: {"stones": 200, "mats": {"uncommon": 3, "rare": 1}, "days": 10},
    4: {"stones": 500, "mats": {"uncommon": 2, "rare": 2, "path": 1}, "days": 20},
    5: {"stones": 1000, "mats": {"rare": 5, "legendary": 1}, "days": 40},
}
