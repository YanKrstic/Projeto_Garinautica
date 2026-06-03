extends Node3D

var mouse_sensitivity = 0.11

func _input(event):
	# Pergunta ao nó pai (Player) se ele está livre antes de mover a câmera verticalmente
	if get_parent().estado_atual == "LIVRE":
		if event is InputEventMouseMotion:
			var change = event.relative.y * -mouse_sensitivity
			rotation.x += deg_to_rad(change)
			rotation.x = clamp(rotation.x, deg_to_rad(-90), deg_to_rad(90))
