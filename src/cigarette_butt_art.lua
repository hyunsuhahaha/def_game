local Butts=require("src.cigarette_butts")
local Art={}
local sprite,burnShader,fxShader,impactAtlas,impactQuads,treeFireAtlas,treeFireQuads
local function load()
    if sprite and impactAtlas and treeFireAtlas then return end
    sprite=love.graphics.newImage("assets/characters/ingame/smoker-cigarette-butt-pixel-v1.png")
    sprite:setFilter("nearest","nearest")
    impactAtlas=love.graphics.newImage("assets/fx/cigarette-impact-atlas-pixel-v1.png")
    impactAtlas:setFilter("nearest","nearest")
    impactQuads={landing={},ignition={}}
    for frame=0,9 do
        impactQuads.landing[frame+1]=love.graphics.newQuad(frame*160,0,160,160,1600,320)
        impactQuads.ignition[frame+1]=love.graphics.newQuad(frame*160,160,160,160,1600,320)
    end
    treeFireAtlas=love.graphics.newImage("assets/fx/tree-fire-loop-atlas-pixel-v3.png")
    treeFireAtlas:setFilter("nearest","nearest")
    treeFireQuads={}
    for frame=0,19 do treeFireQuads[frame+1]=love.graphics.newQuad(frame*320,0,320,320,6400,320) end
    burnShader=love.graphics.newShader("assets/shaders/cigarette-butt-burn.glsl")
    fxShader=love.graphics.newShader("assets/shaders/cigarette-ground-fx.glsl")
end

local function impactFrame(kind,event,time,duration,scale,baseY)
    load()
    local p=math.max(0,math.min(.999,(time-event.startAt)/duration))
    local frame=math.min(10,math.floor(p*10)+1)
    local previous=love.graphics.getShader()
    love.graphics.setShader()
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(impactAtlas,impactQuads[kind][frame],event.x,event.y,0,scale,scale,80,baseY)
    love.graphics.setShader(previous)
end

function Art.drawLandingImpact(impact,time)
    impactFrame("landing",impact,time,.42,.50,104)
end
local function fx(kind,x,y,w,h,time,strength)
    load()
    local previous=love.graphics.getShader()
    love.graphics.setShader(fxShader)
    fxShader:send("fxKind",kind);fxShader:send("fxTime",time)
    fxShader:send("fxGrid",{math.ceil(w*3.2),math.ceil(h*3.2)})
    fxShader:send("strength",strength)
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(sprite,x-w/2,y-h,0,w/256,h/64)
    love.graphics.setShader(previous)
end
local function body(x,y,angle,progress,heat,time,alpha,scale)
    load()
    local previous=love.graphics.getShader()
    love.graphics.setShader(burnShader)
    burnShader:send("burnProgress",progress);burnShader:send("heat",heat);burnShader:send("emberTime",time)
    love.graphics.setColor(1,1,1,alpha or 1)
    scale=scale or 1
    love.graphics.draw(sprite,x,y,angle,32/256*scale,32/256*scale,128,32)
    love.graphics.setShader(previous)
end

function Art.drawGround(butt,time)
    local age=math.max(0,time-butt.bornAt)
    local progress=math.min(1,age/Butts.lifetime)
    local hot=butt.phase=="smolder"
    local alpha=hot and 1 or math.max(0,(butt.coldUntil-time)/Butts.coldLifetime)
    local bounce=age<.28 and math.sin(age/.28*math.pi)*4 or 0
    love.graphics.setColor(.09,.065,.035,.40*alpha)
    love.graphics.ellipse("fill",butt.x,butt.y+3,18,3)
    body(butt.x,butt.y-bounce,butt.angle,progress,hot and 1 or 0,time,alpha)
    -- A compact segmented fuel indicator communicates remaining lifetime.
    for i=0,6 do
        local active=hot and (1-progress)*7>i
        love.graphics.setColor(active and .94 or .27,active and .52 or .26,active and .17 or .21,.85*alpha)
        love.graphics.rectangle("fill",butt.x-13+i*4,butt.y+10,3,2)
    end
end

function Art.drawSmolder(butt,time)
    if butt.phase~="smolder" then return end
    local age=math.max(0,time-butt.bornAt)
    local tipX,tipY=Butts.tip(butt,time)
    local pulse=math.max(0,1-(time-(butt.lastAttemptAt or -10))/.32)
    fx(2,tipX,tipY,40,82,time,.75+.25*(1-age/Butts.lifetime))
    fx(0,tipX,tipY+13,26,26,time,1+pulse*.7)
    if butt.wildfire then fx(1,tipX,tipY+8,32,50,time,.5) end
    -- Small local flecks on attempts, never a fake link to an unlit tree.
    if pulse>0 then
        for i=1,3 do
            local along=1-pulse
            fx(0,tipX+math.sin(i*2.1)*along*17,tipY-along*(10+i*5)+4,8,8,time,pulse)
        end
    end
end

