extends Sprite

onready var cursor = get_parent().get_node("Highlight")
onready var pickedCursor = get_parent().get_node("Picked")

var boon
onready var Boons = $"../../../../Boons"
onready var parent = $"../.."

func _on_hover_in():
  cursor.position = self.position
  Boons.display_boon_upgrades(boon)

func _on_mouse_exited():
  if cursor.position == self.position: 
    cursor.position.x = -200
    Boons.display_boon_upgrades(parent.selectedBoon)


func _on_Area2D_input_event(viewport, event, shape_idx):
  if (event is InputEventMouseButton and event.is_pressed()):
    if boon.get("upgrades") and not boon.get("upgraded"):
      parent.selectedBoon = boon
      pickedCursor.position = self.position
