extends Node2D

var rooms_data = [
#starting room
{noSpawns = true, noUrns = false,},
#ending room
{noSpawns = true, noUrns = false},
#shop,
{noSpawns = true, 
 noUrns = true,
   npc= { 
    name= "Charon", 
    size=Vector2(1,1), 
    sprite = null, #map sprite, temp placeholder
    dialog = [
        {"portrait": "res://assets/portrait_charon.png", 
         "speaker": "Charon", 
         "text": "Hrrrrrrrrrrrrgggggh."
        },
        {"portrait": "res://assets/portrait_zag_smiling.png", 
         "speaker": "Zagreus", 
         "text": "Good to see you too, mate. Let's have a look at your wares."
        },],
  }
},
#combat rooms
{noSpawns = false, noUrns = false, transforms = true},
{noSpawns = false, noUrns = false, transforms = true},
{noSpawns = false, noUrns = false, transforms = true},
{noSpawns = false, noUrns = false, transforms = true},

#meg room
{noSpawns = false, noUrns = true, transforms = false,
  enterDialog =[
        {"portrait": "res://assets/portrait_meg.png", 
         "speaker": "Megaera", 
         "text": "Last chance to turn back, Zagreus."
        },
        {"portrait": "res://assets/portrait_zag.png", 
         "speaker": "Zagreus", 
         "text": "You know I can't, Meg."
        },
        {"portrait": "res://assets/portrait_meg_annoyed.png", 
         "speaker": "Megaera", 
         "text": "Hmph, stubborn as ever. Then come and die."
        },
        ]
  },
#sisy room
{noSpawns = true, noUrns = true,
   npc= { 
    name= "Sisyphus", 
    size=Vector2(1,1), 
    sprite = null, #map sprite, temp placeholder
    dialog = [
        {"portrait": "res://assets/portrait_sisyphus.png", 
         "speaker": "Sisyphus", 
         "text": "Hey there, Prince Z. Just pushing good ol' Bouldy, as usual."
        },
        {"portrait": "res://assets/portrait_zag_smiling.png", 
         "speaker": "Zagreus", 
         "text": "Let me help you out, mate."
        },
        {"portrait": "res://assets/portrait_sisyphus.png", 
         "speaker": "Sisyphus", 
         "text": "Oh, would you? I'd be very grateful. Don't work yourself too hard though!"
        },
        ],
  }
},
]

#all prefab rooms have north and west bounds of 0
func find_room_bounds(tilemap):
  var max_x = 0
  var max_y = 0
  var used_cells = tilemap.get_used_cells()
  for pos in used_cells:
    if pos.x > max_x:
      max_x = int(pos.x)
    elif pos.y > max_y:
      max_y = int(pos.y)
  return Vector2(int(max_x+1), int(max_y+1))
  
func get_room_data(i):
  var map = get_child(i)
  return {bounds = find_room_bounds(map), tilemap = map, data = rooms_data[i]}
  
#returns a list of prefab rooms to put in the level
func get_prefab_rooms(level = 1):
  var rooms = []
  for i in range(3):
    rooms.append(get_room_data(i))
    
  #if level == 1:
  #  rooms.append(get_room_data(8)) #sisy always appears on level 1 for now
  #problem: currently bouldy sprite isn't cleared
    
  var indices = range(3, 7)
  indices.shuffle()
  for j in range(3):
    rooms.append(get_room_data(indices[j]))
  return rooms
  
func get_boss_room():
  return get_room_data(7)