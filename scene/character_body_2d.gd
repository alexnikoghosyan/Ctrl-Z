extends CharacterBody2D

const WALK_SPEED := 150.0
const RUN_SPEED := 200.0
const DOUBLE_TAP_WINDOW := 0.3
const DOG_FOLLOW_DELAY := 0.32
const DOG_FOLLOW_DISTANCE := 160.0
const DOG_FOLLOW_SPEED := 520.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var dog: AnimatedSprite2D = $Robot_Dog

var speed := WALK_SPEED
var double_tap_timer := 0.0
var facing_direction := 1.0
var dog_vertical_offset := 0.0
var trail_elapsed := 0.0
var trail: Array[Dictionary] = []


func _ready() -> void:
	dog_vertical_offset = dog.global_position.y - global_position.y

	dog.z_index = 1
	sprite.z_index = 2
	dog.play("default")

	trail.append({
		"time": trail_elapsed,
		"position": global_position,
		"direction": facing_direction,
	})


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
		sprite.play("Run" if speed == RUN_SPEED else "Walk")
	else:
		velocity.x = move_toward(velocity.x, 0.0, WALK_SPEED * 8.0 * delta)
		speed = WALK_SPEED
		if absf(velocity.x) > 1.0:
			sprite.play("Walk")
		else:
			sprite.play("default")

	if not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()
	_update_dog_follow(delta)


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
	dog.global_position = dog.global_position.lerp(target, blend)
	dog.flip_h = direction < 0.0
