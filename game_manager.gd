extends Node

func _ready() -> void:
	pass 


func _process(delta: float) -> void:
	pass
	
func _unhandled_input(event):
	
	if (event.is_action_pressed("Pause")):
		get_tree().paused = not get_tree().paused
