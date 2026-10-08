extends Node3D
class_name RoadMeshBuilder

@export var road_y: float = 0.05

var road_material: StandardMaterial3D

func _ready() -> void:
road_material = StandardMaterial3D.new()
road_material.albedo_color = Color(0.12, 0.12, 0.12)
road_material.roughness = 0.92

func build_road(points: Array, tags: Dictionary) -> MeshInstance3D:
var mesh_instance := MeshInstance3D.new()
var st := SurfaceTool.new()

st.begin(Mesh.PRIMITIVE_TRIANGLES)

var width := _road_width(tags)

for i in range(points.size() - 1):
var a := Vector3(
float(points[i][0]),
road_y,
float(points[i][1])
)

var b := Vector3(
float(points[i + 1][0]),
road_y,
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
mesh_instance.material_override = road_material

if mesh != null:
mesh_instance.create_trimesh_collision()

return mesh_instance

func _road_width(tags: Dictionary) -> float:
var highway := str(tags.get("highway", ""))

match highway:
"motorway":
return 14.0
"trunk":
return 12.0
"primary":
return 10.0
"secondary":
return 9.0
"tertiary":
return 8.0
"residential":
return 6.5
"service":
return 4.5
"living_street":
return 5.0
"track":
return 3.5
_:
return 5.5
