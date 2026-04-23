extends StaticBody3D

@export_group("Configurações da Refinaria")
@export_enum("Plastico", "Metal", "Papel", "Vidro") var material_alvo: String = "Metal"
@export var capacidade_maxima: int = 10
@export var cena_barra: PackedScene

@export_group("Referências (Nós)")
@export var area_fornalha: Area3D
@export var ponto_de_saida: Marker3D
@export var monitor: Label3D

var tanque_atual: int = 0

func _ready():
	atualizar_monitor()
	
	# Conecta a área automaticamente para facilitar a sua vida!
	if area_fornalha:
		area_fornalha.body_entered.connect(_on_fornalha_body_entered)

func _on_fornalha_body_entered(corpo):
	if "peso_total" not in corpo:
		return
		
	if "esta_segurado" in corpo and corpo.esta_segurado:
		return
		
	if corpo.has_method("calcular_relatorio_triagem"):
		corpo.calcular_relatorio_triagem()

	var peso_total = corpo.peso_total
	if peso_total <= 0: 
		return

	# 2. VERIFICA A PUREZA E O LIMITE DO TANQUE
	var peso_do_alvo = 0
	if corpo.pesos_absolutos_materiais.has(material_alvo):
		peso_do_alvo = corpo.pesos_absolutos_materiais[material_alvo]

	var e_puro = (peso_do_alvo == peso_total)
	
	# MUDANÇA: Verifica se a soma vai passar do limite
	var cabe_no_tanque = (tanque_atual + peso_total) <= capacidade_maxima

	# A máquina agora só engole se for puro E se não transbordar o tanque!
	if e_puro and cabe_no_tanque:
		_processar_item_puro(corpo, peso_total)
	else:
		_rejeitar_item(corpo)

func _processar_item_puro(corpo, peso: int):
	corpo.collision_layer = 0
	corpo.collision_mask = 0
	corpo.visible = false
	corpo.queue_free()

	tanque_atual += peso
	atualizar_monitor()
	
	# MUDANÇA: Como a máquina nunca passa do limite, basta ejetar a barra quando bater exatos 10
	if tanque_atual == capacidade_maxima:
		tanque_atual = 0
		forjar_barra()
		atualizar_monitor()
func _rejeitar_item(corpo):
	# Teleporta o item impuro para o tubo de saída
	corpo.global_position = ponto_de_saida.global_position
	
	# Zera a velocidade de queda para o empurrão ser limpo
	corpo.linear_velocity = Vector3.ZERO 
	
	var direcao_frente = ponto_de_saida.global_transform.basis.z
	var empurrao = (direcao_frente * randf_range(3.0, 5.0)) + Vector3(0, randf_range(1.0, 2.0), 0)
	
	corpo.apply_central_impulse(empurrao)

func forjar_barra():
	if not cena_barra:
		print("ERRO: Cena da barra não configurada no Inspector!")
		return
		
	var barra = cena_barra.instantiate()
	
	# O call_deferred é obrigatório no Godot 4 para criar coisas durante uma colisão
	get_tree().current_scene.call_deferred("add_child", barra)
	
	# Espera um frame para garantir que a barra foi adicionada à árvore
	await get_tree().process_frame 
	
	barra.global_position = ponto_de_saida.global_position
	
	var direcao_frente = ponto_de_saida.global_transform.basis.z
	var empurrao = (direcao_frente * 5.0) + Vector3(0, 2.0, 0)
	
	if barra is RigidBody3D:
		barra.apply_central_impulse(empurrao)

func atualizar_monitor():
	if monitor:
		monitor.text = material_alvo.to_upper() + "\n" + str(tanque_atual) + " / " + str(capacidade_maxima)