function Art.drawTransfer(transfer,time)
    local p=math.max(0,math.min(1,(time-transfer.startAt)/transfer.duration))
    local treeSpread=transfer.treeSpread
    for i=treeSpread and 8 or 6,0,-1 do
        local q=math.max(0,p-i*.045)
        local x=transfer.x+(transfer.tx-transfer.x)*q
        local y=transfer.y+(transfer.ty-6-transfer.y)*q-math.sin(q*math.pi)*24
        local size=i==0 and (treeSpread and 25 or 18) or ((treeSpread and 14 or 11)-i*.65)
        fx(0,x,y+size/2,size,size,time,i==0 and (treeSpread and 2.35 or 1.8) or (.95-i*.075))
    end
    if treeSpread and p<.42 then
        local burst=1-p/.42
        local angle=math.atan2(transfer.ty-transfer.y,transfer.tx-transfer.x)
        for i=1,4 do
            local a=angle+(i-2.5)*.42
            local travel=(1-burst)*(23+i*6)
            fx(0,transfer.x+math.cos(a)*travel,transfer.y-8+math.sin(a)*travel*.55,
                9+i%2*3,9+i%2*3,time+i*.19,burst*(1.45-i*.12))
        end
    end
end

function Art.drawArrival(arrival,time)
    impactFrame("ignition",arrival,time,arrival.duration or .72,
        arrival.scale or (arrival.targetKind=="enemy" and .48 or .64),127)
end

function Art.drawTreeFire(node,time)
    load()
    local age=node.cigaretteIgnitedAt and math.max(0,time-node.cigaretteIgnitedAt) or 1
    local grow=.35+.65*math.min(1,age/.45)
    local seedPhase=((node.x or 0)*.013+(node.y or 0)*.007)%1
    local frame=math.floor((time*14+seedPhase*20)%20)+1
    local previous=love.graphics.getShader()
    love.graphics.setShader()
    local previousBlend=love.graphics.getBlendMode and love.graphics.getBlendMode()or"alpha"
    love.graphics.setBlendMode("add")
    love.graphics.setColor(1,.32,.04,.16)
    love.graphics.draw(treeFireAtlas,treeFireQuads[frame],math.floor(node.x+.5),math.floor(node.y+5.5),
        0,.425*grow,.425*grow,160,286)
    love.graphics.setBlendMode(previousBlend)
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(treeFireAtlas,treeFireQuads[frame],math.floor(node.x+.5),math.floor(node.y+5.5),
        0,.40*grow,.40*grow,160,286)
    love.graphics.setShader(previous)
    fx(2,node.x,node.y-48,76,138,time+.4,.72)
end

function Art.drawEnemyFire(enemy,time)
    if not enemy.burning then return end
    local radius=(enemy.def and enemy.def.radius) or 24
    local age=math.max(0,time-(enemy.fireIgnitedAt or time))
    local duration=enemy.burnDuration or 4
    local grow=.35+.65*math.min(1,age/.35)
    local fade=math.min(1,math.max(0,(duration-(enemy.burnTimer or 0))/.3))
    local count=radius>=120 and 7 or (radius>=50 and 3 or 2)
    local spread=math.min(245,radius*.72)
    local flameW=math.min(105,math.max(30,radius*.62))*grow
    local flameH=math.min(175,math.max(58,radius*1.05))*grow
    for i=1,count do
        local q=count==1 and 0 or (i-1)/(count-1)-.5
        local lift=radius>=120 and ((i-1)%3)*68 or ((i-1)%2)*radius*.28
        local x=enemy.x+q*spread*2
        local y=enemy.y-lift+3
        local phase=i*.71+(enemy.seed or 0)
        fx(1,x,y,flameW*(.82+(i%3)*.09),flameH*(.82+(i%2)*.14),time+phase,fade)
    end
    local smokeWidth=math.min(280,math.max(56,radius*1.25))
    local smokeHeight=math.min(300,math.max(105,radius*1.6))
    fx(2,enemy.x,enemy.y-math.min(190,radius*.72),smokeWidth,smokeHeight,time+.4,.52*fade)
end

function Art.drawFlight(flight,time)
    local x,y,p=Butts.flightPosition(flight)
    local fall=Butts.fallProgress(flight)
    local scale=1-fall*.58
    local angle=(flight.landingAngle or .25)-(1-p)*math.pi*4-fall*math.pi*7
    body(x,y,angle,0,1,time,1,scale)
    local tipX,tipY=x+math.cos(angle)*15.4*scale,y+math.sin(angle)*15.4*scale
    fx(0,tipX,tipY+9*scale,18*scale,18*scale,time,(flight.wildfire and 2.2 or 1.5)*(1-fall*.55))
    -- 산불 융합 전용 투척: 그냥 담뱃불이 아니라 궤적 뒤로 불타는 꼬리를 남긴다.
    if flight.wildfire then
        for i=1,4 do
            local q=math.max(0,p-i*.05)
            local tx,ty=Butts.flightPosition(flight,q*flight.dur)
            fx(1,tx,ty+8,26-i*3,40-i*5,time+i*.13,.85-i*.14)
        end
    end
end

return Art
