extends Control

@onready var icone = $IconeSubmarino
var posicao_inicial_x: float

func _ready():
	posicao_inicial_x = icone.position.x

func atualizar_posicao_submarino(giro_acumulado: float):
	# O multiplicador (ex: 20.0) define quão rápido o ícone anda na tela
	icone.position.x = posicao_inicial_x + (giro_acumulado * 20.0)
	
	# Trava de segurança para o ícone não sair do ecrã
	icone.position.x = clamp(icone.position.x, 0, size.x - icone.size.x)
