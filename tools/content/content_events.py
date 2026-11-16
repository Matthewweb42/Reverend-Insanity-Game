"""Authored events, storylines and epoch events (docs/Systems/Events.md).

Event shape:
  id, type (opportunity|encounter|discovery|challenge|dilemma|chain), title, text,
  where: list of location ids/types, "travel", or "any"; rank: [min,max];
  goals: goal tags that boost weight; weight; urgency (immediate|urgent|normal|background);
  expiry (days in queue); once; req (requirements to appear); choices: [...]
Choice: text, req, hint, check {type: chance|combat, p, stat, enemy...}, ok: [effects], fail: [effects]
Effects: {"do": <type>, ...}. See game/core/events.gd for the interpreter.
Placeholders: {name} {clan} {loc} {path} {npc} {rival} {year}
"""

EVENTS = []
STORYLINES = []


def ev(id, title, text, choices, where=("any",), type="encounter", rank=(1, 9), goals=(), weight=10,
       urgency="normal", expiry=20, once=False, req=None, npc=None, chain=None):
    e = {"id": id, "title": title, "text": text, "choices": choices, "where": list(where), "type": type,
         "rank": list(rank), "goals": list(goals), "weight": weight, "urgency": urgency, "expiry": expiry,
         "once": once}
    if req:
        e["req"] = req
    if npc:
        e["npc"] = npc
    if chain:
        e["chain"] = chain
    EVENTS.append(e)
    return e


def ch(text, ok=None, fail=None, check=None, req=None, hint=None):
    c = {"text": text, "ok": ok or []}
    if fail is not None:
        c["fail"] = fail
    if check:
        c["check"] = check
    if req:
        c["req"] = req
    if hint:
        c["hint"] = hint
    return c


def chance(p, stat=None):
    d = {"type": "chance", "p": p}
    if stat:
        d["stat"] = stat
    return d


def fight(enemy=None, group=None, count=1, rank="r", tier=None):
    d = {"type": "combat", "count": count, "rank": rank}
    if enemy:
        d["enemy"] = enemy
    if group:
        d["group"] = group
    if tier:
        d["tier"] = tier
    return d


def X(do, **k):
    d = {"do": do}
    d.update(k)
    return d


LEAVE = ch("Leave it be.", [X("log", text="You move on.")])

# ============================ TRAVEL / WILD ==================================
ev("wolf_pack", "Wolves on the Road", "Grey shapes slip between the trees. A small wolf pack has picked up your scent and is fanning out to surround you.",
   [ch("Stand and fight.", [X("log", text="The pack scatters.")], check=fight(group="wild", enemy="grey_wolf", count=2)),
    ch("Climb a tree and wait them out (lose 2 days).", [X("time", days=2), X("log", text="They lose interest by morning.")]),
    ch("Throw them some dried meat (10 stones' worth).", [X("stones", n=-10), X("log", text="They snap it up and trot off.")], req={"stones": 10})],
   where=["travel", "qing_mao_woods", "wild_beast_plains"], rank=(1, 2), goals=["combat"], weight=14)

ev("boar_ambush", "Black Boar", "A black boar the size of a cart crashes out of the undergrowth, tusks lowered.",
   [ch("Meet the charge.", [X("mat", id="bear_sinew", n=1)], check=fight(enemy="black_boar")),
    ch("Dive aside and run.", [X("damage", pct=0.08)], hint="You'll take a glancing blow.")],
   where=["travel", "qing_mao_woods", "xiong_village"], rank=(1, 2), goals=["combat"], weight=10)

ev("herb_patch", "Patch of Primeval Grass", "Faint green light pulses from a hollow under a rock: primeval grass, thick and healthy.",
   [ch("Harvest it carefully (1 day).", [X("mat", id="primeval_grass", n=3), X("time", days=1)]),
    ch("Grab what you can quickly.", [X("mat", id="primeval_grass", n=1)])],
   where=["travel", "wild"], rank=(1, 4), goals=["stones"], type="discovery", weight=12)

ev("wild_gu_nest", "Wild Gu Nest", "A hum fills the air. In a split trunk, a cluster of wild Gu are feeding on sap. Capturing one takes skill.",
   [ch("Try to capture one.", [X("gu_pool", rank="r", log="You coax a wild Gu into your aperture.")], fail=[X("damage", pct=0.1), X("log", text="The swarm turns on you.")],
       check=chance(0.55, "wisdom"), hint="Wisdom helps."),
    ch("Fight the swarm for their essence.", [X("stones", n=25)], check=fight(group="wild", count=2, tier="mook")),
    LEAVE],
   where=["wild", "travel"], rank=(1, 5), goals=["gu_path", "gu_kind"], type="discovery", weight=10)

ev("lost_merchant", "A Lost Merchant", "A merchant with a broken cart waves you down. Bandits took his guards and he is far from the road.",
   [ch("Escort him to safety (3 days).", [X("time", days=3), X("stones", n=40), X("rep", n=5), X("fame", n=3)],
       fail=[X("time", days=3)], check=fight(group="bandit", enemy="bandit", count=2)),
    ch("Rob him yourself.", [X("stones", n=70), X("rep", n=-15)], hint="Demonic act."),
    ch("Point him the right way and go.", [X("rep", n=1)])],
   where=["travel"], rank=(1, 3), type="dilemma", weight=8)

ev("bandit_toll", "Bandit Toll", "Three men step onto the road with blades drawn. 'Toll's twenty stones, Gu Master.'",
   [ch("Pay the toll.", [X("stones", n=-20)], req={"stones": 20}),
    ch("Teach them manners.", [X("stones", n=30), X("fame", n=2)], check=fight(group="bandit", enemy="bandit", count=3)),
    ch("Bluff that your clan elder follows close behind.", [X("log", text="They exchange looks and let you pass.")],
       fail=[X("stones", n=-30), X("damage", pct=0.1)], check=chance(0.5, "enslavement"), hint="Enslavement or Wisdom helps.")],
   where=["travel"], rank=(1, 3), goals=["combat"], weight=10)

ev("rogue_duel", "Challenge on the Road", "A lone Gu Master blocks the path. 'Your Gu look well fed. I'll take one.'",
   [ch("Duel.", [X("gu_pool", rank="r", chance=0.4), X("stones", n=35)], check=fight(enemy="rogue_cultivator")),
    ch("Hand over 30 stones instead.", [X("stones", n=-30)], req={"stones": 30})],
   where=["travel"], rank=(2, 4), goals=["combat"], weight=8)

ev("spider_lair", "Moon Shadow Spiders", "Silver webs glitter between the orchids. Something large shifts above you.",
   [ch("Burn the webs and fight.", [X("mat", id="shade_silk", n=2), X("mat", id="venom_sac", n=1)], check=fight(enemy="moon_spider", count=2)),
    ch("Back away slowly.", [])],
   where=["moon_orchid_valley", "travel"], rank=(2, 3), goals=["combat"], weight=9)

