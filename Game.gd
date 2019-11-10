extends Node2D

const TILE_SIZE = 16
const MAP_SIZES = [1, 35, 40, 45]
const MAP_SIZE = 35
const ROOM_DENSITY = 900 #attempts to place rooms
const ROOM_MIN = 5
const ROOM_MAX = 10
const doorChance = 0  #chance of redundant doors

var level = 1

var mapSize
var map = []
var roomMap = []
var roomMapCopy = []
var roomI = 0     #index of the rooms
var enemies = []
var rooms = []
var items = []
var npcs = []
var interactables = []
var astar_graph

enum Tile {Empty = -1, Player, Wall, Enemy, Item, Door, Floor, Exit, Walltop, Talker, HeldItem, Dummy, Pool, Consumable, Urn, ShopItem, Obstacle, LockedDoor, Interactable}
const Enemy = preload("res://Enemy.tscn") 
const Item = preload("res://Item.tscn")
const HeldItem = preload("res://HeldItem.tscn")

const PrefabRooms = preload("res://PrefabRoom.tscn")
var prefabRooms

onready var player = $Player    
onready var tilemap = $TileMap
onready var visibilitymap = $VisibilityMap

var scene = "Tartarus"
const god_convos = ["Athena", "Artemis", "Aphrodite", "Zeus", "Dionysus", "Ares", "Poseidon"]

var Status = {
  "Boiling Blood": {
    desc = "Take 50% more damage.", 
    shortText = "boiling blood!", 
    particles = preload("res://particles/BloodParticles.tscn"),
    textColor = Color.red,
    type = "debuff"},
  "Lightning Rod": {
    desc = "Strikes a random enemy every turn. Effect lasts until you move.", 
    shortText = "lightning!", 
    type = "buff",
    particles = preload("res://particles/LightningParticles.tscn"),
    noDeplete = true,
    textColor = Color.yellow},
  "Reflective Armor": {
    desc = "All damage taken to armor is dealt to the attacker.", 
    shortText = "reflective!", 
    type = "buff",
    textColor = Color.goldenrod},
  "Storm Shroud": {
    desc = "Foes who hit you at melee range are knocked back one tile.", 
    particles = preload("res://particles/WaterParticles.tscn"),
    shortText = "shroud!", 
    type = "buff",
    textColor = Color.skyblue},
  "Torrent Step": {
    desc = "Leave temporary water tiles behind you.", 
    particles = preload("res://particles/WaterParticles.tscn"),
    shortText = "torrent!", 
    type = "buff",
    textColor = Color.skyblue},
  "Wild Fury": {
    desc = "When you deal critical damage, get a free turn.", 
    shortText = "wild fury!", 
    type = "buff",
    textColor = Color.lawngreen},
  "Weak": {
    desc = "Deal 50% less damage.", 
    shortText = "weak!",
    type = "debuff", 
    particles = preload("res://particles/WeakParticles.tscn"),
    textColor = Color.hotpink},
  "Poisoned Wine": {
    desc = "Take damage equal to turns of poison remaining.", 
    additive = true,
    shortText = "poisoned!", 
    particles = preload("res://particles/PoisonParticles.tscn"),
    type = "debuff", 
    textColor = Color.mediumorchid},
  "Burned": {
    desc = "Take 1 damage every turn.", 
    shortText = "burned!",
    additive = true,
    particles = preload("res://particles/FireParticles.tscn"),
    type = "debuff", 
    textColor = Color.orange},
  "Tipsy": {
    desc = "Moves randomly when not attacking. Attacks have 40% chance to miss.",
    missChance = 0.4,
    shortText = "tipsy!", 
    particles = preload("res://particles/TipsyParticles.tscn"),
    type = "debuff", 
    textColor = Color.mediumorchid},
  "Immobilized": {
    desc = "Cannot move, can still attack.", 
    shortText = "immobile!", 
    type = "debuff", 
    textColor = Color.lightsalmon},
  "Stunned": {
    desc = "Cannot act.", 
    shortText = "stun!", 
    type = "debuff", 
    textColor = Color.yellow},
  "Scourge of Furies": {
    desc = "Cannot regenerate blood when moving.", 
    shortText = "scourged!", 
    noDeplete = true,
    type = "debuff", 
    textColor = Color.cornflower},
  "Entangled": {
    desc = "Cannot move, effect lasts until damage is taken.", 
    shortText = "entangled!", 
    noDeplete = true,
    type = "debuff", 
    textColor = Color.forestgreen},
    
  #pop up text not effects
  "Critical": {
    desc = "Uh oh, you shouldn't have this as a status effect.", 
    shortText = "crit!", 
    textColor = Color.lawngreen},
  "Death Defy": {
    desc = "Uh oh, you shouldn't have this as a status effect.", 
    shortText = "death defy!", 
    textColor = Color.lightgray},
}

