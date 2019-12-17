extends "res://Game.gd"

var convos = {
  "Hypnos": [
    {"portrait": "portrait_hypnos.png", 
     "speaker": "Hypnos", 
     "text": "Wow, it says on my list here that you died from a vibe check." #"Oh, hey. Looks like you died again out there. Have you tried... not getting hit as much?"
    },
    {"portrait": "portrait_hypnos_smug.png", 
     "speaker": "Hypnos", 
     "text": "Your vibes must have been pretty rancid!"
    },
  ],
  
  "Achilles": [
    {"portrait": "portrait_achilles_sad.png", 
     "speaker": "Achilles", 
     "text": "Sorry if I seem depressed, lad."
    },
    {"portrait": "portrait_achilles_sad.png", 
     "speaker": "Achilles", 
     "text": "It's the depression."
    },
  ],
  
  "Hades": [
    {"portrait": "portrait_hades.png", 
     "speaker": "Hades", 
     "text": "Foolish boy. You will never get out of here."
    },
    {"portrait": "portrait_zag.png", 
     "speaker": "Zagreus", 
     "text": "We'll see about that, father."
    },
  ],
    
  "Cerberus": [
    {"portrait": "portrait_cerberus.png", 
     "speaker": "Cerberus", 
     "text": "*whine*"
    },
    {"portrait": "portrait_zag_smiling.png", 
     "speaker": "Zagreus", 
     "text": "Aww, who's a good boy?"
    },
    {"portrait": "portrait_cerberus.png", 
     "speaker": "Cerberus", 
     "text": "BORK"
    },
  ],
  
  "Dusa": [
    {"portrait": "portrait_dusa.png", 
     "speaker": "Dusa", 
     "text": "Oh! H-hi, Prince. Don't mind me, I'm just cleaning up the place!"
    },
    {"portrait": "portrait_zag_smiling.png", 
     "speaker": "Zagreus", 
     "text": "I'll see you around, Ms Dusa."
    },
  ],
  
  "Skelly": [
    {"portrait": "portrait_skelly.png", 
     "speaker": "Skelly", 
     "text": "Alright, boyo. Are you gonna slam dunk me into the floor or what? I haven't got all day!"
    },
    {"portrait": "portrait_zag.png", 
     "speaker": "Zagreus", 
     "text": "Not that I wouldn't be delighted to, but... weapons aren't allowed in the House."
    },
  ],
  
  "Nyx": [
    {"portrait": "portrait_placeholder.png", 
     "speaker": "Nyx", 
     "text": "May darkness guide you, child."
    }
  ],
  
  "Orpheus": 
  {
  "dialogs":
    {"1": [
        {"portrait": "portrait_zag_smiling.png", 
         "speaker": "Zagreus", 
         "text": "Say, mate, can I convince you to sing something?"
        },
        {"portrait": "portrait_orpheus.png", 
         "speaker": "Orpheus", 
         "text": "♫♫Certainly, my friend. Normally my heart is to heavy to sing, but since it is you who asks..."
        }
      ],
    "2": [
        {"portrait": "portrait_orpheus_singing.png", 
         "speaker": "Orpheus", 
         "text": "🎶Don't look back~ don't look back~"
        }
      ],
    },
  "chooseDialog": funcref(self, "pick_orpheus_dialog"),
  "onEnd": funcref(self, "play_music"),
  }
}

var npcmap
var passablemap
  
func init():
  mapSize = Vector2(60, 50)
  scene = "House"
  npcmap = $"NpcMap"
  passablemap = $"PassableTileMap"
  tilemap_to_map()
  upgrade_visuals()


const npcs_list = ["Achilles", "Hypnos", "Hades", "Cerberus", "Dusa", "Skelly", "Orpheus", "Nyx", "MusicNote"]

func pick_orpheus_dialog():
  if $music.playing: return "2"
  return "1"
  
func play_music():
  if not $music.playing:
    yield(get_tree().create_timer(0.5), "timeout")
    $music_sprite.visible = true
    $music.play()
  
func tilemap_to_map():
  tilemap = $HouseTileMap
  map.clear()
  for x in range(mapSize.x):
    map.append([])
    for y in range(mapSize.y):
      var tile = tilemap.get_cell(x, y)
      if tile == Tile.Player: 
        tilemap.set_cell(x, y, Tile.Empty)
        player.tile = Vector2(x, y)
        
      if tile == Tile.Floor or tile == Tile.Exit or tile == Tile.Door: map[x].append(tile) 
      else: map[x].append(Tile.Wall)     #all other tiles function as wall 
      
  for x in range(mapSize.x):
    for y in range(mapSize.y):
      var npc = npcmap.get_cell(x, y)
      if npc >= 0:
        var size = Vector2(1,1)
        if npc == 3: size = Vector2(2,2)    #cerberus, might use enum later
        elif npc == 2: size = Vector2(3,2)  #hades
        self.npcs.append({tile = Vector2(x, y), size = size, dialog = convos.get( npcs_list[npc] )})
        
        for i in range(x, x+size.x):
          for j in range(y, y+size.y):
            map[i][j] = Tile.Talker

func update_visibility_map():
  pass      

func upgrade_visuals():
  player.upgrade_visuals()
  player.input = true