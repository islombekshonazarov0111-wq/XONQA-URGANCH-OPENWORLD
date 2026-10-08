class_name ManualTransmission
extends RefCounted

var current_gear: int = 0
var clutch_pedal: float = 1.0
var max_forward_gears: int = 5
var reverse_ratio: float = 3.5
var shift_cooldown: float = 0.0
var shift_delay: float = 0.16

func configure(config: Dictionary, gear_count: int) -> void:
    max_forward_gears = max(1, gear_count)
    reverse_ratio = float(config.get("reverse_ratio", reverse_ratio))
    shift_delay = float(config.get("shift_delay_s", shift_delay))

func update(delta: float) -> void:
    shift_cooldown = max(0.0, shift_cooldown - delta)

func set_clutch(value: float) -> void:
    clutch_pedal = clamp(value, 0.0, 1.0)

func set_gear(gear: int) -> bool:
    if shift_cooldown > 0.0 or clutch_pedal < 0.65:
        return false
    if gear < -1 or gear > max_forward_gears:
        return false
    current_gear = gear
    shift_cooldown = shift_delay
    return true

func shift_up() -> bool:
    if current_gear < 0:
        return set_gear(0)
    return set_gear(min(max_forward_gears, current_gear + 1))

func shift_down() -> bool:
    if current_gear <= 0:
        return false
    return set_gear(current_gear - 1)

func get_powertrain_gear_index() -> int:
    return current_gear - 1 if current_gear > 0 else -1

func get_drive_multiplier() -> float:
    if current_gear < 0:
        return -1.0
    if current_gear > 0:
        return 1.0
    return 0.0

func get_clutch_engagement() -> float:
    return 1.0 - clutch_pedal

func get_display_name() -> String:
    if current_gear < 0:
        return "R"
    if current_gear == 0:
        return "N"
    return str(current_gear)
