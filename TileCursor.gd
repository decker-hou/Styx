extends Sprite

onready var Game = get_parent()
onready var map = get_parent().map
onready var Tile = get_parent().Tile
onready var player = $"../Player"
onready var infobox = $"../UI/Right/Info"
onready var boonsData = $"../Boons"

#display the boon selected by keyboard
func displayBoon():
  var boon = player.deck[player.usingBoon]
  boonsData.display_boon(boon)
  
func _input(event):
  if (event is InputEventMouseButton and event.is_pressed()):
    var pos = get_global_mouse_position()
    var x = floor(pos.x / 16)
    var y = floor(pos.y / 16)
    if x >= 0 and y >= 0 and x < Game.mapSize.x and y < Game.mapSize.y:
      if Game.visibilitymap.get_cell(x, y) == -1: player.use_cursor_boon(x, y) 


func _process(delta):
    var pos = get_global_mouse_position()
    var x = floor(pos.x / 16)
    var y = floor(pos.y / 16)
    self.position = Vector2(x * 16, y * 16)
    
    if Game.scene != "House":
      if $"../UI/BoonSelect".visible or $"../UI/Inventory".visible or $"../UI/PomMenu".visible: return
      
    infobox.text = ""
    if player.usingBoon > -1: displayBoon()
    
    if x >= 0 and y >= 0 and x < Game.mapSize.x and y < Game.mapSize.y:
      if Game.scene == "House" or Game.visibilitymap.get_cell(x, y) == -1:
        var tile = map[x][y]
        if x == player.tile.x && y == player.tile.y:
          player.display_info()
        elif tile == Tile.Enemy:
          for e in Game.enemies:
            if e.tile.x == x && e.tile.y == y:
              e.display_info()
        elif tile == Tile.Item or tile == Tile.HeldItem:
          for i in Game.items:
            if i.tile.x == x && i.tile.y == y:
              i.display_info()
        elif tile == Tile.Exit:
          infobox.text = "Exit"
