extends MeshInstance3D

@export var velocidade: float = -0.34
@export var ajuste_uv: float = 0.5

var material_chao: StandardMaterial3D

func _ready():
	material_chao = get_active_material(0) as StandardMaterial3D

func _process(delta):
	if material_chao:
		material_chao.uv1_offset.y -= (velocidade * ajuste_uv) * delta
