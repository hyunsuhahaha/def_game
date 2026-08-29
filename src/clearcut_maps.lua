-- Playable biomes. Terrain predicates are mirrored by clearcut-terrain.glsl.
local Maps={}
-- One geometry source for collision, wildlife and the terrain shader.
Maps.island={radiusX=1300,radiusY=660,width=3400,height=2200}
Maps.catalog={
    {id="forest",name="온대 숲",region="한반도 중부 산림",globeLat=37.4,globeLon=127.1,subtitle="능선 · 낙엽길 · 깊은 숲",desc="작은 벌목지 60그루에서 시작해 깊은 숲으로 확장됩니다.",short="60그루 벌목지에서 깊은 숲으로.",trees=60,color={.53,.68,.30}},
    {id="mangrove",name="맹그로브 숲",region="벵골만 삼각주",globeLat=21.9,globeLon=89.1,subtitle="청록 물길 · 뿌리 · 물가의 게",desc="성긴 물가 55그루에서 시작해 지주뿌리 습지 전역으로 진입합니다.",short="55그루 물가에서 수로 전역으로.",trees=55,tree="mangrove",color={.26,.72,.65}},
    {id="madagascar",name="마다가스카르 숲",region="마다가스카르 서부",globeLat=-19.2,globeLon=46.7,subtitle="붉은 흙 · 바오밥 · 여우원숭이",desc="성긴 붉은 땅 50그루에서 시작해 바오밥 혼합림으로 전진합니다.",short="50그루 붉은 땅에서 내륙으로.",trees=50,tree="baobab",color={.85,.48,.28}},
    {id="island",name="무인도 전소",region="남태평양 외딴섬",globeLat=-17.6,globeLon=-149.5,subtitle="해변 상륙 · 혼합 야자림 · 앵무새",desc="상륙 구역 65그루부터 태우며 섬과 사방의 해안을 개방합니다.",short="65그루 해변에서 섬 전체로.",trees=65,tree="palm",color={.30,.70,.88}},
}
local byId,images={},{}
Maps.species={
    mangrove={"mangrove","avicennia","nypa"},
    madagascar={"baobab","tamarind","commiphora"},
    island={"palm","seaalmond","pandanus"},
}
for i,def in ipairs(Maps.catalog) do def.index=i;def.chapter=i;byId[def.id]=def end
function Maps.get(id) return byId[id] or Maps.catalog[1] end
function Maps.stageCode(id,stage)
    local def=Maps.get(id)
    return string.format("%d-%d",def.chapter or def.index or 1,math.max(1,math.floor(stage or 1)))
end

-- Regeneration pressure grows by chapter and stage.  Only the sanctums get
-- tougher; ordinary trees keep their short time-to-cut so late builds can
-- still knock down whole patches at once.
local regrowthCoreCounts={
    forest={1,2,3,4},mangrove={2,3,4,5},madagascar={3,4,5,6},island={4,5,6,6},
}
local worldTreeTotemCounts={
    forest={0,0,0,0},mangrove={1,1,2,2},madagascar={1,2,2,3},island={2,2,3,4},
}
local regrowthBaseHp={forest=120,mangrove=165,madagascar=215,island=270}
local regrowthNames={forest="숲의 재생 프리즘",mangrove="조수의 재생 프리즘",
    madagascar="홍토의 재생 프리즘",island="산호의 재생 프리즘"}
function Maps.regrowthCoreCount(id,stage)
    local list=regrowthCoreCounts[Maps.get(id).id] or regrowthCoreCounts.forest
    return list[math.max(1,math.min(4,stage or 1))]
end
function Maps.worldTreeTotemCount(id,stage)
    local list=worldTreeTotemCounts[Maps.get(id).id] or worldTreeTotemCounts.forest
    return list[math.max(1,math.min(4,stage or 1))]
end
function Maps.regrowthTotemStats(id,stage,bossPhase)
    local mapId=Maps.get(id).id;stage=math.max(1,math.min(4,stage or 1))
    local hp=regrowthBaseHp[mapId]*(1+(stage-1)*.34)*(bossPhase and 1.55 or 1)
    return {hp=math.floor(hp+.5),name=regrowthNames[mapId],artKey="planter_"..mapId,
        plantInterval=bossPhase and math.max(7.5,10.5-stage*.55) or math.max(10,14-stage*.65),
        plantRadius=bossPhase and 310 or 230,
        plantCount=math.min(6,2+stage+(bossPhase and 1 or 0))}
