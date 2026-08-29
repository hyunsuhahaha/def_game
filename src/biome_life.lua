-- Ambient wildlife and signature plants; never enemies, harvest goals or loot.
local Maps=require("src.clearcut_maps")
local Life={}
Life.catalog={
    parrot={file="assets/scenery/biomes/parrot-pixel-v1.png",width=58,foot=.65,air=true},
    lemur={file="assets/scenery/biomes/lemur-pixel-v1.png",width=66,foot=.91},
    crab={file="assets/scenery/biomes/crab-pixel-v1.png",width=36,foot=.91},
    traveller={file="assets/scenery/biomes/traveller-pixel-v1.png",width=152,foot=.91,plant=true},
}
local images={}
local function image(kind)
    if not images[kind] then
        images[kind]=love.graphics.newImage(Life.catalog[kind].file);images[kind]:setFilter("nearest","nearest")
    end
    return images[kind]
end
local function uncovered(world,x,y)
    for _,n in ipairs(world.nodes) do
        if math.abs(n.x-x)<100 and n.y>y-20 and n.y<y+180 then return false end
    end
    return true
end
function Life.generate(world,stage)
    local data={items={},time=0};world.biomeLife=data
    local id=world.clearcutMap
    if not id or id=="forest" then return data end
    local seed=31771+(stage or 1)*11939+Maps.get(id).index*751
    local function random() seed=(seed*16807)%2147483647;return (seed-1)/2147483646 end
    local w,h=world.width,world.height
    local function add(kind,x,y)
        local def=Life.catalog[kind]
        if not Maps.insideSpawnTerrain(world,x,y,28) then return false end
        if def.plant and not Maps.insideGroundPlants(world,x,y) then return false end
        data.items[#data.items+1]={kind=kind,x=x,y=y,homeX=x,homeY=y,phase=random()*6.283,
            facing=random()<.5 and -1 or 1,scale=.88+random()*.24,air=def.air}
        return true
    end
    if id=="mangrove" then
        for i=1,22 do
            local y=160+(h-320)*i/23
            local x=w*.32+math.sin(y/240)*110+(i%2==0 and 88 or -88)
            add("crab",x,y)
        end
        -- Indo-Pacific mangroves: do not reuse the American macaw model here.
        -- Collared kingfishers are a researched candidate, not implemented art.
    elseif id=="madagascar" then
        -- A fan-leaf grove frames the start without covering its central combat lane.
        for _,p in ipairs({{-260,-90},{290,-120},{-310,130},{320,160},{-185,-215},{180,-230}}) do
            add("traveller",w/2+p[1],h/2+p[2])
        end
        for i=1,400 do
            local x,y=130+random()*(w-260),150+random()*(h-300)
            if uncovered(world,x,y) and math.abs(x-w/2)>75 then
                add(i%3==0 and "traveller" or "lemur",x,y)
                if #data.items>=32 then break end
            end
        end
        add("lemur",w/2-125,h/2+40);add("lemur",w/2+155,h/2-30)
    elseif id=="island" then
        for i=1,28 do
            local a=i/28*math.pi*2
            local r=(1+.065*math.sin(a*3+.4)+.035*math.cos(a*5))*.94
            add("crab",w/2+Maps.island.radiusX*r*math.cos(a),h/2+Maps.island.radiusY*r*math.sin(a))
        end
        for _,p in ipairs({{-.52,-.23},{.52,-.10},{-.23,.47},{.48,.60},{-.60,.43},{.10,-.57}}) do
            add("parrot",w/2+p[1]*Maps.island.radiusX,h/2+p[2]*Maps.island.radiusY)
            add("parrot",w/2-p[1]*Maps.island.radiusX*.85,h/2-p[2]*Maps.island.radiusY*.85)
        end
    end
    return data
