extends ColorRect
signal dialog_closed

onready var box = $Dialog
onready var portrait = $Dialog/ColorRect/Portrait
onready var textArea = $Dialog/Text
onready var timer = $Dialog/Timer

var index = 0
var dialog = []

# Called when the node enters the scene tree for the first time. give a whole array of dialog
func open(dialogData):
  index = 0
  dialog = dialogData + []
  self.visible = true
  timer.start()
  display(dialog[0])
  
func display(info):
  if info.get("choices"):
    $Dialog/ColorRect.visible = false
    textArea.text = "" #info.choiceText + "\n"
    for i in range(info.choices.size()):
      textArea.text += str(i+1) + ": " + info.choices[i] + "\n"
    textArea.set_visible_characters(9999)
  else:
    $Dialog/ColorRect.visible = true
    portrait.texture = load(info.portrait)
    textArea.text = info.speaker + ": " + info.text
    textArea.set_visible_characters(info.speaker.length() + 1)

func _on_Timer_timeout():
  textArea.set_visible_characters(textArea.get_visible_characters() + 1)

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
      emit_signal("dialog_closed")
    
  get_tree().set_input_as_handled()