extends Node3D

@export_group("Áudios das Fases")
@export var audio_fase1: AudioStream
@export var audio_fase2: AudioStream
@export var audio_fase3: AudioStream

@onready var alto_falante = $AltoFalante

func _ready():
	# Entra no grupo global para o Cérebro o encontrar
	add_to_group("radio_cabine")
	
	# Assim que o rádio nascer no mapa, se for o início do jogo, toca a Fase 1!
	if SistemaOxigenio.fase_atual == 1:
		tocar_mensagem(1)

func tocar_mensagem(fase: int):
	# Corta qualquer áudio que estiver tocando
	alto_falante.stop() 

	if fase == 1 and audio_fase1 != null:
		alto_falante.stream = audio_fase1
		alto_falante.play()
		print("Rádio 3D: Tocando áudio da Fase 1")
		
	elif fase == 2 and audio_fase2 != null:
		alto_falante.stream = audio_fase2
		alto_falante.play()
		print("Rádio 3D: Tocando áudio da Fase 2")
		
	elif fase == 3 and audio_fase3 != null:
		alto_falante.stream = audio_fase3
		alto_falante.play()
		print("Rádio 3D: Tocando áudio da Fase 3")
