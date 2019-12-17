extends Node2D

const TILE_SIZE = 16
const MAP_SIZES = [
  {'min': 3, 'max': 3},
  {'min': 3, 'max': 4},
  {'min': 3, 'max': 4},
]
const ROOM_SPAWN_ATTEMPTS = 5

var level = 1

var mapSize
var mapRoomsX = 3  #we could randomize this for each level
var mapRoomsY = 3
const ROOM_SIZE = 6
var RNG = RandomNumberGenerator.new()

var map = []
var enemies = []
var rooms = []
var items = []
var npcs = []
var interactables = []
var astar_graph
var tutCounter = 0 #mega hacky 

enum Tile {Empty = -1, Player, Wall, Enemy, Item, Door, Floor, Exit, Walltop, Talker, HeldItem, Dummy, Pool, Consumable, Urn, Healing, Obstacle, LockedDoor, EmptyPool}
const Enemy = preload("res://entities/Enemy.tscn") 
const Item = preload("res://items/BoonItem.tscn")
const HeldItem = preload("res://items/HeldItem.tscn")

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
  
func _ready():
  randomize()
  var PrefabRooms = preload("res://prefabs/PrefabRoom.tscn")
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
  if Global.tutorialStage or Global.debug:  #special maps
    init_special_maps()
  else:  #general dungeon gen
    tilemap.visible = true
    player.input = false
    fade_out_level_screen()
    player.input = true
    $TutorialMap.clear()
    $TutorialMap.visible = false
    if level == 4:
      init_boss_room()
    else:
      var ranges = MAP_SIZES[level-1]
      mapRoomsX = RNG.randi_range(ranges['min'], ranges['max'])
      mapRoomsY = RNG.randi_range(ranges['min'], ranges['max'])
      mapSize = Vector2(ROOM_SIZE*mapRoomsX+1, ROOM_SIZE*mapRoomsY+1)
      build_level()
      spawn_stuff()
      upgrade_player_visuals()
      call_deferred("update_visibility_map")
    
  $UI/Minimap.init()
    
func place_tile(x, y, tile): 
  map[x][y] = (tile)
  if tile == Tile.Enemy or tile == Tile.Player or tile == Tile.Item or tile == Tile.HeldItem or tile == Tile.Talker:
    tilemap.set_cell(x, y, Tile.Floor)  #this isn't empty because enemies moving into tiles :/
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
  if tile == Tile.Enemy or tile == Tile.Player or tile == Tile.Item or tile == Tile.HeldItem or tile == Tile.Dummy or tile == Tile.Consumable or tile == Tile.Talker: 
    tmap.set_cell(x, y, -1)
    
  map[x][y] = tile
  if tile == Tile.Dummy or tile == Tile.Obstacle: map[x][y] = Tile.Enemy
  elif tile == Tile.Consumable: map[x][y] = Tile.HeldItem
  
  #instantiate entities
  if tile == Tile.Player:
    player.tile = Vector2(x, y)
  elif tile == Tile.Enemy:
    var table = "skull" if scene == "Tutorial" else "boss" if level == 4 else "tartarus"
    instantiate_enemy(x, y, table)
  elif tile == Tile.Obstacle:
    instantiate_enemy(x, y, "tutorial")
  elif tile == Tile.Dummy:
    instantiate_enemy(x, y, "skelly")
  elif tile == Tile.Item:
    instantiate_boon(x, y)
  elif tile == Tile.HeldItem:
    instantiate_held_item(x, y, "keepsakes")
  elif tile == Tile.Consumable:
    instantiate_held_item(x, y, "consumables")
  
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
  
func init_boss_room():
  var room = prefabRooms.get_boss_room()
  tilemap.clear()
  for x in range(room.bounds.x):
    for y in range(room.bounds.y):
      tilemap.set_cell(x, y, room.tilemap.get_cell(x,y) )
  tilemap_to_map()
  make_pathfinding_graph()
  rooms.append(room)
  
  player.input = false
  call_deferred("update_visibility_map")
  yield(get_tree().create_timer(1.5), "timeout")
  $UI/Dialog.open(rooms[0].data.enterDialog)
  player.input = true
  
