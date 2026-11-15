extends Node

const CHILD_DIALOGUE := "res://dialogue_child_panel.png"
const ROBOT_DIALOGUE := "res://dialogue_robot_panel.png"
const ROBOT_DIALOGUE_EXPANDED := "res://dialogue_robot_panel_expanded.png"
const PIXEL_FONT := "res://Fonts/BlockBlueprint.ttf"
const SLEEPING_BEDROOM := "res://bedroom_sleeping.png"
const CHERNOBYL_SHEET := "res://chernobyl_environment_sheet.png"
const GUARD_SPRITE := "res://Images/chernobyl_guard_walk.png"
const CHERNOBYL_SELECTED_FRAME := 2 # Third still from the lower row of the supplied sheet.
const CHERNOBYL_FRAME_RECTS := [
	Rect2(6, 242, 535, 186), Rect2(548, 242, 535, 186),
	Rect2(1091, 242, 535, 186), Rect2(1634, 242, 535, 186),
	Rect2(6, 459, 535, 186), Rect2(548, 459, 535, 186),
	Rect2(1091, 459, 535, 186), Rect2(1634, 459, 535, 186)
]
const ROOSTER_CROW := "res://Music/rooster_crow.mp3"
const CHERNOBYL_AMBIENCE := "res://Music/chernobyl_ambience.mp3"
const ROBOT_DOG_BARK := "res://Music/robot_dog_bark.mp3"
const TYPEWRITER_SPEED := 32.0
const BOMB_COUNTDOWN_SECONDS := 20.0 * 60.0
const GUARD_POSITION := Vector2(760.0, 506.0)
const REMOTE_PANEL_POSITION := Vector2(1010.0, 545.0)

var player_in_area := false
var bed_player_in_area := false
var table_view_active := false
var book_is_open := false
var animation_busy := false
var opening_book := false
var ending_started := false
var mission_active := false
var guard_talked := false
var countdown_active := false
var code_solved := false
var bomb_disarmed := false
var bomb_exploded := false
var mission_dialogue_open := false
var mission_dialogue_source := ""
var mission_dialogue_lines: Array[String] = []
var mission_dialogue_index := 0
var countdown_seconds := BOMB_COUNTDOWN_SECONDS

var dialogue_panel: TextureRect
var dialogue_text: Label
var robot_dialogue_texture: Texture2D
var fade_to_black: ColorRect
var rooster_player: AudioStreamPlayer
var chernobyl_ambience_player: AudioStreamPlayer
var dog_bark_player: AudioStreamPlayer
var chernobyl_background: TextureRect
var chernobyl_frames: Array[Texture2D] = []
var chernobyl_frame_index := 0
var guard_sprite: AnimatedSprite2D
var remote_panel_marker: PanelContainer
var mission_hud_layer: CanvasLayer
var countdown_label: Label
var interaction_hint: Label
var terminal_overlay: Control
var terminal_code_input: LineEdit
var terminal_feedback: Label
var terminal_morse: Label
var terminal_red_button: Button
var terminal_switch_row: HBoxContainer
var dialogue_index := 0
var conversation_finished := false
var typing_dialogue := false
var typewriter_elapsed := 0.0
const DIALOGUE_LINES := [
	"Երեխա: Ինչ պատահեց Չեռնոբիլում?",
	"Ռոբոտ-շուն: 1986-ին ատոմակայանում վթար եղավ:\nՌադիացիա տարածվեց:",
	"Երեխա: Ինչ եղավ մարդկանց հետ?",
	"Ռոբոտ-շուն: Մարդկանց տարհանեցին:\nՏարածքը երկար տարիներ վտանգավոր մնաց."
]

@onready var stand_up: Node = $"Intro/StandUp"
@onready var standing_down: Node = $"Intro/Standing_Down"
@onready var player_body: CharacterBody2D = $"Intro/StandUp/CharacterBody2D"
@onready var bedroom_background: TextureRect = $"Intro/StandUp/TextureRect"
@onready var book_sprite: AnimatedSprite2D = $"Intro/Standing_Down/AnimatedSprite2D"
@onready var interaction_area: Area2D = $"Intro/StandUp/Area2D"
@onready var bed_area: Area2D = $"Intro/StandUp/Area2D2"
@onready var bedroom_collisions: StaticBody2D = $"Intro/StandUp/StaticBody2D"


