-- Upright 2.5D-safe art for the two max-rank smoker weapon evolutions.
local Art={}
local equip,fx,burstFx,vapeChargeFx,vapePressureFx,vapeLeafFx
local equipQuads,fxQuads,burstQuads,vapeChargeQuads,vapePressureQuads,vapeLeafQuads
local CELL,BURST_CELL,BURST_FRAMES=192,384,30
local VAPE_CHARGE_FRAMES,VAPE_PRESSURE_FRAMES=24,24
local VAPE_CHARGE_CELL,VAPE_PRESSURE_W,VAPE_PRESSURE_H,VAPE_LEAF_CELL=256,768,384,64

local function load()
    if equip then return end
    equip=love.graphics.newImage("assets/characters/ingame/smoker-weapon-evolution-equipment-v1.png")
    fx=love.graphics.newImage("assets/effects/smoker-weapon-evolution-fx-v1.png")
    burstFx=love.graphics.newImage("assets/effects/smoker-firework-burst-v2.png")
    vapeChargeFx=love.graphics.newImage("assets/effects/smoker-vape-charge-fx-v2.png")
    vapePressureFx=love.graphics.newImage("assets/effects/smoker-vape-pressure-fx-v2.png")
    vapeLeafFx=love.graphics.newImage("assets/effects/smoker-vape-leaves-fx-v2.png")
    for _,image in ipairs({equip,fx,burstFx,vapeChargeFx,vapePressureFx,vapeLeafFx})do image:setFilter("nearest","nearest")end
    equipQuads={
        vape=love.graphics.newQuad(0,0,128,96,256,96),
        fireworks=love.graphics.newQuad(128,0,128,96,256,96),
    }
    fxQuads={}
    for row=0,2 do fxQuads[row+1]={};for frame=0,5 do
        fxQuads[row+1][frame+1]=love.graphics.newQuad(frame*CELL,row*CELL,CELL,CELL,1152,576)
    end end
    burstQuads={};for index=0,BURST_FRAMES-1 do
        local column,row=index%6,math.floor(index/6)
        burstQuads[index+1]=love.graphics.newQuad(column*BURST_CELL,row*BURST_CELL,BURST_CELL,BURST_CELL,2304,1920)
    end
    vapeChargeQuads={};for index=0,VAPE_CHARGE_FRAMES-1 do
        vapeChargeQuads[index+1]=love.graphics.newQuad(index*VAPE_CHARGE_CELL,0,VAPE_CHARGE_CELL,VAPE_CHARGE_CELL,VAPE_CHARGE_CELL*VAPE_CHARGE_FRAMES,VAPE_CHARGE_CELL)
    end
    vapePressureQuads={};for index=0,VAPE_PRESSURE_FRAMES-1 do
        local column,row=index%8,math.floor(index/8)
        vapePressureQuads[index+1]=love.graphics.newQuad(column*VAPE_PRESSURE_W,row*VAPE_PRESSURE_H,VAPE_PRESSURE_W,VAPE_PRESSURE_H,VAPE_PRESSURE_W*8,VAPE_PRESSURE_H*3)
    end
    vapeLeafQuads={};for index=0,7 do vapeLeafQuads[index+1]=love.graphics.newQuad(index*VAPE_LEAF_CELL,0,VAPE_LEAF_CELL,VAPE_LEAF_CELL,VAPE_LEAF_CELL*8,VAPE_LEAF_CELL)end
end

local function frame(age,life,count)
    count=count or 6
    return math.max(1,math.min(count,math.floor(math.max(0,age)/(life/count))+1))
end

