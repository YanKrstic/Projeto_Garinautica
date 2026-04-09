extends RigidBody3D
class_name InteractableObject


@export_group("Configurações")
@export var pode_ser_aberto: bool = true 

@export_group("Visuais")
@export var modelo_fechado: Node3D
@export var modelo_aberto: Node3D

@export_group("Colisões")
@export var shapes_fechados: Array[CollisionShape3D]
@export var shapes_abertos: Array[CollisionShape3D]

@export_group("Loot / Itens")
@export var loot_dentro: Array[PackedScene] = []
@export var tabela_de_loot: Array[PackedScene] = []
@export var qtd_minima_loot: int = 1
@export var qtd_maxima_loot: int = 3

@export_group("Composição (Peso)")
@export var peso_plastico: int = 0
@export var peso_metal: int = 0
@export var peso_papel: int = 0
@export var peso_vidro: int = 0

var peso_total: int = 0
var pesos_absolutos_materiais: Dictionary = {}

var esta_segurado: bool = false
var ja_foi_aberto: bool = false
var esta_focado: bool = false
var material_outline: StandardMaterial3D

func _ready():
	# Configuração do Outline
	material_outline = StandardMaterial3D.new()
	material_outline.cull_mode = BaseMaterial3D.CULL_FRONT 
	material_outline.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED 
	material_outline.albedo_color = Color.WHITE 
	material_outline.grow = true 
	
	alternar_visual(false)
	alternar_lista_colisores(shapes_fechados, true)
	alternar_lista_colisores(shapes_abertos, false)
	
	# 1. Sorteia e CRIA FISICAMENTE os itens escondidos logo no início
	if loot_dentro.is_empty() and not tabela_de_loot.is_empty():
		var qtd = randi_range(qtd_minima_loot, qtd_maxima_loot)
		for i in range(qtd):
			loot_dentro.append(tabela_de_loot.pick_random())

	for cena in loot_dentro:
		if cena:
			var novo_item = cena.instantiate()
			add_child(novo_item) # Adiciona como filho escondido da caixa/saco
			novo_item.process_mode = Node.PROCESS_MODE_DISABLED # Congela a física do item
			novo_item.visible = false # Deixa-o invisível
			
	# Limpa a lista de projetos, pois agora os itens já são filhos reais na cena
	loot_dentro.clear() 
	
	# Pede para calcular o peso apenas depois de todos os filhos nascerem
	call_deferred("calcular_relatorio_triagem")

func interagir_abrir():
	# TRAVA DE SEGURANÇA:
	# Se o objeto não foi feito para abrir (ex: latinha, bola),
	# paramos aqui. Assim a física não quebra.
	if not pode_ser_aberto:
		return

	if ja_foi_aberto: return
	
	print("Abrindo objeto...")
	ja_foi_aberto = true
	
	alternar_visual(true)
	alternar_lista_colisores(shapes_fechados, false)
	alternar_lista_colisores(shapes_abertos, true)
	spawnar_loot()
	calcular_relatorio_triagem()
	
	atualizar_outline()

# --- FUNÇÕES DE CONTROLE VISUAL ---

func set_focado(estado: bool):
	esta_focado = estado
	atualizar_outline()

func ao_ser_pego():
	esta_segurado = true
	atualizar_outline()
	
	# MODO ESTÁTICO:
	# Troca para modo Kinematic/Freeze. O objeto para de cair e atravessa tudo,
	# mas ainda colide se o Player empurrar ele contra algo (processado no Player).
	freeze = true
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	
	# Desliga colisão com Player para evitar empurrões indesejados
	set_collision_mask_value(2, false)

func ao_ser_solto():
	esta_segurado = false
	atualizar_outline()
	
	# VOLTA PARA FÍSICA NORMAL:
	freeze = false
	
	# Restaura colisão com Player
	set_collision_mask_value(2, true)

func atualizar_outline():
	if esta_segurado:
		material_outline.grow_amount = 0.05 
		material_outline.albedo_color = Color(1, 1, 0.5) 
	elif esta_focado:
		material_outline.grow_amount = 0.02 
		material_outline.albedo_color = Color.WHITE
	else:
		material_outline.grow_amount = 0.0 
	
	var modelo_atual = modelo_aberto if ja_foi_aberto else modelo_fechado
	aplicar_overlay_no_modelo(modelo_atual, material_outline if (esta_focado or esta_segurado) else null)

