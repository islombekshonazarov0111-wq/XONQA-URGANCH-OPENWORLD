extends CharacterBody3D
@export var speed := 5.0
var nearby_vehicle: Node = null

func _physics_process(_delta):
    var v := Input.get_vector("ui_left","ui_right","ui_up","ui_down")
    velocity.x = v.x * speed
    velocity.z = v.y * speed
    move_and_slide()

func enter_vehicle(vehicle):
    GameState.current_vehicle = vehicle
    GameState.player_on_foot = false
    visible = false
    set_physics_process(false)

func exit_vehicle(at_position: Vector3):
    global_position = at_position
    visible = true
    set_physics_process(true)
    GameState.current_vehicle = null
    GameState.player_on_foot = true
