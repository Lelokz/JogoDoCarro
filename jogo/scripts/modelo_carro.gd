class_name ModeloCarro
extends RefCounted

# O desenho dos carros, montado por código. É só aparência: a colisão continua sendo a caixa do carro.tscn
# (0,84 × 0,36 × 1,18 m) e as rodas continuam onde a suspensão manda. A frente é o -Z.
# São 5 modelos (Padrão, Raio, Tanque, Besouro, Flecha), todos com a mesma física.
# As malhas ficam guardadas depois da primeira vez: os carros do mesmo modelo usam a mesma.
# Superfícies "pintura", "turbina" e "detalhe" cada carro troca pelas suas (cor do time, fogo, detalhes).

static var malhas_corpo := {}
static var malha_roda: ArrayMesh
static var malhas_enfeite := {}

# cortes da carroceria, da frente pra trás: [z, meia largura embaixo, em cima, y de baixo, y de cima, raio embaixo, em cima]
const CARROCERIA := [
	[-0.600, 0.30, 0.26, -0.120, -0.050, 0.02, 0.03],
	[-0.588, 0.36, 0.32, -0.135, -0.022, 0.03, 0.05],
	[-0.555, 0.40, 0.36, -0.140, 0.005, 0.03, 0.06],
	[-0.470, 0.42, 0.38, -0.140, 0.040, 0.03, 0.07],
	[-0.300, 0.42, 0.38, -0.140, 0.078, 0.03, 0.08],
	[-0.100, 0.415, 0.37, -0.140, 0.100, 0.03, 0.08],
	[0.150, 0.415, 0.37, -0.140, 0.112, 0.03, 0.08],
	[0.400, 0.42, 0.38, -0.140, 0.118, 0.03, 0.07],
	[0.540, 0.41, 0.37, -0.135, 0.112, 0.03, 0.06],
	[0.588, 0.38, 0.34, -0.125, 0.098, 0.03, 0.05],
	[0.605, 0.34, 0.30, -0.110, 0.080, 0.02, 0.04],
]
# cabine de vidro
const CABINE := [
	[-0.210, 0.33, 0.30, 0.050, 0.082, 0.01, 0.02],
	[-0.120, 0.33, 0.28, 0.050, 0.170, 0.01, 0.05],
	[-0.020, 0.32, 0.26, 0.050, 0.232, 0.01, 0.07],
	[0.100, 0.32, 0.25, 0.050, 0.252, 0.01, 0.08],
	[0.240, 0.32, 0.25, 0.050, 0.244, 0.01, 0.08],
	[0.360, 0.33, 0.27, 0.050, 0.190, 0.01, 0.06],
	[0.460, 0.34, 0.30, 0.050, 0.125, 0.01, 0.03],
]
# Raio: baixo e largo, nariz em cunha
const CARROCERIA_RAIO := [
	[-0.620, 0.30, 0.26, -0.130, -0.075, 0.02, 0.02],
	[-0.600, 0.38, 0.34, -0.140, -0.050, 0.03, 0.04],
	[-0.540, 0.43, 0.39, -0.145, -0.020, 0.03, 0.05],
	[-0.400, 0.44, 0.40, -0.145, 0.010, 0.03, 0.06],
	[-0.200, 0.44, 0.40, -0.145, 0.040, 0.03, 0.06],
	[0.100, 0.44, 0.40, -0.145, 0.060, 0.03, 0.06],
	[0.400, 0.45, 0.41, -0.145, 0.075, 0.03, 0.05],
	[0.550, 0.44, 0.40, -0.140, 0.080, 0.03, 0.04],
	[0.600, 0.40, 0.37, -0.130, 0.075, 0.02, 0.03],
]
const CABINE_RAIO := [
	[-0.150, 0.34, 0.31, 0.020, 0.050, 0.01, 0.02],
	[-0.060, 0.34, 0.29, 0.020, 0.120, 0.01, 0.05],
	[0.040, 0.33, 0.27, 0.020, 0.165, 0.01, 0.07],
	[0.160, 0.33, 0.26, 0.020, 0.175, 0.01, 0.08],
	[0.280, 0.33, 0.27, 0.020, 0.150, 0.01, 0.06],
	[0.380, 0.34, 0.30, 0.020, 0.100, 0.01, 0.03],
	[0.460, 0.35, 0.33, 0.020, 0.070, 0.01, 0.01],
]
# Tanque: alto e quadradão
const CARROCERIA_TANQUE := [
	[-0.600, 0.40, 0.39, -0.140, 0.080, 0.015, 0.02],
	[-0.585, 0.42, 0.41, -0.150, 0.110, 0.015, 0.025],
	[-0.450, 0.43, 0.42, -0.150, 0.130, 0.015, 0.025],
	[0.000, 0.43, 0.42, -0.150, 0.140, 0.015, 0.025],
	[0.450, 0.43, 0.42, -0.150, 0.140, 0.015, 0.025],
	[0.585, 0.42, 0.41, -0.150, 0.130, 0.015, 0.025],
	[0.600, 0.40, 0.39, -0.140, 0.110, 0.015, 0.02],
]
const CABINE_TANQUE := [
	[-0.220, 0.38, 0.37, 0.100, 0.150, 0.01, 0.01],
	[-0.140, 0.38, 0.35, 0.100, 0.310, 0.01, 0.02],
	[-0.080, 0.38, 0.35, 0.100, 0.330, 0.01, 0.02],
	[0.200, 0.38, 0.35, 0.100, 0.335, 0.01, 0.02],
	[0.480, 0.38, 0.35, 0.100, 0.330, 0.01, 0.02],
	[0.520, 0.38, 0.36, 0.100, 0.300, 0.01, 0.01],
]
# Besouro: tudo arredondado, cabine em domo
const CARROCERIA_BESOURO := [
	[-0.605, 0.26, 0.20, -0.120, 0.000, 0.03, 0.07],
	[-0.580, 0.36, 0.30, -0.135, 0.040, 0.04, 0.10],
	[-0.500, 0.41, 0.35, -0.140, 0.070, 0.04, 0.12],
	[-0.300, 0.42, 0.37, -0.140, 0.090, 0.04, 0.13],
	[0.000, 0.42, 0.37, -0.140, 0.100, 0.04, 0.13],
	[0.300, 0.42, 0.37, -0.140, 0.100, 0.04, 0.13],
	[0.500, 0.41, 0.35, -0.140, 0.090, 0.04, 0.12],
	[0.580, 0.37, 0.30, -0.135, 0.060, 0.04, 0.10],
	[0.605, 0.28, 0.22, -0.120, 0.020, 0.03, 0.07],
]
const CABINE_BESOURO := [
	[-0.240, 0.30, 0.26, 0.060, 0.090, 0.01, 0.02],
	[-0.160, 0.31, 0.25, 0.060, 0.190, 0.01, 0.08],
	[-0.050, 0.31, 0.24, 0.060, 0.260, 0.01, 0.11],
	[0.100, 0.31, 0.23, 0.060, 0.285, 0.01, 0.12],
	[0.250, 0.31, 0.23, 0.060, 0.270, 0.01, 0.11],
	[0.360, 0.31, 0.25, 0.060, 0.210, 0.01, 0.08],
	[0.440, 0.31, 0.27, 0.060, 0.120, 0.01, 0.03],
]
# Flecha: comprido e bicudo, tipo carro de arrancada (traseira larga, cabine pequena lá atrás)
const CARROCERIA_FLECHA := [
	[-0.740, 0.08, 0.06, -0.100, -0.060, 0.02, 0.02],
	[-0.700, 0.16, 0.13, -0.120, -0.040, 0.02, 0.03],
	[-0.600, 0.26, 0.22, -0.130, -0.010, 0.03, 0.04],
	[-0.450, 0.33, 0.28, -0.140, 0.020, 0.03, 0.05],
	[-0.250, 0.37, 0.32, -0.140, 0.050, 0.03, 0.06],
	[0.000, 0.40, 0.35, -0.140, 0.080, 0.03, 0.07],
	[0.300, 0.43, 0.38, -0.140, 0.100, 0.03, 0.07],
	[0.520, 0.44, 0.40, -0.140, 0.110, 0.03, 0.06],
	[0.585, 0.42, 0.38, -0.130, 0.100, 0.03, 0.05],
	[0.605, 0.38, 0.34, -0.120, 0.085, 0.02, 0.04],
]
const CABINE_FLECHA := [
	[-0.020, 0.28, 0.26, 0.060, 0.100, 0.01, 0.02],
	[0.060, 0.28, 0.24, 0.060, 0.190, 0.01, 0.06],
	[0.150, 0.28, 0.22, 0.060, 0.235, 0.01, 0.08],
	[0.270, 0.28, 0.22, 0.060, 0.240, 0.01, 0.08],
	[0.370, 0.29, 0.24, 0.060, 0.200, 0.01, 0.06],
	[0.450, 0.30, 0.27, 0.060, 0.130, 0.01, 0.03],
]
const FORMAS := [
	{"carroceria": CARROCERIA, "cabine": CABINE},
	{"carroceria": CARROCERIA_RAIO, "cabine": CABINE_RAIO},
	{"carroceria": CARROCERIA_TANQUE, "cabine": CABINE_TANQUE},
	{"carroceria": CARROCERIA_BESOURO, "cabine": CABINE_BESOURO},
	{"carroceria": CARROCERIA_FLECHA, "cabine": CABINE_FLECHA},
]
# quanto cada enfeite sobe ou desce em cada modelo (antena, chapéu, aerofólio): o teto muda de altura
const ALTURA_ENFEITE := [[0.0, 0.0, 0.0], [-0.03, -0.077, -0.03], [0.22, 0.083, 0.0], [0.0, 0.033, -0.03], [0.0, -0.012, 0.08]]
const ALTURA_SAIA := -0.065   # abaixo disso a lateral é escura
const RODAS := [Vector3(-0.46, -0.08, -0.42), Vector3(0.46, -0.08, -0.42), Vector3(-0.46, -0.08, 0.42), Vector3(0.46, -0.08, 0.42)]


