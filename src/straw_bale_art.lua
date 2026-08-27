-- High-density bale body + continuous multi-layer flame rendering.
local Art={}
local body,fireField,fireShader
local BW,BH=320,288
local BODY_SCALE=.55

local function load()
    if body then return end
    body=love.graphics.newImage("assets/fx/straw-bale/straw-bale-body-pixel-v4.png")
    body:setFilter("nearest","nearest")
    fireField=love.graphics.newImage("assets/fx/straw-bale/straw-bale-atlas-pixel-v3.png")
    fireField:setFilter("nearest","nearest")
    fireShader=love.graphics.newShader("assets/shaders/straw-bale-fire.glsl")
end

local function drawBody(bale,alpha)
    load();love.graphics.setColor(1,1,1,alpha or 1)
    love.graphics.draw(body,math.floor(bale.x+.5),math.floor(bale.y+.5),0,BODY_SCALE,BODY_SCALE,BW/2,278)
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

local function flameLayer(bale,t,x,y,w,h,layer,alpha,variant)
    load();local previous=love.graphics.getShader()
    love.graphics.setShader(fireShader)
    fireShader:send("fireGrid",{math.floor(w*.50),math.floor(h*.50)})
    fireShader:send("fireTime",t);fireShader:send("intensity",alpha)
    fireShader:send("variant",variant or bale.variant or 0);fireShader:send("fireLayer",layer)
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(fireField,x-w/2,y-h,0,w/fireField:getWidth(),h/fireField:getHeight())
    love.graphics.setShader(previous)
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

function Art.draw(bale,t)
    load();local previous={love.graphics.getColor()};t=t or 0
    if bale.ignited then
        local age=math.max(0,t-(bale.ignitedAt or t))
        local fade=math.min(1,age/.12)*math.min(1,math.max(0,(6-age)/.55))
        drawRange(bale,t,fade)
        flameLayer(bale,t,bale.x-50,bale.y-57,92,136,0,fade*.88,(bale.variant or 0)+.3)
        flameLayer(bale,t+.21,bale.x,bale.y-61,104,190,0,fade,(bale.variant or 0)+1.1)
        flameLayer(bale,t+.43,bale.x+52,bale.y-55,90,148,0,fade*.90,(bale.variant or 0)+2.4)
        drawBody(bale,fade)
        flameLayer(bale,t+.12,bale.x-62,bale.y-30,68,92,1,fade*.82,(bale.variant or 0)+3.0)
        flameLayer(bale,t+.31,bale.x-23,bale.y-38,78,126,1,fade*.94,(bale.variant or 0)+4.2)
        flameLayer(bale,t+.50,bale.x+23,bale.y-39,78,112,1,fade*.92,(bale.variant or 0)+5.5)
        flameLayer(bale,t+.68,bale.x+61,bale.y-28,68,88,1,fade*.80,(bale.variant or 0)+6.8)
    elseif bale.primedAt then
        local p=math.min(1,math.max(0,(t-bale.primedAt)/.5))
        drawBody(bale,1);drawPrime(bale,t,p)
    else
        drawBody(bale,1)
    end
    love.graphics.setColor(unpack(previous))
end

return Art
