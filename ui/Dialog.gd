extends ColorRect
signal dialog_closed

onready var box = $Dialog
onready var portrait = $Dialog/Portrait
onready var textArea = $Dialog/Text
onready var timer = $Timer
onready var audio = $DialogSfx

var index = 0
var count = 0
var dialog = []
var onEnd = false

var samples = {
  "low": preload("res://assets/audio/talk_low.wav"),
  "default": preload("res://assets/audio/talk.wav"),
  "medium": preload("res://assets/audio/talk_higher.wav"),
  "high": preload("res://assets/audio/talk_high.wav"),
  "dog": preload("res://assets/audio/dog.wav"),
}

var voices = {
  "Zagreus": "default",
  "Hypnos": "medium",
  "Skelly": "medium",
  "Hades": "low",
  "Achilles": "low",
  "Cerberus": "dog",
  "Charon": "dog",
  "Orpheus": "high",
  "Dusa": "high",
  "Narrator": "low",
  
  "Ares": "low",
  "Zeus": "low",
  "Artemis": "high",
  "Athena": "medium",
  "Aphrodite": "medium",
}

# Called when the node enters the scene tree for the first time.
func open(data):
  index = 0
  if typeof(data) == TYPE_ARRAY:  #backwards compatibility
    dialog = data + []
  else:
    if data.chooseDialog:
      dialog = data.dialogs[data.chooseDialog.call_func()]
    else:
      dialog = data.dialog
    if data.onEnd: onEnd = data.onEnd
    
  self.visible = true
  timer.start()
  display(dialog[0])
  
func display(info):
  portrait.visible = true
  if info.speaker == "Narrator":
    portrait.visible = false
    textArea.text = info.text
    textArea.set_visible_characters(0)
    textArea.margin_left = 20
  elif info.speaker == "None":
    portrait.visible = false
    textArea.margin_left = 20
    textArea.text = info.text
    textArea.set_visible_characters(textArea.text.length())
  else:
    portrait.texture = load("res://assets/portraits/" + info.portrait)
    textArea.margin_left = 100
    textArea.text = info.speaker + ": " + info.text
    textArea.set_visible_characters(info.speaker.length() + 1)
  
  if voices.has(info.speaker):
    audio.stream = samples.get(voices[info.speaker])
  else:
    audio.stream = samples.get("default")
  
  count = 0

func _on_Timer_timeout():
  textArea.set_visible_characters(textArea.get_visible_characters() + 1)
  
  if textArea.get_visible_characters() <= textArea.text.length() and count % 8 == 0:
    audio.play()
  count += 1

func _input(event):
  if !event.is_pressed(): return
  if not self.visible: return
  
  if event.is_action_pressed("advance_text"):
    if textArea.get_visible_characters() < textArea.text.length():
      textArea.set_visible_characters(textArea.text.length())
    elif index < dialog.size() - 1:
      index += 1
      display(dialog[index])
    else:
      self.visible = false
      if onEnd: onEnd.call_func()
      emit_signal("dialog_closed")
    
  get_tree().set_input_as_handled()