extends ColorRect



func _draw():
    var maxMana = player.maxMana
  var width = barSize / maxMana
  for i in range(1, maxMana):
    draw_rect(Rect2(manabar.rect_position + Vector2(i * width, 0), Vector2(4,50)), Color(1,1,1,1))
  

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#  pass