ev("thunder_wolf_alpha", "Thunder Crown Wolf", "Lightning crackles along the spine of a huge wolf. It has noticed you.",
   [ch("Fight it.", [X("mat", id="thunder_crystal", n=1), X("fame", n=4)], check=fight(enemy="thunder_wolf")),
    ch("Flee into a gully.", [X("damage", pct=0.12)])],
   where=["wild_beast_plains", "travel"], rank=(2, 4), goals=["combat"], weight=7)

ev("snake_pit", "Jade-Eye Snakes", "Grass rustles in a widening circle. Jade eyes rise to meet you.",
   [ch("Fight.", [X("mat", id="venom_sac", n=2), X("mat", id="ancient_amber", n=1)], check=fight(enemy="jade_eye_snake", count=2)),
    ch("Step back into the open.", [X("time", days=1)])],
   where=["wild_beast_plains", "wu_hollow", "travel"], rank=(3, 4), weight=8)

ev("rock_bear", "Rock-Hide Bear", "A bear with stone plates for skin stands up, and up, and up.",
   [ch("Fight it.", [X("mat", id="bear_sinew", n=2), X("mat", id="star_fragment", n=1)], check=fight(enemy="rock_bear")),
    ch("Leave it a gift of honey (one Sweet Nectar).", [X("mat", id="sweet_nectar", n=-1), X("rep", n=2)], req={"mat": "sweet_nectar"})],
   where=["wild_beast_plains", "xiong_village", "northern_plains"], rank=(3, 5), weight=7)

ev("demonic_hunter", "Demonic Gu Master", "A cultivator with blood-red nails smiles at you. 'Your aperture smells delicious.'",
   [ch("Fight for your life.", [X("stones", n=80), X("rep", n=5), X("gu_pool", rank="r", chance=0.5)], check=fight(enemy="demonic_cultivator")),
    ch("Offer a deal: you'll look the other way.", [X("rep", n=-8), X("info", n=1)], hint="Demonic act.")],
   where=["travel", "wild_beast_plains", "moon_orchid_valley", "merchant_city"], rank=(3, 5), goals=["combat"], weight=6)

ev("assassin", "A Needle in the Dark", "A whistle. A needle buries itself in the post beside your head. Someone wants you dead.",
   [ch("Hunt the assassin down.", [X("stones", n=60), X("info", n=1)], check=fight(enemy="poison_assassin")),
    ch("Vanish into the crowd.", [X("time", days=1)], fail=[X("damage", pct=0.15), X("status", s="poisoned")], check=chance(0.6, "dark"))],
   where=["merchant_city", "wu_hollow", "travel"], rank=(3, 5), weight=6)

ev("weather_storm", "Sudden Storm", "Black clouds roll in and rain comes down sideways.",
   [ch("Shelter in a cave (2 days).", [X("time", days=2), X("cult", n=3, log="You meditate while the storm rages.")]),
    ch("Push on through.", [X("damage", pct=0.06)])],
   where=["travel"], rank=(1, 9), weight=6, type="challenge")

ev("abandoned_camp", "Abandoned Camp", "Cold ashes, a torn tent and a pack left behind in a hurry.",
   [ch("Search the pack.", [X("stones", n=15), X("mat_tier", tier="common", n=2)]),
    ch("Search the area for whoever fled.", [X("info", n=1), X("rep", n=2)], check=chance(0.6, "wisdom"), fail=[X("log", text="The trail is cold.")])],
   where=["travel", "wild"], rank=(1, 5), type="discovery", weight=8)

ev("stone_vein", "Primeval Stone Vein", "A crack in the rock glitters with the green of raw primeval stone.",
   [ch("Dig it out (3 days).", [X("time", days=3), X("stones", n=60)]),
    ch("Take what's loose.", [X("stones", n=15)])],
   where=["wild", "travel"], rank=(1, 5), goals=["stones"], type="discovery", weight=6)

ev("ruins", "Scattered Ruins", "Broken pillars poke out of the grass, carved with Gu formulas worn almost smooth.",
   [ch("Study the carvings (4 days).", [X("time", days=4), X("formula", rank="r"), X("attain", path="primary", n=15)],
       fail=[X("time", days=4), X("attain", path="primary", n=8)], check=chance(0.5, "wisdom")),
    ch("Dig for treasure.", [X("mat_tier", tier="rare", n=1)], fail=[X("damage", pct=0.1), X("log", text="A trap!")], check=chance(0.5)),
    LEAVE],
   where=["wild_beast_plains", "moon_orchid_valley", "dang_hun_mountain"], rank=(2, 6), goals=["inheritance", "info"], type="discovery", weight=7)

ev("injured_hunter", "Injured Hunter", "A hunter lies in the grass with a torn leg, waving weakly.",
   [ch("Bind the wound and carry him to camp (1 day).", [X("time", days=1), X("rep", n=6), X("meet_npc", arch="beast_tamer", disp=20)]),
    ch("Give him a healing herb (one Primeval Grass).", [X("mat", id="primeval_grass", n=-1), X("rep", n=4), X("meet_npc", arch="beast_tamer", disp=10)], req={"mat": "primeval_grass"}),
    ch("Take his pack.", [X("stones", n=25), X("rep", n=-12)], hint="Demonic act.")],
   where=["wild_beast_plains", "travel"], rank=(1, 4), goals=["npc"], type="dilemma", weight=6)

ev("wanderer_tale", "Wanderer by the Fire", "A wanderer shares your campfire and, for the price of a meal, a story about a door in the mist.",
   [ch("Pay for the story (10 stones).", [X("stones", n=-10), X("reveal", loc="hu_immortal_land", chance=0.4), X("info", n=1)], req={"stones": 10}),
    ch("Trade stories instead.", [X("info", n=1)], check=chance(0.5, "wisdom"), fail=[X("log", text="He falls asleep halfway through yours.")])],
   where=["travel"], rank=(1, 9), goals=["info", "explore", "inheritance"], weight=6)

ev("caravan", "Passing Caravan", "A caravan of the Merchant Guild rolls past and stops to trade.",
   [ch("Browse the caravan's wares.", [X("open_market", kind="caravan")]),
    LEAVE],
   where=["travel", "village"], rank=(1, 9), goals=["gu_path", "gu_kind"], weight=8, type="opportunity")

ev("soul_wail", "Wailing in the Fog", "A pale figure drifts through the miasma, singing a song with no words.",
   [ch("Banish it.", [X("mat", id="soul_jade", n=1), X("attain", path="dark", n=10)], check=fight(enemy="wandering_soul")),
    ch("Listen to the song.", [X("cult", n=20), X("attain", path="wisdom", n=10)], fail=[X("damage", pct=0.2), X("log", text="The song tears at your soul.")], check=chance(0.4, "wisdom"))],
   where=["dang_hun_mountain"], rank=(4, 7), weight=10)

