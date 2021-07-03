extends RigidBody2D
#Código de movimentação genérico para inimigos e personagens
var Game = null
var Body = null
var Play = null
var NewPos = Vector2(0, 0)
var VH = 0
var VV = 0
var char_id = ""
var is_in_land = 0
var allow_move = true
var telp_pos = Vector2(0, 0)
var Side = 1
var impulso = 0
var dmgArea = null
var dmgArea2 = null
var horArea = null
var tepArea = null
var recuperation = 0
var IA = null
var control = true
var dificult = 0
#Animação
var animator = null
var current_sprite = null
var new_animation = ""
var current_animation = new_animation
var act_id = 0
#Botões
var bt_htime = 0
var bt_hside = 0
var bt_vside = 0
var bt_run = false
var bt_jump = false
var bt_telp = 0
var bt_fight = 0
var bt_special = 0
#Atributos
var MaxHealth = 70
var Health = MaxHealth
var MaxMana = 25
var Mana = MaxMana
var Normal_Speed = 150
var Max_Speed = 320
var Atack = 4
var Jutsus = []

func start(clone):
	#Método de inicialização
	set_process(true)
	if control == true or Networking.is_network_running():
		#Quando a variável controle ou o modo multijogador estiver ativo,
		#ativamos o _input
		set_process_input(true)
		control = true
	else:
		#Caso contrário, ativamos a inteligência artificial, que é genérica
		#para todos os personagens
		set_process_input(false)
		if clone == true:
			IA = load("res://data/characters/artificial_inteligence.gd").new()
			IA.start_settings(self, Game.Players[0], 2)
		else:
			IA = load("res://data/characters/artificial_inteligence.gd").new()
			IA.start_settings(self, Game.Players[0], dificult)
	#Pegando as referências
	Body = self
	Play = get_node("player")
	current_sprite = get_node("player/idle")
	animator = get_node("animcontrol")
	dmgArea = get_node("player/damagearea")
	dmgArea2 = get_node("player/damagearea2")
	horArea = get_node("bodshapeh")
	tepArea = get_node("telparea")
	set_dmg_area_pos(true, Vector2(0, 0))
	pass

func _input(event):
	#Essa função é aciondada sempre que há alguma interação do jogador
	#seja uma técla pressionada, movimentação no mouse, ou qualquer outro pressionamento
	#de outro dispositivo como joystick
	if !Networking.is_network_running() or is_network_master():
		#Só entraremos nesse bloco se o modo multijogador não estiver ativo ou
		#formos o cliente que controla esse jogador
		#Códigos abaixo são para a movimentação básica do jogador
		#como podem perceber, apenas atribuimos valores para as variáveis
		#que efetivarão a movimentação e animação
		if event.is_action_pressed("vk_right"):
			if bt_htime > 0:
				bt_run = true
			else:
				bt_run = false
				bt_htime = 0.25
			bt_hside = 1
		if event.is_action_released("vk_right") and bt_hside == 1:
			bt_hside = 0
			bt_run = false
		if event.is_action_pressed("vk_left"):
			if bt_htime > 0:
				bt_run = true
			else:
				bt_run = false
				bt_htime = 0.25
			bt_hside = -1
		if event.is_action_released("vk_left") and bt_hside == -1:
			bt_hside = 0
			bt_run = false
		if event.is_action_pressed("vk_up"):
			bt_vside = -1
		if event.is_action_released("vk_up") and (bt_vside == -1):
			bt_vside = 0
		if event.is_action_pressed("vk_down"):
			bt_vside = 1
		if event.is_action_released("vk_down") and (bt_vside == 1):
			bt_vside = 0
		if event.is_action_pressed("vk_telp"):
			bt_telp = 0.15
		if event.is_action_pressed("vk_fight"):
			bt_fight = 0.3
		if event.is_action_pressed("vk_special"):
			bt_special = 0.3
		if event.is_action_pressed("vk_jump"):
			bt_jump = true
		if event.is_action_released("vk_jump"):
			bt_jump = false
		if Networking.is_network_running():
			#Se estivermos no modo multijogador e formos o cliente
			#que controla esse personagem, podemos repassar os botões que pressionamos
			#para repassar as interações que realizamos para os outros jogadores
			rpc("set_buttons", bt_run, bt_htime, bt_hside, bt_vside, bt_telp, bt_fight, bt_special, bt_jump)
	pass

remote func set_buttons(etc1, etc2, etc3, etc4, etc5, etc6, etc7, etc8):
	#Função remota para atualizar os botões que cada jogador pressionou
	bt_run = etc1
	bt_htime = etc2
	bt_hside = etc3
	bt_vside = etc4
	bt_telp = etc5
	bt_fight = etc6
	bt_special = etc7
	bt_jump = etc8
	pass

