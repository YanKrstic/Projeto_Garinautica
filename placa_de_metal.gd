extends InteractableObject
class_name FerramentaReparo

@export var tipo_reparo: String = "Casco"

func _ready():
	# Desativamos a função de abrir, pois é uma ferramenta a
	pode_ser_aberto = false 
	# Chama o setup original para ter silhueta e física
	super._ready()
