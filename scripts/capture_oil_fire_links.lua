package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local Mode=require("src.clearcut_mode")
local OilArt=require("src.oil_trail_art")

love.graphics.setColor(.18,.24,.13,1)
love.graphics.rectangle("fill",0,0,1280,520)

local function scene(offsetX,ignited)
    local mode=Mode.new();mode.job="fire";mode.scoreAttack=true;mode.smokerGroundTime=3
    local left={id=offsetX+11,x=offsetX+145,y=260,state="settled",hp=8,maxHp=8,spillFacing=1}
    local right={id=offsetX+22,x=offsetX+465,y=260,state="settled",hp=8,maxHp=8,spillFacing=-1}
    mode:spillOilDrum(left,"axe");mode:spillOilDrum(right,"axe")
    for _,spot in ipairs(mode.oilTrail)do spot.spawnedAt=0 end
    if ignited then
        -- Start at the innermost left-puddle patch. The real propagation graph
        -- decides whether and where it reaches the second drum.
        local start=mode.oilTrail[1]
        for _,spot in ipairs(mode.oilTrail)do if spot.x>start.x then start=spot end end
        mode:igniteOilTrail(start,{world={nodes={}}})
        mode:updateOilFireLinks(0,{world={nodes={},addParticle=function()end}},mode.smokerGroundTime)
        mode.smokerGroundTime=mode.smokerGroundTime+.35
    end
    for _,link in ipairs(mode.oilFireLinks or{})do OilArt.drawGroundBridge(link.from,link.to,mode.smokerGroundTime)end
    for _,spot in ipairs(mode.oilTrail)do OilArt.drawGround(spot,mode.smokerGroundTime)end
    if ignited then
        for _,link in ipairs(mode.oilFireLinks or{})do OilArt.drawFlameBridge(link.from,link.to,mode.smokerGroundTime)end
        for _,spot in ipairs(mode.oilTrail)do OilArt.drawFlame(spot,mode.smokerGroundTime)end
    end
    return #mode.oilFireLinks
end

local unlit=scene(0,false)
local linked=scene(640,true)
love.graphics.setColor(.94,.90,.70,1)
love.graphics.print("점화 전 · 분리된 두 드럼통",150,455)
love.graphics.print("점화 후 · 주변 기름 연결 불길",790,455)
fixture.save("docs/previews/oil-fire-links-v1-draws.json")
print("OIL_FIRE_LINK_CAPTURE_OK unlit="..unlit.." linked="..linked.." window=none")