remote func update_data(pos, sid, anim, he, ma):
	#Função que o servidor chama nos clientes para evitar ambigüidade/falta de sincronização
	NewPos = pos
	Side = sid
	Play.scale = Vector2(Side, 1)
	new_animation = anim
	Health = he
	Mana = ma
	pass

func _process(delta):
	var h = 0
	VH = Body.linear_velocity.x
	VV = Body.linear_velocity.y
	if control == false:
		#Chamando o método principal da inteligência artificial
		#para realizar a movimentação do personagem simulando o pressionamento dos
		#botões
		IA.update(delta)
	if telp_pos.x == 0:
		#Não é possível se teleportar para a mesma posição
		h = Side
	else:
		h = telp_pos.x
	if act_id == 5:
		#Posição destino do teleporte
		tepArea.position = Vector2(h, telp_pos.y).normalized() * 80
	else:
		tepArea.position = Vector2(0, 0)
	#Resetando algumas variáveis de movimentação e de
	#pressionamento de botões
	if bt_htime > 0:
		bt_htime -= delta
	if impulso > 0:
		impulso -= delta
	if bt_telp > 0:
		bt_telp -= delta
	if bt_fight > 0:
		bt_fight -= delta
	if bt_special > 0:
		bt_special -= delta
	if recuperation > 0:
		recuperation -= delta
	if is_in_land > 0:
		#Estamos no chão, bloco de códigos para animar e movimentar
		if is_in_land < 1:
			is_in_land -= delta * 30
		if allow_move == true:
			act_id = 0
			if abs(Body.linear_velocity.x) <= Normal_Speed + 80:
				if abs(Body.linear_velocity.x) < 10:
					new_animation = "idle"
				else:
					new_animation = "walk"
					act_id = 0
			else:
				new_animation = "run"
				act_id = 2
			if abs(bt_hside) > 0:
				var totalspeed = Normal_Speed
				if sign(Body.linear_velocity.x) == bt_hside:
					Side = bt_hside
				if Side == bt_hside:
					if bt_run == true:
						totalspeed = Max_Speed
				else:
					new_animation = "break"
				if abs(Body.linear_velocity.x) <= totalspeed or Side != bt_hside:
					Body.apply_impulse(Vector2(0,0),Vector2(1500 * bt_hside * delta,0))
			if bt_telp > 0 and bt_telp <= 0.1:
				if bt_vside == 1:
					bt_vside = 0
				telp_pos = Vector2(bt_hside,bt_vside)
				act_id = 5
				Body.linear_velocity.x = 0
				Body.gravity_scale = 0
				new_animation = "teleport"
				allow_move = false
			elif bt_jump == true and bt_telp <= 0 and impulso <= 0:
				act_id = 3
				Body.apply_impulse(Vector2(0,0),Vector2(0,- 350))
				impulso = 0.5
			else:
				if bt_vside == 1 and impulso <= 0:
					act_id = 4
					Body.linear_velocity.x = 0
					new_animation = "defense"
				elif bt_vside == -1:
					Body.linear_velocity.x = 0
					new_animation = "chack"
					act_id = 1
					Mana += 5 * delta
					Game.BarsUpdate()
				Normal()
		else:
			if act_id < 0 and recuperation <= 0:
				if act_id == -2:
					new_animation = "knok3"
					act_id = -3
					recuperation = 0.6
				elif act_id == -1 or act_id == -4 or act_id == -5:
					allow_move = true
				elif act_id == -3 and Health > 0 and sqrt(abs(Body.linear_velocity.x * 2) + abs(Body.linear_velocity.x * 2)) < 0.3 / delta:
					new_animation = "knok4"
					act_id = -5
					recuperation = 0.33
	else:
		#Estamos no ar, bloco de códigos para animar e movimentar
		if allow_move == true:
			if abs(bt_hside) > 0:
				var totalspeed
				if bt_run == true:
					totalspeed = Max_Speed
				else:
					totalspeed = Normal_Speed
				if abs(Body.linear_velocity.x) <= totalspeed:
					Body.apply_impulse(Vector2(0,0),Vector2(330 * bt_hside * delta,0))
			if bt_jump == true and impulso > 0:
				Body.apply_impulse(Vector2(0,0),Vector2(0,- 1000 * delta))
			if bt_telp > 0 and bt_telp <= 0.1:
				telp_pos = Vector2(bt_hside,bt_vside)
				act_id = 5
				Body.linear_velocity = Vector2(0,0)
				Body.gravity_scale = 0
				new_animation = "teleport"
				allow_move = false
			else:
				new_animation = "jump_"
				if self.linear_velocity.y > 0:
					new_animation += "down"
				else:
					new_animation += "up"
		else:
			if act_id == -2 and new_animation == current_animation:
				if bt_jump and Mana >= 5:
					Mana -= 5
					new_animation = "retreat"
					act_id = 0
				if abs(linear_velocity.x) > 5:
					if (Side == -1):
						current_sprite.rotation = - Vector2(0,0).angle_to_point(linear_velocity) + deg2rad(180)
					else:
						current_sprite.rotation = Vector2(0,0).angle_to_point(linear_velocity)
				else:
					current_sprite.rotation = 0
	if Mana >= MaxMana:
		#Evitar que o chackra ultrapasse o limite
		Mana = MaxMana
	if Networking.is_network_running() and Networking.is_server():
		#Se esse jogador for o servidor, comandar a atualização dos dados para os clientes
		#para evitar ambigüidade/dessincronização
		rpc_unreliable("update_data", position, Side, new_animation, Health, Mana)
	#Código para trocas de animações e angulo do jogador
	animation()
	pass

