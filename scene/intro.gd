extends Node

const CHILD_DIALOGUE := "res://dialogue_child_panel.png"
const ROBOT_DIALOGUE := "res://dialogue_robot_panel.png"
const ROBOT_DIALOGUE_EXPANDED := "res://dialogue_robot_panel_expanded.png"
const PIXEL_FONT := "res://Fonts/BlockBlueprint.ttf"
const SLEEPING_BEDROOM := "res://bedroom_sleeping.png"
const CHERNOBYL_SHEET := "res://chernobyl_environment_sheet.png"
const CHERNOBYL_INTERIOR := "res://chernobyl_interior_corridor.png"
const ENTRANCE_DOOR_SPRITE := "res://chernobyl_entrance_door.png"
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
const BOOK_OPEN_SFX := "res://Music/book_open.mp3"
const FLICKER_SFX := "res://Music/light_flicker.mp3"
const RADIO_SFX := "res://Music/radio_communication.mp3"
const POWER_SURGE_SFX := "res://Music/power_surge.mp3"
const COUNTDOWN_BEEP_SFX := "res://Music/countdown_beep.wav"
const PLANT_DOOR_OPEN_SFX := "res://Music/plant_door_open.wav"
const TYPEWRITER_SPEED := 32.0
const BOMB_COUNTDOWN_SECONDS := 5.0 * 60.0
const GUARD_GROUND_Y := 609.5
const GUARD_POSITION := Vector2(760.0, GUARD_GROUND_Y)
const GUARD_FRAME_BOTTOMS := [678.0, 703.0, 678.0, 724.0, 724.0, 676.0, 698.0, 700.0]
const GUARD_FRAME_HEIGHT := 724.0
const GUARD_SCALE := 0.29
const ENTRY_DOOR_SCALE := 0.24
const PLANT_ENTRY_POSITION := Vector2(900.0, GUARD_GROUND_Y)
const PLANT_INTERIOR_WIDTH := 1672.0
const REMOTE_PANEL_POSITION := Vector2(1510.0, 545.0)

var player_in_area := false
var bed_player_in_area := false
var table_view_active := false
var book_is_open := false
var animation_busy := false
var opening_book := false
var ending_started := false
var mission_active := false
var guard_talked := false
var entry_door_open := false
var inside_plant := false
var room_transition_active := false
var countdown_active := false
var code_solved := false
var code_hint_shown := false
var bomb_disarmed := false
var bomb_exploded := false
var mission_dialogue_open := false
var mission_dialogue_source := ""
var mission_dialogue_lines: Array[String] = []
var mission_dialogue_index := 0
var countdown_seconds := BOMB_COUNTDOWN_SECONDS

