"""Validate the five FBX exports and render their imported textures."""
import json
from pathlib import Path

import bpy
import numpy as np
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/butter-collection"
names = ("Plain", "Salted", "Golden", "Rainbow", "Cosmic")
reports = []
for name in names:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=str(OUT / name / (name + ".fbx")))
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    wrappers = [o for o in meshes if "wrapper" in o.name]
    assert len(wrappers) == 36
    assert all(o.name == "ButterBody" or o.name.startswith("WaxChip_") for o in meshes)
    assert all(len(o.data.uv_layers) == 1 for o in meshes)
    textures = [node.image for mat in bpy.data.materials if mat.use_nodes
                for node in mat.node_tree.nodes if node.type == "TEX_IMAGE" and node.image]
    assert textures and all(image.size[0] == 1024 for image in textures)
    triangles = []
    for obj in meshes:
        obj.data.calc_loop_triangles()
        triangles.append(len(obj.data.loop_triangles))
    assert max(triangles) < 20000
    # Imported units can vary; normalize the verification scene around the origin.
    body = bpy.data.objects["ButterBody"]
    scale = 6 / max(body.dimensions)
    roots = [o for o in bpy.context.scene.objects if not o.parent]
    for obj in roots:
        obj.location *= scale
        obj.scale *= scale
    bpy.context.view_layer.update()
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.eevee.use_gtao = True
    scene.eevee.taa_render_samples = 48
    scene.render.resolution_x, scene.render.resolution_y = 1000, 640
    scene.render.resolution_percentage = 100
    scene.world = bpy.data.worlds.new("Preview")
    scene.world.color = (0.3, 0.3, 0.3)
    scene.view_settings.view_transform = "Standard"
    for position, energy in [((1, -4, 8), 850), ((-5, 3, 4), 650)]:
        bpy.ops.object.light_add(type="AREA", location=position)
        bpy.context.object.data.energy = energy
        bpy.context.object.data.size = 6
    bpy.ops.object.camera_add(location=(2.4, -5.3, 8.5))
    camera = bpy.context.object
    camera.rotation_euler = (-camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 7.6
    scene.camera = camera
    scene.render.filepath = str(OUT / name / (name + "-import-check.png"))
    bpy.ops.render.render(write_still=True)
    bpy.data.images["Render Result"].save_render(str(OUT / name / (name + "-preview.png")))
    reports.append({"type": name, "fbx_reimport": "passed", "wrapper_pieces": len(wrappers),
                    "embedded_texture_loaded": True, "largest_mesh_triangles": max(triangles)})
    print("VERIFIED", name, flush=True)

# A contact sheet of the reimported exports, not the source Blender scenes.
sheet = np.ones((640 * 3, 1000 * 2, 4), dtype=np.float32)
sheet[:, :, :3] = 0.3
for index, name in enumerate(names):
    img = bpy.data.images.load(str(OUT / name / (name + "-import-check.png")))
    pixels = np.empty(1000 * 640 * 4, dtype=np.float32)
    img.pixels.foreach_get(pixels)
    row, col = 2 - index // 2, index % 2
    sheet[row * 640:(row + 1) * 640, col * 1000:(col + 1) * 1000] = pixels.reshape(640, 1000, 4)
image = bpy.data.images.new("Butter collection", width=2000, height=1920)
image.pixels.foreach_set(sheet.ravel())
image.filepath_raw = str(OUT / "collection-preview.png")
image.file_format = "PNG"
image.save()
(OUT / "import-validation.json").write_text(json.dumps(reports, indent=2))