func animation():
	#Código para trocas de animações e angulo do jogador
	if current_animation != new_animation:
		animator.stop(true)
		current_animation = new_animation
		current_sprite.hide()
		current_sprite = get_node("player/" + current_animation)
		if current_animation == "break":
			current_sprite.rotation_degrees = - 10
		current_sprite.show()
		animator.play(current_animation)
	Play.scale = Vector2(Side,1)
	pass

func enable_move():
	#Habilitar a movimentação do jogador após um bloqueio
	#há bloqueios por conta da animação, especial, ou por ter
	#levado algum golpe
	set_dmg_area_pos(true, Vector2(0, 0))
	allow_move = true
	Body.gravity_scale = 10
	pass

func teleport():
	#Método para verificar espaço vazio para teleporte
	#evita bugs como o jogador ficar preso dentro de algum bloco estático
	#do jogo
	if Empty_For_Telp():
		if telp_pos.x == 0 and telp_pos.y == 0:
			telp_pos = Vector2(Side,0)
		position += telp_pos.normalized() * 80
		telp_pos = Vector2(0,0)
	pass

func Normal():
	#Não há nada aqui porque esse método é da classe filho
	#Vá até o código com o nome do personagem (ex naruto.gd) para ver o conteúdo
	#do método
	pass

func combo():
	#Não há nada aqui porque esse método é da classe filho
	#Vá até o código com o nome do personagem (ex naruto.gd) para ver o conteúdo
	#do método
	pass

func SpecialSpritesHide():
	#Não há nada aqui porque esse método é da classe filho
	#Vá até o código com o nome do personagem (ex naruto.gd) para ver o conteúdo
	#do método
	pass

func set_dmg_area_pos(default : bool, pos : Vector2):
	#Algumas animações permitem um alcance maior
	#esse método serve para resetar a posição ou aumentar o alcançe
	if default:
		dmgArea.position = Vector2(33, 5.5)
		dmgArea2.position = Vector2(- 33, 5.5)
	else:
		dmgArea.position = Vector2(pos.x, -5.5 + pos.y)
		dmgArea2.position = Vector2(- pos.x, -5.5 + pos.y)
	pass

func Create_Effect(id : int, pos : Vector2):
	#Criar um efeito passando como parâmetros o id dele e a posição
	#em que deve ser instanciado
	var o = Game.NormalEffects[id].instance()
	get_parent().add_child(o)
	o.position = Body.position + Vector2(pos.x * Side, pos.y)
	pass

func display_damage(damage : float,vectorimpulse : Vector2, allside : bool = false):
	#Método para causar dano em um alvo que está na area de contato
	var objs = dmgArea.get_overlapping_bodies()
	for i in range(objs.size()):
		if objs[i].is_in_group("character") and objs[i] != self and objs[i].act_id != - 3 and objs[i].act_id != 5:
			objs[i].damage(damage * Atack, Vector2(vectorimpulse.x * Side,vectorimpulse.y))
			var pos = dmgArea.global_position
			var o = Game.NormalEffects[0].instance()
			get_parent().add_child(o)
			o.position = pos
	if allside:
		objs = dmgArea2.get_overlapping_bodies()
		for i in range(objs.size()):
			if objs[i].is_in_group("character") and objs[i] != self and objs[i].act_id != - 3 and objs[i].act_id != 5:
				objs[i].damage(damage * Atack, Vector2(- vectorimpulse.x * Side,vectorimpulse.y))
				var pos = dmgArea2.global_position
				var o = Game.NormalEffects[0].instance()
				get_parent().add_child(o)
				o.position = pos
	pass

