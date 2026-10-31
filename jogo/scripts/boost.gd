class_name Boost
extends Node3D

# O efeito do boost, no escapamento de cada carro (a frente do carro é o -Z, então sai pro +Z).
# Cada estilo é uma mistura de: chama curtinha em cone, presa no bocal (malha que treme), e camadas
# de fluido (chama, fumaça, faíscas, anéis, estrelas) que se comportam como gás de verdade:
#   - saem do bocal com a velocidade do carro + a do jato (herdam o movimento do carro);
#   - o ar freia elas (arrasto), então ficam pra trás no mundo e o rastro curva quando o carro curva;
#   - gás quente sobe, faísca cai, e a turbulência espalha e enrola a fumaça;
#   - crescem e esfriam (a cor muda com a idade).
# (As partículas prontas do Godot não herdam a velocidade de quem solta: o jato ficava duro, como
# uma corda presa atrás do carro.) Tudo com o material do rastro: nada novo pro navegador compilar.

var estilo := 0
var cor := Color(1.0, 0.45, 0.1)
var ligado := false
var forca := 0.0                # 0 a 1: liga e desliga em uns centésimos, sem estalo
var tempo := 0.0
var camadas: Array[Camada] = []
var chamas: Array[MeshInstance3D] = []   # cones e feixes: tremem e somem quando desliga
var antes := Transform3D()               # onde o bocal estava no quadro anterior
var tem_antes := false


