extends Sprite

var tile
var itemName
var itemData

onready var Game = get_parent()
onready var data = $"../Keepsakes"
onready var player = $"../Player"
onready var infobox = $"../UI/Right/Info"

var itemsList
enum Kind {Consumable, Keepsake}
var itemKind
var purchasable = false

##############
  
func _ready():
  Game.items.append(self)
  
#func init(x, y, kind="consumable", spawnList):

func init(x, y, itemName, isShop=false):
  tile = Vector2(x, y)
  position = tile * 16
  
  if isShop: purchasable = true
  self.itemName = itemName
  itemKind = Kind.Consumable if data.consumablesList.has(itemName) else Kind.Keepsake
  itemData = data.items.get(itemName)
  self.texture = itemData.texture
  
  
  if purchasable: #add a price tag
    var price = Label.new()
    price.text = str(itemData.cost)
    #s.rect_scale = Vector2(3, 3)
    price.rect_position = Vector2(0, 0)
    price.add_font_override("font", load("res://NumberFont.tres"))
    add_child(price)
  
func display_info():
  infobox.text = itemData.displayName + "\n\n" + itemData.description

func take_item():
  if purchasable:
    if player.money < itemData.cost: 
      player.display_status_popup("can't afford")
      return
    
  if itemKind == Kind.Keepsake:
    if player.heldItems.has(itemData): return  #can't pick up dupe keepsakes
    player.heldItems.append(itemData)
  
  if itemData.get("onPickup"): itemData.onPickup.call_func() 
  if purchasable: player.money -= itemData.cost
  
  if itemKind == Kind.Keepsake: data.remove_from_spawnTable(itemName)
  remove_self()
  
func remove_self():
  Game.place_tile(tile.x, tile.y, Game.Tile.Floor)
  Game.items.erase(self)
  queue_free()
  Game.upgrade_visuals()