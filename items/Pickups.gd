extends Node

onready var Game = get_parent()
onready var player = $"../Player"
onready var infobox = $"../UI/Right/Info"

var keepsakesList = ["Kindle", "Feather", "Blood", "Eye", "Nail", "Old Collar", "Coin Purse", "Lucky Tooth", "Moly", "Girdle", "Wind Bag", "Crit Boost", "Blood Regen"]  #can only ever have one
var consumablesList = ["Hammer", "Obols", "Heart", "Party Favor", "Food", "Onion", "Pom", "TutBoon1", "TutBoon2", "TutBoon3" ]

var spawnTables = {
  "keepsakes": ["Kindle", "Feather", "Blood", "Nail", "Old Collar", "Coin Purse", "Lucky Tooth", "Moly", "Girdle", "Wind Bag", "Crit Boost", "Blood Regen"],
  "consumables": ["Obols", "Heart", "Pom", "Food"],
  "shopFood": ["Food"],
  "shopConsumables": ["Heart", "Pom"],
  "shopKeepsakes": ["Kindle", "Feather", "Blood", "Nail", "Old Collar", "Lucky Tooth", "Moly", "Girdle", "Wind Bag", "Crit Boost", "Blood Regen"],
  #"dionysusBoon": ["Party Favor"],
  }
  
var tempRemoved = {}