static func corpo(modelo := 0) -> ArrayMesh:
	modelo = clampi(modelo, 0, FORMAS.size() - 1)
	if not malhas_corpo.has(modelo):
		malhas_corpo[modelo] = montar_corpo(modelo)
	return malhas_corpo[modelo]


static func roda() -> ArrayMesh:
	if malha_roda == null:
		malha_roda = montar_roda()
	return malha_roda


static func enfeite(qual: int) -> ArrayMesh:
	# antena, chapéu ou aerofólio (o 0 é sem enfeite). Pedaços "pintura" (cor do time),
	# "escuro" e "detalhe" (cor dos detalhes), que cada carro troca pelos seus
	if qual <= 0:
		return null
	if not malhas_enfeite.has(qual):
		malhas_enfeite[qual] = montar_enfeite(qual)
	return malhas_enfeite[qual]


static func pintura(cor: Color) -> ShaderMaterial:
	return Materiais.liso(cor, 0.25, Color.BLACK, 0.0, 0.35)


static func turbina() -> ShaderMaterial:
	return Materiais.liso(Color(0.1, 0.1, 0.1), 0.5, Color(1.0, 0.45, 0.1), 0.5)


static func montar_corpo(modelo: int) -> ArrayMesh:
	var pinta := Modelagem.nova()
	var escuro := Modelagem.nova()
	var vidro := Modelagem.nova()
	var farol := Modelagem.nova()
	var lanterna := Modelagem.nova()
	var fogo := Modelagem.nova()
	var detalhe := Modelagem.nova()
	var forma: Dictionary = FORMAS[modelo]

	# carroceria: em cima pintada, a saia de baixo escura
	var cortes := []
	for s in forma.carroceria:
		cortes.append(Modelagem.secao(s + [ALTURA_SAIA]))
	var total := Modelagem.PONTOS_CORTE
	Modelagem.costurar(pinta, cortes, Modelagem.indices(Modelagem.LADO_DIREITO, Modelagem.LADO_ESQUERDO, total))
	Modelagem.costurar(escuro, cortes, Modelagem.indices(Modelagem.LADO_ESQUERDO, total + Modelagem.LADO_DIREITO, total))
	Modelagem.tampa(escuro, cortes[0], Vector3.FORWARD, 0.01)
	Modelagem.tampa(escuro, cortes[-1], Vector3.BACK, 0.005)

	# cabine de vidro e o teto pintado por cima (o vidro aparece na frente, atrás e dos lados)
	var cortes_cabine := []
	for s in forma.cabine:
		cortes_cabine.append(Modelagem.secao(s))
	Modelagem.costurar(vidro, cortes_cabine, Modelagem.indices(0, total, total))
	Modelagem.tampa(vidro, cortes_cabine[-1], Vector3.BACK)
	var cortes_teto := []
	for s in forma.cabine.slice(2, 5):
		cortes_teto.append(Modelagem.secao([s[0], s[1], s[2] * 0.82, s[3], s[4] + 0.004, s[5], s[6] * 0.8]))
	Modelagem.costurar(pinta, cortes_teto, Modelagem.indices(Modelagem.LADO_DIREITO + 1, Modelagem.LADO_ESQUERDO - 1, total))

	match modelo:
		1:
			detalhes_raio(pinta, escuro, farol, lanterna)
		2:
			detalhes_tanque(pinta, escuro, farol, lanterna, detalhe)
		3:
			detalhes_besouro(pinta, escuro, farol, lanterna, detalhe)
		4:
			detalhes_flecha(pinta, escuro, farol, lanterna, detalhe)
		_:
			detalhes_padrao(pinta, escuro, farol, lanterna)

	# turbina do boost (no mesmo lugar em todos: o rastro sai dali)
	var deitado := Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(0.0, -0.03, 0.6))
	Modelagem.torno(escuro, [Vector2(0.075, -0.01), Vector2(0.075, 0.045), Vector2(0.06, 0.05), Vector2(0.055, 0.03)], 20, deitado)
	Modelagem.torno(fogo, [Vector2(0.056, 0.032), Vector2(0.0, 0.032)], 20, deitado)

	var malha := ArrayMesh.new()
	Modelagem.adicionar(malha, pinta, "pintura", pintura(Color(0.2, 0.45, 0.95)))
	Modelagem.adicionar(malha, escuro, "escuro", Materiais.liso(Color(0.035, 0.04, 0.045), 0.45, Color.BLACK, 0.0, 0.3))
	Modelagem.adicionar(malha, vidro, "vidro", Materiais.liso(Color(0.02, 0.03, 0.05), 0.06, Color.BLACK, 0.0, 0.7))
	Modelagem.adicionar(malha, farol, "farol", Materiais.liso(Color.WHITE, 0.3, Color(0.85, 0.93, 1.0), 4.0))
	Modelagem.adicionar(malha, lanterna, "lanterna", Materiais.liso(Color(1.0, 0.1, 0.1), 0.3, Color(1.0, 0.06, 0.04), 3.5))
	Modelagem.adicionar(malha, fogo, "turbina", turbina())
	if modelo >= 2:
		Modelagem.adicionar(malha, detalhe, "detalhe", Materiais.liso(Color(0.78, 0.8, 0.84), 0.22, Color.BLACK, 0.0, 0.9))
	return malha