func _ready() -> void:
	interaction_area.body_entered.connect(_on_interaction_body_entered)
	interaction_area.body_exited.connect(_on_interaction_body_exited)
	interaction_area.monitoring = true
	bed_area.body_entered.connect(_on_bed_body_entered)
	bed_area.body_exited.connect(_on_bed_body_exited)

	_create_dialogue_ui()
	_create_fade_overlay()
	_create_rooster_player()
	_create_chernobyl_audio()
	_create_dog_bark_player()
	_create_chernobyl_environment()
	_create_mission_hud()

	book_sprite.animation = "default"
	book_sprite.sprite_frames.set_animation_loop("default", false)
	book_sprite.animation_finished.connect(_on_book_animation_finished)
	book_sprite.stop()
	book_sprite.frame = book_sprite.sprite_frames.get_frame_count("default") - 1

	_set_branch_active(stand_up, true)
	_set_branch_active(standing_down, false)


func _process(_delta: float) -> void:
	if mission_active or mission_dialogue_open or terminal_overlay != null:
		_update_bomb_countdown(_delta)
		if bomb_exploded:
			return
		if mission_dialogue_open:
			if Input.is_action_just_pressed("E") or Input.is_action_just_pressed("Right"):
				_advance_mission_dialogue()
			return
		if terminal_overlay != null:
			return
		_update_mission_prompt()
		if Input.is_action_just_pressed("E"):
			_handle_mission_interaction()
		return

	if not table_view_active:
		if bed_player_in_area and Input.is_action_just_pressed("E"):
			_start_sleep()
			return
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
		if conversation_finished and dialogue_index == DIALOGUE_LINES.size() - 1:
			_close_table_view()
		elif dialogue_index < DIALOGUE_LINES.size() - 1:
			dialogue_index += 1
			_show_dialogue_line()
	elif Input.is_action_just_pressed("Left"):
		if conversation_finished and dialogue_index == DIALOGUE_LINES.size() - 1:
			_close_table_view()
		elif dialogue_index > 0:
			dialogue_index -= 1
			_show_dialogue_line()


func _input(event: InputEvent) -> void:
	if bomb_exploded and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Z and event.ctrl_pressed:
			_rewind_after_explosion()
			get_viewport().set_input_as_handled()
			return

	if not table_view_active or animation_busy:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if conversation_finished and dialogue_index == DIALOGUE_LINES.size() - 1 and dialogue_panel.get_global_rect().has_point(event.position):
			_close_table_view()
			get_viewport().set_input_as_handled()
			return

		var local_mouse := book_sprite.get_local_mouse_position()
		var frame_texture := book_sprite.sprite_frames.get_frame_texture(book_sprite.animation, book_sprite.frame)
		var frame_rect := Rect2(-frame_texture.get_size() * 0.5, frame_texture.get_size())
		if frame_rect.has_point(local_mouse):
			if not book_is_open:
				_set_book_open(true)
			elif conversation_finished:
				_set_book_open(false)