func init_special_maps():
  if Global.debug:
    scene = "Debug"
    $TutorialMap.clear()
    $TutorialMap.visible = false
  else:
    tilemap = $TutorialMap
    scene = "Tutorial"
    $TileMap.queue_free()  #idk it was causing problems with tutorial map visibility
    $TutorialMap.assignNpcs()
    player.boons = []
    player.deck = [null, null, null, null, null]
    tilemap.visible = true
    
  Global.tutorialStage = false
  Global.debug = false
    
  tilemap_to_map()
  make_pathfinding_graph()
  for x in range(mapSize.x):
    map.append([])
    for y in range(mapSize.y):
      visibilitymap.set_cell(x, y, 0)
  call_deferred("update_visibility_map")
    
    
#########generating dungeons
#0 = no room
#1 = regular room where stuff can spawn
#2 = special room where you don't spawn stuff ie shop
var roomsMap = []

func build_level():
  map.clear()
  tilemap.clear()
  visibilitymap.clear()
  roomsMap.clear()
  rooms.clear()
  
  #fill map with walls
  for x in range(mapSize.x):
    map.append([])
    for y in range(mapSize.y):
      map[x].append(Tile.Wall)
      tilemap.set_cell(x, y, Tile.Wall)
      visibilitymap.set_cell(x, y, 0)
  
  #fill roomsMap
  for i in range(mapRoomsX):
    roomsMap.append([])
    for j in range(mapRoomsY):
      roomsMap[i].append(0)
        
  var a = false
  while a == false:
    rooms.clear()
    #fill map with walls
    for x in range(mapSize.x):
      for y in range(mapSize.y):
        map[x][y] = Tile.Wall
        tilemap.set_cell(x, y, Tile.Wall)
    #fill roomsMap
    for i in range(mapRoomsX):
      for j in range(mapRoomsY):
        roomsMap[i][j] = 0

    a = make_main_path()
  
  place_extra_rooms()
  
  make_pathfinding_graph()
  tilemap.update_bitmask_region()
  
#this just adds an empty square room  
func add_room(x, y):
  roomsMap[x][y] = 1
  for i in range(1, ROOM_SIZE):
    for j in range(1, ROOM_SIZE):
      place_tile(x*ROOM_SIZE+i, y*ROOM_SIZE+j, Tile.Floor)  
  rooms.append({'x0': x*ROOM_SIZE,'y0': y*ROOM_SIZE, 'w': ROOM_SIZE, 'h': ROOM_SIZE})
  
#for spawning the main path
#slightly weighted towards south and east
func add_door_to_room(x, y, dir):
  var half = ceil(ROOM_SIZE/2)
  match dir:
    Vector2(0,-1): #n
      place_tile(x*ROOM_SIZE+half, y*ROOM_SIZE, Tile.Door) 
    Vector2(-1,0): #w
      place_tile(x*ROOM_SIZE, y*ROOM_SIZE+half, Tile.Door) 
    Vector2(0,1): #s
      place_tile(x*ROOM_SIZE+half, y*ROOM_SIZE+ROOM_SIZE, Tile.Door) 
    Vector2(1,0): #e
      place_tile(x*ROOM_SIZE+ROOM_SIZE, y*ROOM_SIZE+half, Tile.Door) 
 
func get_next_room(x, y):
  var dirs = []
  if x > 0 and roomsMap[x-1][y] == 0: dirs.append(Vector2(-1,0))  
  if y > 0 and roomsMap[x][y-1] == 0: dirs.append(Vector2(0,-1))
  if x < mapRoomsX-1 and roomsMap[x+1][y] == 0: 
    dirs.append(Vector2(1,0)) 
    dirs.append(Vector2(1,0)) 
  if y < mapRoomsY-1 and roomsMap[x][y+1] == 0: 
    dirs.append(Vector2(0,1))
    dirs.append(Vector2(0,1))
  
  if dirs.size() == 0: return null
  return dirs[randi() % dirs.size()]
  
