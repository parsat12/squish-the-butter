"""Run with Blender --background --python tools/prepare_wax_butter.py -- INPUT OUTPUT_DIR."""
import json
import math
import random
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Vector


source, output = sys.argv[sys.argv.index("--") + 1:]
output = Path(output)
output.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=source)
meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
butter = next(obj for obj in meshes if obj.name.lower() == "butter")
center = sum((butter.matrix_world @ Vector(v) for v in butter.bound_box), Vector()) / 8
scale = 6 / max(butter.dimensions)
for obj in meshes:
    matrix = obj.matrix_world.copy()
    obj.parent = None
    for vertex in obj.data.vertices:
        vertex.co = (matrix @ vertex.co - center) * scale
    obj.matrix_world.identity()
for obj in list(bpy.context.scene.objects):
    if obj.type != "MESH":
        bpy.data.objects.remove(obj, do_unlink=True)

butter.name = "ButterBody"
bpy.context.view_layer.objects.active = butter
subdivision = butter.modifiers.new("DentTopology", "SUBSURF")
subdivision.subdivision_type = "SIMPLE"
subdivision.levels = 3
bpy.ops.object.modifier_apply(modifier=subdivision.name)
for polygon in butter.data.polygons:
    polygon.use_smooth = True

low = Vector(tuple(min(v.co[a] for v in butter.data.vertices) for a in range(3)))
high = Vector(tuple(max(v.co[a] for v in butter.data.vertices) for a in range(3)))
axes = sorted(range(3), key=lambda a: high[a] - low[a], reverse=True)
counts = [3, 3, 3]
counts[axes[0]] = 9
armature = bpy.data.armatures.new("ButterRig")
rig = bpy.data.objects.new("ButterRig", armature)
bpy.context.collection.objects.link(rig)
bpy.ops.object.select_all(action="DESELECT")
rig.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode="EDIT")
root = armature.edit_bones.new("Root")
root.head = (0, 0, 0)
root.tail = (0, 0, 0.1)
positions = []
for x in range(counts[0]):
    for y in range(counts[1]):
        for z in range(counts[2]):
            position = Vector(tuple(low[a] + (high[a] - low[a]) * i / (counts[a] - 1)
                                    for a, i in enumerate((x, y, z))))
            name = f"Dent_{len(positions):03d}"
            bone = armature.edit_bones.new(name)
            bone.head = position
            bone.tail = position + Vector((0, 0, 0.08))
            bone.parent = root
            positions.append((name, position))
bpy.ops.object.mode_set(mode="OBJECT")
groups = {name: butter.vertex_groups.new(name=name) for name, _ in positions}
for vertex in butter.data.vertices:
    nearest = sorted(positions, key=lambda item: (item[1] - vertex.co).length_squared)[:4]
    weights = [1 / max((point - vertex.co).length_squared, 0.015) ** 2 for _, point in nearest]
    total = sum(weights)
    for (name, _), weight in zip(nearest, weights):
        groups[name].add([vertex.index], weight / total, "REPLACE")
modifier = butter.modifiers.new("ButterSquish", "ARMATURE")
modifier.object = rig
butter.parent = rig

# Cut the wrapper and its lettering with identical Voronoi planes, preserving UVs.
rng = random.Random(43)
seeds = []
for along in range(9):
    for across in range(2):
        for height in range(2):
            coords = Vector()
            for axis, index, count in zip(axes, (along, across, height), (9, 2, 2)):
                coords[axis] = low[axis] + (high[axis] - low[axis]) * (index + rng.uniform(0.25, 0.75)) / count
            seeds.append(coords)
pieces = []
for original in [obj for obj in meshes if obj != butter]:
    for index, seed in enumerate(seeds):
        bm = bmesh.new()
        bm.from_mesh(original.data)
        for other in seeds:
            if other == seed or not bm.faces:
                continue
            bmesh.ops.bisect_plane(bm, geom=list(bm.verts) + list(bm.edges) + list(bm.faces),
                                  dist=0.00001, plane_co=(seed + other) / 2,
                                  plane_no=(other - seed).normalized(), clear_outer=True)
        if not bm.faces:
            bm.free()
            continue
        bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
        data = bpy.data.meshes.new(f"WaxChip_{index:02d}_{original.name}")
        bm.to_mesh(data)
        bm.free()
        for material in original.data.materials:
            data.materials.append(material)
        piece = bpy.data.objects.new(data.name, data)
        bpy.context.collection.objects.link(piece)
        # Give the shell a visible edge without exposing gaps in the intact wrapper.
        if original.name.lower() == "wrapper":
            for polygon in data.polygons:
                polygon.use_smooth = False
            bpy.context.view_layer.objects.active = piece
            solid = piece.modifiers.new("WaxThickness", "SOLIDIFY")
            solid.thickness = 0.015
            solid.offset = 0
            bpy.ops.object.modifier_apply(modifier=solid.name)
        pieces.append(piece)
    bpy.data.objects.remove(original, do_unlink=True)

# Keep each shard's local origin near its geometry for click-distance and rotation.
bpy.ops.object.select_all(action="DESELECT")
for piece in pieces:
    piece.select_set(True)
bpy.context.view_layer.objects.active = pieces[0]
bpy.ops.object.origin_set(type="ORIGIN_GEOMETRY", center="BOUNDS")
bpy.ops.object.select_all(action="SELECT")
bpy.ops.wm.save_as_mainfile(filepath=str(output / "SaltedWaxButter.blend"))
bpy.ops.export_scene.fbx(filepath=str(output / "SaltedWaxButter.fbx"), use_selection=True,
                         object_types={"MESH", "ARMATURE"}, add_leaf_bones=False,
                         bake_anim=False, use_mesh_modifiers=True, axis_forward="-Z", axis_up="Y")
assert len(pieces) >= 24
assert len(butter.data.vertices) > 1000
assert all(len(v.groups) <= 4 and abs(sum(g.weight for g in v.groups) - 1) < 0.0001
           for v in butter.data.vertices)
report = {"source": source, "wax_meshes": len(pieces), "dent_bones": len(positions),
          "butter_vertices": len(butter.data.vertices), "bone_weights_valid": True}
(output / "validation.json").write_text(json.dumps(report, indent=2))
print(json.dumps(report))
