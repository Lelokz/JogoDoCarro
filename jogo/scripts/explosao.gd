class_name Explosao
extends Node3D

# Explosões: a de demolição (carro) e a do gol (bem maior, saindo de dentro do gol pro campo).
# Tudo com partículas e o mesmo material do rastro do boost (cor de cada partícula; acima de 1 brilha
# com o bloom da arena), então não cria shader novo pro navegador compilar. Some sozinha.
#   gol: clarão enorme, duas ondas de choque (uma em pé saindo do gol, uma no chão), riscos de faísca,
#        pedaços escuros girando, fumaça grossa na cor do time e confete do time caindo.

var cor := Color(1.0, 0.55, 0.15)
var tamanho := 1.0       # 1 = demolição; 2 ou mais = gol
var para := Vector3.ZERO  # pra onde a explosão do gol sai (do gol pro campo)
var tempo := 0.0


static func criar(onde: Node, posicao: Vector3, cor_: Color, tamanho_: float) -> Explosao:
	var e := Explosao.new()
	e.cor = cor_
	e.tamanho = tamanho_
	if tamanho_ >= 2.0:
		# gol: a bola está dentro do gol, depois da linha; a explosão sai pro campo
		e.para = Vector3(0.0, 0.0, -signf(posicao.z))
	onde.add_child(e)
	e.global_position = posicao
	# só solta as partículas depois de estar no lugar: elas ficam no mundo (não acompanham a explosão),
	# então se soltassem antes saíam do ponto zero, no meio do campo
	for p in e.get_children():
		if p.has_meta("chao"):
			p.position.y = -posicao.y + 0.15   # a onda do chão corre rente à grama
		p.emitting = true
	return e


func _ready() -> void:
	if para != Vector3.ZERO:
		explosao_do_gol()
	else:
		explosao_pequena()


func explosao_pequena() -> void:
	# demolição: clarão que cresce e some, faíscas pra todo lado e um pouco de fumaça
	var clarao := emissor(1, 0.45, bola(1.0, 28), 0.0, 0.0)
	clarao.scale_amount_min = 1.2
	clarao.scale_amount_max = 1.2
	clarao.scale_amount_curve = curva([[0.0, 0.4], [0.35, 1.0], [1.0, 1.3]])
	clarao.color_ramp = degrade([[0.0, cor.lerp(Color.WHITE, 0.75) * 5.0, 1.0], [0.35, cor * 3.0, 0.7], [1.0, cor * 1.5, 0.0]])
	var faiscas := emissor(70, 0.9, risco(0.012, 0.16), 6.0, 18.0)
	faiscas.spread = 180.0
	faiscas.gravity = Vector3(0, -12, 0)
	faiscas.particle_flag_align_y = true
	faiscas.color_ramp = degrade([[0.0, Color(1.0, 0.95, 0.7) * 6.0, 1.0], [0.5, cor * 3.0, 1.0], [1.0, cor, 0.0]])
	var fumaca := emissor(16, 1.8, bola(0.5, 10), 1.0, 3.0)
	fumaca.spread = 180.0
	fumaca.gravity = Vector3(0, 1.5, 0)
	fumaca.scale_amount_min = 0.8
	fumaca.scale_amount_max = 1.6
	fumaca.color_ramp = degrade([[0.0, Color(0.5, 0.45, 0.4), 0.0], [0.3, Color(0.3, 0.3, 0.32), 0.3], [1.0, Color(0.25, 0.25, 0.27), 0.0]])
	pedacos(10, 1.0)


