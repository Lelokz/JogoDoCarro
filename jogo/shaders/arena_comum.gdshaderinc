// Desenho da arena, usado no chão (sólido) e nas paredes (vidro):
// grade em todas as superfícies, metade azul e metade laranja,
// e no chão: linha do meio, círculo central e linha do gol.

uniform vec3 cor_base : source_color = vec3(0.13, 0.15, 0.18);
uniform vec3 cor_linha : source_color = vec3(0.30, 0.33, 0.38);
uniform vec3 cor_azul : source_color = vec3(0.15, 0.4, 1.0);
uniform vec3 cor_laranja : source_color = vec3(1.0, 0.5, 0.1);
uniform float metade_comprimento = 50.0;
uniform float meia_largura_gol = 9.0;

varying vec3 posicao_mundo;
varying vec3 normal_mundo;

void vertex() {
	posicao_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	normal_mundo = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

float grade(vec2 p, float passo, float largura) {
	vec2 distancia = abs(fract(p / passo - 0.5) - 0.5) * passo;
	vec2 borda = fwidth(p);
	vec2 l = 1.0 - smoothstep(vec2(largura), vec2(largura) + borda, distancia);
	return max(l.x, l.y);
}

float faixa(float distancia, float largura) {
	return 1.0 - smoothstep(largura, largura + fwidth(distancia), abs(distancia));
}

float linhas_da_grade() {
	vec3 peso = abs(normal_mundo);
	peso /= peso.x + peso.y + peso.z;
	return grade(posicao_mundo.xz, 4.0, 0.04) * peso.y
		+ grade(posicao_mundo.xy, 4.0, 0.04) * peso.z
		+ grade(posicao_mundo.zy, 4.0, 0.04) * peso.x;
}

vec3 cor_da_arena(float linhas) {
	vec3 time = posicao_mundo.z > 0.0 ? cor_azul : cor_laranja;
	vec3 cor = mix(cor_base, time * 0.35, 0.35);
	cor = mix(cor, cor_linha + time * 0.2, linhas);
	if (normal_mundo.y > 0.9 && posicao_mundo.y < 0.1) {
		float meio = faixa(posicao_mundo.z, 0.2);
		float circulo = faixa(length(posicao_mundo.xz) - 10.0, 0.2);
		float linha_gol = faixa(abs(posicao_mundo.z) - metade_comprimento, 0.2) * step(abs(posicao_mundo.x), meia_largura_gol);
		cor = mix(cor, vec3(0.9), max(max(meio, circulo), linha_gol));
	}
	return cor;
}

vec3 normal_certa(mat4 vista) {
	// a normal vem certa do script, qualquer que seja o lado do triângulo
	return normalize((vista * vec4(normal_mundo, 0.0)).xyz);
}
