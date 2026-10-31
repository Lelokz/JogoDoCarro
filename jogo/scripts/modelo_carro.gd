class_name ModeloCarro
extends RefCounted

# Os carros, montados por código com a Lataria (curvas de projeto). A frente é o -Z.
# Cada modelo tem o seu desenho, as suas rodas e (como no Rocket League) a sua caixa de batida e o
# lugar das rodas. O resto da física é igual pra todos (motor, pulo, boost, giro no ar, peso).
# As malhas ficam guardadas depois da primeira vez: os carros do mesmo modelo usam a mesma.
# Superfícies "pintura", "turbina", "detalhe" e "aro" cada carro troca pelas suas (time, fogo, detalhes).

class Pecas:
	var pinta := Modelagem.nova()
	var escuro := Modelagem.nova()
	var vidro := Modelagem.nova()
	var farol := Modelagem.nova()
	var lanterna := Modelagem.nova()
	var fogo := Modelagem.nova()
	var detalhe := Modelagem.nova()
	var usou_detalhe := false


# física de cada um: caixa de batida (largura, altura, comprimento), centro da caixa,
# rodas (x pra fora, z da frente, z de trás); a altura da roda é a mesma em todos
const MODELOS := [
	{
		"nome": "Raio",
		"caixa": Vector3(0.80, 0.30, 1.315),
		"centro": Vector3(0.0, -0.02, 0.0),
		"rodas": Vector3(0.40, -0.45, 0.45),
		"turbina": Vector3(0.0, -0.035, 0.665),
		"teto": Vector3(0.0, 0.185, 0.14),        # onde fica o chapéu
		"traseira": Vector3(0.0, 0.115, 0.55),    # tampa de trás (antena e aerofólio)
		"roda": {"largura": 0.11, "aro": 0.135, "raios": 10, "fino": true},
	},
	{
		"nome": "Tanque",
		"caixa": Vector3(0.80, 0.46, 1.24),
		"centro": Vector3(0.0, 0.07, 0.0),
		"rodas": Vector3(0.40, -0.42, 0.42),
		"turbina": Vector3(0.0, -0.05, 0.665),
		"teto": Vector3(0.0, 0.37, 0.15),
		"traseira": Vector3(0.0, 0.135, 0.63),
		"roda": {"largura": 0.15, "aro": 0.1, "raios": 6, "cravos": true},
	},
]
const ALTURA_RODA := -0.08
const ARCO_Y := -0.13     # centro dos arcos das rodas (a roda parada fica uns 6,5 cm abaixo do ponto da mola)
const COMPRESSAO_PARADO := 0.055   # quanto a mola afunda com o carro parado no chão (peso + grude)
const RAIO_PNEU := 0.172
const INERCIA := Vector3(22.83, 31.47, 12.53)   # a mesma pra todos (era a da caixa antiga)

static var malhas_corpo := {}
static var malhas_roda := {}
static var malhas_enfeite := {}


static func dados(modelo: int) -> Dictionary:
	return MODELOS[clampi(modelo, 0, MODELOS.size() - 1)]


static func corpo(modelo := 0) -> ArrayMesh:
	modelo = clampi(modelo, 0, MODELOS.size() - 1)
	if not malhas_corpo.has(modelo):
		malhas_corpo[modelo] = montar_corpo(modelo)
	return malhas_corpo[modelo]


static func roda(modelo := 0) -> ArrayMesh:
	modelo = clampi(modelo, 0, MODELOS.size() - 1)
	if not malhas_roda.has(modelo):
		malhas_roda[modelo] = montar_roda(MODELOS[modelo].roda)
	return malhas_roda[modelo]


static func enfeite(qual: int) -> ArrayMesh:
	# antena, chapéu ou aerofólio (o 0 é sem enfeite). Pedaços "pintura" (cor do time),
	# "escuro" e "detalhe" (cor dos detalhes), que cada carro troca pelos seus
	if qual <= 0:
		return null
	if not malhas_enfeite.has(qual):
		malhas_enfeite[qual] = montar_enfeite(qual)
	return malhas_enfeite[qual]


