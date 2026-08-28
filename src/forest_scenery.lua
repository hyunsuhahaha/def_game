-- Low forest dressing, independent of harvestable nodes and combat RNG.
-- First pass is visual: these props never block movement or change fire rules.
local Scenery={}
Scenery.catalog={
    rock={file="assets/scenery/forest/rock-pixel-v1.png",width=100,foot=.90,layer="actor"},
    fern={file="assets/scenery/forest/fern-pixel-v1.png",width=86,foot=.93,layer="actor"},
    leaves={file="assets/scenery/forest/leaves-pixel-v1.png",width=174,foot=.53,layer="ground"},
    log={file="assets/scenery/forest/log-pixel-v1.png",width=132,foot=.88,layer="actor"},
}
local images={}
local clearings={{.24,.43},{.76,.64}}
local zoneVariants={ridge={2,2,3,2,1},dry={4,4,1,4,3},hollow={3,1,3,1,2},woodland={1,1,2,3,4}}
local landmarks={
    {.12,.17,"rock"},{.38,.16,"rock"},{.73,.16,"rock"},
    {.24,.57,"log"},{.60,.38,"log"},{.15,.82,"fern"},
    {.40,.86,"fern"},{.82,.39,"log"},{.85,.80,"log"},
}

function Scenery.isSceneryPocket(x,y,w,h)
    for _,p in ipairs(landmarks) do
        -- Trees below a prop can hide it under their tall canopy. Reserve the
        -- projected canopy footprint, not only the tiny root collision point.
        local dx,dy=x-w*p[1],y-h*p[2]
        if math.abs(dx)<125 and dy>-65 and dy<205 then return true end
    end
    return false
end

function Scenery.zoneAt(x,y,w,h,stage)
    local phase=(stage or 1)*.7
    if y<h*.27+math.sin(x/310+phase)*70 then return "ridge" end
    if x>w*.64+math.sin(y/370+phase)*100 then return "dry" end
    if y>h*.70+math.sin(x/430+phase)*80 then return "hollow" end
    return "woodland"
end

function Scenery.isOpen(x,y,w,h)
    local dx,dy=x-w/2,y-h/2
    if dx*dx+dy*dy<260^2 then return true end
    -- Continuous traversable ribbons through the spawn, plus two side clearings.
    if math.abs(dx-math.sin(dy/380)*100)<58 then return true end
    if math.abs(dy-math.sin(dx/410)*85)<48 then return true end
    for _,p in ipairs(clearings) do
        if ((x-w*p[1])/140)^2+((y-h*p[2])/105)^2<1 then return true end
    end
    return false
end

function Scenery.treeVariant(x,y,w,h,stage,index,count)
    if count~=4 then return ((index-1)%count)+1 end
    local zone=Scenery.zoneAt(x,y,w,h,stage)
    local choices=zoneVariants[zone]
    return choices[((index-1)%#choices)+1]
end

function Scenery.generate(world,stage)
    local data={ground={},actors={},stage=stage or 1,zones={}}
    local seed=(17371+data.stage*7919)%2147483647
    local function random()
        seed=(seed*16807)%2147483647
        return (seed-1)/2147483646
    end
    local w,h=world.width,world.height
    local function nearRoot(x,y,radius)
        for _,node in ipairs(world.nodes) do
            if node.rushTree and (node.x-x)^2+(node.y-y)^2<radius^2 then return true end
        end
        return false
    end
    local function add(kind,x,y,zone,scaleOverride)
        if Scenery.isOpen(x,y,w,h) then return end
        local def=Scenery.catalog[kind]
        local size=scaleOverride or (.72+random()*.44)
        local radius=def.width*size*.55
        if x<radius or x>w-radius or y<70 or y>h-70 then return end
        if kind~="leaves" and nearRoot(x,y,kind=="fern" and 30 or 72) then return end
        if kind~="leaves" then
            for _,other in ipairs(data.actors) do
                local separation=(def.width*size+Scenery.catalog[other.kind].width*other.scale)*.36
                if (other.x-x)^2+(other.y-y)^2<separation^2 then return end
            end
        end
        local prop={kind=kind,x=x,y=y,scale=size,flip=random()<.5 and -1 or 1,
            angle=kind=="leaves" and (random()-.5)*.65 or 0,tone=.91+random()*.09,zone=zone}
        local list=def.layer=="ground" and data.ground or data.actors
        list[#list+1]=prop
        data.zones[zone]=(data.zones[zone] or 0)+1
    end
    -- Deliberately composed landmark clearings, then quieter scattered dressing.
    for _,p in ipairs(landmarks) do
        local x,y=w*p[1],h*p[2]
        local zone=Scenery.zoneAt(x,y,w,h,stage)
        add(p[3],x,y,zone,p[3]=="rock" and 1.35 or 1.25)
        add("fern",x-72,y+40,zone,.78)
        if p[3]=="rock" then add("rock",x+85,y+35,zone,.60)
        else add("fern",x+65,y+50,zone,.85) end
        add("leaves",x+12,y+12,zone,.95)
    end
    for gy=120,h-100,148 do
        for gx=120,w-100,148 do
            local x,y=gx+(random()-.5)*94,gy+(random()-.5)*94
            local zone=Scenery.zoneAt(x,y,w,h,stage)
            if not Scenery.isOpen(x,y,w,h) then
                local r=random()
                if zone=="ridge" then
                    if r<.68 then add("rock",x,y,zone) elseif r<.90 then add("fern",x,y,zone) end
                elseif zone=="dry" then
                    if r<.25 then add("log",x,y,zone) elseif r<.40 then add("rock",x,y,zone) end
                elseif zone=="hollow" then
                    if r<.68 then add("fern",x,y,zone) elseif r<.86 then add("log",x,y,zone) end
                else
                    if r<.36 then add("fern",x,y,zone) elseif r<.54 then add("log",x,y,zone) elseif r<.64 then add("rock",x,y,zone) end
                end
                if random()<(zone=="dry" and .88 or zone=="woodland" and .32 or .12) then
                    add("leaves",x,y+12,zone)
                end
            end
        end
    end
    world.forestScenery=data
    return data
end

local function draw(prop,player)
    local def=Scenery.catalog[prop.kind]
    local sprite=images[prop.kind]
    if not sprite then
        sprite=love.graphics.newImage(def.file);sprite:setFilter("nearest","nearest");images[prop.kind]=sprite
    end
    local scale=def.width/sprite:getWidth()*prop.scale
    -- Ground leaf patches stay muted; high props ghost near the player's feet.
    local alpha=1
    if player and prop.kind~="leaves" and math.abs(player.x-prop.x)<def.width*prop.scale*.55
        and player.y<prop.y and player.y>prop.y-48 then alpha=.48 end
    love.graphics.setColor(prop.tone,prop.tone,prop.tone,alpha)
    love.graphics.draw(sprite,prop.x,prop.y,prop.angle,scale*prop.flip,scale,sprite:getWidth()/2,sprite:getHeight()*def.foot)
end

function Scenery.drawGround(world)
    for _,prop in ipairs(world.forestScenery and world.forestScenery.ground or {}) do draw(prop) end
end

function Scenery.queue(world,queue,player)
    for _,entry in ipairs(world.forestScenery and world.forestScenery.actors or {}) do
        local prop=entry
        queue[#queue+1]={x=prop.x,y=prop.y,draw=function() draw(prop,player) end}
    end
end

return Scenery
