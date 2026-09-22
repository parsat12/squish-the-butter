"""Build a Roblox XML map and render the same geometry in Blender."""
import json
import math
import sys
from pathlib import Path
import xml.etree.ElementTree as ET

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
from grocery_structure import build_grocery
from kitchen_structure import kitchen_parts

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/main-map"
OUT.mkdir(parents=True, exist_ok=True)
parts, plots = [], []
GREEN = (83, 196, 65)
GRASS_EDGE = (44, 139, 73)
PATH = (233, 239, 227)
WHITE = (245, 251, 251)
TEAL = (38, 167, 170)
COLORS = [(255, 141, 153), (255, 192, 86), (121, 211, 230), (178, 158, 235),
          (250, 153, 95), (129, 210, 158), (118, 173, 244), (240, 155, 210)]


def part(name, group, position, size, color, yaw=0, shape="Block", material="Plastic", **extra):
    data = dict(name=name, group=group, position=position, size=size, color=color,
                yaw=yaw, shape=shape, material=material, **extra)
    parts.append(data)
    return data


def rounded_ground(group, size, radius, top, thickness, color, material):
    extent = size / 2 - radius
    part("CenterA", group, (0, top - thickness / 2, 0), (size, thickness, size - radius * 2), color, material=material)
    part("CenterB", group, (0, top - thickness / 2, 0), (size - radius * 2, thickness, size), color, material=material)
    for x in (-extent, extent):
        for z in (-extent, extent):
            part("RoundedCorner", group, (x, top - thickness / 2, z), (radius * 2, thickness, radius * 2), color,
                 shape="Cylinder", material=material)


rounded_ground("Hub/Foundation", 616, 68, -0.5, 10, GRASS_EDGE, "Plastic")
rounded_ground("Hub/Grass", 600, 60, 0, 2, GREEN, "Plastic")
part("SpawnPlaza", "Hub", (0, 0.12, 0), (54, 0.24, 54), (155, 222, 113), shape="Cylinder")
part("Spawn", "Hub", (0, 0.4, 0), (12, 0.5, 12), GREEN, spawn=True, invisible=True)

for index in range(8):
    angle = math.radians(22.5 + 45 * index)
    x, z = math.sin(angle) * 258, math.cos(angle) * 258
    group = f"KitchenPlots/Plot{index + 1:02d}"
    accent = (63, 166, 156)
    def local(name, offset, size, color, **kwargs):
        ox, oy, oz = offset
        return part(name, group, (x + math.cos(angle) * ox + math.sin(angle) * oz,
                                 oy, z - math.sin(angle) * ox + math.cos(angle) * oz),
                    size, color, yaw=angle, **kwargs)
    local("PlotBase", (0, 0.25, 0), (96, 0.5, 88), (213, 230, 224))
    local("BuildArea", (0, 0.54, 0), (90, 0.08, 82), (232, 241, 234))
    local("BackCurb", (0, 0.9, 43), (96, 1.3, 2), accent)
    local("LeftCurb", (-47, 0.9, 0), (2, 1.3, 86), accent)
    local("RightCurb", (47, 0.9, 0), (2, 1.3, 86), accent)
    local("FrontCurbLeft", (-31, 0.9, -43), (34, 1.3, 2), accent)
    local("FrontCurbRight", (31, 0.9, -43), (34, 1.3, 2), accent)
    local("EntryPath", (0, 0.12, -59), (26, 0.24, 34), PATH)
    local("PlotNumber", (-37, 6, 38), (14, 8, 1.5), accent, label=f"{index + 1:02d}", label_face="Front")
    local("NumberPost", (-37, 2, 38), (2, 4, 2), WHITE)
    for furniture in kitchen_parts():
        ox, oy, oz = furniture["position"]
        extra = {key: value for key, value in furniture.items() if key not in ("name", "position", "size", "color")}
        part(furniture["name"], group + "/StarterKitchen",
             (x + math.cos(angle) * ox + math.sin(angle) * oz,
              oy + 0.58, z - math.sin(angle) * ox + math.cos(angle) * oz),
             furniture["size"], furniture["color"], yaw=angle, **extra)
    plots.append(dict(name=f"Plot{index + 1:02d}", center=[x, 0.5, z], yaw_degrees=22.5 + 45 * index,
                      footprint=[96, 88], build_area=[90, 82]))

