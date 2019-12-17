extends Sprite

var item
onready var Keepsakes = $"../../../../Keepsakes"
onready var boonCursor = get_parent().get_child(0)
onready var cursor = get_parent().get_child(1)

func _on_Area2D_mouse_entered():
  boonCursor.position.x = -200
  cursor.position = self.position
  Keepsakes.display_item_info(item)