ev("tomb", "Ancient Tomb", "A doorway into the mountain, sealed with a formation that flickers when you approach.",
   [ch("Break the formation and enter.", [X("gu_pool", rank="r", rarity="rare"), X("stones", n=150)], check=fight(enemy="corpse_puppet", count=2)),
    ch("Decipher the formation (3 days).", [X("time", days=3), X("formula", rank="r"), X("info", n=2)], check=chance(0.45, "wisdom"), fail=[X("time", days=3)])],
   where=["dang_hun_mountain", "wild_beast_plains"], rank=(4, 7), goals=["inheritance", "gu_path"], type="discovery", weight=7)

# ============================ SETTLEMENTS ====================================
ev("market_day", "Market Day", "Stalls fill the square. Prices are good today.",
   [ch("Visit the market.", [X("open_market", kind="local", discount=0.1)]), LEAVE],
   where=["village", "city"], rank=(1, 9), goals=["gu_path", "gu_kind"], weight=6, type="opportunity", urgency="background")

ev("sparring", "Sparring Match", "A clan cousin challenges you to a friendly spar in the training grounds.",
   [ch("Accept.", [X("attain", path="primary", n=12), X("standing", n=4)], fail=[X("attain", path="primary", n=6)], check=fight(enemy="rival_disciple")),
    ch("Decline politely.", [X("standing", n=-1)])],
   where=["village"], rank=(1, 3), goals=["train", "combat"], weight=8)

ev("elder_lecture", "An Elder's Lecture", "An elder is lecturing young Gu Masters on the fundamentals of the aperture.",
   [ch("Attend (2 days).", [X("time", days=2), X("cult", n=10), X("attain", path="primary", n=8)]),
    ch("Ask a pointed question.", [X("disp_arch", arch="elder", n=8), X("attain", path="wisdom", n=10)], check=chance(0.5, "wisdom"), fail=[X("disp_arch", arch="elder", n=-5)])],
   where=["village"], rank=(1, 4), goals=["train"], weight=7)

ev("thief", "Pickpocket", "A boy bumps into you in the crowd. Your purse feels lighter.",
   [ch("Chase him.", [X("log", text="You catch him and take back your stones, with interest."), X("stones", n=10)], fail=[X("stones", n=-25)], check=chance(0.55, "strength")),
    ch("Let him go, he looked hungry.", [X("stones", n=-15), X("rep", n=3)])],
   where=["city", "village"], rank=(1, 4), weight=6)

ev("auction_small", "Back-Room Auction", "A broker whispers that a rare Gu is going under the hammer tonight.",
   [ch("Bid (cost scales with rank).", [X("stones", n="-80r"), X("gu_pool", rank="r", rarity="rare")], req={"stones": "80r"}),
    ch("Just watch and listen.", [X("info", n=1)])],
   where=["merchant_city"], rank=(2, 6), goals=["gu_path", "gu_kind"], weight=6, type="opportunity")

ev("gambling", "Stone Gambling", "A stall sells uncut stones. Some hold primeval essence; most hold nothing.",
   [ch("Buy one stone (20).", [X("stones", n=55)], fail=[X("log", text="Nothing but rock.")], check=chance(0.35, "wisdom"), req={"stones": 20}, hint="Wisdom helps you pick."),
    LEAVE],
   where=["merchant_city", "bai_territory"], rank=(1, 9), goals=["stones"], weight=6, type="opportunity")

ev("broker_offer", "Information for Sale", "An information broker taps the side of his nose. 'I know where a Gu nest is. 30 stones.'",
   [ch("Pay.", [X("stones", n=-30), X("info", n=2), X("queue", id="wild_gu_nest", days=2)], req={"stones": 30}),
    ch("Haggle.", [X("stones", n=-15), X("info", n=2)], fail=[X("disp_arch", arch="broker", n=-5)], check=chance(0.5, "wisdom"), req={"stones": 15})],
   where=["merchant_city"], rank=(1, 6), goals=["info"], weight=6)

ev("refiner_request", "A Refiner's Request", "Madam Su needs three Iron Sand for an order and will pay well.",
   [ch("Sell her three Iron Sand.", [X("mat", id="iron_sand", n=-3), X("stones", n=80), X("disp", npc="madam_su", n=12)], req={"mat": "iron_sand", "mat_n": 3}),
    ch("Promise to bring some later.", [X("disp", npc="madam_su", n=2)])],
   where=["bai_territory"], rank=(1, 4), goals=["npc"], weight=5, npc="madam_su")

ev("arena", "Arena Bout", "The arena master offers you a bout. The crowd is already shouting.",
   [ch("Fight for the purse.", [X("stones", n="40r"), X("fame", n=5)], fail=[X("fame", n=-2)], check=fight(group="bandit", enemy="bandit_leader")),
    LEAVE],
   where=["bai_territory", "southern_border_arena"], rank=(1, 6), goals=["combat", "stones"], weight=7)

ev("clan_politics", "Clan Politics", "Two elders are quarrelling over who controls the clan's spirit spring. Each wants your support.",
   [ch("Back the senior elder.", [X("standing", n=12), X("disp_arch", arch="elder", n=5)]),
    ch("Back the younger, bolder one.", [X("standing", n=6), X("cult", n=15)]),
    ch("Stay out of it.", [])],
   where=["village"], rank=(1, 5), weight=5, type="dilemma")

ev("gu_feeding_crisis", "Spoiled Gu Food", "Rats got into your Gu's food stores overnight.",
   [ch("Buy new food (cost scales with your Gu).", [X("stones", n="-15r")], req={"stones": "15r"}),
    ch("Let your Gu go hungry for a while.", [X("starve", weeks=1)])],
   where=["village", "city"], rank=(1, 6), weight=4, type="challenge")

ev("healer", "Travelling Healer", "A healer offers to mend injuries for a fee.",
   [ch("Pay 30 stones to heal all injuries.", [X("stones", n=-30), X("cure")], req={"stones": 30, "injured": True}),
    ch("Decline.", [])],
   where=["village", "city"], rank=(1, 9), weight=5, type="opportunity", req={"injured": True})

ev("friend_visit", "{npc} Drops By", "{npc} catches you at the inn with a jug of wine and a story.",
   [ch("Share the wine and talk.", [X("disp_npc", n=8), X("info", n=1)]),
    ch("Spar together.", [X("disp_npc", n=5), X("attain", path="primary", n=10)])],
   where=["village", "city"], rank=(1, 9), goals=["npc"], weight=6, npc="known")

ev("rival_taunt", "{rival} Again", "{rival} blocks your way through the square. 'Still crawling along at your stage? Pathetic.'",
   [ch("Challenge {rival} to a duel.", [X("fame", n=6), X("disp_rival", n=-5), X("rival_lose")], fail=[X("fame", n=-4)], check=fight(enemy="rival_disciple", rank="r")),
    ch("Ignore the taunt.", [X("cult", n=5, log="You channel your anger into cultivation.")])],
   where=["village", "city"], rank=(1, 5), goals=["combat"], weight=6, req={"has_rival": True})

