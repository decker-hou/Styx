extends ColorRect

const boonsPerRow = 16
const boonY2 = 250
const boonY = 40
const boonX = 20
const boonXinc = 4 * 10
const yStagger = 4 * 10
const boonYinc = 4 * 20

const itemX = 145
const itemY = 395
const itemXinc = 3*16
onready var inv = $Inventory
onready var infobox = $"../Right/Info"

const BoonSprite = preload("res://ClickableBoonSprite.tscn")
const ItemSprite = preload("res://ClickableItemSprite.tscn")

func _input(event):
  if !event.is_pressed():
    return
  if not self.visible: return
  
  if event.is_action_pressed("inventory"):   #close
    var nodes = inv.get_children()
    for i in range(5, nodes.size()):
      nodes[i].queue_free()
    infobox.text = ""
    inv.get_child(0).position.x = -200
    inv.get_child(1).position.x = -200
    self.visible = false

  get_tree().set_input_as_handled()
  
func new_boon_sprite_collisions(boon, scale, pos, parent=self):
  var s = BoonSprite.instance()
  s.texture = boon["icon"]
  s.scale = Vector2(scale, scale)
  s.position = pos
  parent.add_child(s)
  s.boon = boon
  return s
  
func new_item_sprite(item, scale, pos, parent=self):
  var s = ItemSprite.instance()
  s.texture = item.texture
  s.scale = Vector2(scale, scale)
  s.position = pos
  parent.add_child(s)
  s.item = item
  return s


func open(player):
  self.visible = true
  var available = []
  var discarded = []
  for b in player.boons:
    if player.discard.has(b):
      discarded.append(b)
    else:
      available.append(b)
      
  for i in available.size():
    var boon = available[i]
    
    var row = i % boonsPerRow
    var col = i / boonsPerRow
    
    var x = boonX + boonXinc * row
    var y = boonY + boonYinc * col + yStagger * (row % 2)
    
    var s = new_boon_sprite_collisions(boon, 4, Vector2(x,y), inv)
    
  for i in discarded.size():
    var boon = discarded[i]
    
    var row = i % boonsPerRow
    var col = i / boonsPerRow
    
    var x = boonX + boonXinc * row
    var y = boonY2 + boonYinc * col + yStagger * (row % 2)
    
    var s = new_boon_sprite_collisions(boon, 4, Vector2(x,y), inv)
    
  for i in player.heldItems.size():
    var item = player.heldItems[i]
    
    var x = itemX + i * itemXinc
    var y = itemY
    
    var s = new_item_sprite(item, 3, Vector2(x,y), inv)