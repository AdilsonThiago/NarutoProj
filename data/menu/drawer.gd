extends Node2D

var UI

func Draw():
	#Desenhar
	set_process(false)
	update()
	pass

func _draw():
	#Método da godot chamado pelo update() que permite desenhar formas geométricas
	#ou texturas na tela
	var rect = Rect2(Vector2(0,0),Vector2(44,44))
	draw_texture_rect(UI.Portraits[0],rect,false,Color(1,1,1,1),false,null)
	rect = Rect2(Vector2(436,0),Vector2(44,44))
	draw_texture_rect(UI.Portraits[1],rect,false,Color(1,1,1,1),false,null)
	pass