onready var items = {
  "Old Collar": {
    displayName = "Old Spiked Collar",
    description = "Maximum HP +50",
    cost = 100,
    texture = load("res://assets/item_collar.png"),
    onPickup = funcref(self, "gain_max_hp_collar"),
  },

  "Coin Purse": {
    displayName = "Chthonic Coin Purse",
    description = "Receive 100 obols on pickup.",
    cost = 0,
    texture = load("res://assets/item_purse.png"),
    pickupSound = "coin",
    onPickup = funcref(self, "gain_money_purse"),
  },
  
  "Lucky Tooth": {
    displayName = "Lucky Tooth",
    description = "Survive lethal damage once and regain 20% of your max health.",
    cost = 130,
    texture = load("res://assets/item_tooth.png"),
    onDeath = funcref(self, "death_defy"),
  },
  
  "Moly": {
    displayName = "Holy Moly",
    description = "Negative status effects wear off twice as fast.",
    cost = 100,
    texture = load("res://assets/item_moly.png"),
    onTurnEnd = funcref(self, "wear_off_debuffs"),
  },
  
  "Eye": {
    displayName = "Eye of Argus",
    description = "Allows you to see through doors.",
    cost = 100,
    texture = load("res://assets/item_eye.png"),
    onPickup = funcref(self, "see_through_doors"),
  },
    
  "Girdle": {
    displayName = "Golden Girdle",
    description = "Gain 1 armor each time you use a boon.",
    cost = 110,
    texture = load("res://assets/item_girdle.png"),
    onBoonUse = funcref(self, "girdle_effect"),
  },
  
  "Wind Bag": {
    displayName = "Bag of Wind",
    description = "All dash boons have +1 range.",
    cost = 100,
    texture = load("res://assets/item_bag.png"),
    beforeBoonUse = funcref(self, "wind_bag_effect"),
  },
  
  "Crit Boost": {
    displayName = "Adamantine Needle",
    description = "+3% critical chance to all attacks.",
    cost = 150,
    texture = load("res://assets/item_needle.png"),
    onPickup = funcref(self, "add_crit_chance"),
  },
  
  "Nail": {
    displayName = "Bronze Nail",
    description = "Lose 0.1 blood every turn, +15% damage to all attacks.",
    cost = 130,
    texture = load("res://assets/item_nail.png"),
    onPickup = funcref(self, "nail_attack_up"),
    onTurnEnd = funcref(self, "nail_bleed"),
  },
  
  "Blood Regen": {
    displayName = "Hydralite Zero",
    description = "+0.05 Blood regeneration per turn.",
    cost = 115,
    texture = load("res://assets/item_hydralite.png"),
    onPickup = funcref(self, "gain_blood_regen"),
  },
  
  "Feather": {
    displayName = "Strix Feather",
    description = "+50% chance to dodge when you're moving or dashing.",
    cost = 120,
    texture = load("res://assets/item_feather.png"),
    onPlayerAction = funcref(self, "feather_dodge"),
  },
  
  "Kindle": {
    displayName = "Kindle of Meleager",
    description = "When a foe dies, inflict a random nearby foe with Burn.",
    cost = 130,
    texture = load("res://assets/item_kindle.png"),
    onEnemyDeath = funcref(self, "kindle_burn"),
  },
  
  "Obols": {
    displayName = "Pile of Obols",
    description = "+50 obols",
    cost = 0,
    texture = load("res://assets/coin_pile.png"),
    pickupSound = "coin",
    onPickup = funcref(self, "gain_money"),
  },
  "Food": {
    displayName = "Food",
    description = "+15 health",
    cost = 25,
    texture = load("res://assets/item_food.png"),
    pickupSound = "heal",
    onPickup = funcref(self, "heal"),
  },
  "Heart": {
    displayName = "Centaur Heart",
    description = "Maximum HP +10",
    cost = 50,
    pickupSound = "pom",
    texture = load("res://assets/centaur_heart.png"),
    onPickup = funcref(self, "gain_max_hp"),
  },
  "Blood": {
    displayName = "Kiss of Styx",
    description = "Maximum Blood +1",
    cost = 100,
    texture = load("res://assets/item_kiss.png"),
    onPickup = funcref(self, "gain_max_blood"),
  },
  "Pom": {
    displayName = "Pom of Power",
    description = "Upgrades a boon of your choice.",
    cost = 70,
    onPickup = funcref(self, "pom_of_power"),
    pickupSound = "pom",
    texture = load("res://assets/pom.png"),
  },
  
  "Hammer": {
    displayName = "Daedalus Hammer",
    description = "Duplicate a boon.",
    cost = 100,
    onPickup = funcref(self, "hammer"),
    pickupSound = "hammer",
    texture = load("res://assets/hammer.png"),
  },
  
  "Onion": {
    displayName = "Red Onion",
    description = "Whoops, ran out of items to spawn. Have an onion.",
    cost = 1,
    texture = load("res://assets/item_onion.png"),
    onPickup = funcref(self, "onion_heal"),
  },
  "Party Favor": {
    displayName = "Party Favor",
    description = "Gain 3 blood.",
    texture = load("res://assets/party_urn.png"),
    onPickup = funcref(self, "gain_blood"),
  },
  "Party Favor+": {
    displayName = "Party Favor+",
    description = "Gain 3 blood, you keep any excess.",
    texture = load("res://assets/party_urn.png"),
    onPickup = funcref(self, "gain_blood_overflow"),
  },
  "TutBoon1": {
    displayName = "Bloodstone",
    description = "",
    texture = load("res://assets/cast.png"),
    onPickup = funcref(self, "gain_boon1"),
  },
  "TutBoon2": {
    displayName = "Blood Dash",
    description = "",
    texture = load("res://assets/dash_boon.png"),
    onPickup = funcref(self, "gain_boon2"),
  },
  "TutBoon3": {
    displayName = "Nova Smash",
    description = "",
    texture = load("res://assets/smash.png"),
    onPickup = funcref(self, "gain_boon3"),
  }
}

func _ready():
  for key in spawnTables:
    tempRemoved[key] = []
    spawnTables[key].shuffle()

#each time this is called it will pick the next one
func pick_from_spawnTable(tableName):
  var table = spawnTables[tableName]
  if table.size() == 0: return "Onion"
  
  var s = table.pop_front()
  if tableName == "consumables" or tableName == "shopConsumables" or tableName == "shopFood": 
    table.append(s)
    table.shuffle()
  else:
    #both shop keepsake and regular keepsake spawn tables should be kept in sync
    var otherTable = "shopKeepsakes" if tableName == "keepsakes" else "keepsakes"
    spawnTables[otherTable].erase(s)
    tempRemoved[tableName].append(s)
    tempRemoved[otherTable].append(s)
  return s
  
