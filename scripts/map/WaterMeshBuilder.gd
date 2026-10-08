extends Node3D
class_name WaterMeshBuilder

@export var water_y: float = -0.15

var water_material: StandardMaterial3D

func _ready() -> void:
water_material = StandardMaterial3D.new()
water_material.albedo_color = Color(0.08, 0.30, 0.42)
water_material.metallic = 0.05
water_material.roughness = 0.25

func build_waterway(points: Array, tags: Dictionary) -> MeshInstance3D:
var mesh_instance := MeshInstance3D.new()

if points.size() < 2:
return mesh_instance

var st := SurfaceTool.new()
st.begin(Mesh.PRIMITIVE_TRIANGLES)

var width := _water_width(tags)

for i in range(points.size() - 1):
var a := Vector3(
float(points[i][0]),
water_y,
float(points[i][1])
)

var b := Vector3(
float(points[i + 1][0]),
water_y,
float(points[i + 1][1])
)

var direction := b - a

if direction.length_squared() < 0.01:
continue

direction = direction.normalized()

var side := Vector3(
-direction.z,
0.0,
direction.x
) * width * 0.5

var v0 := a - side
var v1 := a + side
var v2 := b + side
var v3 := b - side

st.set_normal(Vector3.UP)
st.add_vertex(v0)
st.set_normal(Vector3.UP)
st.add_vertex(v1)
st.set_normal(Vector3.UP)
st.add_vertex(v2)

st.set_normal(Vector3.UP)
st.add_vertex(v0)
st.set_normal(Vector3.UP)
st.add_vertex(v2)
st.set_normal(Vector3.UP)
st.add_vertex(v3)

var mesh := st.commit()
mesh_instance.mesh = mesh
mesh_instance.material_override = water_material

return mesh_instance

func _water_width(tags: Dictionary) -> float:
if tags.has("width"):
var raw := str(tags["width"]).replace(" m", "")
if raw.is_valid_float():
return clamp(float(raw), 1.0, 80.0)

match str(tags.get("waterway", "")):
"river":
return 24.0
"canal":
return 12.0
"stream":
return 4.0
"ditch":
return 2.0
"drain":
return 2.5
_:
return 6.0
