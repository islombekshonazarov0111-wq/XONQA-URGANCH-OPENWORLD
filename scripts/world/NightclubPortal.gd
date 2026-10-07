extends Area3D
@export_file("*.tscn") var interior_scene := "res://scenes/interiors/nightclub/Nightclub.tscn"

func enter_club():
    GameState.nightclub_loaded = true
    get_tree().change_scene_to_file(interior_scene)
