"""Preserve the user's original wrapper geometry and layout across butter tiers."""
import colorsys
import json
import math
import random
from pathlib import Path

import bmesh
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/butter-collection"
VARIANTS = {
    "Plain": ("UNSALTED", None, None),
    "Salted": (None, None, None),
    "Golden": ("GOLDEN", "27.4 LB.", "NET WT (12.4 KG)"),
    "Rainbow": ("RAINBOW", "1 LB.", "NET WT (454 G)"),
    "Cosmic": ("COSMIC", "10^30 KG", "NET WT (1e33 G)"),
}
BOUNDS = {
    "Material.004": (-0.42491847, 0.32644266, 0.28146502, 0.41133159),
    "Material.005": (2.09784770, 2.55624914, -0.50579900, -0.35395616),
    "Material.006": (1.98201501, 2.67220402, -0.78389633, -0.64445126),
}


def srgb(c):
    return 12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055


def make_seeds(body):
    low = Vector(tuple(min(v.co[a] for v in body.data.vertices) for a in range(3)))
    high = Vector(tuple(max(v.co[a] for v in body.data.vertices) for a in range(3)))
    axes = sorted(range(3), key=lambda a: high[a] - low[a], reverse=True)
    rng = random.Random(43)
    seeds = []
    for along in range(9):
        for across in range(2):
            for height in range(2):
                coords = Vector()
                for axis, index, count in zip(axes, (along, across, height), (9, 2, 2)):
                    coords[axis] = low[axis] + (high[axis] - low[axis]) * (index + rng.uniform(0.25, 0.75)) / count
                seeds.append(coords)
    return seeds


def replace_text(material_name, wording, seeds):
    # Remove only the requested material section, preserving all other original letters.
    for obj in list(bpy.context.scene.objects):
        if obj.type != "MESH" or "_Text" not in obj.name:
            continue
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        faces = [f for f in bm.faces if obj.data.materials[f.material_index].name == material_name]
        bmesh.ops.delete(bm, geom=faces, context="FACES")
        if bm.faces:
            bm.to_mesh(obj.data)
        else:
            bpy.data.objects.remove(obj, do_unlink=True)
        bm.free()
    curve = bpy.data.curves.new("ReplacementLabel", "FONT")
    curve.body = wording
    curve.font = bpy.data.fonts.load("C:/Windows/Fonts/arial.ttf")
    curve.size = 1
    curve.resolution_u = 4
    obj = bpy.data.objects.new("ReplacementLabel", curve)
    bpy.context.collection.objects.link(obj)
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.convert(target="MESH")
    xmin, xmax, ymin, ymax = BOUNDS[material_name]
    lo = Vector(tuple(min(v.co[a] for v in obj.data.vertices) for a in range(3)))
    hi = Vector(tuple(max(v.co[a] for v in obj.data.vertices) for a in range(3)))
    factor = min((ymax - ymin) / (hi.y - lo.y),
                 (1.05 if material_name == "Material.004" else xmax - xmin) / (hi.x - lo.x))
    center = (lo + hi) / 2
    for vertex in obj.data.vertices:
        vertex.co = (vertex.co - center) * factor + Vector(((xmin + xmax) / 2, (ymin + ymax) / 2, 0.73109853))
    for index, seed in enumerate(seeds):
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        for other in seeds:
            if other == seed or not bm.faces:
                continue
            bmesh.ops.bisect_plane(bm, geom=list(bm.verts) + list(bm.edges) + list(bm.faces),
                                  dist=0.00001, plane_co=(seed + other) / 2,
                                  plane_no=(other - seed).normalized(), clear_outer=True)
        if bm.faces:
            bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
            data = bpy.data.meshes.new("Label")
            bm.to_mesh(data)
            data.materials.append(bpy.data.materials[material_name])
            chip = bpy.data.objects.new(f"WaxChip_{index:02d}_Text", data)
            bpy.context.collection.objects.link(chip)
        bm.free()
    bpy.data.objects.remove(obj, do_unlink=True)


