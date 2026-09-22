# Squish the Butter: Main Map

Import `SquishTheButterMap.rbxmx` into your existing place's Workspace. This is a Roblox model file, not an FBX, so use Studio's Insert from File option for Workspace (or drag the file into Studio). Do not replace your whole game with the preview scene.

## Layout

- A 600 x 600-stud rounded-square grass hub, centered at the world origin. Grass surface Y = 0.
- Exactly eight kitchen plots, each 96 x 88 studs, with a clear 90 x 82-stud build area. Their centers are 258 studs from the hub center, spaced every 45 degrees.
- Matching teal low curbs, an open hub-facing entrance, a short approach path, and an ownership sign identify each plot. All eight starter kitchens use the same layout, colors, furniture, training pad, and expansion markers.
- One 64-stud-wide main path leads north (negative Z) to the grocery entrance.
- The grocery is 1,200 studs long, extending from Z = -410 to Z = -1610. Exactly five contiguous sections increase in length, width, and height: Plain, Salted, Golden, Rainbow, Cosmic. All share the same straight centerline. Gates, empty shelves, refrigerators, themed oversized displays, windows, ceilings, and lights establish the structure without filling the store with products.
- A central neutral spawn and four simple corner trees are included. The center is otherwise open.

## In Studio

1. Stop Play and insert the model into Workspace. Select it and press F to frame it.
2. Check for an existing baseplate covering the grass surface. Move that old baseplate out of the way if necessary; this map has its own anchored ground.
3. The model includes `Hub.Spawn`. Disable or move any older SpawnLocations you don't want used for testing.
4. Press Play to check walking, plot entrances, and the grocery path. This map has no gameplay scripts and doesn't alter the existing butter UI or inventory.

The eight plot models are under `SquishTheButterMap.KitchenPlots`, named `Plot01` through `Plot08`. Their `BuildArea` parts provide the position, rotation, and dimensions for later kitchen generation. The five store section models are under `GroceryStore`, named `Section01_Plain` through `Section05_Cosmic`.

## Starter Kitchens

For an existing map, stop Play, disconnect Rojo while installing manually, close open game script tabs, and run the complete contents of `InstallKitchens.command.luau` in Studio's Command Bar. Wait for `KITCHENS READY`, save, and press Play. The installer backs up scripts and previous StarterKitchen models in ServerStorage, matches each BuildArea's current scale/rotation, and leaves the hub, plot positions, grocery geometry, and butter source models in place. Do not scale the kitchens again.

Every starter has the same open-front 44 x 38 floor, cheap counters, wall cabinets, sink, small fridge, cracking table, 28 x 28 training pad, basic freestanding punching bag, and low expansion corner markers. At your 0.5 map scale, those dimensions become 22 x 19 and 14 x 14 studs respectively. The floor occupies under one-third of the 90 x 82 build area. The left and back walls leave the kitchen open toward the hub. All visible construction parts have classic studs.

One shared `KitchenTemplate` defines every stage-1 kitchen; no per-plot themes are generated. Future upgrade stages should use shared stage templates too. Upgrade purchases, later-stage furniture, and punching-bag training/stat gains are not implemented yet; the footprint and training space are reserved for them.

Players automatically get one unoccupied plot, with their display name on its sign. There are exactly eight slots. Additional players wait for a vacancy without taking somebody else's plot. On leaving, a player's plot is released. Plot number is session-specific; their selected Beebohs persist in existing player data and return to whichever plot is assigned next session (when DataStore saves work).

In Beeboh inventory, select a Beeboh and choose **Place in kitchen**. It roams in the clear indoor area and remains owned; **Return to inventory** removes it from the room. Placing it unequips it as a follower, and equipping it as a follower removes it from the kitchen. Deleting a Beeboh updates saved placement indices. All existing owned-Beeboh coin rates are preserved: kitchen placement neither doubles income nor removes income from unplaced Beebohs. No separate coin collector is required.

The cracking table's prompt opens the preview for your selected owned butter (or your first available type). Other owned types can be selected from the bottom hotbar while that preview is open. Press Crack to place the actual model on the table, then click/tap it three times or use the three-hit proximity prompt. The Beeboh appears on the tabletop with sparkles, and is added to inventory. Walking away or dying cancels an unfinished display without consuming butter; a server-confirmed final crack still grants its prize. The server validates ownership of the table, distance, health, inventory, and Beeboh capacity. Regular hotbar cracking away from the table remains available. The punching bag is currently a visual starter prop, not an attack-strength upgrade mechanic.

