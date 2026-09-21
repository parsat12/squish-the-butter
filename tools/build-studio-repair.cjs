// Generate a self-contained Studio Command Bar repair from the current sources.
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '..');
const client = fs.readFileSync(path.join(root, 'src/client/init.client.luau'), 'utf8');
const interaction = fs.readFileSync(path.join(root, 'src/shared/ButterInteraction.luau'), 'utf8');
assert(!client.includes('addClickCrack'));
assert(client.includes('ButterInteraction.new(crackingModel'));
assert(interaction.includes('DENT_DURATION = 0.9'));
function literal(source) {
  const encoded = JSON.stringify(source);
  assert(!/\\u[0-9a-f]{4}/i.test(encoded), 'Convert JSON unicode escapes before emitting Luau');
  assert.equal(JSON.parse(encoded), source);
  return encoded;
}
const installer = `assert(not game:GetService("RunService"):IsRunning(), "Stop Play before repairing the scripts")
print("BUTTER REPAIR 1/4: Started (direct update)")
local editor = game:GetService("ScriptEditorService")
local clientSource = ${literal(client)}
local interactionSource = ${literal(interaction)}
local starterScripts = game:GetService("StarterPlayer").StarterPlayerScripts
local replicated = game:GetService("ReplicatedStorage")

local function uniqueChild(parent, name, className)
    local found
    for _, child in ipairs(parent:GetChildren()) do
        if child.Name == name then
            assert(not found, "Multiple objects named " .. name .. " under " .. parent:GetFullName() .. "; rename the extra object first")
            assert(child:IsA(className), name .. " must be a " .. className)
            found = child
        end
    end
    return found
end
local shared = uniqueChild(replicated, "Shared", "Folder")
local client = uniqueChild(starterScripts, "Client", "LocalScript")
local interaction = shared and uniqueChild(shared, "ButterInteraction", "ModuleScript")
assert(not client or not editor:FindScriptDocument(client), "Close the Client script tab, then run this repair again")
assert(not interaction or not editor:FindScriptDocument(interaction), "Close the ButterInteraction script tab, then run this repair again")
local duplicates = {}
for _, root in ipairs({game:GetService("StarterPlayer"), game:GetService("StarterGui"), game:GetService("ReplicatedFirst"), workspace}) do
    for _, item in ipairs(root:GetDescendants()) do
        if item:IsA("LocalScript") and item ~= client then
            local source = editor:GetEditorSource(item)
            if source:find("SquishTheButterGui", 1, true) and source:find("addClickCrack", 1, true) then
                table.insert(duplicates, item)
            end
        end
    end
end

local backup = Instance.new("Folder")
backup.Name = "ButterScriptBackup_" .. game:GetService("HttpService"):GenerateGUID(false)
backup.Parent = game:GetService("ServerStorage")
local function backUp(item)
    if not item then return end
    local saved = Instance.new(item.ClassName)
    saved.Name = item.Name
    saved.Source = editor:GetEditorSource(item)
    saved:SetAttribute("OriginalPath", item:GetFullName())
    if saved:IsA("BaseScript") then
        saved:SetAttribute("WasDisabled", item.Disabled)
        saved.Disabled = true
    end
    saved.Parent = backup
end
backUp(client)
backUp(interaction)
for _, item in ipairs(duplicates) do backUp(item) end
if not shared then
    shared = Instance.new("Folder")
    shared.Name = "Shared"
    shared.Parent = replicated
end
if not interaction then
    interaction = Instance.new("ModuleScript")
    interaction.Name = "ButterInteraction"
    interaction.Parent = shared
end
if not client then
    client = Instance.new("LocalScript")
    client.Name = "Client"
    client.Parent = starterScripts
end
print("BUTTER REPAIR 2/4: Updating helper module")
interaction.Source = interactionSource
print("BUTTER REPAIR 3/4: Updating Client")
client.Source = clientSource
print("BUTTER REPAIR 4/4: Checking scripts")
assert(client.Source == clientSource, "Client update did not match; backup: " .. backup:GetFullName())
assert(interaction.Source == interactionSource, "Module update did not match; backup: " .. backup:GetFullName())
client.Disabled = false
for _, item in ipairs(duplicates) do
    item.Disabled = true
    warn("Disabled duplicate old butter UI:", item:GetFullName())
end
print("BUTTER REPAIR COMPLETE. Both scripts updated. Backups:", backup:GetFullName())
print("Press Play. Output should say: [ButterClient] Bubbly UI v4 loaded")
`;
const output = path.join(root, 'tools/RepairButter.command.luau');
const command = installer.split(/\r?\n/).map(line => line.trim()).filter(Boolean).join(' ');
assert(!command.includes('\n'));
assert(command.startsWith('assert('));
assert(!command.includes('UpdateSourceAsync'));
fs.writeFileSync(output, command);
// Verify both embedded payloads are byte-for-byte copies of the project scripts.
const payloads = [...command.matchAll(/local (?:clientSource|interactionSource) = ("(?:[^"\\]|\\.)*")/g)].map(match => JSON.parse(match[1]));
assert.deepEqual(payloads, [client, interaction]);
console.log('Generated and verified:', output);
