extends Sprite
#shared code between players and enemies
#parent node must be Game

var tile
var selfTile

var statusEffects = []

onready var Game = get_parent()
onready var map = get_parent().map
onready var Tile = get_parent().Tile
onready var infobox = $"../UI/Right/Info"
onready var Status = get_parent().Status
onready var pointer = $Pointer

onready var tweenNode = get_node("Tween")
onready var damageNum = $Damage/Damage
onready var statusPopup = $Status/Status

var tookDamageThisTurn = false
var movedThisTurn = false
var dmgThisTurn = 0
var statusThisTurn = null

var maxHealth
var currentHealth
var armor = 0
var dodgeChance = 0

var wallSlamDamage = 5

#flips sprite left or right
func update_look_direction(xdir):
  if xdir == -1: self.set_flip_h(true)
  elif xdir == 1: self.set_flip_h(false)
  
func get_random_direction():
  var x = randi() % 2
  x *= ((randi() % 2) * 2) - 1
  var y = (x + 1) % 2
  y *= ((randi() % 2) * 2) - 1
  return Vector2(x, y)

func upgrade_visuals():
  #display_accumulated_damage()
  var oldPos = self.position
  tweenNode.interpolate_property(self, "position", oldPos, tile * 16, 0.05, Tween.TRANS_LINEAR, Tween.EASE_OUT)
  tweenNode.start()
  
func display_accumulated_damage():
  if tookDamageThisTurn:
    display_damage(dmgThisTurn)
  tookDamageThisTurn = false
  dmgThisTurn = 0
  if statusThisTurn:
    display_status_popup(statusThisTurn)
    statusThisTurn = null

func wear_off_effects():
  for i in range(statusEffects.size()-1, -1, -1):
    var status = statusEffects[i]
    var statusInfo = Game.Status.get(status.status)
    if not statusInfo.get("noDeplete"):
      status.turns -= 1
    
    if status.get("wearOffCondition"):
      if status.wearOffCondition.call_func():
        status.turns = 0
      
    if status.turns <= 0: 
      if status.get("particles"): status.particles.queue_free()
      statusEffects.erase(status)
      
      if status.status == "Torrent Step":  #this is temporary, we should move it closer to Boons or effects later
        for t in self.tempWaterTiles:
          Game.change_tile(t.x, t.y, Tile.Floor)
        self.tempWaterTiles = []
  
#called at the end of each turn
func turn():
  if has_status("Poisoned Wine"): take_damage(get_status_turns("Poisoned Wine"), null)
  if has_status("Burned"): take_damage(1, null)
  display_accumulated_damage()
  
  movedThisTurn = false
  wear_off_effects()
  
  for s in statusEffects:
    if s.get("onTurnEnd"): s.onTurnEnd.call_func(s.boon)
  
func move(nx, ny):
  Game.change_tile(tile.x, tile.y, Tile.Floor)
  tile = Vector2(nx, ny)
  Game.change_tile(tile.x, tile.y, selfTile)
  

func try_move(dx, dy):
  return try_move_to(tile.x + dx, tile.y + dy)
    
func try_move_to(x, y):
  if has_status("Immobilized") or has_status("Stunned"):
    return true
  if has_status("Tipsy"):
    var dir = get_random_direction()
    x = tile.x + dir.x
    y = tile.y + dir.y
    
  var dx = x - tile.x
  update_look_direction(dx)
  
  var target = map[x][y]
  if target == Tile.Floor:
    move(x, y)
    movedThisTurn = true
    return true
  return false
    
func has_status(name):
  for s in statusEffects:
    if s.status == name: return true
  return false
  
func get_status_turns(name):
  for s in statusEffects:
    if s.status == name: return s.turns
  return 0
  
func gain_status_from_boon_data(boon):
  var st = {status= boon.statusEffect, turns= boon.statusTurns}
  if boon.get("wearOffCondition"): st.wearOffCondition = boon.wearOffCondition
  if boon.get("statusFunc"): 
    st.onTurnEnd = boon.statusFunc
    st.boon = boon
  gain_status(st)
  