part("MainPath", "GroceryApproach", (0, 0.18, -335), (64, 0.36, 150), PATH)
for x in (-34, 34):
    part("PathCurb", "GroceryApproach", (x, 0.4, -335), (2, 0.8, 150), (164, 223, 166))

zones = build_grocery(part)

# A few corner trees establish scale while the hub stays mostly empty.
for index, (x, z) in enumerate(((-265, -265), (265, -265), (-265, 265), (265, 265))):
    group = f"Hub/CornerTree{index + 1}"
    part("Trunk", group, (x, 5, z), (4, 10, 4), (161, 119, 83))
    part("LowerCanopy", group, (x, 14, z), (18, 13, 18), (62, 169, 87), yaw=0.2)
    part("UpperCanopy", group, (x, 23, z), (13, 10, 13), (129, 212, 87), yaw=-0.15)

assert len(plots) == 8
assert all(p["footprint"] == [96, 88] for p in plots)
assert all(abs(math.hypot(p["center"][0], p["center"][2]) - 258) < 1e-5 for p in plots)
floors = [p for p in parts if p["name"] == "OpenFloor"]
assert len(floors) == 5 and all(p["position"][0] == 0 and p["yaw"] == 0 for p in floors)
assert all(zones[i]["end"] == zones[i + 1]["start"] for i in range(4))

# Structured XML keeps the map portable without requiring a plugin or script execution.
xml = ET.Element("roblox", version="4")
counter = 0
def item(parent, cls, name):
    global counter
    counter += 1
    node = ET.SubElement(parent, "Item", {"class": cls, "referent": f"RBX{counter}"})
    props = ET.SubElement(node, "Properties")
    ET.SubElement(props, "string", name="Name").text = name
    return node, props


def value(props, tag, name, content):
    ET.SubElement(props, tag, name=name).text = str(content)


def vector(props, tag, name, values, keys):
    node = ET.SubElement(props, tag, name=name)
    for key, v in zip(keys, values):
        ET.SubElement(node, key).text = str(v)


model, _ = item(xml, "Model", "SquishTheButterMap")
groups = {"": model}
for p in parts:
    current = ""
    for section in p["group"].split("/"):
        child = current + "/" + section if current else section
        if child not in groups:
            groups[child], _ = item(groups[current], "Model", section)
        current = child
    node, props = item(groups[current], "SpawnLocation" if p.get("spawn") else "Part", p["name"])
    value(props, "bool", "Anchored", "true")
    value(props, "bool", "CanCollide", "false" if p.get("invisible") or not p.get("collide", True) else "true")
    value(props, "float", "Transparency", 1 if p.get("invisible") else p.get("transparency", 0))
    value(props, "token", "Material", 256)
    for face in ("Top", "Bottom", "Left", "Right", "Front", "Back"):
        value(props, "token", face + "Surface", 0 if p.get("invisible") else 3)
    vector(props, "Color3", "Color", [v / 255 for v in p["color"]], ("R", "G", "B"))
    sx, sy, sz = p["size"]
    vector(props, "Vector3", "size", (sy, sx, sz) if p["shape"] == "Cylinder" else (sx, sy, sz), ("X", "Y", "Z"))
    value(props, "token", "shape", 2 if p["shape"] == "Cylinder" else 1)
    c, s = math.cos(p["yaw"]), math.sin(p["yaw"])
    rotation = (0, -1, 0, 1, 0, 0, 0, 0, 1) if p["shape"] == "Cylinder" else (c, 0, s, 0, 1, 0, -s, 0, c)
    if p.get("roll"):
        cr, sr = math.cos(p["roll"]), math.sin(p["roll"])
        rotation = (c * cr, -c * sr, s, sr, cr, 0, -s * cr, s * sr, c)
    vector(props, "CoordinateFrame", "CFrame", (*p["position"], *rotation),
           ("X", "Y", "Z", "R00", "R01", "R02", "R10", "R11", "R12", "R20", "R21", "R22"))
    if p.get("spawn"):
        value(props, "bool", "Neutral", "true")
        value(props, "bool", "AllowTeamChangeOnTouch", "false")
        value(props, "float", "Duration", 0)
    if p.get("light"):
        _, light = item(node, "PointLight", "AccentLight")
        vector(light, "Color3", "Color", [v / 255 for v in p["light"]["color"]], ("R", "G", "B"))
        value(light, "float", "Brightness", p["light"]["brightness"])
        value(light, "float", "Range", p["light"]["range"])
        value(light, "bool", "Shadows", "false")
    if p.get("label"):
        surface, sp = item(node, "SurfaceGui", "Label")
        value(sp, "token", "Face", 2 if p["label_face"] == "Back" else 5)
        vector(sp, "Vector2", "CanvasSize", (800, 800 * sy / sx), ("X", "Y"))
        label, lp = item(surface, "TextLabel", "Text")
        value(lp, "string", "Text", p["label"])
        value(lp, "float", "BackgroundTransparency", 1)
        value(lp, "bool", "TextScaled", "true")
        value(lp, "token", "Font", 20)
        vector(lp, "Color3", "TextColor3", [v / 255 for v in p.get("text_color", WHITE)], ("R", "G", "B"))
        vector(lp, "UDim2", "Size", (1, 0, 1, 0), ("XS", "XO", "YS", "YO"))
