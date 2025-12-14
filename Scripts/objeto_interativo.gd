extends RigidBody3D
class_name InteractableObject

# --- CONFIGURAÇÃO VISUAL ---
@export_group("Visuais")
@export var modelo_fechado: Node3D
@export var modelo_aberto: Node3D

# --- CONFIGURAÇÃO DE COLISÃO ---
# MUDANÇA AQUI: Agora usamos Arrays (Listas) de colisores
@export_group("Colisões")
@export var shapes_fechados: Array[CollisionShape3D]
@export var shapes_abertos: Array[CollisionShape3D]

# --- LOOT ---
@export_group("Loot / Itens")
@export var loot_dentro: Array[PackedScene] = []
@export var tabela_de_loot: Array[PackedScene] = []

var esta_segurado: bool = false
var ja_foi_aberto: bool = false

func _ready():
	loot_dentro = loot_dentro.duplicate()
	
	# Garante estado inicial FECHADO
	alternar_visual(false)
	
	# Ativa colisores fechados, desativa abertos
	alternar_lista_colisores(shapes_fechados, true)
	alternar_lista_colisores(shapes_abertos, false)
	
	# Sorteio Loot
	if loot_dentro.size() == 0 and tabela_de_loot.size() > 0:
		var qtd = randi_range(1, 3)
		for i in range(qtd):
			loot_dentro.append(tabela_de_loot.pick_random())

# --- LÓGICA DE TROCA ---

func alternar_visual(aberto: bool):
	if modelo_fechado: modelo_fechado.visible = !aberto
	if modelo_aberto: modelo_aberto.visible = aberto

# Função genérica para ligar/desligar uma LISTA de shapes
func alternar_lista_colisores(lista: Array[CollisionShape3D], ativar: bool):
	for shape in lista:
		if shape:
			shape.set_deferred("disabled", !ativar)

# --- INTERAÇÃO ---

# --- SISTEMA DE INTERAÇÃO ---

func interagir_pegar(nova_posicao_node):
	esta_segurado = true
	freeze = true 
	
	# MUDANÇA: NÃO desligamos mais os colisores aqui.
	# Mantemos eles ligados para que o RayCast consiga detectar o objeto
	# e permitir que você aperte o botão de abrir.
	
	# Se a caixa começar a empurrar seu personagem, a solução correta será
	# alterar os Layers de colisão (Collision Layer) no inspetor do objeto,
	# e não desligar os shapes.

func interagir_soltar(impulso_forca: Vector3 = Vector3.ZERO):
	esta_segurado = false
	freeze = false 
	
	# Garante que a física correta esteja aplicada ao soltar
	if ja_foi_aberto:
		alternar_lista_colisores(shapes_fechados, false)
		alternar_lista_colisores(shapes_abertos, true)
	else:
		alternar_lista_colisores(shapes_fechados, true)
		alternar_lista_colisores(shapes_abertos, false)
	
	apply_impulse(impulso_forca)

func interagir_abrir():
	# Se já abriu, não faz nada
	if ja_foi_aberto: 
		return

	print("Abrindo objeto...")
	ja_foi_aberto = true
	
	# 1. Troca o visual
	alternar_visual(true)
	
	# 2. Troca a física IMEDIATAMENTE (mesmo segurando)
	# Assim o colisor muda para o formato aberto e o Raycast continua funcionando
	alternar_lista_colisores(shapes_fechados, false)
	alternar_lista_colisores(shapes_abertos, true)

	# 3. Spawna o loot (mesmo se estiver vazio, a caixa abre)
	spawnar_loot()

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