static func detalhes_padrao(pinta: SurfaceTool, escuro: SurfaceTool, farol: SurfaceTool, lanterna: SurfaceTool) -> void:
	# para-lamas em arco por cima de cada roda
	for r in RODAS:
		para_lama(pinta, r)

	# aerofólio: asa pintada, colunas e placas das pontas escuras
	Modelagem.caixa(pinta, Vector3(0.0, 0.238, 0.535), Vector3(0.80, 0.022, 0.14), Basis(Vector3.RIGHT, deg_to_rad(-7.0)))
	for x in [-0.405, 0.405]:
		Modelagem.caixa(escuro, Vector3(x, 0.222, 0.535), Vector3(0.014, 0.08, 0.17))
	for x in [-0.22, 0.22]:
		Modelagem.caixa(escuro, Vector3(x, 0.17, 0.52), Vector3(0.022, 0.11, 0.05))

	# entradas de ar dos lados, atrás da roda da frente
	for lado in [-1.0, 1.0]:
		Modelagem.caixa(escuro, Vector3(0.418 * lado, 0.025, -0.13), Vector3(0.02, 0.022, 0.17), Basis(Vector3.RIGHT, deg_to_rad(-10.0)))
		Modelagem.caixa(escuro, Vector3(0.418 * lado, -0.01, -0.12), Vector3(0.02, 0.022, 0.14), Basis(Vector3.RIGHT, deg_to_rad(-10.0)))

	# frente: lâmina embaixo, entrada de ar no capô e os faróis
	Modelagem.caixa(escuro, Vector3(0.0, -0.13, -0.605), Vector3(0.64, 0.016, 0.07))
	Modelagem.caixa(escuro, Vector3(0.0, 0.088, -0.26), Vector3(0.16, 0.02, 0.13), Basis(Vector3.RIGHT, deg_to_rad(10.0)))
	for lado in [-1.0, 1.0]:
		Modelagem.caixa(farol, Vector3(0.235 * lado, -0.04, -0.588), Vector3(0.12, 0.024, 0.02), Basis(Vector3.BACK, deg_to_rad(-9.0 * lado)))
		Modelagem.caixa(farol, Vector3(0.30 * lado, -0.085, -0.592), Vector3(0.05, 0.012, 0.02))

	# trás: lanternas e a turbina do boost
	for lado in [-1.0, 1.0]:
		Modelagem.caixa(lanterna, Vector3(0.21 * lado, 0.05, 0.603), Vector3(0.15, 0.026, 0.02))
	Modelagem.caixa(lanterna, Vector3(0.0, 0.065, 0.604), Vector3(0.2, 0.008, 0.02))