ET.indent(xml)
ET.ElementTree(xml).write(OUT / "SquishTheButterMap.rbxmx", encoding="utf-8", xml_declaration=True)
(OUT / "layout.json").write_text(json.dumps(dict(plots=plots, parts=parts, grocery_axis="negative Z",
    grocery_width=176, grocery_length=1200, hub_width=600, zones=zones), indent=2))

# Build a standalone installer from this exact geometry; it only replaces the store.
installer_template = (ROOT / "tools/install_grocery.template.luau").read_text()
template_json = json.dumps(kitchen_parts(), separators=(",", ":"))
(ROOT / "src/shared/KitchenTemplate.luau").write_text(
    '-- Generated by tools/build_main_map.py from kitchen_structure.py.\n'
    'return game:GetService("HttpService"):JSONDecode([==[' + template_json + ']==])\n')
payload = json.dumps([p for p in parts if p["group"].startswith("GroceryStore/")], separators=(",", ":"))
assert "]==]" not in payload
installer = installer_template.replace("__GROCERY_JSON__", payload)
# Studio's single-line Command Bar handles this without line-comment ambiguity.
installer = " ".join(line.strip() for line in installer.splitlines()
                     if line.strip() and not line.lstrip().startswith("--"))
(OUT / "InstallGrocery.command.luau").write_text(installer + "\n")
if "--export-only" in sys.argv:
    print(f"Exported {len(parts)} parts and the grocery installer.")
    raise SystemExit(0)

# Render the manifest itself, so previews match the importable map geometry.
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.preferences.filepaths.save_version = 0
materials = {}
def render_material(color):
    key = tuple(color)
    if key not in materials:
        mat = bpy.data.materials.new(str(key))
        mat.diffuse_color = tuple((v / 255) ** 2.2 for v in color) + (1,)
        materials[key] = mat
    return materials[key]

