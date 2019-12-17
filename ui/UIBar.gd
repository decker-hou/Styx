extends ColorRect

var boonSlotTex = preload("res://assets/boonslot.png")

onready var player = $"../../Player"
onready var minimap = $"../Minimap"

const boonY = 36
const boonX = 380
const boonXinc = 3 * 20
const boonYinc = 0 #3 * 8
const barSize = 200 #hp and blood bars

var highlight

onready var keepsakes = $Keepsakes
onready var moreText  = $Money
var discard
var available
var manaDividers = []

func new_sprite(texture, scale, pos, parent=self, centered=true):
  var s = Sprite.new()
  s.texture = texture
  s.scale = Vector2(scale, scale)
  s.position = pos
  s.set_centered(centered)
  parent.add_child(s)
  return s
  
func new_label(text, font, pos, parent=self, scale=1):
  var s = Label.new()
  s.text = text
  s.rect_scale = Vector2(scale, scale)
  s.rect_position = pos
  s.add_font_override("font", font)
  parent.add_child(s)
  return s
  
var numberFont = load("res://fonts/NumberFont.tres")
var labelFont = load("res://fonts/LabelFont.tres")

func _ready():
  # drawing all the initial ui elements
  
  discard = new_sprite( load("res://assets/boonslot_filled.png"), 3, Vector2(boonX, boonY))
  new_label("+10", numberFont, Vector2(-4, -2), discard)
  new_label("Discarded", labelFont, Vector2(-8, 10), discard, 0.1666)
  
  for i in range(1, player.deckSize+1):
    var x = boonX + i * boonXinc
    var y = boonY + ((i+1) % 2) * boonYinc
    var slot = new_sprite(boonSlotTex, 3, Vector2(x, y))
    new_label("1", numberFont, Vector2(5, -8), slot)
    var s = new_sprite(load("res://assets/pom.png"), 0.3333333, Vector2(5,6), slot)  #pom icon
    s.visible = false
    new_label(str(i), labelFont, Vector2(-1, 10), slot, 0.1666)
    
  available = new_sprite( load("res://assets/boonslot_filled.png"), 3, Vector2(boonX + 6 * boonXinc, boonY))
  new_label("+10", numberFont, Vector2(-4, -2), available)
  new_label("Draw", labelFont, Vector2(-4, 10), available, 0.1666)
    
  #mana bar dividers, will need to call again if max mana changes
  draw_mana_bar()
  
  highlight = new_sprite(load("res://assets/boon_highlight.png"), 3, Vector2(0, 0))
  
  for i in range(12):
    var x = (i % 6) * 35
    var y = (i / 6) * 32
    new_sprite( null, 2, Vector2(x, y), keepsakes)
    
func draw_mana_bar():
  for i in range(manaDividers.size()):
    var r = manaDividers.pop_back()
    r.queue_free()
    
  var maxMana = player.maxMana
  var width = barSize / maxMana
  for i in range(1, maxMana):
    var rect = ColorRect.new()
    rect.rect_position = manabar.rect_position + Vector2(i * width, 0)
    rect.rect_size = Vector2(4, $ManaBar.rect_size.y)
    rect.color = self.color
    add_child(rect)
    manaDividers.append(rect)
    
onready var manabar = $ManaBar
func _draw():
  $HPBar.rect_size.x = barSize * player.currentHealth / player.maxHealth
  manabar.rect_size.x = barSize * min(1.0, player.currentMana / float(player.maxMana))
  manabar.color = Color.orange if floor(player.currentMana) > player.maxMana else Color(1, 0.85, 0, 1)
  
  $Armor.text = str(player.armor) + " Armor"
  $HP.text = "HP: " + str(player.currentHealth) + "/" + str(player.maxHealth)
  $Mana.text = "Blood: " + str(floor(player.currentMana)) + "/" + str(player.maxMana)
  
  var offset = 8
  for i in range(player.deckSize):
    var slot = get_child(i+offset) #bad code i know
    var cost = slot.get_child(0)
    var pom = slot.get_child(1)
    pom.visible = false
    if player.deck[i]:
      var boon = player.deck[i]
      slot.texture = boon.icon
      cost.text = str(boon.mana)
      cost.visible = true
      var color = Color.red if player.currentMana < boon.mana else Color.white
      cost.add_color_override("font_color", color)
      if boon.get("upgraded"): pom.visible = true
    else:
      slot.texture = boonSlotTex
      cost.visible = false
      
  if player.usingBoon >= 0:
    highlight.position = get_child(player.usingBoon + offset).position
  else:
    highlight.position = Vector2(-100, 0)
    
  var numBoons = player.boons.size()
  var availableCards = player.available.size()
  var discarded = player.discard.size()
  
  discard.get_child(0).text = "+" + str(discarded)
  available.get_child(0).text = "+" + str(availableCards)
  
  moreText.text = str(player.money)
  
  var reload = "\n(R to draw)" if player.is_hand_done() and player.boons.size() > 4 else ""
  available.get_child(1).text = "Draw" + reload
  
  #display held trinkets
  for i in range(12):
    if i >= player.heldItems.size(): keepsakes.get_child(i).texture = null
    else: keepsakes.get_child(i).texture = player.heldItems[i].texture
    
  minimap.update()