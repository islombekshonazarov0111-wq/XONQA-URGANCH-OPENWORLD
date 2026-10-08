import json
import math
from pathlib import Path
from collections import defaultdict

SRC = Path("data/map/raw/xonqa_urganch.osm.json")
OUT = Path("data/map/generated")
OUT.mkdir(parents=True, exist_ok=True)

CHUNK_SIZE = 500.0

data = json.loads(SRC.read_text())
elements = data["elements"]

nodes = {}
ways = []

for e in elements:
    if e["type"] == "node":
        nodes[e["id"]] = (e.get("lat"), e.get("lon"))
    elif e["type"] == "way":
        ways.append(e)

lats = [v[0] for v in nodes.values() if v[0] is not None]
lons = [v[1] for v in nodes.values() if v[1] is not None]

lat0 = sum(lats) / len(lats)
lon0 = sum(lons) / len(lons)

def project(lat, lon):
    x = (
        math.radians(lon - lon0)
        * 6378137.0
        * math.cos(math.radians(lat0))
    )
    z = -math.radians(lat - lat0) * 6378137.0
    return [round(x, 2), round(z, 2)]

chunks = defaultdict(lambda: {
    "roads": [],
    "buildings": [],
    "waterways": []
})

for way in ways:
    tags = way.get("tags", {})
    points = []

    for nid in way.get("nodes", []):
        if nid not in nodes:
            continue

        lat, lon = nodes[nid]

        if lat is None or lon is None:
            continue

        points.append(project(lat, lon))

    if len(points) < 2:
        continue

    cx = int(math.floor(points[0][0] / CHUNK_SIZE))
    cz = int(math.floor(points[0][1] / CHUNK_SIZE))
    chunk = chunks[(cx, cz)]

    obj = {
        "osm_id": way["id"],
        "points": points,
        "tags": tags
    }

    if "highway" in tags:
        chunk["roads"].append(obj)
    elif "building" in tags:
        chunk["buildings"].append(obj)
    elif "waterway" in tags or tags.get("natural") == "water":
        chunk["waterways"].append(obj)

manifest = {
    "origin_lat": lat0,
    "origin_lon": lon0,
    "chunk_size_m": CHUNK_SIZE,
    "chunks": []
}

for (cx, cz), chunk in chunks.items():
    name = f"chunk_{cx}_{cz}.json"

    (OUT / name).write_text(
        json.dumps(chunk, ensure_ascii=False)
    )

    manifest["chunks"].append({
        "x": cx,
        "z": cz,
        "file": name,
        "roads": len(chunk["roads"]),
        "buildings": len(chunk["buildings"]),
        "waterways": len(chunk["waterways"])
    })

(OUT / "manifest.json").write_text(
    json.dumps(manifest, indent=2, ensure_ascii=False)
)

print("TAYYOR")
print("Chunklar:", len(chunks))
print("Origin:", lat0, lon0)
print("Manifest:", OUT / "manifest.json")
