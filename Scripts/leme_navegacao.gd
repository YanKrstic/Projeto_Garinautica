extends StaticBody3D
class_name LemeNavegacao

@export var mesh_manivela: Node3D 
@export var camera_leme: Camera3D 
@export var radar_2d: Control 
@export var sensibilidade_giro: float = 1.0
@export var compensacao_visual_graus: float = 0.0 

var angulo_anterior_rato: float = 0.0
var player_pilotando = null

func interagir_abrir():
	var player = get_tree().current_scene.find_child("Player", true, false)
	
	if player and player.estado_atual == "LIVRE":
		player.entrar_no_leme(self)
		player_pilotando = player
		
		var centro_tela = get_viewport().get_visible_rect().size / 2.0
		var mouse_pos = get_viewport().get_mouse_position()
		angulo_anterior_rato = centro_tela.angle_to_point(mouse_pos)
		
		if mesh_manivela:
			mesh_manivela.rotation.x = -angulo_anterior_rato + deg_to_rad(compensacao_visual_graus)

func _process(delta):
	if player_pilotando != null and player_pilotando.estado_atual == "PILOTANDO":
		_calcular_giro_mouse()
	else:
		player_pilotando = null 

func _calcular_giro_mouse():
	var centro_tela = get_viewport().get_visible_rect().size / 2.0
	var mouse_pos = get_viewport().get_mouse_position()
	
	var angulo_atual = centro_tela.angle_to_point(mouse_pos)
	var delta_angulo = wrapf(angulo_atual - angulo_anterior_rato, -PI, PI)
	
	if abs(delta_angulo) > 0.001:
		var movimento_real = delta_angulo * sensibilidade_giro
		
		# MUDANÇA: Agora enviamos apenas a "fração" que o mouse moveu neste exato frame
		if radar_2d and radar_2d.has_method("mover_submarino"):
			radar_2d.mover_submarino(movimento_real)
			
		if mesh_manivela:
			mesh_manivela.rotation.x = -angulo_atual + deg_to_rad(compensacao_visual_graus)
			
	angulo_anterior_rato = angulo_atual