end
function Maps.treeTarget(id,stage)
    local def=Maps.get(id)
    local targets={forest={60,130,220,320},mangrove={55,120,205,295},
        madagascar={50,115,195,285},island={65,145,260,380}}
    local list=targets[def.id] or targets.forest;stage=stage or 1
    if stage<=#list then return list[stage] end
    return math.min(def.id=="island" and 520 or 500,list[#list]+(stage-#list)*(def.id=="island" and 120 or 85))
end
function Maps.stageTimeLimit(id,stage)
    local limits={360,420,480,600}
    stage=math.max(1,math.min(#limits,stage or 1))
    return limits[stage]
end
local stageSizes={
    normal={{2400,1400},{2800,1700},{3050,1900},{3200,2000}},
    island={{2200,1400},{2800,1750},{3150,2000},{3400,2200}},
}
function Maps.configureStage(world,stage)
    stage=math.max(1,stage or 1);world.clearcutStage=stage
    local kind=world.clearcutMap=="island" and "island" or "normal"
    local size=stageSizes[kind][math.min(stage,4)]
    world.playBounds={x=(world.width-size[1])/2,y=(world.height-size[2])/2,w=size[1],h=size[2]}
    -- Movement remains inside playBounds, but the camera may look past the
    -- northern edge. This keeps an upward-moving player framed naturally and
    -- reveals the decorative biome panorama beyond the authored ridge instead
    -- of pinning the view to an invisible wall.
    world.cameraTopReveal=900
    world.northBackdrop=true
    world.cameraBounds={x=world.playBounds.x,y=world.playBounds.y-world.cameraTopReveal,
        w=world.playBounds.w,h=world.playBounds.h+world.cameraTopReveal}
    world.stageZoom=stage==1 and .84 or (stage==2 and .79 or (stage==3 and .75 or .72))
    -- Playable maps always use a following camera. A fixed overview used to
    -- strand the player vertically on the final island stage.
    world.overviewBounds=nil
end
function Maps.insidePlayable(world,x,y,margin)
    local b=world and world.playBounds
    if not b then return true end
    margin=margin or 0
    return x>=b.x+margin and x<=b.x+b.w-margin and y>=b.y+margin and y<=b.y+b.h-margin
end

-- Ground plants are foot-anchored billboards. Keeping only their anchor inside
-- playBounds still lets their crown poke over the northern ridge, so plants
-- share an asymmetric visual reserve. The other edges also retain a quieter
-- strip instead of filling the border with clipped props.
Maps.groundPlantMargins={left=150,right=150,top=240,bottom=140}
local function plantMargins(override)
    local base=Maps.groundPlantMargins
    override=override or {}
    return override.left or base.left,override.right or base.right,
        override.top or base.top,override.bottom or base.bottom
end
function Maps.insideGroundPlants(world,x,y,override)
    local b=world and world.playBounds
    if not b then return true end
    local left,right,top,bottom=plantMargins(override)
    return x>=b.x+left and x<=b.x+b.w-right
        and y>=b.y+top and y<=b.y+b.h-bottom
end
function Maps.constrainGroundPlant(world,x,y,override)
    local b=world and world.playBounds
    if not b then return x,y end
    local left,right,top,bottom=plantMargins(override)
    x=math.max(b.x+left,math.min(b.x+b.w-right,x))
    y=math.max(b.y+top,math.min(b.y+b.h-bottom,y))
    if world.clearcutMap=="island" then
        -- Preserve the shoreline constraint as well as the visual reserve.
        x,y=Maps.constrain(world,x,y,math.max(left,right,top,bottom))
        x=math.max(b.x+left,math.min(b.x+b.w-right,x))
        y=math.max(b.y+top,math.min(b.y+b.h-bottom,y))
    end
    return x,y
end
function Maps.islandDistance(x,y,w,h)
    local dx,dy=(x-w/2)/Maps.island.radiusX,(y-h/2)/Maps.island.radiusY
    local a=math.atan2(dy,dx)
    return math.sqrt(dx*dx+dy*dy)/(1+.065*math.sin(a*3+.4)+.035*math.cos(a*5))
end
function Maps.channelDistance(x,y,w,h)
    return math.min(math.abs(x-(w*.32+math.sin(y/240)*110))-72,
        math.abs(y-(h*.65+math.sin(x/340)*125))-90)
end
function Maps.canPlant(world,x,y)
    if not Maps.insidePlayable(world,x,y,90) then return false end
    local id=world.clearcutMap
    if id=="island" then return Maps.islandDistance(x,y,world.width,world.height)<.80 end
    if id=="mangrove" then return Maps.channelDistance(x,y,world.width,world.height)>26 end
    return true
end
function Maps.treeSpace(world,x,y)
    local dx,dy=x-world.width/2,y-world.height/2
    local island=world.clearcutMap=="island"
    if island and (dx/180)^2+((dy-65)/205)^2<1 then return false end
    if dx*dx+dy*dy<(island and 140 or 230)^2 then return false end
    if math.abs(dx-math.sin(dy/380)*65)<(island and 55 or 48) then return false end
    return Maps.canPlant(world,x,y)
end
function Maps.treeVariant(world,x,y,index)
    local id=world.clearcutMap
    local patch=math.sin(x/237)+math.cos(y/193)
    if id=="mangrove" then
        local bank=Maps.channelDistance(x,y,world.width,world.height)
        -- Calm upper waterways favour clumping nipa; open lower banks favour
        -- pencil-root trees. These are art-direction weights, not field census.
        if y<world.height*.52 and bank<240 and patch>-.6 then return 3 end
        if bank<180 then return patch>.55 and 1 or 2 end
        return patch>.95 and 3 or (patch<-.65 and 2 or 1)
    elseif id=="madagascar" then
        local trail=math.abs(y-world.height*.48-math.sin(x/330)*145)
        -- Baobabs punctuate mixed woodland, not an entire monoculture.
        if index%5==0 then return 1 end
        if trail<260 or patch>.45 then return 2 end
        return 3
    elseif id=="island" then
        local coast=Maps.islandDistance(x,y,world.width,world.height)
        if coast>.68 then return (index*.61803398875)%1<.42 and 3 or 1 end
        return index%4==0 and 1 or 2
    end
end
function Maps.constrain(world,x,y,margin)
    if not world then return x,y end
    margin=margin or 18
    local b=world.playBounds
    if b then x=math.max(b.x+margin,math.min(b.x+b.w-margin,x));y=math.max(b.y+margin,math.min(b.y+b.h-margin,y)) end
    if world.clearcutMap~="island" then return x,y end
    local limit=1-margin/Maps.island.radiusY
    local d=Maps.islandDistance(x,y,world.width,world.height)
    if d>limit then
        local scale=limit/d
        return world.width/2+(x-world.width/2)*scale,world.height/2+(y-world.height/2)*scale
    end
    return x,y
end
function Maps.configure(world,id)
    local def=Maps.get(id);world.clearcutMap=def.id
    world.width,world.height=3200,2000
    world.overviewBounds=nil
    if def.id=="island" then
        world.width,world.height=Maps.island.width,Maps.island.height
        -- Includes crown overhang, beach, sea on every side, and room for the HUD.
    end
    Maps.configureStage(world,1)
    if Maps.species[def.id] then
        world.images.treeVariants={}
        world.images.treeDamageVariants=nil
        for _,name in ipairs(Maps.species[def.id]) do
            if not images[name] then
                local version=(name=="baobab" or name=="mangrove" or name=="palm") and 2 or 1
                images[name]=love.graphics.newImage("assets/trees/"..name.."-tree-pixel-v"..version..".png")
                images[name]:setFilter("nearest","nearest")
            end
            world.images.treeVariants[#world.images.treeVariants+1]=images[name]
        end
        world.treeVisual.variantScale=def.id=="island" and {.78,.82,.86} or {1,.95,.92}
        world.treeVisual.variantShadow={.8,1,1.05}
    end
end
function Maps.filterScenery(world)
    if world.clearcutMap==nil then return end
    for _,list in ipairs({world.forestScenery.ground,world.forestScenery.actors}) do
        for i=#list,1,-1 do
            local p=list[i]
            if not Maps.canPlant(world,p.x,p.y) or (p.kind=="leaves" and world.clearcutMap~="madagascar" and world.clearcutMap~="forest") then table.remove(list,i) end
        end
    end
end
local shader
function Maps.drawGround(world,time)
    local def=Maps.get(world.clearcutMap)
    if def.id=="forest" then return false end
    if not shader then shader=love.graphics.newShader("assets/shaders/clearcut-terrain.glsl") end
    local previous=love.graphics.getShader()
    shader:send("worldSize",{world.width,world.height})
    shader:send("islandRadii",{Maps.island.radiusX,Maps.island.radiusY})
    local ox,oy,sw,sh=0,0,world.width,world.height
    if def.id=="island" then ox,oy,sw,sh=-world.width,-world.height,world.width*3,world.height*3 end
    shader:send("terrainOrigin",{ox,oy});shader:send("terrainSize",{sw,sh})
    shader:send("biome",def.index-1)
    shader:send("clock",time or love.timer.getTime())
    love.graphics.setShader(shader);love.graphics.setColor(1,1,1,1)
    local image=world.images.forestGround
    love.graphics.draw(image,ox,oy,0,sw/image:getWidth(),sh/image:getHeight())
    love.graphics.setShader(previous)
    return true
end
return Maps
