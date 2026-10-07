extends Node
var fps_cap := 60
var resolution_scale := 1.0
var traffic_density := 0.65
var render_distance_chunks := 2
var graphics_preset := "medium"

func apply() -> void:
    Engine.max_fps = fps_cap
    # Project rule: real-time shadows are intentionally disabled.
