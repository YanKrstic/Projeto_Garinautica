extends ObjetoReparavel

@export_group("Relógio de Desgaste do Motor")
@export var intervalo_checagem: float = 30.0
@export var chance_de_falha: float = 0.3 # 30% de chance de travar

var tempo_acumulado: float = 0.0

func _process(delta):
	if get_tree().paused or esta_quebrado or SistemaOxigenio.fase_atual < fase_desbloqueio:
		return
	
		
	tempo_acumulado += delta
	if tempo_acumulado >= intervalo_checagem:
		tempo_acumulado = 0.0 
		if randf() < chance_de_falha:
			quebrar()

# SOBRESCRITA: O que acontece quando as engrenagens travam
func quebrar():
	if esta_quebrado: return 
	super.quebrar() 
	
	# Manda o leme ficar pesado!
	get_tree().call_group("tela_radar", "dificultar_direcao")

# SOBRESCRITA: O que acontece quando conserta
func consertar(player):
	super.consertar(player)
	
	# Manda o leme voltar a ser leve e rápido
	get_tree().call_group("tela_radar", "normalizar_direcao")
