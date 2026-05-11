extends MeshInstance3D

# Número de amostras a tirar ao longo da altura da malha (podes ajustar se a fonte for muito alta)
const Y_SAMPLES = 16

func _ready():
	# Quando o jogo começa, vai buscar o material da água e corre a configuração
	var mat = get_surface_override_material(0) as ShaderMaterial
	if mat == null:
		mat = get_active_material(0) as ShaderMaterial
		
	if mat != null:
		setup(self, mat)
	else:
		push_warning("Nenhum ShaderMaterial encontrado na água.")

func setup(mesh_instance: MeshInstance3D, material: ShaderMaterial) -> void:
	var mesh = mesh_instance.mesh
	if mesh == null:
		push_error("MeshInstance3D não tem malha (mesh)")
		return
	
	# Obtém as posições de todos os vértices
	var vertices = []
	var surface_count = mesh.get_surface_count()
	
	for surface_idx in range(surface_count):
		var arrays = mesh.surface_get_arrays(surface_idx)
		var positions = arrays[Mesh.ARRAY_VERTEX]
		
		for pos in positions:
			var world_pos = mesh_instance.global_transform * pos
			vertices.append(world_pos)
	
	if vertices.is_empty():
		return
	
	# Encontra os valores Y (altura) mínimos e máximos
	var min_y = vertices[0].y
	var max_y = vertices[0].y
	for v in vertices:
		min_y = min(min_y, v.y)
		max_y = max(max_y, v.y)
	
	var y_range = max_y - min_y
	if y_range < 0.001:
		return
	
	# Calcula as direções em cada nível Y
	var bias_directions = []
	var y_levels = []
	
	for i in range(Y_SAMPLES):
		var t = float(i) / float(Y_SAMPLES - 1) if Y_SAMPLES > 1 else 0.0
		var y_level = min_y + t * y_range
		y_levels.append(y_level)
		
		var threshold = y_range / float(Y_SAMPLES) * 0.6
		var verts_at_level = []
		
		for v in vertices:
			if abs(v.y - y_level) < threshold:
				verts_at_level.append(v)
		
		if verts_at_level.is_empty():
			bias_directions.append(Vector3.UP)
			continue
		
		var avg_pos = Vector3.ZERO
		for v in verts_at_level:
			avg_pos += v
		avg_pos /= float(verts_at_level.size())
		
		if i == 0:
			bias_directions.append(Vector3.UP)
		else:
			var prev_level = min_y + float(i - 1) / float(Y_SAMPLES - 1) * y_range
			var prev_verts = []
			
			for v in vertices:
				if abs(v.y - prev_level) < threshold:
					prev_verts.append(v)
			
			if prev_verts.is_empty():
				bias_directions.append(Vector3.UP)
				continue
			
			var prev_avg = Vector3.ZERO
			for v in prev_verts:
				prev_avg += v
			prev_avg /= float(prev_verts.size())
			
			var dir = (avg_pos - prev_avg).normalized()
			dir.x = -dir.x
			dir.z = -dir.z
			if dir.length() < 0.001:
				dir = Vector3.UP
			
			bias_directions.append(dir)
	
	# Cria a imagem com os dados e envia para o Shader
	var img = Image.create(Y_SAMPLES, 1, false, Image.FORMAT_RGBF)
	
	for i in range(Y_SAMPLES):
		var dir = bias_directions[i]
		var color_dir = (dir + Vector3.ONE) / 2.0
		img.set_pixel(i, 0, Color(color_dir.x, color_dir.y, color_dir.z))
	
	var texture = ImageTexture.create_from_image(img)
	material.set_shader_parameter("bias_direction_texture", texture)
	material.set_shader_parameter("bias_min_y", min_y)
	material.set_shader_parameter("bias_max_y", max_y)
