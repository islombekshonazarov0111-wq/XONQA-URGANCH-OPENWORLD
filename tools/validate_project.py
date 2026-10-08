#!/usr/bin/env python3
from pathlib import Path
import json, sys
root=Path(__file__).resolve().parents[1]
errors=[]
required={"id","name","mass_kg","torque_nm","drive","gearbox","gear_ratios","final_drive"}
for path in sorted((root/'data/vehicles').glob('*.json')):
    try: d=json.loads(path.read_text())
    except Exception as e:
        errors.append(f"{path.name}: JSON error: {e}"); continue
    missing=required-set(d)
    if missing: errors.append(f"{path.name}: missing {sorted(missing)}")
    if not isinstance(d.get('gear_ratios'),list) or not d.get('gear_ratios'): errors.append(f"{path.name}: gear_ratios empty")
    if d.get('gearbox') not in ('automatic','manual'): errors.append(f"{path.name}: invalid gearbox")
if not (root/'export_presets.cfg').exists(): errors.append('export_presets.cfg missing')
if errors:
    print('\n'.join('ERROR: '+e for e in errors)); sys.exit(1)
print('Validation OK: vehicle JSON + Android export preset')
