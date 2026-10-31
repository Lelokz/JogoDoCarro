// Coisas compartilhadas pelos dois shaders (superficie.gdshader e transparente.gdshader):
// cores dos times, tamanho do campo, grade das paredes e a normal certa dos dois lados do triângulo.

uniform vec3 cor_azul : source_color = vec3(0.15, 0.4, 1.0);
uniform vec3 cor_laranja : source_color = vec3(1.0, 0.5, 0.1);
uniform float metade_comprimento = 50.0;
uniform float meia_largura = 40.0;
uniform float meia_largura_gol = 9.0;

varying vec3 posicao_mundo;
varying vec3 normal_mundo;
varying vec3 posicao_local;

float grade(vec2 p, float passo, float largura) {
	vec2 distancia = abs(fract(p / passo - 0.5) - 0.5) * passo;
	vec2 borda = fwidth(p);
	vec2 l = 1.0 - smoothstep(vec2(largura), vec2(largura) + borda, distancia);
	return max(l.x, l.y);
}

float faixa(float distancia, float largura) {
	return 1.0 - smoothstep(largura, largura + fwidth(distancia), abs(distancia));
}

float linhas_da_grade(float passo, float largura) {
	// grade "projetada" dos três lados, pra funcionar no chão, na parede e na curva
	vec3 peso = abs(normal_mundo);
	peso /= peso.x + peso.y + peso.z;
	return grade(posicao_mundo.xz, passo, largura) * peso.y
		+ grade(posicao_mundo.xy, passo, largura) * peso.z
		+ grade(posicao_mundo.zy, passo, largura) * peso.x;
}

vec3 cor_do_time() {
	return posicao_mundo.z > 0.0 ? cor_azul : cor_laranja;
}

float sorteio(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float ruido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(sorteio(i), sorteio(i + vec2(1.0, 0.0)), f.x),
		mix(sorteio(i + vec2(0.0, 1.0)), sorteio(i + vec2(1.0, 1.0)), f.x), f.y);
}

vec3 normal_certa(mat4 vista) {
	// a normal vem certa do script, qualquer que seja o lado do triângulo
	return normalize((vista * vec4(normal_mundo, 0.0)).xyz);
}
