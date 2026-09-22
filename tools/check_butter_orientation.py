"""Check the display-frame calculation against the exported collection geometry."""
from pathlib import Path

import bpy
from mathutils import Euler, Vector

root = Path(__file__).resolve().parents[1] / "assets/butter-collection"
for name in ("Plain", "Salted", "Golden", "Rainbow", "Cosmic"):
    bpy.ops.wm.open_mainfile(filepath=str(root / name / (name + ".blend")))
    body = bpy.data.objects["ButterBody"]
    labels = [o for o in bpy.context.scene.objects if o.type == "MESH" and "_Text" in o.name]
    largest = max(labels, key=lambda o: max(o.dimensions.x * o.dimensions.y,
                                         o.dimensions.x * o.dimensions.z,
                                         o.dimensions.y * o.dimensions.z))
    for angles in ((0, 0, 0), (1.57, 3.14, 0), (0.4, -1.2, 2.1)):
        rotation = Euler(angles).to_matrix()
        origin = rotation @ body.location
        basis = [rotation @ Vector((1, 0, 0)), rotation @ Vector((0, 1, 0)), rotation @ Vector((0, 0, 1))]
        front = basis[min(range(3), key=lambda a: largest.dimensions[a])]
        if front.dot(rotation @ largest.location - origin) < 0:
            front = -front
        right = basis[max(range(3), key=lambda a: body.dimensions[a])]
        right = (right - front * right.dot(front)).normalized()
        furthest = max(((rotation @ o.location - origin).dot(right) for o in labels), key=abs)
        if furthest < 0:
            right = -right
        assert right.dot(rotation @ Vector((1, 0, 0))) > 0.999
        assert front.dot(rotation @ Vector((0, 0, 1))) > 0.999
    print("ORIENTATION PASSED:", name, flush=True)
