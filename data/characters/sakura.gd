extends "res://data/characters/characters_basics.gd"

func Start(ID):
	#Método para iniciar alguma variável específica do personagem, ou
	#qualquer outra necessidade
	pass

func Normal():
	#Movimentação do personagem, os golpes bácicos são executados no "characters_basics"
	#e os especiais são executados por esse método do filho
	if bt_fight > 0:
		if bt_run and Mana >= 5:
			Mana -= 5
			act_id = 52
			new_animation = "specialfast"
		else:
			act_id = 6
			new_animation = "fight1"
		allow_move = false
	elif bt_special > 0 and Mana >= 5:
		if bt_vside > 0:
			Mana -= 5
			act_id = 51
			new_animation = "special2"
			allow_move = false
		elif Mana >= 10:
			Mana -= 10
			act_id = 50
			new_animation = "special1"
			allow_move = false
	Game.BarsUpdate()
	pass

func combo():
	#Mesmo esquema do "Normal()", cada jogador possúi sua própria forma de continuar
	#os combos ou movimentações, esse método é chamado pelo pai
	if bt_fight > 0:
		if act_id == 6:
			act_id = 7
			new_animation = "fight2"
		elif act_id == 7:
			act_id = 8
			new_animation = "fight3"
		else:
			allow_move = true
	else:
		allow_move = true
	pass

func SpecialSpritesHide():
	#Mesmo esquema dos métodos anteriores. Esse método apenas certifica de
	#que não haja nada que não possa ser exibido depois de uma animação ter sido
	#interrompida
	pass
