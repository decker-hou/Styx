extends "res://entities/MovingEntity.gd"

const HEAL_POOL_AMOUNT = 20

var maxMana = 3
var currentMana = maxMana
var manaRegen = 0.4

var money = 0
var keys = 0
var heldItems = []

var boons = []      #total boon pool
var deck = []       #active hand
var discard = []
var available = []

var deckSize = 5    #boons in play, not total boons in pool
var usingBoon = -1

var combo = 0
var lastTurnAttack = false
var baseDamage = 3  #weak basic attack, not changed by boons
var baseCritChance = 0  #can be increased occasionally
var baseCritMultiplier = 2
var damageMultiplier = 1

var missTurn = false
var walked_this_turn = false
var dash_this_turn = false
var free_turn = false   #has the player earned a free turn this round
var input = true

onready var pomMenu = $"../UI/PomMenu"
onready var boonData = $"../Boons"
onready var audioPlayer = $"PlayerSfx"
onready var timer = $InputTimer

func _ready():
  selfTile = Tile.Player
  maxHealth = 50
  currentHealth = maxHealth
  deck.resize(deckSize)
  give_starting_hand()
  damageNum.add_color_override("font_color", Color.red)
 
func give_starting_hand(): 
  if boonData: #no boon data in the house
    deck[0] = boonData.get_boon_by_name("Bloodstone")
    deck[1] = boonData.get_boon_by_name("Bloodstone")
    deck[2] = boonData.get_boon_by_name("Bloodstone")
    deck[3] = boonData.get_boon_by_name("Blood Dash")
    deck[4] = boonData.get_boon_by_name("Nova Smash")
    for i in range(5):
      boons.append(deck[i])
      
var moveDir
  
func _unhandled_input(event):
  if not self.input: return
  var turnPass = false
    
  if !event.is_pressed(): return    #filters out non presses
  
  if pomMenu and pomMenu.visible: return    #such a temp hack until i figure out how the hell input handling works
    
  ######don't act when just selecting a boon
  if event.is_action_pressed("atk1"):
    selectBoon(0)
  elif event.is_action_pressed("atk2"):
    selectBoon(1)
  elif event.is_action_pressed("atk3"):
    selectBoon(2)
  elif event.is_action_pressed("atk4"):
    selectBoon(3)
  elif event.is_action_pressed("atk5"):
    selectBoon(4)
  elif event.is_action_pressed("atk"):
    turnPass = use_spacebar_boon()      #this is fine cause it calls useBoon
  elif event.is_action_pressed("reload"):
    if usingBoon == -1: 
      turnPass = reloadBoons() #actually only be true if you succeed reloading
  elif event.is_action_pressed("wait"):
    if usingBoon == -1: 
      audioPlayer.play_sample("wait")
      display_status_popup("wait")
      turnPass = true
  elif event.is_action_pressed("inventory"):
    if usingBoon == -1: 
      $"../UI/Inventory".open(self)
  else:
    var input_x = int(event.is_action("ui_right")) - int(event.is_action("ui_left"))
    var input_y = int(event.is_action("ui_down")) - int(event.is_action("ui_up"))
    if input_x or input_y:
      turnPass = try_direction_action(input_x, input_y)
      
  if free_turn: 
    display_status_popup("Free turn!")
    turnPass = false
    free_turn = false
  else:
    for i in heldItems:
      if i.get("onPlayerAction"):
        i.onPlayerAction.call_func()
  Game.turn(turnPass)
  
func is_unpassable_tile(t):
  return t == Tile.Wall or t == Tile.Exit or t == Tile.Walltop or t == Tile.Door
    
#dash in a straight line, blocked by walls but passing enemies and items
func useDashBoon(dx, dy):
  var boon = deck[usingBoon]
    
  var targetTile
  var blocked = boon.dashRange+1
  var dashEnd
  
  for i in range(1, boon.dashRange+1):    #first check for walls
    var tile_content = map[tile.x + dx*i][tile.y + dy*i]
    if is_unpassable_tile(tile_content):
      blocked = i
      break
      
  var enemies = []
  for i in range(1, blocked):    #now check every tile up to the wall for the last empty tile
    var tile_content = map[tile.x + dx*i][tile.y + dy*i]
    if tile_content == Tile.Floor:
      dashEnd = i
      targetTile = Vector2( tile.x + dx*i , tile.y + dy*i)
    
  if not targetTile: 
    bump_anim(tile.x + dx, tile.y + dy)
    return false
  else: 
    if boon.get("onDashThroughEnemy"):
      for i in range(1, dashEnd):
        var tx = tile.x + dx*i
        var ty = tile.y + dy*i
        var tile_content = map[tx][ty]
        if tile_content == Tile.Enemy:
          for e in Game.enemies:
            if e.tile.x == tx and e.tile.y == ty:
              boon.onDashThroughEnemy.call_func(boon, e)
    
    dash_this_turn = true    
    try_move_to(targetTile.x, targetTile.y)
    boonUsed(boon)
    return true
    