ev("lost_child", "Lost Child", "A crying child says her brother went into the woods to catch a Gu and never came back.",
   [ch("Search the woods (2 days).", [X("time", days=2), X("rep", n=8), X("standing", n=6)], fail=[X("time", days=2), X("rep", n=3)], check=fight(enemy="grey_wolf", count=2)),
    ch("Tell the clan guards.", [X("rep", n=1)])],
   where=["gu_yue_village", "xiong_village", "bai_territory"], rank=(1, 3), type="dilemma", weight=5)

ev("black_market_offer", "Black Market Whisper", "A hooded figure offers you a Gu taken from a dead man. Cheap. No questions.",
   [ch("Buy it (cost scales with rank).", [X("stones", n="-40r"), X("gu_pool", rank="r"), X("rep", n=-6)], req={"stones": "40r"}, hint="Demonic act."),
    ch("Report the figure to the guards.", [X("rep", n=5), X("standing", n=3)])],
   where=["merchant_city", "wu_hollow"], rank=(1, 6), type="dilemma", weight=5)

# ============================ CULTIVATION / META ============================
ev("insight_dream", "Dream of the Dao", "In a dream you see your Gu moving like stars across a black sky, each one connected.",
   [ch("Meditate on the dream.", [X("attain", path="primary", n=20), X("cult", n=8)])],
   where=["any"], rank=(1, 9), goals=["train"], weight=3, type="opportunity", urgency="background")

ev("aperture_turbulence", "Aperture Turbulence", "Your primeval essence churns, threatening to crack the walls of your aperture.",
   [ch("Force it down.", [X("cult", n=12)], fail=[X("injury", name="Aperture Strain", days=30)], check=chance(0.6)),
    ch("Spend stones to calm it (scales with rank).", [X("stones", n="-10r")], req={"stones": "10r"})],
   where=["any"], rank=(1, 9), weight=3, type="challenge")

ev("demonic_plunder", "Aperture Plundering", "A dying demonic cultivator lies at your feet. You know the forbidden technique to tear open his aperture and take its essence.",
   [ch("Plunder his aperture.", [X("cult", n="40r"), X("lifespan", years=2), X("rep", n=-25)], hint="Deeply demonic."),
    ch("Grant him a clean end.", [X("rep", n=6)]),
    ch("Leave him to the beasts.", [X("rep", n=-2)])],
   where=["travel", "wild"], rank=(2, 8), type="dilemma", weight=3)

ev("blood_ritual", "Blood Sacrifice Ritual", "A cult offers to teach you a ritual that buys years of life with the blood of beasts, and some say, worse.",
   [ch("Learn it and perform it.", [X("lifespan", years=6), X("rep", n=-20), X("damage", pct=0.2)], hint="Demonic."),
    ch("Refuse and report the cult.", [X("rep", n=8), X("fame", n=3)])],
   where=["wu_hollow", "merchant_city", "dang_hun_mountain"], rank=(2, 8), type="dilemma", weight=3)

ev("soul_consumption", "Soul Consumption", "The ghost of an ancient cultivator offers itself to you. Consuming it would strengthen your soul and lengthen your life.",
   [ch("Consume the soul.", [X("lifespan", years=8), X("attain", path="dark", n=40), X("rep", n=-15)], hint="Demonic."),
    ch("Help it pass on.", [X("rep", n=10), X("attain", path="wisdom", n=25)])],
   where=["dang_hun_mountain"], rank=(3, 9), type="dilemma", weight=4)

ev("longevity_rumour", "Longevity Gu Rumour", "A merchant swears a Longevity Gu is hidden in a beast's den nearby.",
   [ch("Hunt the beast.", [X("gu", id="longevity")], check=fight(group="wild", count=1, tier="elite")),
    ch("Buy the 'map' for 50 stones.", [X("stones", n=-50), X("gu", id="longevity", chance=0.5)], req={"stones": 50})],
   where=["any"], rank=(2, 9), weight=3, type="opportunity", req={"age_min": 40})

ev("relic_find", "Relic Gu Glow", "Something gleams in a stream bed: a Relic Gu, rare and precious.",
   [ch("Take it.", [X("gu", id="relic")])], where=["wild", "travel"], rank=(1, 5), weight=2, type="discovery")

ev("mentor_offer", "An Elder's Offer", "Elder Chen watches you train. 'You have potential. I could guide your next breakthrough.'",
   [ch("Accept with gratitude.", [X("disp", npc="elder_chen", n=15), X("bt_bonus", n=10)]),
    ch("Bring a gift first (40 stones).", [X("stones", n=-40), X("disp", npc="elder_chen", n=25), X("bt_bonus", n=12)], req={"stones": 40})],
   where=["gu_yue_village"], rank=(1, 4), goals=["npc", "train"], weight=4, npc="elder_chen", once=True)

# ============================ CHAIN: MOON ORCHID MYSTERY (medium) ============
ev("orchid_1", "Withering Orchids", "The moon orchids of the valley are withering overnight. Elder Chen asks you to find out why.",
   [ch("Take the task.", [X("story", id="orchid", step=1), X("queue", id="orchid_2", days=4)]), ch("Not now.", [])],
   where=["gu_yue_village"], rank=(1, 3), type="chain", weight=6, once=True, chain="orchid")
ev("orchid_2", "Tracks in the Mist", "In the valley you find grey slime trails leading to a cave behind a waterfall.",
   [ch("Follow them.", [X("story", id="orchid", step=2), X("queue", id="orchid_3", days=2)]),
    ch("Report back to the elder first.", [X("standing", n=4), X("story", id="orchid", step=2), X("queue", id="orchid_3", days=5)])],
   where=["any"], type="chain", weight=0, chain="orchid", urgency="urgent")
ev("orchid_3", "The Rot Worm Queen", "A bloated worm queen feeds on the orchids' roots, surrounded by her brood.",
   [ch("Destroy her.", [X("story", id="orchid", step=3), X("queue", id="orchid_4", days=1)], fail=[X("damage", pct=0.15)], check=fight(enemy="jade_eye_snake", count=2, rank="r")),
    ch("Capture her with a control Gu.", [X("gu", id="rot_spreading"), X("story", id="orchid", step=3), X("queue", id="orchid_4", days=1)], req={"gu_tag": "control"})],
   where=["any"], type="chain", weight=0, chain="orchid", urgency="urgent")
ev("orchid_4", "Orchids Restored", "The valley glows again. Elder Chen is pleased.",
   [ch("Accept the clan's reward.", [X("stones", n=80), X("standing", n=20), X("mat", id="moon_orchid", n=3), X("story_done", id="orchid")])],
   where=["any"], type="chain", weight=0, chain="orchid", urgency="urgent")

# ============================ CHAIN: MERCHANT'S DEBT (medium) ================
ev("debt_1", "Jia Fu's Problem", "Jia Fu is sweating. 'A Shang elder lent me money. I can't repay. Help me, and I'll make it worth your while.'",
   [ch("Agree to help.", [X("story", id="debt", step=1), X("disp", npc="jia_fu", n=10), X("queue", id="debt_2", days=3)]), ch("Not your problem.", [])],
   where=["merchant_city"], rank=(1, 4), type="chain", weight=6, once=True, npc="jia_fu", chain="debt")