static func posicao_enfeite(modelo: int, qual: int) -> Vector3:
	# os enfeites foram desenhados num lugar fixo; aqui vão pro teto / traseira de cada carro
	var d := dados(modelo)
	match qual:
		1:
			return d.traseira - Vector3(0.0, 0.11, 0.42) + Vector3(0.0, 0.0, -0.05)
		2:
			return d.teto - Vector3(0.0, 0.244, 0.12)
		3:
			return d.traseira - Vector3(0.0, 0.118, 0.56)
	return Vector3.ZERO


static func pintura(cor: Color) -> ShaderMaterial:
	return Materiais.liso(cor, 0.25, Color.BLACK, 0.0, 0.35)


static func turbina() -> ShaderMaterial:
	return Materiais.liso(Color(0.1, 0.1, 0.1), 0.5, Color(1.0, 0.45, 0.1), 0.5)


static func montar_corpo(modelo: int) -> ArrayMesh:
	var p := Pecas.new()
	match MODELOS[modelo].nome:
		"Raio":
			montar_raio(p)
		"Tanque":
			montar_tanque(p)
	# turbina do boost (o rastro sai dali)
	var t: Vector3 = MODELOS[modelo].turbina
	var deitado := Transform3D(Basis(Vector3.RIGHT, PI / 2.0), t + Vector3(0, 0, -0.06))
	Modelagem.torno(p.escuro, [Vector2(0.075, -0.01), Vector2(0.075, 0.045), Vector2(0.06, 0.05), Vector2(0.055, 0.03)], 20, deitado)
	Modelagem.torno(p.fogo, [Vector2(0.056, 0.032), Vector2(0.0, 0.032)], 20, deitado)

	var malha := ArrayMesh.new()
	Modelagem.adicionar(malha, p.pinta, "pintura", pintura(Color(0.2, 0.45, 0.95)))
	Modelagem.adicionar(malha, p.escuro, "escuro", Materiais.liso(Color(0.035, 0.04, 0.045), 0.45, Color.BLACK, 0.0, 0.3))
	Modelagem.adicionar(malha, p.vidro, "vidro", Materiais.liso(Color(0.02, 0.03, 0.05), 0.06, Color.BLACK, 0.0, 0.7))
	Modelagem.adicionar(malha, p.farol, "farol", Materiais.liso(Color.WHITE, 0.3, Color(0.85, 0.93, 1.0), 4.0))
	Modelagem.adicionar(malha, p.lanterna, "lanterna", Materiais.liso(Color(1.0, 0.1, 0.1), 0.3, Color(1.0, 0.06, 0.04), 3.5))
	Modelagem.adicionar(malha, p.fogo, "turbina", turbina())
	if p.usou_detalhe:
		Modelagem.adicionar(malha, p.detalhe, "detalhe", Materiais.liso(Color(0.78, 0.8, 0.84), 0.22, Color.BLACK, 0.0, 0.9))
	return malha


static func lataria(p: Pecas, peca: Dictionary, arcos := [], espelhar := false) -> void:
	# lataria pintada, com a saia de baixo escura (se a peça tiver "saia")
	var lados := [1.0, -1.0] if espelhar else [1.0]
	for lado in lados:
		var copia := peca.duplicate()
		copia["x"] = peca.get("x", 0.0) * lado
		Lataria.montar(copia, arcos, func(centro: Vector3, _n: Vector3) -> SurfaceTool:
			if peca.has("saia") and centro.y < Lataria.valor(peca.saia, centro.z):
				return p.escuro
			return p.pinta)


static func cabine(p: Pecas, peca: Dictionary, teto_a_partir := 0.86, colunas := []) -> void:
	# vidro em volta; o teto (o que é quase reto em cima) e as colunas [z de, z até] são pintados
	Lataria.montar(peca, [], func(centro: Vector3, n: Vector3) -> SurfaceTool:
		if n.y > teto_a_partir:
			return p.pinta
		for c in colunas:
			if centro.z > c[0] and centro.z < c[1] and absf(n.y) < 0.75:
				return p.pinta
		return p.vidro)


static func arcos(d: Dictionary, raio := 0.2) -> Array:
	return [[d.rodas.y, ARCO_Y, raio], [d.rodas.z, ARCO_Y, raio]]


