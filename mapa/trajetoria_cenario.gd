extends Node3D

@onready var ponto_partida = $PontoPartida
@onready var ponto_final = $PontoFinal

@export_group("Objetos")
@export var objs: Array[PackedScene] = []

@export_group("Configuracoes")
@export var velocidade: float = 4
@export var distancia: int = 10

var objs_em_cena: Array[Node3D] = []


func _ready():
	randomize() 
	$Timer.timeout.connect(spawn_obj)
	$Timer.wait_time = 1 #randi_range(4, 18)
	$Timer.start()

func _process(delta):
	for i in range(objs_em_cena.size() - 1, -1, -1):
		var obj = objs_em_cena[i]

		if not is_instance_valid(obj):
			objs_em_cena.remove_at(i)
			continue

		obj.position.z -= velocidade * delta

		if abs(obj.position.z - ponto_final.position.z) < distancia:
			obj.queue_free()
			objs_em_cena.remove_at(i)

func spawn_obj():
	if objs.is_empty():
		return
	
	var obj_cena = objs.pick_random()
	var obj = obj_cena.instantiate()
	obj.position = ponto_partida.global_position
	obj.rotation.y = randi_range(-360, 360)
	
	get_tree().current_scene.add_child(obj)
	objs_em_cena.append(obj)
	$Timer.wait_time = randi_range(2, 5)
	$Timer.start()
	
	
	
	
	
