extends Node2D

const DEFAULT_IP = "127.0.0.1"
const DEFAULT_PORT = 8080
const MAX_PLAYERS = 2

var Ip = "127.0.0.1"
var Id = ""
var Name = ""
var Networking_Started = false

var Peer = null
var Players = []
var N_Players = 0
var Menu = null

func Start_Networking():
	get_tree().connect("connected_to_server", self, "conected_on_server")
	get_tree().connect("connection_failed", self, "conection_error")
	get_tree().connect("server_disconnected", self, "server_disconected")
	Networking_Started = true
	pass

func conected_on_server():
	rpc("register_player", get_tree().get_network_unique_id(), Name)
	pass

func get_ip_adress():
	for ip in IP.get_local_addresses():
		if ip.begins_with("192"):
			return ip
			break
	pass

func client_disconected(id):
	var pos = 0
	for i in range(N_Players):
		if Players[i][0] == id:
			pos = i
	rpc("remove_player", pos)
	pass

func conection_error():
	print("error connection")
	pass

func server_disconected():
	get_tree().quit()
	pass

remote func register_player(id, novonome):
	if get_tree().is_network_server():
		for i in range(N_Players):
			rpc_id(id, "register_player", Players[i][0], Players[i][1])
		rpc("register_player", id, novonome)
	Players.append([])
	Players[N_Players].append([])
	Players[N_Players][0] = id
	Players.append([])
	Players[N_Players].append([])
	Players[N_Players][1] = novonome
	N_Players += 1
	
	if Menu != null:
		Menu.Atualizar_Lista_Jogadores()
	pass

remotesync func remove_player(posicao):
	Players.remove(posicao)
	N_Players -= 1
	pass

func change_name(novonome):
	Name = novonome
	pass

func change_ip(novoip):
	Ip = novoip
	pass

func get_player_list():
	return Players
	pass

func get_number_of_players():
	return N_Players
	pass

func get_network_id():
	return Id
	pass

func is_network_running():
	return Networking_Started
	pass

func is_server():
	return get_tree().is_network_server()
	pass

func host():
	Start_Networking()
	
	Peer = NetworkedMultiplayerENet.new()
	Peer.create_server(DEFAULT_PORT, MAX_PLAYERS)
	get_tree().set_network_peer(Peer)
	Peer.connect("peer_disconnected", self, "client_disconected")
	Id = get_tree().get_network_unique_id()
	
	register_player(Id, Name)
	pass

func join():
	Start_Networking()
	
	Peer = NetworkedMultiplayerENet.new()
	Peer.create_client(Ip, DEFAULT_PORT)
	get_tree().set_network_peer(Peer)
	Id = get_tree().get_network_unique_id()
	pass
