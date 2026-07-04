extends Node3D

@export_group("Conexões")
@export var radar_2d: Control # Arraste a sua TelaRadar (dentro do SubViewport) para aqui
@export var luz_esquerda: Node3D 
@export var luz_direita: Node3D

@export_group("Configuração da Maré")
@export var forca_arrasto: float = 50.0 # Pixels por segundo que o submarino é empurrado
@export var tempo_min_espera: float = 10.0
@export var tempo_max_espera: float = 25.0
@export var duracao_correnteza: float = 6.0

@export_group("Configuração de Fases")
@export var fase_desbloqueio: int = 2 # A correnteza só acorda na Fase 2!

var timer_espera: float = 0.0
var timer_duracao: float = 0.0
var correnteza_ativa: bool = false
var direcao_atual: float = 0.0

func _ready():
	_desligar_luzes()
	_reiniciar_espera()

func _process(delta):
	if get_tree().paused or SistemaOxigenio.fase_atual < fase_desbloqueio: 
		return
		
	
	if correnteza_ativa:
		# Conta o tempo que a maré vai durar
		timer_duracao -= delta
		
		# Empurra constantemente o radar
		if radar_2d and radar_2d.has_method("aplicar_correnteza"):
			radar_2d.aplicar_correnteza(direcao_atual * forca_arrasto)
			
		# Acabou a maré
		if timer_duracao <= 0:
			_parar_correnteza()
	else:
		# Conta o tempo de paz até a próxima maré
		timer_espera -= delta
		if timer_espera <= 0:
			_iniciar_correnteza()

func _iniciar_correnteza():
	correnteza_ativa = true
	timer_duracao = duracao_correnteza
	
	# Sorteia a direção: 50% de chance para cada lado
	if randf() > 0.5:
		direcao_atual = 1.0 # Empurra o submarino para a DIREITA
		if luz_direita: luz_direita.visible = true
	else:
		direcao_atual = -1.0 # Empurra o submarino para a ESQUERDA
		if luz_esquerda: luz_esquerda.visible = true
		
	print("ALERTA MARÍTIMO: Correnteza atingindo o casco! Direção: ", direcao_atual)

func _parar_correnteza():
	correnteza_ativa = false
	direcao_atual = 0.0
	_desligar_luzes()
	
	# Manda o radar parar de deslizar
	if radar_2d and radar_2d.has_method("aplicar_correnteza"):
		radar_2d.aplicar_correnteza(0.0)
		
	_reiniciar_espera()

func _reiniciar_espera():
	timer_espera = randf_range(tempo_min_espera, tempo_max_espera)

func _desligar_luzes():
	if luz_esquerda: luz_esquerda.visible = false
	if luz_direita: luz_direita.visible = false