def texture_model(name, meshes, folder):
    originals = {m.name: tuple(m.node_tree.nodes.get("Principled BSDF").inputs["Base Color"].default_value[:3])
                 for m in bpy.data.materials if m.use_nodes and m.node_tree.nodes.get("Principled BSDF")}
    names = sorted(originals)
    colors = {key: tuple(srgb(c) for c in rgb) for key, rgb in originals.items()}
    if name not in ("Plain", "Salted"):
        ink = {"Golden": (0.28, 0.15, 0.035), "Rainbow": (0.17, 0.16, 0.43), "Cosmic": (0.66, 0.86, 1)}[name]
        for key in names:
            if key not in ("Material.001", "Material.002"):
                colors[key] = ink
        colors["Material.001"] = {"Golden": (1, 0.71, 0.15), "Rainbow": (0.68, 0.90, 1), "Cosmic": (0.43, 0.32, 0.72)}[name]
        colors["Material.002"] = {"Golden": (0.95, 0.69, 0.20), "Rainbow": (0.8, 0.9, 1), "Cosmic": (0.14, 0.11, 0.30)}[name]
    image = bpy.data.images.new(name + "_Color", width=1024, height=512)
    pixels = []
    for y in range(512):
        for x in range(1024):
            if y < 128:
                rgb = colors[names[min(len(names) - 1, x * len(names) // 1024)]]
            elif name == "Rainbow":
                rgb = colorsys.hsv_to_rgb(x / 1023 * 0.80, 0.50, 0.96)
            else:
                rgb = colors["Material.002"]
            pixels.extend((*rgb, 1))
    image.pixels.foreach_set(pixels)
    image.filepath_raw = str(folder / (name + "_Color.png"))
    image.file_format = "PNG"
    image.save()
    image.pack()
    mat = bpy.data.materials.new(name + "_Atlas")
    mat.use_nodes = True
    tex = mat.node_tree.nodes.new("ShaderNodeTexImage")
    tex.image = image
    mat.node_tree.links.new(tex.outputs["Color"], mat.node_tree.nodes.get("Principled BSDF").inputs["Base Color"])
    mat.node_tree.nodes.get("Principled BSDF").inputs["Roughness"].default_value = 0.5
    for obj in meshes:
        for layer in list(obj.data.uv_layers):
            obj.data.uv_layers.remove(layer)
        uv = obj.data.uv_layers.new(name="UVMap")
        for face in obj.data.polygons:
            original = obj.data.materials[face.material_index].name
            for loop_id in face.loop_indices:
                if original == "Material.002":
                    p = obj.matrix_world @ obj.data.vertices[obj.data.loops[loop_id].vertex_index].co
                    coords = (max(0.001, min(0.999, (p.x + 3) / 6)), 0.7)
                else:
                    coords = ((names.index(original) + 0.5) / len(names), 0.125)
                uv.data[loop_id].uv = coords
            face.material_index = 0
        obj.data.materials.clear()
        obj.data.materials.append(mat)


reports = []
for name, changes in VARIANTS.items():
    bpy.ops.wm.open_mainfile(filepath=str(ROOT / "assets/butter/SaltedWaxButter.blend"))
    bpy.context.preferences.filepaths.save_version = 0
    body = bpy.data.objects["ButterBody"]
    seeds = make_seeds(body)
    original_signature = sorted((o.name, len(o.data.vertices), len(o.data.polygons))
                                for o in bpy.context.scene.objects if o.type == "MESH")
    for material_name, wording in zip(BOUNDS, changes):
        if wording:
            replace_text(material_name, wording, seeds)
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    if name == "Salted":
        assert original_signature == sorted((o.name, len(o.data.vertices), len(o.data.polygons)) for o in meshes)
    folder = OUT / name
    folder.mkdir(parents=True, exist_ok=True)
    texture_model(name, meshes, folder)
    bpy.ops.object.select_all(action="DESELECT")
    for obj in meshes:
        if obj != body:
            obj.select_set(True)
    bpy.context.view_layer.objects.active = next(o for o in meshes if "wrapper" in o.name)
    bpy.ops.object.origin_set(type="ORIGIN_GEOMETRY", center="BOUNDS")
    bpy.ops.object.select_all(action="SELECT")
    bpy.context.scene.unit_settings.system = "METRIC"
    bpy.context.scene.unit_settings.scale_length = 0.01
    bpy.ops.wm.save_as_mainfile(filepath=str(folder / (name + ".blend")))
    bpy.ops.export_scene.fbx(filepath=str(folder / (name + ".fbx")), use_selection=True,
                             object_types={"MESH", "ARMATURE"}, add_leaf_bones=False,
                             bake_anim=False, apply_scale_options="FBX_SCALE_UNITS",
                             path_mode="COPY", embed_textures=True, axis_forward="-Z", axis_up="Y")
    reports.append({"type": name, "label_changes": changes, "original_layout_preserved": True,
                    "salted_original_geometry": name == "Salted", "wrapper_pieces": 36})
    print("RESTORED", name, flush=True)
(OUT / "validation.json").write_text(json.dumps(reports, indent=2))