ev("debt_2", "Following the Money", "The debt was bought by a loan shark who hires bandits as collectors.",
   [ch("Confront the collectors.", [X("story", id="debt", step=2), X("queue", id="debt_3", days=2)], check=fight(group="bandit", enemy="bandit", count=2)),
    ch("Dig up dirt on the loan shark.", [X("info", n=1), X("story", id="debt", step=2), X("queue", id="debt_3", days=3)], check=chance(0.5, "wisdom"), fail=[X("queue", id="debt_3", days=3)])],
   where=["any"], type="chain", weight=0, chain="debt", urgency="urgent")
ev("debt_3", "The Loan Shark", "The loan shark meets you in a tea house, guards at his back.",
   [ch("Threaten him.", [X("story", id="debt", step=3), X("queue", id="debt_4", days=1)], check=fight(enemy="bandit_leader")),
    ch("Pay part of the debt yourself (100).", [X("stones", n=-100), X("story", id="debt", step=3), X("queue", id="debt_4", days=1)], req={"stones": 100}),
    ch("Expose him to the Shang clan.", [X("standing", n=10), X("story", id="debt", step=3), X("queue", id="debt_4", days=1)], req={"info": 2})],
   where=["any"], type="chain", weight=0, chain="debt", urgency="urgent")
ev("debt_4", "A Grateful Merchant", "Jia Fu is free. 'From now on, you'll always get my best prices.'",
   [ch("Accept.", [X("disp", npc="jia_fu", n=30), X("relation", npc="jia_fu", level="Contact"), X("stones", n=60), X("story_done", id="debt")])],
   where=["any"], type="chain", weight=0, chain="debt", urgency="urgent")

# ============================ CHAIN: BEAST KING (medium) =====================
ev("bk_1", "Rumours of a Beast King", "Tie Shan says a Hundred-Beast King Tiger has claimed the Wild Beast Plains, and the herds are fleeing.",
   [ch("Promise to deal with it.", [X("story", id="beast_king", step=1), X("disp", npc="tie_shan", n=8)]), ch("Too dangerous.", [])],
   where=["xiong_village", "wild_beast_plains"], rank=(3, 5), type="chain", weight=6, once=True, chain="beast_king")
ev("bk_2", "The King's Pride", "You find the tiger's lieutenants: two Thunder Crown Wolves.",
   [ch("Fight them.", [X("story", id="beast_king", step=2), X("queue", id="bk_3", days=2)], check=fight(enemy="thunder_wolf", count=2))],
   where=["wild_beast_plains"], rank=(3, 6), type="chain", weight=12, chain="beast_king", req={"story": "beast_king", "step": 1})
ev("bk_3", "The Beast King", "The Hundred-Beast King Tiger steps out of the tall grass. The plains go silent.",
   [ch("Face the king.", [X("story_done", id="beast_king"), X("gu", id="beast_king"), X("fame", n=15), X("achieve", id="boss_slayer")], check=fight(enemy="beast_king_tiger")),
    ch("Retreat and prepare.", [X("queue", id="bk_3", days=10)])],
   where=["any"], type="chain", weight=0, chain="beast_king", urgency="urgent")

# ============================ CHAIN: EMBER TYRANT (Chi unlock) ===============
ev("ember_1", "Heat on the Wind", "Smiths from Chi Forge talk of a fire beast in the caldera that melts their ore carts.",
   [ch("Go and see.", [X("story", id="ember", step=1), X("reveal", loc="ember_caldera"), X("reveal", loc="chi_forge")])],
   where=["merchant_city", "southern_border_arena"], rank=(3, 6), type="chain", weight=5, once=True, chain="ember")
ev("ember_2", "The Ember Tyrant", "In the caldera a dragon-like salamander rises from the lava, crowned in flame.",
   [ch("Fight the Ember Tyrant.", [X("story_done", id="ember"), X("flag", id="beat_fire_boss"), X("gu", id="flame_lotus"), X("fame", n=12), X("achieve", id="boss_slayer")], check=fight(enemy="ember_tyrant")),
    ch("Not yet.", [])],
   where=["ember_caldera"], rank=(3, 9), type="chain", weight=20, chain="ember")

# ============================ LONG CHAIN: THREE KINGS (10 steps) =============
tk = [
    ("tk_1", "A Wanderer's Riddle", "Wen Rui speaks of three kings who left a blessed land behind, and a key broken in three.", "moon_orchid_valley"),
    ("tk_2", "The First Shard's Trail", "Old Mo sells you a clue: the first shard lies with a bandit chief who doesn't know its worth.", "merchant_city"),
    ("tk_3", "The Bandit Chief's Hoard", "The chief keeps the shard on a cord around his neck.", "travel"),
    ("tk_4", "The Second Shard", "The second shard is said to rest in an ancient tomb on Dang Hun Mountain.", "dang_hun_mountain"),
    ("tk_5", "Guardian of the Tomb", "A guardian construct stirs as you lift the shard.", "dang_hun_mountain"),
    ("tk_6", "The Third Shard", "The third shard is kept by Elder Ying of the Shang clan.", "merchant_city"),
    ("tk_7", "The Elder's Price", "Elder Ying will part with it, for a price.", "merchant_city"),
    ("tk_8", "Forging the Key", "Three shards, one formula. Refine the key.", "any"),
    ("tk_9", "The Way Opens", "The key hums and points toward a valley beyond Dang Hun Mountain.", "any"),
    ("tk_10", "The Three Kings' Trial", "Inside the blessed land, three guardians stand before the inheritance.", "three_kings_land"),
]
ev("tk_1", tk[0][1], tk[0][2], [ch("Ask how to find the shards.", [X("story", id="three_kings", step=1), X("reveal", loc="three_kings_land"), X("info", n=1)])],
   where=["moon_orchid_valley", "travel"], rank=(2, 6), type="chain", weight=5, once=True, chain="three_kings", goals=["inheritance"])
ev("tk_2", tk[1][1], tk[1][2], [ch("Pay Old Mo 50 stones.", [X("stones", n=-50), X("story", id="three_kings", step=2), X("queue", id="tk_3", days=3)], req={"stones": 50}),
                                   ch("Spend two pieces of information instead.", [X("info", n=-2), X("story", id="three_kings", step=2), X("queue", id="tk_3", days=3)], req={"info": 2})],
   where=["merchant_city"], rank=(2, 6), type="chain", weight=15, chain="three_kings", req={"story": "three_kings", "step": 1})
ev("tk_3", tk[2][1], tk[2][2], [ch("Take it by force.", [X("story", id="three_kings", step=3), X("flag", id="shard_1")], check=fight(enemy="bandit_leader", count=1, rank="r")),
                                   ch("Steal it at night.", [X("story", id="three_kings", step=3), X("flag", id="shard_1")], check=chance(0.5, "dark"), fail=[X("queue", id="tk_3", days=5), X("damage", pct=0.1)])],
   where=["any"], type="chain", weight=0, chain="three_kings", urgency="urgent")