func make_main_path():
  var x = 0
  var y = 0
  while (x != mapRoomsX-1 or y != mapRoomsY-1):
    add_room(x, y)
    var dir = get_next_room(x, y)
    if dir == null: 
      return false
    add_door_to_room(x, y, dir)
    x += dir.x
    y += dir.y
    
  add_room(x, y)
  prefabRooms.place_prefab_room(self, x*ROOM_SIZE+1, y*ROOM_SIZE+1, "Exit")  #temp hack so the walls don't overwrite the door
  return true
      
func copy_tilemap_to_map(tmap, x0, y0, width, height, data):
  for x in range(width):
    for y in range(height):
      var tile = tmap.get_cell(x, y)
      if tile != Tile.Empty:
        
        copy_tile(tmap, x, y, x0+x, y0+y)
        tilemap.set_cell(x0+x, y0+y, tile)
        if tile == Tile.Talker:
          var npc = data.npc
          npc["tile"] = Vector2(x0+x, y0+y)
          npcs.append(data.npc)
  
func place_prefab_room(x0, y0, data):
  copy_tilemap_to_map(data.tilemap, x0, y0, data.bounds.x, data.bounds.y, data.data)
  if data.tilemap.script: 
    data.tilemap.init(x0, y0, self)
    
#for now this just places shop
func place_extra_rooms():
  for i in range(ROOM_SPAWN_ATTEMPTS):
    var spots = []
    for x in range(mapRoomsX):
      for y in range(mapRoomsY):
        if roomsMap[x][y] == 0:
          if x > 0 and roomsMap[x-1][y] == 1: 
            spots.append( [Vector2(x, y), Vector2(-1, 0)] ) 
          if y > 0 and roomsMap[x][y-1] == 1: 
            spots.append( [Vector2(x, y), Vector2(0, -1)] ) 
          if x < mapRoomsX-1 and roomsMap[x+1][y] == 1: 
            spots.append( [Vector2(x, y), Vector2(1, 0)] ) 
          if y < mapRoomsY-1 and roomsMap[x][y+1] == 1: 
            spots.append( [Vector2(x, y), Vector2(0, 1)] ) 
       
    if spots.size() == 0: return
    #in the future multiple extra rooms can be placed here
    var pos = spots[randi() % spots.size()]
    var roomPos = pos[0]
    var door = pos[1]
    add_room(roomPos.x, roomPos.y)

    if i == 1: 
      prefabRooms.place_prefab_room(self, roomPos.x*ROOM_SIZE, roomPos.y*ROOM_SIZE, "Shop")
      roomsMap[roomPos.x][roomPos.y] = 2
    else:
      var roomName = prefabRooms.get_random_regular_room()
      prefabRooms.place_prefab_room(self, roomPos.x*ROOM_SIZE, roomPos.y*ROOM_SIZE, roomName)
      
    add_door_to_room(roomPos.x, roomPos.y, door)
  

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
  instance.init(x, y, item)
  return instance

func get_adjacent_tiles(x, y):
  return [map[x-1][y], map[x+1][y], map[x][y-1], map[x][y+1]]
  
func get_room_center(room):
  return Vector2(room.x0 + int(room.w/2), room.y0 + int(room.h/2))
  
#returns an empty floor tile, hopefully the room isn't full
func get_random_spot_in_room(xr, yr):
  var tile = Tile.Empty
  var x
  var y
  while tile != Tile.Floor:
    var randw = randi() % int(ROOM_SIZE-1)
    var randh = randi() % int(ROOM_SIZE-1)
    x = xr*ROOM_SIZE + randw + 1
    y = yr*ROOM_SIZE + randh + 1
    tile = map[x][y]
  return Vector2(x, y)
  
