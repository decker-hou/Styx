extends "res://MovingEntity.gd"

var spawnTables = {
  "tartarus": ["Dumbskull", "Numbskull", "Wretched Brute", "Wretched Hag"],
  "tutorial": ["Obstacle"],
  "skull": ["Dumbskull"],
  "skelly": ["Skelly"],
  "boss": ["Meg"],
  "bossSummons": ["Dumbskull", "Numbskull"]
}

var enemiesInfo = {
  "Dumbskull": { 
    name = "Dumbskull",
    sprite = "res://assets/skull.png",
    description = "The skeletal remains of one who was vicious and narrow-minded in life.",
    drops = [{"money": 10}],
    health = 12,
    damage = 2,
    abilities = [{name = "Bite", 
       desc = "Deal 2 damage.", 
       damage = 2,
    }],
    routine = funcref(self, "basic_melee_ai"),
  },
  "Numbskull": {
    name = "Numbskull",
    sprite = "res://assets/elite_skull.png",
    description = "The skeletal remains of one who sprouted philosophy incessantly in life.",
    drops = [{"money": 10}],
    health = 20,
    damage = 2,
    abilities = [
    {name = "Bite", 
       desc = "Deal 2 damage.", 
       damage = 2,
    },
    {name = "Numbing Bite", 
       desc = "Deal 3 damage and give the Numb curse.", 
       damage = 3, 
       giveCard = "Numb"
    }],
    routine = funcref(self, "numbskull_melee_ai"),
  },
  "Wretched Brute": {
    name = "Wretched Brute",
    description = "The tortured soul of one who was cruel and sadistic in life.",
    sprite = "res://assets/wretch.png",
    drops = [{"money": 10}],
    health = 30,
    damage = 5,  
    abilities = [{name = "Club", 
       desc = "Deal 5 damage.", 
       damage = 5, 
    }],
    routine = funcref(self, "basic_melee_ai"),
  },
  "Wretched Hag": {
    name = "Wretched Hag",
    description = "The tortured soul of one who practiced witchcraft in life.",
    sprite = "res://assets/witch.png",
    health = 25,
    drops = [{"money": 10}],
    abilities = [{name = "Witch Fire", 
       desc = "Ranged, apply Burned for 5 turns.", 
       damage = 0, charge = 5, 
       apply = {status = "Burned", turns = 5} 
    }],
    routine = funcref(self, "basic_ranged_ai"),
  },
  
  "Skelly": {
    name = "Skelly",
    description = "Skelly will happily let you use him for target practice.",
    drops = [],
    sprite = "res://assets/training_dummy.png",
    health = 9999999,
    routine = funcref(self, "dummy_ai"),
  },
  
  "Obstacle": {
    name = "Obstacle",
    description = "Crystallized darkness from the depths of Tartarus.",
    drops = [],
    abilities = [{name = "Chthonic Energy", desc = "Must deal damage equal to HP in a single turn to break."}],
    sprite = "res://assets/crystal.png",
    health = 9,
    routine = funcref(self, "damage_check_ai"),
  },
  
  "Meg": {
    name = "Megaera the Fury",
    sprite = "res://assets/meg.png",
    health = 250,
    drops = [{"keys": 1}],
    abilities = [{name = "Scourge of the Fury", 
         desc = "Prevents you from regenerating blood when you move.", 
         damage = 0,
         unavoidable = true,
         apply = {status = "Scourge of Furies", turns = 999} 
      },
      
      {name = "Whip Lash", 
         desc = "Deals 4 damage.", 
         damage = 4,
      },
      {name = "Whip Lunge", 
         desc = "Deals 9 damage and knocks target back 3 times in quick succession.", 
         damage = 3,
      },
      {name = "Tormenting Flame", 
         desc = "Deals 5 damage to targeted tiles.", 
         damage = 5,
      },
      {name = "Summon", 
         desc = "Summon shades as backup.",
      }],
    routine = funcref(self, "meg_ai"),
    onDeath = funcref(self, "meg_on_death"),
  },
}

var data
var state = {dead = false, seen = false, charge = 1, currentState = null, turn = 0}
onready var player = $"../Player"
onready var indicators = $"../IndicatorMap"

func _ready():
  selfTile = 2
  #var e = spawnList[randi() % spawnList.size()]
  #init(enemiesInfo[e])
  Game.enemies.append(self)

func init(x, y, table):
  var spawnList = spawnTables[table]
  var name = spawnList[randi() % spawnList.size()]
  data = enemiesInfo[name]
  if data.name == "Obstacle":
    data.health += Game.tutCounter
    Game.tutCounter += 3
  
  tile = Vector2(x, y)
  position = tile * 16

  self.texture = load(data.sprite)
  maxHealth = data.health
  currentHealth = maxHealth
  
func act():
  if state.dead: 
    indicators.clear() #temp for meg
    return
  if not state.seen:
    state.seen = true
  if has_status("Stunned"): return
  data.routine.call_func()
  
