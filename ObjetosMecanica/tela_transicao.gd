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
	SistemaOxigenio.bloqueia_pausa = false 
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) 
	get_tree().paused = false # O mundo acorda!
	
	# A MÁGICA: Esperamos exatamente 0.2 segundos reais antes de gritar a ordem.
	# Isso garante que o motor de áudio já "descongelou" totalmente!
	await get_tree().create_timer(0.2).timeout
	
	if SistemaOxigenio:
		get_tree().call_group("radio_cabine", "tocar_mensagem", SistemaOxigenio.fase_atual)