func aplicar_overlay_no_modelo(no_pai: Node, material: Material):
	if not no_pai: return
	if no_pai is MeshInstance3D:
		no_pai.material_overlay = material
	for filho in no_pai.get_children():
		aplicar_overlay_no_modelo(filho, material)

# --- AUXILIARES ---

func alternar_visual(aberto: bool):
	if modelo_fechado: modelo_fechado.visible = !aberto
	if modelo_aberto: modelo_aberto.visible = aberto

func alternar_lista_colisores(lista: Array[CollisionShape3D], ativar: bool):
	for shape in lista:
		if shape: shape.set_deferred("disabled", !ativar)

func spawnar_loot():
	# 3. Solta os filhos que estavam guardados
	for filho in get_children():
		if filho is InteractableObject:
			var item_escondido = filho
			
			# Tira a subordinação da caixa e atira para o mundo principal
			remove_child(item_escondido)
			get_parent().add_child(item_escondido)
			
			# Acorda o item (liga a física e torna-o visível)
			item_escondido.process_mode = Node.PROCESS_MODE_INHERIT
			item_escondido.visible = true
			
			# Posição de saída e empurrão
			var offset = Vector3(0, 0, 1.0) if esta_segurado else Vector3(0, 0.5, 0)
			item_escondido.global_position = global_position + offset
			item_escondido.apply_impulse(Vector3(randf_range(-1,1), 2, randf_range(-1,1)))
	
func calcular_relatorio_triagem():
	pesos_absolutos_materiais.clear()
	
	pesos_absolutos_materiais["Plastico"] = peso_plastico
	pesos_absolutos_materiais["Metal"] = peso_metal
	pesos_absolutos_materiais["Papel"] = peso_papel
	pesos_absolutos_materiais["Vidro"] = peso_vidro
	
	peso_total = peso_plastico + peso_metal + peso_papel + peso_vidro
	
	# Se a caixa já abriu, já não tem nada dentro, por isso para por aqui
	if ja_foi_aberto:
		return
		
	# 2. Varre os filhos adormecidos e soma o peso deles
	for filho in get_children():
		# Garante que é um lixo e não apenas um modelo 3D
		if filho is InteractableObject: 
			filho.calcular_relatorio_triagem() # Pede para o filho atualizar-se
			
			peso_total += filho.peso_total
			
			for mat in filho.pesos_absolutos_materiais.keys():
				if pesos_absolutos_materiais.has(mat):
					pesos_absolutos_materiais[mat] += filho.pesos_absolutos_materiais[mat]
				else:
					pesos_absolutos_materiais[mat] = filho.pesos_absolutos_materiais[mat]


# --- SISTEMA DE DESMANCHE PROVISÓRIO ---

func desmanchar():
	# Trava de Segurança: Não faz nada se o jogador estiver segurando o item
	if esta_segurado:
		print("Solte o item no chão para desmanchá-lo!")
		return
		
	if not ja_foi_aberto:
		spawnar_loot()
	
	# Usamos LOAD em vez de PRELOAD para evitar o Crash de Dependência Circular!
	var cena_plastico = load("res://Itens/Sucatas/SucataPastico.tscn")
	var cena_metal = load("res://Itens/Sucatas/SucataMetal.tscn")
	var cena_papel = load("res://Itens/Sucatas/SucataPapel.tscn")
	var cena_vidro = load("res://Itens/Sucatas/SucataVidro.tscn")
	
	_gerar_sucata(cena_plastico, peso_plastico)
	_gerar_sucata(cena_metal, peso_metal)
	_gerar_sucata(cena_papel, peso_papel)
	_gerar_sucata(cena_vidro, peso_vidro)
	
	collision_layer = 0 # Fica intocável
	collision_mask = 0
	visible = false     # Fica invisível instantaneamente
	queue_free()        # Deleta com segurança

func _gerar_sucata(cena_sucata: PackedScene, quantidade: int):
	if quantidade <= 0 or not cena_sucata:
		return
		
	for i in range(quantidade):
		var nova_sucata = cena_sucata.instantiate()
		
		# Joga a sucata solta no mundo principal
		get_tree().current_scene.add_child(nova_sucata)
		
		nova_sucata.global_position = global_position + Vector3(randf_range(-0.3, 0.3), 0.5, randf_range(-0.3, 0.3))
		
		if nova_sucata is RigidBody3D:
			nova_sucata.apply_impulse(Vector3(randf_range(-2, 2), 3, randf_range(-2, 2)))
