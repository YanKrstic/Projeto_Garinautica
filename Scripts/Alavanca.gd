extends StaticBody3D

# --- CONFIGURAÇÕES ---
@export_group("Referências")
@export var mesh_cabo: Node3D 

@export_group("Conexões")
@export var spawner_alvo: Node3D

@export_group("Animação")
@export var angulo_desligado: float = 60.0
@export var angulo_ligado: float = -60.0
@export var tempo_ativacao: float = 1.5
@export var tempo_retorno: float = 2.5

# --- CONTROLE VISUAL (NOVO) ---
var material_outline: StandardMaterial3D
var esta_focado: bool = false
var esta_movendo: bool = false

func _ready():
	# 1. Configura a posição inicial
	if mesh_cabo:
		mesh_cabo.rotation_degrees.x = angulo_desligado

	# 2. Cria o Material de Outline (Igual ao do Lixo)
	material_outline = StandardMaterial3D.new()
	material_outline.cull_mode = BaseMaterial3D.CULL_FRONT 
	material_outline.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED 
	material_outline.albedo_color = Color.WHITE 
	material_outline.grow = true 
	material_outline.grow_amount = 0.0 # Começa invisível

# --- FUNÇÕES CHAMADAS PELO PLAYER ---

# O Player chama isso quando olha/para de olhar
func set_focado(estado: bool):
	esta_focado = estado
	atualizar_outline()

# O Player chama isso quando aperta "E"
func interagir_abrir():
	if esta_movendo: return
	acionar()

# --- LÓGICA DO BRILHO ---

func atualizar_outline():
	if esta_focado:
		material_outline.grow_amount = 0.02 # Tamanho da borda
		material_outline.albedo_color = Color.WHITE
	else:
		material_outline.grow_amount = 0.0 # Invisível
	
	# Aplica o efeito em MIM mesmo (self) e em todos os meus filhos (cabo, base)
	aplicar_overlay_no_modelo(self, material_outline if esta_focado else null)

# Função recursiva para achar as malhas 3D e pintar
func aplicar_overlay_no_modelo(no_pai: Node, material: Material):
	if not no_pai: return
	
	# Se achou uma parte visual (Mesh), aplica a borda
	if no_pai is MeshInstance3D:
		no_pai.material_overlay = material
	
	# Continua procurando nos filhos
	for filho in no_pai.get_children():
		aplicar_overlay_no_modelo(filho, material)

# --- LÓGICA DA ALAVANCA (MANTIDA IGUAL) ---

func acionar():
	esta_movendo = true
	var tween = create_tween()
	
	# Ida seca
	tween.tween_property(mesh_cabo, "rotation_degrees:x", angulo_ligado, tempo_ativacao).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	
	tween.tween_callback(funcao_do_spawn)
	tween.tween_interval(0.5)
	
	# Volta suave
	tween.tween_property(mesh_cabo, "rotation_degrees:x", angulo_desligado, tempo_retorno).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	tween.tween_callback(func(): esta_movendo = false)

func funcao_do_spawn():
	print("CLACK! Alavanca ativada.")
	
	# --- NOVO: CHAMA O SPAWNER ---
	if spawner_alvo and spawner_alvo.has_method("spawnar_lote"):
		spawner_alvo.spawnar_lote()
	else:
		print("ERRO: Nenhum spawner conectado na alavanca!")
