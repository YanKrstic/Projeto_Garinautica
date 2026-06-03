extends StaticBody3D
class_name LemeNavegacao

@export var mesh_manivela: Node3D 
@export var camera_leme: Camera3D # <--- AGORA É UMA CAMERA3D!
@export var sensibilidade_giro: float = 1.0

# Ajuste visual (Tente 0, 90, -90, etc. até alinhar perfeito)
@export var compensacao_visual_graus: float = 0.0 

var angulo_anterior_rato: float = 0.0
var player_pilotando = null
var giro_acumulado_total: float = 0.0 

func interagir_abrir():
	var player = get_tree().current_scene.find_child("Player", true, false)
	
	if player and player.estado_atual == "LIVRE":
		player.entrar_no_leme(self)
		player_pilotando = player
		
		var centro_tela = get_viewport().get_visible_rect().size / 2.0
		var mouse_pos = get_viewport().get_mouse_position()
		angulo_anterior_rato = centro_tela.angle_to_point(mouse_pos)
		
		# SNAP INICIAL (EIXO Z DEFINITIVO)
		if mesh_manivela:
			mesh_manivela.rotation.z = -angulo_anterior_rato + deg_to_rad(compensacao_visual_graus)
			
		print("Entraste no Leme!")

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
		# Lógica de Movimento
		var movimento_real = delta_angulo * sensibilidade_giro
		giro_acumulado_total += movimento_real
		print("Submarino moveu-se! Giro Acumulado: ", snapped(giro_acumulado_total, 0.01))
		# Visual da Manivela (EIXO Z DEFINITIVO)
		if mesh_manivela:
			mesh_manivela.rotation.z = -angulo_atual + deg_to_rad(compensacao_visual_graus)
			
	angulo_anterior_rato = angulo_atual
