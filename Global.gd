extends Node

#global should only be used sparingly for things that need to be preserved between scenes

var startScreen = false
var noEnemies = true
var debug = true  #turns on/off debug room
var tutorialStage = false #turns on/off tutorial room 
var playerSprite

func swap(a, b):
  var temp = a
  a = b
  b = temp
  
func new_sprite(texture, scale, pos, parent=self, centered=true):
  var s = Sprite.new()
  s.texture = texture
  s.scale = Vector2(scale, scale)
  s.position = pos
  s.set_centered(centered)
  parent.add_child(s)
  return s