class_name Comandos
extends RefCounted

# O que um jogador está apertando. O carro só olha pra isso: no carro de quem joga aqui
# vem do teclado/controle; no carro de um amigo, vem pela rede.

var acelerador := 0.0   # -1 ré … 1 acelerar
var direcao := 0.0      # -1 esquerda … 1 direita
var inclinar := 0.0     # no ar: -1 nariz pra cima … 1 nariz pra baixo
var rolar := 0.0        # -1 esquerda … 1 direita
var pulo := false
var boost := false
var freio_mao := false
# contam quantas vezes apertou: se um pacote se perder na rede, o toque não some
var pulos := 0
var desviradas := 0


func ler_teclado() -> void:
	acelerador = Input.get_axis("re", "acelerar")
	direcao = Input.get_axis("esquerda", "direita")
	inclinar = Input.get_axis("nariz_cima", "nariz_baixo")
	rolar = Input.get_axis("rolar_esquerda", "rolar_direita")
	pulo = Input.is_action_pressed("pulo")
	boost = Input.is_action_pressed("boost")
	freio_mao = Input.is_action_pressed("freio_mao")
	if Input.is_action_just_pressed("pulo"):
		pulos += 1
	if Input.is_action_just_pressed("desvirar"):
		desviradas += 1


func para_rede() -> Array:
	return [acelerador, direcao, inclinar, rolar, int(pulo) | int(boost) << 1 | int(freio_mao) << 2, pulos, desviradas]


func de_rede(dados: Array) -> void:
	if dados.size() != 7:
		return
	acelerador = clampf(dados[0], -1.0, 1.0)
	direcao = clampf(dados[1], -1.0, 1.0)
	inclinar = clampf(dados[2], -1.0, 1.0)
	rolar = clampf(dados[3], -1.0, 1.0)
	pulo = dados[4] & 1 != 0
	boost = dados[4] & 2 != 0
	freio_mao = dados[4] & 4 != 0
	pulos = dados[5]
	desviradas = dados[6]