var kb = false
func knockback(dx, dy, kbRange):
  kb = true
  .knockback(dx, dy, kbRange)
  kb = false
    
func try_move(dx, dy):
  return try_direction_action(dx, dy)
  
#arrow keys action, returns if turn passed successfully
func try_direction_action(dx, dy):
  
  update_look_direction(dx)
  
  if usingBoon >= 0 and deck[usingBoon].target == "dash":
    return useBoon(Vector2(dx, dy))
    
  var nx = tile.x + dx
  var ny = tile.y + dy
  return try_action_on_tile(nx, ny)
  
func try_action_on_tile(x, y):
  var target = map[x][y]
  
  if usingBoon != -1 and target != Tile.Enemy: 
    display_damage("NO TARGET")
    return false
  
  match target:
    Tile.Floor:
      move(x, y)
      audioPlayer.play_sample("footstep")
      if not kb: walked_this_turn = true
      return true
    Tile.Enemy:
      for e in Game.enemies:
        if e.tile.x == x and e.tile.y == y:
          if player_attack(e): #returns whether attack was successful enough to end a turn
            bump_anim(x, y)
            return true
          else: return false
    Tile.Item:   #boons
      for i in Game.items:
        if i.tile.x == x and i.tile.y == y:
          i.take_item()
    Tile.HeldItem:
      for i in Game.items:
        if i.tile.x == x and i.tile.y == y:
          i.take_item()
          
          if i.itemData.has("pickupSound"):
            audioPlayer.play_sample(i.itemData.pickupSound)
          else:
            audioPlayer.play_sample("defaultPickup")
            
          if not kb: walked_this_turn = true
          try_move_to(x, y)
          return true
    Tile.Door:
      audioPlayer.play_sample("openDoor")
      Game.change_tile(x, y, Tile.Floor)
      bump_anim(x, y)
    Tile.LockedDoor:
      audioPlayer.play_sample("openDoor")
      if keys > 0:
        keys -= 1
        Game.change_tile(x, y, Tile.Floor)
        bump_anim(x, y)
    Tile.Exit:
      if Game.scene == "Tutorial" or Game.scene == "House":
        get_tree().change_scene("res://Game.tscn")
      else:
        if Game.level == 4:
          game_over()
        else:
          Game.level += 1
          Game.init()
      return false
    Tile.Talker:
      for npc in Game.npcs:      #for now npc data is just a simple dict with no functions
        if is_in_character_box(npc, x, y):
          $"../UI/Dialog".open(npc.dialog)
    Tile.Urn:
      audioPlayer.play_sample("urnSmash")
      Game.change_tile(x, y, Tile.Floor)
      bump_anim(x, y)
    Tile.Healing:
      audioPlayer.play_sample("pool")
      Game.change_tile(x, y, Tile.EmptyPool)
      bump_anim(x, y)
      heal_pool()
    _:
      audioPlayer.play_sample("bump")
      bump_anim(x, y) 
      return false
  return true
  
var tempWaterTiles = []

func move(nx, ny):
  var oldTile = tile
  .move(nx, ny)
  if has_status("Torrent Step"):
    Game.change_tile(oldTile.x, oldTile.y, Tile.Pool)
    self.tempWaterTiles.append(oldTile)
  
func is_in_character_box(c, nx, ny):
  return nx >= c.tile.x and ny >= c.tile.y and nx < c.tile.x + c.size.x and ny < c.tile.y + c.size.y
    
func player_attack(enemy):
  if usingBoon >= 0 and (deck[usingBoon].target == "melee" or deck[usingBoon].target == "area"):
    return useBoon(enemy)
  else: #basic attack
    audioPlayer.play_sample("sword")
    var damage = baseDamage + combo * baseDamage
    damage *= damageMultiplier
    var fractionPart = damage - floor(damage)
    damage = floor(damage)
    if randf() < fractionPart: damage += 1
    
    if (randf() < baseCritChance):
      if has_status("Wild Fury"): 
        free_turn = true
      enemy.display_status_popup("Critical")
      damage *= baseCritMultiplier
        
    attack(enemy, damage)
    lastTurnAttack = true
    return true
  
onready var card = $"../UI/Right/Card"
#tries to select boon index i
func selectBoon(i):
  if deck[i]:
    if usingBoon == i:
      usingBoon = -1
      card.spin_out()
      return
    usingBoon = i
    card.visible = true
    card.spin_in()