static func colado(st: SurfaceTool, onde: Vector3, normal: Vector3, tamanho: Vector3, girar := 0.0) -> void:
	# peça fina deitada na lataria (farol, lanterna, entrada de ar), virada pra fora
	var frente := -normal.normalized()
	var cima := Vector3.UP if absf(frente.dot(Vector3.UP)) < 0.95 else Vector3.BACK
	var base := Basis.looking_at(frente, cima) * Basis(Vector3.BACK, girar)
	Modelagem.caixa(st, onde, tamanho, base)


# ---------------------------------------------------------------- Raio
# Superesportivo em cunha: corpo central baixo e estreito entre as rodas, para-lamas em "ombros"
# separados por cima de cada roda (mais altos que o capô), cabine em gota bem pra trás,
# tudo em faces retas. Barra de luz atrás, difusor, entradas de ar nos lados.

const RAIO_CORPO := {
	"reto": false,
	"topo": [[-0.69, -0.075], [-0.62, -0.03], [-0.40, 0.025], [-0.16, 0.065], [0.42, 0.105], [0.60, 0.115], [0.665, 0.085]],
	"fundo": [[-0.69, -0.12], [-0.62, -0.185], [0.60, -0.185], [0.665, -0.15]],
	"cintura": [[-0.69, -0.09], [-0.55, -0.05], [0.0, -0.01], [0.665, 0.02]],
	"largura": [[-0.69, 0.22], [-0.62, 0.3], [-0.28, 0.32], [-0.2, 0.43], [0.2, 0.44], [0.27, 0.33], [0.62, 0.33], [0.665, 0.3]],
	"ombro": [[-0.69, 0.8], [0.665, 0.85]],
	"forma": [[-0.69, 3.0], [0.665, 3.0]],
	"saia": [[-0.69, -0.13], [0.665, -0.09]],
}
const RAIO_PARALAMA_FRENTE := {
	"reto": false,
	"x": 0.36,
	"topo": [[-0.70, -0.06], [-0.63, 0.04], [-0.47, 0.105], [-0.30, 0.095], [-0.12, 0.06]],
	"fundo": [[-0.70, -0.1], [-0.63, -0.175], [-0.12, -0.175]],
	"cintura": [[-0.70, -0.07], [-0.12, 0.0]],
	"largura": [[-0.70, 0.07], [-0.62, 0.11], [-0.2, 0.115], [-0.12, 0.08]],
	"ombro": [[-0.70, 0.75], [-0.12, 0.75]],
	"forma": [[-0.70, 3.0], [-0.12, 3.0]],
	"saia": [[-0.70, -0.13], [-0.12, -0.13]],
}
const RAIO_PARALAMA_TRAS := {
	"reto": false,
	"x": 0.37,
	"topo": [[0.12, 0.02], [0.28, 0.11], [0.45, 0.135], [0.60, 0.125], [0.67, 0.09]],
	"fundo": [[0.12, -0.175], [0.67, -0.15]],
	"cintura": [[0.12, 0.0], [0.67, 0.03]],
	"largura": [[0.12, 0.07], [0.25, 0.115], [0.6, 0.12], [0.67, 0.1]],
	"ombro": [[0.12, 0.7], [0.67, 0.7]],
	"forma": [[0.12, 3.0], [0.67, 3.0]],
	"saia": [[0.12, -0.12], [0.67, -0.09]],
}
const RAIO_CABINE := {
	"reto": false,
	"topo": [[-0.22, 0.04], [-0.02, 0.15], [0.12, 0.183], [0.26, 0.178], [0.50, 0.105]],
	"fundo": [[-0.22, 0.0], [0.50, 0.04]],
	"cintura": [[-0.22, 0.05], [0.50, 0.08]],
	"largura": [[-0.22, 0.29], [0.05, 0.31], [0.35, 0.3], [0.50, 0.24]],
	"ombro": [[-0.22, 0.72], [0.50, 0.7]],
	"forma": [[-0.22, 3.0], [0.50, 3.0]],
}