var tutCounter = 0 #mega hacky 
  
func _ready():
  randomize()
  prefabRooms = PrefabRooms.instance()
  init()
  
func clear_entities():
  for e in enemies: 
    remove_child(e)
    e.queue_free()
  for i in items: 
    remove_child(i)
    i.queue_free()
  enemies = []
  rooms = []
  items = []
  npcs = []
  interactables = []
  
func fade_out_level_screen():
  var screen = $UI/FadeInScreen
  var tween = $UI/FadeInScreen/Tween
  var label = $UI/FadeInScreen/Label
  label.text = "TARTARUS - LEVEL " + str(level)
  screen.visible = true
  tween.interpolate_property(screen, "modulate:a", 1, 0, 1.5, Tween.TRANS_QUINT, Tween.EASE_IN)
  tween.start()
  
#called when generating a new floor
func init():  
  clear_entities()
  $Keepsakes.shuffle_spawntables()
  if Global.tutorialStage or Global.debug:
    if Global.debug:
      scene = "Debug"
      $TutorialMap.clear()
    else:
      tilemap = $TutorialMap
      scene = "Tutorial"
      $TileMap.queue_free()  #idk it was causing problems with tutorial map visibility
      player.boons = []
      player.deck = [null, null, null, null, null]
      tilemap.visible = true
      $Instructions.visible = true
      
    Global.tutorialStage = false
    Global.debug = false
      
    tilemap_to_map()
    make_pathfinding_graph()

  else:
    player.input = false
    fade_out_level_screen()
    player.input = true
      
    $TutorialMap.clear()
    if level == 4:
      var room = prefabRooms.get_boss_room()
      tilemap.clear()
      for x in range(room.bounds.x):
        for y in range(room.bounds.y):
          tilemap.set_cell(x, y, room.tilemap.get_cell(x,y) )
      tilemap_to_map()
      make_pathfinding_graph()
      rooms.append(room)
      
      player.input = false
      upgrade_visibility_map()
      yield(get_tree().create_timer(1.5), "timeout")
      $UI/Dialog.open(rooms[0].data.enterDialog)
      player.input = true
      
    else:
      mapSize = Vector2(MAP_SIZES[level], MAP_SIZES[level])
      build_level()
      spawn_stuff()
    
  $UI/Minimap.init()
  call_deferred("upgrade_visuals")
    
func place_tile(x, y, tile): 
  map[x][y] = (tile)
  if tile == Tile.Enemy or tile == Tile.Player or tile == Tile.Item or tile == Tile.HeldItem: 
    tilemap.set_cell(x, y, Tile.Floor)  #don't put enemy sprites on tilemap
  else:
    tilemap.set_cell(x, y, tile) 
    
  tilemap.update_bitmask_area ( Vector2(x, y) )
    
#don't call this during initial generation, this updates the AStar map
func change_tile(x, y, tile):
  place_tile(x, y, tile)
  if not astar_graph: return
  if is_walkable_tile(tile):
    connect_pathfinding_node(x, y)
  else:
    disconnect_pathfinding_node(x, y)
    
