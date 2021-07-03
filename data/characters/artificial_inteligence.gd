#Todo esse código é para a inteligência artificial
#Pega informações sobre os jogadores e simula o pressionamento dos botões
var Player = null
var Enemy_Target = null
var Chak_Status = 0
var Healt_Stats = 0
var time = 0
var Enemy_Chak_Status = 0
var Strategy = ""
var Dificult = 3
var Agressive = true
var Level = 0
#Algumas partes eu defini mas não usei, será atualizado em versões futuras
var retreatchance = 95
var teleportchance = 200
var guardchance = 75
var jumpchance = 300
var usespecial = 20
var fightchance = 70
var continuefight = 15
var recmana = 60
#Para facilitar a visualização do estado em relação ao oponente
var Status = ["Terrible","Bad","Normal","Good","Exelent"]

func start_settings(id, eneid, diflevel):
	#Método chamado para inicializar as variáveis assim que o jogador é
	#instanciado
	Dificult = 2
	Player = id
	Enemy_Target = eneid
	Level = diflevel + 1
	#Valores que são usados para testes de aleatóriedade
	#interferem na jogabilidade (dificuldade) do jogador
	retreatchance = retreatchance / Level
	teleportchance = teleportchance / Level
	guardchance = guardchance / Level
	jumpchance = jumpchance / Level
	usespecial = usespecial / Level
	fightchance = fightchance / Level
	continuefight = continuefight / Level
	recmana = recmana / Level
	pass

func update(delta):
	#Função chamada externamente para realizar a atualização da inteligência
	#artificial
	time += delta
	if time >= 0.1:
		#Execução da inteligência artificial fixa a cada 0,1 segundos
		time -= 0.1
		IA()
	pass

