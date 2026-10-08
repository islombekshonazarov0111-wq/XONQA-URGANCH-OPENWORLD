extends RefCounted
class_name TerrainHeight

const DATA_PATH := "res://data/map/elevation/elevation_grid.json"

var heights: Array = []
var rows: int = 0
var cols: int = 0
var base_height: float = 0.0
var origin_lat: float = 0.0
var origin_lon: float = 0.0
var lat_min: float = 0.0
var lat_max: float = 0.0
var lon_min: float = 0.0
var lon_max: float = 0.0

func load_data() -> bool:
if not FileAccess.file_exists(DATA_PATH):
return false

var file := FileAccess.open(DATA_PATH, FileAccess.READ)
if file == null:
return false

var data = JSON.parse_string(file.get_as_text())
if typeof(data) != TYPE_DICTIONARY:
return false

rows = int(data.get("rows", 0))
cols = int(data.get("cols", 0))
heights = data.get("elevations", [])

if rows < 2 or cols < 2 or heights.size() != rows * cols:
return false

var bounds: Dictionary = data.get("bounds", {})
lat_min = float(bounds.get("lat_min", 0.0))
lat_max = float(bounds.get("lat_max", 0.0))
lon_min = float(bounds.get("lon_min", 0.0))
lon_max = float(bounds.get("lon_max", 0.0))

if lat_max <= lat_min or lon_max <= lon_min:
return false

base_height = float(heights[0])
return true

func set_origin(lat: float, lon: float) -> void:
origin_lat = lat
origin_lon = lon

func get_height(x: float, z: float) -> float:
if heights.is_empty():
return 0.0

var lat := origin_lat + z / 111320.0
var lon_scale := 111320.0 * cos(deg_to_rad(origin_lat))
var lon := origin_lon + x / lon_scale

var gx := clamp(
(lon - lon_min) / (lon_max - lon_min) * (cols - 1),
0.0, float(cols - 1)
)
var gy := clamp(
(lat - lat_min) / (lat_max - lat_min) * (rows - 1),
0.0, float(rows - 1)
)

var x0 := mini(floori(gx), cols - 2)
var y0 := mini(floori(gy), rows - 2)
var tx := gx - x0
var ty := gy - y0

var h00 := float(heights[y0 * cols + x0])
var h10 := float(heights[y0 * cols + x0 + 1])
var h01 := float(heights[(y0 + 1) * cols + x0])
var h11 := float(heights[(y0 + 1) * cols + x0 + 1])

var h0 := lerpf(h00, h10, tx)
var h1 := lerpf(h01, h11, tx)

return lerpf(h0, h1, ty) - base_height
