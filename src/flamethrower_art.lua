-- Authored, upright-safe pixel art for the score-mode flamethrower.
local Art={}
local streamImage,equipmentImage,streamQuads
local CELL_W,CELL_H,FRAMES=1536,768,8
local SOURCE_REACH,SOURCE_HALF=1480,220

local function load()
    if streamImage then return end
    streamImage=love.graphics.newImage("assets/effects/smoker-flamethrower-stream-atlas-v4.png")
    equipmentImage=love.graphics.newImage("assets/effects/smoker-flamethrower-equipment-v1.png")
    streamImage:setFilter("nearest","nearest");equipmentImage:setFilter("nearest","nearest")
    streamQuads={}
    for index=0,FRAMES-1 do
        streamQuads[index+1]=love.graphics.newQuad((index%4)*CELL_W,math.floor(index/4)*CELL_H,CELL_W,CELL_H,CELL_W*4,CELL_H*2)
    end
end

local function atan2(y,x)
    if math.atan2 then return math.atan2(y,x)end
    if x>0 then return math.atan(y/x)end
    if x<0 and y>=0 then return math.atan(y/x)+math.pi end
    if x<0 then return math.atan(y/x)-math.pi end
    return y>=0 and math.pi*.5 or -math.pi*.5
end

function Art.drawHeld(mode,game)
    load()
    local player=game.player;local facing=player.facing or 1
    local active=mode.flameStream~=nil
    local recoil=active and(3+math.sin((mode.flameStream.t or 0)*28)*2)or 0
    local x,y=player.x-facing*(30+recoil),player.y-75
    love.graphics.setColor(0,0,0,.26)
    love.graphics.ellipse("fill",player.x-facing*21,player.y+5,32,7)
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(equipmentImage,x,y,0,.24*facing,.24,0,0)
    return true
end

function Art.drawStream(stream)
    if not stream then return false end
    load()
    local time=stream.t or 0
    local frame=math.floor(time*16)%FRAMES+1
    -- The gameplay stream lives on the ground plane. Upright FX compensate for
    -- camera pitch while preserving the authored pressured forward jet.
    local angle=atan2((stream.ny or 0)*.62,stream.nx or 1)
    local halfWidth=(stream.halfWidth or 72)*.62
    local visualReach=stream.visualReach or stream.reach or 250
    local scaleX=visualReach/SOURCE_REACH
    local pressure=1+math.sin(time*38)*.035
    local scaleY=math.max(.24,halfWidth/SOURCE_HALF*1.25)*pressure
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(streamImage,streamQuads[frame],stream.x,stream.y,angle,scaleX,scaleY,30,410)
    love.graphics.setColor(1,1,1,1)
    love.graphics.setBlendMode("alpha")
    return true
end

function Art.assets()
    load();return{stream=streamImage,equipment=equipmentImage}
end

return Art