###############AI routines

func do_attack(attack, target):
  if attack.name == "Witch Fire": animate_projectile()
  if not attack.get("unavoidable") and randf() < target.dodgeChance:
    target.display_status_popup("dodged!")
    return
    
  if has_status("Tipsy"):
    if randf() < Status["Tipsy"].missChance:
      display_status_popup("Miss!")
      return
  if attack.damage: attack(target, attack.damage)
  if attack.get("apply"): target.gain_status(attack.apply)
  if attack.get("giveCard"):
    target.display_status_popup("cursed!") 
    target.gain_boon_by_name(attack.giveCard)
  
const Projectile = preload("res://Projectile.tscn")

func animate_projectile():
  var proj = Projectile.instance()
  var tween = proj.get_child(0)
  Game.add_child(proj)
  proj.position = self.position + Vector2(8,8)
  var targetPos = player.tile * 16 + Vector2(8,8) #not using position bc it's not updated yet
  
  tween.interpolate_property(proj, "position", proj.position, targetPos, 0.2, Tween.TRANS_LINEAR, Tween.EASE_OUT)
  tween.start()
  yield(tween, "tween_completed")
  proj.queue_free()
  

#ai that does nothing
func dummy_ai():
  return
  
#wall AI that regens all health
func damage_check_ai():
  currentHealth = maxHealth
  self.get_child(0).rect_size.x = 16
  
#ai that chases the player and attacks
func basic_melee_ai():
  var dist = get_distance_to_player()
  if dist == 1: #attack player
    bump_anim(player.tile.x, player.tile.y)
    do_attack(data.abilities[0], player)
  else:
    move_to_player()
    
#applies curse every third attack
func numbskull_melee_ai():
  var dist = get_distance_to_player()
  if dist == 1: #attack player
    bump_anim(player.tile.x, player.tile.y)
    if state.charge == 3:    #curse applying bite
      do_attack(data.abilities[1], player)
      state.charge = 1
    else:
      do_attack(data.abilities[0], player)
      state.charge += 1
  else:
    move_to_player()
      
func basic_ranged_ai():
  var dist = get_distance_to_player()
  if dist <= 1:  #too close, try to move away from player
    var dx = tile.x - player.tile.x 
    var dy = tile.y - player.tile.y 
    var result = try_move(dx, dy)     #try to move directly away from player first, if not successful, then try to move laterally
#    if not result:
#      result = try_move(dy, dx)
#      if not result: try_move(-1 * dy, -1 * dx)
  elif dist <= 3: #in the right zone, attack player
    var attack = data.abilities[0]
    if state.charge == attack.charge:
      bump_anim(player.tile.x, player.tile.y)
      do_attack(attack, player)
      state.charge = 1
    else:
      state.charge += 1
  else:
    move_to_player()
    
func meg_prepare_tile_attack():
  for x in range(Game.mapSize.x):
    for y in range(Game.mapSize.y):
      var tile = Game.map[x][y]
      if abs(player.tile.x - x) == abs(player.tile.y - y):  #X-shape
        if tile == Game.Tile.Player or tile == Game.Tile.Floor or tile == Game.Tile.Enemy:
          indicators.set_cell(x, y, 1)
          
func meg_prepare_tile_chase():
  indicators.set_cell(player.tile.x, player.tile.y, 1)
 
var meg_sprites = []

func animate_attack():
  var done = false
  for s in meg_sprites:
    if s.frame >= 1: 
      done = true
    s.frame += 1
  if done:
    for s in meg_sprites: s.queue_free()
    meg_sprites = []
         
func meg_does_tile_attack():
  for tile in indicators.get_used_cells_by_id(1):
    var s = Global.new_sprite(load("res://assets/meg_floor_attack.png"), 1, tile*16, Game, false)
    s.hframes = 2
    #s._on_timeout = funcref(self, "animate_attack")
    meg_sprites.append(s)
    $"../AnimationTimer".connect("timeout", self ,"animate_attack") 
    
  var x = player.tile.x
  var y = player.tile.y
  if indicators.get_cell(x, y) == 1:
    do_attack(data.abilities[3], player)
  indicators.clear()
  
func meg_triple_attack():
  var dx = player.tile.x - tile.x
  var dy = player.tile.y - tile.y
  player.input = false

  do_attack(data.abilities[2], player)
  player.knockback(dx, dy, 1)
  try_move_to(tile.x + dx, tile.y + dy)
  player.missTurn = true
    #Game.upgrade_visuals()
    #yield(get_tree().create_timer(0.2), "timeout")

func meg_prepare_summon():
  for i in range(3):
    var tile = Game.Tile.Empty
    var x
    var y
    while tile != Game.Tile.Floor:
      x = randi() % int(Game.mapSize.x-2) + 1
      y = randi() % int(Game.mapSize.y-2) + 1
      tile = map[x][y]
    indicators.set_cell(x, y, 2)
    
