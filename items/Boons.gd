extends Node

var boons = {
  "zag": [
    {name = "Bloodstone",
    mana = 1,
    basePower = 8,
    statusEffect = "Boiling Blood",
    statusTurns = 6, #bc first turn doesn't do anything
    icon = preload("res://assets/cast.png"),
    god = "Zagreus",
    description = "Deal @basePower@ damage. Inflict Boiling Blood for @statusTurns-1@ turns.",
    upgrades = {statusTurns = 11} },
    
    {name = "Nova Smash",
    mana = 3,
    basePower = 30,
    target = "area",
    icon = preload("res://assets/smash.png"),
    god = "Zagreus",
    description = "Deal @basePower@ damage in the surrounding tiles.",
    upgrades = {mana = 1}},
    
    {name = "Regain Favor",
    mana = 0,
    target = "self",
    onUse = funcref(self, "shuffle_discard"),
    icon = preload("res://assets/blood_boon.png"),
    sfx = "regain_favor",
    god = "Zagreus",
    description = "Shuffle discard pile into draw pile, then draw." },
    
    {name = "Blood Dash",
    mana = 1,
    target = "dash",
    dashRange = 4,
    icon = preload("res://assets/dash_boon.png"),
    god = "Zagreus",
    sfx = "dash",
    description = "Dash up to @dashRange@ tiles away in one direction, passing through foes and low obstacles.",
    upgrades = {instant = true} },
  ],
  
  "Artemis": [
    {name = "Hunter's Javelin",
    mana = 2,
    basePower = 18,
    critChance = 0.5,
    critMultiplier = 2,
    icon = preload("res://assets/artemis_boon_4.png"),
    god = "Artemis",
    description = "Deal @basePower@ damage, with a 50% chance of a critical hit." },
    
    {name = "Swift Strike",
    mana = 1,
    basePower = 12,
    quickDraw = true,
    icon = preload("res://assets/artemis_boon_1.png"),
    god = "Artemis",
    description = "Deal @basePower@ damage, then instantly draw a boon from available deck.",
    upgrades = {basePower = 18} },
    
    {name = "Twin Daggers",
    mana = 1,
    basePower = 7,
    multihit = 2,
    icon = preload("res://assets/artemis_boon_2.png"),
    god = "Artemis",
    description = "Deal @basePower@ damage twice.",
    upgrades = {basePower = 11} },
    
    {name = "Protective Camouflage",
    mana = 1,
    gainArmor = 10,
    target = "self",
    icon = preload("res://assets/artemis_boon_shield.png"),
    god = "Artemis",
    description = "Gain @gainArmor@ armor.",
    upgrades = {gainArmor = 15} },
    
    {name = "Hunter Dash",
    mana = 1,
    target = "dash",
    dashRange = 4,
    basePower = 10,
    onDashThroughEnemy = funcref(self, "artemis_dash_dmg"),
    icon = preload("res://assets/artemis_dash_boon.png"),
    god = "Artemis",
    sfx = "dash",
    description = "Dash up to @dashRange@ tiles away in one direction, dealing @basePower@ damage to foes passed through.",
    upgrades = {basePower = 18} },
    
    {name = "Fury of the Wilds",
    mana = 2,
    target = "self",
    statusEffect = "Wild Fury",
    statusTurns = 25,
    icon = preload("res://assets/artemis_boon_3.png"),
    god = "Artemis",
    description = "For @statusEffect@ turns, if you deal a critical hit, you get a free turn.", },
    
  ],
  
  "Athena": [
    {name = "Panoply of Pallas",
    mana = 2,
    gainArmor = 15,
    target = "self",
    icon = preload("res://assets/athena_boon_2.png"),
    god = "Athena",
    description = "Gain @gainArmor@ armor.",
    upgrades = {gainArmor = 20} },
    
    {name = "Polished Bronze",
    mana = 2,
    basePower = 0,
    target = "self",
    statusEffect = "Reflective Armor",
    statusTurns = 20,
    icon = preload("res://assets/athena_boon_5.png"),
    god = "Athena",
    description = "For @statusTurns@ turns, all damage dealt to armor is inflicted back on the attacker.",
    upgrades = {statusTurns = 40} },
    
    {name = "Assured Victory",
    mana = 1,
    basePower = 10,
    maxPower = 25,
    icon = preload("res://assets/athena_boon_3.png"),
    god = "Athena",
    onKill = funcref(self, "athena_power_up_kill"),
    description = "Deal @basePower@ damage. Increase damage by 5 each time this boon kills a foe, up to @maxPower@.",
    upgrades = {maxPower = 40}},
    
    {name = "Keen-Eyed Strike",
    mana = 1,
    basePower = 12,
    icon = preload("res://assets/athena_boon_1.png"),
    god = "Athena",
    onUse = funcref(self, "athena_status_attack"),
    description = "Deal @basePower@ damage, doubled if foe has two or more negative status effects.",
    upgrades = {basePower = 16} },
    
    {name = "Phalanx Slam",
    mana = 3,
    basePower = 20,
    statusEffect = "Stunned",
    statusTurns = 1,
    target = "area",
    icon = preload("res://assets/athena_boon_4.png"),
    god = "Athena",
    description = "Deal @basePower@ damage in the surrounding tiles, and stun foes for 1 turn.", },
  ],
  
  "Aphrodite": [
    {name = "Divine Beauty",
    mana = 2,
    target = "area",
    icon = preload("res://assets/aphrodite_boon_2.png"),
    god = "Aphrodite",   
    statusEffect = "Weak",
    statusTurns = 8,
    description = "Inflict Weak for @statusTurns@ turns on every enemy in the surrounding tiles.",
    upgrades = {statusTurns = 16} },
    
    {name = "Passion Strike",
    mana = 1,
    basePower = 12, 
    statusEffect = "Weak",
    statusTurns = 5,
    icon = preload("res://assets/aphrodite_boon_3.png"),
    god = "Aphrodite",
    description = "Deal @basePower@ damage and inflict Weak for @statusTurns@ turns.",
    upgrades = {statusTurns = 9} },
    
    {name = "Dazzling Dash",
    mana = 1,
    target = "dash",
    dashRange = 4,
    statusEffect = "Immobilized",
    statusTurns = 4,
    onDashThroughEnemy = funcref(self, "aphrodite_dash_effect"),
    icon = preload("res://assets/aphrodite_dash_boon.png"),
    god = "Aphrodite",
    sfx = "dash",
    description = "Dash up to @dashRange@ tiles away in one direction, immobilizing foes passed through for @statusTurns@ turns.",
    upgrades = {statusTurns= 8} },
    
    {name = "Painful Rejection",
    mana = 1,
    basePower = 13,
    statusEffect = "Immobilized",
    statusTurns = 5,
    icon = preload("res://assets/aphrodite_boon_1.png"),
    god = "Aphrodite",
    description = "Deal @basePower@ damage and immobilize the target for @statusTurns@ turns.",
    upgrades = {basePower = 20} },
    
    {name = "Pure Devotion",
    mana = 2,
    basePower = 5,
    onUse = funcref(self, "aphro_devotion"),
    icon = preload("res://assets/aphrodite_boon_4.png"),
    god = "Aphrodite",
    description = "Deal @basePower@ damage for every boon from the Olympian who has given you the most boons.", 
    upgrades = {basePower = 8}},
  ],
  
  "Dionysus": [
    {name = "Poisoned Libations",
    mana = 1,
    statusEffect = "Poisoned Wine",
    statusTurns = 6,
    icon = preload("res://assets/dionysus_boon_1.png"),
    god = "Dionysus",
    description = "Inflict @statusEffect@ for @statusTurns@ turns.",
    upgrades = {statusTurns = 8} },
    
    {name = "Festive Fog",
    mana = 1,
    basePower = 12,
    target = "cursor",
    statusEffect = "Tipsy",
    statusTurns = 10, 
    icon = preload("res://assets/dionysus_boon_3.png"),
    god = "Dionysus",
    description = "Deal @basePower@ damage to the foe under the cursor, and inflict @statusEffect@ for @statusTurns@ turns.",
    upgrades = {basePower = 18, statusTurns = 15} },
    
    {name = "Secret Stash",
    mana = 1,
    target = "self",
    beforeUse = funcref(self, "spawn_blood_cache"),
    icon = preload("res://assets/dionysus_boon_2.png"),
    god = "Dionysus",
    description = "Place down a party favor. When picked up, it gives back 3 blood.",
    upgrades = {description = "Place down a party favor. When picked up, it gives back 3 blood. You keep any excess."} },
    
    {name = "Midnight Festivities",
    mana = 1,
    target = "cursor",
    turns = 4,
    onUse = funcref(self, "dio_status_extend"),
    icon = preload("res://assets/dionysus_boon_4.png"),
    god = "Dionysus",
    description = "Extend all of the target's status effects by @turns@ turns.",
    upgrades = {turns = 6}},
    
    {name = "Fortifying Wine",
    mana = 1,
    target = "self",
    threshhold = 20,
    onUse = funcref(self, "dio_heal"),
    icon = preload("res://assets/dionysus_boon_5.png"),
    god = "Dionysus",
    description = "Restore health to threshhold of @threshhold@% of max health.",
    upgrades = {threshhold = 30}},
  ],
  
  "Zeus": [
    {name = "Thunderbolt",
    mana = 1,
    basePower = 12,
    target = "cursor",
    statusEffect = "Immobilized",
    statusTurns = 4,
    icon = preload("res://assets/zeus_boon_1.png"),
    god = "Zeus",
    description = "Strike the foe under the cursor, dealing @basePower@ damage and immobilizing for @statusTurns@ turns.",
    upgrades = {basePower = 20} },
    
    {name = "Chain Lightning",
    mana = 1,
    basePower = 10,
    onUse = funcref(self, "zeus_chain_lightning"),
    icon = preload("res://assets/zeus_boon_2.png"),
    god = "Zeus",
    description = "Deal @basePower@ damage that spreads to adjacent foes.",
    upgrades = {basePower = 20} },
    
    {name = "Magnificent Hospitality",
    mana = 3,
    target = "self",
    onUse = funcref(self, "zeus_reduce_blood_cost"),
    icon = preload("res://assets/zeus_boon_3.png"),
    god = "Zeus",
    description = "All boons in your hand cost 0 blood.",
    upgrades = {mana = 1, instant = true} },
    
    {name = "Olympian Authority",
    mana = 1,
    basePower = 14,
    afterUse = funcref(self, "zeus_draw_new_hand"),
    icon = preload("res://assets/zeus_boon_4.png"),
    god = "Zeus",
    description = "Deal @basePower@ damage, discard all boons in hand and draw a new hand.",},
    
    {name = "Lightning Rod",
    mana = 2,
    basePower = 5,
    target = "self",
    statusEffect = "Lightning Rod",
    statusTurns = 1,
    statusFunc = funcref(self, "zeus_lightning_rod"),
    onUse = funcref(self, "zeus_remember_player_position"),
    wearOffCondition = funcref(self, "zeus_player_moved"),
    icon = preload("res://assets/zeus_boon_5.png"),
    god = "Zeus",
    description = "Strike a random foe for @basePower@ damage every turn, effect ends as soon as you move from your current position.",
    upgrades = {basePower = 8}
    },
  ],
  
  "Ares": [
    {name = "Flurry Blades",
    mana = 1,
    basePower = 2,
    multihit = 8,
    icon = preload("res://assets/ares_boon_5.png"),
    god = "Ares",
    description = "Deals @basePower@ damage @multihit@ times.",
    upgrades = {multihit = 12} },
    
    #partially implemented, right now all curses add 10 damage
    {name = "Vengeful Curse",
    mana = 1,
    basePower = 10,
    icon = preload("res://assets/ares_boon_2.png"),
    god = "Ares",
    onUse = funcref(self, "ares_curse_attack"),
    description = "Deals @basePower@ damage, plus extra damage for each curse in your hand, depending on the curse's strength.",
    upgrades = {basePower = 18} },
    
    {name = "Preemptive Assault",
    mana = 2,
    basePower = 40,
    powerDecrease = 10,
    icon = preload("res://assets/ares_boon_1.png"),
    god = "Ares",
    afterUse = funcref(self, "ares_power_down_attack"),
    description = "Deal @basePower@ damage. Decrease damage by @powerDecrease@ each time this boon is used. Min 5 damage.",
    upgrades = {powerDecrease = 5} }, 
    
    {name = "Sanguine Protection",
    mana = 1,
    target = "self",
    basePower = 10,
    icon = preload("res://assets/ares_boon_3.png"),
    god = "Ares",
    onUse = funcref(self, "ares_health_to_armor"),
    description = "Converts 10 health into 30 armor.",
    upgrades = {instant = true} }, 
    
    {name = "Lethal Strike",
    mana = 1,
    basePower = 14,
    icon = preload("res://assets/ares_boon_4.png"),
    god = "Ares",
    onKill = funcref(self, "ares_instant_on_kill"),
    description = "Deal @basePower@ damage, instant if this boon kills an enemy.",
    upgrades = {mana = 2, basePower = 30} }, 
  ],
  
  "Poseidon": [
    {name = "Tempest Strike",
    mana = 1,
    basePower = 14,
    knockbackRange = 1,
    onUse = funcref(self, "poseidon_knockback"),
    icon = preload("res://assets/poseidon_boon_1.png"),
    god = "Poseidon",
    description = "Deal @basePower@ damage and knock back foe 1 tile.",
    upgrades = {basePower = 18, knockbackRange = 2, description = "Deal @basePower@ damage and knock back foe 2 tiles."} },
    
    {name = "Tidal Wave",
    mana = 1,
    target = "area",
    knockbackRange = 2, 
    onHitEnemy = funcref(self, "poseidon_knockback"),
    icon = preload("res://assets/poseidon_boon_3.png"),
    god = "Poseidon",
    description = "Knock away all foes in the surrounding area by @knockbackRange@ tiles.",
    upgrades = {knockbackRange = 4} },     #upgrade should deal more kb damage honestly
    
    {name = "Storm Shroud",
    mana = 2,
    target = "self",
    statusEffect = "Storm Shroud",
    statusTurns = 8,
    icon = preload("res://assets/poseidon_boon_2.png"),
    god = "Poseidon",
    description = "For @statusTurns@ turns, foes are knocked back 1 tile when they hit you at melee range.",
    upgrades = {statusTurns = 15} },
    
    {name = "Torrent Step",
    mana = 1,
    target = "self",
    statusEffect = "Torrent Step",
    statusTurns = 8,
    icon = preload("res://assets/poseidon_boon_4.png"),
    god = "Poseidon",
    description = "For @statusTurns@ turns, when you move, leave behind a line of water tiles, which disappear on effect end.",
    upgrades = {mana = 0, statusTurns = 16} },
    
    {name = "Favorable Currents",
    mana = 1,
    target = "self",
    instant = true,
    onUse = funcref(self, "make_a_boon_instant"),
    icon = preload("res://assets/poseidon_boon_5.png"),
    god = "Poseidon",
    description = "A random boon in your hand becomes instant.",
    upgrades = {quickDraw = true, description = "A random boon in your hand becomes instant, then draw a boon from available deck."} },
    ],
  
  "Curse": [
    {name = "Numb",
    mana = 0,
    target = "unplayable",
    discardRemove = true,
    icon = preload("res://assets/curse_boon_1.png"),
    god = "Curse",
    description = "Remove from deck when discarded." },
    
    {name = "Disfavored",
    mana = 0,
    target = "unplayable",
    discardRemove = false,
    icon = preload("res://assets/curse_boon_1.png"),
    god = "Curse",
    description = "If this curse is in hand, Regain Favor costs 3 blood." },
  ],
}