func explosao_do_gol() -> void:
	var forte := tamanho / 2.5   # 0,8 a 1,4: bola mais rápida, explosão maior
	var claro := cor.lerp(Color.WHITE, 0.7)

	# clarão: uma bola de luz que incha até uns 7 m e apaga, e um miolo branco mais rápido
	var clarao := emissor(1, 0.9, bola(1.0, 32), 0.0, 0.0)
	clarao.scale_amount_min = 7.0 * forte
	clarao.scale_amount_max = 7.0 * forte
	clarao.scale_amount_curve = curva([[0.0, 0.15], [0.12, 0.85], [1.0, 1.0]])
	clarao.color_ramp = degrade([[0.0, claro * 8.0, 0.95], [0.25, cor * 4.0, 0.55], [1.0, cor * 1.5, 0.0]])
	var miolo := emissor(1, 0.35, bola(1.0, 24), 0.0, 0.0)
	miolo.scale_amount_min = 3.2 * forte
	miolo.scale_amount_max = 3.2 * forte
	miolo.scale_amount_curve = curva([[0.0, 0.3], [0.3, 1.0], [1.0, 1.1]])
	miolo.color_ramp = degrade([[0.0, Color.WHITE * 10.0, 1.0], [0.5, claro * 6.0, 0.8], [1.0, cor * 3.0, 0.0]])

	# ondas de choque: anel em pé saindo da boca do gol e anel deitado correndo pelo chão
	var em_pe := onda(Basis(Vector3.RIGHT, PI / 2.0), 16.0 * forte, 0.7)
	em_pe.position = para * 1.5
	var no_chao := onda(Basis(), 22.0 * forte, 0.9)
	no_chao.position = para * 2.0
	no_chao.set_meta("chao", true)

	# riscos de faísca: rápidos, esticados na direção que voam, saindo pro campo e caindo
	var riscos := emissor(int(220 * forte), 1.4, risco(0.03, 0.9), 18.0, 42.0)
	riscos.direction = (para + Vector3.UP * 0.35).normalized()
	riscos.spread = 70.0
	riscos.gravity = Vector3(0, -14, 0)
	riscos.particle_flag_align_y = true
	riscos.damping_min = 4.0
	riscos.damping_max = 10.0
	riscos.color_ramp = degrade([[0.0, Color(1.0, 0.97, 0.85) * 9.0, 1.0], [0.35, claro * 5.0, 1.0], [1.0, cor * 2.0, 0.0]])
	# faíscas miúdas pra todo lado (enchem o meio)
	var faiscas := emissor(int(160 * forte), 1.1, bola(0.06, 6), 6.0, 22.0)
	faiscas.spread = 180.0
	faiscas.gravity = Vector3(0, -10, 0)
	faiscas.damping_min = 2.0
	faiscas.damping_max = 6.0
	faiscas.color_ramp = degrade([[0.0, claro * 7.0, 1.0], [0.6, cor * 4.0, 1.0], [1.0, cor * 2.0, 0.0]])

	# fumaça grossa na cor do time, inchando e subindo devagar
	var fumaca := emissor(int(55 * forte), 3.2, bola(0.8, 18), 3.0, 9.0)
	fumaca.direction = (para + Vector3.UP * 0.6).normalized()
	fumaca.spread = 80.0
	fumaca.gravity = Vector3(0, 1.2, 0)
	fumaca.damping_min = 2.0
	fumaca.damping_max = 3.0
	fumaca.scale_amount_min = 1.2
	fumaca.scale_amount_max = 2.4
	fumaca.scale_amount_curve = curva([[0.0, 0.4], [0.4, 1.4], [1.0, 2.0]])
	fumaca.color_ramp = degrade([[0.0, cor * 2.5, 0.0], [0.08, cor * 1.4, 0.45], [0.5, cor.lerp(Color(0.3, 0.3, 0.33), 0.6), 0.3], [1.0, Color(0.22, 0.22, 0.25), 0.0]])

	# confete do time: papelzinho que voa alto e desce rodando
	var confete := emissor(int(160 * forte), 3.8, papel(), 12.0, 24.0)
	confete.direction = (para * 0.6 + Vector3.UP).normalized()
	confete.spread = 55.0
	confete.gravity = Vector3(0, -4.0, 0)
	confete.damping_min = 2.5
	confete.damping_max = 4.0
	confete.angular_velocity_min = -360.0
	confete.angular_velocity_max = 360.0
	confete.color_ramp = degrade([[0.0, claro * 2.5, 1.0], [0.85, cor * 1.6, 1.0], [1.0, cor, 0.0]])
	confete.hue_variation_min = -0.04
	confete.hue_variation_max = 0.04
	pedacos(int(26 * forte), 2.2)


