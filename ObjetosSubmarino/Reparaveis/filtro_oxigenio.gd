extends ObjetoReparavel

@export_group("Configuração do Relógio de Sujeira")
@export var intervalo_checagem: float = 20.0 
@export var chance_de_falha: float = 0.4 

@export_group("Impacto no Oxigênio")
@export var aumento_consumo_percentual: float = 200.0 # Ex: 200% = consome 3x mais rápido

var tempo_acumulado: float = 0.0

func _process(delta):
	if get_tree().paused or esta_quebrado:
		return
		
	tempo_acumulado += delta
	if tempo_acumulado >= intervalo_checagem:
		tempo_acumulado = 0.0 
		if randf() < chance_de_falha:
			quebrar()

func quebrar():
	if esta_quebrado: return 
	super.quebrar() 
	
	# Envia a percentagem DESTE filtro para o sistema
	if SistemaOxigenio:
		SistemaOxigenio.entupir_filtro(aumento_consumo_percentual)

func consertar(player):
	super.consertar(player)
	
	# Devolve a percentagem DESTE filtro para limpar a matemática
	if SistemaOxigenio:
		SistemaOxigenio.limpar_filtro(aumento_consumo_percentual)
