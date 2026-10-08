extends Node3D
class_name VehicleModelLoader

@export var vehicle_id: String = "cobalt"
@export var model_root: Node3D

var loaded_model: Node3D

func _ready() -> void:
load_vehicle_model()

func load_vehicle_model() -> void:
if loaded_model:
loaded_model.queue_free()
loaded_model = null

var path := "res://assets/vehicles/%s/%s.glb" % [vehicle_id, vehicle_id]

if ResourceLoader.exists(path):
var scene = load(path)
if scene is PackedScene:
loaded_model = scene.instantiate()
add_child(loaded_model)
print("3D vehicle loaded: ", vehicle_id)
else:
print("3D model kutilmoqda: ", path)

func change_vehicle(new_vehicle_id: String) -> void:
vehicle_id = new_vehicle_id
load_vehicle_model()
