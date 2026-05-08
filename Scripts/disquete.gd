extends InteractableObject 
class_name Disquete

@export_group("Dados do Projeto")
@export var nome_projeto: String = "Projeto Desconhecido"
@export var cena_resultado: PackedScene 

@export_group("Custos de Fabricação (Unidades)")
@export var custo_metal: int = 0
@export var custo_plastico: int = 0
@export var custo_vidro: int = 0
@export var custo_papel: int = 0

func _ready():
	pode_ser_aberto = false 
	super._ready()
