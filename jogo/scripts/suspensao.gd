class_name Suspensao
extends Node3D

# A suspensão desenhada de cada carro, ligando as rodas ao chassi e se mexendo junto com elas
# (a mola é a da física: roda que sobe aperta a mola, roda no ar fica pendurada nos braços).
#   bandeja: braço de cima e de baixo em A, manga de eixo, amortecedor com a mola em volta,
#            semieixo até o diferencial e, na frente, a barra de direção (vira junto com a roda);
#   eixo:    eixo rígido de jipe (Tanque): tubo de uma roda à outra com o diferencial no meio,
#            braços puxados até o chassi, amortecedores e cardã.
# Tudo é feito de tubos: cada material é um MultiMesh só (3 desenhos por carro, não 40).
# A mola usa o material de detalhe do carro (a cor que a pessoa escolheu).

const LADOS := [-1.0, 1.0, -1.0, 1.0]   # RodaFE, RodaFD, RodaTE, RodaTD

var tipo := "bandeja"
var chassi := 0.16        # meia largura do chassi, onde os braços prendem
var larguras := [0.11, 0.11, 0.11, 0.11]
var repouso := Vector3.ZERO   # y do centro da roda com o carro parado (pra prender os braços na altura certa)
var lugares := []             # centro de cada roda parada
var escuro := MultiMeshInstance3D.new()
var cromo := MultiMeshInstance3D.new()
var molas := MultiMeshInstance3D.new()

var mola_parada := 0.15       # comprimento da mola com o carro parado (a malha é feita com ele)

static var malha_tubo: ArrayMesh
static var malhas_mola := {}


func _ready() -> void:
	if malha_tubo == null:
		malha_tubo = tubo_unitario()
	for grupo in [[escuro, malha_tubo, Materiais.liso(Color(0.3, 0.31, 0.33), 0.35, Color.BLACK, 0.0, 0.75)],
			[cromo, malha_tubo, Materiais.liso(Color(0.85, 0.86, 0.88), 0.15, Color.BLACK, 0.0, 0.95)],
			[molas, null, null]]:
		var no: MultiMeshInstance3D = grupo[0]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = grupo[1]
		no.multimesh = mm
		if grupo[2]:
			no.material_override = grupo[2]
		add_child(no)


func montar(modelo: int, rodas: Array, detalhe: Material, altura_parado: float) -> void:
	# rodas: o lugar de cada uma (Marker do carro); altura_parado: y do centro da roda parada no chão
	var d := ModeloCarro.dados(modelo)
	tipo = d.suspensao.tipo
	chassi = d.suspensao.chassi
	molas.material_override = detalhe
	lugares.clear()
	for i in 4:
		var r: Dictionary = d.roda_tras if i >= 2 and d.has("roda_tras") else d.roda
		larguras[i] = r.largura
		lugares.append(Vector3(rodas[i].x, altura_parado, rodas[i].z))
	# quantas peças de cada tipo: monta uma vez com as rodas paradas e conta
	var pecas := montar_pecas(lugares, 0.0)
	var primeira: Array = pecas.mola[0]
	mola_parada = primeira[0].distance_to(primeira[1])
	molas.multimesh.mesh = mola(mola_parada, primeira[2])
	for grupo in [[escuro, "escuro"], [cromo, "cromo"], [molas, "mola"]]:
		grupo[0].multimesh.instance_count = pecas[grupo[1]].size()
	desenhar(pecas)


func atualizar(centros: Array, angulo: float) -> void:
	# centros: onde está o centro de cada roda agora (no carro); angulo: quanto as da frente viraram
	if lugares.is_empty():
		return
	desenhar(montar_pecas(centros, angulo))


func desenhar(pecas: Dictionary) -> void:
	for grupo in [[escuro, "escuro"], [cromo, "cromo"], [molas, "mola"]]:
		var mm: MultiMesh = grupo[0].multimesh
		var lista: Array = pecas[grupo[1]]
		for k in mini(lista.size(), mm.instance_count):
			var a: Vector3 = lista[k][0]
			var b: Vector3 = lista[k][1]
			if grupo[0] == molas:
				mm.set_instance_transform(k, ligando(a, b, 1.0, a.distance_to(b) / mola_parada))
			else:
				mm.set_instance_transform(k, ligando(a, b, lista[k][2], b.distance_to(a)))


