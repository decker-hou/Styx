extends Node2D

var rooms_data = {

"Shop": {noSpawns = true, 
 noUrns = true,
   npc= { 
    name= "Charon", 
    size=Vector2(1,1), 
    sprite = preload("res://assets/nyx.png"), #map sprite, temp placeholder
    dialog = [
        {"portrait": "portrait_charon.png", 
         "speaker": "Charon", 
         "text": "Hrrrrrrrrrrrrgggggh."
        },
        {"portrait": "portrait_zag_smiling.png", 
         "speaker": "Zagreus", 
         "text": "Good to see you too, mate. Let's have a look at your wares."
        },],
  }
},

"Meg": {noSpawns = false, noUrns = true, transforms = false,
  enterDialog =[
        {"portrait": "portrait_meg.png", 
         "speaker": "Megaera", 
         "text": "Last chance to turn back, Zagreus."
        },
        {"portrait": "portrait_zag.png", 
         "speaker": "Zagreus", 
         "text": "You know I can't, Meg."
        },
        {"portrait": "portrait_meg_annoyed.png", 
         "speaker": "Megaera", 
         "text": "Hmph, stubborn as ever. Then come and die."
        },
        ]
  },

"Sisyphus": {noSpawns = true, noUrns = true,
   npc= { 
    name= "Sisyphus", 
    size=Vector2(1,1), 
    sprite = null, #map sprite, temp placeholder
    dialog = [
        {"portrait": "portrait_sisyphus.png", 
         "speaker": "Sisyphus", 
         "text": "Hey there, Prince Z. Just pushing good ol' Bouldy, as usual."
        },
        {"portrait": "portrait_zag_smiling.png", 
         "speaker": "Zagreus", 
         "text": "Let me help you out, mate."
        },
        {"portrait": "portrait_sisyphus.png", 
         "speaker": "Sisyphus", 
         "text": "Oh, would you? I'd be very grateful. Don't work yourself too hard though!"
        },
        ],
  }
},

}

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
  
#semi deprecated, try not to use this and keep functions within this script or room scripts
func get_room_data(name):
  var map = get_node(name)
  return {bounds = find_room_bounds(map), tilemap = map, data = rooms_data[name]}
  
func get_boss_room():
  return get_room_data("Meg")
  
func get_random_regular_room():
  var list = ["Room1","Room2","Room3","Room4"]
  return list[randi() % list.size()]
  
func place_prefab_room(Game, x0, y0, room):
  var map = get_node(room)
  var data = rooms_data[room] if rooms_data.has(room) else 0
  Game.copy_tilemap_to_map(map, x0, y0, 7, 7, data)
  if map.has_method("onPlacement"): map.onPlacement(Game, x0, y0)