class Camada:
	# um tipo de partícula de fluido (desenhadas todas de uma vez, num MultiMesh no mundo)
	var no := MultiMeshInstance3D.new()
	var malha := MultiMesh.new()
	var capacidade := 0
	var vivas := 0
	var acumulado := 0.0
	var posicao := PackedVector3Array()
	var velocidade := PackedVector3Array()
	var idade := PackedFloat32Array()
	var vida := PackedFloat32Array()
	var tamanho := PackedFloat32Array()
	var fase := PackedFloat32Array()
	var cor_inicial := PackedColorArray()
	var giro := []               # Basis de cada uma (anel deitado na direção que saiu, estrela girando)
	var buffer := PackedFloat32Array()
	# como ela se comporta
	var taxa := 100.0            # por segundo, com o boost inteiro
	var vida_min := 0.3
	var vida_max := 0.5
	var vel_min := 8.0           # m/s em relação ao bocal, pra trás
	var vel_max := 12.0
	var abertura := 8.0          # graus
	var herda := 1.0             # quanto da velocidade do carro ela leva junto
	var arrasto := 5.0           # 1/s: o ar freando
	var empuxo := Vector3.ZERO   # m/s²: gás quente sobe, faísca cai
	var turbulencia := 0.0       # m/s² de vento bagunçado (cada uma com a sua fase)
	var raio_saida := 0.02       # m: sai de qualquer ponto do bocal
	var crescer: Curve           # tamanho pela idade (0 a 1)
	var tamanho_min := 1.0
	var tamanho_max := 1.0
	var esticar := 0.0           # estica na direção que voa, por m/s (língua de fogo, faísca)
	var girar := 0.0             # graus/s girando (estrela)
	var deitar := false          # o anel fica de frente pra direção que saiu
	var cores: Gradient          # cor e transparência pela idade
	var cores_sorteadas: Gradient   # se tiver: cada uma sorteia a sua cor (arco-íris)

	func preparar(forma: Mesh, maximo: int) -> void:
		capacidade = maximo
		malha.transform_format = MultiMesh.TRANSFORM_3D
		malha.use_colors = true
		malha.mesh = forma
		malha.instance_count = capacidade
		malha.visible_instance_count = 0
		malha.custom_aabb = AABB(Vector3(-300, -60, -300), Vector3(600, 260, 600))
		no.multimesh = malha
		no.top_level = true   # as partículas vivem no mundo, não no carro
		no.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		posicao.resize(capacidade)
		velocidade.resize(capacidade)
		idade.resize(capacidade)
		vida.resize(capacidade)
		tamanho.resize(capacidade)
		fase.resize(capacidade)
		cor_inicial.resize(capacidade)
		giro.resize(capacidade)
		buffer.resize(capacidade * 16)

	func soltar(de: Transform3D, ate: Transform3D, vel_bocal: Vector3, quanto: float, delta: float) -> void:
		# as novas saem espalhadas pelo caminho que o bocal fez neste quadro (senão saem em bolos)
		acumulado += taxa * quanto * delta
		var novas := int(acumulado)
		acumulado -= novas
		for k in novas:
			if vivas >= capacidade:
				return
			var f := (k + randf()) / novas
			var bocal := de.interpolate_with(ate, f)
			var a := deg_to_rad(abertura) * sqrt(randf())
			var b := randf() * TAU
			var direcao := bocal.basis * Vector3(sin(a) * cos(b), sin(a) * sin(b), cos(a))
			var r := raio_saida * sqrt(randf())
			var i := vivas
			vivas += 1
			posicao[i] = bocal * Vector3(r * cos(b), r * sin(b), 0.0)
			velocidade[i] = direcao.normalized() * randf_range(vel_min, vel_max) + vel_bocal * herda
			idade[i] = 0.0
			vida[i] = randf_range(vida_min, vida_max)
			tamanho[i] = randf_range(tamanho_min, tamanho_max)
			fase[i] = randf() * 100.0
			cor_inicial[i] = cores_sorteadas.sample(randf()) if cores_sorteadas else Color.WHITE
			if deitar:
				giro[i] = bocal.basis.orthonormalized()
			elif girar != 0.0:
				giro[i] = Basis(Vector3(randf() - 0.5, randf() - 0.5, randf() - 0.5).normalized(), randf() * TAU)
			else:
				giro[i] = Basis()
			# já anda o pedaço do quadro que ela "perdeu" (saiu no meio do caminho)
			andar(i, (1.0 - f) * delta, 0.0)

	func andar(i: int, dt: float, tempo: float) -> void:
		var v := velocidade[i]
		v += empuxo * dt
		if turbulencia > 0.0:
			var t := tempo * 3.0 + fase[i]
			v += Vector3(sin(t * 1.7), sin(t * 2.3 + 1.0), cos(t * 1.9)) * turbulencia * dt
		v *= exp(-arrasto * dt)
		velocidade[i] = v
		posicao[i] += v * dt
		idade[i] += dt

	func atualizar(delta: float, tempo: float) -> void:
		var i := 0
		while i < vivas:
			andar(i, delta, tempo)
			if idade[i] >= vida[i]:
				# a última viva vem pro lugar da que morreu
				vivas -= 1
				posicao[i] = posicao[vivas]
				velocidade[i] = velocidade[vivas]
				idade[i] = idade[vivas]
				vida[i] = vida[vivas]
				tamanho[i] = tamanho[vivas]
				fase[i] = fase[vivas]
				cor_inicial[i] = cor_inicial[vivas]
				giro[i] = giro[vivas]
				continue
			i += 1
		desenhar()

	func desenhar() -> void:
		for i in vivas:
			var t := idade[i] / vida[i]
			var s := tamanho[i] * (crescer.sample(t) if crescer else 1.0)
			var b: Basis
			if esticar > 0.0:
				# deitada na direção que voa, mais comprida quanto mais rápida
				var v := velocidade[i]
				var rapidez := v.length()
				var y := v / rapidez if rapidez > 0.01 else Vector3.UP
				var x := y.cross(Vector3.UP if absf(y.y) < 0.9 else Vector3.RIGHT).normalized()
				var z := x.cross(y)
				b = Basis(x * s, y * s * (1.0 + rapidez * esticar), z * s)
			else:
				b = giro[i] * s
				if girar != 0.0:
					b = Basis(Vector3.UP, deg_to_rad(girar) * idade[i]) * b
			var c := cores.sample(t) * cor_inicial[i]
			var p := posicao[i]
			var k := i * 16
			buffer[k] = b.x.x
			buffer[k + 1] = b.y.x
			buffer[k + 2] = b.z.x
			buffer[k + 3] = p.x
			buffer[k + 4] = b.x.y
			buffer[k + 5] = b.y.y
			buffer[k + 6] = b.z.y
			buffer[k + 7] = p.y
			buffer[k + 8] = b.x.z
			buffer[k + 9] = b.y.z
			buffer[k + 10] = b.z.z
			buffer[k + 11] = p.z
			buffer[k + 12] = c.r
			buffer[k + 13] = c.g
			buffer[k + 14] = c.b
			buffer[k + 15] = c.a
		malha.buffer = buffer
		malha.visible_instance_count = vivas
		no.visible = vivas > 0


