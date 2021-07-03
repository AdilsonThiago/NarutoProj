extends Sprite
#Declarando variáveis
var Characters = []
var CharSize = 0
var Sel = 0
var Selection = []
var Cursor
var GPOT1
var GPOT2
var Portraits = []
var LabelInfo
var Bars = []
var stage
var ready = [false, false, false]
var level = ["Fácilimo", "Fácil", "Médio", "Difícil", "Dificílimo"]

func _ready():
	#Carregando a fase
	stage = load("res://data/stages/florest.tscn")
	#Permitindo a função de entrada de dados (_input(event)
	set_process_input(true)
	#Usando um método para carregar os personagens
	add_character("naruto")
	add_character("sakura")
	add_character("sasuke")
	#Carregando os elementos visuais para alterar e mostrar ao jogador
	Cursor = get_node("cursor")
	Bars = [get_node("chbar/bar"),get_node("chbar2/bar"),get_node("chbar3/bar"),get_node("chbar4/bar"),get_node("chbar5/bar")]
	LabelInfo = get_node("info")
	#Esse vetor armazena as opções escolhidas pelo jogador.
	#O personagem do jogador 1, do jogador 2, e a dificuldade
	Selection.append([])
	Selection = [0, 0, 2]
	if Networking.is_network_running():
		#Verificando na classe pública se o modo multijogador foi escolhido
		#e verificando se somos o servidor para mostrar o ip da máquina
		if Networking.is_server():
			$ipadr.text = "ip : " + str(Networking.get_ip_adress())
		else:
			Sel = 1
	update()
	pass

func _input(event):
	if !ready[Sel]:
		#Navegando entre os personagens/opções (se já não estiver sido feito)
		if (event.is_action_pressed("vk_right")):
			Selection[Sel] += 1
		if (event.is_action_pressed("vk_left")):
			Selection[Sel] -= 1
		if Sel < 2:
			if Selection[Sel] >= CharSize:
				Selection[Sel] -= CharSize
			elif Selection[Sel] < 0:
				Selection[Sel] += CharSize
		else:
			if Selection[Sel] < 0:
				Selection[Sel] = 4
			elif Selection[Sel] >= 5:
				Selection[Sel] = 0
	if Networking.get_number_of_players() > 1:
		#Atualizando as escolhas dos jogadores no jogo multijogador
		rpc("ch_selection", Sel, Selection[Sel])
	if event.is_action_pressed("vk_acept"):
		#Foi apertado o botão de confirmar
		if Networking.is_network_running():
			#Jogador confirmou a escolha
			rpc("start", Sel)
			if ready[0] and ready[1] and Networking.is_server():
				#Se for o servidor e ambos tiverem confirmado
				#podemos começar o jogo
				Sel = 2
		else:
			Sel += 1
		if Sel > 1:
			#Ambos confirmaram o personagem, é só começar o jogo
			if Networking.is_network_running():
				#Chamada remota para o cliente iniciar o jogo
				rpc("start_game")
			elif Sel > 2:
				#Iniciar o jogo no servidor também
				#(No caso de não ter sido ativado o modo multijogador
				#caímos aqui direto)
				start_game()
	else:
		#Atualizar a interface (_draw())
		update()
	pass

remote func ch_selection(sid,s):
	#Mudar a seleção do jogador (modo multijogador)
	Selection[sid] = s
	pass

remotesync func start(id):
	#Confirmar a escolha (modo multijogador)
	ready[id] = true
	pass

remotesync func start_game():
	#Carregar o jogo (modo multijogador e também offline)
	#Carregar a fase
	var o = stage.instance()
	get_parent().add_child(o)
	var system = o.get_node("system")
	#Instanciar dois jogadores
	for i in range(2):
		var list = Networking.get_player_list()
		var pos = o.get_node("player" + str(i)).position
		var character = load("res://data/characters/" + str(Characters[Selection[i]]) + str(".tscn"))
		var no = character.instance()
		o.add_child(no)
		#Registrando o jogador no sistema (interface)
		system.Players.append([])
		system.Players[i] = no
		#Não peguem esse meu costume de acessar as variáveis
		#Criem métodos ou funções para alterar as variáveis
		#Sera arrumado em uma atualização futura
		no.Game = system
		no.position = pos
		no.char_id = Characters[Selection[i]]
		no.dificult = Selection[2]
		if Networking.is_network_running():
			#Quem controla qual jogador
			no.set_network_master(list[i][0])
		#Quando o "control" não for ativo e não for jogo multijogador
		#a ia tomará controle do jogador
		if (i == 0):
			no.control = true
		else:
			no.control = false
			if (i == 1):
				no.Side = -1
		no.start(false)
	#Inicializando a interface e deletando esse menu
	system.start()
	queue_free()
	pass

func _draw():
	#Vamos desenhar a interface
	var ref
	GPOT1 = load("res://graphs/game/characters/" + str(Characters[Selection[0]]) + str("/selection.png"))
	GPOT2 = load("res://graphs/game/characters/" + str(Characters[Selection[1]]) + str("/selection.png"))
	draw_texture(GPOT1,Vector2(5,5),Color(1,1,1,1),null)
	draw_texture(GPOT2,Vector2(240,5),Color(1,1,1,1),null)
	for i in range(CharSize):
		if Sel < 2:
			if (i == Selection[Sel]):
				#Carrego esse script para ter acesso aos dados como força, velocidade
				#chackra, etc, para exibir nas barrinhas
				#Ainda não fiz a implementação completa, então esse carregamento está a toa
				ref = load("res://data/characters/" + str(Characters[Selection[Sel]]) + ".gd").new()
				Cursor.position = Vector2(65 + (42 * i),250)
		draw_texture(Portraits[i],Vector2(20 + (42 * i),250),Color(1,1,1,1),null)
	Bars[0].scale = Vector2(154,1)
	Bars[1].scale = Vector2(154,1)
	LabelInfo.text = "Nome:" + str("\nVitalidade:\nChakra:\nAtaque:\nChakra Ataque:\nVelocidade:\nVitórias:\nDerrotas:")
	$nv.text = level[Selection[2]]
	pass

func add_character(name_id):
	#Método para adicionar personagens de forma genérica, apenas pelo nome
	Characters.append([])
	Characters[CharSize] = name_id
	Portraits.append([])
	Portraits[CharSize] = load("res://graphs/game/characters/" + str(name_id) + str("/portrait.png"))
	CharSize += 1
	pass