static func montar_raio(p: Pecas) -> void:
	var d := MODELOS[0] as Dictionary
	lataria(p, RAIO_CORPO)
	lataria(p, RAIO_PARALAMA_FRENTE, arcos(d), true)
	lataria(p, RAIO_PARALAMA_TRAS, arcos(d), true)
	cabine(p, RAIO_CABINE, 0.9, [[0.3, 0.5]])
	for lado in [-1.0, 1.0]:
		# faróis: lâminas finas no bico dos para-lamas, puxadas pra trás
		var f := Lataria.ponto(RAIO_PARALAMA_FRENTE, -0.655, PI / 2.0)
		f.x *= lado
		colado(p.farol, f, Vector3(0.0, 0.8, -1.0), Vector3(0.16, 0.024, 0.012), 0.1 * lado)
		# entrada de ar grande na lateral, atrás da porta
		Modelagem.caixa(p.escuro, Vector3(0.405 * lado, 0.0, 0.2), Vector3(0.03, 0.07, 0.14), Basis(Vector3.UP, deg_to_rad(-12.0 * lado)))
		# saias laterais entre as rodas
		Modelagem.caixa(p.escuro, Vector3(0.44 * lado, -0.165, 0.0), Vector3(0.03, 0.035, 0.42))
		# lanterna em cada para-lama traseiro (liga na barra do meio)
		Modelagem.caixa(p.lanterna, Vector3(0.37 * lado, 0.06, 0.668), Vector3(0.18, 0.016, 0.012))
		# retrovisor
		Modelagem.caixa(p.pinta, Vector3(0.33 * lado, 0.1, -0.13), Vector3(0.06, 0.03, 0.05))
	# barra de luz atrás, de ponta a ponta
	Modelagem.caixa(p.lanterna, Vector3(0.0, 0.06, 0.667), Vector3(0.56, 0.01, 0.012))
	# bico: lâmina escura embaixo e entrada de ar no meio
	Modelagem.caixa(p.escuro, Vector3(0.0, -0.15, -0.67), Vector3(0.78, 0.014, 0.1))
	Modelagem.caixa(p.escuro, Vector3(0.0, -0.075, -0.665), Vector3(0.3, 0.05, 0.03), Basis(Vector3.RIGHT, deg_to_rad(-35.0)))
	# grelha do motor na tampa de trás e difusor
	for k in 5:
		var z := 0.36 + 0.045 * k
		var y := Lataria.valor(RAIO_CORPO.topo, z, true)
		Modelagem.caixa(p.escuro, Vector3(0.0, y + 0.002, z), Vector3(0.36, 0.006, 0.022))
	for x in [-0.27, -0.16, -0.05, 0.05, 0.16, 0.27]:
		Modelagem.caixa(p.escuro, Vector3(x, -0.15, 0.62), Vector3(0.01, 0.07, 0.09))


# ---------------------------------------------------------------- Tanque
# Jipe de trilha: caixa de faces retas, capô reto, para-brisa em pé, teto chato; para-lamas quadrados
# saltados pra fora; grade com barras e faróis redondos; para-choque de impulsão, snorkel, estribo,
# bagageiro com barra de luz e estepe atrás da cabine. Pneu de trilha largo, com cravos.

const TANQUE_CORPO := {
	"reto": true,
	"topo": [[-0.64, 0.07], [-0.625, 0.11], [-0.59, 0.125], [-0.25, 0.135], [0.60, 0.135], [0.64, 0.115]],
	"fundo": [[-0.64, -0.1], [-0.6, -0.165], [0.6, -0.165], [0.64, -0.12]],
	"cintura": [[-0.64, 0.02], [0.64, 0.04]],
	"largura": [[-0.64, 0.34], [-0.61, 0.37], [0.61, 0.37], [0.64, 0.35]],
	"ombro": [[-0.64, 0.96], [0.64, 0.96]],
	"forma": [[-0.64, 8.0], [0.64, 8.0]],
	"saia": [[-0.64, -0.105], [0.64, -0.105]],
}
const TANQUE_CABINE := {
	"reto": true,
	"topo": [[-0.27, 0.13], [-0.19, 0.345], [-0.15, 0.36], [0.49, 0.36], [0.53, 0.33]],
	"fundo": [[-0.27, 0.08], [0.53, 0.08]],
	"cintura": [[-0.27, 0.15], [0.53, 0.15]],
	"largura": [[-0.27, 0.355], [0.53, 0.355]],
	"ombro": [[-0.27, 0.9], [0.53, 0.9]],
	"forma": [[-0.27, 10.0], [0.53, 10.0]],
}


