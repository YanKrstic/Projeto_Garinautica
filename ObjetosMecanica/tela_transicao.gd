extends Control

@onready var texto_radio = %TextoRadio

func _ready():
	hide() # Começa invisível

func exibir(mensagem_radio: String):
	texto_radio.text = mensagem_radio
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) # Libera o mouse
	get_tree().paused = true # Pausa o caos!

# Lembre-se de conectar o sinal 'pressed' do botão a esta função!
func _on_botao_continuar_pressed():
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) # Prende o mouse de volta
	get_tree().paused = false # O jogo volta a rolar!
