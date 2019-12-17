extends TileMap

onready var Game = $"../"

var convos = {
  "s1": [
    {
     "speaker": "Narrator", 
     "text": "Willful Zagreus makes his escape from his father’s palace, but a wall of crystallized chthonic energy from beneath the earth impedes him."
    },
    {"portrait": "portrait_zag.png", 
     "speaker": "Zagreus", 
     "text": "I can break that with my sword pretty easily."
    },
    {
     "speaker": "None", 
     "text": "(Use WASD/arrows to attack)"
    },
  ],
  
  "s2": [
    {
     "speaker": "Narrator", 
     "text": "The prince grows in strength from his connection to the realm of the dead."
    },
    {"portrait": "portrait_zag.png", 
     "speaker": "Zagreus", 
     "text": "I feel my powers returning to me..."
    },
    {"portrait": "portrait_zag.png", 
     "speaker": "Zagreus", 
     "text": "But every time I use a card, it’ll cost me some blood, and I can only use each card once."
    },
    {
     "speaker": "None", 
     "text": "(1-5 keys to select cards)"
    },
  ],
  
  "s3": [
    {
     "speaker": "Narrator", 
     "text": "As swift as the wind, flame-footed Zagreus dashes across the pools overflowing from the river Styx."
    }
  ],
  
  "s4": [
    {
     "speaker": "Narrator", 
     "text": "The prince’s power is soon depleted, as he faces yet another insurmountable obstacle."
    },
    {"portrait": "portrait_zag.png", 
     "speaker": "Zagreus", 
     "text": "Sounding a little presumptuous there, mate."
    },
    {"portrait": "portrait_zag_smiling.png", 
     "speaker": "Zagreus", 
     "text": "Once I use up all my cards, I’ve got a trick to bring them back."
    },
    {
     "speaker": "Narrator", 
     "text": "Ah, of course. Though perhaps the spirited prince may yet learn the virtues of a little patience from time to time, should he need to recover."
    },
    {
     "speaker": "None", 
     "text": "(T to wait a turn)"
    },
    {"portrait": "portrait_zag.png", 
     "speaker": "Zagreus", 
     "text": "I got it, old man."
    },
  ],
  
  "s5": [
    {
     "speaker": "Narrator", 
     "text": "With the assistance of his Olympian brethren, Zagreus presses on to the depths of Tartarus."
    },
    {
     "speaker": "None", 
     "text": "(V to view deck)"
    },
  ],
}



func assignNpcs():
  for n in get_children():
    if convos.get(n.name):
      var npc = {"dialog": convos[n.name]}
      npc.tile = n.position/16
      npc.size = Vector2(1,1)
      Game.npcs.append(npc)