static func paralama_tanque(z: float) -> Dictionary:
	# para-lama quadrado, saltado pra fora da caixa (o arco da roda é recortado nele)
	return {
		"reto": true,
		"x": 0.415,
		"topo": [[z - 0.25, 0.03], [z - 0.21, 0.115], [z + 0.21, 0.115], [z + 0.25, 0.03]],
		"fundo": [[z - 0.25, -0.05], [z + 0.25, -0.05]],
		"cintura": [[z - 0.25, 0.0], [z + 0.25, 0.0]],
		"largura": [[z - 0.25, 0.07], [z + 0.25, 0.07]],
		"ombro": [[z - 0.25, 0.85], [z + 0.25, 0.85]],
		"forma": [[z - 0.25, 6.0], [z + 0.25, 6.0]],
	}


static func montar_tanque(p: Pecas) -> void:
	var d := MODELOS[1] as Dictionary
	var arcos_ := arcos(d, 0.205)
	lataria(p, TANQUE_CORPO, arcos_)
	for z in [d.rodas.y, d.rodas.z]:
		var flare := paralama_tanque(z)
		for lado in [1.0, -1.0]:
			flare["x"] = 0.415 * lado
			Lataria.montar(flare, arcos_, func(_c: Vector3, _n: Vector3) -> SurfaceTool: return p.pinta)
	cabine(p, TANQUE_CABINE, 0.9, [[0.02, 0.09], [0.42, 0.54]])
	p.usou_detalhe = true
	var de_frente := Basis(Vector3.RIGHT, -PI / 2.0)
	# grade: fundo escuro com barras cromadas em pé, entre os faróis redondos
	Modelagem.caixa(p.escuro, Vector3(0.0, 0.035, -0.643), Vector3(0.4, 0.13, 0.008))
	for k in 7:
		Modelagem.caixa(p.detalhe, Vector3(-0.15 + 0.05 * k, 0.035, -0.648), Vector3(0.018, 0.115, 0.008))
	for lado in [-1.0, 1.0]:
		Modelagem.torno(p.farol, meia_bola(0.046), 16, Transform3D(de_frente.scaled(Vector3(1, 1, 0.35)), Vector3(0.27 * lado, 0.045, -0.643)))
		Modelagem.torno(p.detalhe, [Vector2(0.058, -0.004), Vector2(0.058, 0.012), Vector2(0.047, 0.014)], 16, Transform3D(de_frente, Vector3(0.27 * lado, 0.045, -0.642)))
		# piscas e lanternas em pé atrás
		Modelagem.caixa(p.lanterna, Vector3(0.335 * lado, 0.05, 0.643), Vector3(0.05, 0.11, 0.008))
		# retrovisor no braço
		Modelagem.caixa(p.escuro, Vector3(0.39 * lado, 0.2, -0.2), Vector3(0.05, 0.07, 0.02))
		Modelagem.caixa(p.escuro, Vector3(0.365 * lado, 0.17, -0.2), Vector3(0.04, 0.012, 0.012))
		# estribo entre as rodas
		Modelagem.caixa(p.escuro, Vector3(0.41 * lado, -0.13, 0.0), Vector3(0.09, 0.02, 0.36))
		# trilhos do bagageiro
		Modelagem.caixa(p.escuro, Vector3(0.3 * lado, 0.385, 0.18), Vector3(0.025, 0.025, 0.62))
		for z in [-0.08, 0.44]:
			Modelagem.caixa(p.escuro, Vector3(0.3 * lado, 0.372, z), Vector3(0.02, 0.025, 0.02))
	# para-choque de impulsão: barra grossa, quebra-mato cromado na frente da grade
	Modelagem.caixa(p.escuro, Vector3(0.0, -0.075, -0.67), Vector3(0.8, 0.065, 0.06))
	Modelagem.caixa(p.detalhe, Vector3(0.0, 0.1, -0.69), Vector3(0.36, 0.022, 0.022))
	for x in [-0.17, 0.17]:
		Modelagem.caixa(p.detalhe, Vector3(x, 0.02, -0.69), Vector3(0.022, 0.16, 0.022))
	Modelagem.caixa(p.escuro, Vector3(0.0, -0.075, 0.665), Vector3(0.8, 0.06, 0.05))
	# barras do bagageiro e barra de luz na frente do teto
	for z in [0.0, 0.2, 0.4]:
		Modelagem.caixa(p.escuro, Vector3(0.0, 0.39, z), Vector3(0.62, 0.016, 0.02))
	Modelagem.caixa(p.escuro, Vector3(0.0, 0.405, -0.11), Vector3(0.56, 0.05, 0.05))
	for k in 4:
		Modelagem.torno(p.farol, meia_bola(0.019), 12, Transform3D(de_frente.scaled(Vector3(1, 1, 0.4)), Vector3(-0.21 + 0.14 * k, 0.405, -0.136)))
	# snorkel subindo pela coluna da direita
	Modelagem.caixa(p.escuro, Vector3(0.385, 0.05, -0.29), Vector3(0.035, 0.12, 0.035))
	Modelagem.caixa(p.escuro, Vector3(0.375, 0.24, -0.235), Vector3(0.035, 0.3, 0.035), Basis(Vector3.RIGHT, deg_to_rad(-14.0)))
	Modelagem.caixa(p.escuro, Vector3(0.37, 0.39, -0.28), Vector3(0.045, 0.04, 0.08))
	# estepe pendurado atrás da cabine
	var estepe := Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(0.0, 0.24, 0.585))
	Modelagem.torno(p.escuro, [Vector2(0.06, -0.05), Vector2(0.11, -0.055), Vector2(0.125, -0.03), Vector2(0.125, 0.03), Vector2(0.11, 0.055), Vector2(0.06, 0.05)], 24, estepe)
	Modelagem.torno(p.detalhe, [Vector2(0.065, 0.045), Vector2(0.0, 0.04)], 20, estepe)
	# capô: duas entradas de ar
	for x in [-0.12, 0.12]:
		Modelagem.caixa(p.escuro, Vector3(x, 0.139, -0.42), Vector3(0.1, 0.008, 0.12))


