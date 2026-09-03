extends Node3D
class_name InfiniteTerrainGenerator

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
@export var rng_seed: int = -1

@export var player: PlayerScript

@export var biomes: FastNoiseLite
# should be @export var but idk
const enable_mountains: bool = false

@export var enable_forest: bool = true

@export var trees_for_forest: Array[String] = []

@export_range(2, 1000) var trees_count_per_chunk: int = 2

var used_chunks: Dictionary[Vector2i, NodePath] = {}

var player_global_pos: Vector2i = Vector2i.ZERO:
	set(val):
		if player_global_pos != val:
			player_global_pos = val
			regenerate_chunks()
		else:
			player_global_pos = val

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if rng_seed == -1:
		rng_seed = rng.randi()
	biomes.seed = rng_seed
	regenerate_chunks()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	check_chunks()

func check_chunks():
	if player != null:
		player_global_pos = Vector2i(snappedi(player.global_position.x - 32, 64) / 64, snappedi(player.global_position.z - 32, 64) / 64)

func regenerate_chunks():
	for i in range(player_global_pos.x - 2, player_global_pos.x + 3):
		for j in range(player_global_pos.y - 2, player_global_pos.y + 3):
			if i == player_global_pos.x - 2 || i == player_global_pos.x + 2 || \
			   j == player_global_pos.y - 2 || j == player_global_pos.y + 2:
				if used_chunks.has(Vector2i(i, j)):
					unload_chunk(i, j)
			else:
				if used_chunks.has(Vector2i(i, j)):
					continue
				else:
					load_chunk(i, j)

func load_chunk(x: int, y: int):
	var chunk: TerrainChunk = TerrainChunk.new()
	add_child(chunk)
	chunk.global_position = Vector3(x * 64, 0, y * 64)
	chunk.terrain_generator(Vector2i(x, y))
	used_chunks[Vector2i(x, y)] = chunk.get_path()

func unload_chunk(x: int, y: int):
	var chunk: TerrainChunk = get_node(used_chunks[Vector2i(x, y)])
	chunk.queue_free()
	used_chunks.erase(Vector2i(x, y))