func _close_table_view() -> void:
	table_view_active = false
	book_is_open = false
	conversation_finished = false
	typing_dialogue = false
	dialogue_panel.visible = false
	book_sprite.stop()
	book_sprite.frame = book_sprite.sprite_frames.get_frame_count("default") - 1
	_set_branch_active(standing_down, false)
	_set_branch_active(stand_up, true)


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
	var panel_height := panel_width * float(panel_texture.get_height()) / float(panel_texture.get_width()) * 0.90
	var expanded_robot_sheet := load(ROBOT_DIALOGUE_EXPANDED) as Texture2D
	if expanded_robot_sheet != null:
		var robot_panel_crop := AtlasTexture.new()
		robot_panel_crop.atlas = expanded_robot_sheet
		robot_panel_crop.region = Rect2(0.0, 88.0, expanded_robot_sheet.get_width(), 543.0)
		robot_dialogue_texture = robot_panel_crop
	else:
		robot_dialogue_texture = load(ROBOT_DIALOGUE) as Texture2D
	dialogue_panel.position = Vector2((viewport_size.x - panel_width) * 0.5, viewport_size.y - panel_height - 12.0)
	dialogue_panel.size = Vector2(panel_width, panel_height)
	dialogue_panel.visible = false
	layer.add_child(dialogue_panel)

	dialogue_text = Label.new()
	dialogue_text.name = "ChildQuestion"
	dialogue_text.text = "Երեխա: Ինչ պատահեց Չեռնոբիլում?"
	dialogue_text.position = Vector2(panel_width * 0.33, panel_height * 0.14)
	dialogue_text.size = Vector2(panel_width * 0.63, panel_height * 0.72)
	dialogue_text.custom_maximum_size = dialogue_text.size
	dialogue_text.scale = Vector2.ONE
	dialogue_text.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	dialogue_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dialogue_text.add_theme_font_size_override("font_size", 24)
	dialogue_text.add_theme_constant_override("line_spacing", 6)
	dialogue_text.add_theme_color_override("font_color", Color("#342a29"))
	var pixel_font := load(PIXEL_FONT) as FontFile
	if pixel_font != null:
		pixel_font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		pixel_font.fallbacks = [ThemeDB.fallback_font]
		dialogue_text.add_theme_font_override("font", pixel_font)
	dialogue_panel.add_child(dialogue_text)


func _on_interaction_body_entered(body: Node2D) -> void:
	if body == player_body:
		player_in_area = true


func _on_interaction_body_exited(body: Node2D) -> void:
	if body == player_body:
		player_in_area = false


func _on_bed_body_entered(body: Node2D) -> void:
	if body == player_body:
		bed_player_in_area = true


func _on_bed_body_exited(body: Node2D) -> void:
	if body == player_body:
		bed_player_in_area = false


func _start_sleep() -> void:
	if ending_started:
		return

	ending_started = true
	bed_player_in_area = false
	_stop_chernobyl_environment()
	bedroom_background.visible = true
	var sleeping_texture := load(SLEEPING_BEDROOM) as Texture2D
	if sleeping_texture == null:
		push_error("Could not load sleeping bedroom: " + SLEEPING_BEDROOM)
		return
	bedroom_background.texture = sleeping_texture

	player_body.velocity = Vector2.ZERO
	player_body.set_physics_process(false)
	player_body.set_process(false)

	var player_sprite: AnimatedSprite2D = player_body.get_node("AnimatedSprite2D")
	player_sprite.stop()
	player_sprite.visible = false
	var dog: AnimatedSprite2D = player_body.get_node("Robot_Dog")
	dog.stop()
	dog.visible = false

	await get_tree().create_timer(2.0).timeout
	var fade_out := create_tween()
	fade_out.tween_property(fade_to_black, "color:a", 1.0, 1.5)
	await fade_out.finished

	_activate_plant_play_area()
	_start_chernobyl_environment()
	mission_active = true
	guard_sprite.visible = true
	remote_panel_marker.visible = true
	countdown_label.text = "Մինչև պայթյունը՝ 20:00"
	countdown_label.visible = false
	player_body.call("wake_up_at", Vector2(580.0, 530.0))
	if rooster_player != null:
		rooster_player.play()

	var reveal_tween := create_tween()
	reveal_tween.tween_property(fade_to_black, "color:a", 0.0, 0.8)
	await reveal_tween.finished


func _activate_plant_play_area() -> void:
	interaction_area.monitoring = false
	bed_area.monitoring = false
	for collision in bedroom_collisions.get_children():
		if collision is CollisionShape2D:
			collision.set_deferred("disabled", true)

	var plant_ground := StaticBody2D.new()
	plant_ground.name = "PlantRoadCollision"
	var ground_shape := CollisionShape2D.new()
	var road := RectangleShape2D.new()
	road.size = Vector2(3000.0, 40.0)
	ground_shape.shape = road
	plant_ground.add_child(ground_shape)
	plant_ground.position = Vector2(578.0, 629.5)
	stand_up.add_child(plant_ground)


