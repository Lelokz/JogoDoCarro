shader_type spatial;
render_mode cull_disabled;

// Receita única de tudo que é sólido: gramado, carro, bola, pads, arquibancada, painel de LED...
// Cada shader diferente o navegador compila separado na primeira vez que o jogo abre (uns 1 s cada),
// então tudo usa este mesmo; o "tipo" escolhe o desenho.

#include "res://shaders/arena_comum.gdshaderinc"

// 0 = gramado da arena, 1 = cor lisa, 2 = bola, 3 = grade do campo de teste,
// 4 = torcida da arquibancada, 5 = painel de LED
uniform int tipo = 1;
uniform vec4 cor : source_color = vec4(1.0);
uniform float aspereza = 0.8;
uniform float metal = 0.0;
uniform vec3 brilho : source_color = vec3(0.0);   // cor que brilha sozinha (luzes, pads de boost)
uniform float forca_brilho = 0.0;

const float FI = 1.618034;   // proporção áurea: monta os gomos da bola
const float FI_INV = 0.618034;

void vertex() {
	posicao_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	normal_mundo = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	posicao_local = VERTEX;
}

float sd_caixa(vec2 p, vec2 metade, float raio) {
	vec2 q = abs(p) - metade + raio;
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - raio;
}

vec3 gramado() {
	vec2 p = posicao_mundo.xz;
	float z = abs(p.y);
	// listras de corte a cada 5 m e manchas, pra grama não ficar chapada
	float listra = step(0.5, fract(p.y / 10.0));
	vec3 grama = mix(vec3(0.09, 0.27, 0.08), vec3(0.13, 0.36, 0.11), listra);
	float mancha = ruido(p * 0.3) * 0.55 + ruido(p * 2.1) * 0.3 + ruido(p * 9.0) * 0.15;
	grama *= 0.82 + 0.36 * mancha;
	// área na frente de cada gol com a cor do time
	float area = step(abs(p.x), 18.0) * step(metade_comprimento - 12.0, z) * step(z, metade_comprimento);
	grama = mix(grama, cor_do_time() * 0.6, 0.14 * area);
	if (z > metade_comprimento) {
		grama *= 0.5;   // dentro do gol
	}
	// marcação: meio, círculo, bolinha central, linha do gol, área grande, área pequena e a borda
	float l = faixa(p.y, 0.15);
	l = max(l, faixa(length(p) - 10.0, 0.15));
	l = max(l, 1.0 - smoothstep(0.45, 0.45 + fwidth(length(p)), length(p)));
	l = max(l, faixa(z - metade_comprimento, 0.15) * step(abs(p.x), meia_largura_gol));
	l = max(l, faixa(sd_caixa(vec2(p.x, z - (metade_comprimento - 6.0)), vec2(18.0, 6.0), 0.0), 0.15) * step(z, metade_comprimento));
	l = max(l, faixa(sd_caixa(vec2(p.x, z - (metade_comprimento - 2.5)), vec2(12.0, 2.5), 0.0), 0.15) * step(z, metade_comprimento));
	l = max(l, faixa(sd_caixa(p, vec2(meia_largura - 4.0, metade_comprimento - 4.0), 10.0), 0.15) * step(z, metade_comprimento - 0.2));
	return mix(grama, vec3(0.92, 0.94, 0.9), l * 0.9);
}

void gomo(vec3 n, vec3 p, bool pentagono, inout float d1, inout float d2, inout bool mais_perto_pentagono) {
	float d = dot(n, normalize(p));
	if (d > d1) {
		d2 = d1;
		d1 = d;
		mais_perto_pentagono = pentagono;
	} else if (d > d2) {
		d2 = d;
	}
}

vec3 bola(out float aspereza_bola) {
	// bola de futebol clássica: 12 pentágonos (pontas de um icosaedro) e 20 hexágonos (faces dele)
	vec3 n = normalize(posicao_local);
	float d1 = -2.0;
	float d2 = -2.0;
	bool pentagono = false;
	for (int i = 0; i < 4; i++) {
		vec2 s = vec2((i & 1) == 0 ? 1.0 : -1.0, (i & 2) == 0 ? 1.0 : -1.0);
		gomo(n, vec3(0.0, s.x, s.y * FI), true, d1, d2, pentagono);
		gomo(n, vec3(s.x, s.y * FI, 0.0), true, d1, d2, pentagono);
		gomo(n, vec3(s.y * FI, 0.0, s.x), true, d1, d2, pentagono);
		gomo(n, vec3(s.x * FI_INV, 0.0, s.y * FI), false, d1, d2, pentagono);
		gomo(n, vec3(0.0, s.x * FI, s.y * FI_INV), false, d1, d2, pentagono);
		gomo(n, vec3(s.x * FI, s.y * FI_INV, 0.0), false, d1, d2, pentagono);
	}
	for (int i = 0; i < 8; i++) {
		vec3 s = vec3((i & 1) == 0 ? 1.0 : -1.0, (i & 2) == 0 ? 1.0 : -1.0, (i & 4) == 0 ? 1.0 : -1.0);
		gomo(n, s, false, d1, d2, pentagono);
	}
	float diferenca = d1 - d2;
	float costura = 1.0 - smoothstep(0.012, 0.012 + fwidth(diferenca) * 1.5, diferenca);
	vec3 cor_gomo = pentagono ? vec3(0.1, 0.11, 0.13) : vec3(0.93, 0.94, 0.96);
	aspereza_bola = mix(0.32, 0.7, costura);
	return mix(cor_gomo, vec3(0.05, 0.05, 0.06), costura);
}

