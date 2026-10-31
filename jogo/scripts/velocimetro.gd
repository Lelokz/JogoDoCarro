class_name Velocimetro
extends Control

# Canto de baixo à direita: velocímetro (arco que enche + ponteiro + km/h no meio)
# e, do lado, o boost num círculo que enche e esvazia com o número no meio.

var velocidade := 0.0      # m/s
var maxima := 23.0         # m/s (o fim do arco)
var supersonico := false
var boost := 33.0          # 0 a 100
var boostando := false
var camera_bola := false
var piscar := 0.0

const CENTRO_VELOCIDADE := Vector2(140, 140)
const RAIO_VELOCIDADE := 100.0
const CENTRO_BOOST := Vector2(345, 160)
const RAIO_BOOST := 64.0
const INICIO := deg_to_rad(135.0)   # o arco vai de baixo-esquerda até baixo-direita, por cima
const VOLTA := deg_to_rad(270.0)


func _ready() -> void:
	custom_minimum_size = Vector2(430, 262)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	piscar += delta
	queue_redraw()


func _draw() -> void:
	desenhar_velocidade()
	desenhar_boost()


func desenhar_velocidade() -> void:
	var c := CENTRO_VELOCIDADE
	var r := RAIO_VELOCIDADE
	var fracao := clampf(velocidade / maxima, 0.0, 1.0)
	var cor := Estilo.AZUL.lerp(Color(0.5, 0.95, 1.0), fracao)
	if supersonico:
		cor = Estilo.LARANJA.lerp(Color(1.0, 0.95, 0.8), 0.5 + 0.5 * sin(piscar * 12.0))
	draw_circle(c, r + 14.0, Color(0.02, 0.03, 0.06, 0.55))
	draw_arc(c, r, INICIO, INICIO + VOLTA, 64, Color(1, 1, 1, 0.16), 12.0, true)
	if fracao > 0.005:
		draw_arc(c, r, INICIO, INICIO + VOLTA * fracao, 64, cor, 12.0, true)
	# marquinhas a cada 10 km/h, maiores a cada 20
	var km_maximo := maxima * 3.6
	var km := 0.0
	while km <= km_maximo + 0.1:
		var a := INICIO + VOLTA * km / km_maximo
		var direcao := Vector2(cos(a), sin(a))
		var grande := int(roundf(km)) % 20 == 0
		draw_line(c + direcao * (r - 22.0), c + direcao * (r - (32.0 if grande else 27.0)), Color(1, 1, 1, 0.7 if grande else 0.35), 2.0 if grande else 1.5, true)
		km += 10.0
	# ponteiro: só a ponta, perto do arco, pra não passar por cima do número
	var angulo := INICIO + VOLTA * fracao
	var ponta := Vector2(cos(angulo), sin(angulo))
	draw_line(c + ponta * (r - 40.0), c + ponta * (r + 6.0), Color.WHITE, 4.0, true)
	texto_no_meio(str(roundi(velocidade * 3.6)), c + Vector2(0, 16), 50, Color.WHITE, Estilo.titulo())
	texto_no_meio("km/h", c + Vector2(0, 42), 16, Estilo.TEXTO_APAGADO)
	if supersonico:
		texto_no_meio("SUPERSÔNICO", c + Vector2(0, -r - 24), 17, cor, Estilo.titulo())
	if camera_bola:
		texto_no_meio("CÂMERA DA BOLA", CENTRO_BOOST + Vector2(0, -RAIO_BOOST - 26), 15, Estilo.AZUL.lerp(Color.WHITE, 0.3))


func desenhar_boost() -> void:
	var c := CENTRO_BOOST
	var r := RAIO_BOOST
	var fracao := clampf(boost / 100.0, 0.0, 1.0)
	var cor := Estilo.LARANJA
	if boostando:
		cor = cor.lerp(Color(1.0, 0.9, 0.6), 0.5 + 0.5 * sin(piscar * 20.0))
	elif boost < 1.0:
		cor = Color(0.5, 0.5, 0.55)
	draw_circle(c, r + 10.0, Color(0.02, 0.03, 0.06, 0.6))
	draw_circle(c, r - 10.0, cor * Color(1, 1, 1, 0.12 + 0.18 * fracao))
	draw_arc(c, r, 0.0, TAU, 64, Color(1, 1, 1, 0.1), 12.0, true)
	if fracao > 0.005:
		draw_arc(c, r, -PI / 2.0, -PI / 2.0 + TAU * fracao, 64, cor, 12.0, true)
	texto_no_meio(str(roundi(boost)), c + Vector2(0, 14), 44, Color.WHITE, Estilo.titulo())
	texto_no_meio("BOOST", c + Vector2(0, 36), 14, Estilo.TEXTO_APAGADO)


func texto_no_meio(texto: String, onde: Vector2, tamanho: int, cor: Color, letra: Font = null) -> void:
	if letra == null:
		letra = Estilo.forte()
	draw_string_outline(letra, onde - Vector2(150, 0), texto, HORIZONTAL_ALIGNMENT_CENTER, 300, tamanho, 4, Color(0, 0, 0, 0.6))
	draw_string(letra, onde - Vector2(150, 0), texto, HORIZONTAL_ALIGNMENT_CENTER, 300, tamanho, cor)