func _update_bomb_countdown(delta: float) -> void:
	if not countdown_active or bomb_disarmed or bomb_exploded:
		return

	countdown_seconds = maxf(countdown_seconds - delta, 0.0)
	var whole_seconds := int(ceil(countdown_seconds))
	var minutes := int(whole_seconds / 60)
	var seconds := whole_seconds % 60
	countdown_label.text = "Մինչև պայթյունը՝ %02d:%02d" % [minutes, seconds]
	if countdown_seconds <= 0.0:
		_trigger_bomb_explosion()


func _update_mission_prompt() -> void:
	if bomb_disarmed:
		interaction_hint.visible = false
		return

	var player_x := player_body.global_position.x
	if not guard_talked:
		if absf(player_x - GUARD_POSITION.x) <= 110.0:
			interaction_hint.text = "E — խոսել պահակի հետ"
			interaction_hint.visible = true
		else:
			interaction_hint.text = "Գտիր պահակին և խոսիր նրա հետ"
			interaction_hint.visible = true
		return

	if absf(player_x - REMOTE_PANEL_POSITION.x) <= 170.0:
		interaction_hint.text = "E — օգտագործել հեռակառավարման վահանակը"
	else:
		interaction_hint.text = "Գնա դեպի հեռակառավարման վահանակը"
	interaction_hint.visible = true


func _handle_mission_interaction() -> void:
	var player_x := player_body.global_position.x
	if not guard_talked and absf(player_x - GUARD_POSITION.x) <= 110.0:
		_begin_mission_dialogue([
			"Երեխա: Ես վտանգի մասին տեղեկություն ունեմ․ 20 րոպեից պայթյուն է լինելու։",
		"Պահակ: Դժվար է հավատալ, տղա՛ս, բայց ազդանշաններն էլ են խափանում ցույց տալիս։ Ահա անցագիրը։ Գլխավոր վահանակի կոդը VWRS է։ Վազի՛ր, միայն դու կարող ես կանգնեցնել սա։",
			"Ռոբոտ-շուն: Շտապենք դեպի վահանակը։ Պայթյունին մնացել է 20 րոպե։"
		], "guard")
	elif guard_talked and absf(player_x - REMOTE_PANEL_POSITION.x) <= 170.0:
		_open_remote_panel()


func _begin_mission_dialogue(lines: Array[String], source: String) -> void:
	mission_dialogue_lines = lines
	mission_dialogue_source = source
	mission_dialogue_index = 0
	mission_dialogue_open = true
	interaction_hint.text = "E կամ → — շարունակել"
	interaction_hint.visible = true
	_show_mission_dialogue_line()


func _show_mission_dialogue_line() -> void:
	var line := mission_dialogue_lines[mission_dialogue_index]
	if line.begins_with("Ռոբոտ-շուն"):
		dialogue_panel.texture = robot_dialogue_texture
	else:
		dialogue_panel.texture = load(CHILD_DIALOGUE) as Texture2D
	dialogue_text.text = line
	dialogue_text.visible_characters = -1
	dialogue_panel.visible = true


func _advance_mission_dialogue() -> void:
	if mission_dialogue_index < mission_dialogue_lines.size() - 1:
		mission_dialogue_index += 1
		_show_mission_dialogue_line()
		return

	mission_dialogue_open = false
	dialogue_panel.visible = false
	if mission_dialogue_source == "guard":
		guard_talked = true
		countdown_active = true
		countdown_seconds = BOMB_COUNTDOWN_SECONDS
		countdown_label.text = "Մինչև պայթյունը՝ 20:00"
		countdown_label.visible = true
	elif mission_dialogue_source == "success":
		interaction_hint.text = "Փուլ 1-ն ավարտված է։ Խաղը շարունակվում է։"
		interaction_hint.visible = true
	interaction_hint.visible = true