static func detalhes_raio(pinta: SurfaceTool, escuro: SurfaceTool, farol: SurfaceTool, lanterna: SurfaceTool) -> void:
	# para-lamas baixos e largos, rabo de pato atrás, difusor e saias laterais
	for r in RODAS:
		para_lama(pinta, r, 0.2, 0.18, 0.56)
	Modelagem.caixa(pinta, Vector3(0.0, 0.092, 0.575), Vector3(0.76, 0.018, 0.08), Basis(Vector3.RIGHT, deg_to_rad(-16.0)))
	for x in [-0.24, -0.08, 0.08, 0.24]:
		Modelagem.caixa(escuro, Vector3(x, -0.115, 0.6), Vector3(0.012, 0.05, 0.1))
	for lado in [-1.0, 1.0]:
		Modelagem.caixa(escuro, Vector3(0.448 * lado, -0.125, 0.0), Vector3(0.02, 0.03, 0.46))
		# entradas de ar no capô
		Modelagem.caixa(escuro, Vector3(0.12 * lado, 0.012, -0.32), Vector3(0.07, 0.012, 0.16), Basis(Vector3.RIGHT, deg_to_rad(9.0)))
		# farol fininho e puxado pros lados
		Modelagem.caixa(farol, Vector3(0.26 * lado, -0.08, -0.6), Vector3(0.15, 0.014, 0.02), Basis(Vector3.BACK, deg_to_rad(-7.0 * lado)))
		Modelagem.caixa(lanterna, Vector3(0.25 * lado, 0.04, 0.6), Vector3(0.2, 0.018, 0.02))
	Modelagem.caixa(escuro, Vector3(0.0, -0.14, -0.62), Vector3(0.72, 0.014, 0.08))
	Modelagem.caixa(lanterna, Vector3(0.0, 0.05, 0.602), Vector3(0.3, 0.006, 0.02))