func copy_tile(tmap, xo, yo, x, y):
  var tile = tmap.get_cell(xo, yo)
  if tile == Tile.Enemy or tile == Tile.Player or tile == Tile.Item or tile == Tile.HeldItem or tile == Tile.Dummy or tile == Tile.Consumable or tile == Tile.ShopItem: 
    tmap.set_cell(x, y, -1)
    
  map[x][y] = tile
  if tile == Tile.Dummy or tile == Tile.Obstacle: map[x][y] = Tile.Enemy
  elif tile == Tile.Consumable or tile == Tile.ShopItem: map[x][y] = Tile.HeldItem
  
  #instantiate entities
  if tile == Tile.Player:
    player.tile = Vector2(x, y)
  elif tile == Tile.Enemy:
    var table = "skull" if scene == "Tutorial" else "boss" if level == 4 else "tartarus"
    instantiate_enemy(x, y, table)
  elif tile == Tile.Obstacle:
    instantiate_enemy(x, y, "tutorial")
  elif tile == Tile.Dummy:
    var e = instantiate_enemy(x, y, "skelly")
  elif tile == Tile.Item:
    instantiate_boon(x, y)
  elif tile == Tile.HeldItem:
    instantiate_held_item(x, y, "keepsakes")
  elif tile == Tile.Consumable:
    instantiate_held_item(x, y, "consumables")
  elif tile == Tile.ShopItem:
    instantiate_held_item(x, y, "shop")
  
func tilemap_to_map():  
  map.clear()
  mapSize = find_room_bounds(tilemap)
  for x in range(mapSize.x):
    map.append([])
    for y in range(mapSize.y):
      map[x].append(0)
      copy_tile(tilemap, x, y, x, y)
     
  if scene == "Tutorial": 
    for i in range(3):
      var itemName = "TutBoon" + str(i+1)
      var item = items[i]
      item.init(item.tile.x, item.tile.y, itemName)
      
func find_room_bounds(tmap):
  var max_x = 0
  var max_y = 0
  var used_cells = tmap.get_used_cells()
  for pos in used_cells:
    if pos.x > max_x:
      max_x = int(pos.x)
    elif pos.y > max_y:
      max_y = int(pos.y)
  return Vector2(int(max_x+1), int(max_y+1))
  
#########generating dungeons

func build_level():
  map.clear()
  tilemap.clear()
  roomMap.clear()
  visibilitymap.clear()
  roomI = 0
  #fill map with walls
  for x in range(mapSize.x):
    map.append([])
    roomMap.append([])
    for y in range(mapSize.y):
      map[x].append(Tile.Wall)
      tilemap.set_cell(x, y, Tile.Wall)
      visibilitymap.set_cell(x, y, 0)
      roomMap[x].append(-1)
    
  #add prefab rooms here. prefab rooms can be irregularly shaped
  add_prefab_rooms()
  
  #add regular random square rooms
  for i in range(ROOM_DENSITY):
    try_add_room()
    
  #adding corridors
  place_maze()
  
  roomMapCopy = roomMap.duplicate(true)
  place_doors()
  remove_dead_ends()
  
  make_pathfinding_graph()
  tilemap.update_bitmask_region()
  
#find a place to add the prefab rooms
func add_prefab_rooms():
  var prefabs = prefabRooms.get_prefab_rooms()
  
  for r in prefabs:
    try_add_prefab_room(r)
  
func copy_tilemap_to_map(tmap, x0, y0, width, height, data):
  for x in range(width):
    for y in range(height):
      var tile = tmap.get_cell(x, y)
      if tile != Tile.Empty:
        
        copy_tile(tmap, x, y, x0+x, y0+y)
        var setTile = Tile.Empty if tile == Tile.ShopItem else tile  #VERY temp solution
        tilemap.set_cell(x0+x, y0+y, setTile)
        if tile == Tile.Talker:
          var npc = data.npc
          npc["tile"] = Vector2(x0+x, y0+y)
          npcs.append(data.npc)
        if tile == Tile.Floor: 
          roomMap[x0+x][y0+y] = roomI
  