var dialogue_panel: TextureRect
var dialogue_text: Label
var guard_dialogue_backing: ColorRect
var guard_dialogue_portrait: TextureRect
var robot_dialogue_texture: Texture2D
var fade_to_black: ColorRect
var rooster_player: AudioStreamPlayer
var chernobyl_ambience_player: AudioStreamPlayer
var dog_bark_player: AudioStreamPlayer
var book_open_player: AudioStreamPlayer
var flicker_player: AudioStreamPlayer
var radio_player: AudioStreamPlayer
var power_surge_player: AudioStreamPlayer
var countdown_beep_player: AudioStreamPlayer
var countdown_beep_elapsed := 0.0
var chernobyl_background: TextureRect
var interior_background: TextureRect
var chernobyl_frames: Array[Texture2D] = []
var chernobyl_frame_index := 0
var guard_sprite: AnimatedSprite2D
var entry_door_pivot: Node2D
var plant_door_player: AudioStreamPlayer
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
	"Երեխա: Ռոբոտ-շո՛ւն, կպատմե՞ս Չեռնոբիլի ատոմակայանի պատմությունը։ Ինչո՞ւ այն պայթեց։",
	"Ռոբոտ-շուն: Կայանը կառուցվեց Ուկրաինայում՝ Պրիպյատ քաղաքի մոտ։ Առաջին էներգաբլոկը գործարկվեց 1977-ին, իսկ 1984-ին կայանն արդեն չորս բլոկ ուներ։ Պրիպյատում ապրում էին աշխատողներն ու նրանց ընտանիքները։",
	"Երեխա: Իսկ ինչո՞ւ հենց չորրորդ բլոկը պայթեց։",
	"Ռոբոտ-շուն: 1986-ի ապրիլի 26-ի գիշերը այնտեղ ստուգում էին՝ հոսանքն անջատվելուց հետո տուրբինն ինչքան կկարողանա պահուստային հոսանք տալ։",
	"Երեխա: Այսինքն՝ փորձում էին անվտանգության համակարգը ստուգե՞լ։",
	"Ռոբոտ-շուն: Այո։ Բայց հզորությունը շատ ցածր ընկավ, ռեակտորը դարձավ անկայուն, իսկ փորձարկման ընթացքում մի քանի պաշտպանիչ համակարգ անջատված էր։",
	"Երեխա: Իսկ ռեակտորի մեջ ի՞նչ տեղի ունեցավ։",
	"Ռոբոտ-շուն: Այդ RBMK ռեակտորն ուներ նախագծային վտանգավոր թերություններ։ Այդ պայմաններում ջրի գոլորշին կարող էր հզորությունը նվազեցնելու փոխարեն մեծացնել։ Կանգնեցման ձողերի թերության պատճառով վթարային կոճակը սեղմելիս հզորությունը սկզբում ավելի աճեց։",
	"Երեխա: Ու դրա՞ց եղավ պայթյունը։",
	"Ռոբոտ-շուն: Գիշերվա 01:23-ին հզորությունը կտրուկ աճեց։ Գոլորշու պայթյունները վնասեցին ռեակտորն ու շենքը, գրաֆիտը հրդեհվեց, և ռադիոակտիվ նյութեր տարածվեցին օդում։ Դա ատոմային ռումբի պայթյուն չէր։",
	"Երեխա: Իսկ մոտակայքում ապրող մարդիկ ի՞նչ եղան։",
	"Ռոբոտ-շուն: Հրշեջներն առաջիններից էին, որ գնացին հանգցնելու հրդեհը։ Պրիպյատի բնակիչներին տարհանեցին հաջորդ օրը՝ վթարից մոտ 36 ժամ անց։ Շատերը սկզբում չգիտեին՝ որքան վտանգավոր էր ճառագայթումը։",
	"Երեխա: Իսկ հետո ինչպե՞ս պաշտպանեցին շրջակայքը։",
	"Ռոբոտ-շուն: Հրշեջներն ու հազարավոր աշխատողներ պայքարեցին հրդեհի ու ռադիացիայի դեմ։ Վնասված ռեակտորը փակեցին պաշտպանիչ կառույցով, իսկ Պրիպյատն ու շրջակայքը մնացին փակ գոտում։",
	"Երեխա: Ուրեմն դա միայն աշխատողների սխա՞լն էր։",
	"Ռոբոտ-շուն: Ոչ։ Վթարին բերեցին մարդկային սխալների, անվտանգության կանոնների խախտումների ու ռեակտորի նախագծային թերությունների համադրությունը։ Մյուս բլոկները նորից աշխատեցին, բայց կայանն ամբողջությամբ փակվեց 2000-ին։",
	"Երեխա: Չեռնոբիլի դասը ո՞րն է։",
	"Ռոբոտ-շուն: Վտանգը պետք է ընդունել, հետաքննել ու դրա մասին ազնվորեն զգուշացնել։",
	"Երեխա: Շատ տխուր պատմություն է։ Կուզեի՝ մարդիկ ժամանակին իմանային վտանգի մասին։ Ես արդեն հոգնել եմ… գնամ քնեմ։"
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
	book_open_player = _create_effect_player(BOOK_OPEN_SFX, "BookOpenSfx", -12.0)
	flicker_player = _create_effect_player(FLICKER_SFX, "LightFlickerSfx", -15.0)
	radio_player = _create_effect_player(RADIO_SFX, "RadioSfx", -14.0)
	power_surge_player = _create_effect_player(POWER_SURGE_SFX, "PowerSurgeSfx", -8.0)
	countdown_beep_player = _create_effect_player(COUNTDOWN_BEEP_SFX, "CountdownBeepSfx", -13.0)
	plant_door_player = _create_effect_player(PLANT_DOOR_OPEN_SFX, "PlantDoorOpenSfx", -7.0)
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
	if get_node_or_null("SuccessEnding") != null:
		return

	if mission_active or mission_dialogue_open or terminal_overlay != null:
		_update_bomb_countdown(_delta)
		if bomb_exploded:
			return
		if mission_dialogue_open:
			if typing_dialogue:
				typewriter_elapsed += _delta
				var visible_count := int(typewriter_elapsed * 46.0)
				dialogue_text.visible_characters = mini(visible_count, dialogue_text.text.length())
				if dialogue_text.visible_characters >= dialogue_text.text.length():
					typing_dialogue = false
				elif Input.is_action_just_pressed("E") or Input.is_action_just_pressed("Right"):
					dialogue_text.visible_characters = -1
					typing_dialogue = false
				return
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
		_update_bedroom_prompt()
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
			if Input.is_action_just_pressed("Right") or Input.is_action_just_pressed("E"):
				dialogue_text.visible_characters = -1
				typing_dialogue = false
				if dialogue_index == DIALOGUE_LINES.size() - 1:
					conversation_finished = true
			return

	if not book_is_open:
		if Input.is_action_just_pressed("Right") or Input.is_action_just_pressed("E"):
			_set_book_open(true)
		return

	if Input.is_action_just_pressed("Right") or Input.is_action_just_pressed("E"):
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

	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F:
		if mission_active and guard_talked and entry_door_open and not inside_plant and not room_transition_active and not mission_dialogue_open and terminal_overlay == null and not bomb_exploded:
			if absf(player_body.global_position.x - PLANT_ENTRY_POSITION.x) <= 110.0:
				_enter_plant_interior()
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
		if book_open_player != null:
			book_open_player.play()
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

	guard_dialogue_backing = ColorRect.new()
	guard_dialogue_backing.name = "GuardPortraitBacking"
	guard_dialogue_backing.position = Vector2(panel_width * 0.035, panel_height * 0.13)
	guard_dialogue_backing.size = Vector2(panel_width * 0.19, panel_height * 0.75)
	guard_dialogue_backing.color = Color("#f8d4a1")
	guard_dialogue_backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	guard_dialogue_backing.visible = false
	dialogue_panel.add_child(guard_dialogue_backing)

	guard_dialogue_portrait = TextureRect.new()
	guard_dialogue_portrait.name = "GuardDialoguePortrait"
	guard_dialogue_portrait.position = guard_dialogue_backing.position
	guard_dialogue_portrait.size = guard_dialogue_backing.size
	guard_dialogue_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	guard_dialogue_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	guard_dialogue_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	guard_dialogue_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	guard_dialogue_portrait.visible = false
	var guard_sheet := load(GUARD_SPRITE) as Texture2D
	if guard_sheet != null:
		var guard_head := AtlasTexture.new()
		guard_head.atlas = guard_sheet
		guard_head.region = Rect2(543.0, 0.0, 271.0, 220.0)
		guard_dialogue_portrait.texture = guard_head
	dialogue_panel.add_child(guard_dialogue_portrait)

	dialogue_text = Label.new()
	dialogue_text.name = "ChildQuestion"
	dialogue_text.text = "Երեխա: Կպատմե՞ս Չեռնոբիլի ատոմակայանի մասին։ Ինչո՞ւ այն պայթեց։"
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
	player_body.call("stop_movement_audio")

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
	countdown_label.text = "Մինչև պայթյունը՝ 05:00"
	countdown_label.visible = false
	player_body.call("wake_up_at", Vector2(200.0, 530.0))
	if rooster_player != null:
		rooster_player.play()

	var reveal_tween := create_tween()
	reveal_tween.tween_property(fade_to_black, "color:a", 0.0, 0.8)
	await reveal_tween.finished
	await get_tree().create_timer(2.0).timeout
	_begin_mission_dialogue([
		"Երեխա: Որտե՞ղ ենք… Ես իմ սենյակում էի։ Սա ատոմակայանի միջո՞ցն է։",
		"Ռոբոտ-շուն: Սկանավորում եմ… Սա Չեռնոբիլի ատոմակայանն է։ Ամսաթիվը՝ 1986 թ. ապրիլի 26։ Ես էլ չգիտեմ՝ ինչպես հայտնվեցինք այստեղ։",
		"Երեխա: Դու հենց նոր պատմում էիր այս տեղի մասին։ Սա նույն պատմությո՞ւնն է։",
		"Ռոբոտ-շուն: Չգիտեմ։ Բայց ահազանգը ցույց է տալիս՝ կայանի ներսում մի բան այն չէ։ Գտնենք հերթապահին ու պարզենք՝ ինչ է կատարվում։"
	], "awakening")


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
	if countdown_seconds <= 10.0:
		countdown_beep_elapsed += delta
		if countdown_beep_elapsed >= 1.0:
			countdown_beep_elapsed = 0.0
			if countdown_beep_player != null:
				countdown_beep_player.play()
	else:
		countdown_beep_elapsed = 0.0
	var whole_seconds := int(ceil(countdown_seconds))
	var minutes := int(whole_seconds / 60)
	var seconds := whole_seconds % 60
	countdown_label.text = "Մինչև պայթյունը՝ %02d:%02d" % [minutes, seconds]
	if countdown_seconds <= 60.0:
		var pulse := 0.58 + 0.42 * (0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.012))
		countdown_label.modulate = Color(1.0, 1.0, 1.0, pulse)
	else:
		countdown_label.modulate = Color.WHITE
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

	if not inside_plant:
		if absf(player_x - PLANT_ENTRY_POSITION.x) <= 110.0:
			interaction_hint.text = "F — մտնել ատոմակայան"
		else:
			interaction_hint.text = "Մոտեցիր բաց դռանը"
	else:
		if absf(player_x - REMOTE_PANEL_POSITION.x) <= 145.0:
			interaction_hint.text = "E — օգտագործել կառավարման վահանակը"
		else:
			interaction_hint.text = "Գտիր կառավարման վահանակը"
	interaction_hint.visible = true