for p in parts:
    if p.get("invisible"):
        continue
    x, y, z = p["position"]
    sx, sy, sz = p["size"]
    if p["shape"] == "Cylinder":
        bpy.ops.mesh.primitive_cylinder_add(vertices=64, radius=sx / 2, depth=sy, location=(x, -z, y))
    else:
        bpy.ops.mesh.primitive_cube_add(size=1, location=(x, -z, y))
        bpy.context.object.dimensions = (sx, sz, sy)
    obj = bpy.context.object
    obj.name = p["group"] + "/" + p["name"]
    obj.rotation_euler.z = p["yaw"]
    if p.get("roll"):
        obj.rotation_euler.y = -p["roll"]
    obj.data.materials.append(render_material(p["color"]))
    if p.get("transparency"):
        mat = render_material(p["color"]).copy()
        mat.diffuse_color = (*mat.diffuse_color[:3], 1 - p["transparency"])
        mat.blend_method = "BLEND"
        mat.use_screen_refraction = True
        obj.data.materials[0] = mat
    if p.get("light"):
        bpy.ops.object.light_add(type="POINT", location=(x, -z, y - 2))
        light = bpy.context.object
        light.data.energy = 12000 * p["light"]["brightness"] / 2.2
        light.data.color = tuple(v / 255 for v in p["light"]["color"])
        light.data.shadow_soft_size = 8
    if p.get("label"):
        text = bpy.data.curves.new("Label", "FONT")
        text.body = p["label"]
        text.align_x, text.align_y = "CENTER", "CENTER"
        longest = max(len(line) for line in p["label"].splitlines())
        text.size = min(sy * 0.68 / len(p["label"].splitlines()), sx / max(longest * 0.7, 1))
        label = bpy.data.objects.new("Label", text)
        bpy.context.collection.objects.link(label)
        # Front-facing entrance sign; plot numbers face the hub.
        normal = Vector((math.sin(p["yaw"]), -math.cos(p["yaw"]), 0))
        if p["label_face"] == "Front":
            normal = -normal
        label.location = Vector((x, -z, y)) + normal * (sz / 2 + 0.05)
        label.rotation_euler = normal.to_track_quat("Z", "Y").to_euler()
        label.data.materials.append(render_material(p.get("text_color", WHITE)))

scene = bpy.context.scene
scene.render.engine = "BLENDER_EEVEE"
scene.eevee.use_gtao = True
scene.eevee.gtao_distance = 14
scene.eevee.taa_render_samples = 96
scene.world = bpy.data.worlds.new("Sky")
scene.world.color = (0.65, 0.75, 0.85)
scene.view_settings.view_transform = "Standard"
scene.render.resolution_percentage = 100
bpy.ops.object.light_add(type="SUN", location=(400, -400, 900))
bpy.context.object.rotation_euler = (0.4, -0.5, -0.4)
bpy.context.object.data.energy = 2
bpy.ops.object.camera_add()
camera = bpy.context.object
camera.data.type = "ORTHO"
camera.data.clip_end = 10000
scene.camera = camera
def render(filename, position, target, scale, width, height):
    camera.location = position
    camera.rotation_euler = (Vector(target) - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.data.ortho_scale = scale
    scene.render.resolution_x, scene.render.resolution_y = width, height
    scene.render.filepath = str(OUT / filename)
    bpy.ops.render.render(write_still=True)

roofs = [obj for obj in bpy.data.objects if obj.name.endswith("/Ceiling")]
for roof in roofs:
    roof.hide_render = True
render("map-overhead.png", (0, 655, 2200), (0, 655, 0), 2080, 1000, 1600)
render("grocery-cutaway.png", (820, 370, 1050), (0, 990, 0), 1400, 1600, 1000)
for roof in roofs:
    roof.hide_render = False
render("hub-preview.png", (560, -740, 790), (0, 30, 0), 840, 1400, 1100)
render("grocery-entrance.png", (125, 255, 110), (0, 455, 20), 260, 1400, 1000)
camera.data.type = "PERSP"
camera.data.lens = 22
render("grocery-interior.png", (0, 425, 10), (0, 1200, 12), 260, 1600, 900)
render("grocery-cosmic.png", (0, 1380, 14), (0, 1575, 28), 260, 1400, 1000)
camera.data.type = "ORTHO"
for obj in bpy.data.objects:
    if obj.type not in {"CAMERA", "LIGHT"}:
        obj.hide_render = not obj.name.startswith("KitchenPlots/Plot01/")
render("kitchen-preview.png", (144, -100, 85), (99, -238, 0), 145, 1400, 1100)
for obj in bpy.data.objects:
    obj.hide_render = False
bpy.ops.wm.save_as_mainfile(filepath=str(OUT / "MapPreview.blend"))
print(json.dumps({"parts": len(parts), "kitchen_plots": len(plots), "grocery_straight": True,
                  "output": str(OUT / "SquishTheButterMap.rbxmx")}))
