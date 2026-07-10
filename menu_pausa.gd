extends CanvasLayer

@onready var painel_ui = $PainelUI
@onready var btn_continuar = $PainelUI/VBoxContainer/BtnContinuar

# Variável para saber se o jogador estava no leme (rato solto) ou a andar (rato preso)
var mouse_estava_solto: bool = false 

const CenaManual = preload("res://ObjetosMecanica/tela_manual.tscn")

func _ready():
	# Começa escondido
	painel_ui.hide()

func _input(event):
	if event.is_action_pressed("ui_cancel"): # ui_cancel = Tecla ESC
		if SistemaOxigenio.bloqueia_pausa:
			return
		if get_tree().paused:
			despausar()
		else:
			pausar()

func pausar():
	get_tree().paused = true
	painel_ui.show()
	
	# Guarda o estado atual do rato
	mouse_estava_solto = (Input.mouse_mode == Input.MOUSE_MODE_VISIBLE)
	
	# Liberta o rato para o jogador poder clicar nos botões
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Foca automaticamente no botão para permitir usar o teclado (setas + enter)
	btn_continuar.grab_focus()

func despausar():
	painel_ui.hide()
	get_tree().paused = false
	
	# Devolve o rato exatamente como estava (preso se estava a andar, solto se estava no leme)
	if mouse_estava_solto:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# --- SINAIS DOS BOTÕES ---
func _on_btn_continuar_pressed():
	despausar()

func _on_btn_sair_pressed():
	get_tree().quit()

func _on_btn_manual_pressed() -> void: # Ou o nome da sua função
		print("Botão do manual foi clicado!") # <- Adicione isso
		var manual = CenaManual.instantiate()
		add_child(manual)

func _on_btn_menu_pressed() -> void:
	pass # Replace with function body.