#returns a spot against a wall, not against the door
func get_random_edge_in_room(xr, yr):
  while true:
    var randw = randi() % int(ROOM_SIZE-1)
    var randh = randi() % int(ROOM_SIZE-1)
    var x = xr*ROOM_SIZE + randw
    var y = yr*ROOM_SIZE + randh
    
    if map[x][y] == Tile.Floor:
      var neighbours = get_adjacent_tiles(x, y)
      if neighbours.has(Tile.Wall) and not neighbours.has(Tile.Door):
        return Vector2(x, y)
        
func get_center_of_room(x, y):
  var half = ceil(ROOM_SIZE / 2)
  return Vector2(x*ROOM_SIZE+half, y*ROOM_SIZE+half)
  
func spawn_stuff():
  player.tile = Vector2(3,3)
  #place_tile(mapSize.x-4, mapSize.y-4, Tile.Exit)   #temporary
  
  for x in range(mapRoomsX):
    for y in range(mapRoomsY):
      if roomsMap[x][y] != 1: continue  #no room here
        
      var urns = randi() % 4
      for j in urns:
        var c = get_random_edge_in_room(x, y)
        place_tile(c.x, c.y, Tile.Urn)
        
      if (x == 0 and y == 0) or (x == mapRoomsX-1 and y == mapRoomsY-1): continue

      #spawning items
      var c = get_center_of_room(x,y)
      var rand = randf()
      if rand < 0.40:      #40% boon
        place_tile(c.x, c.y, Tile.Item)
        instantiate_boon(c.x, c.y)
      elif rand < 0.60:  #20%
        place_tile(c.x, c.y, Tile.HeldItem)
        var i = instantiate_held_item(c.x, c.y, "keepsakes") 
      else:  #40%
        place_tile(c.x, c.y, Tile.HeldItem)
        var i = instantiate_held_item(c.x, c.y, "consumables")
      
      if not Global.noEnemies:
        var num_enemies = (randi() % 4)
        for j in num_enemies:
          var pos = get_random_spot_in_room(x, y)
          place_tile(pos.x, pos.y, Tile.Enemy)
          instantiate_enemy(pos.x, pos.y, "tartarus")

####this is called whenever player handles an input
######timePass is whether the enemies get to act
func turn(timePass):
  upgrade_player_visuals()

  if timePass:
    var ems = []
    for e in enemies:
      if visibilitymap.get_cell(e.tile.x, e.tile.y) != 0:
        if e.data.name != "Obstacle" and e.data.name != "Skelly": ems.append(e)  
    
    if (ems.size() > 0):
      player.input = false
      yield(get_tree().create_timer(0.4), "timeout")
          
    for e in enemies:
      if visibilitymap.get_cell(e.tile.x, e.tile.y) != 0:
        if e.data.name != "Obstacle" and e.data.name != "Skelly":
          e.pointer.visible = true
          yield(get_tree().create_timer(0.5), "timeout")
          e.pointer.visible = false
        e.act()
        upgrade_enemy_visuals(e)
       
    #end of turn actions like taking status damage
    player.input = false
    player.turn()
    for e in enemies:
      e.turn()
    player.input = true

  if $UI/UIBar: $UI/UIBar.update()

func tile_center(pos):
  return pos + Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
  
func update_visibility_map():
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
  update_enemies_visibility()
   
func update_enemies_visibility():
  for e in enemies:
    e.upgrade_visibility()
           
func upgrade_player_visuals():
  call_deferred("update_visibility_map")
  player.upgrade_visuals()
  if $UI/UIBar: $UI/UIBar.update()
  for e in enemies:
    e.display_accumulated_damage()
  
func upgrade_enemy_visuals(e):
  e.upgrade_visuals()
  e.display_accumulated_damage()
  player.display_accumulated_damage()
  $UI/UIBar.update()
  
func _input(event):
  if !event.is_pressed():
    return
  #call_deferred("update_visibility_map")
  #upgrade_visibility_map()
  if event.is_action_pressed("debug"):
      Global.debug = true
      get_tree().change_scene("res://Game.tscn")
  elif event.is_action_pressed("skip"):
    if scene == "Tutorial":
      Global.tutorialStage = false
      get_tree().change_scene("res://Game.tscn")