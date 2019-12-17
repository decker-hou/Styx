extends Sprite

onready var cursor = get_parent().get_node("Highlight")
onready var itemCursor = get_parent().get_node("ItemHighlight")

var boon
onready var Boons = $"../../../../Boons"

func _on_hover_in():
  itemCursor.position.x = -200
  cursor.position = self.position
  Boons.display_boon(boon)