func pedacos(quantos: int, forca: float) -> void:
	# pedaços escuros (lataria/placa) girando e caindo
	var p := emissor(quantos, 1.8, caixinha(), 6.0 * forca, 14.0 * forca)
	p.direction = (para + Vector3.UP * 0.8).normalized() if para != Vector3.ZERO else Vector3.UP
	p.spread = 75.0 if para != Vector3.ZERO else 180.0
	p.gravity = Vector3(0, -16, 0)
	p.angular_velocity_min = -540.0
	p.angular_velocity_max = 540.0
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.4
	p.color_ramp = degrade([[0.0, cor * 3.0, 1.0], [0.15, Color(0.08, 0.08, 0.09), 1.0], [1.0, Color(0.05, 0.05, 0.06), 0.0]])


func onda(giro: Basis, raio_final: float, vida: float) -> CPUParticles3D:
	# anel fino que cresce rápido e apaga (partícula parada: a malha já vem deitada/em pé)
	var p := emissor(1, vida, anel(giro), 0.0, 0.0)
	p.local_coords = true
	p.scale_amount_min = raio_final
	p.scale_amount_max = raio_final
	p.scale_amount_curve = curva([[0.0, 0.05], [0.35, 0.75], [1.0, 1.0]])
	p.color_ramp = degrade([[0.0, cor.lerp(Color.WHITE, 0.6) * 6.0, 0.9], [0.4, cor * 3.0, 0.5], [1.0, cor, 0.0]])
	return p


func emissor(quantos: int, vida: float, malha: Mesh, velocidade_min: float, velocidade_max: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = maxi(quantos, 1)
	p.lifetime = vida
	p.one_shot = true
	p.explosiveness = 1.0
	p.local_coords = false
	p.direction = Vector3.UP
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = velocidade_min
	p.initial_velocity_max = velocidade_max
	p.mesh = malha
	p.emitting = false
	add_child(p)
	return p


func bola(raio: float, lados: int) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = raio
	m.height = raio * 2.0
	m.radial_segments = lados
	m.rings = lados / 2
	m.material = Materiais.rastro()
	return m


func risco(grossura: float, comprimento: float) -> BoxMesh:
	# fininho e comprido no Y: com align_y, fica deitado na direção que a faísca voa
	var m := BoxMesh.new()
	m.size = Vector3(grossura, comprimento, grossura)
	m.material = Materiais.rastro()
	return m


func papel() -> BoxMesh:
	var m := BoxMesh.new()
	m.size = Vector3(0.32, 0.012, 0.2)
	m.material = Materiais.rastro()
	return m


func caixinha() -> BoxMesh:
	var m := BoxMesh.new()
	m.size = Vector3(0.18, 0.06, 0.12)
	m.material = Materiais.rastro()
	return m


func anel(giro: Basis) -> ArrayMesh:
	# anel de raio 1 (a partícula cresce até o raio final), virado pelo giro
	var st := Modelagem.nova()
	Modelagem.torno(st, [Vector2(0.965, 0.0), Vector2(1.0, 0.006), Vector2(1.025, 0.0), Vector2(1.0, -0.006), Vector2(0.965, 0.0)], 64, Transform3D(giro, Vector3.ZERO))
	var malha := ArrayMesh.new()
	Modelagem.adicionar(malha, st, "anel", Materiais.rastro())
	return malha


func curva(pontos: Array) -> Curve:
	var k := Curve.new()
	k.max_value = 3.0
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


func _process(delta: float) -> void:
	tempo += delta
	if tempo > 4.5:
		queue_free()