func meg_summon():
  for tile in indicators.get_used_cells_by_id(2):
    Game.instantiate_enemy(tile.x, tile.y, "bossSummons")
    indicators.set_cell(tile.x, tile.y, -1)
  
func meg_ai():
  meg_summon()
  if state.get("c") == null: state["c"] = 1
  if not player.has_status("Scourge of Furies"):
    do_attack(data.abilities[0], player)
  
  match state.currentState:
    "attack":
      indicators.clear()
      var dist = get_distance_to_player()
      if dist <= 1: #attack player
        bump_anim(player.tile.x, player.tile.y)
        do_attack(data.abilities[1], player)
      else:
        move_to_player() 
      
      if (currentHealth/float(maxHealth)) < 0.5: state.currentState = "triple"
      if state.turn >= 20:
        state.turn = 0
        state.currentState = "summon"
    "triple":
      indicators.clear()
      var dist = get_distance_to_player()
      if dist <= 1: #attack player
        if state.c == 4:
          state.c = 1
        else:
          bump_anim(player.tile.x, player.tile.y)
          meg_triple_attack()
          state.c += 1
      else:
        move_to_player()
        
      if state.turn >= 20:
        state.turn = 0
        state.currentState = "summon"
        
    "tile":
      if state.turn % 2 == 1: meg_does_tile_attack()
      else: meg_prepare_tile_attack()
      
      if state.turn >= 16:
        state.turn = 0
        state.currentState = "triple" if (currentHealth/float(maxHealth)) < 0.5 else "attack"
      
    "tile_chase":
      meg_does_tile_attack()
      meg_prepare_tile_chase()
      
      if state.turn >= 8:
        state.turn = 0
        state.currentState = "tile"
        
    "summon":
      meg_prepare_summon()
      state.currentState = "tile_chase" if (currentHealth/float(maxHealth)) < 0.5 else "tile"
    _:
      state.currentState = "attack"
  
#not straight line distance, tile distance. 1 means right next to the player
func get_distance_to_player():
  var dx = abs(tile.x - player.tile.x)
  var dy = abs(tile.y - player.tile.y)
  return dx + dy
  
func move_to_player():
  var currentPoint = Game.calculate_id(tile.x, tile.y)
  var playerPoint = Game.calculate_id(player.tile.x, player.tile.y)
  var path = Game.astar_graph.get_point_path(currentPoint, playerPoint)
  var tries = 1
  var disabledPoints = []
  while tries < 10:
    if (not path) or path.size() == 1: break
    if try_move_to(path[1].x, path[1].y): break
    var pointId = Game.calculate_id(path[1].x, path[1].y)
    Game.astar_graph.set_point_disabled(pointId)
    disabledPoints.append(pointId)
    path = Game.astar_graph.get_point_path(currentPoint, playerPoint)
  for p in disabledPoints:
    Game.astar_graph.set_point_disabled(p, false)

func take_damage(dmg, attacker):
  var result = .take_damage(dmg, attacker)
  var rectWidth = 0 if currentHealth <= 0 else max(1, (16 * currentHealth / maxHealth))
  self.get_child(0).rect_size.x = rectWidth
  return result
  
func turn():
  .turn()
  state.turn += 1
  
func meg_on_death():
  for e in Game.enemies:
    e.die()
  for s in player.statusEffects:
    if s.status == "Scourge of Furies":
      player.statusEffects.erase(s)
      return

func die():
  if state.dead: return
  state.dead = true
  for i in player.heldItems:
    if i.get("onEnemyDeath"):
      i.onEnemyDeath.call_func(self)
      
  for loot in data.drops:
    for key in loot:
      player[key] += loot[key]
      
  Game.change_tile(tile.x, tile.y, Game.Tile.Floor)
  yield(get_tree().create_timer(0.2), "timeout")
  
  if data.get("onDeath"): data.onDeath.call_func()
  Game.enemies.erase(self)
  queue_free()
  
func upgrade_visibility():
  self.visible = true if data.get("alwaysVisible") else Game.visibilitymap.get_cell(tile.x, tile.y) == -1
  if not visible:
    Game.tilemap.set_cell(tile.x, tile.y, Tile.Floor)  #prevents enemy out of view from missing the floor dot texture giving it away
  
func display_info():
  infobox.text = data.name + "\n\n" + "HP: " + str(currentHealth) + "/" + str(maxHealth) + "\n\n"
  
  if data.get("description"): infobox.text += data.description + "\n\n"
  
  if data.get("abilities"):
    infobox.text += "Abilities: \n" 
    for attack in data.abilities:
      infobox.text += str(attack.name) + ": " + str(attack.desc) + "\n\n"
  display_status()
  
var bump = null

#instead of performing immediately, defer to when upgrade visuals is called
func bump_anim(dx, dy):
  bump = Vector2(dx, dy)
  
func upgrade_visuals():
  .upgrade_visuals()
  if bump:
    .bump_anim(bump.x, bump.y)
    bump = null