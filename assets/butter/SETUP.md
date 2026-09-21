# Wax Butter Setup

`SaltedWaxButter.fbx` is a prepared copy of your supplied butter model. The original file is unchanged.

## Import into Roblox Studio

1. Open Studio's 3D Importer and select `SaltedWaxButter.fbx` in this folder.
2. Keep the separate meshes and skinning/bones. Do not merge everything into one mesh or remove the rig. This is a custom object, not a player avatar.
3. Import the entire model. Expand it in Explorer: there should be `ButterBody`, bones named `Dent_...`, and meshes starting with `WaxChip_...`. Preserve those names (suffixes added by the importer are fine).
4. Create a Folder named `ButterModels` in `ReplicatedStorage` if it doesn't exist. Move the whole imported model into it and name the outer Model `Salted`. For testing with the free starting butter, use `Plain` instead, or duplicate it under that name.
5. Set the outer model's PrimaryPart to `ButterBody`. Check the wrapper colors and lettering in the importer; the export preserves the original material assignments and UVs, but Studio's imported appearance needs checking. Keep the wrapper opaque, not Glass.
6. Sync the updated project scripts with Rojo. The client now also needs `ReplicatedStorage.Shared.ButterInteraction` (the ModuleScript from `src/shared/ButterInteraction.luau`).
7. Play, obtain Salted butter with `!givebutter Salted 1` using your creator account, select its bottom icon, then press Crack.

Clicking empty space should do nothing. Clicking the butter should dent it briefly and dislodge nearby wax fragments. The third hit removes the remaining shell and reveals the prize after the fragments move away. The existing prize sparkle effect remains.

## What Was Prepared

- The original wrapper and raised lettering were cut along matching irregular boundaries into 49 mesh objects. The unbroken pieces meet at their original boundaries.
- The butter has 81 deformation bones with at most four influences per vertex. It dents locally and returns over 0.65 seconds.
- The wrapper fractures along prepared boundaries, not a newly simulated fracture at every click. The clicked area chooses which pieces detach.
- An old unprepared model can still be opened, but cannot show the local dent or fragment effect. It needs the new mesh and bones.
- Blender round-trip checks verify the exported rig and actual vertex movement. Roblox Studio import, click alignment, and mobile appearance still need in-game testing.

The editable Blender source is `SaltedWaxButter.blend`. `intact-preview.png` and `click-preview.png` show the exported model reimported into Blender; these are not Roblox screenshots.

Roblox references: [rigging and skinning](https://create.roblox.com/docs/art/modeling/rigging), [Bone transforms](https://create.roblox.com/docs/reference/engine/classes/Bone).

## Rebuild

Run Blender in background mode with `tools/prepare_wax_butter.py`, passing the original FBX and this output folder after `--`. Run `tools/verify_wax_butter.py` with this output folder to check the export and regenerate previews.