func _open_remote_panel() -> void:
	if terminal_overlay != null or bomb_disarmed:
		return

	terminal_overlay = Control.new()
	terminal_overlay.name = "RemoteControlOverlay"
	terminal_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mission_hud_layer.add_child(terminal_overlay)
	player_body.set_physics_process(false)
	player_body.set_process(false)

	var dim := ColorRect.new()
	dim.color = Color(0.015, 0.025, 0.04, 0.86)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	terminal_overlay.add_child(dim)

	var panel_size := Vector2(760.0, 520.0)
	var panel := PanelContainer.new()
	panel.position = (get_viewport().get_visible_rect().size - panel_size) * 0.5
	panel.size = panel_size
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#111923")
	panel_style.border_color = Color("#bf7d3e")
	panel_style.set_border_width_all(4)
	panel_style.set_content_margin_all(26.0)
	panel.add_theme_stylebox_override("panel", panel_style)
	terminal_overlay.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)

	var heading := Label.new()
	heading.text = "ՀԵՌԱԿԱՌԱՎԱՐՄԱՆ ՎԱՀԱՆԱԿ"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 26)
	heading.add_theme_color_override("font_color", Color("#f0b766"))
	column.add_child(heading)

	var code_hint := Label.new()
	code_hint.text = "Պահակի տված կոդը՝ VWRS"
	code_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	code_hint.add_theme_font_size_override("font_size", 22)
	code_hint.add_theme_color_override("font_color", Color("#d7e2e9"))
	column.add_child(code_hint)

	terminal_code_input = LineEdit.new()
	terminal_code_input.placeholder_text = "Մուտքագրիր կոդը"
	terminal_code_input.max_length = 16
	terminal_code_input.custom_minimum_size = Vector2(0.0, 52.0)
	terminal_code_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	terminal_code_input.add_theme_font_size_override("font_size", 24)
	column.add_child(terminal_code_input)

	var submit_button := Button.new()
	submit_button.text = "ՄՈՒՏՔ"
	submit_button.custom_minimum_size = Vector2(0.0, 48.0)
	submit_button.add_theme_font_size_override("font_size", 20)
	submit_button.pressed.connect(_submit_remote_code)
	terminal_code_input.text_submitted.connect(_on_terminal_text_submitted)
	column.add_child(submit_button)

	terminal_feedback = Label.new()
	terminal_feedback.text = ""
	terminal_feedback.custom_minimum_size = Vector2(0.0, 78.0)
	terminal_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	terminal_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	terminal_feedback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	terminal_feedback.add_theme_font_size_override("font_size", 18)
	terminal_feedback.add_theme_color_override("font_color", Color("#f0d6b4"))
	column.add_child(terminal_feedback)

	terminal_morse = Label.new()
	terminal_morse.text = "ՄՈՐԶԵԻ ՀՈՒՇՈՒՄ՝ .-.   .   -.."
	terminal_morse.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	terminal_morse.add_theme_font_size_override("font_size", 24)
	terminal_morse.add_theme_color_override("font_color", Color("#ff514b"))
	terminal_morse.visible = false
	column.add_child(terminal_morse)

	terminal_switch_row = HBoxContainer.new()
	terminal_switch_row.alignment = BoxContainer.ALIGNMENT_CENTER
	terminal_switch_row.add_theme_constant_override("separation", 10)
	terminal_switch_row.visible = code_solved
	column.add_child(terminal_switch_row)
	for switch_name in ["ԴԵՂԻՆ", "ԿԱՆԱՉ", "ԿԱՐՄԻՐ", "ՍՊԻՏԱԿ"]:
		var switch_button := Button.new()
		switch_button.text = switch_name
		switch_button.custom_minimum_size = Vector2(145.0, 58.0)
		switch_button.add_theme_font_size_override("font_size", 20)
		var switch_style := StyleBoxFlat.new()
		var switch_colors := {
			"ԴԵՂԻՆ": "#c9a131",
			"ԿԱՆԱՉ": "#2b784b",
			"ԿԱՐՄԻՐ": "#b62424",
			"ՍՊԻՏԱԿ": "#d7dce0"
		}
		switch_style.bg_color = Color(switch_colors[switch_name])
		switch_style.set_content_margin_all(10.0)
		switch_button.add_theme_stylebox_override("normal", switch_style)
		if switch_name == "ՍՊԻՏԱԿ":
			switch_button.add_theme_color_override("font_color", Color("#1b252d"))
		switch_button.pressed.connect(_choose_switch.bind(switch_name))
		terminal_switch_row.add_child(switch_button)
		if switch_name == "ԿԱՐՄԻՐ":
			terminal_red_button = switch_button
	if code_solved:
		terminal_code_input.editable = false
		terminal_feedback.text = "Մուտքն ընդունված է։ Վահանակի ներքևում նոր հուշում կա։"
		terminal_feedback.add_theme_color_override("font_color", Color("#9be09b"))
		terminal_morse.visible = true
		terminal_red_button.visible = true
		terminal_switch_row.visible = true

	var close_button := Button.new()
	close_button.text = "ՓԱԿԵԼ"
	close_button.pressed.connect(_close_remote_panel)
	column.add_child(close_button)
	if not code_solved:
		terminal_code_input.grab_focus()


