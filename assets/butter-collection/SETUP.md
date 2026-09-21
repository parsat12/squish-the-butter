# Butter Collection

Five models based on your original butter, each with 36 breakaway wrapper pieces and matching cut lettering:

| File | Model name in ButterModels | Design |
| --- | --- | --- |
| Plain/Plain.fbx | Plain | Original wrapper; only SALTED changes to UNSALTED; 4 oz / 113 g |
| Salted/Salted.fbx | Salted | Original design, original lettering and colors; 4 oz / 113 g |
| Golden/Golden.fbx | Golden | Original layout in gold; 27.4 lb / 12.4 kg |
| Rainbow/Rainbow.fbx | Rainbow | Original layout with rainbow colors; 1 lb / 454 g |
| Cosmic/Cosmic.fbx | Cosmic | Original layout in deep violet and pale blue; 10^30 kg / 1e33 g |

No taglines, end stripes, stars, or new label panels. The original BUTTER lettering is retained as geometry. Weight labels are decorative and do not change physics or game odds. Salted's geometry and lettering are preserved from the original prepared model; its original material colors are carried by a texture atlas for Roblox import.

Each folder also includes an editable `.blend` source, an embedded/exported `_Color.png` texture atlas, and preview renders. These are Blender previews, not Roblox screenshots. FBX reimports were checked for texture loading, piece names, UVs, and triangle counts.

## Import

1. Stop Play mode. Import each FBX into Studio. Keep its `_Color.png` in the same folder as the FBX if moving files elsewhere.
2. Keep all mesh objects checked. Enable Import Only as a Model, Upload to Roblox, Add to Workspace, Keep Zero Influence Bones, and Set Pivot to Scene Origin.
3. Set Rig Type to Custom, keep Merge Meshes off, and use Studs for Scale Unit. The existing rig is preserved, but denting is optional; these models work with the wrapper-breaking script.
4. Verify the preview includes the colors and labels. Textures are embedded in the FBX as well as supplied separately. If Studio misses a texture, upload that variant's `_Color.png` and assign it to the ColorMap of a SurfaceAppearance on every MeshPart in that model. Set MeshPart.Color and SurfaceAppearance.Color to white so they don't tint the texture.
5. Move each outer Model into ReplicatedStorage > ButterModels. Name it exactly Plain, Salted, Golden, Rainbow, or Cosmic. Preserve all names inside it.
6. Move an older model of the same name outside ButterModels first. Keep only one model per type in that folder. Do not delete the old model until you have tested its replacement.
7. Run `NormalizeModels.command.luau` in Studio's Command Bar to size the five models to 5 studs and set their PrimaryParts. This only updates models with those five names in ButterModels.
8. Play and test your starting Plain butter. Your creator commands can add the others: `!givebutter Salted 1`, `!givebutter Golden 1`, `!givebutter Rainbow 1`, `!givebutter Cosmic 1`.

No gameplay script replacement is needed for these models. Keep your working Client and ButterInteraction scripts. The model files are not automatically imported by Rojo.
