-- Selected concept A: high-density bale body with an authored 8-frame fire loop.
local Art={}
local body,fire,fireQuads
local BW,BH=320,288
local FW,FH,FRAMES=256,112,8
local BODY_SCALE=.55

local function load()
    if body then return end
    body=love.graphics.newImage("assets/fx/straw-bale/straw-bale-body-pixel-v5.png")
    body:setFilter("nearest","nearest")
    fire=love.graphics.newImage("assets/fx/straw-bale/straw-fire-a-atlas-pixel-v4.png")
    fire:setFilter("nearest","nearest")
    fireQuads={}
    for frame=0,FRAMES-1 do fireQuads[frame+1]=love.graphics.newQuad(frame*FW,0,FW,FH,fire:getDimensions()) end
end

local function drawBody(bale,alpha,squash)
    load();love.graphics.setColor(1,1,1,alpha or 1)
    local sx,sy=BODY_SCALE*(2-(squash or 1)),BODY_SCALE*(squash or 1)
    love.graphics.draw(body,math.floor(bale.x+.5),math.floor(bale.y+.5),0,sx,sy,BW/2,278)
end

local function drawFire(frame,x,y,sx,sy,alpha)
    love.graphics.setColor(1,1,1,alpha or 1)
    love.graphics.draw(fire,fireQuads[frame],math.floor(x+.5),math.floor(y+.5),0,sx,sy or sx,FW/2,106)
end

local function drawRange(bale,t,fade)
    local radius=bale.radius or 105
    local pulse=.82+.18*math.sin(t*5.2+(bale.variant or 0))
    love.graphics.setColor(1,.25,.035,.085*fade)
    love.graphics.ellipse("fill",bale.x,bale.y+3,radius,radius*.34)
    love.graphics.setLineWidth(2)
    love.graphics.setColor(1,.54,.12,.38*fade*pulse)
    love.graphics.ellipse("line",bale.x,bale.y+3,radius,radius*.34)
end

local function drawPrime(bale,t,p)
    for i=1,6 do
        local phase=t*5.0+i*2.17
        local x=bale.x+(i-3.5)*12+math.sin(phase)*3
        local y=bale.y-78-math.abs(math.sin(phase*.7))*10*p
        love.graphics.setColor(1,.28+.45*p,.035,.25+.65*p)
        love.graphics.rectangle("fill",math.floor(x),math.floor(y),i%2==0 and 3 or 2,i%3==0 and 4 or 3)
    end
end

local FALL_DUR,FALL_HEIGHT=.42,230

function Art.draw(bale,t)
    load();local previous={love.graphics.getColor()};t=t or 0
    local elapsed=bale.spawnedAt and (t-bale.spawnedAt) or FALL_DUR
    local dropY,squash=0,1
    if elapsed<FALL_DUR then
        local p=math.max(0,elapsed/FALL_DUR)
        dropY=-(1-p*p)*FALL_HEIGHT
        local shadowP=math.min(1,p*1.3)
        love.graphics.setColor(0,0,0,.30*shadowP)
        love.graphics.ellipse("fill",bale.x,bale.y+6,58*shadowP,17*shadowP)
        if p>.84 then squash=1-math.sin((p-.84)/.16*math.pi)*.22 end
    end
    local visual={x=bale.x,y=bale.y+dropY,radius=bale.radius,variant=bale.variant,
        ignited=bale.ignited,ignitedAt=bale.ignitedAt,primedAt=bale.primedAt,duration=bale.duration}
    if visual.ignited then
        local age=math.max(0,t-(visual.ignitedAt or t))
        local duration=visual.duration or 6
        local fade=math.min(1,age/.10)*math.min(1,math.max(0,(duration-age)/.55))
        local frame=math.floor(age*12)%FRAMES+1
        local front=(frame+2)%FRAMES+1
        drawRange(visual,t,fade)
        drawBody(visual,fade,squash)
        -- Both fire strips render over the bale. Different vertical anchors
        -- and frames preserve depth without hiding the flames behind the body.
        drawFire(frame,visual.x,visual.y-62,.76,.78,fade*.92)
        drawFire(front,visual.x,visual.y-31,.68,.62,fade*.94)
    elseif visual.primedAt then
        local p=math.min(1,math.max(0,(t-visual.primedAt)/.5))
        drawBody(visual,1,squash);drawPrime(visual,t,p)
    else
        drawBody(visual,1,squash)
    end
    love.graphics.setColor(unpack(previous))
end

return Art