func place_prefab_room(x0, y0, data):
  copy_tilemap_to_map(data.tilemap, x0, y0, data.bounds.x, data.bounds.y, data.data)
  if data.tilemap.script: 
    data.tilemap.init(x0, y0, self)
  rooms.append({x0= x0,y0= y0, w= data.bounds.x, h= data.bounds.y, data=data.data})
  roomI += 1
  
func try_add_prefab_room(data, attempts = 10):
  var w = data.bounds.x
  var h = data.bounds.y
    
  for i in range(attempts):
    var x0 = floor( rand_range(1,  (mapSize.x - data.bounds.x) ) )
    var y0 = floor( rand_range(1,  (mapSize.y - data.bounds.y) ) )
    assert (  x0 + w < mapSize.x and y0 + h < mapSize.y)
    var overlaps = false
    for r in rooms:
      if x0-1 < r.x0 + r.w && x0-1 + w+2 > r.x0 && y0-1 < r.y0 + r.h && y0-1 + h+2 > r.y0:
        overlaps = true
        break
    if not overlaps: 
      place_prefab_room(x0, y0, data)
      return
  print("failed to place room")
       
#every tile in each room labelled by room #
func place_room(x0, y0, w, h):
  rooms.append({'x0': x0,'y0': y0, 'w': w, 'h': h})
  for x in range(w):
    for y in range(h):
      var xc = x0 + x
      var yc = y0 + y
      place_tile(xc, yc, Tile.Floor)
      roomMap[xc][yc] = roomI
  roomI += 1
  
#attempt to place down a random rectangular room
func try_add_room():
  var w = randi() % (ROOM_MAX-ROOM_MIN) + ROOM_MIN
  var h = randi() % (ROOM_MAX-ROOM_MIN) + ROOM_MIN
  var x0 = randi() % (int(mapSize.x-1)) + 1
  var y0 = randi() % (int(mapSize.y-1)) + 1
  
  if x0 + w >= mapSize.x or y0 + h >= mapSize.y:
    return
    
  #check overlapping rooms
  for r in rooms:
    if x0-1 < r.x0 + r.w && x0-1 + w+2 > r.x0 && y0-1 < r.y0 + r.h && y0-1 + h+2 > r.y0:
      return
      
  place_room(x0, y0, w, h)
  
func check_surroundings(x, y):
  for i in range(x-1, x+2):
    for j in range(y-1, y+2):
      if map[i][j] != Tile.Wall:
        return false
  return true
  
func place_maze():
  #iterate through every tile looking for a 3x3 solid area
  var done = false
  while not done:
    done = true
    for x in range(1, mapSize.x-1):
      for y in range(1, mapSize.y-1):
        if check_surroundings(x, y):
          done = false
          start_maze(x, y) #run the algo here
          roomI += 1
  
func find_frontiers(x, y):
  var frontiers = []
  var dirs = [
    [Vector2(x-1, y), x-2, x,   y-1, y+2 ],  #left 
    [Vector2(x+1, y), x+1, x+3, y-1, y+2 ], #right
    [Vector2(x, y-1), x-1, x+2, y-2, y], #up
    [Vector2(x, y+1), x-1, x+2, y+1, y+3] #down
    ]
  for f in dirs:
    var valid = true
    for i in range(f[1], f[2]):
      for j in range(f[3], f[4]):
        if i < 0 or j < 0 or i >= mapSize.x or j >= mapSize.y: 
          valid = false
          break
        if map[i][j] != Tile.Wall:
          valid = false
    if valid: frontiers.append(f)
  frontiers.shuffle()
  return frontiers
  
