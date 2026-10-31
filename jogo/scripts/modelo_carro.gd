class_name ModeloCarro
extends RefCounted

# O desenho do carro, montado por código. É só aparência: a colisão continua sendo a caixa do carro.tscn
# (0,84 × 0,36 × 1,18 m) e as rodas continuam onde a suspensão manda. A frente é o -Z.
# As malhas ficam guardadas depois da primeira vez: todos os carros usam as mesmas.
# Superfícies com nome "pintura" e "turbina" cada carro troca pelas suas (cor do time, brilho do boost).

static var malha_corpo: ArrayMesh
static var malha_roda: ArrayMesh

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
const ALTURA_SAIA := -0.065   # abaixo disso a lateral é escura
const RODAS := [Vector3(-0.46, -0.08, -0.42), Vector3(0.46, -0.08, -0.42), Vector3(-0.46, -0.08, 0.42), Vector3(0.46, -0.08, 0.42)]


static func corpo() -> ArrayMesh:
	if malha_corpo == null:
		malha_corpo = montar_corpo()
	return malha_corpo


static func roda() -> ArrayMesh:
	if malha_roda == null:
		malha_roda = montar_roda()
	return malha_roda


static func pintura(cor: Color) -> ShaderMaterial:
	return Materiais.liso(cor, 0.25, Color.BLACK, 0.0, 0.35)


static func turbina() -> ShaderMaterial:
	return Materiais.liso(Color(0.1, 0.1, 0.1), 0.5, Color(1.0, 0.45, 0.1), 0.5)


static func montar_corpo() -> ArrayMesh:
	var pinta := Modelagem.nova()
	var escuro := Modelagem.nova()
	var vidro := Modelagem.nova()
	var farol := Modelagem.nova()
	var lanterna := Modelagem.nova()
	var fogo := Modelagem.nova()

	# carroceria: em cima pintada, a saia de baixo escura
	var cortes := []
	for s in CARROCERIA:
		cortes.append(Modelagem.secao(s + [ALTURA_SAIA]))
	var total := Modelagem.PONTOS_CORTE
	Modelagem.costurar(pinta, cortes, Modelagem.indices(Modelagem.LADO_DIREITO, Modelagem.LADO_ESQUERDO, total))
	Modelagem.costurar(escuro, cortes, Modelagem.indices(Modelagem.LADO_ESQUERDO, total + Modelagem.LADO_DIREITO, total))
	Modelagem.tampa(escuro, cortes[0], Vector3.FORWARD, 0.01)
	Modelagem.tampa(escuro, cortes[-1], Vector3.BACK, 0.005)

	# cabine de vidro e o teto pintado por cima (o vidro aparece na frente, atrás e dos lados)
	var cortes_cabine := []
	for s in CABINE:
		cortes_cabine.append(Modelagem.secao(s))
	Modelagem.costurar(vidro, cortes_cabine, Modelagem.indices(0, total, total))
	Modelagem.tampa(vidro, cortes_cabine[-1], Vector3.BACK)
	var cortes_teto := []
	for s in CABINE.slice(2, 5):
		cortes_teto.append(Modelagem.secao([s[0], s[1], s[2] * 0.82, s[3], s[4] + 0.004, s[5], s[6] * 0.8]))
	Modelagem.costurar(pinta, cortes_teto, Modelagem.indices(Modelagem.LADO_DIREITO + 1, Modelagem.LADO_ESQUERDO - 1, total))

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
	return malha


static func para_lama(st: SurfaceTool, roda_em: Vector3) -> void:
	# arco grosso por cima da roda, um pouco pra fora da carroceria
	var dentro := 0.395 * signf(roda_em.x)
	var fora := 0.54 * signf(roda_em.x)
	var raio_fora := 0.215
	var raio_dentro := 0.19
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
