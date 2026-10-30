shader_type spatial;

// Gomos claros e escuros + faixa laranja no meio, pra dar pra ver a bola girando.

varying vec3 posicao_local;

void vertex() {
	posicao_local = VERTEX;
}

void fragment() {
	vec3 n = normalize(posicao_local);
	float gomo = step(0.0, sin(atan(n.z, n.x) * 3.0));
	vec3 cor = mix(vec3(0.95), vec3(0.72, 0.74, 0.78), gomo);
	cor = mix(cor, vec3(1.0, 0.55, 0.1), step(abs(n.y), 0.08));
	ALBEDO = cor;
	ROUGHNESS = 0.5;
}