func _on_terminal_text_submitted(_text: String) -> void:
	_submit_remote_code()


func _submit_remote_code() -> void:
	if code_solved or terminal_code_input == null:
		return

	var answer := terminal_code_input.text.strip_edges().to_upper()
	if answer == "STOP":
		code_solved = true
		terminal_feedback.text = "Մուտքն ընդունված է։ Վահանակի ներքևում նոր հուշում կա։"
		terminal_feedback.add_theme_color_override("font_color", Color("#9be09b"))
		terminal_morse.visible = true
		terminal_switch_row.visible = true
		terminal_red_button.visible = true
		terminal_code_input.editable = false
	elif answer == "VWRS":
		terminal_feedback.text = "Սխալ է։ Ռոբոտ-շուն․ «Սա շիֆրովկա է։ Տառերը երեք քայլ ետ տեղափոխիր»։"
		terminal_feedback.add_theme_color_override("font_color", Color("#ff9c86"))
		if dog_bark_player != null:
			dog_bark_player.play()
		terminal_code_input.clear()
	else:
		terminal_feedback.text = "Կոդը սխալ է։ Փորձիր նորից։"
		terminal_feedback.add_theme_color_override("font_color", Color("#ff9c86"))
		terminal_code_input.clear()
	terminal_code_input.grab_focus()


func _close_remote_panel() -> void:
	if terminal_overlay != null:
		terminal_overlay.queue_free()
	terminal_overlay = null
	if mission_active and not bomb_exploded:
		player_body.set_physics_process(true)
		player_body.set_process(true)
	terminal_code_input = null
	terminal_feedback = null
	terminal_morse = null
	terminal_red_button = null
	terminal_switch_row = null
	interaction_hint.visible = true


func _disarm_bomb() -> void:
	if not code_solved:
		return
	bomb_disarmed = true
	countdown_active = false
	_close_remote_panel()
	countdown_label.text = "ՌՈՒՄԲՆ ԱՆՋԱՏՎԱԾ Է"
	countdown_label.add_theme_color_override("font_color", Color("#9be09b"))
	_begin_mission_dialogue([
		"Ռոբոտ-շուն: Մորզեի կոդը RED էր։ Կարմիր կոճակը սեղմվեց։",
		"Պահակ: Ռումբն անջատված է։ Դու փրկեցիր կայանը։"
	], "success")


func _choose_switch(switch_name: String) -> void:
	if not code_solved or bomb_disarmed or bomb_exploded:
		return
	if switch_name == "ԿԱՐՄԻՐ":
		_disarm_bomb()
	else:
		_trigger_bomb_explosion("Սխալ անջատիչ․ համակարգը գերծանրաբեռնվեց")


func _trigger_bomb_explosion(reason: String = "Ժամանակը սպառվեց") -> void:
	bomb_exploded = true
	countdown_active = false
	mission_active = false
	mission_dialogue_open = false
	dialogue_panel.visible = false
	_close_remote_panel()
	interaction_hint.visible = false
	player_body.velocity = Vector2.ZERO
	player_body.set_physics_process(false)
	player_body.set_process(false)

	var explosion_layer := CanvasLayer.new()
	explosion_layer.name = "ExplosionOverlay"
	explosion_layer.layer = 15
	add_child(explosion_layer)
	var overlay := ColorRect.new()
	overlay.color = Color(0.35, 0.015, 0.015, 0.94)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	explosion_layer.add_child(overlay)
	var message := Label.new()
	message.text = "ՊԱՅԹՅՈՒՆ\n" + reason + "\nCtrl+Z — հետ գնալ 15 վայրկյան"
	message.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 30)
	message.add_theme_color_override("font_color", Color.WHITE)
	overlay.add_child(message)
	var restart_button := Button.new()
	restart_button.text = "RESTART"
	var viewport_size := get_viewport().get_visible_rect().size
	restart_button.position = Vector2((viewport_size.x - 220.0) * 0.5, viewport_size.y * 0.68)
	restart_button.custom_minimum_size = Vector2(220.0, 64.0)
	restart_button.add_theme_font_size_override("font_size", 26)
	restart_button.pressed.connect(func(): get_tree().reload_current_scene())
	overlay.add_child(restart_button)


