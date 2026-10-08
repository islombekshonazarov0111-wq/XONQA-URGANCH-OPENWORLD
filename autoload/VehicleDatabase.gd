extends Node

var vehicles: Dictionary = {}
const REQUIRED_KEYS := ["id", "name", "mass_kg", "torque_nm", "drive", "gearbox", "gear_ratios", "final_drive"]

func _ready() -> void:
    reload()

func reload() -> void:
    vehicles.clear()
    var dir := DirAccess.open("res://data/vehicles")
    if dir == null:
        push_error("data/vehicles papkasi topilmadi")
        return
    var names := dir.get_files()
    names.sort()
    for filename in names:
        if not filename.ends_with(".json"):
            continue
        _load_vehicle("res://data/vehicles/" + filename)
    print("VehicleDatabase: %d ta mashina yuklandi" % vehicles.size())

func _load_vehicle(path: String) -> void:
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        push_error("Vehicle JSON ochilmadi: " + path)
        return
    var parsed = JSON.parse_string(file.get_as_text())
    if typeof(parsed) != TYPE_DICTIONARY:
        push_error("Vehicle JSON noto'g'ri: " + path)
        return
    var data: Dictionary = parsed
    for key in REQUIRED_KEYS:
        if not data.has(key):
            push_error("Vehicle JSON kaliti yo'q [%s]: %s" % [key, path])
            return
    var id := str(data["id"])
    if vehicles.has(id):
        push_error("Takroriy vehicle id: " + id)
        return
    vehicles[id] = data

func get_vehicle(id: String) -> Dictionary:
    return vehicles.get(id, {})

func get_ids() -> Array:
    var ids := vehicles.keys()
    ids.sort()
    return ids