func start_maze(xi, yi):
  place_tile(xi, yi, Tile.Floor)
  roomMap[xi][yi] = roomI
  var frontiers = find_frontiers(xi, yi)

  while frontiers.size() > 0:
    #var f = frontiers.pop_back() 
    var f = frontiers[randi() % frontiers.size()]
    frontiers.erase(f)
    
    var valid = true
    for i in range(f[1], f[2]):
      for j in range(f[3], f[4]):
        if map[i][j] != Tile.Wall:
          valid = false
          break
        
    if valid:
      place_tile(f[0].x, f[0].y, Tile.Floor)
      roomMap[f[0].x][f[0].y] = roomI
      frontiers = frontiers + find_frontiers(f[0].x, f[0].y)
  
func find_potential_doors():
  var potential_doors = []
  for x in range(1, mapSize.x-1):
    for y in range(1, mapSize.y-1):
      if map[x][y] == Tile.Wall:
        var valid = false
        var r1
        var r2
        if map[x-1][y] == Tile.Floor && map[x+1][y] == Tile.Floor:
          r1 = roomMap[x-1][y]
          r2 = roomMap[x+1][y]
          if r1 != r2: 
            valid = true
          
        elif map[x][y-1] == Tile.Floor && map[x][y+1] == Tile.Floor:
          r1 = roomMap[x][y-1]
          r2 = roomMap[x][y+1]
          if r1 != r2: 
            valid = true
          
        if valid:
          potential_doors.append({'x': x, 'y': y, 'r1': r1, 'r2': r2})
  potential_doors.shuffle()
  return potential_doors
     
var room_dict = {}

func place_doors():
  var doors = find_potential_doors()
  
  for i in range(roomI):
    room_dict[i] = i

  while doors.size() > 0:
    var door = doors.pop_front()
    var r1 = door.r1
    var r2 = door.r2
    
    place_tile(door.x, door.y, Tile.Door)
    
    var p = room_dict[r1]
    if p != r1: room_dict[room_dict[r1]] = room_dict[r2]

    room_dict[r1] = room_dict[r2]     #d[4] = 5         what if d[5] == 6     then d[4] = 6?
    for k in range(roomI):
      if room_dict[k] == p: room_dict[k] = room_dict[r1]      #d[2] = 4  -> d[2] = 6


    for i in range(doors.size()-1, -1, -1):
      var d = doors[i]
      #if room_dict[d.r1] == room_dict[d.r2]:    #uncomment this line for spanning tree dungeon
      if (d.r1 == r1 and d.r2 == r2) or (d.r2 == r1 and d.r1 == r2):   #uncomment this line for lots of doors
        var next_to_door = false
        for k in range(d.x-1, d.x+2):
          for l in range(d.y-1, d.y+2):
            if map[k][l] == Tile.Door: next_to_door = true

        if randf() < doorChance and not next_to_door: 
          place_tile(d.x, d.y, Tile.Door)
        doors.remove(i)
  
func is_dead_end(x, y):
  var c = 0
  if map[x][y] != Tile.Floor and map[x][y] != Tile.Door: return false
  if map[x-1][y] == Tile.Wall: c += 1
  if map[x+1][y] == Tile.Wall: c += 1
  if map[x][y-1] == Tile.Wall: c += 1
  if map[x][y+1] == Tile.Wall: c += 1
  return c >= 3
  
func remove_dead_ends():
  var done = false
  while not done:
    done = true
    for x in range(1, mapSize.x-1):
      for y in range(1, mapSize.y-1):
        if is_dead_end(x, y):
          place_tile(x, y, Tile.Wall)
          done = false
      
func fancify_sprites():
  pass

#####pathfinding graph building functions 

func is_walkable_tile(tile):
  return tile == Tile.Floor or tile == Tile.Enemy or tile == Tile.Player
  
func calculate_id(x, y):
  return x * mapSize.x + y
  
