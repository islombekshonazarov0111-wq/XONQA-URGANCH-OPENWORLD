extends VehicleBody3D
class_name VehicleController

@export var vehicle_id: String = "equinox_20t"

var data: Dictionary = {}
var powertrain: Powertrain
var automatic_transmission: AutomaticTransmission
var manual_transmission: ManualTransmission
var gearbox_type := "automatic"
var drivetrain := "FWD"
var throttle_input := 0.0
var brake_input := 0.0
var steering_input := 0.0
var handbrake_input := 0.0
var speed_kmh := 0.0
var engine_rpm := 800.0
var reverse_ratio := 3.0
var service_brake_force := 45.0
var parking_brake_force := 80.0
var aero_drag_coefficient := 0.34
var frontal_area_m2 := 2.5
var rolling_resistance := 0.015
var max_steering_low_speed := 0.52
var max_steering_high_speed := 0.16
const AIR_DENSITY := 1.225
const GRAVITY := 9.81

func _ready() -> void:
    data = VehicleDatabase.get_vehicle(vehicle_id)
    if data.is_empty():
        push_error("Vehicle data topilmadi: " + vehicle_id)
        set_physics_process(false)
        return
    mass = float(data.get("mass_kg", 1500.0))
    gearbox_type = str(data.get("gearbox", "automatic")).to_lower()
    drivetrain = str(data.get("drive", "FWD")).to_upper()
    powertrain = Powertrain.new()
    powertrain.configure(data)
    _configure_chassis()
    if gearbox_type == "manual":
        manual_transmission = ManualTransmission.new()
        manual_transmission.configure(data, powertrain.gear_ratios.size())
    else:
        automatic_transmission = AutomaticTransmission.new()
        automatic_transmission.configure(data, powertrain.gear_ratios.size())
        automatic_transmission.set_selector(AutomaticTransmission.Selector.P)
    engine_rpm = powertrain.idle_rpm

func _configure_chassis() -> void:
    reverse_ratio = float(data.get("reverse_ratio", 3.0))
    aero_drag_coefficient = float(data.get("drag_coefficient", 0.34))
    frontal_area_m2 = float(data.get("frontal_area_m2", 2.5))
    rolling_resistance = float(data.get("rolling_resistance", 0.015))
    service_brake_force = float(data.get("service_brake_force", 45.0))
    parking_brake_force = float(data.get("parking_brake_force", 80.0))
    max_steering_low_speed = float(data.get("steering_low_speed_rad", 0.52))
    max_steering_high_speed = float(data.get("steering_high_speed_rad", 0.16))

func _physics_process(delta: float) -> void:
    speed_kmh = linear_velocity.length() * 3.6
    if gearbox_type == "manual":
        manual_transmission.update(delta)
    _update_rpm(delta)
    if automatic_transmission != null:
        automatic_transmission.update(engine_rpm, throttle_input, speed_kmh, delta)
    _update_engine_force()
    _update_brakes()
    _update_steering()

func _update_rpm(delta: float) -> void:
    var gear_index := -1
    var clutch := 0.0
    var ratio_override := 0.0
    if automatic_transmission != null:
        if automatic_transmission.selector == AutomaticTransmission.Selector.R:
            ratio_override = reverse_ratio
            clutch = automatic_transmission.get_clutch_engagement()
        elif automatic_transmission.selector == AutomaticTransmission.Selector.D:
            gear_index = automatic_transmission.get_powertrain_gear_index()
            clutch = automatic_transmission.get_clutch_engagement()
    elif manual_transmission != null:
        clutch = manual_transmission.get_clutch_engagement()
        if manual_transmission.current_gear < 0:
            ratio_override = reverse_ratio
        else:
            gear_index = manual_transmission.get_powertrain_gear_index()
    engine_rpm = powertrain.update_rpm(linear_velocity.length(), gear_index, throttle_input, delta, clutch, ratio_override)