func _update_bedroom_prompt() -> void:
	if bed_player_in_area:
		interaction_hint.text = "Քնել"
		interaction_hint.visible = true
	elif player_in_area:
		interaction_hint.text = "Նստել սեղանի մոտ"
		interaction_hint.visible = true
	else:
		interaction_hint.visible = false


func _handle_mission_interaction() -> void:
	var player_x := player_body.global_position.x
	if not guard_talked and absf(player_x - GUARD_POSITION.x) <= 110.0:
		_begin_mission_dialogue([
			"Երեխա: Պարո՛ն, չորրորդ էներգաբլոկի ազդանշանները ցույց են տալիս՝ 5 րոպեից վթար է լինելու։ Պետք է տարհանել մարդկանց։",
			"Պահակ: Ես էլ եմ տեսնում ճնշման անկումը, բայց կառավարման սենյակը փակ է։ Վերցրու անցագիրս։ Հերթափոխի կոդը VWRS է։ Ես ռադիոյով կկանչեմ անձնակազմին։"
		], "guard")
	elif inside_plant and absf(player_x - REMOTE_PANEL_POSITION.x) <= 145.0:
		_open_remote_panel()


func _begin_mission_dialogue(lines: Array[String], source: String) -> void:
	mission_dialogue_lines = lines
	mission_dialogue_source = source
	mission_dialogue_index = 0
	mission_dialogue_open = true
	if source != "code_hint":
		player_body.velocity = Vector2.ZERO
		player_body.set_process(false)
		player_body.set_physics_process(false)
		player_body.call("stop_movement_audio")
	interaction_hint.text = "E կամ → — շարունակել"
	interaction_hint.visible = true
	_show_mission_dialogue_line()


