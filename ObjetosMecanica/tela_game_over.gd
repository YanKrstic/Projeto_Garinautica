extends Control

# O símbolo % diz à Godot para procurar este nó em QUALQUER LUGAR da cena!
@onready var motivo_texto = %MotivoTexto 

func _ready():
	hide() 

func exibir(motivo: String):
	show()
	motivo_texto.text = motivo # Agora ele vai encontrar com certeza!
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) 
	get_tree().paused = true 

func _on_botao_reiniciar_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()
