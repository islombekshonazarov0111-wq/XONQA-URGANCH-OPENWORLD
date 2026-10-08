extends Node3D
class_name MapChunkStreamer

@export var player: Node3D
@export var load_radius: int = 2
@export var chunk_size: float = 500.0

var loaded_chunks: Dictionary = {}
var road_builder: RoadMeshBuilder
var building_builder: BuildingMeshBuilder
var water_builder: WaterMeshBuilder
var ground_builder: GroundChunkBuilder
var last_chunk := Vector2i(999999, 999999)

func _ready() -> void:
road_builder = RoadMeshBuilder.new()
add_child(road_builder)

building_builder = BuildingMeshBuilder.new()
add_child(building_builder)

water_builder = WaterMeshBuilder.new()
add_child(water_builder)

ground_builder = GroundChunkBuilder.new()
ground_builder.chunk_size = chunk_size
add_child(ground_builder)

if player:
_update_streaming()

func _process(_delta: float) -> void:
if player == null:
return

var current := _world_to_chunk(player.global_position)

if current != last_chunk:
last_chunk = current
_update_streaming()

func _world_to_chunk(pos: Vector3) -> Vector2i:
return Vector2i(
floori(pos.x / chunk_size),
floori(pos.z / chunk_size)
)

func _update_streaming() -> void:
if player == null:
return

var center := _world_to_chunk(player.global_position)
var wanted: Dictionary = {}

for x in range(center.x - load_radius, center.x + load_radius + 1):
for z in range(center.y - load_radius, center.y + load_radius + 1):
var key := Vector2i(x, z)
wanted[key] = true

if not loaded_chunks.has(key):
_load_chunk(key)

var remove_list: Array[Vector2i] = []

for key in loaded_chunks.keys():
if not wanted.has(key):
remove_list.append(key)

for key in remove_list:
_unload_chunk(key)

func _load_chunk(key: Vector2i) -> void:
var path := "res://data/map/generated/chunk_%d_%d.json" % [
key.x,
key.y
]

if not FileAccess.file_exists(path):
return

var file := FileAccess.open(path, FileAccess.READ)

if file == null:
return

var parsed = JSON.parse_string(file.get_as_text())

if typeof(parsed) != TYPE_DICTIONARY:
return

var root := Node3D.new()
root.name = "MapChunk_%d_%d" % [key.x, key.y]
add_child(root)

var ground := ground_builder.build_ground(key)
root.add_child(ground)

# Chunkdagi obyektlar uchun umumiy balandlik manbasi
var terrain_height := ground_builder.terrain

for road in parsed.get("roads", []):
var mesh := road_builder.build_road(
road.get("points", []),
road.get("tags", {})
)

# Yo'l meshini relyefga moslashtirish
if mesh.mesh != null:
var arrays := mesh.mesh.surface_get_arrays(0)
var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]

for i in range(vertices.size()):
var v := vertices[i]
v.y += terrain_height.get_height(v.x, v.z)
vertices[i] = v

arrays[Mesh.ARRAY_VERTEX] = vertices

var adjusted := ArrayMesh.new()
adjusted.add_surface_from_arrays(
Mesh.PRIMITIVE_TRIANGLES, arrays
)
# Asfalt materialini saqlash
var old_material := mesh.mesh.surface_get_material(0)
if old_material != null:
adjusted.surface_set_material(0, old_material)

mesh.mesh = adjusted
mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

# Eski collision shaklini olib tashlash
for child in mesh.get_children():
if child is StaticBody3D:
child.queue_free()

# Yangi relyefga mos collision
mesh.create_trimesh_collision()

root.add_child(mesh)

for building in parsed.get("buildings", []):
var building_mesh := building_builder.build_building(
building.get("points", []),
building.get("tags", {})
)

# Binoni yer balandligiga joylashtirish
var building_points: Array = building.get("points", [])
if building_points.size() > 0:
var bx := float(building_points[0][0])
var bz := float(building_points[0][1])
building_mesh.position.y = terrain_height.get_height(bx, bz)

building_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
root.add_child(building_mesh)

for waterway in parsed.get("waterways", []):
var water_mesh := water_builder.build_waterway(
waterway.get("points", []),
waterway.get("tags", {})
)

# Suv meshining har bir nuqtasini relyefga moslash
if water_mesh.mesh != null:
var arrays := water_mesh.mesh.surface_get_arrays(0)
var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]

for i in range(vertices.size()):
var v := vertices[i]
v.y += terrain_height.get_height(v.x, v.z)
vertices[i] = v

arrays[Mesh.ARRAY_VERTEX] = vertices

var adjusted_water := ArrayMesh.new()
adjusted_water.add_surface_from_arrays(
Mesh.PRIMITIVE_TRIANGLES, arrays
)
# Suv materialini saqlash
var water_material := water_mesh.mesh.surface_get_material(0)
if water_material != null:
adjusted_water.surface_set_material(0, water_material)

water_mesh.mesh = adjusted_water

water_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
root.add_child(water_mesh)

loaded_chunks[key] = root

func _unload_chunk(key: Vector2i) -> void:
if not loaded_chunks.has(key):
return

var chunk: Node = loaded_chunks[key]

if is_instance_valid(chunk):
chunk.queue_free()

loaded_chunks.erase(key)

func force_refresh() -> void:
last_chunk = Vector2i(999999, 999999)
_update_streaming()
