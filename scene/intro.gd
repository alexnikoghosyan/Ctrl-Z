extends Node

const CHILD_DIALOGUE := "res://dialogue_child_panel.png"
const ROBOT_DIALOGUE := "res://dialogue_robot_panel.png"
const TYPEWRITER_SPEED := 32.0

var player_in_area := false
var table_view_active := false
var book_is_open := false
var animation_busy := false
var opening_book := false
var ending_started := false

var dialogue_panel: TextureRect
var dialogue_text: Label
var dialogue_index := 0
var conversation_finished := false
var typing_dialogue := false
var typewriter_elapsed := 0.0
const DIALOGUE_LINES := [
	"Երեխա․ «Ի՞նչ է տեղի ունեցել Չեռնոբիլի ատոմակայանի հետ»։",
	"Ռոբոտ-շուն․ «1986-ին ռեակտորի վթարի հետևանքով մեծ քանակությամբ ռադիոակտիվ նյութեր տարածվեցին»։",
	"Երեխա․ «Իսկ ի՞նչ եղավ այնտեղ ապրող մարդկանց հետ»։",
	"Ռոբոտ-շուն․ «Մարդկանց տարհանեցին, իսկ վթարի հետևանքները երկար տարիներ ազդեցին շրջակա միջավայրի վրա»։"
]

@onready var stand_up: Node = $"Intro/StandUp"
@onready var standing_down: Node = $"Intro/Standing_Down"
@onready var player_body: CharacterBody2D = $"Intro/StandUp/CharacterBody2D"
@onready var book_sprite: AnimatedSprite2D = $"Intro/Standing_Down/AnimatedSprite2D"
@onready var interaction_area: Area2D = $"Intro/StandUp/Area2D"
@onready var bed_area: Area2D = $"Intro/StandUp/Area2D2"


func _ready() -> void:
	interaction_area.body_entered.connect(_on_interaction_body_entered)
	interaction_area.body_exited.connect(_on_interaction_body_exited)
	interaction_area.monitoring = true
	bed_area.body_entered.connect(_on_bed_body_entered)

	_create_dialogue_ui()

	book_sprite.animation = "default"
	book_sprite.sprite_frames.set_animation_loop("default", false)
	book_sprite.animation_finished.connect(_on_book_animation_finished)
	book_sprite.stop()
	book_sprite.frame = book_sprite.sprite_frames.get_frame_count("default") - 1

	_set_branch_active(stand_up, true)
	_set_branch_active(standing_down, false)


func _process(_delta: float) -> void:
	if not table_view_active:
		if player_in_area and Input.is_action_just_pressed("E"):
			table_view_active = true
			_set_branch_active(stand_up, false)
			_set_branch_active(standing_down, true)
			book_sprite.stop()
			book_sprite.frame = book_sprite.sprite_frames.get_frame_count("default") - 1
		return

	if animation_busy:
		return

	if typing_dialogue:
		typewriter_elapsed += _delta
		var visible_count := int(typewriter_elapsed * TYPEWRITER_SPEED)
		dialogue_text.visible_characters = mini(visible_count, dialogue_text.text.length())
		if dialogue_text.visible_characters >= dialogue_text.text.length():
			typing_dialogue = false
			if dialogue_index == DIALOGUE_LINES.size() - 1:
				conversation_finished = true
		if typing_dialogue:
			if Input.is_action_just_pressed("Right"):
				dialogue_text.visible_characters = -1
				typing_dialogue = false
				if dialogue_index == DIALOGUE_LINES.size() - 1:
					conversation_finished = true
			return

	if not book_is_open:
		if Input.is_action_just_pressed("Right"):
			_set_book_open(true)
		return

	if Input.is_action_just_pressed("Right"):
		if dialogue_index < DIALOGUE_LINES.size() - 1:
			dialogue_index += 1
			_show_dialogue_line()
	elif Input.is_action_just_pressed("Left"):
		if conversation_finished:
			_set_book_open(false)
		elif dialogue_index > 0:
			dialogue_index -= 1
			_show_dialogue_line()


func _input(event: InputEvent) -> void:
	if not table_view_active or animation_busy:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var local_mouse := book_sprite.get_local_mouse_position()
		var frame_texture := book_sprite.sprite_frames.get_frame_texture(book_sprite.animation, book_sprite.frame)
		var frame_rect := Rect2(-frame_texture.get_size() * 0.5, frame_texture.get_size())
		if frame_rect.has_point(local_mouse):
			if not book_is_open:
				_set_book_open(true)
			elif conversation_finished:
				_set_book_open(false)


