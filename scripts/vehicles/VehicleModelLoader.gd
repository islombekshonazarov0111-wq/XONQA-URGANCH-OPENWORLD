extends Node3D
class_name VehicleModelLoader
@export var vehicle_id := "cobalt"
var loaded_model: Node3D
func _ready() -> void:
    load_vehicle_model()
func load_vehicle_model() -> void:
    if is_instance_valid(loaded_model):
        loaded_model.queue_free()
    loaded_model = null
    var path := "res://assets/vehicles/%s/%s.glb" % [vehicle_id, vehicle_id]
    if ResourceLoader.exists(path):
        var resource := load(path)
        if resource is PackedScene:
            loaded_model = resource.instantiate()
            add_child(loaded_model)
func change_vehicle(new_vehicle_id: String) -> void:
    vehicle_id = new_vehicle_id
    load_vehicle_model()
