extends "res://Item.gd"

var itemid

var items = {
  "Old Collar": {
    description = "Maximum HP +20",
    texture = preload("res://assets/item_collar.png"),
    onPickup = funcref(self, "gain_max_hp"),
  },
  
  "Mana Thing": {
    description = "Maximum Blood +1",
    texture = preload("res://assets/item_collar.png"),
    onPickup = funcref(self, "gain_max_mana"),
  }
}


########## unique functions for items

func gain_max_hp(item, player):
  player.maxHealth += 20
  player.currentHealth += 20
  
  
##############

func _ready():
  itemid = 0 #items[randi() % items.size()]
  self.texture = items["Old Collar"].texture
  
  var pos = self.position / 16
  tile = pos
  Game.items.append(self)