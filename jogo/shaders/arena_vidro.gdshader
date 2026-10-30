shader_type spatial;
render_mode cull_disabled, depth_draw_never;

// Paredes da arena: vidro. A câmera atrás da parede ainda vê o carro e a bola.
// A curva de baixo fica quase sólida (é chão, onde o carro sobe) e vai virando vidro pra cima.

#include "res://shaders/arena_comum.gdshaderinc"

uniform float transparencia_vidro = 0.12;
uniform float transparencia_linhas = 0.45;
uniform float altura_solida = 0.6;
uniform float altura_vidro = 3.0;

void fragment() {
	float linhas = linhas_da_grade();
	ALBEDO = cor_da_arena(linhas);
	ROUGHNESS = 0.15;
	METALLIC = 0.2;
	float vidro = mix(transparencia_vidro, transparencia_linhas, linhas);
	ALPHA = mix(0.9, vidro, smoothstep(altura_solida, altura_vidro, posicao_mundo.y));
	NORMAL = normal_certa(VIEW_MATRIX);
}
