extends ObjetoReparavel

@export_group("Configuração do Relógio de Sujeira")
@export var intervalo_checagem: float = 20.0 
@export var chance_de_falha: float = 0.4 # 40% de chance de entupir a cada checagem

var tempo_acumulado: float = 0.0

func _process(delta):
	if get_tree().paused or esta_quebrado:
		return
		
	# Conta o tempo em que o filtro está acumulando poeira
	tempo_acumulado += delta
	if tempo_acumulado >= intervalo_checagem:
		tempo_acumulado = 0.0 
		if randf() < chance_de_falha:
			quebrar()

# SOBRESCRITA: O que acontece quando entope
func quebrar():
	if esta_quebrado: return 
	super.quebrar() 
	
	# MÁGICA: Avisa o sistema global para aumentar a taxa de consumo
	if SistemaOxigenio:
		SistemaOxigenio.entupir_filtro()

# SOBRESCRITA: O que acontece quando conserta
func consertar(player):
	super.consertar(player)
	
	# MÁGICA: Avisa o sistema global para voltar o ar ao normal
	if SistemaOxigenio:
		SistemaOxigenio.limpar_filtro()