### First-Visit Arrow and Table Update

Run `UpdateKitchenGuide.command.luau` with Play stopped, Rojo disconnected, and script tabs closed. It updates the game scripts with backups but preserves existing kitchen geometry (building only missing kitchens). Save and press Play. Plots are assigned after player data loads; players beyond the eight available slots wait for a vacancy.

A personal yellow arrow trail runs from the character to the assigned plot, using pathfinding around obstacles. The server marks the visit complete only when a living character enters their own plot. The trail stays through respawns until that happens, then remains off for that assignment. A fresh server join gets fresh guidance because the player's plot number can change. No other player's route is shown.

Check in Studio with two players: unique plot names/routes; entering somebody else's plot should not clear your route; entering your own should; respawning afterward should not bring it back. At your own table test each butter type, three hits, the prize reveal, insufficient butter, a full Beeboh inventory, walking away, and another player's table. Engine interaction tests have not been run by the filesystem build tools.

`kitchen-preview.png` is a Blender geometry preview; native studs appear in Roblox, not Blender. `tools/tests/Kitchens.spec.luau` supplies Studio tests for unique assignment, full plots, reassignment, roaming bounds, and removal. Engine tests must be run in Studio; filesystem validation checks the identical templates, containment, and map geometry.

`layout.json` records exact part and plot coordinates. `map-overhead.png` and `hub-preview.png` are Blender renders of the same geometry, not Studio screenshots. `MapPreview.blend` is for editing/rendering previews; use the `.rbxmx` for the game.

The ground uses green anchored Plastic parts, not voxel Terrain, to keep the hub exactly flat. All visible map parts have classic Studs on all six surfaces, including floors, borders, and store structure. The invisible spawn stays smooth. Native Roblox surface studs are not shown in the Blender layout previews.

## Update an Already Imported Map

Stop Play, then run the contents of `ApplyStuds.command.luau` in Studio's Command Bar. This updates only Parts inside `Workspace.SquishTheButterMap`; butter models, Beebohs, and gameplay scripts are untouched. Save your place afterward. Alternatively, replace the previous imported map with the updated `.rbxmx`; do not keep two copies.

## Install the Grocery on Your Half-Scale Map

The current store has very soft ceiling lights (brightness 0.12), no Neon materials, advertising panels, or text labels. Colored structural arches remain. StarterPlayer.CharacterWalkSpeed is 24 in the Rojo project. Geometry previews do not include runtime police, real butter replacements, or roaming Beebohs. `DimGrocery.command.luau` and `SimplifyGrocery.command.luau` are older lighting alternatives; do not run them after the pickup installer unless you want those older settings.

1. Stop Play. Open `InstallGrocery.command.luau` and paste the entire contents into Studio's Command Bar, then press Enter.
2. Wait for `GROCERY COMPLETE` in Output. The script measures `GroceryApproach.MainPath` and matches its size, location, and rotation automatically. Do not halve the store again.
3. The old `GroceryStore` is moved to a uniquely named `GroceryBackup_...` folder in ServerStorage. The hub, plots, UI, butter models, and game scripts are unchanged. Running again replaces the store rather than duplicating it.
4. Save your place and test walking from the hub to the final display. The glass-look entrance doors are parked open; no scripts, unlock logic, combat, automatic doors, or teleporting portals are installed.

At scale 0.5 the store is 600 studs long. Its sections measure:

| Section | Length | Width | Ceiling height |
| --- | ---: | ---: | ---: |
| Plain | 80 | 64 | 19 |
| Salted | 100 | 70 | 23 |
| Golden | 120 | 76 | 28 |
| Rainbow | 140 | 82 | 34 |
| Cosmic | 160 | 88 | 42 |

The continuous central combat lane is at least 32 studs wide at that scale. Doors and windows use transparent Plastic so they retain the classic stud surface settings; lights are actual PointLights rather than replacing the studded parts with Neon. The portal is static set dressing. Colored arches distinguish the sections without signs. There are no purchase gates or tier locks yet.

## Actual Butter Pickups

