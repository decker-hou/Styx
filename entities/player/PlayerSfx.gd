#can only play one sound at a time

extends AudioStreamPlayer

var sample_library = {
  "bump": preload("res://assets/audio/soft_bump.wav"),
  "footstep": preload("res://assets/audio/footstep2.wav"),
  "openDoor": preload("res://assets/audio/door.wav"),
  "urnSmash": preload("res://assets/audio/urn_breaking.wav"),
  "wait": preload("res://assets/audio/wait.wav"),
  "sword": preload("res://assets/audio/sword1.wav"),
  "coin": preload("res://assets/audio/coin.wav"),
  "heal": preload("res://assets/audio/heal.wav"),
  "pool": preload("res://assets/audio/healpool.wav"),
  "pom": preload("res://assets/audio/pom.wav"),
  "hammer": preload("res://assets/audio/metal_clang.wav"),
  "defaultPickup": preload("res://assets/audio/pom.wav"),
  "defaultAttack": preload("res://assets/audio/attack.wav"),
  
  #boon_sounds
  "regain_favor": preload("res://assets/audio/boons/blood.wav"),
  "dash": preload("res://assets/audio/boons/whoosh.wav"),
}

func play_sample(var sound):
  if sample_library.has(sound):
    stream = sample_library[sound]
    play()