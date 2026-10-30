extends Node

# Regras da partida: saída de bola com contagem, gol, placar, cronômetro, prorrogação e pads de boost.
# O carro é do time azul e ataca o gol laranja (z negativo).

@export var carro_caminho: NodePath
@export var bola_caminho: NodePath
@export var hud_caminho: NodePath

const TEMPO_PARTIDA := 300.0
const TEMPO_CONTAGEM := 3.0
const TEMPO_COMEMORACAO := 3.0
const BOOST_SAIDA := 33.0
const RAIO_BOLA := 0.9125
const ALTURA_CARRO := 0.32
# onde o carro pode começar na saída de bola (sempre olhando pra bola)
const SAIDAS := [Vector3(0, 0, 42), Vector3(-2.5, 0, 36), Vector3(2.5, 0, 36), Vector3(-20, 0, 25), Vector3(20, 0, 25)]
# pads: grandes enchem o tanque e voltam em 10 s; pequenos dão 12 e voltam em 4 s
const PADS_GRANDES := [Vector2(-33, -38), Vector2(33, -38), Vector2(-33, 38), Vector2(33, 38), Vector2(-36, 0), Vector2(36, 0)]
const PADS_PEQUENOS := [
	Vector2(0, -12), Vector2(0, 12), Vector2(0, -30), Vector2(0, 30),
	Vector2(-12, -20), Vector2(12, -20), Vector2(-12, 20), Vector2(12, 20), Vector2(-12, 0), Vector2(12, 0),
	Vector2(-24, -10), Vector2(24, -10), Vector2(-24, 10), Vector2(24, 10),
	Vector2(-24, -30), Vector2(24, -30), Vector2(-24, 30), Vector2(24, 30),
	Vector2(-8, -42), Vector2(8, -42), Vector2(-8, 42), Vector2(8, 42),
]

enum Estado { CONTAGEM, JOGANDO, GOL, FIM }

var carro: RigidBody3D
var bola: RigidBody3D
var hud: CanvasLayer
var estado := Estado.CONTAGEM
var tempo_estado := 0.0
var relogio := TEMPO_PARTIDA
var prorrogacao := false
var acabou := false
var placar := {"azul": 0, "laranja": 0}
var pads := []
var tempo_total := 0.0


func _ready() -> void:
	carro = get_node(carro_caminho)
	bola = get_node(bola_caminho)
	hud = get_node(hud_caminho)
	for p in PADS_GRANDES:
		criar_pad(p, true)
	for p in PADS_PEQUENOS:
		criar_pad(p, false)
	saida_de_bola()


func _physics_process(delta: float) -> void:
	tempo_estado += delta
	tempo_total += delta
	atualizar_pads()
	match estado:
		Estado.CONTAGEM:
			var falta := TEMPO_CONTAGEM - tempo_estado
			mensagem(str(ceili(falta)))
			if falta <= 0.0:
				comecar()
		Estado.JOGANDO:
			if tempo_estado < 0.8:
				mensagem("VAI!")
			elif prorrogacao and tempo_estado < 3.0:
				mensagem("PRORROGAÇÃO\nquem fizer o próximo gol ganha")
			else:
				mensagem("")
			if not prorrogacao:
				relogio = maxf(relogio - delta, 0.0)
			ver_gol()
			if estado == Estado.JOGANDO and relogio <= 0.0 and not prorrogacao:
				acabar_tempo()
		Estado.GOL:
			if tempo_estado >= TEMPO_COMEMORACAO:
				if acabou:
					fim_de_jogo()
				else:
					saida_de_bola()
		Estado.FIM:
			if Input.is_action_just_pressed("ui_accept"):
				nova_partida()
	atualizar_placar()


func ver_gol() -> void:
	var b := bola.global_position
	if absf(b.x) > Arena.GOL_LARGURA / 2.0 or b.y > Arena.GOL_ALTURA or absf(b.z) < Arena.COMPRIMENTO / 2.0 + RAIO_BOLA:
		return
	var time := "azul" if b.z < 0.0 else "laranja"
	placar[time] += 1
	acabou = prorrogacao
	estado = Estado.GOL
	tempo_estado = 0.0
	mensagem("GOL DO %s!" % time.to_upper())
	bola.visible = false
	bola.freeze = true


