extends ColorRect

onready var tween = $Tween

func spin_in():
  self.rect_scale.y = 1
  tween.interpolate_property(self, "rect_scale:x", 0, 1, 0.15, Tween.TRANS_QUINT, Tween.EASE_IN)
  tween.start()
  
func spin_out():
  self.rect_scale.y = 1
  tween.interpolate_property(self, "rect_scale:x", 1, 0, 0.15, Tween.TRANS_QUINT, Tween.EASE_IN)
  tween.start()
  
func use_anim():
  tween.interpolate_property(self, "modulate:a", 1, 0, 0.25, Tween.TRANS_LINEAR, Tween.EASE_IN)
  tween.interpolate_property(self, "rect_scale", Vector2(1,1), Vector2(1.1,1.1), 0.25, Tween.TRANS_SINE, Tween.EASE_IN)
  tween.start()
  yield(tween, "tween_completed")
  self.modulate.a = 1
  self.visible = false
  
func update_card(boon):
  $BoonName.text = boon.name
  $God.text = "Innate" if boon.god == "Zagreus" else "Curse" if boon.god == "Curse" else "Boon of " + boon.god
  $BoonIcon.texture = boon.icon
  $ManaCost.text = str(boon.mana)
  $Pom.visible = boon.has("upgraded")
  var text = parse_desc(boon)
  if boon.has("target"):
    if boon.target == "area" or boon.target == "self":
      text += "\nSPACE to activate"
    elif boon.target == "cursor":
      text += "\nClick to activate"
  $BoonDesc.text = text
  
func parse_desc(boon):
  var strs = boon.description.split("@", false)
  
  for i in range(strs.size()):
    #special cases
    if strs[i] == "statusTurns-1": strs[i] = str(boon.statusTurns - 1)
    elif boon.get(strs[i]):
      strs[i] = str(boon[strs[i]])
  var result = strs.join("")
  
  if boon.get("instant"): result += " Instant."
  if boon.get("target") == "unplayable": result = "Unplayable. " + result
  return result