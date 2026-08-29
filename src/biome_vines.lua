-- World-space vine vegetation. These are depth-sorted actors attached to trees
-- or rooted in the ground; nothing in this module is drawn in screen space.
local Maps=require("src.clearcut_maps")
local Scenery=require("src.forest_scenery")
local Vines={}

local CELL_W,CELL_H,FRAMES=160,224,6
local image,quads
local profiles={
    forest={attached=12,ground=8,tint={.78,.88,.68}},
    beginner={attached=4,ground=3,tint={.84,.91,.72}},
    mangrove={attached=18,ground=12,tint={.64,.86,.72}},
    madagascar={attached=7,ground=5,tint={.82,.78,.55}},
    island={attached=12,ground=10,tint={.74,.90,.62}},
    greatforest={attached=30,ground=22,tint={.64,.84,.56}},
}

local function ensureArt()
    if image then return end
    image=love.graphics.newImage("assets/scenery/biomes/world-vines-atlas-pixel-v1.png")
    image:setFilter("nearest","nearest")
    quads={}
    for frame=1,FRAMES do quads[frame]=love.graphics.newQuad((frame-1)*CELL_W,0,CELL_W,CELL_H,image:getDimensions()) end
end

local function mapSeed(id,stage)
    local seed=23011+(stage or 1)*7919
    for index=1,#id do seed=(seed*33+id:byte(index)*index)%2147483647 end
    return seed
end

function Vines.generate(world,stage)
    local id=world.clearcutMap or "forest"
    local profile=profiles[id] or profiles.forest
    local data={attached={},ground={},profile=profile,stage=stage or 1,rustleCooldown=0,lastPlayerX=nil}
    local seed=mapSeed(id,stage)
    local function random()
        seed=(seed*16807)%2147483647
        return (seed-1)/2147483646
    end
    local trees={}
    for _,node in ipairs(world.nodes or {}) do if node.rushTree then trees[#trees+1]=node end end
    local attachTarget=math.min(profile.attached+math.max(0,(stage or 1)-1)*2,math.floor(#trees*.16+.5))
    local step=math.max(1,math.floor(#trees/math.max(1,attachTarget)))
    local cursor=1+math.floor(random()*step)
    while #data.attached<attachTarget and cursor<=#trees do
        local node=trees[cursor]
        if not node.giantTree then
            data.attached[#data.attached+1]={node=node,frame=random()<.5 and 1 or 2,
                offsetX=math.floor((random()-.5)*18),scale=.78+random()*.20,
                flip=random()<.5 and -1 or 1,phase=random()*math.pi*2}
        end
        cursor=cursor+step
    end
    local groundTarget=math.min(profile.ground+math.max(0,(stage or 1)-1),math.floor(#trees*.12+.5))
    local attempts=0
    while #data.ground<groundTarget and attempts<groundTarget*20 and #trees>0 do
        attempts=attempts+1
        local node=trees[1+math.floor(random()*#trees)]
        local angle=random()*math.pi*2
        local radius=72+random()*105
        local x,y=node.x+math.cos(angle)*radius,node.y+math.sin(angle)*radius*.72
        local valid=Maps.canPlant(world,x,y) and not Scenery.isOpen(x,y,world.width,world.height)
        for _,patch in ipairs(data.ground) do
            if (patch.x-x)^2+(patch.y-y)^2<105^2 then valid=false;break end
        end
        if valid then
            data.ground[#data.ground+1]={x=x,y=y,scale=.68+random()*.20,flip=random()<.5 and -1 or 1,
                rustle=0,bend=1,cut=false,phase=random()*math.pi*2}
        end
    end
    world.biomeVines=data
    return data
end

function Vines.update(world,player,dt,game)
    local data=world and world.biomeVines
    if not data then return end
    data.rustleCooldown=math.max(0,(data.rustleCooldown or 0)-dt)
    local previousX=data.lastPlayerX or (player and player.x or 0)
    for _,patch in ipairs(data.ground) do
        patch.rustle=math.max(0,(patch.rustle or 0)-dt)
        if player and player.isMoving and not patch.cut and math.abs(player.x-patch.x)<48
            and player.y>patch.y-30 and player.y<patch.y+22 then
            patch.rustle=.26;patch.bend=player.x>=previousX and 1 or -1
            if data.rustleCooldown<=0 and game and game.feedback then
                game.feedback:play("grass",true);data.rustleCooldown=.24
            end
        end
    end
    if player then data.lastPlayerX=player.x end
end

function Vines.cutRadius(world,x,y,radius,game)
    local data=world and world.biomeVines
    if not data then return 0 end
    local cut=0
    for _,patch in ipairs(data.ground) do
        if not patch.cut then
            local dx,dy=patch.x-x,(patch.y-y)*1.35
            if dx*dx+dy*dy<=radius*radius then
                patch.cut,patch.rustle=true,0;cut=cut+1
                if world.addLeafParticle then for _=1,4 do world:addLeafParticle(patch.x,patch.y-18) end end
            end
        end
    end
    return cut
end

local function drawAttached(entry,profile,time)
    local node=entry.node
    if not node.active or node.fallT then return end
    ensureArt()
    local sway=math.sin(time*.72+entry.phase)*.009+(node.swayAngle or 0)*.34
    local alpha=node.burning and .70 or .94
    love.graphics.setColor(profile.tint[1],profile.tint[2],profile.tint[3],alpha)
    love.graphics.draw(image,quads[entry.frame],node.x+entry.offsetX,node.y,sway,
        entry.scale*entry.flip,entry.scale,CELL_W/2,CELL_H*.94)
end

local function drawGround(patch,profile,player)
    ensureArt()
    local frame=patch.cut and 6 or ((patch.rustle or 0)>0 and (patch.bend<0 and 4 or 5) or 3)
    local alpha=.96
    if player and not patch.cut and player.y<patch.y and player.y>patch.y-42 and math.abs(player.x-patch.x)<58 then alpha=.58 end
    love.graphics.setColor(profile.tint[1],profile.tint[2],profile.tint[3],alpha)
    love.graphics.draw(image,quads[frame],patch.x,patch.y,0,
        patch.scale*patch.flip,patch.scale,CELL_W/2,CELL_H*.94)
end

function Vines.queue(world,queue,player,time)
    local data=world and world.biomeVines
    if not data then return end
    for _,value in ipairs(data.attached) do local entry=value
        local node=entry.node
        queue[#queue+1]={x=node.x,y=node.y+.02,anchorY=node.y,sortBias=.02,
            draw=function() drawAttached(entry,data.profile,time) end}
    end
    for _,value in ipairs(data.ground) do local patch=value
        queue[#queue+1]={x=patch.x,y=patch.y,anchorY=patch.y,
            draw=function() drawGround(patch,data.profile,player) end}
    end
end

return Vines
