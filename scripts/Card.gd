extends Control

# ─── SEÑALES ────────────────────────────────────────────────
signal card_drag_started(card)
signal card_dropped(card, pos)
signal card_clicked(card)
signal request_zoom(card_id)

# ─── DATOS ──────────────────────────────────────────────────
@export var card_id: String = ""
@export var card_name: String = "Unknown"
@export var card_type: String = "POKEMON"
@export var pokemon_type: String = "COLORLESS"
@export var hp: int = 60
@export var stage: Variant = 0
@export var evolves_from: String = ""
@export var retreat_cost: int = 1
@export var weakness: String = ""
@export var resistance: String = ""
@export var attacks: Array = []
@export var rarity: String = "COMMON"
@export var card_number: String = ""
@export var image_path: String = ""

# ─── ESTADO ─────────────────────────────────────────────────
var is_draggable: bool = true
var is_dragging:  bool = false
var drag_offset:  Vector2 = Vector2.ZERO
var original_position: Vector2 = Vector2.ZERO
var original_z_index:  int     = 0
var damage_counters:   int     = 0
var attached_energy:   Array   = []
var status_condition:  String  = ""
var is_face_down:   bool = false
var is_highlighted: bool = false
var is_hovered:     bool = false
var is_locked:      bool = false

# ── Estado hover — se resetea siempre desde afuera ──────────
var _is_scaled_up: bool    = false
var _base_scale:   Vector2 = Vector2.ONE
var _base_pos:     Vector2 = Vector2.ZERO   # ← guardamos posición completa, no solo Y
var _hover_tween:  Tween   = null

# ─── CONSTANTES ─────────────────────────────────────────────
const CARD_W = 130
const CARD_H = 182

const TYPE_COLORS = {
	"FIRE":      Color(0.92, 0.42, 0.15),
	"WATER":     Color(0.18, 0.62, 0.88),
	"GRASS":     Color(0.32, 0.72, 0.36),
	"LIGHTNING": Color(0.98, 0.85, 0.10),
	"PSYCHIC":   Color(0.80, 0.25, 0.72),
	"FIGHTING":  Color(0.78, 0.52, 0.30),
	"DARKNESS":  Color(0.22, 0.22, 0.38),
	"METAL":     Color(0.55, 0.62, 0.70),
	"COLORLESS": Color(0.72, 0.70, 0.66),
	"TRAINER":   Color(0.30, 0.30, 0.30),
	"ENERGY":    Color(0.25, 0.25, 0.25),
}

# ─── READY ──────────────────────────────────────────────────
func _ready() -> void:
	custom_minimum_size = Vector2(CARD_W, CARD_H)
	size = Vector2(CARD_W, CARD_H)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_build_card_visual()


# ─── RESET HOVER STATE (llamar desde HandManager al reposicionar) ──
## Debe llamarse cada vez que HandManager actualiza la posición de la carta.
func reset_hover_state() -> void:
	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()
	_is_scaled_up = false
	is_hovered    = false
	# No tocamos position ni scale aquí — HandManager ya los puso correctos


# ─── BUILD VISUAL ───────────────────────────────────────────
func _build_card_visual() -> void:
	for child in get_children():
		child.queue_free()

	self.mouse_filter = Control.MOUSE_FILTER_STOP

	var type_col = TYPE_COLORS.get(
		pokemon_type if card_type == "POKEMON" else card_type,
		Color(0.5, 0.5, 0.5)
	)

	var frame = Panel.new()
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame_style = StyleBoxFlat.new()
	frame_style.bg_color = type_col
	frame_style.set_corner_radius_all(10)
	frame.add_theme_stylebox_override("panel", frame_style)
	add_child(frame)

	var tex_rect = TextureRect.new()
	tex_rect.name         = "CardImage"
	tex_rect.position     = Vector2(4, 4)
	tex_rect.size         = Vector2(CARD_W - 8, CARD_H - 8)
	tex_rect.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if image_path != "" and ResourceLoader.exists(image_path):
		tex_rect.texture = load(image_path)
	add_child(tex_rect)

	var highlight = Panel.new()
	highlight.name         = "Highlight"
	highlight.set_anchors_preset(Control.PRESET_FULL_RECT)
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	highlight.modulate.a   = 0.0
	var hl_style = StyleBoxFlat.new()
	hl_style.bg_color     = Color(0, 0, 0, 0)
	hl_style.border_color = Color(1, 0.95, 0.3)
	hl_style.set_border_width_all(3)
	hl_style.set_corner_radius_all(10)
	highlight.add_theme_stylebox_override("panel", hl_style)
	add_child(highlight)


