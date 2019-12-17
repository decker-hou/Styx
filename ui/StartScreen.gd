extends Node2D

func _ready():
  if not Global.startScreen:
    get_tree().change_scene("res://Game.tscn")
  $Logo.modulate.a = 0
  $copyright.modulate.a = 0

func _input(event):
  if !event.is_pressed():
    return
    
  if event.is_action_pressed("ui_accept"):
    get_tree().change_scene("res://Game.tscn")

onready var turn = -3

func _on_Timer_timeout():
  if turn % 4 == 0: $Logo.modulate.a += 0.2
  if $Logo.modulate.a >= 1.3:
    $copyright.modulate.a += 0.1
  turn += 1
  