static func detalhes_tanque(pinta: SurfaceTool, escuro: SurfaceTool, farol: SurfaceTool, lanterna: SurfaceTool, detalhe: SurfaceTool) -> void:
	# para-lamas retos, para-choque de impulsão, barra de luz e bagageiro no teto
	for r in RODAS:
		var lado := signf(r.x)
		Modelagem.caixa(pinta, Vector3(0.47 * lado, 0.125, r.z), Vector3(0.15, 0.024, 0.3))
		for frente in [-1.0, 1.0]:
			Modelagem.caixa(pinta, Vector3(0.47 * lado, 0.07, r.z + 0.185 * frente), Vector3(0.15, 0.024, 0.14), Basis(Vector3.RIGHT, deg_to_rad(52.0 * frente)))
	Modelagem.caixa(detalhe, Vector3(0.0, -0.03, -0.635), Vector3(0.62, 0.035, 0.035))
	Modelagem.caixa(detalhe, Vector3(0.0, 0.06, -0.635), Vector3(0.46, 0.025, 0.025))
	for x in [-0.2, 0.2]:
		Modelagem.caixa(detalhe, Vector3(x, 0.0, -0.635), Vector3(0.03, 0.15, 0.03))
	Modelagem.caixa(escuro, Vector3(0.0, 0.03, -0.603), Vector3(0.3, 0.11, 0.012))
	for k in 5:
		Modelagem.caixa(detalhe, Vector3(-0.12 + 0.06 * k, 0.03, -0.608), Vector3(0.012, 0.09, 0.012))
	Modelagem.caixa(escuro, Vector3(0.0, 0.355, -0.03), Vector3(0.52, 0.035, 0.05))
	Modelagem.caixa(farol, Vector3(0.0, 0.355, -0.057), Vector3(0.46, 0.02, 0.008))
	for lado in [-1.0, 1.0]:
		Modelagem.caixa(escuro, Vector3(0.3 * lado, 0.352, 0.22), Vector3(0.025, 0.025, 0.46))
		Modelagem.caixa(farol, Vector3(0.29 * lado, 0.05, -0.605), Vector3(0.09, 0.06, 0.02))
		Modelagem.caixa(lanterna, Vector3(0.36 * lado, 0.04, 0.603), Vector3(0.05, 0.12, 0.02))
	for z in [0.05, 0.4]:
		Modelagem.caixa(escuro, Vector3(0.0, 0.352, z), Vector3(0.62, 0.02, 0.025))


