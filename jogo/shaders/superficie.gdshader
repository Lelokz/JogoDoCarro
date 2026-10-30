shader_type spatial;
render_mode cull_disabled;

// Receita única de tudo que é sólido: chão da arena, campo de teste, carro, bola e pads.
// Cada shader diferente o navegador compila separado na primeira vez que o jogo abre (uns 1 s cada),
// então tudo usa este mesmo; o "tipo" escolhe o desenho.

#include "res://shaders/arena_comum.gdshaderinc"

uniform int tipo = 1;   // 0 = chão da arena, 1 = cor lisa, 2 = bola, 3 = grade do campo de teste
uniform vec4 cor : source_color = vec4(1.0);
uniform float aspereza = 0.8;
uniform vec3 brilho : source_color = vec3(0.0);   // cor que brilha sozinha (pads de boost)
uniform float forca_brilho = 0.0;

void vertex() {
	posicao_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	normal_mundo = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	posicao_local = VERTEX;
}

float linha_fina(vec2 p, float passo, float largura) {
	return grade(p, passo, largura);
}

void fragment() {
	vec3 albedo = cor.rgb;
	if (tipo == 0) {
		albedo = cor_da_arena(linhas_da_grade());
	} else if (tipo == 2) {
		// gomos claros e escuros + faixa laranja, pra dar pra ver a bola girando
		vec3 n = normalize(posicao_local);
		float gomo = step(0.0, sin(atan(n.z, n.x) * 3.0));
		albedo = mix(vec3(0.95), vec3(0.72, 0.74, 0.78), gomo);
		albedo = mix(albedo, vec3(1.0, 0.55, 0.1), step(abs(n.y), 0.08));
	} else if (tipo == 3) {
		// campo de teste: linha fina a cada 1 m, laranja a cada 10 m
		albedo = mix(vec3(0.16, 0.18, 0.21), vec3(0.32, 0.35, 0.40), linha_fina(posicao_mundo.xz, 1.0, 0.02));
		albedo = mix(albedo, vec3(0.95, 0.55, 0.15), linha_fina(posicao_mundo.xz, 10.0, 0.06));
	}
	ALBEDO = albedo;
	ROUGHNESS = aspereza;
	EMISSION = brilho * forca_brilho;
	NORMAL = normal_certa(VIEW_MATRIX);
}