func _show_mission_dialogue_line() -> void:
	var line := mission_dialogue_lines[mission_dialogue_index]
	var guard_is_speaking := line.begins_with("Պահակ:")
	if line.begins_with("Ռոբոտ-շուն"):
		dialogue_panel.texture = robot_dialogue_texture
	else:
		dialogue_panel.texture = load(CHILD_DIALOGUE) as Texture2D
	guard_dialogue_backing.visible = guard_is_speaking
	guard_dialogue_portrait.visible = guard_is_speaking and guard_dialogue_portrait.texture != null
	dialogue_text.text = line
	dialogue_text.visible_characters = 0
	typewriter_elapsed = 0.0
	typing_dialogue = true
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
		countdown_beep_elapsed = 0.0
		countdown_label.text = "Մինչև պայթյունը՝ 05:00"
		countdown_label.visible = true
		_open_plant_entrance()
		if radio_player != null:
			radio_player.play()
		player_body.set_process(true)
		player_body.set_physics_process(true)
	elif mission_dialogue_source == "awakening":
		player_body.set_process(true)
		player_body.set_physics_process(true)
	elif mission_dialogue_source == "success":
		_show_success_ending()
	elif mission_dialogue_source == "code_hint":
		if is_instance_valid(terminal_overlay):
			terminal_overlay.visible = true
		if is_instance_valid(terminal_code_input):
			terminal_code_input.grab_focus()