func ligando(a: Vector3, b: Vector3, raio: float, comprimento: float) -> Transform3D:
	# peça feita no X (tubo de raio 1 e comprimento 1, ou a mola), esticada de "a" até "b"
	var v := b - a
	var u := v.normalized() if v.length() > 0.0001 else Vector3.RIGHT
	var ref := Vector3.UP if absf(u.y) < 0.9 else Vector3.BACK
	var n1 := u.cross(ref).normalized()
	var n2 := u.cross(n1)
	return Transform3D(Basis(u * comprimento, n1 * raio, n2 * raio), a)


func montar_pecas(centros: Array, angulo: float) -> Dictionary:
	var pecas := {"escuro": [], "cromo": [], "mola": []}
	if tipo == "eixo":
		eixo_rigido(pecas, centros, angulo, 0)
		eixo_rigido(pecas, centros, angulo, 2)
	else:
		for i in 4:
			bandejas(pecas, i, centros[i], angulo if i < 2 else 0.0)
	return pecas


func bandejas(pecas: Dictionary, i: int, c: Vector3, angulo: float) -> void:
	var s: float = LADOS[i]
	var z: float = lugares[i].z
	var y0: float = lugares[i].y
	var giro := Basis(Vector3.UP, angulo)
	# manga de eixo: logo pra dentro do pneu, vira junto com a roda
	var dentro := Vector3(-s * (larguras[i] / 2.0 + 0.012), 0.0, 0.0)
	var manga := c + giro * dentro
	var junta_cima := c + giro * (dentro + Vector3(0.0, 0.065, 0.0))
	var junta_baixo := c + giro * (dentro + Vector3(0.0, -0.07, 0.0))
	pecas.escuro.append([junta_baixo, junta_cima, 0.016])
	pecas.escuro.append([manga, c, 0.03])
	# braços em A: duas pernas presas no chassi (na altura da roda parada), juntando na manga
	for dz in [-0.08, 0.08]:
		pecas.escuro.append([Vector3(s * chassi, y0 - 0.03, z + dz), junta_baixo, 0.011])
	for dz in [-0.06, 0.06]:
		pecas.escuro.append([Vector3(s * (chassi + 0.01), y0 + 0.075, z + dz), junta_cima, 0.009])
	# amortecedor com mola: de baixo (no braço de baixo, perto da roda) até o chassi lá em cima
	var baixo := Vector3(s * chassi, y0 - 0.03, z).lerp(junta_baixo, 0.72)
	var cima := Vector3(s * (chassi + 0.03), y0 + 0.17, z)
	amortecedor(pecas, baixo, cima)
	# semieixo do diferencial até a roda, com as coifas de borracha nas pontas
	var diferencial := Vector3(s * (chassi - 0.04), y0 - 0.005, z)
	pecas.cromo.append([diferencial, manga, 0.011])
	var u := (manga - diferencial).normalized()
	pecas.escuro.append([diferencial, diferencial + u * 0.04, 0.02])
	pecas.escuro.append([manga - u * 0.04, manga, 0.02])
	if i < 2:
		# barra de direção: da caixa (no chassi) até o braço da manga, que vira com a roda
		var braco := Vector3(0.0, -0.015, 0.075)
		var ponta := c + giro * (dentro + braco)
		var ponta_reta: Vector3 = lugares[i] + dentro + braco
		var caixa := Vector3(s * (chassi - 0.02) + (ponta.x - ponta_reta.x), ponta_reta.y, ponta_reta.z)
		pecas.escuro.append([caixa, ponta, 0.008])
		pecas.escuro.append([manga + giro * Vector3(0.0, -0.015, 0.0), ponta, 0.01])


