class_name AutomaticTransmission
extends RefCounted

enum Selector { P, R, N, D }

var selector: Selector = Selector.P
var current_gear: int = 1
var max_forward_gears: int = 6
var shift_up_rpm: float = 5700.0
var shift_down_rpm: float = 1700.0
var kickdown_throttle: float = 0.82
var shift_delay: float = 0.28
var shift_timer: float = 0.0
var shifting: bool = false

func configure(config: Dictionary, gear_count: int) -> void:
    max_forward_gears = max(1, gear_count)
    shift_up_rpm = float(config.get("shift_up_rpm", shift_up_rpm))
    shift_down_rpm = float(config.get("shift_down_rpm", shift_down_rpm))
    kickdown_throttle = float(config.get("kickdown_throttle", kickdown_throttle))
    shift_delay = float(config.get("shift_delay_s", shift_delay))
    current_gear = 1

func set_selector(new_selector: Selector, speed_kmh: float = 0.0) -> void:
    if shifting or speed_kmh > 4.0 and new_selector in [Selector.P, Selector.R]:
        return
    selector = new_selector
    if selector == Selector.D:
        current_gear = max(1, current_gear)

func update(engine_rpm: float, throttle: float, speed_kmh: float, delta: float) -> void:
    if shift_timer > 0.0:
        shift_timer -= delta
        if shift_timer <= 0.0:
            shifting = false
    if selector != Selector.D or shifting:
        return
    if speed_kmh < 4.0 and current_gear != 1:
        _shift_to(1)
        return
    if throttle >= kickdown_throttle and current_gear > 1 and engine_rpm < shift_up_rpm * 0.72:
        _shift_to(current_gear - 1)
        return
    var up_threshold := lerp(shift_up_rpm * 0.72, shift_up_rpm, throttle)
    var down_threshold := lerp(shift_down_rpm, shift_down_rpm * 1.35, 1.0 - throttle)
    if engine_rpm >= up_threshold and current_gear < max_forward_gears:
        _shift_to(current_gear + 1)
    elif engine_rpm <= down_threshold and current_gear > 1:
        _shift_to(current_gear - 1)

func _shift_to(new_gear: int) -> void:
    var clamped := clampi(new_gear, 1, max_forward_gears)
    if clamped == current_gear:
        return
    current_gear = clamped
    shifting = true
    shift_timer = shift_delay

func get_powertrain_gear_index() -> int:
    return current_gear - 1 if selector == Selector.D else -1

func get_drive_multiplier() -> float:
    if selector == Selector.R:
        return -1.0
    if selector == Selector.D:
        return 1.0
    return 0.0

func get_display_name() -> String:
    return ["P", "R", "N", "D"][int(selector)]

func get_clutch_engagement() -> float:
    return 0.15 if shifting else 1.0
