extends ObjetoReparavel

@export_group("Relógio de Avaria do Radar")
@export var intervalo_checagem: float = 25.0
@export var chance_de_falha: float = 0.35 # 35% de chance

var tempo_acumulado: float = 0.0


func _process(delta):
	
	if get_tree().paused or esta_quebrado or SistemaOxigenio.fase_atual < fase_desbloqueio:
		return
		
	tempo_acumulado += delta
	if tempo_acumulado >= intervalo_checagem:
		tempo_acumulado = 0.0 
		if randf() < chance_de_falha:
			quebrar()

# SOBRESCRITA: O que acontece quando quebra
func quebrar():
	if esta_quebrado: return 
	super.quebrar() 
	
	# Manda o ecrã 2D ficar preto!
	get_tree().call_group("tela_radar", "avariar_tela")

# SOBRESCRITA: O que acontece quando repara
func consertar(player):
	super.consertar(player)
	
	# Manda o ecrã 2D voltar ao normal
	get_tree().call_group("tela_radar", "reparar_tela")