end
function Life.update(world,dt)
    local data=world.biomeLife;if not data then return end
    data.time=data.time+dt
    for _,p in ipairs(data.items) do
        local t=data.time
        if p.startle and p.startle>0 then
            p.startle=p.startle-dt;p.x=p.x+(p.startleVX or 0)*dt;p.y=p.y+(p.startleVY or 0)*dt
            p.startleVX=(p.startleVX or 0)*math.exp(-dt*(p.air and .3 or 1.4))
            if p.air then p.startleVY=(p.startleVY or 0)-18*dt
            else p.startleVY=(p.startleVY or 0)*math.exp(-dt*1.4);p.x,p.y=Maps.constrain(world,p.x,p.y,12)end
            p.facing=(p.startleVX or 0)>=0 and 1 or -1
            if p.startle<=0 then p.homeX,p.homeY,p.startle=p.x,p.y,nil end
        elseif p.kind=="parrot" then
            local a=t*.35+p.phase
            p.x=p.homeX+math.sin(a)*125;p.y=p.homeY+math.cos(a*.8)*42
            p.facing=math.cos(a)>=0 and 1 or -1
        elseif p.kind=="lemur" or p.kind=="crab" then
            local a=t*(p.kind=="lemur" and .7 or .4)+p.phase
            local radius=p.kind=="lemur" and 25 or 9
            p.x=p.homeX+math.sin(a)*radius;p.y=p.homeY+math.cos(a*1.3)*5
            p.x,p.y=Maps.constrain(world,p.x,p.y,12)
            p.facing=math.cos(a)>=0 and 1 or -1
        end
        p.x,p.y=Maps.constrain(world,p.x,p.y,28)
    end
end
function Life.startle(world,x,y,radius)
    local data=world.biomeLife;if not data then return 0 end
    local count=0;radius=radius or 520
    for _,p in ipairs(data.items)do if not Life.catalog[p.kind].plant then
        local dx,dy=p.x-x,p.y-y;local distance=math.sqrt(dx*dx+dy*dy)
        if distance<radius then
            if distance<1 then dx,dy,distance=(p.phase or 0)>.5 and 1 or -1,-.4,1 end
            local speed=p.air and 310 or (p.kind=="lemur" and 230 or 150)
            p.startle=1.9+(p.phase%1)*.7;p.startleVX=dx/distance*speed;p.startleVY=(p.air and -180 or dy/distance*speed*.48)
            count=count+1
        end
    end end
    return count
end
local function draw(p,time,player)
    local def=Life.catalog[p.kind];local sprite=image(p.kind)
    local scale=def.width/sprite:getWidth()*p.scale
    local bob=def.air and (64+math.sin(time*2+p.phase)*7) or (def.plant and 0 or math.abs(math.sin(time*3+p.phase))*2)
    local alpha=1
    if def.plant and player and math.abs(player.x-p.x)<70 and player.y<p.y and player.y>p.y-100 then alpha=.42 end
    if not def.plant then
        love.graphics.setColor(.02,.06,.05,def.air and .13 or .19)
        love.graphics.ellipse("fill",p.x,p.y+2,def.width*(def.air and .17 or .27),def.air and 3 or 4)
    end
    love.graphics.setColor(1,1,1,alpha)
    local angle=def.air and math.sin(time*.35+p.phase)*.12 or 0
    love.graphics.draw(sprite,p.x,p.y-bob,angle,scale*p.facing,scale,sprite:getWidth()/2,sprite:getHeight()*def.foot)
end
function Life.queue(world,queue,player)
    local data=world.biomeLife;if not data then return end
    for _,p in ipairs(data.items) do
        local entry=p
        if Maps.insideSpawnTerrain(world,p.x,p.y,20)
            and (not Life.catalog[p.kind].plant or Maps.insideGroundPlants(world,p.x,p.y)) then
            queue[#queue+1]={x=p.x,y=p.air and 100000+p.y or p.y,anchorY=p.y,draw=function() draw(entry,data.time,player) end}
        end
    end
end
return Life
