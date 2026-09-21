"""Reimport the exported FBX, validate skinning, and render intact/click previews."""
import json
import sys
from pathlib import Path

import bpy
from mathutils import Vector

folder = Path(sys.argv[sys.argv.index("--") + 1])
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=str(folder / "SaltedWaxButter.fbx"))
body = bpy.data.objects["ButterBody"]
rig = next(obj for obj in bpy.context.scene.objects if obj.type == "ARMATURE")
chips = [obj for obj in bpy.context.scene.objects if obj.name.startswith("WaxChip_")]
assert len(chips) == 49
assert len([bone for bone in rig.pose.bones if bone.name.startswith("Dent_")]) == 81
assert len(body.vertex_groups) == 81
assert any(mod.type == "ARMATURE" for mod in body.modifiers)

scene = bpy.context.scene
scene.render.engine = "BLENDER_EEVEE"
scene.eevee.use_gtao = True
scene.eevee.gtao_distance = 3
scene.eevee.taa_render_samples = 48
scene.render.resolution_x = 1000
scene.render.resolution_y = 650
scene.render.resolution_percentage = 100
scene.world = bpy.data.worlds.new("PreviewWorld")
scene.world.color = (0.22, 0.22, 0.22)
scene.view_settings.view_transform = "Standard"
for location, power, size in [((1, -4, 8), 1100, 6), ((-5, 3, 4), 700, 5)]:
    bpy.ops.object.light_add(type="AREA", location=location)
    bpy.context.object.data.energy = power
    bpy.context.object.data.size = size
bpy.ops.object.camera_add(location=(3.4, -6.2, 7.2))
camera = bpy.context.object
camera.rotation_euler = (-camera.location).to_track_quat("-Z", "Y").to_euler()
camera.data.type = "ORTHO"
camera.data.ortho_scale = 8.5
scene.camera = camera
scene.render.filepath = str(folder / "intact-preview.png")
bpy.ops.render.render(write_still=True)

depsgraph = bpy.context.evaluated_depsgraph_get()
before = [v.co.copy() for v in body.evaluated_get(depsgraph).data.vertices]
hit = Vector((0.5, -0.3, 0.7))
for bone in rig.pose.bones:
    if bone.name.startswith("Dent_"):
        position = rig.matrix_world @ bone.bone.head_local
        strength = max(0, 1 - (position - hit).length / 1.25) ** 2
        bone.location = bone.bone.matrix_local.to_3x3().inverted() @ Vector((0, 0, -0.35 * strength))
for chip in chips:
    if (chip.location - hit).length < 1.35:
        chip.location += Vector((0, -0.3, 0.5))
        chip.rotation_euler.x += 0.35
bpy.context.view_layer.update()
after = [v.co.copy() for v in body.evaluated_get(depsgraph).data.vertices]
movement = max((a - b).length for a, b in zip(before, after))
assert movement > 0.01, f"Skinning did not deform exported mesh: {movement}"
scene.render.filepath = str(folder / "click-preview.png")
bpy.ops.render.render(write_still=True)
print(json.dumps({"fbx_roundtrip": "passed", "max_dent": movement, "pieces": len(chips)}))
