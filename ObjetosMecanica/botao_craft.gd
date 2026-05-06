extends StaticBody3D

func interagir_abrir():
	# Avisa a mesa para tentar fabricar o item
	if get_parent().has_method("craftar_item"):
		get_parent().craftar_item()
