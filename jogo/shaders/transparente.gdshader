shader_type spatial;
render_mode cull_disabled, depth_draw_never;

// Receita única de tudo que é transparente: paredes da arena, rede do gol e rastro do boost
// (mesmo motivo do superficie.gdshader: um shader só = uma compilação só no navegador).

#include "res://shaders/arena_comum.gdshaderinc"

uniform int tipo = 1;   // 0 = paredes da arena, 1 = cor transparente, 2 = rastro do boost, 3 = rede do gol
uniform vec4 cor : source_color = vec4(1.0, 1.0, 1.0, 0.35);
// paredes: a curva de baixo é sólida (é chão, onde o carro sobe) e vira vidro pra cima,
// com uma faixa de luz na cor do time na emenda
uniform float altura_solida = 2.4;
uniform float altura_vidro = 3.2;
uniform float altura_faixa = 3.0;
uniform float altura_teto = 20.0;
// rastro: as malhas (chama do boost) não guardam cor acima de 1 nos vértices; isto faz brilhar
uniform float forca_luz = 1.0;
uniform float alfa = 1.0;
uniform float suave = 0.0;   // 1 = borda esfumaçada

varying vec4 cor_do_vertice;

void vertex() {
	posicao_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	normal_mundo = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	posicao_local = VERTEX;
	cor_do_vertice = COLOR;   // no rastro, é a cor de cada bolinha (vai sumindo)
}

void fragment() {
	if (tipo == 0) {
		float y = posicao_mundo.y;
		vec3 time = cor_do_time();
		// rampa: borracha escura com placas
		float placas = linhas_da_grade(4.0, 0.03);
		vec3 rampa = mix(vec3(0.06, 0.07, 0.09), time * 0.25, 0.25 + 0.5 * placas);
		// vidro: quase invisível, com os caixilhos aparecendo um pouco
		float caixilho = linhas_da_grade(8.0, 0.05);
		vec3 vidro = mix(vec3(0.75, 0.85, 0.95), time, 0.25);
		float solido = 1.0 - smoothstep(altura_solida, altura_vidro, y);
		ALBEDO = mix(vidro, rampa, solido);
		// pouco reflexo: de lado o vidro refletia o céu inteiro e escondia a torcida
		ROUGHNESS = mix(0.2, 0.6, solido);
		SPECULAR = mix(0.12, 0.5, solido);
		ALPHA = mix(0.04 + 0.3 * caixilho, 0.97, solido);
		// faixas de luz: na emenda da rampa e perto do teto
		float faixa_baixo = faixa(y - altura_faixa, 0.12);
		float faixa_cima = faixa(y - (altura_teto - 3.0), 0.08);
		float luz = max(faixa_baixo, faixa_cima * 0.7);
		EMISSION = time * luz * 3.0;
		ALPHA = max(ALPHA, luz);
	} else if (tipo == 1) {
		ALBEDO = cor.rgb;
		ROUGHNESS = 0.6;
		ALPHA = cor.a;
	} else if (tipo == 3) {
		// rede: fios em quadradinhos na cor do time, com um fundo bem fraquinho
		float fios = linhas_da_grade(0.5, 0.025);
		ALBEDO = mix(cor.rgb * 0.3, mix(cor.rgb, vec3(1.0), 0.4), fios);
		EMISSION = cor.rgb * fios * 0.5;
		ROUGHNESS = 0.7;
		ALPHA = mix(cor.a, 0.9, fios);
	} else {
		ALBEDO = vec3(0.0);
		EMISSION = cor_do_vertice.rgb * forca_luz;
		// borda esfumaçada (fogo, fumaça): de frente é cheio, na beirada some
		float frente = abs(dot(normalize(NORMAL), VIEW));
		ALPHA = clamp(cor_do_vertice.a * alfa * mix(1.0, frente * frente, suave), 0.0, 1.0);
	}
	NORMAL = normal_certa(VIEW_MATRIX);
}
