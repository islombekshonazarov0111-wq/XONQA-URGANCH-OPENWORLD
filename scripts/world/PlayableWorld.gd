extends Node3D

const CHUNK_SIZE := 500.0
const LOAD_RADIUS := 1
const MAX_CHUNKS_PER_FRAME := 1
var car: Node3D
var cam: Camera3D
var map_root: Node3D
var loaded: Dictionary = {}
var pending: Array[Vector2i] = []
var center := Vector2i(999999, 999999)
var speed := 0.0
var yaw := 0.0
var ground_mat: StandardMaterial3D
var road_mat: StandardMaterial3D
var wall_mat: StandardMaterial3D
var roof_mat: StandardMaterial3D
var water_mat: StandardMaterial3D
var hud: Label
var gas := false
var reverse := false
var left := false
var right := false

func _ready() -> void:
    cam = $Camera3D
    map_root = Node3D.new()
    map_root.name = "RealOSMMap"
    add_child(map_root)
    ground_mat = _material(Color(0.38, 0.51, 0.30))
    road_mat = _material(Color(0.16, 0.17, 0.19))
    wall_mat = _material(Color(0.74, 0.68, 0.57))
    roof_mat = _material(Color(0.58, 0.32, 0.24))
    water_mat = _material(Color(0.12, 0.39, 0.65))
    car = Node3D.new()
    car.name = "DrivablePlaceholderCar"
    add_child(car)
    car.position = Vector3(114.44, 0.85, 295.63)
    _create_car()
    _create_forsaj_service()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.55, 0.73, 0.91)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.85, 0.86, 0.9)
    env.ambient_light_energy = 0.9
    $WorldEnvironment.environment = env
    hud = Label.new()
    hud.position = Vector2(18, 60)
    hud.add_theme_font_size_override("font_size", 22)
    $UI.add_child(hud)
    _add_button("GAZ", Vector2(-175, -145), "gas")
    _add_button("ORQA", Vector2(-175, -75), "reverse")
    _add_button("CHAP", Vector2(20, -105), "left", true)
    _add_button("ONG", Vector2(140, -105), "right", true)
    _refresh()

func _material(color: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = 1.0
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    return m

func _add_button(label_text: String, pos: Vector2, action: String, from_left := false) -> void:
    var b := Button.new()
    b.text = label_text
    b.custom_minimum_size = Vector2(110, 65)
    b.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT if not from_left else Control.PRESET_BOTTOM_LEFT)
    b.position = pos
    b.add_theme_font_size_override("font_size", 22)
    $UI.add_child(b)
    b.button_down.connect(func(): set(action, true))
    b.button_up.connect(func(): set(action, false))

func _create_car() -> void:
    _box(car, Vector3(1.8, 0.55, 4.1), Vector3(0, 0, 0), _material(Color(0.76, 0.08, 0.09)))
    _box(car, Vector3(1.5, 0.65, 2.05), Vector3(0, 0.55, 0.0), _material(Color(0.12, 0.22, 0.29)))
    var tire_mat := _material(Color(0.08, 0.08, 0.09))
    for x in [-0.9, 0.9]:
        for z in [-1.3, 1.3]:
            _box(car, Vector3(0.3, 0.55, 0.65), Vector3(x, -0.25, z), tire_mat)

func _box(parent: Node3D, size: Vector3, at: Vector3, mat: Material) -> void:
    var m := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    m.mesh = mesh
    m.position = at
    m.material_override = mat
    m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(m)

func _process(delta: float) -> void:
    var throttle := float(gas or Input.is_action_pressed("ui_up")) - float(reverse or Input.is_action_pressed("ui_down"))
    var steer := float(left or Input.is_action_pressed("ui_left")) - float(right or Input.is_action_pressed("ui_right"))
    speed = move_toward(speed, throttle * 24.0, delta * (12.0 if throttle != 0.0 else 8.0))
    yaw += steer * delta * clampf(absf(speed) / 8.0, 0.0, 1.0) * (1.0 if speed >= 0.0 else -1.0)
    car.rotation.y = yaw
    car.position += Vector3(sin(yaw), 0, -cos(yaw)) * speed * delta
    cam.global_position = cam.global_position.lerp(car.global_position + Vector3(-sin(yaw) * 15.0, 10.0, cos(yaw) * 15.0), minf(1.0, delta * 5.0))
    cam.look_at(car.global_position + Vector3.UP * 1.0, Vector3.UP)
    hud.text = "XONQA - URGANCH | %d km/soat | %d xarita bo'lagi" % [roundi(absf(speed) * 3.6), loaded.size()]
    var c := Vector2i(floori(car.position.x / CHUNK_SIZE), floori(car.position.z / CHUNK_SIZE))
    if c != center:
        center = c
        _refresh()
    if not pending.is_empty():
        for i in range(mini(MAX_CHUNKS_PER_FRAME, pending.size())):
            _load_chunk(pending.pop_front())