func IA():
	#Código principal da inteligência artificial
	randomize()
	if Enemy_Target != null and Enemy_Target.Health > 0:
		#Pegando informações relativas entre os jogadores
		var health_diference = Player.Health - Enemy_Target.Health
		var enemy_distance = Player.position.distance_to(Enemy_Target.position)
		#Essa parte abaixo será removida em atualizações
		#Basicamente verifica a diferença de vida e de chackra
		if abs(health_diference) > 10:
			if health_diference > 0:
				Healt_Stats = 4
			else:
				Healt_Stats = 0
		elif abs(health_diference) > 5:
			if health_diference > 0:
				Healt_Stats = 3
			else:
				Healt_Stats = 1
		else:
			Healt_Stats = 2
		if Player.Mana > 30:
			Chak_Status = 4
		elif Player.Mana > 15:
			Chak_Status = 3
		elif Player.Mana > 5:
			Chak_Status = 2
		else:
			Chak_Status = 1
		#Atribuindo valores para as variáveis auxiliares
		#Posição relativa, comportamento atual, etc
		var enemy_vulnerability = false
		var enemy_slepping = false
		var enemy_position_relative = Vector2(sign(Enemy_Target.position.x - Player.position.x), 0)
		var looking_at_enemy = Player.Side == enemy_position_relative.x
		var enemy_looking_at_me = Enemy_Target.Side == - enemy_position_relative.x
		var guard_stance = false
		if abs(Player.position.y - Enemy_Target.position.y) > 45:
			#Forma simples para pular, sem verificar muitas possibilidades
			enemy_position_relative = Vector2(enemy_position_relative.x, sign(Enemy_Target.position.y - Player.position.y))
		if Enemy_Target.act_id < -1:
			#Inimigo foi derrubado, está deitado
			enemy_slepping = true
		if (Enemy_Target.act_id >= 6 and !enemy_looking_at_me) or Enemy_Target.act_id == - 5:
			#Inimigo está vulnerável
			enemy_vulnerability = true
		
		Player.bt_jump = false
		
		if Player.act_id >= 9 and Player.act_id < 50 and looking_at_enemy:
			#Tentando continuar combos de especiais se possível
			Player.bt_fight = 0.1
			Player.bt_special = 0.1
		if Player.act_id >= 6 and Player.act_id <= 8 and looking_at_enemy and enemy_distance < 80 and Test_Chance(continuefight):
			#Continuar combos
			Player.bt_fight = 0.1
		if Player.bt_vside == 1 and (Enemy_Target.act_id < 6 or !enemy_looking_at_me or !looking_at_enemy):
			#Parar de se defender
			Player.bt_vside = 0
		if Player.act_id == - 2 and enemy_distance >= 80 and Player.Mana >= 10 and Test_Chance(retreatchance):
			#Se recuperar no ar
			Player.bt_jump = true
		if Enemy_Target.act_id >= 6 and enemy_looking_at_me:
			#Inimigo está atacando, escolher uma forma de defesa
			if (Test_Chance(teleportchance) or Player.bt_telp > 0) and Player.Mana >= 5:
				#Jutsu de substituição
				Player.bt_hside = enemy_position_relative.x
				Player.bt_telp = 0.5
				Player.bt_vside = 0
			elif (Test_Chance(guardchance) or Player.bt_vside > 0) and looking_at_enemy and Player.bt_telp <= 0 and !Player.bt_jump:
					#Entrar em defesa
					Player.bt_vside = 1
			elif (Test_Chance(jumpchance) or Player.bt_jump) and Player.bt_telp <= 0 and Player.bt_vside != 1:
					#Pular para esquivar
					Player.bt_hside = enemy_position_relative.x
					Player.bt_jump = true
		else:
			#Não há motivos para usar o teleporte se não for para se defender
			Player.bt_telp = 0
		if Player.bt_vside > 0:
			#Estamos em modo de defesa
			guard_stance = true
		if (enemy_distance > 60 and Agressive) or !looking_at_enemy:
			#Estamos longe ou olhando para o lado errado
			#Vamos nos aproximar do oponente
			if enemy_distance > 80:
				Player.bt_run = true
			else:
				Player.bt_run = false
			Player.bt_hside = enemy_position_relative.x
		if enemy_distance < 100 and Player.Mana >= 5 and enemy_vulnerability and looking_at_enemy:
			#Momento propício para tentar usar uma habilidade especial
			if Test_Chance(usespecial):
				if floor(rand_range(0, 2)) == 1:
					Player.bt_run = true
					Player.bt_vside = 1
					if floor(rand_range(0,2)) == 1:
						Player.bt_special = 0.1
					else:
						Player.bt_fight = 0.1
				else:
					Player.bt_special = 0.1
		elif enemy_distance < 60 and looking_at_enemy and !guard_stance:
			#Estamos próximo do inimigo
			Player.bt_run = false
			if abs(Player.linear_velocity.x) > 200:
				#Estamos muito perto e com muita velocidade
				#Freiar
				Player.bt_hside = - sign(Player.linear_velocity.x)
			else:
				#Soltar o botão de movimentação
				Player.bt_hside = 0
			if looking_at_enemy and Test_Chance(fightchance):
				#Estamos próximos do oponente e olhando para ele
				#Atacar!
				Player.bt_fight = 0.1
		elif enemy_distance >= 100 and !guard_stance:
			#Estamos longe do nosso inimigo e não estamos em posição de defesa
			if Player.Mana < Player.MaxMana:
				#Pouco chackra, podemos recarregar
				if (Test_Chance(recmana) or Player.Mana / Player.MaxMana < 0.5) or Player.bt_vside == -1:
					Player.bt_vside = - 1
					Agressive = false
			else:
				#Já temos o chackra cheio, vamos soltar o botão de recarregar
				if Player.bt_vside == -1:
					Player.bt_vside = 0
			if Player.Mana / Player.MaxMana > 0.8 and Test_Chance(recmana * 1.5):
				#Temos mana suficiente, podemos agressivar
				Agressive = true
				if Player.bt_vside == -1:
					Player.bt_vside = 0
	else:
		#Se não existir inimigo ou ele não possuir vida
		#podemos parar a movimentação
		Player.bt_hside = 0
		Player.bt_vside = 0
	pass

func Test_Chance(prob):
	#Método que fiz para testar aleatóriedade
	var ret = false
	var easy = 6
	for s in range(easy):
		if (floor(rand_range(0,prob)) == 1):
			ret = true
	return ret
	pass
