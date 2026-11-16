"""Build game/data/*.json from the content tables and validate them.

Usage: python3 tools/content/build_content.py
Validation follows docs/Content/Gu.md 'Validation Rules' (name ends in Gu, rank-appropriate cost, etc.).
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import content_core as C  # noqa: E402
import content_world as W  # noqa: E402
import content_events as EV  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
OUT = os.path.join(ROOT, "game", "data")

VERBS = {"damage", "heal", "shield", "status", "self_damage", "essence", "draw", "combo", "dmg_combo", "cheapen", "reveal",
         "dmg_missing_hp", "create", "upgrade_hand", "form", "mimic", "summon", "steal_essence", "multiply_status", "detonate",
         "execute", "dmg_shield", "shield_pct_hp", "dmg_essence", "cleanse"}
EVENT_EFFECTS = {"log", "stones", "immortal_stones", "mat", "mat_tier", "gu", "gu_pool", "time", "rep", "fame", "damage", "heal",
                 "cult", "attain", "info", "formula", "killer", "flag", "unflag", "injury", "cure", "lifespan", "story", "story_done",
                 "queue", "reveal", "meet_npc", "disp", "disp_npc", "disp_arch", "disp_rival", "relation", "standing", "open_market",
                 "starve", "bt_bonus", "achieve", "kill_npc", "kill_rival", "rival_lose", "rival_friend", "dao", "beast_companion", "status"}
COST_RANGE = {1: (4, 15), 2: (8, 25), 3: (18, 40), 4: (35, 60), 5: (40, 80)}


def load_icon_names():
    p = os.path.join(ROOT, "..", "assets_dl", "iconify-json-game-icons-1.2.4", "package", "icons.json")
    p = os.environ.get("GAME_ICONS_JSON", p)
    if not os.path.exists(p):
        return None
    d = json.load(open(p))
    names = set(d["icons"].keys()) | set(d.get("aliases", {}).keys())
    return names


def main():
    os.makedirs(OUT, exist_ok=True)
    errors = []
    icons_used = set()
    ids = set()
    for g in C.GU:
        if g["id"] in ids:
            errors.append("duplicate gu id " + g["id"])
        ids.add(g["id"])
        if not g["name"].endswith(" Gu"):
            errors.append("gu name must end with Gu: " + g["name"])
        for e in g["effects"]:
            if e["v"] not in VERBS:
                errors.append("bad verb %s in %s" % (e["v"], g["id"]))
        r = g["rank"]
        if g["kind"] not in ("passive", "consumable") and "temporary" not in g["flags"] and r in COST_RANGE:
            lo, hi = COST_RANGE[r]
            if not (lo <= g["cost"] <= hi):
                errors.append("cost %d out of rank %d range for %s" % (g["cost"], r, g["id"]))
        icons_used.add(g["icon"])
    gu_ids = ids
    for clan in W.CLANS:
        for gid in clan["start_gu"] + clan["unique"]:
            if gid not in gu_ids:
                errors.append("clan %s references unknown gu %s" % (clan["id"], gid))
        icons_used.add(clan["icon"])
    for km in C.KILLER_MOVES:
        for e in km["effects"]:
            if e["v"] not in VERBS:
                errors.append("bad verb in killer " + km["id"])
    # formulas: every pooled, non-consumable Gu up to rank 5 can be refined; consumables too (except keys)
    formulas = []
    for g in C.GU:
        if "temporary" in g["flags"] or "key" in g["flags"] or g["rank"] > 5:
            continue
        cost = C.REFINE_COST[g["rank"]]
        formulas.append({"id": g["id"], "rank": g["rank"], "path": g["path"], "stones": cost["stones"],
                         "mats": cost["mats"], "days": cost["days"], "clan": g.get("clan")})
    loc_ids = {l["id"] for l in W.LOCATIONS}
    for a, b, d in W.ROUTES:
        if a not in loc_ids or b not in loc_ids:
            errors.append("route to unknown location %s-%s" % (a, b))
    for l in W.LOCATIONS:
        icons_used.add(l["icon"])
        for env in l["env"]:
            if env not in W.ENVIRONMENTS:
                errors.append("unknown env " + env)
    enemy_ids = {e["id"] for e in W.ENEMIES}
    groups = {e["group"] for e in W.ENEMIES}
    for e in W.ENEMIES:
        icons_used.add(e["icon"])
        for a in e["abilities"]:
            for x in a["effects"]:
                if x["v"] not in VERBS:
                    errors.append("bad enemy verb " + e["id"])
    for l in W.LOCATIONS:
        for g in l["enemies"]:
            if g not in groups:
                errors.append("location %s uses unknown enemy group %s" % (l["id"], g))
    ev_ids = set()
    for e in EV.EVENTS:
        if e["id"] in ev_ids:
            errors.append("duplicate event " + e["id"])
        ev_ids.add(e["id"])
    for e in EV.EVENTS:
        for c in e["choices"]:
            chk = c.get("check")
            if chk and chk["type"] == "combat":
                if chk.get("enemy") and chk["enemy"] not in enemy_ids:
                    errors.append("event %s uses unknown enemy %s" % (e["id"], chk["enemy"]))
                if chk.get("group") and chk["group"] not in groups:
                    errors.append("event %s uses unknown group %s" % (e["id"], chk["group"]))
            for eff in c.get("ok", []) + c.get("fail", []):
                if eff["do"] not in EVENT_EFFECTS:
                    errors.append("event %s bad effect %s" % (e["id"], eff["do"]))
                if eff["do"] == "gu" and eff["id"] not in gu_ids:
                    errors.append("event %s gives unknown gu %s" % (e["id"], eff["id"]))
                if eff["do"] == "queue" and eff["id"] not in ev_ids:
                    errors.append("event %s queues unknown %s" % (e["id"], eff["id"]))
                if eff["do"] in ("reveal",) and eff["loc"] not in loc_ids:
                    errors.append("event %s reveals unknown %s" % (e["id"], eff["loc"]))
                if eff["do"] == "mat" and eff["id"] not in {m[0] for m in C.MATERIALS}:
                    errors.append("event %s unknown material %s" % (e["id"], eff["id"]))
    for s in EV.STORYLINES:
        if s["start"] not in ev_ids:
            errors.append("storyline start missing " + s["start"])
    for ep in W.EPOCHS:
        if ep["event"] not in ev_ids:
            errors.append("epoch event missing " + ep["event"])
    for p in C.PATHS:
        icons_used.add(p[5])
    for st in C.STATUSES.values():
        icons_used.add(st["icon"])
    for m in C.MATERIALS:
        icons_used.add(m[4])
    for n in W.NPCS:
        icons_used.add(n["icon"])
    for e in W.ENEMIES:
        for a in e["abilities"]:
            pass
    for g in C.GU:
        for e in g["effects"]:
            if e["v"] == "summon":
                icons_used.add(e["icon"])
            if e["v"] == "create" and e["card"] not in gu_ids:
                errors.append("create unknown card " + e["card"])

    names = load_icon_names()
    if names is not None:
        missing = sorted(i for i in icons_used if i not in names)
        if missing:
            errors.append("missing icons: " + ", ".join(missing))

    if errors:
        print("CONTENT ERRORS:")
        for e in errors:
            print("  -", e)
        sys.exit(1)

    def dump(name, obj):
        with open(os.path.join(OUT, name + ".json"), "w", encoding="utf-8") as f:
            json.dump(obj, f, ensure_ascii=False, indent=1)

    dump("paths", [{"id": p[0], "name": p[1], "symbol": p[2], "color": p[3], "desc": p[4], "icon": p[5]} for p in C.PATHS])
    dump("statuses", C.STATUSES)
    dump("forms", C.FORMS)
    dump("gu", C.GU)
    dump("killer_moves", C.KILLER_MOVES)
    dump("materials", [{"id": m[0], "name": m[1], "tier": m[2], "path": m[3], "icon": m[4], "value": m[5]} for m in C.MATERIALS])
    dump("formulas", formulas)
    dump("clans", W.CLANS)
    dump("locations", W.LOCATIONS)
    dump("routes", [{"a": a, "b": b, "days": d} for a, b, d in W.ROUTES])
    dump("environments", W.ENVIRONMENTS)
    dump("enemies", {"list": W.ENEMIES, "tiers": W.TIER_MULT})
    dump("npcs", {"seeds": W.NPCS, "names": W.NAME_SYL, "archetypes": W.ARCHETYPES,
                  "bands": W.DISPOSITION_BANDS, "levels": W.RELATION_LEVELS})
    dump("meta", {"inheritance": W.INHERITANCE, "starts": W.STARTS, "modes": W.MODES, "achievements": W.ACHIEVEMENTS})
    dump("world", {"goals": W.GOAL_TYPES, "epochs": W.EPOCHS, "missions": W.MISSIONS,
                   "standing": W.STANDING, "stipend": W.STIPEND, "feed": C.FEED_COST})
    dump("events", {"events": EV.EVENTS, "storylines": EV.STORYLINES, "templates": EV.TEMPLATES, "words": EV.WORDS})
    with open(os.path.join(ROOT, "tools", "content", "icons_used.txt"), "w") as f:
        f.write("\n".join(sorted(icons_used)))
    print("OK: %d Gu, %d killer moves, %d enemies, %d events, %d locations, %d formulas, %d icons"
          % (len(C.GU), len(C.KILLER_MOVES), len(W.ENEMIES), len(EV.EVENTS), len(W.LOCATIONS), len(formulas), len(icons_used)))


if __name__ == "__main__":
    main()
