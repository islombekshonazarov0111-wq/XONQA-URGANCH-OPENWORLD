import requests
from pathlib import Path

OUT = Path("data/map/raw")
OUT.mkdir(parents=True, exist_ok=True)

bbox = "41.42,60.72,41.62,60.90"

query = f"""
[out:json][timeout:180];
(
  way["highway"]({bbox});
  way["building"]({bbox});
  way["waterway"]({bbox});
  way["natural"="water"]({bbox});
  way["landuse"]({bbox});
  way["railway"]({bbox});
  node["place"]({bbox});
  node["amenity"]({bbox});
);
out body;
>;
out skel qt;
"""

servers = [
    "https://overpass.private.coffee/api/interpreter",
    "https://overpass.nchc.org.tw/api/interpreter",
    "https://overpass-api.de/api/interpreter"
]

for server in servers:
    try:
        print("OSM yuklanmoqda:", server)
        r = requests.get(server, params={"data": query}, headers={"User-Agent": "XonqaUrganchGameMap/1.0"}, timeout=300)
        r.raise_for_status()

        path = OUT / "xonqa_urganch.osm.json"
        path.write_bytes(r.content)

        print("TAYYOR:", path)
        print("Hajmi:", round(len(r.content) / 1024 / 1024, 2), "MB")
        break
    except Exception as e:
        print("XATO:", e)
else:
    raise SystemExit("OSM yuklab bo'lmadi")