func montar(estilo_: int, cor_: Color) -> void:
	estilo = estilo_
	cor = cor_
	for filho in get_children():
		filho.queue_free()
	camadas.clear()
	chamas.clear()
	tem_antes = false
	var claro := cor.lerp(Color.WHITE, 0.6)
	var quente := cor.lerp(Color(1.0, 0.95, 0.6), 0.5)
	var ponta := cor.lerp(Color(0.9, 0.12, 0.05), 0.45)
	match Aparencia.BOOSTS[estilo]:
		"Fogo":
			# só o miolo fica preso no bocal (curtinho); o resto é chama solta no ar
			cone(0.2, 0.04, Color(1.0, 0.97, 0.85), quente, 1.6)
			cone(0.36, 0.064, quente, cor, 1.2)
			var fogo := camada(bola(0.045, 10), 220)
			fogo.taxa = 700.0
			fogo.vida_min = 0.12
			fogo.vida_max = 0.24
			fogo.vel_min = 13.0
			fogo.vel_max = 17.0
			fogo.abertura = 5.0
			fogo.arrasto = 7.0
			fogo.empuxo = Vector3(0, 3.0, 0)
			fogo.turbulencia = 9.0
			fogo.raio_saida = 0.035
			fogo.esticar = 0.05
			fogo.tamanho_min = 0.8
			fogo.tamanho_max = 1.2
			fogo.crescer = curva([[0.0, 0.7], [0.3, 1.5], [1.0, 2.4]])
			fogo.cores = degrade([[0.0, Color(1.0, 0.95, 0.75) * 1.6, 0.7], [0.3, quente * 1.3, 0.55], [0.6, cor, 0.32], [0.85, ponta * 0.6, 0.12], [1.0, Color(0.2, 0.06, 0.03), 0.0]])
			fumaca(Color(0.22, 0.2, 0.19), 0.14, 90.0)
			faiscas(28.0, 1.0)
		"Faíscas":
			cone(0.3, 0.05, claro, cor, 2.0)
			faiscas(220.0, 1.5)
			var brasa := camada(bola(0.03, 8), 80)
			brasa.taxa = 120.0
			brasa.vida_min = 0.15
			brasa.vida_max = 0.25
			brasa.vel_min = 9.0
			brasa.vel_max = 12.0
			brasa.arrasto = 6.0
			brasa.cores = degrade([[0.0, claro * 2.0, 0.8], [1.0, cor, 0.0]])
		"Fumaça preta":
			cone(0.26, 0.055, claro, cor, 2.0)
			var preta := camada(bola(0.08, 10), 400)
			preta.taxa = 270.0
			preta.vida_min = 0.9
			preta.vida_max = 1.4
			preta.vel_min = 8.0
			preta.vel_max = 11.0
			preta.abertura = 7.0
			preta.arrasto = 3.5
			preta.empuxo = Vector3(0, 1.6, 0)
			preta.turbulencia = 5.0
			preta.raio_saida = 0.04
			preta.tamanho_min = 0.8
			preta.tamanho_max = 1.3
			preta.crescer = curva([[0.0, 0.5], [0.25, 1.5], [1.0, 3.2]])
			preta.cores = degrade([[0.0, cor * 1.4, 0.8], [0.08, Color(0.12, 0.11, 0.1), 0.6], [0.6, Color(0.06, 0.06, 0.07), 0.35], [1.0, Color(0.05, 0.05, 0.06), 0.0]])
		"Plasma":
			cone(0.5, 0.028, claro, cor, 2.4)
			cone(0.3, 0.065, cor, cor, 1.5)
			var aneis := camada(anel(), 40)
			aneis.taxa = 22.0
			aneis.vida_min = 0.5
			aneis.vida_max = 0.6
			aneis.vel_min = 8.0
			aneis.vel_max = 8.0
			aneis.abertura = 0.0
			aneis.arrasto = 3.0
			aneis.raio_saida = 0.0
			aneis.deitar = true
			aneis.crescer = curva([[0.0, 0.6], [1.0, 2.4]])
			aneis.cores = degrade([[0.0, claro * 2.2, 1.0], [0.5, cor * 2.0, 0.7], [1.0, cor * 1.2, 0.0]])
			labaredas(170.0, 0.3, 0.03, [[0.0, claro * 2.2, 1.0], [0.5, cor * 2.0, 0.8], [1.0, cor, 0.0]])
		"Laser":
			# luz não é fluido: os feixes ficam retos no bocal (curtos), e o brilho que sobra fica no ar
			for x in [-0.03, 0.03]:
				feixe(Vector3(x, 0.0, 0.0), 1.1, 0.014, claro, 3.0)
				feixe(Vector3(x, 0.0, 0.0), 1.1, 0.045, cor, 1.8)
			labaredas(140.0, 0.4, 0.022, [[0.0, claro * 2.5, 1.0], [1.0, cor * 2.0, 0.0]])
		"Estrelinhas":
			cone(0.24, 0.05, claro, cor, 2.0)
			var estrelas := camada(estrela(), 120)
			estrelas.taxa = 70.0
			estrelas.vida_min = 0.8
			estrelas.vida_max = 1.2
			estrelas.vel_min = 4.0
			estrelas.vel_max = 7.0
			estrelas.abertura = 22.0
			estrelas.arrasto = 3.0
			estrelas.empuxo = Vector3(0, 0.6, 0)
			estrelas.turbulencia = 2.0
			estrelas.girar = 300.0
			estrelas.tamanho_min = 0.7
			estrelas.tamanho_max = 1.3
			estrelas.crescer = curva([[0.0, 0.4], [0.15, 1.0], [0.8, 1.0], [1.0, 0.3]])
			estrelas.cores = degrade([[0.0, claro * 2.2, 1.0], [0.3, cor * 2.0, 1.0], [1.0, cor * 1.4, 0.0]])
		"Arco-íris":
			cone(0.24, 0.05, Color(1.0, 0.95, 0.9), Color(1.0, 0.8, 0.6), 2.0)
			var arco := camada(bola(0.05, 8), 400)
			arco.taxa = 480.0
			arco.vida_min = 0.6
			arco.vida_max = 0.8
			arco.vel_min = 7.0
			arco.vel_max = 9.0
			arco.abertura = 5.0
			arco.arrasto = 5.0
			arco.turbulencia = 2.5
			arco.crescer = curva([[0.0, 1.0], [0.4, 1.4], [1.0, 0.6]])
			var cores := Gradient.new()
			cores.offsets = PackedFloat32Array([0.0, 0.2, 0.4, 0.6, 0.8, 1.0])
			cores.colors = PackedColorArray([Color(1, 0.1, 0.1) * 1.8, Color(1, 0.55, 0.05) * 1.8, Color(1, 0.95, 0.1) * 1.8, Color(0.2, 1, 0.3) * 1.8, Color(0.2, 0.5, 1) * 1.8, Color(0.7, 0.2, 1) * 1.8])
			arco.cores_sorteadas = cores
			arco.cores = degrade([[0.0, Color.WHITE, 1.0], [0.7, Color.WHITE, 0.8], [1.0, Color.WHITE, 0.0]])


