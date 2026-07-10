extends Control

# O preload garante que o Manual já esteja carregado na memória assim que o Menu abrir
const CenaManual = preload("res://ObjetosMecanica/tela_manual.tscn")

func _ready() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Garante que o HUD do oxigênio desapareça assim que o Menu abrir
	SistemaOxigenio.esconder_interface()

func _on_botao_iniciar_pressed() -> void:
	SistemaOxigenio.reiniciar_partida_completa()
	
	# Acende as luzes do HUD no exato momento em que pularmos para o mapa 3D!
	SistemaOxigenio.mostrar_interface()
	
	get_tree().change_scene_to_file("res://mapa/node_3d.tscn")

func _on_botao_manual_pressed() -> void:
	# Instancia e adiciona o Manual como "filho" deste Menu (sobreposição)
	var manual = CenaManual.instantiate()
	add_child(manual)

func _on_botao_ranking_pressed() -> void:
	# Abre a URL no navegador padrão do sistema
	OS.shell_open("https://garinautica.vercel.app/")

func _on_botao_sair_pressed() -> void:
	get_tree().quit()
