extends Node2D

onready var gameOverText = $RichTextLabel
onready var zag = $PlayerSprite
#onready var anim = $AnimationPlayer
var c = 0

func _input(event):
  if !event.is_pressed():
    return
    
  if event.is_action_pressed("restart"):
    get_tree().change_scene("res://House.tscn")
   
func _ready():
  gameOverText.set_visible_characters(0)
  if Global.playerSprite:
    zag.set_flip_h(Global.playerSprite)

func _on_Timer_timeout():
  c += 1
  gameOverText.set_visible_characters(gameOverText.get_visible_characters() + 1)
  if c > 5 and c % 5 == 0: zag.frame += 1