class_name Powertrain
extends RefCounted

var idle_rpm: float = 750.0
var redline_rpm: float = 6500.0
var rpm: float = 750.0
var peak_torque_nm: float = 250.0
var drivetrain_efficiency: float = 0.88
var final_drive: float = 3.5
var wheel_radius_m: float = 0.33
var gear_ratios: Array[float] = [4.5, 2.8, 1.9, 1.4, 1.0, 0.8]
var torque_curve: Array = []

func configure(config: Dictionary) -> void:
    idle_rpm = float(config.get("idle_rpm", idle_rpm))
    redline_rpm = float(config.get("redline_rpm", redline_rpm))
    peak_torque_nm = float(config.get("torque_nm", peak_torque_nm))
    drivetrain_efficiency = float(config.get("drivetrain_efficiency", drivetrain_efficiency))
    final_drive = float(config.get("final_drive", final_drive))
    wheel_radius_m = float(config.get("wheel_radius_m", wheel_radius_m))
    var raw_ratios: Array = config.get("gear_ratios", [])
    if not raw_ratios.is_empty():
        gear_ratios.clear()
        for ratio in raw_ratios:
            gear_ratios.append(float(ratio))
    torque_curve = config.get("torque_curve", [])
    rpm = idle_rpm

func torque_at_rpm(engine_rpm: float) -> float:
    if torque_curve.size() >= 2:
        var target := clamp(engine_rpm, idle_rpm, redline_rpm)
        for i in range(torque_curve.size() - 1):
            var a: Array = torque_curve[i]
            var b: Array = torque_curve[i + 1]
            if target >= float(a[0]) and target <= float(b[0]):
                var span := max(1.0, float(b[0]) - float(a[0]))
                var t := (target - float(a[0])) / span
                return lerp(float(a[1]), float(b[1]), t)
        return float(torque_curve[torque_curve.size() - 1][1])
    var normalized := clamp((engine_rpm - idle_rpm) / max(1.0, redline_rpm - idle_rpm), 0.0, 1.0)
    var shape := max(0.45, 1.0 - pow(normalized - 0.55, 2.0) * 1.25)
    return shape * peak_torque_nm

func calculate_wheel_force(throttle: float, gear_index: int, ratio_override: float = 0.0) -> float:
    var ratio := ratio_override
    if ratio <= 0.0:
        if gear_index < 0 or gear_index >= gear_ratios.size():
            return 0.0
        ratio = gear_ratios[gear_index]
    var engine_torque := torque_at_rpm(rpm) * clamp(throttle, 0.0, 1.0)
    var wheel_torque := engine_torque * ratio * final_drive * drivetrain_efficiency
    return wheel_torque / max(0.05, wheel_radius_m)

func rpm_from_speed(speed_ms: float, gear_index: int, ratio_override: float = 0.0) -> float:
    var ratio := ratio_override
    if ratio <= 0.0:
        if gear_index < 0 or gear_index >= gear_ratios.size():
            return idle_rpm
        ratio = gear_ratios[gear_index]
    var wheel_rps := abs(speed_ms) / (TAU * max(0.05, wheel_radius_m))
    return clamp(wheel_rps * 60.0 * ratio * final_drive, idle_rpm, redline_rpm)

func update_rpm(speed_ms: float, gear_index: int, throttle: float, delta: float, clutch_engagement: float = 1.0, ratio_override: float = 0.0) -> float:
    var coupled_rpm := rpm_from_speed(speed_ms, gear_index, ratio_override)
    var free_rev := lerp(idle_rpm, redline_rpm * 0.94, clamp(throttle, 0.0, 1.0))
    var target := lerp(free_rev, coupled_rpm, clamp(clutch_engagement, 0.0, 1.0))
    rpm = move_toward(rpm, target, 5200.0 * delta)
    return rpm