vec3 torcida(vec2 uv) {
	// cada cadeira tem 0,55 m de largura e cada degrau 0,85 m; o sorteio escolhe quem senta ali
	vec2 c = uv / vec2(0.55, 0.85);
	vec2 cadeira = floor(c);
	float s = sorteio(cadeira);
	vec2 f = fract(c);
	f.y -= 0.05 * max(sin(TIME * 4.0 + s * 40.0), 0.0);   // uns pulando
	vec3 roupa;
	if (s < 0.55) {
		roupa = cor_do_time() * (0.6 + 0.5 * sorteio(cadeira + 7.0));
	} else if (s < 0.72) {
		roupa = vec3(0.85);
	} else {
		roupa = vec3(sorteio(cadeira + 1.0), sorteio(cadeira + 2.0), sorteio(cadeira + 3.0)) * 0.7;
	}
	float ocupada = step(0.12, sorteio(cadeira + 9.0));
	float corpo = 1.0 - step(1.0, length((f - vec2(0.5, 0.3)) / vec2(0.34, 0.28)));
	float cabeca = 1.0 - step(1.0, length((f - vec2(0.5, 0.68)) / 0.15));
	vec3 pele = mix(vec3(0.95, 0.75, 0.6), vec3(0.35, 0.22, 0.15), sorteio(cadeira + 5.0));
	vec3 assento = vec3(0.1, 0.11, 0.14) * (0.7 + 0.3 * fract(c.y));
	vec3 perto = mix(assento, roupa, corpo * ocupada);
	perto = mix(perto, pele, cabeca * ocupada);
	// de longe as cadeiras ficam menores que um pixel: troca pela cor média (com manchas), senão pisca
	float longe = smoothstep(0.25, 0.7, max(fwidth(c.x), fwidth(c.y)));
	vec3 media = mix(vec3(0.08, 0.09, 0.11), cor_do_time() * 0.5 + vec3(0.05), 0.4);
	media *= 0.35 + 1.3 * ruido(c * vec2(0.2, 0.5));
	vec3 cor_final = mix(perto, media, longe);
	// escadas a cada 24 m e um corredor no meio da subida
	float escada = 1.0 - step(0.05, fract(uv.x / 24.0));
	float corredor = 1.0 - step(0.7, abs(uv.y - 19.0));
	return mix(cor_final, vec3(0.26, 0.27, 0.29), max(escada, corredor));
}

vec3 painel_de_led(vec2 uv) {
	// setas correndo na cor do time, com faixas brancas de vez em quando
	float x = uv.x * 0.5 - TIME * 2.5;
	float seta = step(0.5, fract(x / 1.5 + abs(uv.y - 0.5) * 0.8));
	float bloco = step(0.82, fract(uv.x / 40.0 + TIME * 0.05));
	vec3 c = mix(cor_do_time() * mix(0.25, 1.0, seta), vec3(1.0) * mix(0.4, 1.0, seta), bloco);
	return c;
}

void fragment() {
	vec3 albedo = cor.rgb;
	float rugosidade = aspereza;
	vec3 luz = brilho * forca_brilho;
	if (tipo == 0) {
		albedo = gramado();
		rugosidade = 0.9;
	} else if (tipo == 2) {
		albedo = bola(rugosidade);
	} else if (tipo == 3) {
		// campo de teste: linha fina a cada 1 m, laranja a cada 10 m
		albedo = mix(vec3(0.16, 0.18, 0.21), vec3(0.32, 0.35, 0.40), grade(posicao_mundo.xz, 1.0, 0.02));
		albedo = mix(albedo, vec3(0.95, 0.55, 0.15), grade(posicao_mundo.xz, 10.0, 0.06));
	} else if (tipo == 4) {
		albedo = torcida(UV);
		rugosidade = 0.95;
	} else if (tipo == 5) {
		vec3 led = painel_de_led(UV);
		albedo = led * 0.2;
		luz = led * 1.8;
		rugosidade = 0.4;
	}
	ALBEDO = albedo;
	ROUGHNESS = rugosidade;
	METALLIC = metal;
	EMISSION = luz;
	NORMAL = normal_certa(VIEW_MATRIX);
}
