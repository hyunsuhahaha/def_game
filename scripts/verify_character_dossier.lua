-- The static dossier is a required mirror of every in-game skill definition.
package.path="./?.lua;./?/init.lua;"..package.path
local function read(path)
    local file=assert(io.open(path,"rb"));local value=file:read("*a");file:close();return value
end
local source=read("src/clearcut_mode.lua")
local dossier=read("docs/character_dossier.html")
local checked=0
for line in source:gmatch("[^\r\n]+") do
    local id=line:match('{id="([^"]+)"')
    local name=line:match('name="([^"]+)"')
    local desc=line:match('desc="([^"]*)"')
    local max=line:match('max=(%d+)')
    if id and name and desc and max then
        local dossierLine=dossier:match('[^\r\n]*id:"'..id..'"[^\r\n]*')
        assert(dossierLine,"character_dossier.html is missing skill "..id)
        assert(dossierLine:find('name:"'..name..'"',1,true),"dossier skill name is stale: "..id)
        assert(dossierLine:find('desc:"'..desc..'"',1,true),"dossier skill description is stale: "..id)
        -- Older static entries may omit max only when it is the universal 6.
        local documentedMax=dossierLine:match('max:(%d+)') or "6"
        assert(documentedMax==max,"dossier skill max level is stale: "..id)
        checked=checked+1
    end
end
assert(checked>=29,"dossier verifier found too few skill definitions")
print("CHARACTER_DOSSIER_OK skills="..checked.." names/descriptions/max=synced")
