extends CanvasLayer

#Inicializando as variáveis
#código da interface
var Cam
var Players = []
onready var NormalEffects = [preload("res://data/effects/hit.tscn"),preload("res://data/effects/mini_smoke.tscn"),preload("res://data/effects/strike_effect.tscn"),preload("res://data/effects/subjuts.tscn"),preload("res://data/effects/mana.tscn")]
var Portraits = []
var Drawer
var Bars = []

var endDelay = 0
var selScreen = preload("res://data/menu/character_selection_screen.tscn")

func start():
	#Pegando referências e atualizando a interface
	Bars.append([])
	Bars[0] = get_node("leftH/bar")
	Bars.append([])
	Bars[1] = get_node("leftM/bar")
	Bars.append([])
	Bars[2] = get_node("rightH/bar")
	Bars.append([])
	Bars[3] = get_node("rightM/bar")
	Drawer = get_node("drawer")
	Drawer.UI = self
	Portraits.append([])
	Portraits[0] = load("res://graphs/game/characters/" + str(Players[0].char_id) + str("/portrait.png"))
	Portraits.append([])
	Portraits[1] = load("res://graphs/game/characters/" + str(Players[1].char_id) + str("/portrait.png"))
	Cam = get_parent().get_node("camera")
	Drawer.Draw()
	BarsUpdate()
	pass

func _process(delta):
	var p = Players[0].position
	var pp = Vector2(0, 0)
	var r = -1
	if endDelay > 0:
		#Usado para reiniciar o jogo após a derrota do oponente
		endDelay += delta
		if endDelay > 3:
			var o = selScreen.instance()
			get_parent().get_parent().call_deferred("add_child", o)
			get_parent().queue_free()
	for i in range(Players.size()):
		#Calculando melhor posição para a câmera...
		var d = p.distance_to(Players[i].position)
		if d > r:
			pp = Players[i].position
			r = d
	var prelative = (pp - p) / 2
	var sz = 1
	p = p + prelative + Vector2(0,- 50)
	if r > 240:
		#... e um bom zoom para ela também...
		sz = 1 + (r - 240) / 480
		if sz > 1.35:
			sz = 1.35
	#Aplicando a posição e o zoom na câmera
	Cam.zoom = Vector2(sz,sz)
	Cam.position = Vector2(floor(p.x) - (240 * (sz - 1)),floor(p.y) - (180 * (sz - 1)))
	pass

func BarsUpdate():
	#Atualizando a barra de vida e de chackra
	Bars[0].scale = Vector2((Players[0].Health * 154) / Players[0].MaxHealth,1)
	Bars[1].scale = Vector2((Players[0].Mana * 154) / Players[0].MaxMana,1)
	Bars[2].scale = Vector2((Players[1].Health * 154) / Players[1].MaxHealth,1)
	Bars[3].scale = Vector2((Players[1].Mana * 154) / Players[1].MaxMana,1)
	if endDelay <= 0 and (Players[0].Health <= 0 or Players[1].Health <= 0):
		endDelay += 0.1
	pass
