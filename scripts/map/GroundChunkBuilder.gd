extends Node3D
class_name GroundChunkBuilder

@export var chunk_size: float = 500.0
@export_range(4, 64) var resolution: int = 32

var terrain := TerrainHeight.new()
var ground_material: StandardMaterial3D

func _ready() -> void:
ground_material = StandardMaterial3D.new()
ground_material.albedo_color = Color(0.36, 0.39, 0.24)
ground_material.roughness = 1.0

if terrain.load_data():
var manifest_path := "res://data/map/generated/manifest.json"
if FileAccess.file_exists(manifest_path):
var file := FileAccess.open(manifest_path, FileAccess.READ)
if file:
var manifest = JSON.parse_string(file.get_as_text())
if manifest is Dictionary:
var origin = {
"lat": manifest.get("origin_lat", 41.512505157447514),
"lon": manifest.get("origin_lon", 60.77412308585105)
}
if origin is Dictionary:
terrain.set_origin(
float(origin.get("lat", 41.512505)),
float(origin.get("lon", 60.774123))
)
print("REAL TERRAIN DATA LOADED")
else:
push_warning("Elevation ma'lumotlari topilmadi")

func build_ground(key: Vector2i) -> MeshInstance3D:
var ground := MeshInstance3D.new()
ground.name = "Terrain_%d_%d" % [key.x, key.y]

var st := SurfaceTool.new()
st.begin(Mesh.PRIMITIVE_TRIANGLES)

var step := chunk_size / float(resolution)
var start_x := float(key.x) * chunk_size
var start_z := float(key.y) * chunk_size

for z in range(resolution):
for x in range(resolution):
var x0 := start_x + x * step
var x1 := x0 + step
var z0 := start_z + z * step
var z1 := z0 + step

var a := Vector3(x0, terrain.get_height(x0, z0), z0)
var b := Vector3(x1, terrain.get_height(x1, z0), z0)
var c := Vector3(x1, terrain.get_height(x1, z1), z1)
var d := Vector3(x0, terrain.get_height(x0, z1), z1)

st.add_vertex(a)
st.add_vertex(d)
st.add_vertex(c)

st.add_vertex(a)
st.add_vertex(c)
st.add_vertex(b)

st.generate_normals()

var mesh := st.commit()
ground.mesh = mesh
ground.material_override = ground_material
ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

if mesh:
ground.create_trimesh_collision()

return ground
