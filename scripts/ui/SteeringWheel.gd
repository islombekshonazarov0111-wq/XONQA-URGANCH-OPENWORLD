extends Control
@export var max_visual_degrees := 540.0
var steering := 0.0
var dragging := false

func _gui_input(event):
    if event is InputEventScreenTouch:
        dragging = event.pressed
        if not dragging: steering = 0.0
    elif event is InputEventScreenDrag and dragging:
        var c := size * 0.5
        var a := (event.position-c).angle()
        steering = clamp(a / PI, -1.0, 1.0)
        rotation = deg_to_rad(steering * max_visual_degrees * 0.5)

func _process(delta):
    if not dragging:
        steering = move_toward(steering, 0.0, delta*3.5)
        rotation = lerp_angle(rotation, 0.0, min(1.0,delta*7.0))
