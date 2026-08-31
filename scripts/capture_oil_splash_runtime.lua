package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local ClearcutMode=require("src.clearcut_mode")
local OilArt=require("src.oil_trail_art")
local SpillArt=require("src.oil_drum_spill_art")

love.graphics.setColor(.19,.25,.14,1)
love.graphics.rectangle("fill",0,0,1200,420)

local function scene(centerX,upgraded,ignited)
    local mode=ClearcutMode.new();mode.scoreAttack=true;mode.smokerGroundTime=2
    mode.permanentTraits.scoreOilDrum=1
    if upgraded then
        mode.permanentTraits.scoreOilRadius=150
        mode.permanentTraits.scoreOilSplashCount=12
        mode.permanentTraits.scoreOilPatchScale=.32
        mode.permanentTraits.scoreOilBurnDuration=6
    end
    local drum={id=upgraded and 22 or 11,x=centerX,y=220,state="settled",hp=8,maxHp=8,spillFacing=1}
    mode:spillOilDrum(drum,"axe")
    for _,spot in ipairs(mode.oilTrail)do
        spot.x=spot.x-drum.x+centerX
        spot.y=spot.y-drum.y+220
        spot.spawnedAt=0
        if ignited then spot.ignited=true;spot.ignitedAt=1 end
        OilArt.drawGround(spot,2)
    end
    if ignited then for _,spot in ipairs(mode.oilTrail)do OilArt.drawFlame(spot,2)end end
    SpillArt.drawGround({x=centerX,y=220,age=.32,facing=1,seed=drum.id})
end

scene(170,false,false)
scene(510,false,true)
scene(830,true,true)
love.graphics.setColor(.95,.91,.68,1)
love.graphics.print("기본 16자국",70,370)
love.graphics.print("기본 점화",430,370)
love.graphics.print("최대 28자국 / 반경 330",760,370)
fixture.save("docs/previews/oil-splash-runtime-v3-draws.json")
print("OIL_SPLASH_RUNTIME_CAPTURE_OK base=16 max=28 fire=separate window=none")