func _set_book_open(open: bool) -> void:
	opening_book = open
	animation_busy = true
	if open:
		book_sprite.frame = book_sprite.sprite_frames.get_frame_count("default") - 1
		book_sprite.play_backwards("default")
	else:
		book_sprite.frame = 0
		book_sprite.play("default")


func _create_dialogue_ui() -> void:
	var panel_texture := load(CHILD_DIALOGUE) as Texture2D
	if panel_texture == null:
		push_error("Could not load child dialogue panel: " + CHILD_DIALOGUE)
		return

	var layer := CanvasLayer.new()
	layer.name = "DialogueLayer"
	layer.layer = 5
	add_child(layer)

	dialogue_panel = TextureRect.new()
	dialogue_panel.name = "ChildDialoguePanel"
	dialogue_panel.texture = panel_texture
	dialogue_panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dialogue_panel.stretch_mode = TextureRect.STRETCH_SCALE
	dialogue_panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	dialogue_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var viewport_size := get_viewport().get_visible_rect().size
	var panel_width := minf(1100.0, viewport_size.x - 32.0)
	var panel_height := panel_width * float(panel_texture.get_height()) / float(panel_texture.get_width())
	dialogue_panel.position = Vector2((viewport_size.x - panel_width) * 0.5, viewport_size.y - panel_height - 12.0)
	dialogue_panel.size = Vector2(panel_width, panel_height)
	dialogue_panel.visible = false
	layer.add_child(dialogue_panel)

	dialogue_text = Label.new()
	dialogue_text.name = "ChildQuestion"
	dialogue_text.text = "Երեխա․ «Ի՞նչ է տեղի ունեցել Չեռնոբիլի ատոմակայանի հետ»։"
	dialogue_text.position = Vector2(panel_width * 0.255, panel_height * 0.25)
	dialogue_text.size = Vector2(panel_width * 0.72, panel_height * 0.50)
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	dialogue_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dialogue_text.add_theme_font_size_override("font_size", 19)
	dialogue_text.add_theme_color_override("font_color", Color("#342a29"))
	dialogue_panel.add_child(dialogue_text)


func _on_interaction_body_entered(body: Node2D) -> void:
	if body == player_body:
		player_in_area = true


func _on_interaction_body_exited(body: Node2D) -> void:
	if body == player_body:
		player_in_area = false


func _on_bed_body_entered(body: Node2D) -> void:
	if body != player_body or ending_started:
		return

	ending_started = true
	player_body.velocity = Vector2.ZERO
	player_body.global_position = bed_area.global_position
	player_body.set_physics_process(false)
	player_body.set_process(false)

	var player_sprite: AnimatedSprite2D = player_body.get_node("AnimatedSprite2D")
	player_sprite.stop()
	player_sprite.play("default")
	player_sprite.scale = Vector2(0.7, 0.7)
	player_sprite.rotation = PI / 2.0


func _on_book_animation_finished() -> void:
	book_sprite.stop()
	if opening_book:
		book_sprite.frame = 0
		book_is_open = true
		dialogue_index = 0
		conversation_finished = false
		_show_dialogue_line()
		dialogue_panel.visible = true
	else:
		book_sprite.frame = book_sprite.sprite_frames.get_frame_count("default") - 1
		book_is_open = false
		dialogue_panel.visible = false
	animation_busy = false


func _show_dialogue_line() -> void:
	var line: String = DIALOGUE_LINES[dialogue_index]
	var panel_path := ROBOT_DIALOGUE if line.begins_with("Ռոբոտ-շուն") else CHILD_DIALOGUE
	dialogue_panel.texture = load(panel_path) as Texture2D
	dialogue_text.text = line
	dialogue_text.visible_characters = 0
	typewriter_elapsed = 0.0
	typing_dialogue = true
	if dialogue_index == DIALOGUE_LINES.size() - 1:
		conversation_finished = false


func _set_branch_active(branch: Node, active: bool) -> void:
	_set_node_active(branch, active)


func _set_node_active(node: Node, active: bool) -> void:
	if node is CanvasItem:
		node.visible = active

	if node is Camera2D:
		node.enabled = active

	if node is CharacterBody2D:
		node.set_process(active)
		node.set_physics_process(active)
		if not active:
			node.velocity = Vector2.ZERO

	if node is AnimatedSprite2D and not active:
		node.stop()

	# Keep the interaction zone monitoring while the room branch is hidden.
	if node is Area2D:
		node.monitoring = true

	for child in node.get_children():
		_set_node_active(child, active)
