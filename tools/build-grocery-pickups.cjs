const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '..');
const sources = [
  ['ServerScriptService', 'Server', 'Script', 'src/server/init.server.luau'],
  ['ServerScriptService.Server', 'GroceryPickups', 'ModuleScript', 'src/server/GroceryPickups.luau'],
  ['ServerScriptService.Server', 'GroceryCombat', 'ModuleScript', 'src/server/GroceryCombat.luau'],
  ['ServerScriptService.Server', 'Kitchens', 'ModuleScript', 'src/server/Kitchens.luau'],
  ['ReplicatedStorage.Shared', 'KitchenTemplate', 'ModuleScript', 'src/shared/KitchenTemplate.luau'],
  ['ReplicatedStorage.Shared', 'KitchenLayout', 'ModuleScript', 'src/shared/KitchenLayout.luau'],
  ['ReplicatedStorage.Shared', 'KitchenGuide', 'ModuleScript', 'src/shared/KitchenGuide.luau'],
  ['ReplicatedStorage.Shared', 'TableButter', 'ModuleScript', 'src/shared/TableButter.luau'],
  ['ReplicatedStorage.Shared', 'ButterInteraction', 'ModuleScript', 'src/shared/ButterInteraction.luau'],
  ['ReplicatedStorage.Shared', 'GroceryCombatConfig', 'ModuleScript', 'src/shared/GroceryCombatConfig.luau'],
  ['ReplicatedStorage.Shared', 'GroceryCombatClient', 'ModuleScript', 'src/shared/GroceryCombatClient.luau'],
  ['ReplicatedStorage.Shared', 'GroceryPickupClient', 'ModuleScript', 'src/shared/GroceryPickupClient.luau'],
  ['StarterPlayer.StarterPlayerScripts', 'Client', 'LocalScript', 'src/client/init.client.luau'],
];
const entries = sources.map(([parent, name, cls, file]) => {
  const source = fs.readFileSync(path.join(root, file), 'utf8');
  const encoded = JSON.stringify(source);
  assert(!/\\u[0-9a-f]{4}/i.test(encoded));
  assert.equal(JSON.parse(encoded), source);
  return `{Parent=${JSON.stringify(parent)},Name=${JSON.stringify(name)},Class=${JSON.stringify(cls)},Source=${encoded}}`;
});
const template = fs.readFileSync(path.join(__dirname, 'install-grocery-pickups.template.luau'), 'utf8');
const command = template.replace('__SOURCES__', entries.join(','))
  .split(/\r?\n/).filter(line => line.trim() && !line.trimStart().startsWith('--')).map(line => line.trim()).join(' ');
assert(!command.includes('__SOURCES__'));
const payloads = [...command.matchAll(/,Source=("(?:[^"\\]|\\.)*")/g)].map(match => JSON.parse(match[1]));
assert.deepEqual(payloads, sources.map(entry => fs.readFileSync(path.join(root, entry[3]), 'utf8')));
fs.writeFileSync(path.join(root, 'assets/main-map/InstallGroceryPickups.command.luau'), command + '\n');
fs.writeFileSync(path.join(root, 'assets/main-map/InstallGroceryCombat.command.luau'), command + '\n');
const kitchenTemplate = fs.readFileSync(path.join(__dirname, 'install-kitchens.template.luau'), 'utf8');
const kitchenCommand = kitchenTemplate.replace('__SOURCES__', entries.join(','))
  .split(/\r?\n/).filter(line => line.trim() && !line.trimStart().startsWith('--')).map(line => line.trim()).join(' ');
const kitchenPayloads = [...kitchenCommand.matchAll(/,Source=("(?:[^"\\]|\\.)*")/g)].map(match => JSON.parse(match[1]));
assert.deepEqual(kitchenPayloads, payloads);
fs.writeFileSync(path.join(root, 'assets/main-map/InstallKitchens.command.luau'), kitchenCommand.replaceAll('__REBUILD_KITCHENS__', 'true') + '\n');
fs.writeFileSync(path.join(root, 'assets/main-map/UpdateKitchenGuide.command.luau'), kitchenCommand.replaceAll('__REBUILD_KITCHENS__', 'false') + '\n');
console.log(`Generated pickup/combat installers; all ${sources.length} source payloads verified.`);
