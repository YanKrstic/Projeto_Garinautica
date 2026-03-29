extends Area3D

@export var monitor_materiais: Label3D
@export var monitor_peso: Label3D

var itens_na_balanca: Array = []

func _ready():
	# Chama a função assim que o jogo começa para a tela não ficar em branco
	atualizar_monitor()

func _on_body_entered(body):
	if "peso_total" in body:
		itens_na_balanca.append(body)
		atualizar_monitor()

func _on_body_exited(body):
	if body in itens_na_balanca:
		itens_na_balanca.erase(body)
		atualizar_monitor()

func atualizar_monitor():
	if not monitor_materiais or not monitor_peso:
		return
		
	var soma_peso_total = 0
	
	# MUDANÇA 1: Sem acento aqui
	var soma_materiais = {
		"Plastico": 0, 
		"Metal": 0,
		"Papel": 0,
		"Vidro": 0
	}
	
	# Soma tudo o que estiver na balança
	for item in itens_na_balanca:
		soma_peso_total += item.peso_total
		for mat in item.pesos_absolutos_materiais.keys():
			if soma_materiais.has(mat):
				soma_materiais[mat] += item.pesos_absolutos_materiais[mat]
			
	monitor_peso.text = "Peso....... " + str(soma_peso_total)
	
	var texto_mat = "" 
	
	# MUDANÇA 2: Sem acento aqui também
	var ordem_materiais = ["Plastico", "Metal", "Papel", "Vidro"] 
	
	for mat in ordem_materiais:
		var percentagem = 0
		if soma_peso_total > 0:
			percentagem = roundi((float(soma_materiais[mat]) / float(soma_peso_total)) * 100.0)
		
		var linha_formatada = mat.rpad(12, ".") + " " + str(percentagem) + "%\n"
		texto_mat += linha_formatada
			
	monitor_materiais.text = texto_mat
