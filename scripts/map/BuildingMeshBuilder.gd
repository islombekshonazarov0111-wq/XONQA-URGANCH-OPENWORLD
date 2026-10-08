extends Node3D
class_name BuildingMeshBuilder

var building_material: StandardMaterial3D

func _ready() -> void:
building_material = StandardMaterial3D.new()
building_material.albedo_color = Color(0.62, 0.60, 0.56)
building_material.roughness = 0.9

func build_building(points: Array, tags: Dictionary) -> MeshInstance3D:
var result := MeshInstance3D.new()

if points.size() < 3:
return result

var height := _get_height(tags)
var polygon := PackedVector2Array()

for p in points:
polygon.append(Vector2(float(p[0]), float(p[1])))

if polygon.size() > 1 and polygon[0].distance_to(polygon[-1]) < 0.1:
polygon.remove_at(polygon.size() - 1)

if polygon.size() < 3:
return result

var indices := Geometry2D.triangulate_polygon(polygon)

if indices.is_empty():
return result

var st := SurfaceTool.new()
st.begin(Mesh.PRIMITIVE_TRIANGLES)

# Tom
for i in range(0, indices.size(), 3):
for j in range(3):
var p := polygon[indices[i + j]]
st.set_normal(Vector3.UP)
st.add_vertex(Vector3(p.x, height, p.y))

# Devorlar
for i in range(polygon.size()):
var j := (i + 1) % polygon.size()

var a := Vector3(polygon[i].x, 0.0, polygon[i].y)
var b := Vector3(polygon[j].x, 0.0, polygon[j].y)
var c := Vector3(polygon[j].x, height, polygon[j].y)
var d := Vector3(polygon[i].x, height, polygon[i].y)

var normal := (b - a).cross(d - a).normalized()

st.set_normal(normal)
st.add_vertex(a)
st.set_normal(normal)
st.add_vertex(b)
st.set_normal(normal)
st.add_vertex(c)

st.set_normal(normal)
st.add_vertex(a)
st.set_normal(normal)
st.add_vertex(c)
st.set_normal(normal)
st.add_vertex(d)

var mesh := st.commit()
result.mesh = mesh
result.material_override = building_material

if mesh != null:
result.create_trimesh_collision()

return result

func _get_height(tags: Dictionary) -> float:
if tags.has("height"):
var raw := str(tags["height"]).replace(" m", "")
if raw.is_valid_float():
return clamp(float(raw), 2.5, 80.0)

if tags.has("building:levels"):
var levels := str(tags["building:levels"])
if levels.is_valid_float():
return clamp(float(levels) * 3.0, 3.0, 80.0)

match str(tags.get("building", "")):
"garage":
return 3.0
"garages":
return 3.0
"industrial":
return 7.0
"commercial":
return 8.0
"apartments":
return 12.0
_:
return 5.5
