extends StaticBody3D

@export_group("Referências")
@export var bandeja: Area3D
@export var monitor: Label3D
@export var slot_disquete: Marker3D
@export var ponto_spawn: Marker3D

var disquete_atual: Disquete = null

# Organizador inteligente das barras que caem na bandeja
var barras_na_bandeja = {
	"Metal": [],
	"Plastico": [],
	"Vidro": [],
	"Papel": []
}

func _process(_delta):
	_escanear_bandeja()
	_atualizar_monitor()

# --- 1. O SCANNER DA BANDEJA ---
func _escanear_bandeja():
	if not bandeja: return
	
	# Esvazia as gavetas a cada frame para recontar tudo de forma limpa
	barras_na_bandeja["Metal"].clear()
	barras_na_bandeja["Plastico"].clear()
	barras_na_bandeja["Vidro"].clear()
	barras_na_bandeja["Papel"].clear()
	
	var corpos = bandeja.get_overlapping_bodies()
	
	for corpo in corpos:
		if "peso_total" in corpo and not corpo.get("esta_segurado") and corpo.get("e_material_refinado") == true:
			if corpo.has_method("calcular_relatorio_triagem"):
				corpo.calcular_relatorio_triagem()
			
			# Descobre de que material a barra é feita e guarda-a na respetiva "gaveta"
			for mat in barras_na_bandeja.keys():
				if corpo.pesos_absolutos_materiais.has(mat) and corpo.pesos_absolutos_materiais[mat] > 0:
					barras_na_bandeja[mat].append(corpo)
					break # Assume que cada barra refinada é de apenas 1 material puro

# --- 2. O MONITOR ---
func _atualizar_monitor():
	if monitor == null: return
		
	if not disquete_atual:
		monitor.text = "INSIRA UM PROJETO\n(DISQUETE)"
		monitor.modulate = Color.RED
		return
		
	var texto = "PROJETO: " + disquete_atual.nome_projeto + "\n"
	var pronto = true
	var tem_requisitos = false
	
	# Verifica cada material. Só mostra no ecrã se o custo for maior que zero!
	if disquete_atual.custo_metal > 0:
		tem_requisitos = true
		var qtd = barras_na_bandeja["Metal"].size()
		texto += "Metal: " + str(qtd) + " / " + str(disquete_atual.custo_metal) + "\n"
		if qtd < disquete_atual.custo_metal: pronto = false
		
	if disquete_atual.custo_plastico > 0:
		tem_requisitos = true
		var qtd = barras_na_bandeja["Plastico"].size()
		texto += "Plastico: " + str(qtd) + " / " + str(disquete_atual.custo_plastico) + "\n"
		if qtd < disquete_atual.custo_plastico: pronto = false

	if disquete_atual.custo_vidro > 0:
		tem_requisitos = true
		var qtd = barras_na_bandeja["Vidro"].size()
		texto += "Vidro: " + str(qtd) + " / " + str(disquete_atual.custo_vidro) + "\n"
		if qtd < disquete_atual.custo_vidro: pronto = false

	if disquete_atual.custo_papel > 0:
		tem_requisitos = true
		var qtd = barras_na_bandeja["Papel"].size()
		texto += "Papel: " + str(qtd) + " / " + str(disquete_atual.custo_papel) + "\n"
		if qtd < disquete_atual.custo_papel: pronto = false
		
	if not tem_requisitos:
		texto += "Erro: Sem custos definidos!"
		pronto = false

	if pronto:
		monitor.modulate = Color.GREEN
		texto += "PRONTO PARA MONTAR!"
	else:
		monitor.modulate = Color.YELLOW
		
	monitor.text = texto

# --- 3. A LÓGICA DE CRAFTING ---
func craftar_item():
	if not disquete_atual: return
	
	# Trava final de segurança: Verifica se tem as quantidades mínimas de tudo
	if disquete_atual.custo_metal > 0 and barras_na_bandeja["Metal"].size() < disquete_atual.custo_metal: return
	if disquete_atual.custo_plastico > 0 and barras_na_bandeja["Plastico"].size() < disquete_atual.custo_plastico: return
	if disquete_atual.custo_vidro > 0 and barras_na_bandeja["Vidro"].size() < disquete_atual.custo_vidro: return
	if disquete_atual.custo_papel > 0 and barras_na_bandeja["Papel"].size() < disquete_atual.custo_papel: return
	
	# Se chegou aqui, a receita está completa! Vamos "gastar" as barras exatas.
	_deletar_barras("Metal", disquete_atual.custo_metal)
	_deletar_barras("Plastico", disquete_atual.custo_plastico)
	_deletar_barras("Vidro", disquete_atual.custo_vidro)
	_deletar_barras("Papel", disquete_atual.custo_papel)
	
	# Spawna a recompensa!
	if disquete_atual.cena_resultado:
		var novo_item = disquete_atual.cena_resultado.instantiate()
		get_tree().current_scene.add_child(novo_item)
		novo_item.global_position = ponto_spawn.global_position

# Função auxiliar para deletar apenas a quantidade que foi usada na receita
func _deletar_barras(material: String, quantidade_a_deletar: int):
	for i in range(quantidade_a_deletar):
		var barra = barras_na_bandeja[material][i]
		barra.queue_free()