func gain_status(data, display = true):
  if display: statusThisTurn = data.status    #the last status effect applied this round will show
  for s in statusEffects:
    if s.status == data.status:
      if Status.get(s.status).get("additive"): s.turns += data.turns
      else: s.turns = data.turns    #resets number of turns, doesn't add
      return
     
  var statusData = Status.get(data.status)
   
  var new = {}        #we have to manually copy the data 
  for key in data:
    new[key] = data[key]
  
  if statusData.get("particles"):
    var p = statusData.particles.instance()
    new.particles = p
    self.add_child(p)
  
  statusEffects.append(new)
    
#returns the target's status
func attack(target, dmg):
  if has_status("Stunned"): return null
  if has_status("Weak"):
    dmg = dmg / 2 #floor
  return target.take_damage(dmg, self)
  
  
enum TakeDamageStatus {Nothing, Died}

func take_damage(dmg, attacker):  
  if has_status("Boiling Blood"):
    dmg = floor(dmg * 1.5)
  self.tookDamageThisTurn = true
  self.dmgThisTurn += dmg
  
  var dp = dmg
  var armor_dmg = min(armor, dp)
  armor -= armor_dmg
  dp -= armor_dmg
  
  if has_status("Storm Shroud") and attacker:
    var dx = attacker.tile.x - self.tile.x
    var dy = attacker.tile.y - self.tile.y
    if abs(dx) + abs(dy) == 1: attacker.knockback(dx, dy, 1)
  
  if armor_dmg > 0 and has_status("Reflective Armor") and attacker:   #okay if both has this status this will spiral, but only zag has this for now so it's okay
    attacker.take_damage(dmg, self)                     
  
  currentHealth -= dp
  if currentHealth < 0: currentHealth = 0
  if currentHealth == 0: 
    die()
    return TakeDamageStatus.Died
  return TakeDamageStatus.Nothing
  
func knockback(dx, dy, kbRange):
  for i in range(kbRange):
    var result = try_move(dx, dy)
    if not result: 
      take_damage(wallSlamDamage, null)
      if selfTile != Tile.Player: gain_status({status = "Stunned", turns = 1}, false)
      display_status_popup("wall slam!")
      break
  upgrade_visuals()  #so enemy moves immediately
  
func die():
  pass
  
#quick_animation
func bump_anim(x, y):
  var dx = (x - tile.x) * 4
  var dy = (y - tile.y) * 4
  
  var offset = Vector2(dx, dy)
  
  tweenNode.interpolate_property(self, "offset", Vector2(0, 0), offset, 0.02, Tween.TRANS_LINEAR, Tween.EASE_OUT)
  tweenNode.start()
  yield(tweenNode, "tween_completed")
  tweenNode.interpolate_property(self, "offset", offset, Vector2(0, 0), 0.02, Tween.TRANS_LINEAR, Tween.EASE_OUT)
  tweenNode.start()
  
#displays it in the hover right hand bar
func display_status():
  for s in statusEffects:
    var desc = Status.get(s.status).desc
    infobox.text += s.status + " (" + str(s.turns) + ")\n" + desc + "\n\n"

onready var statusDefaultPos = statusPopup.rect_position
const popupTime = 0.4

func display_status_popup(s):
  if Status.get(s):
    statusPopup.add_color_override("font_color", Status[s].textColor)
    statusPopup.text = Status[s].shortText
  else:
    statusPopup.add_color_override("font_color", Color.white)
    statusPopup.text = s
    
  statusPopup.visible = true
  tweenNode.interpolate_property(statusPopup, "rect_position", statusDefaultPos, statusDefaultPos-Vector2(0,5), popupTime, Tween.TRANS_LINEAR, Tween.EASE_OUT)
  tweenNode.start()
  yield(get_tree().create_timer(popupTime),"timeout")
  statusPopup.rect_position = statusDefaultPos
  statusPopup.visible = false
  
onready var defaultPos =  damageNum.rect_position
func display_damage(damage):
  damageNum.text = str(damage)
  damageNum.visible = true
  tweenNode.interpolate_property(damageNum, "rect_position", defaultPos, defaultPos-Vector2(0,5), popupTime, Tween.TRANS_LINEAR, Tween.EASE_OUT)
  tweenNode.start()
  yield(get_tree().create_timer(popupTime),"timeout")
  damageNum.rect_position = defaultPos
  damageNum.visible = false
  