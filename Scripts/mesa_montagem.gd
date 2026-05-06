extends StaticBody3D

@export_group("Referências")
@export var bandeja: Area3D
@export var monitor: Label3D
@export var slot_disquete: Marker3D
@export var ponto_spawn: Marker3D

var disquete_atual: Disquete = null
var barras_na_bandeja: Array = []
var contagem_material_atual: int = 0

func _process(_delta):
	_escanear_bandeja()
	_atualizar_monitor()

# --- 1. O SCANNER DA BANDEJA ---
func _escanear_bandeja():
	if not bandeja: return
	
	barras_na_bandeja.clear()
	contagem_material_atual = 0
	
	var corpos = bandeja.get_overlapping_bodies()
	
	for corpo in corpos:
		# MUDANÇA 1: A mesa agora EXIGE que a variável "e_material_refinado" seja verdadeira (true)
		if "peso_total" in corpo and not corpo.get("esta_segurado") and corpo.get("e_material_refinado") == true:
			
			if corpo.has_method("calcular_relatorio_triagem"):
				corpo.calcular_relatorio_triagem()
			
			if disquete_atual:
				if corpo.pesos_absolutos_materiais.has(disquete_atual.material_necessario):
					var peso = corpo.pesos_absolutos_materiais[disquete_atual.material_necessario]
					
					if peso > 0:
						barras_na_bandeja.append(corpo)
						# MUDANÇA 2: Conta +1 unidade (Barra) em vez de somar o peso da barra
						contagem_material_atual += 1
# --- 2. O MONITOR ---
func _atualizar_monitor():
	if monitor == null: return
		
	if not disquete_atual:
		monitor.text = "INSIRA UM PROJETO\n(DISQUETE)"
		monitor.modulate = Color.RED
		return
		
	var mat = disquete_atual.material_necessario
	var meta = disquete_atual.quantidade_necessaria # Removi o * 10
	
	monitor.text = "PROJETO: " + disquete_atual.nome_projeto + "\n"
	monitor.text += mat + ": " + str(contagem_material_atual) + " / " + str(meta)
	
	if contagem_material_atual >= meta:
		monitor.modulate = Color.GREEN
		monitor.text += "\nPRONTO PARA MONTAR!"
	else:
		monitor.modulate = Color.YELLOW

# --- 3. A LÓGICA DE CRAFTING ---
func craftar_item():
	if not disquete_atual:
		return
		
	var meta = disquete_atual.quantidade_necessaria 
	
	if contagem_material_atual >= meta:
		# MUDANÇA 3: Contador de unidades deletadas
		var barras_deletadas = 0
		
		# Deleta as barras usadas (uma por uma até bater a meta)
		for barra in barras_na_bandeja:
			if barras_deletadas < meta:
				barras_deletadas += 1
				barra.queue_free()
				
		# Spawna o item final
		if disquete_atual.cena_resultado:
			var novo_item = disquete_atual.cena_resultado.instantiate()
			get_tree().current_scene.add_child(novo_item)
			novo_item.global_position = ponto_spawn.global_position