onready var Game = get_parent()
onready var player = $"../Player"
onready var infobox = $"../UI/Right/Info"

var givenBoons = []

#instantiate a full NEW data structure from the data above
func get_boon(boon):
  var b = {}
  for key in boon:
    b[key] = boon[key]
    
  b["temp"] = {}
  if not b.get("target"): b["target"] = "melee"
  if not b.get("critChance"): b["critChance"] = 0
  if not b.get("multihit"): b["multihit"] = 1
  if not b.get("oneTimeUse"): b["oneTimeUse"] = false
  if not b.get("repeatedOffer"): b["repeatedOffer"] = 0    #this should be a numeral counting how many times it can give
  if not b.get("unplayable"): b["unplayable"] = false
  if not b.get("instant"): b["instant"] = false
  return b
  
func get_boon_by_name(name):
  for key in boons:
    var list = boons[key]
    for b in list:
      if b["name"] == name: return get_boon(b)
  print("couldn't find " + name)
  return 0
  
  
func parse_desc(boon):
  var strs = boon.description.split("@", false)
  
  for i in range(strs.size()):
    #special cases
    if strs[i] == "statusTurns-1": strs[i] = str(boon.statusTurns - 1)
    elif boon.get(strs[i]):
      strs[i] = str(boon[strs[i]])
  var result = strs.join("")
  
  if boon.get("instant"): result += " Instant."
  if boon.get("target") == "unplayable": result = "Unplayable. " + result
  return result
      
