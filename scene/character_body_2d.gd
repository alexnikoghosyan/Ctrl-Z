extends CharacterBody2D

const WALK_SPEED := 150.0
const RUN_SPEED := 200.0
const DOUBLE_TAP_WINDOW := 0.3
const DOG_FOLLOW_DELAY := 0.32
const DOG_FOLLOW_DISTANCE := 160.0
const DOG_FOLLOW_SPEED := 520.0
const WAKE_CHARACTER_SCALE := 0.56
const WALK_SPRITE_SCALE := Vector2(2.0, 2.45)
const WALK_SPRITE_OFFSET := Vector2(0.0, -14.0)
const IDLE_SPRITE_SCALE := Vector2(2.0, 2.21)
const IDLE_SPRITE_OFFSET := Vector2(0.0, -22.0)
const STANDARD_SPRITE_SCALE := Vector2(2.0, 2.0)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var dog: AnimatedSprite2D = $Robot_Dog

var speed := WALK_SPEED
var double_tap_timer := 0.0
var facing_direction := 1.0
var dog_vertical_offset := 0.0
var trail_elapsed := 0.0
var trail: Array[Dictionary] = []


func _ready() -> void:
	_play_character_animation("default")
	var player_sprite_bottom := _get_sprite_bottom_in_parent(sprite)
	var dog_sprite_bottom := _get_sprite_bottom_in_parent(dog)
	dog_vertical_offset = (player_sprite_bottom - dog_sprite_bottom) * absf(global_scale.y)

	dog.z_index = 1
	sprite.z_index = 2
	dog.play("Idle")

	trail.append({
		"time": trail_elapsed,
		"position": global_position,
		"direction": facing_direction,
	})


func wake_up_at(wake_position: Vector2) -> void:
	scale *= WAKE_CHARACTER_SCALE
	dog.scale /= WAKE_CHARACTER_SCALE
	dog_vertical_offset = (
		_get_sprite_bottom_in_parent(sprite) - _get_sprite_bottom_in_parent(dog)
	) * absf(global_scale.y)
	global_position = wake_position
	velocity = Vector2.ZERO
	speed = WALK_SPEED
	double_tap_timer = 0.0
	facing_direction = 1.0
	trail_elapsed = 0.0
	trail.clear()
	trail.append({
		"time": trail_elapsed,
		"position": global_position,
		"direction": facing_direction,
	})

	sprite.flip_h = false
	_play_character_animation("default")
	sprite.modulate = Color(1.0, 1.0, 1.0, 0.0)
	sprite.visible = true
	dog.global_position = global_position + Vector2(-DOG_FOLLOW_DISTANCE, dog_vertical_offset)
	dog.flip_h = false
	dog.play("Idle")
	dog.modulate = Color(1.0, 1.0, 1.0, 0.0)
	dog.visible = true
	set_process(true)
	set_physics_process(true)

	var wake_tween := create_tween()
	wake_tween.set_parallel(true)
	wake_tween.tween_property(sprite, "modulate:a", 1.0, 0.35)
	wake_tween.tween_property(dog, "modulate:a", 1.0, 0.35)


func _get_sprite_bottom_in_parent(animated_sprite: AnimatedSprite2D) -> float:
	var texture := animated_sprite.sprite_frames.get_frame_texture(animated_sprite.animation, animated_sprite.frame)
	if texture == null:
		return animated_sprite.position.y

	var texture_size := texture.get_size()
	var frame_bottom := texture_size.y
	var frame_image := texture.get_image()
	if frame_image != null and not frame_image.is_empty():
		var visible_pixels := frame_image.get_used_rect()
		if visible_pixels.size != Vector2i.ZERO:
			frame_bottom = float(visible_pixels.end.y)
	if animated_sprite.centered:
		frame_bottom -= texture_size.y * 0.5
	return animated_sprite.position.y + (animated_sprite.offset.y + frame_bottom) * animated_sprite.scale.y


func _physics_process(delta: float) -> void:
	var left_pressed := Input.is_action_just_pressed("Left")
	var right_pressed := Input.is_action_just_pressed("Right")

	if left_pressed or right_pressed:
		if double_tap_timer > 0.0:
			speed = RUN_SPEED
			double_tap_timer = 0.0
		else:
			speed = WALK_SPEED
			double_tap_timer = DOUBLE_TAP_WINDOW
	else:
		double_tap_timer = maxf(double_tap_timer - delta, 0.0)

	var direction := Input.get_axis("Left", "Right")
	if direction != 0.0:
		facing_direction = signf(direction)
		velocity.x = direction * speed
		sprite.flip_h = direction < 0.0
		if speed == RUN_SPEED:
			_play_character_animation("Run")
		else:
			_play_character_animation("Walk")
	else:
		velocity.x = move_toward(velocity.x, 0.0, WALK_SPEED * 8.0 * delta)
		speed = WALK_SPEED
		if absf(velocity.x) > 1.0:
			_play_character_animation("Walk")
		else:
			_play_character_animation("default")

	if not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()
	_update_dog_follow(delta)


func _play_character_animation(animation_name: StringName) -> void:
	if animation_name == "Walk":
		sprite.scale = WALK_SPRITE_SCALE
		sprite.offset = WALK_SPRITE_OFFSET
	elif animation_name == "default":
		sprite.scale = IDLE_SPRITE_SCALE
		sprite.offset = IDLE_SPRITE_OFFSET
	else:
		sprite.scale = STANDARD_SPRITE_SCALE
		sprite.offset = Vector2.ZERO
	sprite.play(animation_name)


func _update_dog_follow(delta: float) -> void:
	trail_elapsed += delta
	trail.append({
		"time": trail_elapsed,
		"position": global_position,
		"direction": facing_direction,
	})

	var delayed_time := trail_elapsed - DOG_FOLLOW_DELAY
	while trail.size() > 2 and float(trail[1]["time"]) <= delayed_time:
		trail.pop_front()

	var delayed_point: Dictionary = trail[0]
	var direction := facing_direction
	var delayed_position: Vector2 = delayed_point["position"]
	var target := Vector2(
		delayed_position.x - direction * DOG_FOLLOW_DISTANCE,
		delayed_position.y + dog_vertical_offset
	)

	var blend := 1.0 - exp(-8.0 * delta)
	var previous_dog_position := dog.global_position
	dog.global_position = dog.global_position.lerp(target, blend)
	dog.flip_h = direction < 0.0
	var dog_animation: StringName = "Walk" if previous_dog_position.distance_to(dog.global_position) > 0.35 else "Idle"
	if dog.animation != dog_animation:
		dog.play(dog_animation)
