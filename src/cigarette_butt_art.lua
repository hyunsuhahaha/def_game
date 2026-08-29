local Butts=require("src.cigarette_butts")
local Art={}
local sprite,burnShader,fxShader
local function load()
    if sprite then return end
    sprite=love.graphics.newImage("assets/characters/ingame/smoker-cigarette-butt-pixel-v1.png")
    sprite:setFilter("nearest","nearest")
    burnShader=love.graphics.newShader("assets/shaders/cigarette-butt-burn.glsl")
    fxShader=love.graphics.newShader("assets/shaders/cigarette-ground-fx.glsl")
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
    for i=6,0,-1 do
        local q=math.max(0,p-i*.045)
        local x=transfer.x+(transfer.tx-transfer.x)*q
        local y=transfer.y+(transfer.ty-6-transfer.y)*q-math.sin(q*math.pi)*24
        local size=i==0 and 18 or (11-i*.65)
        fx(0,x,y+size/2,size,size,time,i==0 and 1.8 or (.9-i*.1))
    end
end

function Art.drawArrival(arrival,time)
    local p=math.max(0,math.min(1,(time-arrival.startAt)/.65))
    for i=1,5 do
        local a=i*2.4
        fx(0,arrival.x+math.cos(a)*p*32,arrival.y-6-math.abs(math.sin(a))*p*26,10,10,time,(1-p)*1.3)
    end
end

function Art.drawTreeFire(node,time)
    local age=node.cigaretteIgnitedAt and math.max(0,time-node.cigaretteIgnitedAt) or 1
    local grow=.35+.65*math.min(1,age/.45)
    fx(1,node.x,node.y+3,54*grow,86*grow,time,1)
    fx(1,node.x-15,node.y+4,28*grow,48*grow,time+.7,.85)
    fx(1,node.x+14,node.y+4,30*grow,60*grow,time+1.6,.9)
    fx(2,node.x,node.y-45,64,120,time,.6)
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
