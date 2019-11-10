extends "res://Game.gd"

var MAP_WIDTH = 60
var MAP_HEIGHT = 50

var convos = {
  "Hypnos": [
#    {"choiceText": "Hypnos choice test", 
#     "choices": ["Talk", "Give ambrosia"],
#    },
    {"portrait": "res://assets/portrait_hypnos.png", 
     "speaker": "Hypnos", 
     "text": "Wow, it says on my list here that you died from a vibe check." #"Oh, hey. Looks like you died again out there. Have you tried... not getting hit as much?"
    },
    {"portrait": "res://assets/portrait_hypnos_smug.png", 
     "speaker": "Hypnos", 
     "text": "Your vibes must have been pretty rancid!"
    },
  ],
  
  "Achilles": [
    {"portrait": "res://assets/portrait_achilles.png", 
     "speaker": "Achilles", 
     "text": "Keep going, lad. I know you can make it out."
    },
  ],
  
  "Hades": [
    {"portrait": "res://assets/portrait_hades.png", 
     "speaker": "Hades", 
     "text": "Foolish boy. You will never get out of here."
    },
    {"portrait": "res://assets/portrait_zag.png", 
     "speaker": "Zagreus", 
     "text": "We'll see about that, father."
    },
  ],
    
  "Cerberus": [
    {"portrait": "res://assets/portrait_cerberus.png", 
     "speaker": "Cerberus", 
     "text": "*whine*"
    },
    {"portrait": "res://assets/portrait_zag_smiling.png", 
     "speaker": "Zagreus", 
     "text": "Aww, who's a good boy?"
    },
    {"portrait": "res://assets/portrait_cerberus.png", 
     "speaker": "Cerberus", 
     "text": "BORK"
    },
  ],
  
  "Dusa": [
    {"portrait": "res://assets/portrait_dusa.png", 
     "speaker": "Dusa", 
     "text": "Oh! H-hi, Prince. Don't mind me, I'm just cleaning up the place!"
    },
    {"portrait": "res://assets/portrait_zag_smiling.png", 
     "speaker": "Zagreus", 
     "text": "I'll see you around, Ms Dusa."
    },
  ],
  
  "Skelly": [
    {"portrait": "res://assets/portrait_skelly.png", 
     "speaker": "Skelly", 
     "text": "Alright, boyo. Are you gonna slam dunk me into the floor or what? I haven't got all day!"
    },
    {"portrait": "res://assets/portrait_zag.png", 
     "speaker": "Zagreus", 
     "text": "Not that I wouldn't be delighted to, but... weapons aren't allowed in the House."
    },
  ],
  
  "Nyx": [
    {"portrait": "res://assets/portrait_placeholder.png", 
     "speaker": "Nyx", 
     "text": "Darkness guide you, child."
    }
  ],
  
  "Orpheus": [
    {"portrait": "res://assets/portrait_placeholder.png", 
     "speaker": "Orpheus", 
     "text": "♫♫Hum dum... I'm never gonna dance again... Guilty feet have got no rhythm~"
    },
  ],
}

var npcmap
var passablemap
  
func init():
  scene = "House"
  npcmap = $"NpcMap"
  passablemap = $"PassableTileMap"
  tilemap_to_map()
  upgrade_visuals()

###enum Tile {Empty = -1, Player, Wall, Enemy, Item, Door, Floor, Exit, Walltop, Talker}
const npcs_list = ["Achilles", "Hypnos", "Hades", "Cerberus", "Dusa", "Skelly", "Orpheus", "Nyx"]

func tilemap_to_map():
  tilemap = $HouseTileMap
  map.clear()
  for x in range(MAP_WIDTH):
    map.append([])
    for y in range(MAP_HEIGHT):
      var tile = tilemap.get_cell(x, y)
      if tile == Tile.Player: 
        tilemap.set_cell(x, y, Tile.Empty)
        player.tile = Vector2(x, y)
        
      if tile == Tile.Floor or tile == Tile.Exit or tile == Tile.Door: map[x].append(tile) 
      else: map[x].append(Tile.Wall)     #all other tiles function as wall 
      
  for x in range(MAP_WIDTH):
    for y in range(MAP_HEIGHT):
      var npc = npcmap.get_cell(x, y)
      if npc >= 0:
        var size = Vector2(1,1)
        if npc == 3: size = Vector2(2,2)    #cerberus, might use enum later
        elif npc == 2: size = Vector2(3,2)  #hades
        self.npcs.append({tile = Vector2(x, y), size = size, dialog = convos.get( npcs_list[npc] )})
        
        for i in range(x, x+size.x):
          for j in range(y, y+size.y):
            map[i][j] = Tile.Talker
      

func upgrade_visuals():
  player.upgrade_visuals()
  player.input = true