extends InteractableObject # Mudamos de RigidBody3D para herdar o seu script base!
class_name Disquete

@export_group("Dados do Projeto")
@export var nome_projeto: String = "Reparo de Casco"
@export_enum("Plastico", "Metal", "Papel", "Vidro") var material_necessario: String = "Metal"
@export var quantidade_necessaria: int = 2
@export var cena_resultado: PackedScene 

func _ready():
	# Desativamos a função de abrir, afinal, não queremos "abrir" um disquete como uma caixa
	pode_ser_aberto = false 
	
	# Chama o _ready() do script original (objeto_interativo) para configurar a silhueta e física
	super._ready()
