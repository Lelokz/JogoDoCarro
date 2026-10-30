shader_type spatial;
render_mode cull_disabled, depth_draw_never;

// Receita única de tudo que é transparente: vidro da arena, rede do gol e rastro do boost
// (mesmo motivo do superficie.gdshader: um shader só = uma compilação só no navegador).

#include "res://shaders/arena_comum.gdshaderinc"

uniform int tipo = 1;   // 0 = vidro da arena, 1 = cor transparente (rede do gol), 2 = rastro do boost
uniform vec4 cor : source_color = vec4(1.0, 1.0, 1.0, 0.35);
// vidro: a curva de baixo fica quase sólida (é chão, onde o carro sobe) e vai virando vidro pra cima
uniform float transparencia_vidro = 0.12;
uniform float transparencia_linhas = 0.45;
uniform float altura_solida = 0.6;
uniform float altura_vidro = 3.0;

varying vec4 cor_do_vertice;

void vertex() {
	posicao_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	normal_mundo = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	posicao_local = VERTEX;
	cor_do_vertice = COLOR;   // no rastro, é a cor de cada bolinha (vai sumindo)
}

void fragment() {
	if (tipo == 0) {
		float linhas = linhas_da_grade();
		ALBEDO = cor_da_arena(linhas);
		ROUGHNESS = 0.15;
		METALLIC = 0.2;
		float vidro = mix(transparencia_vidro, transparencia_linhas, linhas);
		ALPHA = mix(0.9, vidro, smoothstep(altura_solida, altura_vidro, posicao_mundo.y));
	} else if (tipo == 1) {
		ALBEDO = cor.rgb;
		ROUGHNESS = 0.6;
		ALPHA = cor.a;
	} else {
		ALBEDO = vec3(0.0);
		EMISSION = cor_do_vertice.rgb;
		ALPHA = cor_do_vertice.a;
	}
	NORMAL = normal_certa(VIEW_MATRIX);
}
