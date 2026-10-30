class_name Materiais
extends RefCounted

# Todos os materiais do jogo saem daqui, de só dois shaders (sólido e transparente).
# Medido em 30/10/2026: cada shader diferente custava ~1 s pro navegador compilar na primeira
# vez que o jogo abria; com tudo em dois, o "Treinar sozinho" abre na hora.

const SOLIDO := preload("res://shaders/superficie.gdshader")
const TRANSPARENTE := preload("res://shaders/transparente.gdshader")


static func liso(cor: Color, aspereza := 0.8, brilho := Color.BLACK, forca_brilho := 0.0) -> ShaderMaterial:
	var m := novo(SOLIDO, 1)
	m.set_shader_parameter("cor", cor)
	m.set_shader_parameter("aspereza", aspereza)
	m.set_shader_parameter("brilho", brilho)
	m.set_shader_parameter("forca_brilho", forca_brilho)
	return m


static func chao_da_arena(metade_comprimento: float, meia_largura_gol: float) -> ShaderMaterial:
	var m := novo(SOLIDO, 0)
	m.set_shader_parameter("metade_comprimento", metade_comprimento)
	m.set_shader_parameter("meia_largura_gol", meia_largura_gol)
	return m


static func bola() -> ShaderMaterial:
	var m := novo(SOLIDO, 2)
	m.set_shader_parameter("aspereza", 0.5)
	return m


static func grade() -> ShaderMaterial:
	var m := novo(SOLIDO, 3)
	m.set_shader_parameter("aspereza", 0.9)
	return m


static func vidro(metade_comprimento: float) -> ShaderMaterial:
	var m := novo(TRANSPARENTE, 0)
	m.set_shader_parameter("metade_comprimento", metade_comprimento)
	return m


static func transparente(cor: Color) -> ShaderMaterial:
	var m := novo(TRANSPARENTE, 1)
	m.set_shader_parameter("cor", cor)
	return m


static func rastro() -> ShaderMaterial:
	return novo(TRANSPARENTE, 2)


static func novo(shader: Shader, tipo: int) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = shader
	m.set_shader_parameter("tipo", tipo)
	return m