#TODO: none of these should be called direction, all boons go through useBoon so we can calculate item effects on them
func use_spacebar_boon():
  if usingBoon < 0: return false
  var boon = deck[usingBoon]
  if boon.target == "area" or boon.target == "self":
    return useBoon(null)
  return false
      
func use_cursor_boon(x, y):
  if usingBoon < 0: return false
  var boon = deck[usingBoon]
  if boon.target != "cursor": return false
  
  var enemy = null
  for e in Game.enemies:
    if e.tile.x == x and e.tile.y == y: 
      enemy = e
      break
  if not enemy:
    display_damage("NO TARGET")
    return false
  var turnPass = useBoon(enemy)
  Game.turn(turnPass)
  

func copy_dict(d):
  var dic = {}
  for k in d:
    dic[k] = d[k]
  return dic
  
func get_status_from_boon(boon):
  var st = {status= boon.statusEffect, turns= boon.statusTurns}
  if boon.get("wearOffCondition"): st.wearOffCondition = boon.wearOffCondition
  if boon.get("statusFunc"): 
    st.onTurnEnd = boon.statusFunc
    st.boon = boon
  return st
    
#try to use currently selected boon, return success or failure
func useBoon(enemy):
  if usingBoon < 0: return false
  var boon = deck[usingBoon]
  
  for i in heldItems:
    if i.get("beforeBoonUse"):
      i.beforeBoonUse.call_func(boon)    #this may add temp attributes to boon
      
  if boon.target == "unplayable": return false
  
  if currentMana < boon.mana: 
    display_damage("OUT OF BLOOD")
    return false
  
  if not enemy and boon.target == "melee": return false 
  
  if boon.get("beforeUse"): 
    var result = boon.beforeUse.call_func(boon, enemy)
    if result == false: return false

  if boon.has("sfx"):
    audioPlayer.play_sample(boon.sfx)
  else:
    audioPlayer.play_sample("defaultAttack")
  
  if boon.get("onUse"): boon.onUse.call_func(boon, enemy)
  
  if boon.target == "dash": 
    return useDashBoon(enemy.x, enemy.y) #dx and dy
    
  for i in boon.multihit:
    var gotCrit = false
    var damage = 0
    if boon.get("basePower"):
      damage = boon.basePower
      if (randf() < (boon.critChance + baseCritChance)):
        gotCrit = true
        if has_status("Wild Fury"): 
          free_turn = true
        var critMult = boon.critMultiplier if boon.get("critMultiplier") else baseCritMultiplier
        damage *= critMult
    
    if boon.target == "self":
      if boon.get("gainArmor"): self.armor += boon.gainArmor
      
      if boon.get("statusEffect"):
        var st = get_status_from_boon(boon)
        self.gain_status(st)

      
    elif boon.target == "area":
      var hit = false
      for x in range(tile.x - 1, tile.x + 2):
        for y in range(tile.y - 1, tile.y + 2):
          for e in Game.enemies:
            if e.tile.x == x && e.tile.y == y:
              if gotCrit: e.display_status_popup("Critical")
              hit_enemy(damage, e, boon)
              hit = true
      if not hit: 
        display_damage("NO TARGET")
        return false
    else:
      if gotCrit: enemy.display_status_popup("Critical")
      hit_enemy(damage, enemy, boon)
      
  boonUsed(boon)
  return true
  
#hits single enemy with a boon, precalculated damage, e must not be null
func hit_enemy(dmg, enemy, boon):
  
  if boon.get("onHitEnemy"): boon.onHitEnemy.call_func(boon, enemy)
  
  dmg *= damageMultiplier
  var fractionPart = dmg - floor(dmg)
  dmg = floor(dmg)
  if randf() < fractionPart: dmg += 1
    
  var isOffensive = boon.get("basePower") != null
  if isOffensive:
    var result = attack(enemy, dmg)
    if result == TakeDamageStatus.Died:
      if boon.get("onKill"): 
        boon.onKill.call_func(boon, enemy)
  
  if boon.get("statusEffect"): 
    var st = get_status_from_boon(boon)
    enemy.gain_status(st)

    
func gain_boon_by_name(name):
  var b = boonData.get_boon_by_name(name)
  gain_boon(b)
  
#behaviour: new boons always insert into the draw pile randomly
func gain_boon(boon):
  boons.append(boon)
  var toPile = true
  
  if boon.god != "Curse":
    for i in range(deckSize):
      if not deck[i]:
        deck[i] = boon
        toPile = false
        break
      
    if toPile: #attempt to replace regain favor
      for i in range(deckSize):
        if deck[i].name == "Regain Favor":
          deck[i] = boon
          toPile = false
          break 
      
  if toPile: 
    var i = randi() % (available.size()+1)
    available.insert(i, boon)
  
