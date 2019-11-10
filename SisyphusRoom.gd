extends TileMap

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func init(x0, y0, Game):
  var x = x0
  var y = y0
  Global.new_sprite(load("res://assets/bouldy.png"), 1, 16*Vector2(x, y), Game, false)
  
  for i in range(x, x+2):
    for j in range(y, y+2):
      Game.map[i][j] = Game.Tile.Interactable
  
  print("sisy room init")