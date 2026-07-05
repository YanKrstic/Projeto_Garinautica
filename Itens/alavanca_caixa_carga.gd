extends "res://Scripts/Alavanca.gd"

func _ready():
	super._ready() # Garante que as configurações visuais originais carreguem

# A MÁGICA: Em vez de mexer no clique, nós mudamos o que acontece no final da animação!
func funcao_do_spawn():
	print("Alavanca puxada! Verificando a carga...")
	
	if SistemaOxigenio:
		SistemaOxigenio.avancar_fase()
