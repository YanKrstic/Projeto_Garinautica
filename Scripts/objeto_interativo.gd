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

# Variáveis internas que a balança vai ler
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
	
	loot_dentro = loot_dentro.duplicate()
	
	alternar_visual(false)
	alternar_lista_colisores(shapes_fechados, true)
	alternar_lista_colisores(shapes_abertos, false)
	
	if loot_dentro.size() == 0 and tabela_de_loot.size() > 0:
		var qtd = randi_range(qtd_minima_loot, qtd_maxima_loot)
		for i in range(qtd):
			loot_dentro.append(tabela_de_loot.pick_random())
	
	calcular_relatorio_triagem()
# --- FUNÇÕES DE INTERAÇÃO ---

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
	if loot_dentro.is_empty(): return
	for item in loot_dentro:
		if item:
			var novo = item.instantiate()
			get_parent().add_child(novo)
			var offset = Vector3(0, 0, 1.0) if esta_segurado else Vector3(0, 0.5, 0)
			novo.global_position = global_position + offset
			if novo is RigidBody3D:
				novo.apply_impulse(Vector3(randf_range(-1,1), 2, randf_range(-1,1)))
	loot_dentro.clear()
	
func calcular_relatorio_triagem():
	pesos_absolutos_materiais.clear()
	
	# 1. Registra a composição base deste próprio objeto
	pesos_absolutos_materiais["Plástico"] = peso_plastico
	pesos_absolutos_materiais["Metal"] = peso_metal
	pesos_absolutos_materiais["Papel"] = peso_papel
	pesos_absolutos_materiais["Vidro"] = peso_vidro
	
	peso_total = peso_plastico + peso_metal + peso_papel + peso_vidro
	
	# 2. Se houver itens dentro da caixa, simula eles para somar ao relatório
	for cena_item in loot_dentro:
		if cena_item:
			var temp_item = cena_item.instantiate()
			if temp_item is InteractableObject:
				# Pede para o clone calcular a si mesmo primeiro
				temp_item.calcular_relatorio_triagem()
				
				# Soma o peso total
				peso_total += temp_item.peso_total
				
				# Soma as composições misturadas
				for mat in temp_item.pesos_absolutos_materiais.keys():
					pesos_absolutos_materiais[mat] += temp_item.pesos_absolutos_materiais[mat]
					
			temp_item.queue_free()
