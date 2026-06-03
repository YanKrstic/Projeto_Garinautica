extends "res://Scripts/Alavanca.gd"

@export var tubo_conectado: Node3D 

func _ready():
	# Roda o código original da alavanca para garantir o outline e posição iniciais
	super._ready()

# SOBRESCRITA: Esta versão da função vai ignorar o Spawner antigo e focar apenas no Tubo!
func funcao_do_spawn():
	if tubo_conectado and tubo_conectado.has_method("acionar_tubo"):
		tubo_conectado.acionar_tubo()
	else:
		print("Alavanca do Tubo: Nenhum tubo foi arrastado para o Inspector!")