func connect_pathfinding_node(x, y):
  var nodeid = calculate_id(x, y)
  if not astar_graph.has_point(nodeid):
    astar_graph.add_point(nodeid, Vector3(x, y, 0))
    
  var neighbours = []
  
  if x > 0 and is_walkable_tile( map[x-1][y] ):
    neighbours.append( calculate_id(x-1, y) )
  if y > 0 and is_walkable_tile( map[x][y-1] ):
    neighbours.append( calculate_id(x, y-1) )   
  if x < mapSize.x-1 and is_walkable_tile( map[x+1][y] ):
    neighbours.append( calculate_id(x+1, y) ) 
  if y < mapSize.y-1 and is_walkable_tile( map[x][y+1] ):
    neighbours.append( calculate_id(x, y+1) )
  
  for p in neighbours:
    astar_graph.connect_points(p, nodeid)  #this is bidirectional
    
func disconnect_pathfinding_node(x, y):
  var nodeid = calculate_id(x, y)
  if not astar_graph.has_point(nodeid): return
    
  var neighbours = []
  if x > 0 and is_walkable_tile( map[x-1][y] ):
    neighbours.append( calculate_id(x-1, y) )
  if y > 0 and is_walkable_tile( map[x][y-1] ):
    neighbours.append( calculate_id(x, y-1) )   
  if x < mapSize.x-1 and is_walkable_tile( map[x+1][y] ):
    neighbours.append( calculate_id(x+1, y) ) 
  if y < mapSize.y-1 and is_walkable_tile( map[x][y+1] ):
    neighbours.append( calculate_id(x, y+1) )
  
  for p in neighbours:
    astar_graph.disconnect_points(p, nodeid)  #this is bidirectional

func make_pathfinding_graph():
  astar_graph = AStar.new()
  
  #adds a point for every walkable tile
  for x in range(mapSize.x):
    for y in range(mapSize.y):
      if is_walkable_tile(map[x][y]):
        var newPoint = calculate_id(x, y)
        astar_graph.add_point(newPoint, Vector3(x, y, 0))
      
  #connects points with neighbours
  for x in range(mapSize.x):
    for y in range(mapSize.y): 
      if is_walkable_tile(map[x][y]):
        connect_pathfinding_node(x, y)
   
  
########placing stuff
  
#doesn't place it on the map, just instatiate
func instantiate_enemy(x, y, table):
  var e = Enemy.instance()
  add_child(e)
  e.init(x, y, table)
  return e
  
func instantiate_boon(x, y):
  var tile = Vector2(x, y)
  var instance = Item.instance()
  instance.tile = tile
  instance.position = tile * TILE_SIZE
  add_child(instance)
  return instance
  
func instantiate_held_item(x, y, list):
  var instance = HeldItem.instance()
  add_child(instance)
  var item = $Keepsakes.pick_from_spawnTable(list)
  instance.init(x, y, item, list=="shop")
  return instance

func get_adjacent_tiles(x, y):
  return [map[x-1][y], map[x+1][y], map[x][y-1], map[x][y+1]]
  
func get_room_center(room):
  return Vector2(room.x0 + int(room.w/2), room.y0 + int(room.h/2))
  
#returns an empty floor tile, not next to the walls. hopefully the room isn't full
func get_random_spot_in_room(room):
  var tile = Tile.Empty
  var x
  var y
  while tile != Tile.Floor:
    var randw = randi() % int(room.w-2) + 1
    var randh = randi() % int(room.h-2) + 1
    x = room.x0 + randw
    y = room.y0 + randh
    tile = map[x][y]
  return Vector2(x, y)
  
#returns a spot against a wall, not against the door
func get_random_edge_in_room(room):
  var pos
  while true:
    var randw = randi() % int(room.w)
    var randh = randi() % int(room.h)
    var x = room.x0 + randw
    var y = room.y0 + randh
    
    if map[x][y] == Tile.Floor:
      var neighbours = get_adjacent_tiles(x, y)
      if neighbours.has(Tile.Wall) and not neighbours.has(Tile.Door):
        return Vector2(x, y)
  
