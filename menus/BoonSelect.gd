extends ColorRect

var item
onready var player = $"../../Player"
onready var boonsData = $"../../Boons"

func _input(event):
  if !event.is_pressed():
    return
  if not self.visible: return
  
  if event.is_action_pressed("atk1"):
    givePlayerBoon(0)
  elif event.is_action_pressed("atk2"):
    givePlayerBoon(1)
  elif event.is_action_pressed("atk3"):
    givePlayerBoon(2)
  elif event.is_action_pressed("reload"):
    item.removeSelf()
    self.visible = false
  else:
    pass
  get_tree().set_input_as_handled()
  
func display_boons(god, boons):
  $BoonSelect/Title.text = god + " offers a boon"
  
  for i in range(3):
    var card = $BoonSelect.get_child(i+1)
    card.spin_in()
    if i >= boons.size():
      card.visible = false
    else: 
      card.visible = true
      var boon = boons[i]
      card.update_card(boon)
      
#returns whether screen should be open after this
func givePlayerBoon(i):
  if i >= item.pickedBoons.size(): return
  var boon = boonsData.get_boon(item.pickedBoons[i])
  if boon.repeatedOffer == 0: boonsData.givenBoons.append(boon.name)
  player.gain_boon(boon)
  
  item.removeSelf()
  self.visible = false