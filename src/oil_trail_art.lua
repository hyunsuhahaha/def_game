-- Visuals only. Oil-road damage, duration and ignition remain in clearcut_mode.lua.
local Art={}
local image,quads
local CELL=128

local function load()
    if image then return end
    image=love.graphics.newImage("assets/fx/oil-trail/oil-trail-atlas-pixel-v2.png")
    image:setFilter("nearest","nearest")
    quads={}
    for row=0,1 do
        quads[row+1]={}
        for column=0,5 do
            quads[row+1][column+1]=love.graphics.newQuad(column*CELL,row*CELL,CELL,CELL,image:getDimensions())
        end
    end
end

local function drawFrame(row,column,x,y,angle,scale,alpha,ox,oy)
    load()
    love.graphics.setColor(1,1,1,alpha or 1)
    love.graphics.draw(image,quads[row][column],math.floor(x+.5),math.floor(y+.5),angle or 0,scale or 1,scale or 1,ox or CELL/2,oy or 116)
end

local function drawOilBase(spot,alpha)
    drawFrame(1,spot.variant or 1,spot.x,spot.y+2,(spot.angle or 0)-math.pi/2,.50,.88*(alpha or 1))
end

local function drawFlameBase(spot,t,alpha)
    local frame=(math.floor((t or 0)*9+(spot.sequence or 0))%3)+1
    drawFrame(2,frame,spot.x,spot.y+1,spot.angle or 0,.55,alpha or 1)
end

function Art.drawGround(spot,t)
    local previous={love.graphics.getColor()}
    local age=math.max(0,(t or 0)-(spot.spawnedAt or 0))
    local fade=spot.ignited and 1 or math.min(1,math.max(0,(6-age)/.55))
    local variant=spot.variant or 1
    drawOilBase(spot,fade)
    if not spot.ignited and age<.32 and (spot.sequence or 0)%3==0 then
        local p=age/.32
        drawFrame(1,5,spot.x,spot.y-1,0,.37*(1+p*.12),(1-p)*.92)
        drawFrame(1,6,spot.x+math.cos(spot.angle or 0)*5,spot.y-8-p*4,spot.angle or 0,.32,(1-p)*.85)
    end
    love.graphics.setColor(unpack(previous))
end


local function bridge(from,to,draw)
    local dx,dy=to.x-from.x,to.y-from.y
    local distance=math.sqrt(dx*dx+dy*dy)
    if distance<18 or distance>85 then return end
    local count=math.max(1,math.ceil(distance/17)-1)
    local angle=math.atan2(dy,dx)
    for index=1,count do
        local p=index/(count+1)
        draw({
            x=from.x+dx*p,y=from.y+dy*p,angle=angle,
            variant=((from.sequence or 1)+index-1)%3+1,
            sequence=(from.sequence or 0)+index*.31,
            spawnedAt=from.spawnedAt+(to.spawnedAt-from.spawnedAt)*p,
            ignited=from.ignited and to.ignited,
            ignitedAt=from.ignitedAt and to.ignitedAt and (from.ignitedAt+(to.ignitedAt-from.ignitedAt)*p) or nil
        })
    end
end

function Art.drawGroundBridge(from,to,t)
    local previous={love.graphics.getColor()}
    bridge(from,to,function(spot) drawOilBase(spot,1) end)
    love.graphics.setColor(unpack(previous))
end

function Art.drawFlame(spot,t)
    if not spot.ignited then return end
    local previous={love.graphics.getColor()}
    local age=math.max(0,(t or 0)-(spot.ignitedAt or t or 0))
    local fade=math.min(1,age/.12)*math.min(1,math.max(0,(5-age)/.55))
    drawFlameBase(spot,t,fade)
    if age<.30 then
        local p=age/.30
        drawFrame(2,4,spot.x,spot.y-2,0,.48+p*.10,(1-p)*fade)
        drawFrame(2,6,spot.x,spot.y-11-p*7,0,.40,(1-p)*fade)
    end
    if (spot.sequence or 0)%4==0 then
        local drift=math.sin((t or 0)*2.1+(spot.sequence or 0)) * 4
        drawFrame(2,5,spot.x+drift,spot.y-13-age*2,0,.42,.48*fade)
    end
    love.graphics.setColor(unpack(previous))
end


function Art.drawFlameBridge(from,to,t)
    if not (from.ignited and to.ignited) then return end
    local previous={love.graphics.getColor()}
    bridge(from,to,function(spot)
        local age=math.max(0,(t or 0)-(spot.ignitedAt or t or 0))
        local fade=math.min(1,age/.12)*math.min(1,math.max(0,(5-age)/.55))
        drawFlameBase(spot,t,fade)
    end)
    love.graphics.setColor(unpack(previous))
end

return Art
