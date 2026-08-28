package.path="./?.lua;./?/init.lua;"..package.path

local fixture=require("scripts.forest_render_fixture")
love.math.random=function(a,b) if b then return a elseif a then return 1 else return .5 end end

local Mode=require("src.clearcut_mode")
local ForestArt=require("src.forest_arcade_art")
local MoleBurrowArt=require("src.mole_burrow_art")

local mode=Mode.new()
mode.job="miner"
mode.levels.burrow_uproot=4
mode.permanentTraits={attackSpeed=1,range=0,area=0,extraTargets=0,treeDamage=0,moveSpeed=1}
mode.minerBurrow={state="tunnel",t=0,duration=4,lastX=200,lastY=205,trackX=200,trackY=205,side=1,launched=0}

local function enemy(kind,x,y,radius)
    return {kind=kind,x=x,y=y,hp=100,maxHp=100,hitTimer=0,visualHit=0,visualAttack=0,
        def={radius=radius,speed=0,boss=true,hitCooldown=1,damage=0}}
end

local squirrel=enemy("squirrel",135,194,16)
local boar=enemy("boar",270,222,25)
mode.enemies={squirrel,boar}

local game={
    player={x=200,y=205,facing=1},
    world={width=400,height=300},
    camera={trauma=0},
    setNotice=function() end,
}

assert(mode:eruptMinerBurrow(game),"tunnel eruption did not activate")
mode:updateEnemies(.37,game)
assert(squirrel.hopHeight>0 and boar.hopHeight>0,"eruption preview enemies did not become airborne")

fixture.reset()
love.graphics.setColor(.30,.47,.17,1)
love.graphics.rectangle("fill",0,0,400,300)
MoleBurrowArt.draw(mode.burrowTracks[#mode.burrowTracks])
ForestArt.drawBody(squirrel,.37)
ForestArt.drawBody(boar,.37)
ForestArt.drawHealth(squirrel,.37)
ForestArt.drawHealth(boar,.37)

local capture=assert(os.getenv("MOLE_ERUPTION_CAPTURE"),"MOLE_ERUPTION_CAPTURE is required")
fixture.save(capture)
print(string.format("MOLE_ERUPTION_CAPTURE_OK enemies=2 squirrel_hop=%.1f boar_hop=%.1f",squirrel.hopHeight,boar.hopHeight))
