shader_type spatial;

// Grade no chão: linha fina a cada 1 m, linha laranja a cada 10 m.

uniform vec3 cor_base : source_color = vec3(0.16, 0.18, 0.21);
uniform vec3 cor_linha : source_color = vec3(0.32, 0.35, 0.40);
uniform vec3 cor_linha_forte : source_color = vec3(0.95, 0.55, 0.15);

varying vec3 posicao_mundo;

void vertex() {
	posicao_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float linha(vec2 p, float passo, float largura) {
	vec2 distancia = abs(fract(p / passo - 0.5) - 0.5) * passo;
	vec2 borda = fwidth(p);
	vec2 l = 1.0 - smoothstep(vec2(largura), vec2(largura) + borda, distancia);
	return max(l.x, l.y);
}

void fragment() {
	vec2 p = posicao_mundo.xz;
	vec3 cor = mix(cor_base, cor_linha, linha(p, 1.0, 0.02));
	cor = mix(cor, cor_linha_forte, linha(p, 10.0, 0.06));
	ALBEDO = cor;
	ROUGHNESS = 0.9;
}
