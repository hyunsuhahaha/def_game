-- Authored visuals only. Ignition delay and damage live in clearcut_mode.lua.
local Art={}
local image,quads
local W,H=128,224

local function load()
    if image then return end
    image=love.graphics.newImage("assets/fx/straw-bale/straw-bale-atlas-pixel-v3.png")
    image:setFilter("nearest","nearest")
    quads={}
    for row=0,1 do
        quads[row+1]={}
        for column=0,5 do quads[row+1][column+1]=love.graphics.newQuad(column*W,row*H,W,H,image:getDimensions()) end
    end
end

local function drawFrame(row,column,bale,alpha,scale)
    load();love.graphics.setColor(1,1,1,alpha or 1)
    love.graphics.draw(image,quads[row][column],math.floor(bale.x+.5),math.floor(bale.y+.5),0,scale or .60,scale or .60,W/2,214)
end

function Art.draw(bale,t)
    local previous={love.graphics.getColor()};t=t or 0
    if bale.ignited then
        local age=math.max(0,t-(bale.ignitedAt or t))
        local fade=math.min(1,age/.08)*math.min(1,math.max(0,(6-age)/.45))
        local frame=math.floor(age*11)%6+1
        drawFrame(2,frame,bale,fade,.60)
    elseif bale.primedAt then
        local p=math.min(1,math.max(0,(t-bale.primedAt)/.5))
        local frame=p<.45 and 3 or (p<.82 and 4 or 5)
        drawFrame(1,frame,bale,1,.60)
        if p>.82 then drawFrame(1,6,bale,(p-.82)/.18,.60) end
    else
        drawFrame(1,(bale.variant or 1)%2+1,bale,1,.60)
    end
    love.graphics.setColor(unpack(previous))
end

return Art
