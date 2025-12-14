extends Node3D

var mouse_sensitivity = 0.11

func _ready():
	pass

func _input(event):
	if event is InputEventMouseMotion:
		var change = event.relative.y * -mouse_sensitivity
		rotation.x += deg_to_rad(change)
		rotation.x = clamp(rotation.x, deg_to_rad(-90), deg_to_rad(90))

func _process(delta):
	pass
