extends Node3D
@export var chunk_size := 500.0
@export var radius := 2
@export var target_path: NodePath
var loaded := {}
var center := Vector2i(999999,999999)

func _process(_delta):
    var target := get_node_or_null(target_path)
    if target == null: return
    var p: Vector3 = target.global_position
    var c := Vector2i(floori(p.x/chunk_size), floori(p.z/chunk_size))
    if c != center:
        center = c
        _refresh()

func _refresh():
    var wanted := {}
    for x in range(center.x-radius, center.x+radius+1):
        for z in range(center.y-radius, center.y+radius+1):
            var k := Vector2i(x,z)
            wanted[k] = true
            if not loaded.has(k):
                _load_chunk(k)
    for k in loaded.keys():
        if not wanted.has(k):
            loaded[k].queue_free()
            loaded.erase(k)

func _load_chunk(k: Vector2i):
    var path := "res://assets/map/chunks/chunk_%d_%d.tscn" % [k.x,k.y]
    if ResourceLoader.exists(path):
        ResourceLoader.load_threaded_request(path)
        var scene = load(path)
        var node = scene.instantiate()
        add_child(node)
        loaded[k] = node
