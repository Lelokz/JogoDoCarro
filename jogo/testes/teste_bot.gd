extends SceneTree

# Roda sem tela: godot --headless --fixed-fps 120 --path jogo -s res://testes/teste_bot.gd
# O bot joga sozinho (o carro azul fica parado) em cada nível; conta os gols e os toques na bola.

const SEGUNDOS := 90.0

var nivel := 0


func _initialize() -> void:
	if not InputMap.has_action("acelerar"):
		root.add_child(load("res://scripts/controles.gd").new())
	rodar()


func rodar() -> void:
	for n in ([int(OS.get_cmdline_user_args()[1])] if OS.get_cmdline_user_args().has("--rastrear") else [0, 1, 2]):
		var rede: Node = root.get_node("Rede")
		rede.modo = "sozinho"
		rede.bot = n
		var cena: Node = load("res://cenas/arena.tscn").instantiate()
		root.add_child(cena)
		var partida: Node = cena.get_node("Partida")
		await physics_frame
		await physics_frame
		var bot_carro: RigidBody3D = partida.carros[partida.ID_BOT]
		var bola: RigidBody3D = cena.get_node("Bola")
		var toques := 0
		var tocando := false
		var parado := 0.0
		var mais_rapido := 0.0
		var pulos := 0
		for i in int(SEGUNDOS * 120.0):
			await physics_frame
			var agora: bool = bola in bot_carro.get_colliding_bodies()
			if agora and not tocando:
				toques += 1
			tocando = agora
			if partida.estado == partida.Estado.JOGANDO and bot_carro.linear_velocity.length() < 1.0:
				parado += 1.0 / 120.0
			mais_rapido = maxf(mais_rapido, bot_carro.linear_velocity.length())
			if OS.get_cmdline_user_args().has("--rastrear") and i % 240 == 0:
				var b: Node = partida.get_children().filter(func(x: Node) -> bool: return x.has_method("comecar_pulo"))[0]
				print("  %4.0f s: bot %s v %.1f rodas %d cima·y %.2f etapa pulo %d ré %.1f · bola %s · alvo %s · estado %s" % [i / 120.0, bot_carro.global_position.snapped(Vector3.ONE * 0.1), bot_carro.linear_velocity.length(), bot_carro.rodas_no_chao, bot_carro.global_basis.y.y, b.pulo_etapa, b.tempo_de_re, bola.global_position.snapped(Vector3.ONE * 0.1), b.alvo_lento.snapped(Vector3.ONE * 0.1), partida.Estado.keys()[partida.estado]])
		pulos = bot_carro.comandos.pulos
		print("bot %-8s em %d s: %d gols do bot (laranja), %d contra; %d toques na bola; parado %.0f s; até %.0f km/h; %d pulos" % [["Fácil", "Médio", "Difícil"][n], int(SEGUNDOS), partida.placar["laranja"], partida.placar["azul"], toques, parado, mais_rapido * 3.6, pulos])
		cena.queue_free()
		await physics_frame
	quit()
