extends AudioStreamPlayer

var sample_library = {
  "defaultMove": preload("res://assets/audio/footstep2.wav"),
  "defaultAttack": preload("res://assets/audio/sword1.wav"),
  "wait": preload("res://assets/audio/beepbeep.wav"),
  "defaultDie": preload("res://assets/audio/footstep.wav"),
}

func play_sample(var sound):
  if sample_library.has(sound):
    stream = sample_library[sound]
    play()