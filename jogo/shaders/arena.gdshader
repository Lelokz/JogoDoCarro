shader_type spatial;
render_mode cull_disabled;

// Chão da arena: sólido.

#include "res://shaders/arena_comum.gdshaderinc"

void fragment() {
	ALBEDO = cor_da_arena(linhas_da_grade());
	ROUGHNESS = 0.8;
	NORMAL = normal_certa(VIEW_MATRIX);
}