func _rewind_after_explosion() -> void:
	var explosion_layer := get_node_or_null("ExplosionOverlay")
	if explosion_layer != null:
		explosion_layer.queue_free()
	bomb_exploded = false
	mission_active = true
	countdown_active = true
	countdown_seconds = 15.0
	countdown_label.text = "Մինչև պայթյունը՝ 00:15"
	countdown_label.visible = true
	player_body.set_physics_process(true)
	player_body.set_process(true)
	interaction_hint.text = "Ժամանակը հետ տրվեց․ արագ ընտրիր կարմիր կոճակը։"
	interaction_hint.visible = true


func _create_rooster_player() -> void:
	var rooster_stream := load(ROOSTER_CROW) as AudioStream
	if rooster_stream == null:
		push_error("Could not load rooster crow: " + ROOSTER_CROW)
		return

	rooster_player = AudioStreamPlayer.new()
	rooster_player.name = "RoosterCrow"
	rooster_player.stream = rooster_stream
	add_child(rooster_player)


func _create_chernobyl_audio() -> void:
	var ambience := load(CHERNOBYL_AMBIENCE) as AudioStreamMP3
	if ambience == null:
		return
	ambience.loop = true
	chernobyl_ambience_player = AudioStreamPlayer.new()
	chernobyl_ambience_player.name = "ChernobylAmbience"
	chernobyl_ambience_player.stream = ambience
	chernobyl_ambience_player.volume_db = -12.0
	add_child(chernobyl_ambience_player)


func _create_dog_bark_player() -> void:
	var bark_stream := load(ROBOT_DOG_BARK) as AudioStream
	if bark_stream == null:
		return
	dog_bark_player = AudioStreamPlayer.new()
	dog_bark_player.name = "RobotDogBark"
	dog_bark_player.stream = bark_stream
	add_child(dog_bark_player)


func _create_chernobyl_environment() -> void:
	var sheet := load(CHERNOBYL_SHEET) as Texture2D
	if sheet == null:
		push_error("Could not load Chernobyl sprite sheet: " + CHERNOBYL_SHEET)
		return

	for frame_rect in CHERNOBYL_FRAME_RECTS:
		var atlas_frame := AtlasTexture.new()
		atlas_frame.atlas = sheet
		atlas_frame.region = frame_rect
		chernobyl_frames.append(atlas_frame)

	chernobyl_background = TextureRect.new()
	chernobyl_background.name = "ChernobylBackground"
	chernobyl_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chernobyl_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	chernobyl_background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	chernobyl_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chernobyl_background.z_index = -10
	chernobyl_background.texture = chernobyl_frames[0]
	chernobyl_background.visible = false
	stand_up.add_child(chernobyl_background)
	chernobyl_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var guard_sheet := load(GUARD_SPRITE) as Texture2D
	if guard_sheet == null:
		push_error("Could not load security guard sprite: " + GUARD_SPRITE)
		return
	var guard_frames := SpriteFrames.new()
	guard_frames.add_animation("Idle")
	guard_frames.set_animation_speed("Idle", 5.0)
	guard_frames.set_animation_loop("Idle", true)
	for frame_index in range(8):
		var guard_frame := AtlasTexture.new()
		guard_frame.atlas = guard_sheet
		guard_frame.region = Rect2(float(frame_index) * guard_sheet.get_width() / 8.0, 0.0, float(guard_sheet.get_width()) / 8.0, float(guard_sheet.get_height()))
		guard_frames.add_frame("Idle", guard_frame)
	guard_sprite = AnimatedSprite2D.new()
	guard_sprite.name = "SecurityGuard"
	guard_sprite.sprite_frames = guard_frames
	guard_sprite.animation = "Idle"
	guard_sprite.frame = 2
	guard_sprite.flip_h = true
	guard_sprite.position = GUARD_POSITION
	guard_sprite.scale = Vector2(0.29, 0.29)
	guard_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	guard_sprite.z_index = 2
	guard_sprite.visible = false
	stand_up.add_child(guard_sprite)

	remote_panel_marker = PanelContainer.new()
	remote_panel_marker.name = "RemoteControlMarker"
	remote_panel_marker.position = REMOTE_PANEL_POSITION - Vector2(80.0, 108.0)
	remote_panel_marker.size = Vector2(160.0, 78.0)
	remote_panel_marker.z_index = 3
	remote_panel_marker.visible = false
	var marker_style := StyleBoxFlat.new()
	marker_style.bg_color = Color("#151a20")
	marker_style.border_color = Color("#d28a3a")
	marker_style.set_border_width_all(3)
	marker_style.set_content_margin_all(8.0)
	remote_panel_marker.add_theme_stylebox_override("panel", marker_style)
	var marker_label := Label.new()
	marker_label.text = "REMOTE\nCONTROL"
	marker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	marker_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	marker_label.add_theme_color_override("font_color", Color("#f2c27d"))
	marker_label.add_theme_font_size_override("font_size", 16)
	remote_panel_marker.add_child(marker_label)
	stand_up.add_child(remote_panel_marker)