func _process(delta: float) -> void:
	tempo += delta
	forca = move_toward(forca, 1.0 if ligado else 0.0, delta * 14.0)
	# onde o bocal está agora (como aparece na tela) e a que velocidade anda
	var agora := get_global_transform_interpolated()
	if not tem_antes or delta <= 0.0 or agora.origin.distance_to(antes.origin) > 3.0:
		antes = agora   # nasceu ou teleportou: nada de rastro emendando de longe
	var vel_bocal := (agora.origin - antes.origin) / delta if delta > 0.0 else Vector3.ZERO
	for c in camadas:
		if ligado and is_visible_in_tree():
			c.soltar(antes, agora, vel_bocal, forca, delta)
		c.atualizar(delta, tempo)
	antes = agora
	tem_antes = true
	# a chama do bocal treme: comprimento e grossura mudam um pouco a cada quadro
	for i in chamas.size():
		var c := chamas[i]
		c.visible = forca > 0.01
		var tremor := 0.85 + 0.15 * sin(tempo * 47.0 + i * 1.7) + randf_range(-0.12, 0.12)
		var grossura := forca * (0.92 + randf_range(0.0, 0.16))
		c.scale = Vector3(grossura, grossura, forca * tremor)


func camada(forma: Mesh, maximo: int) -> Camada:
	var c := Camada.new()
	c.preparar(forma, maximo)
	add_child(c.no)
	camadas.append(c)
	return c


