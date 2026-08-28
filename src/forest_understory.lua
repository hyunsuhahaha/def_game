local Understory={}

local CELL_W,CELL_H=128,96
local image,quads

local function ensureArt()
    if image then return end
    image=love.graphics.newImage("assets/scenery/forest/grass-understory-atlas-pixel-v1.png")
    image:setFilter("nearest","nearest")
    quads={}
    for frame=0,3 do quads[frame+1]=love.graphics.newQuad(frame*CELL_W,0,CELL_W,CELL_H,image:getDimensions()) end
end

local function eligible(world)
    return world and (world.clearcutMap=="forest" or world.clearcutMap=="beginner")
end

function Understory.generate(world,stage)
    local data={patches={},soundCooldown=0,stage=stage or 1}
    world.forestUnderstory=data
    if not eligible(world) then return data end
    local seed=(91733+data.stage*10657)%2147483647
    local function random()
        seed=(seed*16807)%2147483647
        return (seed-1)/2147483646
    end
    local w,h=world.width,world.height
    for gy=86,h-70,104 do
        for gx=76,w-70,112 do
            if random()<.58 then
                local x=gx+(random()-.5)*72
                local y=gy+(random()-.5)*58
                local dx,dy=x-w/2,y-h/2
                -- Keep the immediate arrival circle readable, then let grass
                -- cross the wider walking lanes so traversal can disturb it.
                if dx*dx+dy*dy>175^2 then
                    data.patches[#data.patches+1]={x=x,y=y,scale=.66+random()*.26,
                        flip=random()<.5 and -1 or 1,rustle=0,bend=0,cut=false,cutPulse=0}
                end
            end
        end
    end
    return data
end

function Understory.update(world,player,dt,game)
    local data=world and world.forestUnderstory
    if not data or not player then return end
    data.soundCooldown=math.max(0,(data.soundCooldown or 0)-dt)
    local oldX,oldY=data.playerX or player.x,data.playerY or player.y
    local mx,my=player.x-oldX,player.y-oldY
    local moving=mx*mx+my*my>.04 or player.isMoving
    data.playerX,data.playerY=player.x,player.y
    for _,patch in ipairs(data.patches) do
        patch.rustle=math.max(0,(patch.rustle or 0)-dt)
        patch.cutPulse=math.max(0,(patch.cutPulse or 0)-dt)
        if not patch.cut and moving then
            local dx,dy=player.x-patch.x,player.y-patch.y
            if math.abs(dx)<48*patch.scale and math.abs(dy)<24*patch.scale then
                patch.rustle=.34
                patch.bend=(math.abs(mx)>.02 and mx or (dx>=0 and 1 or -1))>=0 and 1 or -1
                if data.soundCooldown<=0 and game and game.feedback then
                    game.feedback:play("grass",false)
                    data.soundCooldown=.13
                end
            end
        end
    end
end

function Understory.cutRadius(world,x,y,radius,game)
    local data=world and world.forestUnderstory
    if not data then return 0 end
    local cut=0
    for _,patch in ipairs(data.patches) do
        if not patch.cut then
            local dx,dy=patch.x-x,(patch.y-y)*1.35
            if dx*dx+dy*dy<=radius*radius then
                patch.cut,patch.rustle,patch.cutPulse=true,0,.24
                cut=cut+1
                if world.addLeafParticle then
                    for _=1,3 do world:addLeafParticle(patch.x,patch.y-14) end
                end
            end
        end
    end
    if cut>0 and game and game.feedback then game.feedback:play("grass",true) end
    return cut
end

local function drawPatch(patch,player)
    ensureArt()
    local frame=1
    if patch.cut then frame=4 elseif patch.rustle>0 then frame=patch.bend<0 and 2 or 3 end
    local alpha=1
    if player and not patch.cut and player.y<patch.y and player.y>patch.y-34
        and math.abs(player.x-patch.x)<42 then alpha=.72 end
    local pulse=1+(patch.cutPulse or 0)*.18
    love.graphics.setColor(1,1,1,alpha)
    love.graphics.draw(image,quads[frame],patch.x,patch.y,0,
        patch.scale*patch.flip*pulse,patch.scale*pulse,CELL_W/2,CELL_H*.91)
end

function Understory.queue(world,queue,player)
    local data=world and world.forestUnderstory
    if not data then return end
    for _,entry in ipairs(data.patches) do
        local patch=entry
        queue[#queue+1]={x=patch.x,y=patch.y-1,anchorY=patch.y,draw=function() drawPatch(patch,player) end}
    end
end

return Understory
