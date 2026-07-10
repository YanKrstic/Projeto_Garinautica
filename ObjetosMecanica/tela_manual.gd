extends Control

# O método queue_free() atua como um "unmount" do componente,
# destruindo esta tela e revelando o que quer que esteja por baixo.
func _on_botao_voltar_pressed() -> void:
	queue_free()