1. Keep the real models in `ReplicatedStorage.ButterModels`, named `Plain`, `Salted`, `Golden`, `Rainbow`, and `Cosmic` (the corresponding `Plain Butter` etc. names also work). Source models are never edited. Missing models produce an Output warning and leave that tier's placeholders visible.
2. Stop Play, disconnect Rojo while manually installing, and close the Server, Client, GroceryPickups, and GroceryPickupClient script tabs.
3. Run the entire contents of `InstallGroceryCombat.command.luau` in Studio's Command Bar (`InstallGroceryPickups.command.luau` is an identical compatibility copy). It backs up affected scripts in ServerStorage, installs pickup/combat code, previews the actual models, and applies soft ceiling lighting without replacing the store or hub. Close all Server, Client, and grocery module script tabs before running. Wait for `GROCERY COMBAT READY`, then save and press Play. No map rescaling is needed.
4. Approach a butter and hold the pickup prompt (E, controller button, or touch). That player's section closes and police attack. Stay within six studs of an officer to automatically punch it. Defeating every officer opens both gates and grants one matching butter. Only the collecting player hides the display; other players have their own independent encounters.

Each display can be successfully collected once per player, with claims saved alongside the existing inventory. Claims survive respawns and rejoining when DataStore saves are available. No timer respawn is enabled. Existing Studio DataStore permission failures prevent persistence, just as for the rest of the inventory. Previous successful claims are preserved by this update. Butter is only awarded after victory; death, reset, leaving, or a 120-second safety timeout ends the encounter without granting or consuming that display. It can then be retried. You cannot start a second encounter while fighting. There are no coin charges or tier-unlock requirements yet.

The server validates a registered display ID, living character, proximity, request rate, section membership, and previous claim before starting combat. It owns officer positions, pathfinding, damage, cooldowns, and encounter completion. Personal client gates are backed by server boundary checks. Clients cannot report damage or victory. Claims and inventory are changed together without yielding after victory. Collecting never destroys the shared model on the server. Display IDs use the section and stable position ordering, so re-installing or uniformly scaling this layout does not reset claims. Reordering/removing display locations is a content migration and may change those IDs.

Officers are studded, block-style police with blue uniforms, caps, and badges. Each player sees idle officers in every section, their own active fight, officer health bars, and a compact combat status display. Other players' gates and officers do not block them. Combat tuning is in `src/shared/GroceryCombatConfig.luau`: officer counts are 2/2/3/3/4 and health is 24/32/40/48/56 from Plain through Cosmic. Player damage is 24 every 0.45 seconds. These are initial balance values, not playtested difficulty guarantees. Winning lets the player run back toward the hub; it does not teleport or assign a kitchen plot.

### Studio Test Checklist

- Run a local server with two players. Both should see the same butter. Pick it up with player A: A is trapped and fights; B still sees it and can move through the area. B can independently start the same encounter. A's victory should not unlock or finish B's fight.
- Verify both players auto-punch nearby police and police retaliate, with visible health changes. Defeat all officers: only that player gets one butter and their gates disappear.
- Try escaping through the entrance, far exit, side walls, and over the gates while fighting. Server bounds must return the character inside. Die/reset: gates clear, no butter is awarded, and the display returns for retry.
- Repeat a pickup request: inventory must not increase again. Dead characters, unknown IDs, pickups outside the section, and requests more than 14 studs from the display must fail.
- Respawn player A: the display should remain hidden. With working DataStores, rejoin and verify the claim and inventory persist.
- Check all five model types, keyboard/controller/touch prompts, shelf placement, and lighting. This requires Studio; filesystem builds cannot verify engine rendering or multiplayer behavior.

`tools/tests/GroceryCombat.spec.luau` supplies server-side Studio tests for isolated encounters, cooldowns, retaliation, confinement, victory, duplicate completion, reset, timeout, and tier scaling. Run it as a temporary server Script in a separate test session after installing. It creates/removes its own fixtures far from the map. These engine tests have not been executed by the filesystem-only build workflow.

`grocery-entrance.png`, `grocery-interior.png`, `grocery-cosmic.png`, and `grocery-cutaway.png` are Blender geometry previews, not in-Studio verification. The cutaway hides ceiling slabs for inspection. Native stud textures are visible in Roblox, not these previews. The full `.rbxmx` remains authored at scale 1 for reproducibility; use the installer for an existing scaled map.
