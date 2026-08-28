package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local Art=require("src.secondhand_smoke_art")

local function save(path,clouds)
    fixture.reset()
    Art.draw({secondhandSmokeClouds=clouds})
    fixture.save(path)
end

save(assert(os.getenv("SECONDHAND_SINGLE_CAPTURE")),{
    {x=64+7*.68,y=-17-2.5*.68,age=.68,life=3.2},
})
save(assert(os.getenv("SECONDHAND_OVERLAP_CAPTURE")),{
    {x=64+7*2.45,y=-17-2.5*2.45,age=2.45,life=3.2},
    {x=64+7*1.52,y=-17-2.5*1.52,age=1.52,life=3.2},
    {x=64+7*.58,y=-17-2.5*.58,age=.58,life=3.2},
})
print("SECONDHAND_SMOKE_CAPTURE_OK single=1 overlap=3 runtime=secondhand_smoke_art")