function Art.drawHeld(mode,game,t)
    local branch=mode.smokerEvolutionId and mode:smokerEvolutionId() or mode:skillBranch("molotov")
    if branch~="vape" and branch~="fireworks"then return false end
    load();local quad=equipQuads[branch]
    local player=game.player;local facing=player.facing or 1
    local kick=branch=="vape"and(mode.vapeKick or 0)*9 or 0
    local x,y=player.x+facing*(24-kick),player.y-68
    love.graphics.setColor(0,0,0,.25);love.graphics.ellipse("fill",x,y+40,22,5)
    love.graphics.setColor(1,1,1,1)
    local scale=branch=="vape" and .55 or .62
    love.graphics.draw(equip,quad,x,y,0,scale*facing,scale,64,48)
    if branch=="vape" then
        local charge=math.max(0,math.min(1,mode.vapeCharge or 0))
        if charge>0 then
            local index=math.max(1,math.min(VAPE_CHARGE_FRAMES,math.floor(charge*(VAPE_CHARGE_FRAMES-1))+1))
            love.graphics.setColor(1,1,1,.56+charge*.44)
            love.graphics.draw(vapeChargeFx,vapeChargeQuads[index],x+facing*4,y-1,0,.31*facing,.31,118,132)
        end
    else
        love.graphics.setColor(1,.68,.2,.3+math.sin(t*13)*.12);love.graphics.circle("fill",x+facing*29,y-2,5)
    end
    return true
end

function Art.drawChoice(branch,cx,cy,scale)
    load();local quad=equipQuads[branch];if not quad then return false end
    love.graphics.setColor(0,0,0,.32);love.graphics.ellipse("fill",cx,cy+35,42,9)
    love.graphics.setColor(1,1,1,1);love.graphics.draw(equip,quad,cx,cy,0,scale or .9,scale or .9,64,48)
    return true
end

function Art.drawProjectile(projectile)
    load();local age=projectile.age or projectile.t or 0
    if projectile.kind=="vape_gust" then
        local life=projectile.maxLife or .52;local index=frame(age,life,VAPE_PRESSURE_FRAMES)
        local fade=age<life*.80 and 1 or math.max(0,(life-age)/(life*.20))
        local scale=(projectile.range or 630)/VAPE_PRESSURE_W
        love.graphics.setColor(1,1,1,fade)
        love.graphics.draw(vapePressureFx,vapePressureQuads[index],projectile.x,projectile.y,projectile.angle or 0,scale,scale,82,VAPE_PRESSURE_H/2)
    elseif projectile.kind=="vape" then
        local index=frame(age,projectile.maxLife or .72);local angle=projectile.angle or 0
        love.graphics.setColor(1,1,1,math.max(0,1-age/(projectile.maxLife or .72)))
        love.graphics.draw(fx,fxQuads[1][index],projectile.x,projectile.y,angle,.58,.58,96,96)
    elseif projectile.kind=="firework" then
        local index=frame(age,projectile.dur or .55);local angle=projectile.angle or 0
        love.graphics.setColor(1,1,1,1);love.graphics.draw(fx,fxQuads[2][index],projectile.x,projectile.y,angle,.62,.62,96,96)
    elseif projectile.kind=="firework_burst" then
        local life=projectile.life or 1;local index=frame(age,life,BURST_FRAMES)
        local fade=age<life*.82 and 1 or math.max(0,(life-age)/(life*.18))
        love.graphics.setColor(1,1,1,fade)
        local scale=((projectile.radius or 180)*2)/BURST_CELL
        love.graphics.draw(burstFx,burstQuads[index],projectile.x,projectile.y,0,scale,scale,BURST_CELL/2,BURST_CELL/2)
    end
end

function Art.drawWindLeaf(leaf)
    load();local index=math.max(1,math.min(8,leaf.frame or 1));local fade=math.max(0,1-(leaf.age or 0)/(leaf.life or 1))
    love.graphics.setColor(1,1,1,math.min(1,fade*1.35))
    local scale=.36*(leaf.scale or 1)
    love.graphics.draw(vapeLeafFx,vapeLeafQuads[index],leaf.x,leaf.y,leaf.angle or 0,scale,scale,VAPE_LEAF_CELL/2,VAPE_LEAF_CELL/2)
end

function Art.assets()load();return{equipment=equip,fx=fx,fireworkBurst=burstFx,vapeCharge=vapeChargeFx,vapePressure=vapePressureFx,vapeLeaves=vapeLeafFx}end
return Art
