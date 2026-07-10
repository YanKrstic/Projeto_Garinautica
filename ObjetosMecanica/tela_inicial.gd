extends Control

# O preload garante que o Manual já esteja carregado na memória assim que o Menu abrir
const CenaManual = preload("res://ObjetosMecanica/tela_manual.tscn")

func _ready() -> void:
	# Garante que o jogo não inicie pausado e destrava o cursor
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_botao_iniciar_pressed() -> void:
	SistemaOxigenio.reiniciar_partida_completa()
	get_tree().call_deferred("change_scene_to_file", "res://mapa/node_3d.tscn")

func _on_botao_manual_pressed() -> void:
	# Instancia e adiciona o Manual como "filho" deste Menu (sobreposição)
	var manual = CenaManual.instantiate()
	add_child(manual)

func _on_botao_ranking_pressed() -> void:
	# Abre a URL no navegador padrão do sistema
	OS.shell_open("https://garinautica.vercel.app/")

func _on_botao_sair_pressed() -> void:
	get_tree().quit()