ev("tk_4", tk[3][1], tk[3][2], [ch("Search the tombs.", [X("story", id="three_kings", step=4), X("queue", id="tk_5", days=1)])],
   where=["dang_hun_mountain"], rank=(3, 9), type="chain", weight=20, chain="three_kings", req={"story": "three_kings", "step": 3})
ev("tk_5", tk[4][1], tk[4][2], [ch("Destroy the guardian.", [X("story", id="three_kings", step=5), X("flag", id="shard_2")], check=fight(enemy="guardian_construct"))],
   where=["any"], type="chain", weight=0, chain="three_kings", urgency="urgent")
ev("tk_6", tk[5][1], tk[5][2], [ch("Request an audience.", [X("story", id="three_kings", step=6), X("queue", id="tk_7", days=1)])],
   where=["merchant_city"], rank=(3, 9), type="chain", weight=20, chain="three_kings", req={"story": "three_kings", "step": 5})
ev("tk_7", tk[6][1], tk[6][2], [ch("Pay 600 stones.", [X("stones", n=-600), X("story", id="three_kings", step=7), X("flag", id="shard_3"), X("queue", id="tk_8", days=1)], req={"stones": 600}),
                                   ch("Serve the Shang clan (60 days).", [X("time", days=60), X("story", id="three_kings", step=7), X("flag", id="shard_3"), X("queue", id="tk_8", days=1)]),
                                   ch("Persuade her with what you know.", [X("story", id="three_kings", step=7), X("flag", id="shard_3"), X("queue", id="tk_8", days=1)], req={"info": 4}, check=chance(0.6, "wisdom"), fail=[X("disp", npc="elder_ying", n=-10)])],
   where=["any"], type="chain", weight=0, chain="three_kings", urgency="urgent")
ev("tk_8", tk[7][1], tk[7][2], [ch("Refine the key (10 days, 200 stones).", [X("time", days=10), X("stones", n=-200), X("story", id="three_kings", step=8), X("queue", id="tk_9", days=1)], req={"stones": 200}),
                                   ch("Pay Madam Su to do it (400 stones).", [X("stones", n=-400), X("story", id="three_kings", step=8), X("queue", id="tk_9", days=1)], req={"stones": 400})],
   where=["any"], type="chain", weight=0, chain="three_kings", urgency="urgent")
ev("tk_9", tk[8][1], tk[8][2], [ch("Take the key.", [X("gu", id="three_kings_key"), X("story", id="three_kings", step=9)])],
   where=["any"], type="chain", weight=0, chain="three_kings", urgency="urgent")
ev("tk_10", tk[9][1], tk[9][2], [ch("Face the three guardians.", [X("story_done", id="three_kings"), X("achieve", id="three_kings"), X("gu", id="heavenly_light"), X("gu", id="star_thought"),
                                                                  X("mat", id="dao_shard", n=3), X("stones", n=2000), X("flag", id="blessed_seed")], check=fight(enemy="guardian_construct", count=3)),
                                    ch("Withdraw for now.", [])],
   where=["three_kings_land"], rank=(5, 9), type="chain", weight=30, chain="three_kings", req={"story": "three_kings", "step": 9})

# ============================ LONG CHAIN: RIVAL'S SHADOW (10 steps) ==========
rival_steps = [
    ("rv_1", "A Rival Is Born", "{rival} of the Bai clan is the same age as you, and the elders keep comparing you.", "village", (1, 2)),
    ("rv_2", "First Clash", "{rival} challenges you in front of everyone.", "village", (1, 3)),
    ("rv_3", "Sabotage", "Someone poisoned your Gu's food. Witnesses saw {rival}'s servant.", "village", (1, 3)),
    ("rv_4", "The Competition Trials", "Both of you are chosen for a clan trial in the woods.", "wild", (1, 3)),
    ("rv_5", "{rival}'s New Master", "Word is {rival} has taken a demonic master: Hei Tu.", "any", (2, 4)),
    ("rv_6", "Ambush", "{rival} and his master's men ambush you on the road.", "travel", (2, 5)),
    ("rv_7", "A Desperate Plea", "{rival}'s sister begs you to save him from Hei Tu before it's too late.", "village", (3, 5)),
    ("rv_8", "Hei Tu's Lair", "You track Hei Tu to a cave on the Wild Beast Plains.", "wild_beast_plains", (3, 6)),
    ("rv_9", "Choice of Blades", "Hei Tu is dead. {rival} kneels, beaten. His fate is yours to decide.", "any", (3, 6)),
    ("rv_10", "Rivals No More", "Years later, {rival} comes to see you.", "any", (4, 9)),
]
ev("rv_1", rival_steps[0][1], rival_steps[0][2], [ch("Swear to surpass {rival}.", [X("story", id="rival", step=1), X("cult", n=10)]), ch("Ignore the comparisons.", [X("story", id="rival", step=1)])],
   where=["village"], rank=(1, 2), type="chain", weight=6, once=True, chain="rival", req={"has_rival": True})
ev("rv_2", rival_steps[1][1], rival_steps[1][2], [ch("Fight.", [X("story", id="rival", step=2), X("fame", n=4)], fail=[X("story", id="rival", step=2), X("fame", n=-3)], check=fight(enemy="rival_disciple"))],
   where=["village"], rank=(1, 3), type="chain", weight=12, chain="rival", req={"story": "rival", "step": 1})
ev("rv_3", rival_steps[2][1], rival_steps[2][2], [ch("Accuse him before the elders.", [X("story", id="rival", step=3), X("standing", n=8)], check=chance(0.5, "wisdom"), fail=[X("story", id="rival", step=3), X("standing", n=-5)]),
                                                 ch("Take revenge quietly.", [X("story", id="rival", step=3), X("rep", n=-5)])],
   where=["village"], rank=(1, 3), type="chain", weight=12, chain="rival", req={"story": "rival", "step": 2, "days_since": 60})
ev("rv_4", rival_steps[3][1], rival_steps[3][2], [ch("Race him to the prize.", [X("story", id="rival", step=4), X("gu_pool", rank="r")], check=chance(0.55, "strength"), fail=[X("story", id="rival", step=4)]),
                                                 ch("Work together this once.", [X("story", id="rival", step=4), X("disp_rival", n=15), X("attain", path="primary", n=15)])],
   where=["wild", "travel"], rank=(1, 3), type="chain", weight=12, chain="rival", req={"story": "rival", "step": 3, "days_since": 60})
ev("rv_5", rival_steps[4][1], rival_steps[4][2], [ch("Gather information on Hei Tu.", [X("story", id="rival", step=5), X("info", n=1), X("meet_npc", npc="hei_tu", disp=-40)])],
   where=["any"], rank=(2, 4), type="chain", weight=10, chain="rival", req={"story": "rival", "step": 4, "days_since": 120})