func acabar_tempo() -> void:
	if placar["azul"] == placar["laranja"]:
		prorrogacao = true
		tempo_estado = 0.0
	else:
		fim_de_jogo()


func fim_de_jogo() -> void:
	estado = Estado.FIM
	tempo_estado = 0.0
	carro.travado = true
	var vencedor := "o Azul venceu!" if placar["azul"] > placar["laranja"] else "o Laranja venceu!"
	mensagem("FIM DE JOGO\nAzul %d × %d Laranja: %s\nEnter: jogar de novo" % [placar["azul"], placar["laranja"], vencedor])


func nova_partida() -> void:
	placar = {"azul": 0, "laranja": 0}
	relogio = TEMPO_PARTIDA
	prorrogacao = false
	acabou = false
	saida_de_bola()


func saida_de_bola() -> void:
	var posicao: Vector3 = SAIDAS.pick_random() + Vector3.UP * ALTURA_CARRO
	var para_bola := Vector3(-posicao.x, 0, -posicao.z)
	carro.colocar_em(Transform3D(Basis.looking_at(para_bola), posicao))
	carro.boost = BOOST_SAIDA
	carro.travado = true
	bola.freeze = true
	bola.global_transform = Transform3D(Basis(), Vector3.UP * RAIO_BOLA)
	bola.linear_velocity = Vector3.ZERO
	bola.angular_velocity = Vector3.ZERO
	bola.visible = true
	estado = Estado.CONTAGEM
	tempo_estado = 0.0


func comecar() -> void:
	carro.travado = false
	bola.freeze = false
	estado = Estado.JOGANDO
	tempo_estado = 0.0


func criar_pad(onde: Vector2, grande: bool) -> void:
	var raiz := Node3D.new()
	raiz.position = Vector3(onde.x, 0.0, onde.y)
	var base := MeshInstance3D.new()
	base.mesh = CylinderMesh.new()
	base.mesh.top_radius = 1.6 if grande else 0.9
	base.mesh.bottom_radius = base.mesh.top_radius
	base.mesh.height = 0.04
	base.position.y = 0.02
	var cor_base := StandardMaterial3D.new()
	cor_base.albedo_color = Color(0.25, 0.22, 0.2)
	base.material_override = cor_base
	var brilho := MeshInstance3D.new()
	if grande:
		brilho.mesh = SphereMesh.new()
		brilho.mesh.radius = 0.55
		brilho.mesh.height = 1.1
		brilho.position.y = 1.0
	else:
		brilho.mesh = CylinderMesh.new()
		brilho.mesh.top_radius = 0.45
		brilho.mesh.bottom_radius = 0.45
		brilho.mesh.height = 0.08
		brilho.position.y = 0.06
	var cor := StandardMaterial3D.new()
	cor.albedo_color = Color(1.0, 0.6, 0.15)
	cor.emission_enabled = true
	cor.emission = Color(1.0, 0.5, 0.1)
	cor.emission_energy_multiplier = 2.0
	brilho.material_override = cor
	raiz.add_child(base)
	raiz.add_child(brilho)
	add_child(raiz)
	pads.append({
		"onde": onde,
		"raio": 2.0 if grande else 1.3,
		"quanto": 100.0 if grande else 12.0,
		"espera": 10.0 if grande else 4.0,
		"volta_em": 0.0,
		"brilho": brilho,
	})


func atualizar_pads() -> void:
	var agora := tempo_total
	var p := carro.global_position
	for pad in pads:
		var ativo: bool = agora >= pad["volta_em"]
		pad["brilho"].visible = ativo
		if not ativo or carro.boost >= 100.0 or p.y > 2.5:
			continue
		if Vector2(p.x, p.z).distance_to(pad["onde"]) < pad["raio"]:
			carro.boost = minf(carro.boost + pad["quanto"], 100.0)
			pad["volta_em"] = agora + pad["espera"]


func mensagem(texto: String) -> void:
	hud.get_node("Mensagem").text = texto


func atualizar_placar() -> void:
	var tempo := "PRORROGAÇÃO" if prorrogacao else "%d:%02d" % [floori(ceilf(relogio) / 60.0), int(ceilf(relogio)) % 60]
	hud.get_node("Placar").text = "AZUL  %d  ×  %d  LARANJA\n%s" % [placar["azul"], placar["laranja"], tempo]