# ---------------------------------------------------------------- rodas

static func montar_roda(r: Dictionary) -> ArrayMesh:
	# eixo da roda no Y (o carro.gd deita e gira ela); os dois lados iguais
	var borracha := Modelagem.nova()
	var aro := Modelagem.nova()
	var fundo := Modelagem.nova()
	var w: float = r.largura / 2.0
	var a: float = r.aro
	var R := RAIO_PNEU
	var pneu := [Vector2(a - 0.004, -w + 0.004), Vector2(R - 0.018, -w), Vector2(R - 0.006, -w + 0.008), Vector2(R, -w * 0.45),
		Vector2(R + 0.001, 0.0), Vector2(R, w * 0.45), Vector2(R - 0.006, w - 0.008), Vector2(R - 0.018, w), Vector2(a - 0.004, w - 0.004)]
	Modelagem.torno(borracha, pneu, 32)
	var borda := [Vector2(a + 0.002, w - 0.002), Vector2(a - 0.008, w - 0.002), Vector2(a - 0.016, w - 0.01)]
	var cubo := [Vector2(0.03, w - 0.016), Vector2(0.026, w - 0.004), Vector2(0.0, w - 0.002)]
	var prato := [Vector2(a - 0.016, w - 0.01), Vector2(a - 0.02, w - 0.03), Vector2(0.0, w - 0.034)]
	for perfil in [borda, cubo]:
		Modelagem.torno(aro, perfil, 32)
		Modelagem.torno(aro, Modelagem.espelhar(perfil), 32)
	Modelagem.torno(fundo, prato, 32)
	Modelagem.torno(fundo, Modelagem.espelhar(prato), 32)
	var n: int = r.raios
	var comprimento := a - 0.04
	for lado in [-1.0, 1.0]:
		for k in n:
			var giro := Basis(Vector3.UP, TAU * k / n)
			var largura_raio := 0.012 if r.get("fino", false) else 0.024
			Modelagem.caixa(aro, giro * Vector3(0.0, (w - 0.014) * lado, 0.03 + comprimento / 2.0), Vector3(largura_raio, 0.012, comprimento), giro)
	if r.get("cravos", false):
		# blocos de borracha em volta do pneu, alternados (pneu de trilha)
		for k in 22:
			var giro := Basis(Vector3.UP, TAU * k / 22.0)
			var lado := 1.0 if k % 2 == 0 else -1.0
			Modelagem.caixa(borracha, giro * Vector3(0.0, w * 0.45 * lado, R + 0.002), Vector3(0.04, w * 0.5, 0.016), giro)
			Modelagem.caixa(borracha, giro * Vector3(0.0, -w * 0.25 * lado, R + 0.002), Vector3(0.03, w * 0.4, 0.014), giro)
	var malha := ArrayMesh.new()
	Modelagem.adicionar(malha, borracha, "pneu", Materiais.liso(Color(0.045, 0.045, 0.05), 0.85))
	Modelagem.adicionar(malha, aro, "aro", Materiais.liso(Color(0.78, 0.8, 0.84), 0.22, Color.BLACK, 0.0, 0.9))
	Modelagem.adicionar(malha, fundo, "fundo do aro", Materiais.liso(Color(0.06, 0.065, 0.07), 0.4, Color.BLACK, 0.0, 0.6))
	return malha