func _open_plant_entrance() -> void:
	if entry_door_open:
		return
	entry_door_open = true
	if guard_sprite != null:
		guard_sprite.stop()
	if plant_door_player != null:
		plant_door_player.play()
	if entry_door_pivot != null:
		entry_door_pivot.visible = true
		create_tween().tween_property(entry_door_pivot, "rotation", -1.05, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _enter_plant_interior() -> void:
	if room_transition_active or not entry_door_open or interior_background == null or entry_door_pivot == null:
		return
	room_transition_active = true
	interaction_hint.visible = false
	player_body.velocity = Vector2.ZERO
	player_body.set_physics_process(false)
	player_body.set_process(false)
	player_body.call("stop_movement_audio")
	var fade_out := create_tween()
	fade_out.tween_property(fade_to_black, "color:a", 1.0, 0.35)
	await fade_out.finished

	chernobyl_background.visible = false
	interior_background.visible = true
	guard_sprite.visible = false
	entry_door_pivot.visible = false
	inside_plant = true
	player_body.call("teleport_to", Vector2(220.0, 530.0))
	var camera := player_body.get_node_or_null("Camera2D") as Camera2D
	if camera != null:
		camera.limit_right = int(PLANT_INTERIOR_WIDTH)
		camera.reset_smoothing()
	player_body.set_process(true)
	player_body.set_physics_process(true)

	var fade_in := create_tween()
	fade_in.tween_property(fade_to_black, "color:a", 0.0, 0.5)
	await fade_in.finished
	room_transition_active = false


func _show_success_ending() -> void:
	mission_active = false
	countdown_active = false
	interaction_hint.visible = false
	var ending_layer := CanvasLayer.new()
	ending_layer.name = "SuccessEnding"
	ending_layer.layer = 15
	ending_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(ending_layer)

	var dim := ColorRect.new()
	dim.color = Color(0.025, 0.035, 0.055, 0.94)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	ending_layer.add_child(dim)

	var panel_size := Vector2(850.0, 450.0)
	var panel := PanelContainer.new()
	panel.position = (get_viewport().get_visible_rect().size - panel_size) * 0.5
	panel.size = panel_size
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#151d2a")
	panel_style.border_color = Color("#e0a451")
	panel_style.set_border_width_all(4)
	panel_style.set_content_margin_all(30.0)
	panel.add_theme_stylebox_override("panel", panel_style)
	dim.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 20)
	panel.add_child(content)

	var title := Label.new()
	title.text = "ՊԱՏՄՈՒԹՅՈՒՆԸ ՓՈԽՎԵՑ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color("#f4bd70"))
	content.add_child(title)

	var epilogue := Label.new()
	epilogue.text = "Այս խաղում վթարը կանխվեց։ Իրականում՝ 1986 թ. ապրիլի 26-ին Չեռնոբիլի 4-րդ էներգաբլոկի վթարը տեղի ունեցավ տուրբագեներատորի փորձարկման ժամանակ։ Դրան նպաստեցին և՛ շահագործման սխալները, և՛ ռեակտորի նախագծային թերությունները․ պատճառը մեկ կոճակ չէր։"
	epilogue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	epilogue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	epilogue.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	epilogue.custom_minimum_size = Vector2(0.0, 190.0)
	epilogue.add_theme_font_size_override("font_size", 21)
	epilogue.add_theme_color_override("font_color", Color("#e6e2dc"))
	content.add_child(epilogue)

	var source_note := Label.new()
	source_note.text = "Պատմական աղբյուր՝ IAEA, INSAG-7"
	source_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	source_note.add_theme_font_size_override("font_size", 14)
	source_note.add_theme_color_override("font_color", Color("#aab2be"))
	content.add_child(source_note)

	var restart_button := Button.new()
	restart_button.text = "ԿՐԿԻՆ ԽԱՂԱԼ"
	restart_button.custom_minimum_size = Vector2(0.0, 54.0)
	restart_button.add_theme_font_size_override("font_size", 22)
	restart_button.pressed.connect(func(): get_tree().reload_current_scene())
	content.add_child(restart_button)