func Empty_For_Telp():
	#Função para verificar espaço vazio para o teleporte
	var objs = tepArea.get_overlapping_bodies()
	for i in range(objs.size()):
		if objs[i].is_in_group("solid"):
			return false
	return true
	pass

func damage(dmg, vec):
	#Tomar dano de algum meio
	#esse método é chamado externamente pelo método "display_damage"
	if act_id >= - 1 or act_id == - 4:
		vec = vec * 60
		Body.linear_velocity = Vector2(0,0)
		if bt_telp >= 0.1 and Mana >= 5:
			Mana -= 5
			telp_pos = Vector2(bt_hside,bt_vside)
			act_id = 5
			Body.gravity_scale = 0
			new_animation = "teleport"
			allow_move = false
			var o = Game.NormalEffects[3].instance()
			get_parent().add_child(o)
			o.position = Body.position
			o.apply_impulse(Vector2(0,0),vec)
			for s in range(5):
				o = Game.NormalEffects[1].instance()
				get_parent().add_child(o)
				o.position = Body.position + Vector2(rand_range(-6,12),rand_range(-22,22))
				o.VH = vec.x / 2
		else:
			if abs(act_id) == 4 and Side != sign(vec.x):
				act_id = -4
				Health -= dmg / 3
				Body.apply_impulse(Vector2(0,0),Vector2((vec.x) / 2,0))
			else:
				Side = - sign(vec.x)
				if abs(vec.y) > 0.5 or is_in_land < 0.4:
					act_id = -2
					new_animation = "knok2"
				else:
					act_id = -1
					new_animation = "knok1"
				Health -= dmg
				Body.apply_impulse(Vector2(0,0),vec)
			VH = vec.x
			VV = vec.y
			allow_move = false
			recuperation = 0.5
			var chc = horArea.get_overlapping_bodies()
			for i in range(chc.size()):
				if chc[i].is_in_group("solid"):
					_on_bodshapeh_body_entered(chc[i])
			if Health <= 0:
				if act_id != -2:
					act_id = -2
					new_animation = "knok2"
				Health = 0
		SpecialSpritesHide()
		Game.BarsUpdate()
	pass

func velocity(vec : Vector2):
	#Usado nas animações para alterar a velocidade do personagem durante a animação
	linear_velocity = Vector2(vec.x * Side,vec.y)
	pass

func break_smoke_effect():
	#Emitir efeito de fumaça nos pés do jogador ao freiar
	var o = Game.NormalEffects[1].instance()
	get_parent().add_child(o)
	o.position = Body.position + Vector2(0,10)
	o.VH = VH / 4
	pass

func mana_effect():
	#Emitir efeito do chackra ao estar absorvendo
	var o = Game.NormalEffects[4].instance()
	get_parent().add_child(o)
	o.position = Body.position + Vector2(0, 0)
	pass

func _integrate_forces(state):
	#Método que permite a alteração de posição do rigidbody
	if abs(NewPos.x) + abs(NewPos.y) > 0:
		var xy = state.get_transform()
		xy.origin = NewPos
		state.set_transform(xy)
		NewPos = Vector2(0,0)
	pass

func _on_bodshapeh_body_entered(body):
	#Identifica colisão com o chão (conectado com area2d bodshapeh)
	if body.is_in_group("solid"):
		if abs(VH) > 450 and act_id < 0 and sign(VH) == sign(body.position.x - Body.position.x):
			var o = Game.NormalEffects[2].instance()
			get_parent().add_child(o)
			o.position = Body.position
			o.rotation_degrees = 90
			o.scale = Vector2(1,Side)
		Side = - Side
		if abs(VH) > 0:
			VH = VH / 3
			Body.linear_velocity.x = - (VH)
		if abs(VV) > 0:
			VV = VV / 2
			Body.linear_velocity.y = VV
	pass

func _on_Naruto_body_entered(body):
	#Colisão com outro objeto sólido
	if body.is_in_group("solid"):
		if VV > 450:
			var o = Game.NormalEffects[2].instance()
			get_parent().add_child(o)
			o.position = Body.position + Vector2(0,15)
			if abs(VV) > 0:
				VV = - (VV / 3)
				Body.linear_velocity.y = VV
		else:
			is_in_land = 1
	pass

func _on_Naruto_body_exited(body):
	#Saída de colisão com outro objeto sólido
	if body.is_in_group("solid"):
		is_in_land -= 0.1
		var chc = Body.get_colliding_bodies()
		for i in range(chc.size()):
			if chc[i] != body and chc[i].is_in_group("solid"):
				is_in_land = 1
	pass