func display_boon(boon):
  var text
  var godMsg = "Innate" if boon.god == "Zagreus" else "Curse" if boon.god == "Curse" else "Boon of " + boon.god
  text = boon.name + "\n" + godMsg + "\nBlood cost: " + str(boon.mana) + "\n\n"
  text += parse_desc(boon)
  if boon.target == "area" or boon.target == "self":
    text += "\n\nSPACE to activate"
  elif boon.target == "cursor":
    text += "\n\nClick on a tile to activate"
  infobox.bbcode_text = text
  
func display_boon_upgrades(b):
  if b == null: 
    infobox.bbcode_text = ""
    return
    
  display_boon(b)
  
  if not b.get("upgrades"):
    infobox.bbcode_text += "\n\n\n[color=yellow]NO UPGRADES\n\n"
    return
  elif b.get("upgraded"):
    infobox.bbcode_text += "\n\n\n[color=yellow]ALREADY UPGRADED\n\n"
    return
  
  var boon = get_boon(b)
  upgrade_boon(boon)
  var text
  text = boon.name + "\nBlood cost: " + str(boon.mana) + "\n\n"
  text += parse_desc(boon)
  infobox.bbcode_text += "\n\n\n[color=yellow]UPGRADED:\n\n" + text + "[/color]"
  