ev("rv_6", rival_steps[5][1], rival_steps[5][2], [ch("Fight your way out.", [X("story", id="rival", step=6), X("fame", n=5)], fail=[X("story", id="rival", step=6), X("injury", name="Ambush Wounds", days=40)], check=fight(enemy="bandit_leader", count=2))],
   where=["travel"], rank=(2, 5), type="chain", weight=14, chain="rival", req={"story": "rival", "step": 5, "days_since": 60})
ev("rv_7", rival_steps[6][1], rival_steps[6][2], [ch("Agree to help.", [X("story", id="rival", step=7), X("rep", n=5)]), ch("He made his choice.", [X("story", id="rival", step=7), X("flag", id="rival_abandoned")])],
   where=["village", "city"], rank=(3, 5), type="chain", weight=10, chain="rival", req={"story": "rival", "step": 6, "days_since": 90})
ev("rv_8", rival_steps[7][1], rival_steps[7][2], [ch("Storm the lair.", [X("story", id="rival", step=8), X("kill_npc", npc="hei_tu"), X("stones", n=300), X("gu", id="crimson_tide")], check=fight(enemy="demonic_cultivator", count=2, rank="r+1")),
                                                 ch("Wait for a better moment.", [])],
   where=["wild_beast_plains"], rank=(3, 6), type="chain", weight=20, chain="rival", req={"story": "rival", "step": 7})
ev("rv_9", rival_steps[8][1], rival_steps[8][2], [ch("Spare him.", [X("story", id="rival", step=9), X("rep", n=10), X("disp_rival", n=40)]),
                                                 ch("End the rivalry for good.", [X("story", id="rival", step=9), X("rep", n=-10), X("kill_rival")])],
   where=["any"], rank=(3, 6), type="chain", weight=20, chain="rival", req={"story": "rival", "step": 8})
ev("rv_10", rival_steps[9][1], rival_steps[9][2], [ch("Greet him as a friend.", [X("story_done", id="rival"), X("rival_friend"), X("bt_bonus", n=10), X("gu_pool", rank="r", rarity="rare")])],
   where=["any"], rank=(4, 9), type="chain", weight=12, chain="rival", req={"story": "rival", "step": 9, "days_since": 365, "rival_alive": True})

# ============================ HU IMMORTAL (discovery chain, short) ===========
ev("hu_1", "A Fox in the Mist", "A white fox with nine pale markings watches you from the edge of the woods, then trots away, looking back.",
   [ch("Follow the fox.", [X("reveal", loc="hu_immortal_land"), X("log", text="Behind a curtain of mist, a hidden valley. The Hu Immortal Blessed Land!")], check=chance(0.6, "wisdom"), fail=[X("log", text="You lose it in the mist.")]),
    LEAVE],
   where=["qing_mao_woods", "travel"], rank=(2, 6), type="discovery", weight=5, goals=["explore", "inheritance"], req={"not_known": "hu_immortal_land"})
ev("hu_2", "The Fox's Gift", "In the heart of the Hu Immortal land, the white fox lays a cultivation Gu at your feet.",
   [ch("Accept the gift.", [X("gu", id="spring_autumn_cicada"), X("achieve", id="explorer")])],
   where=["hu_immortal_land"], rank=(1, 9), type="discovery", weight=30, once=True)

# ============================ EPOCH EVENTS ===================================
ev("epoch_verdant", "Verdant Great Inheritance", "The Verdant Great Inheritance has opened! Treasure hunters flood the wilds toward a forest that wasn't there yesterday.",
   [ch("Join the hunt.", [X("gu_pool", rank="r", rarity="legendary"), X("attain", path="primary", n=50), X("fame", n=10)], check=fight(group="demonic", count=2, rank="r")),
    ch("Trade information to the hunters.", [X("stones", n="60r"), X("info", n=2)]), ch("Stay away.", [])],
   where=["any"], rank=(1, 9), type="opportunity", weight=0, urgency="immediate", expiry=30)
ev("epoch_competition", "Southern Border Competition", "Every hundred years the clans send their best young Gu Masters to the arena. Your clan has chosen you.",
   [ch("Compete.", [X("fame", n=20), X("standing", n=40), X("gu_pool", rank="r", rarity="rare"), X("stones", n="80r")], check=fight(group="bandit", enemy="rogue_cultivator", count=3, rank="r")),
    ch("Decline the honour.", [X("standing", n=-20)])],
   where=["any"], rank=(1, 9), type="challenge", weight=0, urgency="immediate", expiry=30)
ev("epoch_storm", "Heavenly Tribulation Storm", "The sky splits. Lightning falls for days without end. Those who weather it come out changed.",
   [ch("Bathe in the lightning.", [X("cult", n="60r"), X("attain", path="primary", n=60)], fail=[X("injury", name="Lightning Burns", days=60), X("damage", pct=0.4)], check=chance(0.5)),
    ch("Shelter and wait it out (20 days).", [X("time", days=20)])],
   where=["any"], rank=(1, 9), type="challenge", weight=0, urgency="immediate", expiry=10)
ev("epoch_war", "Demonic Alliance War", "Demonic cultivators have united and marched on the Southern Border.",
   [ch("Fight for the righteous.", [X("rep", n=20), X("fame", n=15), X("stones", n="100r")], check=fight(group="demonic", count=3, rank="r")),
    ch("Join the demonic alliance.", [X("rep", n=-30), X("stones", n="150r"), X("gu_pool", rank="r", rarity="rare")]),
    ch("Hide in seclusion.", [X("time", days=90)])],
   where=["any"], rank=(1, 9), type="dilemma", weight=0, urgency="immediate", expiry=30)
ev("epoch_awaken", "Ancient Immortal Awakens", "An ancient Gu Immortal has awakened and is seeking disciples, or meals.",
   [ch("Seek an audience.", [X("cult", n="80r"), X("bt_bonus", n=15)], fail=[X("damage", pct=0.5)], check=chance(0.5, "wisdom")),
    ch("Flee the region.", [X("time", days=30)])],
   where=["any"], rank=(1, 9), type="dilemma", weight=0, urgency="immediate", expiry=30)
ev("epoch_beast_tide", "Great Beast Tide", "A tide of beasts pours off the Wild Beast Plains toward the villages.",
   [ch("Hold the wall.", [X("standing", n=25), X("mat_tier", tier="rare", n=2), X("fame", n=8)], check=fight(group="wild", count=3, rank="r")),
    ch("Evacuate villagers.", [X("rep", n=12), X("time", days=5)])],
   where=["any"], rank=(1, 9), type="challenge", weight=0, urgency="immediate", expiry=20)
ev("epoch_wolf_tide", "Thunder Wolf Tide", "Hundreds of wolves descend on Qing Mao Mountain. The clans must hold the line.",
   [ch("Fight on the front line.", [X("standing", n=25), X("stones", n="50r"), X("fame", n=6)], check=fight(enemy="grey_wolf", count=3, rank="r")),
    ch("Guard the clan's Gu stores.", [X("standing", n=10)])],
   where=["any"], rank=(1, 9), type="challenge", weight=0, urgency="immediate", expiry=20)
