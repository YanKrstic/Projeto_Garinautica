extends Node3D

@export var cena_lixo: PackedScene # Arraste o seu "saco_de_lixo.tscn" para aqui!
@export var ponto_spawn: Marker3D
@export var luz_alerta: OmniLight3D

var lixos_armazenados: int = 0

func _ready():
	# Inscreve este tubo no grupo para ele conseguir "ouvir" o radar!
	add_to_group("tubos_de_coleta")
	_atualizar_visual()

# Esta função é ativada pelo Radar!
func receber_lixo():
	lixos_armazenados += 1
	_atualizar_visual()
	print("Tubo físico: Recebi o lixo! Retidos agora: ", lixos_armazenados)

# Esta função será ativada pela Alavanca!
func acionar_tubo():
	if lixos_armazenados > 0:
		lixos_armazenados -= 1
		if cena_lixo and ponto_spawn:
			var novo_lixo = cena_lixo.instantiate()
			get_tree().current_scene.add_child(novo_lixo)
			novo_lixo.global_position = ponto_spawn.global_position
		print("Tubo físico: Lixo ejetado no chão!")
	else:
		print("Tubo físico: Vazio. Vá pilotar e buscar mais!")
		
	_atualizar_visual()

func _atualizar_visual():
	if luz_alerta:
		# Se tem lixo, a luz acende forte. Se não, apaga.
		luz_alerta.light_energy = 2.0 if lixos_armazenados > 0 else 0.0