func upgrade_boon(boon):
  if boon.get("upgraded"): return
  boon.upgraded = true
  boon.name += "+"
  if boon.get("upgrades"):
    for k in boon.upgrades:
      boon[k] = boon.upgrades[k]
 
#the temporary attribute is restored once the boon has been used once  
func give_boon_temp_property(boon, property, value):
  var old_val = boon[property]
  boon[property] = value
  boon.temp[property] = old_val
  
########## unique functions for boon effects. all of the same kind take same arguments to make things easy
#####onUse functions are called immediately before default damage dealing stuff

###onUse
func shuffle_discard(b, target):
  player.shuffle_discard_pile()
  
func get_adjacent_enemies(x, y):
  var enemies = []
  var pos = [Vector2(x+1, y), Vector2(x-1, y), Vector2(x, y+1), Vector2(x, y-1)]
  for p in pos:
    for e in Game.enemies:
      if e.tile == p: enemies.append(e)
  return enemies
  
func zeus_chain_lightning(boon, target):
  var queue = [target]
  var enemiesHit = [target]
  while queue.size() > 0:
    var enemy = queue.pop_back()
    var neighbours = get_adjacent_enemies(enemy.tile.x, enemy.tile.y)
    for e in neighbours:
      if not enemiesHit.has(e):
        queue.append(e)
        enemiesHit.append(e)
        player.attack(e, boon.basePower)
        