#called when new floor generates
func shuffle_spawntables():
  for key in spawnTables:
    spawnTables[key] += tempRemoved[key]
    tempRemoved[key] = []
    spawnTables[key].shuffle()
  
func remove_from_spawnTable(item):  # keepsakes can only be gotten once
  spawnTables["keepsakes"].erase(item)
  tempRemoved["keepsakes"].erase(item)
  spawnTables["shopKeepsakes"].erase(item)
  tempRemoved["shopKeepsakes"].erase(item)
  
func display_item_info(itemData):
  var text = itemData.displayName + "\n\n" + itemData.description
  infobox.text = text
  
########## unique functions for items

#onPickup

func heal():
  player.currentHealth += 15
  player.currentHealth = min(player.currentHealth, player.maxHealth)
  
func onion_heal():
  player.currentHealth += 1
  player.currentHealth = min(player.currentHealth, player.maxHealth)
  
func add_crit_chance():
  player.baseCritChance += 0.03
  
func gain_max_hp():
  player.maxHealth += 10
  player.currentHealth += 10
  
func gain_blood():
  player.currentMana += 3
  player.currentMana = min(player.currentMana, player.maxMana)
  
func gain_blood_overflow():
  player.currentMana += 3
  
func gain_max_blood():
  player.maxMana += 1
  player.currentMana += 1
  $"../UI/UIBar".draw_mana_bar()
  
func gain_max_hp_collar():
  player.maxHealth += 50
  player.currentHealth += 50
  
func gain_money():
  player.money += 50
  
func gain_money_purse():
  player.money += 100
  
func gain_blood_regen():
  player.manaRegen += 0.05
  
func see_through_doors():
  #tileset resource has been made local to scene so this doesn't persist between scenes
  Game.tilemap.get_tileset().tile_set_shape(Game.Tile.Door, 0, null)
  
func nail_attack_up():
  player.damageMultiplier += 0.15
  
func pom_of_power():
  $"../UI/PomMenu".open()
  
func hammer():
  pass
    
#onBoonUse - only called once boon is successfully used
func girdle_effect():
  player.armor += 1
  
func gain_boon1():
  for i in range(3):
    player.gain_boon_by_name("Bloodstone")
    
func gain_boon2():
  player.gain_boon_by_name("Blood Dash")
  
func gain_boon3():
  player.gain_boon_by_name("Nova Smash")
  
#beforeBoonUse - takes the boon and transforms it. if it's meant to be temporary (last until the boon is used), put the temporary keys under temp
func wind_bag_effect(boon):  
  if boon.target == "dash": 
    boon["temp"].dashRange = boon.dashRange
    boon.dashRange += 1
  
#onDeath
func death_defy():
  player.display_status_popup("Death Defy")
  player.currentHealth = int(player.maxHealth * 0.2)

#onPlayerAction - called immediately AFTER play performs an action
func feather_dodge():
  if player.walked_this_turn or player.dash_this_turn:
    player.dodgeChance = 0.5
  else:
    player.dodgeChance = 0
    
#onTurnEnd - player turn ends after enemies acted
func nail_bleed():
  player.currentMana = max(0, player.currentMana - 0.1)

func wear_off_debuffs():
  for i in range(player.statusEffects.size()-1, -1, -1):
    var status = player.statusEffects[i]
    var statusInfo = Game.Status.get(status.status)
    if not statusInfo.get("noDeplete") and statusInfo.type == "debuff":
      status.turns -= 1
    if status.turns == 0:
      if status.get("particles"): status.particles.queue_free()
      player.statusEffects.erase(status)
    
#onEnemyDeath
func kindle_burn(deadEnemy):
  var enemies = []
  for e in Game.enemies:
    if e.visible and not e.state.dead: enemies.append(e)
  if enemies.size() > 0:
    var target = enemies[randi() % enemies.size()]
    target.gain_status({status = "Burned", turns = 5})