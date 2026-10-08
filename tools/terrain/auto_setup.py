import json
import math
import time
import urllib.request
from pathlib import Path

ROOT = Path.cwd()
manifest_path = ROOT / "data/map/generated/manifest.json"
output_dir = ROOT / "data/map/elevation"
output_dir.mkdir(parents=True, exist_ok=True)

if not manifest_path.exists():
    raise SystemExit("XATO: xarita manifesti topilmadi")

manifest = json.loads(manifest_path.read_text())
print("Xarita manifesti topildi")

# OSM xarita hududining boshlang'ich koordinatalari
lat_min, lat_max = 41.42, 41.62
lon_min, lon_max = 60.72, 60.90

# 25x25 balandlik namunalari
rows = 25
cols = 25
points = []

for y in range(rows):
    lat = lat_min + (lat_max - lat_min) * y / (rows - 1)
    for x in range(cols):
        lon = lon_min + (lon_max - lon_min) * x / (cols - 1)
        points.append((lat, lon))

# Open-Meteo Elevation API, kichik guruhlar
cache_file = output_dir / "elevation_progress.json"
if cache_file.exists():
    elevations = json.loads(cache_file.read_text())
else:
    elevations = []
batch_size = 25

for start in range(len(elevations), len(points), batch_size):
    batch = points[start:start + batch_size]
    lats = ",".join(f"{p[0]:.6f}" for p in batch)
    lons = ",".join(f"{p[1]:.6f}" for p in batch)

    url = (
        "https://api.open-meteo.com/v1/elevation?"
        f"latitude={lats}&longitude={lons}"
    )

    for attempt in range(3):
        try:
            req = urllib.request.Request(
                url, headers={"User-Agent": "XonqaUrganchGame/1.0"}
            )
            with urllib.request.urlopen(req, timeout=35) as response:
                data = json.load(response)
            values = data["elevation"]
            if len(values) != len(batch):
                raise ValueError("Balandlik soni mos emas")
            elevations.extend(values)
            cache_file.write_text(json.dumps(elevations))
            print(f"Yuklandi: {len(elevations)}/{len(points)}")
            time.sleep(5)
            break
        except Exception as exc:
            print("Ulanish xatosi:", exc)
            if attempt == 2:
                raise SystemExit("Yuklash to'xtadi, qayta urinib ko'ring")
            time.sleep(30 * (attempt + 1))

result = {
    "bounds": {
        "lat_min": lat_min,
        "lat_max": lat_max,
        "lon_min": lon_min,
        "lon_max": lon_max
    },
    "rows": rows,
    "cols": cols,
    "elevations": elevations,
    "source": "Open-Meteo Elevation API"
}

out = output_dir / "elevation_grid.json"
out.write_text(json.dumps(result, separators=(",", ":")))

print("TAYYOR:", out)
print("Balandlik nuqtalari:", len(elevations))
print("Minimum:", min(elevations), "metr")
print("Maksimum:", max(elevations), "metr")