func is_hand_empty():
  for b in deck:
    if b: return false
  return true
  
func is_hand_done():
  for b in deck:
    if b and b.god != "Curse": return false
  return true
  
func is_hand_full():
  for b in deck:
    if not b: return false
  return true

func discard(i):
  if deck[i] != null:
    if deck[i].get("discardRemove"):
      boons.erase(deck[i])
    else:
      discard.append(deck[i])
    deck[i] = null

func boonUsed(boon):
  for i in heldItems:
    if i.get("onBoonUse"):
      i.onBoonUse.call_func()
      
  currentMana -= boon.mana
  
  if boon.get("instant"):
    free_turn = true
    
  #remove temp attributes
  if boon.get("temp"):
    for key in boon.temp:
      boon[key] = boon.temp[key]
    boon.temp = {}
  
  if boon.name == "Regain Favor":
    deck[usingBoon] = available.pop_back()
  else: 
    discard.append(boon)
    deck[usingBoon] = null

  if boon.get("quickDraw"): 
    if available.size() > 0:
      deck[usingBoon] = available.pop_back()
      
  if boon.get("afterUse"): boon.afterUse.call_func(boon)
  usingBoon = -1
  
  card.use_anim()
  
  
#only called when available pile is empty by regain favour
func shuffle_discard_pile():
  available += discard
  available.shuffle()
  discard = []
  for i in range(deckSize):  
    if not deck[i]:
      if available.size() > 0:
        deck[i] = available.pop_back()
  
#pressing R. return success or failure
func reloadBoons():
  if not is_hand_done(): return false
  if boons.size() < 4: return false
  usingBoon = -1
  
  #hand should only have curses in it. wipe the curses, later don't wipe reusable curses
  for i in range(deckSize):
    discard(i)
  
  for i in range(deckSize):
    if available.size() > 0:
      deck[i] = available.pop_back()
    else:
      deck[i] = boonData.get_boon_by_name("Regain Favor")   #put regain favour in hand
      return true
  return true
  
func heal_pool():
  var healAmount = min(HEAL_POOL_AMOUNT, maxHealth-currentHealth)
  currentHealth += healAmount
  display_healing(healAmount)
  
func turn():
  for i in heldItems:
    if i.get("onTurnEnd"):
      i.onTurnEnd.call_func()
      
  if currentMana < maxMana:
    if walked_this_turn and has_status("Scourge of Furies"): pass
    else:
      var regen = min(manaRegen, maxMana - currentMana)
      currentMana += regen
    
  combo = (combo + 1 ) % 3 if lastTurnAttack else 0
  lastTurnAttack = false
  walked_this_turn = false
  dash_this_turn = false
  free_turn = false
  .turn()
  
func die():
  for i in heldItems:
    if i.get("onDeath"):
      i.onDeath.call_func()
      heldItems.erase(i)
      return
  input = false
  yield(get_tree().create_timer(0.25), "timeout")
  
  Global.playerSprite = self.flip_h
  get_tree().change_scene("res://scenes/GameOver.tscn")
  
func game_over():
  Global.playerSprite = self.flip_h
  get_tree().change_scene("res://scenes/GameOver.tscn")
  
func display_info():
  infobox.text = "Zagreus\nPrince of the Underworld\n\n"
  display_status()
  
func display_healing(amount):
  damageNum.add_color_override("font_color", Color.green)
  damageNum.text = str(amount)
  damageNum.visible = true
  tweenNode.interpolate_property(damageNum, "rect_position", defaultPos, defaultPos-Vector2(0,5), popupTime, Tween.TRANS_LINEAR, Tween.EASE_OUT)
  tweenNode.start()
  yield(get_tree().create_timer(popupTime),"timeout")
  damageNum.rect_position = defaultPos
  damageNum.visible = false
  damageNum.add_color_override("font_color", Color.red)


onready var indicators = $"../PlayerIndicators"

func upgrade_visuals():
  #attack indicator stuff
  if indicators:
    for cell in indicators.get_used_cells_by_id(0):
      indicators.set_cell(cell.x, cell.y, -1)
      
    if usingBoon > -1 && deck[usingBoon].target == "area":
      for x in range(tile.x - 1, tile.x + 2):
        for y in range(tile.y - 1, tile.y + 2):
          if x != tile.x or y != tile.y: indicators.set_cell(x, y, 0)
  .upgrade_visuals()
  