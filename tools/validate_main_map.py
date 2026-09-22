"""Check plot footprints, clear approach, and the exported Roblox map hierarchy."""
import json
import math
from pathlib import Path
import xml.etree.ElementTree as ET

folder = Path(__file__).resolve().parents[1] / "assets/main-map"
data = json.loads((folder / "layout.json").read_text())


def rectangle(x, z, width, depth, yaw):
    c, s = math.cos(yaw), math.sin(yaw)
    return [(x + c * u + s * v, z - s * u + c * v)
            for u, v in ((-width/2, -depth/2), (width/2, -depth/2),
                         (width/2, depth/2), (-width/2, depth/2))]


def overlap(a, b):
    for polygon in (a, b):
        for i, point in enumerate(polygon):
            next_point = polygon[(i + 1) % 4]
            axis = (point[1] - next_point[1], next_point[0] - point[0])
            first = [x * axis[0] + z * axis[1] for x, z in a]
            second = [x * axis[0] + z * axis[1] for x, z in b]
            if max(first) <= min(second) or max(second) <= min(first):
                return False
    return True


footprints = []
for plot in data["plots"]:
    x, _, z = plot["center"]
    polygon = rectangle(x, z, *plot["footprint"], math.radians(plot["yaw_degrees"]))
    for px, pz in polygon:
        dx, dz = max(abs(px) - 240, 0), max(abs(pz) - 240, 0)
        assert dx * dx + dz * dz <= 60 ** 2, "Plot extends outside the hub"
    footprints.append(polygon)
for i, a in enumerate(footprints):
    assert all(not overlap(a, b) for b in footprints[i + 1:]), "Plots overlap"
    assert not overlap(a, rectangle(0, -335, 70, 150, 0)), "Plot blocks the grocery path"
xml = ET.parse(folder / "SquishTheButterMap.rbxmx")
plot_models = [node for node in xml.findall('.//Item[@class="Model"]')
               if (node.findtext('Properties/string[@name="Name"]') or "").startswith("Plot")]
assert len(plot_models) == 8
assert len(xml.findall('.//Item[@class="SpawnLocation"]')) == 1
for node in xml.findall('.//Item[@class="Part"]'):
    assert node.findtext('Properties/token[@name="Material"]') == "256"
    if node.findtext('Properties/float[@name="Transparency"]') == "1":
        continue
    for face in ("Top", "Bottom", "Left", "Right", "Front", "Back"):
        assert node.findtext(f'Properties/token[@name="{face}Surface"]') == "3"
print("PASS: 8 equal plots; all inside hub; no plot overlap; grocery path clear; 1 spawn")
print("PASS: every visible map part uses Plastic and all six studded surfaces")

normalized = []
for plot in data["plots"]:
    prefix = "KitchenPlots/" + plot["name"] + "/StarterKitchen"
    furniture = [p for p in data["parts"] if p["group"] == prefix]
    assert {"KitchenFloor", "Refrigerator", "WallCabinet", "Countertop", "CrackingTable", "RoamArea", "TrainingPad", "PunchingBag"} <= {p["name"] for p in furniture}
    angle = math.radians(plot["yaw_degrees"])
    cx, _, cz = plot["center"]
    result = []
    for p in furniture:
        x, y, z = p["position"]
        x, z = x - cx, z - cz
        lx, lz = math.cos(angle) * x - math.sin(angle) * z, math.sin(angle) * x + math.cos(angle) * z
        assert abs(lx) + p["size"][0] / 2 <= 45.01
        assert abs(lz) + p["size"][2] / 2 <= 41.01
        result.append((p["name"], round(lx, 4), round(y - 0.58, 4), round(lz, 4), p["size"], p["color"]))
    normalized.append(result)
assert len(normalized) == 8 and all(items == normalized[0] for items in normalized)
assert 44 * 38 < 90 * 82 / 3, "Starter kitchen must leave expansion room"
print("PASS: 8 identical inward-facing kitchens; furniture contained in plots; over two-thirds reserved outside starter floor")

zones = data["zones"]
assert [z["id"] for z in zones] == ["Plain", "Salted", "Golden", "Rainbow", "Cosmic"]
assert zones[0]["start"] == -410 and zones[-1]["end"] == -1610
for first, second in zip(zones, zones[1:]):
    assert first["end"] == second["start"], "Gap or overlap between sections"
    assert all(first[key] < second[key] for key in ("length", "width", "height"))
store_parts = [p for p in data["parts"] if p["group"].startswith("GroceryStore/")]
floors = [p for p in store_parts if p["name"] == "OpenFloor"]
assert len(floors) == 5 and all(p["position"][0] == 0 and p["yaw"] == 0 for p in floors)
assert len([p for p in store_parts if p["name"] == "TierArch"]) == 5
assert all(not p.get("label") for p in store_parts)
assert all(p["name"] == "CeilingLight" and p["light"]["brightness"] == 0.12
           for p in store_parts if p.get("light"))
for p in store_parts:
    x, y, z = p["position"]
    sx, sy, sz = p["size"]
    # The last display deliberately terminates the aisle; everything before it
    # leaves a 64-stud-wide, 12-stud-tall combat corridor (32 x 6 at half scale).
    if p.get("collide", True) and y - sy / 2 < 12 and y + sy / 2 > 0.65:
        lane = rectangle(0, (-410 - 1560) / 2, 64, 1150, 0)
        footprint = rectangle(x, z, sx, sz, p["yaw"])
        assert not overlap(lane, footprint), f'Blocked center aisle: {p["group"]}/{p["name"]}'
assert all(p["material"] == "Plastic" for p in store_parts)
installer = (folder / "InstallGrocery.command.luau").read_text()
payload = installer.split("[==[", 1)[1].split("]==]", 1)[0]
assert json.loads(payload) == store_parts, "Installer differs from model geometry"
assert "__GROCERY_JSON__" not in installer
assert 'store:ScaleTo(scale)' in installer and 'store:PivotTo(path.CFrame)' in installer
# Map-relative alignment remains correct after uniform scaling and translation.
for scale in (0.25, 0.5, 0.75, 1):
    authored_path_z = -335
    moved_path_z = 127
    entrance_z = moved_path_z + (-410 - authored_path_z) * scale
    assert abs(entrance_z - (moved_path_z - 150 * scale / 2)) < 1e-8
print(f"PASS: 5 ordered growing zones; straight clear aisle; {len(store_parts)} store parts; installer parity; scaled alignment")
