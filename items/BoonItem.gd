extends Sprite

var tile
var god
var pickedBoons = []

const gods = ["Athena", "Artemis", "Aphrodite", "Zeus", "Dionysus", "Ares", "Poseidon"]
var convos = {
  "Artemis": [
    {"portrait": "portrait_zag.png", 
     "speaker": "Zagreus", 
     "text": "In the name of Hades. Olympus, I accept this message!"
    },
    {"portrait": "portrait_artemis.png", 
     "speaker": "Artemis", 
     "text": "Good hunting, Zagreus. I've got something that might help you."
    },
  ],
  
  "Athena": [
    {"portrait": "portrait_zag.png", 
     "speaker": "Zagreus", 
     "text": "In the name of Hades. Olympus, I accept this message!"
    },
    {"portrait": "portrait_athena.png", 
     "speaker": "Athena", 
     "text": "Hail, cousin. May this blessing find you in times of need."
    },
  ],
  
  "Aphrodite": [
    {"portrait": "portrait_zag.png", 
     "speaker": "Zagreus", 
     "text": "In the name of Hades. Olympus, I accept this message!"
    },
    {"portrait": "portrait_aphrodite.png", 
     "speaker": "Aphrodite", 
     "text": "Hello there, little godling. Let's get you out of that dismal place."
    },
  ],
  
  "Ares": [
    {"portrait": "portrait_zag.png", 
     "speaker": "Zagreus", 
     "text": "In the name of Hades. Olympus, I accept this message!"
    },
    {"portrait": "portrait_ares.png", 
     "speaker": "Ares", 
     "text": "Allow me to aid you in sowing bloodshed among the dead, my kin."
    },
  ],
  
  "Dionysus": [
    {"portrait": "portrait_zag.png", 
     "speaker": "Zagreus", 
     "text": "In the name of Hades. Olympus, I accept this message!"
    },
    {"portrait": "portrait_dionysus.png", 
     "speaker": "Dionysus", 
     "text": "Hey man, you gotta get out of there already! We got a party waiting for you on Olympus!"
    },
  ],
  
  "Hermes": [
    {"portrait": "portrait_zag.png", 
     "speaker": "Zagreus", 
     "text": "In the name of Hades. Olympus, I accept this message!"
    },
    {"portrait": "portrait_placeholder.png", 
     "speaker": "Hermes", 
     "text": "..."
    },
  ],
  
  "Poseidon": [
    {"portrait": "portrait_zag.png", 
     "speaker": "Zagreus", 
     "text": "In the name of Hades. Olympus, I accept this message!"
    },
    {"portrait": "portrait_poseidon.png", 
     "speaker": "Poseidon", 
     "text": "Ahoy there, little Hades! The power of the sea is on your side!"
    },
  ],
  
  "Zeus": [
    {"portrait": "portrait_zag.png", 
     "speaker": "Zagreus", 
     "text": "In the name of Hades. Olympus, I accept this message!"
    },
    {"portrait": "portrait_zeus.png", 
     "speaker": "Zeus", 
     "text": "Greetings, nephew! With my power, you'll make it out of there in no time."
    },
  ]
}

onready var Game = get_parent()
onready var player = get_parent().player
onready var infobox = $"../UI/Right/Info"
onready var boonsData = $"../Boons"
onready var boonMenu = $"../UI/BoonSelect"
onready var dialogBox = $"../UI/Dialog"

func _ready():
  god = gods[randi() % gods.size()]
  self.texture = load("res://assets/boon_" + god.to_lower() + ".png")
  
  var pos = self.position / 16
  tile = pos
  Game.items.append(self)
  
  $"../AnimationTimer".connect("timeout", self ,"animate") 
  
func animate():
  self.offset.y = -1 if (self.offset.y == 0) else 0
  
func display_info():
  infobox.text = "Boon of " + god + "\n\nA divine gift from Olympus"

func take_item():
  if Game.god_convos.has(god): 
    Game.god_convos.erase(god)
    dialogBox.connect("dialog_closed", self, "_on_dialog_close")
    dialogBox.open(convos.get(god))
  else:
    self.consume()
  
func _on_dialog_close():
  self.consume() 

func consume():
  boonMenu.visible = true
  boonMenu.item = self
  var boonList = boonsData.boons[god]      #this is just the plain data of the god
  
  var index = range(boonList.size())
  index.shuffle()
  pickedBoons = []
  while pickedBoons.size() < 3 and index.size() > 0:
    var i = index.pop_front()
    var boon = boonList[i]
    if not boonsData.givenBoons.has(boon.name): 
      pickedBoons.append(boon)
  
  boonMenu.display_boons(god, pickedBoons)
  
func removeSelf():
  Game.place_tile(tile.x, tile.y, Game.Tile.Floor)
  Game.items.erase(self)
  queue_free()
  Game.upgrade_player_visuals()
