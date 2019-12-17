extends TileMap

onready var Game = get_tree().get_root().get_node("Game")
var map
var visibility


func init():
  map = Game.tilemap
  visibility = Game.visibilitymap

func update():
  self.clear()
  
  set_cellv(Game.player.tile, 1)
  var cells = map.get_used_cells()
  for c in cells:
    if visibility.get_cellv(c) != 0:
      match map.get_cellv(c):
        Game.Tile.Wall:
          set_cellv(c, 0)
        Game.Tile.Exit:
          set_cellv(c, 2)
        Game.Tile.Talker:
          set_cellv(c, 3)
        _:
          pass