static func detalhes_besouro(pinta: SurfaceTool, escuro: SurfaceTool, farol: SurfaceTool, lanterna: SurfaceTool, detalhe: SurfaceTool) -> void:
	# para-lamas gordinhos, faróis redondos com aro, para-choques cromados
	for r in RODAS:
		para_lama(pinta, r, 0.235, 0.2, 0.53)
	var de_frente := Basis(Vector3.RIGHT, -PI / 2.0)
	var de_tras := Basis(Vector3.RIGHT, PI / 2.0)
	for lado in [-1.0, 1.0]:
		Modelagem.torno(farol, meia_bola(0.05), 16, Transform3D(de_frente.scaled(Vector3(1, 1, 0.5)), Vector3(0.24 * lado, 0.0, -0.565)))
		Modelagem.torno(detalhe, [Vector2(0.062, -0.01), Vector2(0.062, 0.012), Vector2(0.05, 0.016)], 16, Transform3D(de_frente, Vector3(0.24 * lado, 0.0, -0.565)))
		Modelagem.torno(lanterna, meia_bola(0.035), 12, Transform3D(de_tras.scaled(Vector3(1, 1, 0.5)), Vector3(0.27 * lado, 0.03, 0.585)))
	Modelagem.caixa(detalhe, Vector3(0.0, -0.11, -0.615), Vector3(0.6, 0.03, 0.03))
	Modelagem.caixa(detalhe, Vector3(0.0, -0.11, 0.615), Vector3(0.6, 0.03, 0.03))
	for lado in [-1.0, 1.0]:
		Modelagem.caixa(escuro, Vector3(0.43 * lado, -0.12, 0.0), Vector3(0.05, 0.015, 0.5))