# ─── INPUT ──────────────────────────────────────────────────
func _gui_input(event: InputEvent) -> void:
	if is_locked: return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# FIX: Guardamos la posición VISUAL actual (incluyendo el offset del hover)
				# para que el drag empiece exactamente donde está la carta visualmente.
				original_position = global_position
				original_z_index  = z_index
				drag_offset       = global_position - event.global_position
				get_viewport().set_input_as_handled()
			else:
				if is_dragging:
					is_dragging = false
					z_index     = original_z_index
					emit_signal("card_dropped", self, event.global_position)
					if is_inside_tree() and not is_queued_for_deletion():
						_animate_return_to_origin()
				else:
					emit_signal("card_clicked", self)
				get_viewport().set_input_as_handled()

		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if card_id != "":
				emit_signal("request_zoom", card_id)
			get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			if not is_draggable: return

			if not is_dragging:
				var dist = (event.global_position + drag_offset - original_position).length()
				if dist > 8:
					is_dragging = true
					z_index     = 500
					# FIX: Al iniciar drag, restaurar escala y posición base
					# para que el drag no arrastre una carta "inflada"
					if _is_scaled_up:
						_cancel_hover_immediately()
					emit_signal("card_drag_started", self)

			if is_dragging:
				global_position = event.global_position + drag_offset
				get_viewport().set_input_as_handled()


# ─── DRAG HELPERS ───────────────────────────────────────────
func _animate_return_to_origin() -> void:
	var tw = create_tween()
	tw.tween_property(self, "global_position", original_position, 0.18) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func confirm_drop() -> void:
	queue_free()

# ─── HOVER ──────────────────────────────────────────────────
func _on_mouse_entered() -> void:
	if is_locked or is_dragging: return
	is_hovered = true

	# FIX PRINCIPAL: Siempre capturamos la posición y escala ACTUALES
	# como base, sin importar si _is_scaled_up era true o false antes.
	# Esto evita que una reposición de HandManager corrompa _base_pos.
	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()

	# Solo guardamos base si NO estamos ya en estado hover
	# (puede entrar dos veces si hay overlap de cartas)
	if not _is_scaled_up:
		_base_scale = scale
		_base_pos   = position
		_is_scaled_up = true

	z_index = 200

	_hover_tween = create_tween().set_parallel(true)
	_hover_tween.tween_property(self, "scale",      _base_scale * 1.06,          0.10)
	_hover_tween.tween_property(self, "position:y", _base_pos.y - 8,             0.10)


func _on_mouse_exited() -> void:
	if is_locked or is_dragging: return
	is_hovered = false

	if not _is_scaled_up: return

	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()

	_is_scaled_up = false
	z_index       = original_z_index

	_hover_tween = create_tween().set_parallel(true)
	# FIX: Volvemos exactamente a _base_pos (X e Y), no solo a Y
	_hover_tween.tween_property(self, "scale",    _base_scale, 0.10)
	_hover_tween.tween_property(self, "position", _base_pos,   0.10)


## Cancela hover instantáneamente sin animación (para cuando arranca drag)
func _cancel_hover_immediately() -> void:
	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()
	if _is_scaled_up:
		scale    = _base_scale
		position = _base_pos
		_is_scaled_up = false


# ─── HELPERS ────────────────────────────────────────────────
func set_highlighted(v: bool) -> void:
	is_highlighted = v
	if has_node("Highlight"):
		get_node("Highlight").modulate.a = 1.0 if v else 0.0

func setup(data: Dictionary) -> void:
	card_id      = data.get("id",           "")
	card_name    = data.get("name",         "")
	card_type    = data.get("type",         "POKEMON")
	pokemon_type = data.get("pokemon_type", "COLORLESS")
	hp           = data.get("hp",           60)
	image_path   = data.get("image",        "")
	_build_card_visual()