func spawn_stuff():
  player.tile = get_room_center(rooms[0])
  
  for r in rooms:
    if r.get("data") and r.data.noUrns: pass
    else:
      var urns = randi() % 6
      for j in urns:
        var c = get_random_edge_in_room(r)
        place_tile(c.x, c.y, Tile.Urn)
        
    if r.get("data") and r.data.noSpawns:
      pass
    else:
      if not Global.noEnemies:
        var num_enemies = (randi() % 3) + 1
        for j in num_enemies:
          var c = get_random_spot_in_room(r)
          place_tile(c.x, c.y, Tile.Enemy)
          instantiate_enemy(c.x, c.y, "tartarus")
    
      var c = get_random_spot_in_room(r)
      var rand = randf()
      if rand < 0.40:      #boon
        place_tile(c.x, c.y, Tile.Item)
        instantiate_boon(c.x, c.y)
      elif rand < 0.60:  #20%
        place_tile(c.x, c.y, Tile.HeldItem)
        var i = instantiate_held_item(c.x, c.y, "keepsakes") 
      else:  #40%
        place_tile(c.x, c.y, Tile.HeldItem)
        var i = instantiate_held_item(c.x, c.y, "consumables")
  
######called whenever Player handles an action
#####turnPass is a parameter for meg's chain attack
func turn(timePass, turnPass=true):
  player.upgrade_visuals()
  call_deferred("update_visibility_map")
    
  if timePass:
    player.input = false
    yield(get_tree().create_timer(0.08), "timeout")
    player.input = true
      
    if not turnPass: #hacky meg stuff
      enemies[0].act()
        
    if turnPass: 
      for e in enemies:
        if visibilitymap.get_cell(e.tile.x, e.tile.y) != 0:
          e.act()
         
      player.turn()
      for e in enemies:
        if visibilitymap.get_cell(e.tile.x, e.tile.y) != 0:
          e.turn()
          
    call_deferred("upgrade_visuals")
  else: #you pressed like 1-5 keys
    for e in enemies:
      if visibilitymap.get_cell(e.tile.x, e.tile.y) != 0:
        e.display_accumulated_damage()
    player.upgrade_visuals()
  if $UI/UIBar: $UI/UIBar.update()

func tile_center(pos):
  return pos + Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
  
func upgrade_visibility_map():
  var playerCenter = tile_center(player.tile * 16)
  var spaceState = get_world_2d().direct_space_state
  for x in range(mapSize.x):
    for y in range(mapSize.y):
      var coords = Vector2(x, y) * TILE_SIZE
      var xdir = 1 if x < player.tile.x else -1
      var ydir = 1 if y < player.tile.y else -1
      var testPoint = tile_center(coords) + Vector2(xdir, ydir) * TILE_SIZE / 2
      var occlusion = spaceState.intersect_ray(playerCenter, testPoint)
      if !occlusion or (occlusion.position - testPoint).length() < 1: #visible
        visibilitymap.set_cell(x, y, -1)
      else:
        if visibilitymap.get_cell(x, y) == -1:
          visibilitymap.set_cell(x, y, 1)      #half visible
          
#called at the end of turn after all state changes happened
func upgrade_visuals():
  player.input = false
    
  upgrade_visibility_map()
  player.upgrade_visuals()
  $UI/UIBar.update()
    
  var wait = false
  for e in enemies:
    e.upgrade_visibility()
    if e.visible: wait = true
    e.display_accumulated_damage()
    
  #if wait: yield(get_tree().create_timer(0.15), "timeout")
  
  for e in enemies:
    e.upgrade_visuals()  
  
  player.display_accumulated_damage()
  $UI/UIBar.update()
  
  #if wait: yield(get_tree().create_timer(0.1), "timeout")
  
  if player.missTurn: 
    player.missTurn = false
    turn(true, false)
    
  player.input = true
  
func _input(event):
  if !event.is_pressed():
    return
  if event.is_action_pressed("debug"):
      Global.debug = true
      get_tree().change_scene("res://Game.tscn")
  elif event.is_action_pressed("skip"):
    if scene == "Tutorial":
      Global.tutorialStage = false
      get_tree().change_scene("res://Game.tscn")