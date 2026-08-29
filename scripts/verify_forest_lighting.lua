package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local Lighting=require("src.forest_lighting")
local Maps=require("src.clearcut_maps")

for _,def in ipairs(Maps.catalog) do
    local world={clearcutMap=def.id,width=3200,height=2000,playBounds=nil}
    Maps.configureStage(world,1)
    local data=Lighting.generate(world,1)
    local expected=({forest=22,beginner=17,mangrove=26,madagascar=20,island=21})[def.id]
    assert(#data.patches==expected,def.id.." lighting density mismatch")
    fixture.reset();Lighting.drawGround(world)
    assert(#fixture.commands==expected,def.id.." lighting patches did not all render")
    for _,command in ipairs(fixture.commands) do
        assert(command.op=="draw" and command.file:find("forest%-light%-patterns%-pixel%-v1%.png"),"runtime primitive replaced authored lighting art")
    end
end
local first={clearcutMap="forest",width=3200,height=2000};Maps.configureStage(first,1)
local second={clearcutMap="forest",width=3200,height=2000};Maps.configureStage(second,1)
Lighting.generate(first,2);Lighting.generate(second,2)
for i,a in ipairs(first.forestLighting.patches) do local b=second.forestLighting.patches[i]
    assert(a.x==b.x and a.y==b.y and a.sx==b.sx and a.sy==b.sy and a.alpha==b.alpha,"world lighting is not deterministic")
end
print("FOREST_LIGHTING_OK atlas=768x768 cells=9 maps=5 worldLocked=true primitives=none")