static func detalhes_flecha(pinta: SurfaceTool, escuro: SurfaceTool, farol: SurfaceTool, lanterna: SurfaceTool, detalhe: SurfaceTool) -> void:
	# compressor no capô, escapamentos dos lados, asa alta atrás e para-lamas soltos na frente
	for r in RODAS:
		if r.z < 0.0:
			para_lama(pinta, r, 0.2, 0.185, 0.54, 0.44)
			Modelagem.caixa(escuro, Vector3(0.38 * signf(r.x), 0.02, r.z), Vector3(0.14, 0.02, 0.04))
		else:
			para_lama(pinta, r, 0.22, 0.195, 0.55)
	Modelagem.caixa(escuro, Vector3(0.0, 0.1, -0.16), Vector3(0.17, 0.09, 0.18))
	Modelagem.caixa(detalhe, Vector3(0.0, 0.165, -0.18), Vector3(0.19, 0.045, 0.13), Basis(Vector3.RIGHT, deg_to_rad(8.0)))
	Modelagem.caixa(escuro, Vector3(0.0, 0.175, -0.25), Vector3(0.15, 0.03, 0.01))
	for lado in [-1.0, 1.0]:
		for k in 3:
			Modelagem.caixa(detalhe, Vector3(0.39 * lado, 0.05 + 0.012 * k, -0.08 + 0.09 * k), Vector3(0.03, 0.03, 0.09), Basis(Vector3.BACK, deg_to_rad(25.0 * lado)) * Basis(Vector3.RIGHT, deg_to_rad(20.0)))
		Modelagem.caixa(escuro, Vector3(0.2 * lado, 0.22, 0.54), Vector3(0.02, 0.24, 0.05))
		Modelagem.caixa(escuro, Vector3(0.43 * lado, 0.33, 0.55), Vector3(0.014, 0.08, 0.24))
		Modelagem.caixa(farol, Vector3(0.12 * lado, -0.06, -0.66), Vector3(0.07, 0.012, 0.02), Basis(Vector3.UP, deg_to_rad(-30.0 * lado)))
		Modelagem.caixa(lanterna, Vector3(0.24 * lado, 0.05, 0.603), Vector3(0.14, 0.024, 0.02))
	Modelagem.caixa(pinta, Vector3(0.0, 0.345, 0.55), Vector3(0.84, 0.022, 0.2), Basis(Vector3.RIGHT, deg_to_rad(-10.0)))
	Modelagem.caixa(escuro, Vector3(0.0, -0.12, -0.73), Vector3(0.3, 0.012, 0.08))


