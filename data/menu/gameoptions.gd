extends Node2D

#Menu principal do jogo
#Carregar variáveis essênciais
var TextLabel = null
var Options = []
var Options2 = []
var Selection = 0
var SubMenu = 0
onready var SelectionScreen = preload("res://data/menu/character_selection_screen.tscn")
var ListSize = 0

func _ready():
	set_process_input(true)
	TextLabel = $gameoptions
	#As opções de jogo são mostradas ao jogador de acordo com esses vetores
	Options = ["História","Survival","Versus","Campeonato","Personagens","Opções","Sair"]
	Options2 = ["Único Jogador","Criar Lan","Entrar Lan"]
	TextLabel.text = ""
	#Percorrendo os vetores para mostrar as informações ao jogador
	for i in range(Options.size()):
		if i == Selection:
			TextLabel.text += "< "
		TextLabel.text += Options[i]
		if i == Selection:
			TextLabel.text += " >"
		TextLabel.text += str("\n")
	pass

func _input(event):
	#Tecla pressionada...
	if event.is_action_pressed("vk_down"):
		change_selection(+1)
	if event.is_action_pressed("vk_up"):
		change_selection(-1)
	if event.is_action_pressed("vk_acept"):
		game_selected(Selection)
	pass

func change_selection(value):
	#Método para trocar a seleção do jogador (mover o cursor)
	Selection += value
	if SubMenu == 0:
		ListSize = Options.size()
	elif SubMenu == 1:
		ListSize = Options2.size()
	if Selection < 0:
		Selection = ListSize - 1
	elif Selection > ListSize -1:
		Selection = 0
	TextLabel.text = ""
	for i in range(ListSize):
		if i == Selection:
			TextLabel.text += "< "
		if SubMenu == 0:
			TextLabel.text += Options[i]
		elif SubMenu == 1:
			TextLabel.text += Options2[i]
		if i == Selection:
			TextLabel.text += " >"
		TextLabel.text += str("\n")
	pass

func game_selected(number):
	#Método que confirma a seleção
	if SubMenu == 0:
		if number == 2:
			SubMenu = 1
			change_selection(0)
	elif SubMenu == 1:
		if number == 0:
			var obj = SelectionScreen.instance()
			get_parent().add_child(obj)
			queue_free()
		if number == 1:
			Networking.host()
			var obj = SelectionScreen.instance()
			get_parent().add_child(obj)
			queue_free()
		elif number == 2:
			Networking.change_ip($ipins.text)
			Networking.join()
			var obj = SelectionScreen.instance()
			get_parent().add_child(obj)
			queue_free()
	pass