func _open_remote_panel() -> void:
	if terminal_overlay != null or bomb_disarmed:
		return

	terminal_overlay = Control.new()
	terminal_overlay.name = "RemoteControlOverlay"
	terminal_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mission_hud_layer.add_child(terminal_overlay)
	player_body.set_physics_process(false)
	player_body.set_process(false)
	player_body.call("stop_movement_audio")
	if radio_player != null:
		radio_player.play()

	var dim := ColorRect.new()
	dim.color = Color(0.015, 0.025, 0.04, 0.86)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	terminal_overlay.add_child(dim)

	var panel_size := Vector2(820.0, 590.0)
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
	code_hint.text = "ԳԱՂՏՆԱԲԱՌ"
	code_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	code_hint.add_theme_font_size_override("font_size", 22)
	code_hint.add_theme_color_override("font_color", Color("#d7e2e9"))
	column.add_child(code_hint)

	terminal_code_input = LineEdit.new()
	terminal_code_input.placeholder_text = "Մուտքագրիր գաղտնաբառը"
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
	terminal_morse.text = "ՄՈՐԶԵԻ ԱԶԴԱՆՇԱՆ՝ .-.   .   -.."
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
	var morse_button_names := {
		"ԿԱՐՄԻՐ": ".-.   .   -..",
		"ԴԵՂԻՆ": "-.--   .   .-..   .-..   ---   .--",
		"ԿԱՆԱՉ": "--.   .-.   .   .   -.",
		"ԿԱՊՈՒՅՏ": "-...   .-..   ..-   ."
	}
	for switch_name in ["ԿԱՐՄԻՐ", "ԴԵՂԻՆ", "ԿԱՆԱՉ", "ԿԱՊՈՒՅՏ"]:
		var button_column := VBoxContainer.new()
		button_column.custom_minimum_size = Vector2(150.0, 96.0)
		button_column.add_theme_constant_override("separation", 5)
		var switch_button := Button.new()
		switch_button.text = ""
		switch_button.custom_minimum_size = Vector2(145.0, 58.0)
		switch_button.add_theme_font_size_override("font_size", 20)
		var switch_style := StyleBoxFlat.new()
		var switch_colors := {
			"ԴԵՂԻՆ": "#c9a131",
			"ԿԱՆԱՉ": "#2b784b",
			"ԿԱՐՄԻՐ": "#b62424",
			"ԿԱՊՈՒՅՏ": "#287bb8"
		}
		switch_style.bg_color = Color(switch_colors[switch_name])
		switch_style.set_content_margin_all(10.0)
		switch_button.add_theme_stylebox_override("normal", switch_style)
		switch_button.pressed.connect(_choose_switch.bind(switch_name))
		button_column.add_child(switch_button)
		var morse_name := Label.new()
		morse_name.text = morse_button_names[switch_name]
		morse_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		morse_name.add_theme_font_size_override("font_size", 12)
		morse_name.add_theme_color_override("font_color", Color("#e6e2dc"))
		button_column.add_child(morse_name)
		terminal_switch_row.add_child(button_column)
		if switch_name == "ԿԱՐՄԻՐ":
			terminal_red_button = switch_button
	if code_solved:
		terminal_code_input.editable = false
		terminal_feedback.text = "ՄՈՒՏՔԸ ԲԱՑՎԵՑ։"
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
		terminal_feedback.text = "ՄՈՒՏՔԸ ԲԱՑՎԵՑ։"
		terminal_feedback.add_theme_color_override("font_color", Color("#9be09b"))
		terminal_morse.visible = true
		terminal_switch_row.visible = true
		terminal_red_button.visible = true
		terminal_code_input.editable = false
		if radio_player != null:
			radio_player.play()
	else:
		terminal_feedback.text = "ՄՈՒՏՔԸ ՄԵՐԺՎԵՑ։"
		terminal_feedback.add_theme_color_override("font_color", Color("#ff9c86"))
		terminal_code_input.clear()
		if not code_hint_shown:
			code_hint_shown = true
			terminal_code_input.release_focus()
			terminal_overlay.visible = false
			_begin_mission_dialogue([
				"Ռոբոտ-շուն: Կոդը մի՛ ընդունիր բառացի։ Վահանակը հին ծածկագիր է օգտագործում։ Նախ փորձենք, հետո կվերլուծեմ սխալը։"
			], "code_hint")
			return
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
	if countdown_beep_player != null:
		countdown_beep_player.stop()
	_close_remote_panel()
	countdown_label.text = "ՌՈՒՄԲՆ ԱՆՋԱՏՎԱԾ Է"
	countdown_label.add_theme_color_override("font_color", Color("#9be09b"))
	_begin_mission_dialogue([
		"Ռոբոտ-շուն: Մորզեն ասում էր՝ RED։ Ճիշտ անջատիչը գտանք․ վթարային շղթան անջատված է։",
		"Պահակ: Ազդանշանը դադարեց։ Անձնակազմին տարհանման հրաման տվեցի։ Լավ արեցիր, որ չանտեսեցիր վտանգը։",
		"Երեխա: Այս անգամ պատմությունը փոխեցինք։ Գնանք տեսնենք՝ ինչ փոխվեց մյուս էջում։"
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
	player_body.call("stop_movement_audio")
	if countdown_beep_player != null:
		countdown_beep_player.stop()
	if power_surge_player != null:
		power_surge_player.play()

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
	message.text = "ՊԱՅԹՅՈՒՆ\n" + reason + "\nCtrl+Z — ժամանակը հետ տալ 15 վայրկյան"
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


func _create_effect_player(resource_path: String, player_name: String, volume_db: float) -> AudioStreamPlayer:
	var effect_stream := load(resource_path) as AudioStream
	if effect_stream == null:
		push_warning("Could not load sound effect: " + resource_path)
		return null
	var effect_player := AudioStreamPlayer.new()
	effect_player.name = player_name
	effect_player.stream = effect_stream
	effect_player.volume_db = volume_db
	add_child(effect_player)
	return effect_player


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

	var interior_texture := load(CHERNOBYL_INTERIOR) as Texture2D
	if interior_texture == null:
		push_error("Could not load plant interior: " + CHERNOBYL_INTERIOR)
	else:
		interior_background = TextureRect.new()
		interior_background.name = "ChernobylInterior"
		interior_background.texture = interior_texture
		interior_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		interior_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		interior_background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		interior_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		interior_background.z_index = -11
		interior_background.visible = false
		stand_up.add_child(interior_background)
		interior_background.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		interior_background.position = Vector2(0.0, 22.0)
		interior_background.size = Vector2(PLANT_INTERIOR_WIDTH, get_viewport().get_visible_rect().size.y)

	var door_texture := load(ENTRANCE_DOOR_SPRITE) as Texture2D
	if door_texture != null:
		entry_door_pivot = Node2D.new()
		entry_door_pivot.name = "PlantEntranceDoor"
		entry_door_pivot.position = Vector2(
			PLANT_ENTRY_POSITION.x - door_texture.get_width() * ENTRY_DOOR_SCALE * 0.5,
			GUARD_GROUND_Y
		)
		entry_door_pivot.visible = false
		var door_sprite := Sprite2D.new()
		door_sprite.name = "DoorPanel"
		door_sprite.texture = door_texture
		door_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		door_sprite.scale = Vector2.ONE * ENTRY_DOOR_SCALE
		door_sprite.position = Vector2(
			door_texture.get_width() * ENTRY_DOOR_SCALE * 0.5,
			-door_texture.get_height() * ENTRY_DOOR_SCALE * 0.5
		)
		door_sprite.z_index = 1
		entry_door_pivot.add_child(door_sprite)
		stand_up.add_child(entry_door_pivot)

	var guard_sheet := load(GUARD_SPRITE) as Texture2D
	if guard_sheet == null:
		push_error("Could not load security guard sprite: " + GUARD_SPRITE)
		return
	var guard_frames := SpriteFrames.new()
	guard_frames.add_animation("Walk")
	guard_frames.set_animation_speed("Walk", 8.0)
	guard_frames.set_animation_loop("Walk", true)
	for frame_index in range(8):
		var guard_frame := AtlasTexture.new()
		guard_frame.atlas = guard_sheet
		guard_frame.region = Rect2(float(frame_index) * guard_sheet.get_width() / 8.0, 0.0, float(guard_sheet.get_width()) / 8.0, float(guard_sheet.get_height()))
		guard_frames.add_frame("Walk", guard_frame)
	guard_sprite = AnimatedSprite2D.new()
	guard_sprite.name = "SecurityGuard"
	guard_sprite.sprite_frames = guard_frames
	guard_sprite.animation = "Walk"
	guard_sprite.frame = 2
	guard_sprite.flip_h = true
	guard_sprite.scale = Vector2(GUARD_SCALE, GUARD_SCALE)
	guard_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	guard_sprite.z_index = 2
	guard_sprite.visible = false
	guard_sprite.frame_changed.connect(Callable(self, "_align_guard_to_ground"))
	guard_sprite.position = Vector2(
		GUARD_POSITION.x,
		GUARD_GROUND_Y - (GUARD_FRAME_BOTTOMS[guard_sprite.frame] - GUARD_FRAME_HEIGHT * 0.5) * GUARD_SCALE
	)
	stand_up.add_child(guard_sprite)

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
	interior_background.visible = false
	entry_door_pivot.visible = false
	bedroom_background.visible = false
	chernobyl_background.visible = true
	if guard_sprite != null:
		guard_sprite.play("Walk")
	if flicker_player != null:
		flicker_player.play()
	if chernobyl_ambience_player != null and not chernobyl_ambience_player.playing:
		chernobyl_ambience_player.play()


func _align_guard_to_ground() -> void:
	if guard_sprite == null:
		return
	var frame_index := clampi(guard_sprite.frame, 0, GUARD_FRAME_BOTTOMS.size() - 1)
	var frame_bottom: float = GUARD_FRAME_BOTTOMS[frame_index]
	guard_sprite.position = Vector2(
		GUARD_POSITION.x,
		GUARD_GROUND_Y - (frame_bottom - GUARD_FRAME_HEIGHT * 0.5) * GUARD_SCALE
	)


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
	guard_dialogue_backing.visible = false
	guard_dialogue_portrait.visible = false
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
	# Mission actors belong to the bedroom branch for shared coordinates, but must
	# stay hidden until the Chernobyl transition explicitly reveals them.
	if node == guard_sprite or node == entry_door_pivot:
		return

	if node is CanvasItem:
		node.visible = active

	if node is Camera2D:
		node.enabled = active

	if node is CharacterBody2D:
		node.set_process(active)
		node.set_physics_process(active)
		if not active:
			node.velocity = Vector2.ZERO
			node.call("stop_movement_audio")

	if node is AnimatedSprite2D and not active:
		node.stop()

	# Keep the interaction zone monitoring while the room branch is hidden.
	if node is Area2D:
		node.monitoring = true

	for child in node.get_children():
		_set_node_active(child, active)