ev("epoch_auction", "Grand Merchant Auction", "The Grand Merchant Auction is being held in Merchant City this month.",
   [ch("Attend and bid.", [X("open_market", kind="auction")]), ch("Skip it.", [])],
   where=["any"], rank=(1, 9), type="opportunity", weight=0, urgency="urgent", expiry=30)
ev("epoch_plague", "Grey Plague", "A grey plague spreads through the settlements. Healers are overwhelmed.",
   [ch("Help the healers (30 days).", [X("time", days=30), X("rep", n=15), X("fame", n=8)], fail=[X("time", days=30), X("injury", name="Grey Fever", days=60)], check=chance(0.7)),
    ch("Seclude yourself until it passes.", [X("time", days=40)])],
   where=["any"], rank=(1, 9), type="challenge", weight=0, urgency="immediate", expiry=20)
ev("epoch_eclipse", "Blood Moon Eclipse", "The moon turns red. Blood path cultivators grow bold; light path cultivators weaken.",
   [ch("Cultivate under the blood moon.", [X("attain", path="blood", n=40), X("cult", n="20r")]), ch("Wait it out.", [])],
   where=["any"], rank=(1, 9), type="opportunity", weight=0, urgency="urgent", expiry=10)
ev("epoch_clan_war", "Gu Yue and Bai Clan War", "Old grudges boil over. The Gu Yue and Bai clans are at war.",
   [ch("Fight for your clan.", [X("standing", n=40), X("fame", n=10)], check=fight(group="bandit", enemy="rogue_cultivator", count=2, rank="r")),
    ch("Broker a truce.", [X("rep", n=15), X("standing", n=10)], check=chance(0.45, "wisdom"), fail=[X("standing", n=-10)])],
   where=["any"], rank=(1, 9), type="dilemma", weight=0, urgency="immediate", expiry=20)
ev("epoch_three_kings", "Three Kings Land Stirs", "A pillar of light rises beyond Dang Hun Mountain. The Three Kings Blessed Land is stirring.",
   [ch("Note the location.", [X("reveal", loc="three_kings_land"), X("info", n=1)])],
   where=["any"], rank=(1, 9), type="discovery", weight=0, urgency="urgent", expiry=30)

# ============================ IMMORTAL-STAGE EVENTS ==========================
ev("imm_auction", "Treasure Yellow Heaven", "The Treasure Yellow Heaven, where immortals trade, opens its gates to you.",
   [ch("Enter the auction.", [X("open_market", kind="treasure_yellow_heaven")]), LEAVE],
   where=["any"], rank=(6, 9), type="opportunity", weight=8)
ev("imm_sect", "Sect Elder's Challenge", "A Righteous Sect Elder senses your demonic deeds and descends from the clouds.",
   [ch("Fight.", [X("immortal_stones", n=20), X("fame", n=15)], check=fight(enemy="sect_elder")),
    ch("Bow and apologise.", [X("rep", n=10), X("immortal_stones", n=-5)], req={"immortal_stones": 5})],
   where=["any"], rank=(6, 9), weight=5, req={"align_max": -20})
ev("imm_dao_vision", "Dao Vision", "For a moment you see the dao marks of the world itself, like veins in jade.",
   [ch("Engrave what you saw.", [X("dao", n=40)])],
   where=["any"], rank=(6, 9), type="opportunity", weight=6, urgency="background")
ev("imm_eagle", "Golden Eagle Lord", "A golden eagle the size of a pavilion circles, then dives for you.",
   [ch("Fight.", [X("immortal_stones", n=15), X("beast_companion", name="Golden Eagle")], check=fight(enemy="eagle_lord")), ch("Hide in your blessed land.", [])],
   where=["northern_plains", "wild_beast_plains", "travel"], rank=(6, 9), weight=6)

# ============================ STORYLINE INDEX ================================
STORYLINES = [
    {"id": "orchid", "name": "The Withering Orchids", "length": "medium", "steps": 4, "start": "orchid_1"},
    {"id": "debt", "name": "The Merchant's Debt", "length": "medium", "steps": 4, "start": "debt_1"},
    {"id": "beast_king", "name": "The Beast King", "length": "medium", "steps": 3, "start": "bk_1"},
    {"id": "ember", "name": "The Ember Tyrant", "length": "short", "steps": 2, "start": "ember_1"},
    {"id": "three_kings", "name": "The Three Kings' Key", "length": "long", "steps": 10, "start": "tk_1"},
    {"id": "rival", "name": "A Rival's Shadow", "length": "long", "steps": 10, "start": "rv_1"},
]

# ---- procedural event templates (offline 'AI' generation, docs/AIGeneration.md) ----
TEMPLATES = [
    {"id": "tpl_beast", "title": "{adj} {beast}", "text": "A {adj_l} {beast_l} prowls near {loc}. {flavor}",
     "kind": "combat", "where": ["wild", "travel"]},
    {"id": "tpl_find", "title": "{adj} {thing}", "text": "You come across {article} {adj_l} {thing_l} half-buried in the {terrain}. {flavor}",
     "kind": "discovery", "where": ["wild", "travel"]},
    {"id": "tpl_npc", "title": "{npc_title} in Need", "text": "{npc}, a {arch_l}, asks for your help: {need}.",
     "kind": "favour", "where": ["village", "city"]},
    {"id": "tpl_trade", "title": "{arch} with a Deal", "text": "A {arch_l} offers you {offer} for {price} stones.",
     "kind": "trade", "where": ["village", "city", "travel"]},
]
WORDS = {
    "adj": ["Hungry", "Wounded", "Ancient", "Silent", "Scarred", "Pale", "Thunderous", "Moon-Eyed", "Starving", "Enormous"],
    "beast": ["Wolf", "Boar", "Spider", "Snake", "Bear", "Hawk", "Centipede", "Toad"],
    "beast_enemy": {"Wolf": "grey_wolf", "Boar": "black_boar", "Spider": "moon_spider", "Snake": "jade_eye_snake",
                    "Bear": "rock_bear", "Hawk": "grey_wolf", "Centipede": "moon_spider", "Toad": "jade_eye_snake"},
    "thing": ["Gu Corpse", "Stone Tablet", "Satchel", "Shrine", "Gu Pot", "Cracked Urn"],
    "terrain": ["mud", "grass", "roots", "riverbank", "scree", "snow"],
    "flavor": ["The air smells of iron.", "Birds have gone quiet.", "Something about it feels old.", "Your Gu stir uneasily.", "Mist curls around your ankles."],
    "need": ["their Gu fell sick and needs spirit water", "bandits stole their family's stones", "they need an escort through the woods",
             "they want help capturing a wild Gu", "their mentor vanished on the plains"],
    "offer": ["a scrap of a Gu formula", "a map of a beast den", "a crate of materials", "a rumour about a hidden blessed land", "a used but healthy Gu"],
}