func _update_engine_force() -> void:
    var gear_index := -1
    var direction := 0.0
    var clutch := 0.0
    var ratio_override := 0.0
    if automatic_transmission != null:
        direction = automatic_transmission.get_drive_multiplier()
        clutch = automatic_transmission.get_clutch_engagement()
        if automatic_transmission.selector == AutomaticTransmission.Selector.R:
            ratio_override = reverse_ratio
        elif automatic_transmission.selector == AutomaticTransmission.Selector.D:
            gear_index = automatic_transmission.get_powertrain_gear_index()
    elif manual_transmission != null:
        direction = manual_transmission.get_drive_multiplier()
        clutch = manual_transmission.get_clutch_engagement()
        if manual_transmission.current_gear < 0:
            ratio_override = reverse_ratio
        else:
            gear_index = manual_transmission.get_powertrain_gear_index()
    var drive_force := powertrain.calculate_wheel_force(throttle_input, gear_index, ratio_override) * clutch
    var resistance := _calculate_resistance()
    engine_force = max(0.0, drive_force - resistance) * direction

func _calculate_resistance() -> float:
    var speed_ms := linear_velocity.length()
    var aero := 0.5 * AIR_DENSITY * aero_drag_coefficient * frontal_area_m2 * speed_ms * speed_ms
    var rolling := rolling_resistance * mass * GRAVITY
    return aero + rolling

func _update_brakes() -> void:
    var requested := clamp(brake_input, 0.0, 1.0) * service_brake_force
    if automatic_transmission != null and automatic_transmission.selector == AutomaticTransmission.Selector.P:
        requested = parking_brake_force
    requested = max(requested, clamp(handbrake_input, 0.0, 1.0) * parking_brake_force)
    brake = requested

func _update_steering() -> void:
    var factor := clamp(speed_kmh / 140.0, 0.0, 1.0)
    var limit := lerp(max_steering_low_speed, max_steering_high_speed, factor)
    steering = clamp(steering_input, -1.0, 1.0) * limit

func set_throttle(value: float) -> void:
    throttle_input = clamp(value, 0.0, 1.0)
func set_brake(value: float) -> void:
    brake_input = clamp(value, 0.0, 1.0)
func set_handbrake(value: float) -> void:
    handbrake_input = clamp(value, 0.0, 1.0)
func set_steering(value: float) -> void:
    steering_input = clamp(value, -1.0, 1.0)
func set_clutch(value: float) -> void:
    if manual_transmission != null:
        manual_transmission.set_clutch(value)
func set_manual_gear(gear: int) -> bool:
    return manual_transmission.set_gear(gear) if manual_transmission != null else false
func shift_up() -> bool:
    return manual_transmission.shift_up() if manual_transmission != null else false
func shift_down() -> bool:
    return manual_transmission.shift_down() if manual_transmission != null else false
func set_selector(mode: String) -> void:
    if automatic_transmission == null:
        return
    var next := AutomaticTransmission.Selector.P
    match mode.to_upper():
        "R": next = AutomaticTransmission.Selector.R
        "N": next = AutomaticTransmission.Selector.N
        "D": next = AutomaticTransmission.Selector.D
        _: next = AutomaticTransmission.Selector.P
    automatic_transmission.set_selector(next, speed_kmh)
func get_selector_name() -> String:
    if automatic_transmission != null:
        return automatic_transmission.get_display_name()
    return manual_transmission.get_display_name() if manual_transmission != null else "N"
func get_current_gear() -> int:
    if automatic_transmission != null:
        return automatic_transmission.current_gear
    return manual_transmission.current_gear if manual_transmission != null else 0
func get_rpm() -> float:
    return engine_rpm
func get_speed_kmh() -> float:
    return speed_kmh
func get_drivetrain() -> String:
    return drivetrain
func get_vehicle_name() -> String:
    return str(data.get("name", vehicle_id))
