extends Node
var vehicles := {}

func _ready() -> void:
    var dir := DirAccess.open("res://data/vehicles")
    if dir == null: return
    dir.list_dir_begin()
    var f := dir.get_next()
    while f != "":
        if f.ends_with(".json"):
            var file := FileAccess.open("res://data/vehicles/" + f, FileAccess.READ)
            var data = JSON.parse_string(file.get_as_text())
            if typeof(data) == TYPE_DICTIONARY:
                vehicles[data.get("id", f)] = data
        f = dir.get_next()