# ---------------------------------------------------------------- enfeites

static func montar_enfeite(qual: int) -> ArrayMesh:
	var pinta := Modelagem.nova()
	var escuro := Modelagem.nova()
	var detalhe := Modelagem.nova()
	match qual:
		1:
			# antena atrás à direita, com bolinha na ponta e bandeirinha do time
			var pe := Vector3(0.3, 0.11, 0.42)
			var giro := Basis(Vector3.RIGHT, deg_to_rad(-12.0))
			Modelagem.caixa(escuro, pe + giro * Vector3(0, 0.2, 0), Vector3(0.012, 0.4, 0.012), giro)
			var ponta := pe + giro * Vector3(0, 0.4, 0)
			Modelagem.torno(detalhe, meia_bola(0.026), 12, Transform3D(Basis(), ponta))
			Modelagem.caixa(pinta, pe + giro * Vector3(0, 0.33, 0.075), Vector3(0.006, 0.09, 0.14), giro)
		2:
			# cartola em cima do teto, meio de lado
			var onde := Transform3D(Basis(Vector3.BACK, deg_to_rad(-8.0)), Vector3(0.0, 0.244, 0.12))
			Modelagem.torno(escuro, [Vector2(0.0, 0.0), Vector2(0.16, 0.0), Vector2(0.16, 0.014), Vector2(0.095, 0.016), Vector2(0.1, 0.175), Vector2(0.0, 0.175)], 24, onde)
			Modelagem.torno(detalhe, [Vector2(0.0975, 0.03), Vector2(0.0985, 0.065)], 24, onde)
		3:
			# aerofólio alto de corrida (vai ser refeito depois dos carros novos)
			var inclinado := Basis(Vector3.RIGHT, deg_to_rad(-9.0))
			Modelagem.caixa(pinta, Vector3(0.0, 0.37, 0.57), Vector3(0.86, 0.02, 0.17), inclinado)
			for x in [-0.22, 0.22]:
				Modelagem.caixa(escuro, Vector3(x, 0.26, 0.56), Vector3(0.018, 0.21, 0.045))
			for x in [-0.435, 0.435]:
				Modelagem.caixa(detalhe, Vector3(x, 0.365, 0.575), Vector3(0.012, 0.07, 0.2))
	var malha := ArrayMesh.new()
	Modelagem.adicionar(malha, escuro, "escuro", Materiais.liso(Color(0.035, 0.04, 0.045), 0.45, Color.BLACK, 0.0, 0.3))
	Modelagem.adicionar(malha, detalhe, "detalhe", Materiais.liso(Color(0.78, 0.8, 0.84), 0.22, Color.BLACK, 0.0, 0.9))
	if qual != 2:
		Modelagem.adicionar(malha, pinta, "pintura", pintura(Color(0.2, 0.45, 0.95)))
	return malha


static func meia_bola(raio: float) -> Array:
	# perfil do torno pra uma bolinha: de baixo pra cima pelo lado de fora
	var perfil := []
	for k in 9:
		var a := PI * k / 8.0
		perfil.append(Vector2(raio * sin(a), -raio * cos(a)))
	return perfil