func _refresh() -> void:
    var c := Vector2i(floori(car.position.x / CHUNK_SIZE), floori(car.position.z / CHUNK_SIZE))
    center = c
    var wanted := {}
    for x in range(c.x - LOAD_RADIUS, c.x + LOAD_RADIUS + 1):
        for z in range(c.y - LOAD_RADIUS, c.y + LOAD_RADIUS + 1):
            var k := Vector2i(x, z)
            wanted[k] = true
            if not loaded.has(k) and not pending.has(k):
                pending.append(k)
    for k in loaded.keys():
        if not wanted.has(k):
            loaded[k].queue_free()
            loaded.erase(k)
    for k in pending.duplicate():
        if not wanted.has(k):
            pending.erase(k)

func _load_chunk(k: Vector2i) -> void:
    var root := Node3D.new()
    root.name = "Chunk_%d_%d" % [k.x, k.y]
    map_root.add_child(root)
    loaded[k] = root
    var ground := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(CHUNK_SIZE, CHUNK_SIZE)
    ground.mesh = plane
    ground.position = Vector3((k.x + 0.5) * CHUNK_SIZE, -0.1, (k.y + 0.5) * CHUNK_SIZE)
    ground.material_override = ground_mat
    root.add_child(ground)
    var path := "res://data/map/generated/chunk_%d_%d.json" % [k.x, k.y]
    if not FileAccess.file_exists(path):
        return
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return
    var data = JSON.parse_string(file.get_as_text())
    if not data is Dictionary:
        return
    for road in data.get("roads", []):
        _strip(root, road.get("points", []), 6.0, 0.04, road_mat)
    for water in data.get("waterways", []):
        _strip(root, water.get("points", []), 10.0, 0.02, water_mat)
    for building in data.get("buildings", []):
        _building(root, building.get("points", []), building.get("tags", {}))

func _strip(parent: Node3D, points: Array, width: float, height: float, mat: Material) -> void:
    if points.size() < 2:
        return
    var verts := PackedVector3Array()
    for i in range(points.size() - 1):
        var a := Vector3(float(points[i][0]), height, float(points[i][1]))
        var b := Vector3(float(points[i + 1][0]), height, float(points[i + 1][1]))
        var direction := b - a
        if direction.length_squared() < 0.01:
            continue
        var side := Vector3(-direction.z, 0, direction.x).normalized() * width * 0.5
        verts.append_array(PackedVector3Array([a - side, a + side, b + side, a - side, b + side, b - side]))
    _triangles(parent, verts, mat)

func _building(parent: Node3D, points: Array, tags: Dictionary) -> void:
    if points.size() < 3:
        return
    var height := 6.0
    var levels := str(tags.get("building:levels", ""))
    if levels.is_valid_float():
        height = clampf(float(levels) * 3.0, 3.0, 50.0)
    var verts := PackedVector3Array()
    for i in range(points.size() - 1):
        var a := Vector3(float(points[i][0]), 0, float(points[i][1]))
        var b := Vector3(float(points[i + 1][0]), 0, float(points[i + 1][1]))
        verts.append_array(PackedVector3Array([a, a + Vector3.UP * height, b + Vector3.UP * height, a, b + Vector3.UP * height, b]))
    _triangles(parent, verts, wall_mat)
    var poly := PackedVector2Array()
    for p in points:
        poly.append(Vector2(float(p[0]), float(p[1])))
    if poly.size() > 3 and poly[0].distance_to(poly[poly.size() - 1]) < 0.1:
        poly.remove_at(poly.size() - 1)
    var indices := Geometry2D.triangulate_polygon(poly)
    var roof := PackedVector3Array()
    for idx in indices:
        roof.append(Vector3(poly[idx].x, height, poly[idx].y))
    _triangles(parent, roof, roof_mat)

func _triangles(parent: Node3D, verts: PackedVector3Array, mat: Material) -> void:
    if verts.size() < 3:
        return
    var arrays := []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = verts
    var mesh := ArrayMesh.new()
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    var inst := MeshInstance3D.new()
    inst.mesh = mesh
    inst.material_override = mat
    inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    parent.add_child(inst)


func _create_forsaj_service() -> void:
    var service := Node3D.new()
    service.name = "AVTO_SERVICE_CENTRE_FORSAJ"
    service.position = Vector3(114.44, 0.0, 315.0)
    add_child(service)

    var concrete := _material(Color(0.48, 0.48, 0.48))
    var walls := _material(Color(0.78, 0.79, 0.81))
    var roof := _material(Color(0.12, 0.18, 0.27))
    var door := _material(Color(0.17, 0.22, 0.28))
    var yellow := _material(Color(0.98, 0.72, 0.08))

    _box(service, Vector3(45, 0.15, 35), Vector3(0, 0, 0), concrete)
    _box(service, Vector3(32, 9, 13), Vector3(0, 4.5, 10), walls)
    _box(service, Vector3(34, 0.8, 15), Vector3(0, 9.3, 10), roof)

    for x in [-10.0, 0.0, 10.0]:
        _box(service, Vector3(7, 6, 0.15), Vector3(x, 3.2, 3.4), door)

    _box(service, Vector3(34, 1.4, 0.3), Vector3(0, 10.6, 2.3), yellow)

    var sign_label := Label3D.new()
    sign_label.text = "AVTO SERVICE CENTRE FORSAJ"
    sign_label.font_size = 72
    sign_label.pixel_size = 0.007
    sign_label.position = Vector3(0, 10.6, 2.05)
    sign_label.modulate = Color.BLACK
    service.add_child(sign_label)

    print("FORSAJ servis maketi yaratildi")