static func para_lama(st: SurfaceTool, roda_em: Vector3, raio_fora := 0.215, raio_dentro := 0.19, ate := 0.54, de := 0.395) -> void:
	# arco grosso por cima da roda, um pouco pra fora da carroceria
	var dentro := de * signf(roda_em.x)
	var fora := ate * signf(roda_em.x)
	var passos := 14
	for k in passos:
		var a0 := deg_to_rad(-12.0 + 204.0 * k / passos)
		var a1 := deg_to_rad(-12.0 + 204.0 * (k + 1) / passos)
		var d0 := Vector3(0.0, sin(a0), -cos(a0))
		var d1 := Vector3(0.0, sin(a1), -cos(a1))
		var c := Vector3(0.0, roda_em.y, roda_em.z)
		var lado_fora := Vector3(signf(roda_em.x), 0.0, 0.0)
		# em cima (lado de fora do arco), embaixo (de dentro, virado pra roda) e a lateral
		Modelagem.quadrado(st, [c + d0 * raio_fora + Vector3(dentro, 0, 0), c + d1 * raio_fora + Vector3(dentro, 0, 0), c + d1 * raio_fora + Vector3(fora, 0, 0), c + d0 * raio_fora + Vector3(fora, 0, 0)], [d0, d1, d1, d0])
		Modelagem.quadrado(st, [c + d0 * raio_dentro + Vector3(dentro, 0, 0), c + d1 * raio_dentro + Vector3(dentro, 0, 0), c + d1 * raio_dentro + Vector3(fora, 0, 0), c + d0 * raio_dentro + Vector3(fora, 0, 0)], [-d0, -d1, -d1, -d0])
		Modelagem.quadrado(st, [c + d0 * raio_dentro + Vector3(fora, 0, 0), c + d1 * raio_dentro + Vector3(fora, 0, 0), c + d1 * raio_fora + Vector3(fora, 0, 0), c + d0 * raio_fora + Vector3(fora, 0, 0)], [lado_fora, lado_fora, lado_fora, lado_fora])


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
			# aerofólio alto de corrida por cima do de série
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


static func montar_roda() -> ArrayMesh:
	# eixo da roda no Y (igual ao cilindro de antes: o carro.gd deita e gira ela)
	var borracha := Modelagem.nova()
	var aro := Modelagem.nova()
	var fundo := Modelagem.nova()
	var pneu := [Vector2(0.118, -0.06), Vector2(0.15, -0.062), Vector2(0.163, -0.055), Vector2(0.17, -0.035),
		Vector2(0.172, 0.0), Vector2(0.17, 0.035), Vector2(0.163, 0.055), Vector2(0.15, 0.062), Vector2(0.118, 0.06)]
	Modelagem.torno(borracha, pneu, 28)
	# os dois lados iguais: a mesma roda serve na esquerda e na direita
	var borda := [Vector2(0.12, 0.058), Vector2(0.112, 0.058), Vector2(0.104, 0.05)]
	var cubo := [Vector2(0.03, 0.042), Vector2(0.026, 0.054), Vector2(0.0, 0.056)]
	var prato := [Vector2(0.104, 0.05), Vector2(0.1, 0.034), Vector2(0.0, 0.03)]
	for perfil in [borda, cubo]:
		Modelagem.torno(aro, perfil, 24)
		Modelagem.torno(aro, Modelagem.espelhar(perfil), 24)
	Modelagem.torno(fundo, prato, 24)
	Modelagem.torno(fundo, Modelagem.espelhar(prato), 24)
	for lado in [-1.0, 1.0]:
		for k in 5:
			var giro := Basis(Vector3.UP, TAU * k / 5.0)
			Modelagem.caixa(aro, giro * Vector3(0.0, 0.045 * lado, 0.066), Vector3(0.024, 0.014, 0.08), giro)
	var malha := ArrayMesh.new()
	Modelagem.adicionar(malha, borracha, "pneu", Materiais.liso(Color(0.045, 0.045, 0.05), 0.85))
	Modelagem.adicionar(malha, aro, "aro", Materiais.liso(Color(0.78, 0.8, 0.84), 0.22, Color.BLACK, 0.0, 0.9))
	Modelagem.adicionar(malha, fundo, "fundo do aro", Materiais.liso(Color(0.06, 0.065, 0.07), 0.4, Color.BLACK, 0.0, 0.6))
	return malha
