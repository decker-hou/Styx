extends ColorRect

const boonsPerRow = 16
const boonY = 76
const boonY2 = 294
const boonX = 20
const boonXinc = 4 * 10
const yStagger = 4 * 10
const boonYinc = 4 * 20

onready var menu = $PomMenu
onready var infobox = $"../Right/Info"
onready var player = $"../../Player"

const BoonSprite = preload("res://PomMenuBoonSprite.tscn")

var selectedBoon = null
var sprites = []

var outOfBoons = false

func new_boon_sprite(boon, scale, pos, parent=self):
  var s = BoonSprite.instance()
  s.texture = boon["icon"]
  s.scale = Vector2(scale, scale)
  s.position = pos
  parent.add_child(s)
  s.boon = boon
  sprites.append(s)
  return s

func open():
  self.visible = true
  var upgraded = []
  var notUpgraded = []
  for b in player.boons:
    if b.get("upgraded") or (not b.get("upgrades")):
      upgraded.append(b)
    else:
      notUpgraded.append(b)
      
  outOfBoons = notUpgraded.size() == 0
      
  for i in notUpgraded.size():
    var boon = notUpgraded[i]
    var row = i % boonsPerRow
    var col = i / boonsPerRow
    var x = boonX + boonXinc * row
    var y = boonY + boonYinc * col + yStagger * (row % 2)
    var s = new_boon_sprite(boon, 4, Vector2(x,y), menu)
    
  for i in upgraded.size():
    var boon = upgraded[i]
    var row = i % boonsPerRow
    var col = i / boonsPerRow
    var x = boonX + boonXinc * row
    var y = boonY2 + boonYinc * col + yStagger * (row % 2)
    var s = new_boon_sprite(boon, 4, Vector2(x,y), menu)

func _on_Button_pressed():  
  if selectedBoon or outOfBoons:
    if selectedBoon:
      $"../../Boons".upgrade_boon(selectedBoon)
      
    $"../UIBar".update()
    $PomMenu/Highlight.position.x = -200
    $PomMenu/Picked.position.x = -200
    for s in sprites:
      s.queue_free()
    sprites = []
    infobox.text = ""
    selectedBoon = null
    self.visible = false

#func _input(event):
#  if not self.visible: return
#  get_tree().set_input_as_handled()