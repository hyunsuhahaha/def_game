package.path="./?.lua;./?/init.lua;"..package.path
love={filesystem={getInfo=function()return nil end,write=function()return true end,read=function()return nil end}}
local A=require("src.achievements")
local a=A.new(true)
assert(#a:getDefinitions()==27,"achievement catalog must contain 27 entries")
local species=0 for _,d in ipairs(a:getDefinitions())do if d.category=="species"then species=species+1 end end
assert(species==13,"all 13 tree species need a 100-tree achievement")
for _=1,100 do a:recordTree("forest",1,"physical")end
assert(a:isUnlocked("first_cut") and a:isUnlocked("forest_100") and a:isUnlocked("species_broadleaf"),"tree achievements did not unlock")
assert(a.data.points==6,"tree achievement points incorrect")
assert(#a.queue==3,"unlock popup queue missing")
local encoded=A.encode(a.data);local restored=A.decode(encoded)
assert(restored.stats.species_broadleaf==100 and restored.unlocked.species_broadleaf,"achievement save migration failed")
for _,map in ipairs({"forest","mangrove","madagascar","island","beginner"})do a:recordMapClear(map)end
assert(a:isUnlocked("first_operation") and a:isUnlocked("all_operations"),"operation achievements did not unlock")
local operationSave=A.decode(A.encode(a.data));assert(operationSave.clears.island and operationSave.stats.unique_operations==5,"operation clear save failed")
local ok=select(1,a:buy("brass_edge"));assert(ok and a:effects().treeDamage==1,"achievement reward purchase/effect failed")
a:setBest("best_chain",20);assert(a:isUnlocked("chain_20"),"best-stat achievement failed")
local clearcut=assert(io.open("src/clearcut_mode.lua","rb")):read("*a")
assert(clearcut:find("recordTree",1,true) and clearcut:find('add("vegan_eaten"',1,true) and clearcut:find('add("bosses"',1,true) and clearcut:find("recordMapClear",1,true),"gameplay achievement hooks missing")
print("ACHIEVEMENTS_OK total=27 species=13 operations=5 rewards=4 popup=queued save=v1")