func poseidon_knockback(boon, target):
  var dx = target.tile.x - player.tile.x
  var dy = target.tile.y - player.tile.y
  target.knockback(dx, dy, boon.knockbackRange)

func make_a_boon_instant(boon, target):
  var boons = []
  for b in player.deck:
    if b and b != boon and not b.get("instant"):
      boons.append(b)
  
  if boons.size() > 0:
    var r = boons[randi() % boons.size()]
    give_boon_temp_property(r, "instant", true)

func dio_status_extend(boon, target):
  for s in target.statusEffects:
    s.turns += boon.turns
    
func dio_heal(boon, target):
  var maxHealth = floor( player.maxHealth * (boon.threshhold / 100.0))
  player.currentHealth = max(player.currentHealth, maxHealth)
  
func aphro_devotion(boon, target):
  var most = 1
  for b in player.boons:
    var god = b.god
    if god != "Zagreus":
      var count = 0
      for b2 in player.boons:
        if b2.god == god: count += 1
      if count > most: most = count
  boon.basePower = 10 * most
  
func athena_status_attack(boon, target):
  var counter = 0
  for s in target.statusEffects:
    if Game.Status[s.status].type == "debuff": counter += 1  #should only count negative effects
  
  if counter >= 2: 
    var newPower = boon.basePower * 2
    give_boon_temp_property(boon, "basePower", newPower)