func _create_mission_hud() -> void:
	mission_hud_layer = CanvasLayer.new()
	mission_hud_layer.name = "MissionHud"
	mission_hud_layer.layer = 9
	add_child(mission_hud_layer)

	var root := Control.new()
	root.name = "MissionHudRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mission_hud_layer.add_child(root)

	var viewport_size := get_viewport().get_visible_rect().size
	countdown_label = Label.new()
	countdown_label.name = "BombCountdown"
	countdown_label.position = Vector2(24.0, 18.0)
	countdown_label.size = Vector2(420.0, 48.0)
	countdown_label.add_theme_font_size_override("font_size", 24)
	countdown_label.add_theme_color_override("font_color", Color("#ffbd69"))
	countdown_label.add_theme_color_override("font_outline_color", Color("#1b1010"))
	countdown_label.add_theme_constant_override("outline_size", 4)
	countdown_label.visible = false
	root.add_child(countdown_label)

	interaction_hint = Label.new()
	interaction_hint.name = "MissionInteractionHint"
	interaction_hint.position = Vector2(24.0, viewport_size.y - 56.0)
	interaction_hint.size = Vector2(viewport_size.x - 48.0, 40.0)
	interaction_hint.add_theme_font_size_override("font_size", 22)
	interaction_hint.add_theme_color_override("font_color", Color.WHITE)
	interaction_hint.add_theme_color_override("font_outline_color", Color.BLACK)
	interaction_hint.add_theme_constant_override("outline_size", 4)
	interaction_hint.visible = false
	root.add_child(interaction_hint)


func _start_chernobyl_environment() -> void:
	if chernobyl_frames.is_empty():
		return
	chernobyl_frame_index = CHERNOBYL_SELECTED_FRAME
	chernobyl_background.texture = chernobyl_frames[chernobyl_frame_index]
	bedroom_background.visible = false
	chernobyl_background.visible = true
	if guard_sprite != null:
		guard_sprite.play("Idle")
	if chernobyl_ambience_player != null and not chernobyl_ambience_player.playing:
		chernobyl_ambience_player.play()


func _stop_chernobyl_environment() -> void:
	if chernobyl_background != null:
		chernobyl_background.visible = false
	if chernobyl_ambience_player != null:
		chernobyl_ambience_player.stop()


func _create_fade_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.name = "EndingLayer"
	layer.layer = 20
	add_child(layer)

	fade_to_black = ColorRect.new()
	fade_to_black.name = "FadeToBlack"
	fade_to_black.color = Color(0.0, 0.0, 0.0, 0.0)
	fade_to_black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_to_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(fade_to_black)


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
	if line.begins_with("Ռոբոտ-շուն"):
		dialogue_panel.texture = robot_dialogue_texture
	else:
		dialogue_panel.texture = load(CHILD_DIALOGUE) as Texture2D
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