func eixo_rigido(pecas: Dictionary, centros: Array, angulo: float, primeira: int) -> void:
	# as duas rodas do eixo (esquerda e direita) presas no mesmo tubo: se uma sobe, o tubo inclina
	var esq: Vector3 = centros[primeira]
	var dir: Vector3 = centros[primeira + 1]
	var ponta_esq := esq + Vector3(larguras[primeira] / 2.0 + 0.02, 0.0, 0.0)
	var ponta_dir := dir - Vector3(larguras[primeira + 1] / 2.0 + 0.02, 0.0, 0.0)
	var z: float = lugares[primeira].z
	var y0: float = lugares[primeira].y
	var para_dentro := signf(-z)   # do eixo pro meio do carro
	pecas.escuro.append([ponta_esq, ponta_dir, 0.03])
	var meio := (ponta_esq + ponta_dir) / 2.0
	pecas.escuro.append([meio + Vector3(0, 0, -0.06), meio + Vector3(0, 0, 0.06), 0.075])
	pecas.escuro.append([esq, ponta_esq, 0.04])
	pecas.escuro.append([dir, ponta_dir, 0.04])
	# cardã do diferencial até o meio do carro
	pecas.cromo.append([meio + Vector3(0, 0, 0.06 * para_dentro), Vector3(0.0, y0 + 0.02, z + para_dentro * 0.36), 0.016])
	for lado in [-1.0, 1.0]:
		var no_eixo := ponta_esq.lerp(ponta_dir, 0.5 + lado * 0.22)
		# braços puxados (de baixo e de cima) até o chassi, mais pro meio do carro
		pecas.escuro.append([Vector3(lado * 0.2, y0 - 0.0, z + para_dentro * 0.3), no_eixo + Vector3(0, -0.035, 0), 0.013])
		pecas.escuro.append([Vector3(lado * 0.1, y0 + 0.08, z + para_dentro * 0.25), meio + Vector3(lado * 0.06, 0.04, 0), 0.011])
		amortecedor(pecas, ponta_esq.lerp(ponta_dir, 0.5 + lado * 0.36) + Vector3(0, 0.03, -para_dentro * 0.05), Vector3(lado * 0.24, y0 + 0.22, z - para_dentro * 0.03))
	if primeira == 0:
		# barra de direção de uma roda à outra, atrás do eixo, virando junto
		var giro := Basis(Vector3.UP, angulo)
		var braco := Vector3(0.0, -0.02, 0.09)
		pecas.escuro.append([esq + giro * (Vector3(larguras[0] / 2.0 + 0.02, 0, 0) + braco), dir + giro * (Vector3(-larguras[1] / 2.0 - 0.02, 0, 0) + braco), 0.01])


func amortecedor(pecas: Dictionary, baixo: Vector3, cima: Vector3) -> void:
	# corpo grosso preso em cima, haste cromada presa embaixo (um entra no outro) e a mola em volta
	var u := (cima - baixo).normalized()
	var comprimento := baixo.distance_to(cima)
	pecas.escuro.append([cima, cima - u * comprimento * 0.5, 0.019])
	pecas.cromo.append([baixo, baixo + u * comprimento * 0.6, 0.007])
	pecas.escuro.append([baixo, baixo + u * 0.025, 0.013])
	pecas.escuro.append([cima - u * comprimento * 0.12, cima - u * comprimento * 0.12 + u * 0.008, 0.034])
	pecas.escuro.append([baixo + u * 0.03, baixo + u * 0.038, 0.034])
	pecas.mola.append([baixo + u * 0.038, cima - u * comprimento * 0.12, 0.028])


static func tubo_unitario() -> ArrayMesh:
	# tubo de raio 1 do X=0 ao X=1, com tampas (cantos duplicados: a tampa fica reta, não arredondada)
	var st := Modelagem.nova()
	var perfil := [Vector2(0, 0), Vector2(1, 0), Vector2(1, 0), Vector2(1, 1), Vector2(1, 1), Vector2(0, 1)]
	Modelagem.torno(st, perfil, 10, Transform3D(Basis(Vector3.BACK, -PI / 2.0), Vector3.ZERO))
	return st.commit()


static func mola(comprimento: float, raio: float) -> ArrayMesh:
	# mola em espiral do X=0 ao X=comprimento (o tamanho dela com o carro parado): esticada ou
	# apertada, o carro só muda o passo (o fio continua da mesma grossura)
	var chave := "%.3f %.3f" % [comprimento, raio]
	if malhas_mola.has(chave):
		return malhas_mola[chave]
	var st := Modelagem.nova()
	var voltas := 6.0
	var passos := 96
	var fio := 0.0045
	var lados := 6
	var aneis := []
	for k in passos + 1:
		var t := float(k) / passos
		var a := t * voltas * TAU
		var radial := Vector3(0.0, cos(a), sin(a))
		var tangente := Vector3(comprimento / (voltas * TAU * raio), -sin(a), cos(a)).normalized()
		var outro := tangente.cross(radial)
		var anel := []
		for j in lados:
			var b := TAU * j / lados
			var n := radial * cos(b) + outro * sin(b)
			anel.append([Vector3(t * comprimento, 0, 0) + radial * raio + n * fio, n])
		aneis.append(anel)
	for k in passos:
		for j in lados:
			var a0: Array = aneis[k][j]
			var a1: Array = aneis[k][(j + 1) % lados]
			var b1: Array = aneis[k + 1][(j + 1) % lados]
			var b0: Array = aneis[k + 1][j]
			Modelagem.quadrado(st, [a0[0], a1[0], b1[0], b0[0]], [a0[1], a1[1], b1[1], b0[1]])
	malhas_mola[chave] = st.commit()
	return malhas_mola[chave]