func ares_curse_attack(boon, t):
  var power = boon.basePower
  for b in player.deck:
    if b and b.god == "Curse" : power += 10
  give_boon_temp_property(boon, "basePower", power)

func ares_health_to_armor(boon, t):
  var points = min(boon.basePower, player.currentHealth-1)
  player.currentHealth -= points
  player.armor += 3 * points
  
func ares_armor_to_damage(boon, t):
  boon.basePower = player.armor
  player.armor = 0
  
func zeus_reduce_blood_cost(boon, t):
  for b in player.deck:
    if b and b != boon:
      give_boon_temp_property(b, "mana", 0)
      
      
var zeus_boon_pos
func zeus_remember_player_position(boon, t):
  zeus_boon_pos = player.tile
 
#called by status effects 
func zeus_lightning_rod(boon):
  var enemies = []
  for e in Game.enemies:
    if e.visible and not e.state.dead: enemies.append(e)
  if enemies.size() > 0:
    var target = enemies[randi() % enemies.size()]
    target.take_damage(boon.basePower, null)
    
    
#wearOffConditions
func zeus_player_moved():
  return zeus_boon_pos != player.tile

#beforeUse, which is called the same time as onUse but can return false to show the boon failed

func spawn_blood_cache(boon, target):
  var x = player.tile.x
  var y = player.tile.y
  var pos = [Vector2(x+1, y), Vector2(x-1, y), Vector2(x, y+1), Vector2(x, y-1)]
  pos.shuffle()
  while pos.size() > 0:
    var t = pos.pop_back()
    if Game.map[t.x][t.y] == Game.Tile.Floor:
      var p = Game.HeldItem.instance()
      Game.add_child(p) 
      if boon.get("upgraded"): p.init(t.x, t.y, "Party Favor+")
      else: p.init(t.x, t.y, "Party Favor")
      Game.map[t.x][t.y] = Game.Tile.HeldItem
      return true
  player.display_status_popup("Cannot Place")
  return false
  
#onDashThroughEnemy
func artemis_dash_dmg(b, e):
  e.take_damage(b.basePower, player)
  
func aphrodite_dash_effect(b, e):
  e.gain_status_from_boon_data(b)
 
#afterUse - called after card has been put into discard pile
func ares_power_down_attack(b):
  if b.basePower > 10:
    b.basePower -= b.powerDecrease  
    
func zeus_draw_new_hand(b):
  for i in player.deckSize:
    player.discard(i)
  player.reloadBoons()
   
#onKill
func athena_power_up_kill(b, t):
  if b.basePower < b.maxPower: 
    b.basePower += 5  
    
func ares_instant_on_kill(b, t):
  player.free_turn = true
  
  