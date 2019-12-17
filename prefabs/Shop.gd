extends TileMap


func onPlacement(Game, x0, y0):
  Game.place_tile(x0 + 2, y0 + 3, Game.Tile.HeldItem)
  var item = Game.instantiate_held_item(x0 + 2, y0 + 3, "shopFood")
  item.make_purchasable()
  
  Game.place_tile(x0 + 3, y0 + 3, Game.Tile.HeldItem)
  var item2 = Game.instantiate_held_item(x0 + 3, y0 + 3, "shopConsumables")
  item2.make_purchasable()
  
  Game.place_tile(x0 + 4, y0 + 3, Game.Tile.HeldItem)
  var item3 = Game.instantiate_held_item(x0 + 4, y0 + 3, "shopKeepsakes")
  item3.make_purchasable()
