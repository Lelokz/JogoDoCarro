class_name Estilo
extends RefCounted

# Visual das telas (menu, pausa, opções): painéis escuros de vidro, botões com borda que acendem
# quando o mouse passa, letra grossa e inclinada nos títulos. Tudo montado aqui, uma vez só.

const FUNDO := Color(0.05, 0.07, 0.12, 0.9)
const BORDA := Color(0.35, 0.55, 0.9, 0.35)
const AZUL := Color(0.25, 0.6, 1.0)
const LARANJA := Color(1.0, 0.55, 0.15)
const TEXTO := Color(0.93, 0.95, 1.0)
const TEXTO_APAGADO := Color(0.6, 0.65, 0.75)

static var tema_pronto: Theme
static var letra_titulo: FontVariation
static var letra_forte: FontVariation


static func tema() -> Theme:
	if tema_pronto:
		return tema_pronto
	var t := Theme.new()
	t.default_font = forte()
	t.default_font_size = 20
	t.set_color("font_color", "Label", TEXTO)

	t.set_stylebox("panel", "PanelContainer", caixa(FUNDO, BORDA, 16, 1))
	t.set_stylebox("normal", "Button", caixa(Color(0.1, 0.13, 0.2, 0.85), Color(1, 1, 1, 0.08), 10, 1))
	t.set_stylebox("hover", "Button", caixa(Color(0.16, 0.3, 0.55, 0.95), AZUL, 10, 2))
	t.set_stylebox("pressed", "Button", caixa(Color(0.1, 0.22, 0.45, 1.0), AZUL, 10, 2))
	t.set_stylebox("focus", "Button", caixa(Color(0, 0, 0, 0), AZUL.lerp(Color.WHITE, 0.3), 10, 2))
	t.set_stylebox("disabled", "Button", caixa(Color(0.08, 0.09, 0.12, 0.6), Color(1, 1, 1, 0.04), 10, 1))
	t.set_color("font_color", "Button", TEXTO)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_color("font_focus_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", TEXTO_APAGADO)
	t.set_font_size("font_size", "Button", 22)

	t.set_stylebox("normal", "LineEdit", caixa(Color(0.03, 0.04, 0.07, 0.9), Color(1, 1, 1, 0.12), 10, 1))
	t.set_stylebox("focus", "LineEdit", caixa(Color(0, 0, 0, 0), AZUL, 10, 2))
	t.set_color("font_color", "LineEdit", TEXTO)
	t.set_color("font_placeholder_color", "LineEdit", TEXTO_APAGADO)

	# barrinha deslizante: trilho escuro, parte cheia azul e uma bolinha branca
	t.set_stylebox("slider", "HSlider", caixa(Color(0.02, 0.03, 0.05, 0.9), Color(1, 1, 1, 0.1), 6, 1, 4))
	t.set_stylebox("grabber_area", "HSlider", caixa(AZUL, AZUL, 6, 0, 4))
	t.set_stylebox("grabber_area_highlight", "HSlider", caixa(AZUL.lerp(Color.WHITE, 0.2), AZUL, 6, 0, 4))
	t.set_icon("grabber", "HSlider", bolinha(22, Color.WHITE))
	t.set_icon("grabber_highlight", "HSlider", bolinha(24, Color.WHITE))

	t.set_stylebox("background", "ProgressBar", caixa(Color(0.02, 0.03, 0.05, 0.9), Color(1, 1, 1, 0.1), 8, 1))
	t.set_stylebox("fill", "ProgressBar", caixa(AZUL, AZUL, 8, 0))
	t.set_color("font_color", "ProgressBar", Color.WHITE)
	t.set_color("font_color", "CheckButton", TEXTO)
	t.set_color("font_hover_color", "CheckButton", Color.WHITE)
	t.set_stylebox("separator", "HSeparator", caixa(Color(1, 1, 1, 0.1), Color(1, 1, 1, 0.1), 0, 0, 1))
	tema_pronto = t
	return t


static func forte() -> FontVariation:
	if letra_forte == null:
		letra_forte = FontVariation.new()
		letra_forte.base_font = ThemeDB.fallback_font
		letra_forte.variation_embolden = 0.5
	return letra_forte


static func titulo() -> FontVariation:
	# grossa e inclinada pra frente, cara de jogo de corrida
	if letra_titulo == null:
		letra_titulo = FontVariation.new()
		letra_titulo.base_font = ThemeDB.fallback_font
		letra_titulo.variation_embolden = 1.1
		letra_titulo.variation_transform = Transform2D(Vector2(1, 0), Vector2(0.22, 1), Vector2.ZERO)
	return letra_titulo


static func caixa(fundo: Color, borda: Color, raio: int, grossura: int, margem := 14) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fundo
	s.border_color = borda
	s.set_border_width_all(grossura)
	s.set_corner_radius_all(raio)
	s.content_margin_left = margem
	s.content_margin_right = margem
	s.content_margin_top = margem * 0.6
	s.content_margin_bottom = margem * 0.6
	s.anti_aliasing = true
	return s


static func bolinha(tamanho: int, cor: Color) -> ImageTexture:
	var imagem := Image.create(tamanho, tamanho, false, Image.FORMAT_RGBA8)
	var centro := (tamanho - 1) / 2.0
	for y in tamanho:
		for x in tamanho:
			var d := Vector2(x - centro, y - centro).length()
			imagem.set_pixel(x, y, Color(cor, clampf(centro - d + 0.5, 0.0, 1.0)))
	return ImageTexture.create_from_image(imagem)


static func rotulo(texto: String, tamanho := 20, cor := TEXTO, letra: Font = null) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	if letra:
		l.add_theme_font_override("font", letra)
	return l


static func botao(texto: String, ao_clicar: Callable, altura := 52) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size.y = altura
	b.pressed.connect(ao_clicar)
	return b


static func fundo_escuro(alpha := 0.55) -> ColorRect:
	var f := ColorRect.new()
	f.color = Color(0.0, 0.01, 0.03, alpha)
	f.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return f