func fumaca(cinza: Color, transparencia: float, quantas: float) -> void:
	# fumaça fininha que sobra do fogo, subindo e se espalhando
	var f := camada(bola(0.07, 10), 130)
	f.taxa = quantas
	f.vida_min = 0.7
	f.vida_max = 1.1
	f.vel_min = 6.0
	f.vel_max = 9.0
	f.arrasto = 4.0
	f.empuxo = Vector3(0, 1.4, 0)
	f.turbulencia = 4.0
	f.raio_saida = 0.04
	f.crescer = curva([[0.0, 0.8], [1.0, 3.5]])
	f.cores = degrade([[0.0, cinza, 0.0], [0.2, cinza, transparencia], [1.0, cinza, 0.0]])


func labaredas(quantas: float, vida: float, raio: float, cores: Array) -> void:
	# bolinhas rápidas que saem quentes (brancas) e esfriam na cor escolhida
	var p := camada(bola(raio, 8), 120)
	p.taxa = quantas
	p.vida_min = vida * 0.7
	p.vida_max = vida
	p.vel_min = 9.0
	p.vel_max = 12.0
	p.abertura = 6.0
	p.arrasto = 5.0
	p.turbulencia = 3.0
	p.crescer = curva([[0.0, 1.0], [0.5, 0.75], [1.0, 0.25]])
	p.cores = degrade(cores)


func faiscas(quantas: float, forca_: float) -> void:
	# caem com a gravidade e o ar quase não segura
	var p := camada(risco(), 160)
	p.taxa = quantas
	p.vida_min = 0.35
	p.vida_max = 0.7
	p.vel_min = 5.0 * forca_
	p.vel_max = 11.0 * forca_
	p.abertura = 26.0
	p.arrasto = 1.5
	p.empuxo = Vector3(0, -9.0, 0)
	p.esticar = 0.06
	p.cores = degrade([[0.0, Color(1.0, 0.95, 0.8) * 2.5, 1.0], [0.4, cor.lerp(Color.WHITE, 0.3) * 2.0, 1.0], [1.0, cor * 1.2, 0.0]])


func cone(comprimento: float, raio: float, cor_base: Color, cor_ponta: Color, brilho: float) -> void:
	# chama: cone deitado pro +Z, base opaca e ponta sumindo (as cores ficam nos vértices)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lados := 14
	var aneis := [[0.0, 1.0, 0.0], [0.25, 0.95, 0.15], [0.6, 0.6, 0.55], [1.0, 0.0, 1.0]]   # [onde, largura, quanto já virou a cor da ponta]
	for k in aneis.size() - 1:
		var a: Array = aneis[k]
		var b: Array = aneis[k + 1]
		var cor_a := Color(cor_base.lerp(cor_ponta, a[2]), 1.0 - a[0] * 0.95)
		var cor_b := Color(cor_base.lerp(cor_ponta, b[2]), 1.0 - b[0] * 0.95 if k + 1 < aneis.size() - 1 else 0.0)
		for j in lados:
			var t0 := TAU * j / lados
			var t1 := TAU * (j + 1) / lados
			var p := [Vector3(cos(t0) * raio * a[1], sin(t0) * raio * a[1], comprimento * a[0]),
				Vector3(cos(t1) * raio * a[1], sin(t1) * raio * a[1], comprimento * a[0]),
				Vector3(cos(t1) * raio * b[1], sin(t1) * raio * b[1], comprimento * b[0]),
				Vector3(cos(t0) * raio * b[1], sin(t0) * raio * b[1], comprimento * b[0])]
			var cores := [cor_a, cor_a, cor_b, cor_b]
			for i in [0, 1, 2, 0, 2, 3]:
				st.set_color(cores[i])
				st.set_normal(Vector3(p[i].x, p[i].y, 0.0).normalized())
				st.add_vertex(p[i])
	var m := MeshInstance3D.new()
	m.mesh = st.commit()
	m.material_override = Materiais.rastro(brilho, 1.0)
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.visible = false
	add_child(m)
	chamas.append(m)


