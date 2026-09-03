extends Node3D
class_name TerrainChunk

@onready var terrain_manager: InfiniteTerrainGenerator = get_parent()

@export var chunk_size: Vector2i = Vector2i(64, 64)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
#
#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass

## Generates terrain
func terrain_generator(offset: Vector2i):
	var noise_offset: Vector2 = Vector2(offset.x * chunk_size.x, offset.y * chunk_size.y)
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_color(Color(1, 1, 1))
	for z in range(int(chunk_size.y + 1)):
		for x in range(int(chunk_size.x + 1)):
			var height: float = terrain_manager.biomes.get_noise_2d(noise_offset.x + x, noise_offset.y + z)
			height *= biome_height_generator(noise_offset.x + x, noise_offset.y + z, terrain_manager.biomes)
			
			# BEGIN THIRDPARTY CONTENT
			# USED FROM https://github.com/bsubard/Godot-3D-Procedural-Infinite-Terrain
			# MADE BY bsubard
			# Licensed under MIT License
			var uv = Vector2(x / float(chunk_size.x), z / float(chunk_size.y))
			st.set_uv(uv)
			# END THIRDPARTY CONTENT
			
			st.add_vertex(Vector3(x, height, z))
	
	# BEGIN THIRDPARTY CONTENT
	# USED FROM https://github.com/bsubard/Godot-3D-Procedural-Infinite-Terrain
	# MADE BY bsubard
	# Licensed under MIT License
	for z in range(int(chunk_size.y)):
		for x in range(int(chunk_size.x)):
			var i00 = z * (chunk_size.x + 1) + x
			var i10 = i00 + 1
			var i01 = (z + 1) * (chunk_size.x + 1) + x
			var i11 = i01 + 1
			st.add_index(i00); st.add_index(i10); st.add_index(i01)
			st.add_index(i10); st.add_index(i11); st.add_index(i01)
	# END THIRDPARTY CONTENT
	st.generate_normals()
	st.generate_tangents()
	var result_mesh: ArrayMesh = st.commit()
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = result_mesh
	mi.mesh.surface_set_material(0, load("res://Shaders/chunk.tres"))
	mi.create_trimesh_collision()
	add_child(mi)
	
	var water_level: MeshInstance3D = MeshInstance3D.new()
	water_level.mesh = PlaneMesh.new()
	water_level.mesh.size = Vector2(64, 64)
	water_level.mesh.center_offset = Vector3(32, -1, 32)
	water_level.mesh.surface_set_material(0, load("res://Shaders/water.tres"))
	add_child(water_level)
	biome_generator(terrain_manager.biomes, offset)

func biome_height_generator(x: int, y: int, noise_value: FastNoiseLite) -> float:
	if x < 30 && y < 30 && x > 3 && y > 3:
		if noise_value.get_noise_2d(x, y) > 0.85 && terrain_manager.enable_mountains:
			return 32.0
		elif noise_value.get_noise_2d(x, y) < -0.01:
			return 32.0
		elif noise_value.get_noise_2d(x, y) > 0.625 || noise_value.get_noise_2d(x, y) < 0.375:
			return 2.0
		else:
			return 1.0
	else:
		return 1.0

func biome_generator(noise_value: FastNoiseLite, offset: Vector2i):
	for i in range(terrain_manager.trees_for_forest.size()):
		# Create the multimesh.
		var multimesh: MultiMesh = MultiMesh.new()
		# Set the format first.
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		# Set the mesh that will be duplicated.
		multimesh.mesh = load(terrain_manager.trees_for_forest[i])
		# Then resize (otherwise, changing the format is not allowed).
		multimesh.instance_count = terrain_manager.trees_count_per_chunk
		# Maybe not all of them should be visible at first.
		multimesh.visible_instance_count = terrain_manager.trees_count_per_chunk
		
		# Set the transform of the instances.
		for j in multimesh.visible_instance_count:
			var failed: bool = false
			var random_coords: Vector2 = Vector2(terrain_manager.rng.randf_range(offset.x, offset.x + chunk_size.x), terrain_manager.rng.randf_range(offset.y, offset.y + chunk_size.y))
			for k in range(128):
				if noise_value.get_noise_2dv(random_coords) > 0.375 || noise_value.get_noise_2dv(random_coords) < 0.675:
					break
				elif k < 127:
					random_coords = Vector2(terrain_manager.rng.randf_range(offset.x, offset.x + chunk_size.x), terrain_manager.rng.randf_range(offset.y, offset.y + chunk_size.y))
				else:
					failed = true
					break
			if failed:
				break
			
			var height: float = noise_value.get_noise_2dv(random_coords)
			if height < -0.01: 
				break
			
			# Fix floating tree bug
			var random_position: Vector3 = Vector3(random_coords.x, height - 1, random_coords.y)
			multimesh.set_instance_transform(j, Transform3D(Basis(), random_position))
		var mmi: MultiMeshInstance3D = MultiMeshInstance3D.new()
		mmi.multimesh = multimesh
		add_child(mmi)
	
