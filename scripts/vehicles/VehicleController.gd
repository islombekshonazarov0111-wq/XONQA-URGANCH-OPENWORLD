extends VehicleBody3D
@export var vehicle_id := "equinox_20t"
var data := {}
var gear_mode := "P" # P R N D
var current_gear := 1
var rpm := 800.0
var throttle := 0.0
var brake_input := 0.0

func _ready():
    data = VehicleDatabase.vehicles.get(vehicle_id, {})
    mass = float(data.get("mass_kg", 1500.0))

func set_selector(mode:String):
    if mode in ["P","R","N","D"]:
        gear_mode = mode

func _physics_process(_delta):
    if gear_mode == "P":
        brake = 40.0
        engine_force = 0.0
        return
    if gear_mode == "N":
        brake = brake_input * 35.0
        engine_force = 0.0
        return
    var direction := -1.0 if gear_mode == "R" else 1.0
    var torque_nm := float(data.get("torque_nm", 200.0))
    engine_force = throttle * torque_nm * 4.2 * direction
    brake = brake_input * 35.0
    # Production version will replace this foundation with sampled torque curves,
    # real gear ratios, wheel radius, final drive and drivetrain losses.
