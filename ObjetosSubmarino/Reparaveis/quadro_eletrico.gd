extends ObjetoReparavel

@export_group("Configuração do Relógio do Caos")
# De quanto em quanto tempo (em segundos) o quadro decide se vai falhar
@export var intervalo_checagem: float = 15.0 
# A chance de falhar a cada checagem (0.3 = 30% de chance)
@export var chance_de_falha: float = 0.3 

var tempo_acumulado: float = 0.0

func _ready():
	add_to_group("quadros_eletricos")
	super._ready()

func _process(delta):
	# Se o jogo estiver pausado ou o painel JÁ estiver quebrado, para o relógio
	if get_tree().paused or esta_quebrado:
		return
		
	# Conta o tempo em tempo real
	tempo_acumulado += delta
	if tempo_acumulado >= intervalo_checagem:
		tempo_acumulado = 0.0 # Reseta o relógio
		_tentar_gerar_falha_eletrica()

func _tentar_gerar_falha_eletrica():
	# Sorteia um número entre 0.0 e 1.0
	if randf() < chance_de_falha:
		quebrar()

# SOBRESCRITA: Apaga as luzes
func quebrar():
	if esta_quebrado: return 
	super.quebrar() 
	
	print("ALERTA: O sistema elétrico falhou por desgaste! Apagando luzes...")
	get_tree().set_group("luzes_principais", "visible", false)

# SOBRESCRITA: Acende as luzes
func consertar(player):
	super.consertar(player)
	
	print("Reparo Elétrico Concluído! Luzes restauradas.")
	get_tree().set_group("luzes_principais", "visible", true)
