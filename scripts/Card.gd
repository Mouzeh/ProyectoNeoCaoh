extends Control

# ─── SEÑALES ────────────────────────────────────────────────
signal card_drag_started(card)
signal card_dropped(card, pos)
signal card_clicked(card)

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
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var original_position: Vector2 = Vector2.ZERO
var original_y: float = 0.0
var original_z_index: int = 0
var damage_counters: int = 0
var attached_energy: Array = []
var status_condition: String = ""
var is_face_down: bool = false
var is_highlighted: bool = false
var zoom_overlay: Control = null
var is_hovered: bool = false

# ── NUEVO: bloquea hover/drag para cuando se muestra en zoom de acción ───────
var is_locked: bool = false

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

# ─── BUILD VISUAL ───────────────────────────────────────────
func _build_card_visual() -> void:
	for child in get_children():
		child.queue_free()

	self.mouse_filter = Control.MOUSE_FILTER_STOP

	var type_col = TYPE_COLORS.get(pokemon_type if card_type == "POKEMON" else card_type, Color(0.5, 0.5, 0.5))

	var frame = Panel.new()
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame_style = StyleBoxFlat.new()
	frame_style.bg_color = type_col
	frame_style.set_corner_radius_all(10)
	frame.add_theme_stylebox_override("panel", frame_style)
	add_child(frame)

	var tex_rect = TextureRect.new()
	tex_rect.name = "CardImage"
	tex_rect.position = Vector2(4, 4)
	tex_rect.size = Vector2(CARD_W - 8, CARD_H - 8)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if image_path != "" and ResourceLoader.exists(image_path):
		tex_rect.texture = load(image_path)
	add_child(tex_rect)

	var name_lbl = Label.new()
	name_lbl.text = card_name
	name_lbl.position = Vector2(8, CARD_H - 50)
	name_lbl.size = Vector2(CARD_W - 16, 40)
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(name_lbl)

	var highlight = Panel.new()
	highlight.name = "Highlight"
	highlight.set_anchors_preset(Control.PRESET_FULL_RECT)
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	highlight.modulate.a = 0.0
	var hl_style = StyleBoxFlat.new()
	hl_style.bg_color = Color(0, 0, 0, 0)
	hl_style.border_color = Color(1, 0.95, 0.3)
	hl_style.set_border_width_all(3)
	hl_style.set_corner_radius_all(10)
	highlight.add_theme_stylebox_override("panel", hl_style)
	add_child(highlight)

# ─── INPUT ──────────────────────────────────────────────────
func _gui_input(event: InputEvent) -> void:
	# Si está bloqueada, ignorar todo input
	if is_locked:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				original_position = global_position
				original_y = position.y
				original_z_index = z_index
				drag_offset = global_position - event.global_position
				get_viewport().set_input_as_handled()
			else:
				if is_dragging:
					is_dragging = false
					z_index = original_z_index
					emit_signal("card_dropped", self, event.global_position)
					if is_inside_tree() and not is_queued_for_deletion():
						_animate_return_to_origin()
				else:
					emit_signal("card_clicked", self)
				get_viewport().set_input_as_handled()

		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# Solo zoom con clic derecho si la carta está en la mano (draggable)
			if is_draggable:
				_show_zoom()
			get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			if not is_draggable:
				return

			if not is_dragging:
				var dist = (event.global_position + drag_offset - original_position).length()
				if dist > 8:
					is_dragging = true
					z_index = 500
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
# NOTA: El zoom con espacio fue eliminado de Card.gd.
# BattleBoard._unhandled_input maneja KEY_SPACE globalmente
# para evitar que múltiples cartas abran zoom simultáneamente.

func _on_mouse_entered() -> void:
	# Si está bloqueada, no hacer nada
	if is_locked:
		return
	is_hovered = true
	if is_dragging:
		return
	original_y = position.y
	z_index = 200
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector2(1.08, 1.08), 0.1)
	tw.tween_property(self, "position:y", original_y - 14, 0.1)

func _on_mouse_exited() -> void:
	# Si está bloqueada, no hacer nada
	if is_locked:
		return
	is_hovered = false
	if is_dragging:
		return
	z_index = original_z_index
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
	tw.tween_property(self, "position:y", original_y, 0.1)

func _show_zoom() -> void:
	if zoom_overlay != null or image_path == "":
		return
	zoom_overlay = Control.new()
	zoom_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	zoom_overlay.z_index = 999
	var bd = ColorRect.new()
	bd.set_anchors_preset(Control.PRESET_FULL_RECT)
	bd.color = Color(0, 0, 0, 0.8)
	zoom_overlay.add_child(bd)
	var img = TextureRect.new()
	if ResourceLoader.exists(image_path):
		img.texture = load(image_path)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.size = Vector2(400, 560)
	var vp_size = Vector2(get_viewport().size)
	img.position = (vp_size - img.size) / 2.0
	zoom_overlay.add_child(img)
	get_tree().root.add_child(zoom_overlay)
	bd.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			_close_zoom()
	)

func _close_zoom() -> void:
	if zoom_overlay:
		zoom_overlay.queue_free()
		zoom_overlay = null

# ─── HELPERS ────────────────────────────────────────────────
func set_highlighted(v: bool) -> void:
	is_highlighted = v
	if has_node("Highlight"):
		get_node("Highlight").modulate.a = 1.0 if v else 0.0

func setup(data: Dictionary) -> void:
	card_id = data.get("id", "")
	card_name = data.get("name", "")
	card_type = data.get("type", "POKEMON")
	pokemon_type = data.get("pokemon_type", "COLORLESS")
	hp = data.get("hp", 60)
	image_path = data.get("image", "")
	_build_card_visual()