func feixe(onde: Vector3, comprimento: float, grossura: float, cor_: Color, brilho: float) -> void:
	# laser: caixinha comprida que some na ponta
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var g := grossura / 2.0
	var cantos := [Vector2(-g, -g), Vector2(g, -g), Vector2(g, g), Vector2(-g, g)]
	for j in 4:
		var c0: Vector2 = cantos[j]
		var c1: Vector2 = cantos[(j + 1) % 4]
		var p := [Vector3(c0.x, c0.y, 0.0), Vector3(c1.x, c1.y, 0.0), Vector3(c1.x, c1.y, comprimento), Vector3(c0.x, c0.y, comprimento)]
		var cores := [Color(cor_, 1.0), Color(cor_, 1.0), Color(cor_, 0.0), Color(cor_, 0.0)]
		for i in [0, 1, 2, 0, 2, 3]:
			st.set_color(cores[i])
			st.set_normal(Vector3(p[i].x, p[i].y, 0.0).normalized())
			st.add_vertex(p[i])
	var m := MeshInstance3D.new()
	m.mesh = st.commit()
	m.material_override = Materiais.rastro(brilho)
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.position = onde
	m.visible = false
	add_child(m)
	chamas.append(m)


func bola(raio: float, lados: int) -> SphereMesh:
	# bolinha de borda esfumaçada (junta várias, vira chama ou nuvem, não bolha)
	var m := SphereMesh.new()
	m.radius = raio
	m.height = raio * 2.0
	m.radial_segments = maxi(lados, 12)
	m.rings = maxi(lados / 2, 6)
	m.material = Materiais.rastro(1.0, 1.0)
	return m


func risco() -> BoxMesh:
	var m := BoxMesh.new()
	m.size = Vector3(0.012, 0.09, 0.012)
	m.material = Materiais.rastro()
	return m


func anel() -> ArrayMesh:
	# anel em pé (de frente pra trás do carro), raio 0,1
	var st := Modelagem.nova()
	Modelagem.torno(st, [Vector2(0.085, 0.0), Vector2(0.1, 0.008), Vector2(0.11, 0.0), Vector2(0.1, -0.008), Vector2(0.085, 0.0)], 28, Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3.ZERO))
	var malha := ArrayMesh.new()
	Modelagem.adicionar(malha, st, "anel", Materiais.rastro())
	return malha


func estrela() -> ArrayMesh:
	# estrela chata de 5 pontas
	var st := Modelagem.nova()
	var centro := Vector3.ZERO
	for k in 10:
		var a0 := TAU * k / 10.0
		var a1 := TAU * (k + 1) / 10.0
		var r0 := 0.07 if k % 2 == 0 else 0.03
		var r1 := 0.03 if k % 2 == 0 else 0.07
		Modelagem.triangulo(st, [centro, Vector3(cos(a0) * r0, sin(a0) * r0, 0.0), Vector3(cos(a1) * r1, sin(a1) * r1, 0.0)], [Vector3.BACK, Vector3.BACK, Vector3.BACK])
	var malha := ArrayMesh.new()
	Modelagem.adicionar(malha, st, "estrela", Materiais.rastro())
	return malha


func curva(pontos: Array) -> Curve:
	var k := Curve.new()
	k.max_value = 4.0
	for ponto in pontos:
		k.add_point(Vector2(ponto[0], ponto[1]))
	return k


func degrade(pontos: Array) -> Gradient:
	# [[onde, cor, transparência], ...]
	var g := Gradient.new()
	var onde := PackedFloat32Array()
	var lista := PackedColorArray()
	for ponto in pontos:
		onde.append(ponto[0])
		lista.append(Color(ponto[1], ponto[2]))
	g.offsets = onde
	g.colors = lista
	return g
