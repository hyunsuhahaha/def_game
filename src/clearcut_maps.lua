-- Playable biomes. Terrain predicates are mirrored by clearcut-terrain.glsl.
local Maps={}
-- One geometry source for collision, wildlife and the terrain shader.
Maps.island={radiusX=1300,radiusY=660,width=3400,height=2200}
Maps.catalog={
    {id="forest",name="온대 숲",subtitle="능선 · 낙엽길 · 깊은 숲",desc="기존 숲. 네 종류의 나무와 바위, 고사리가 섞인 넓은 전장.",short="네 종류의 나무가 섞인 넓은 숲.",trees=260,color={.53,.68,.30}},
    {id="mangrove",name="맹그로브 숲",subtitle="청록 물길 · 뿌리 · 물가의 게",desc="얕은 물길과 드러난 지주뿌리. 커다란 집게를 든 게가 진흙 물가를 걷는 습지.",short="얕은 물길을 건너는 뿌리 숲.",trees=230,tree="mangrove",color={.26,.72,.65}},
    {id="madagascar",name="마다가스카르 숲",subtitle="붉은 흙 · 바오밥 · 여우원숭이",desc="통 모양 바오밥과 부채잎 식물, 줄무늬 꼬리의 여우원숭이가 어울리는 붉은 땅.",short="붉은 땅 위의 바오밥 군락.",trees=220,tree="baobab",color={.85,.48,.28}},
    {id="island",name="무인도 전소",subtitle="넓은 섬 · 혼합 야자림 · 앵무새",desc="넓어진 해안과 혼합 야자림 280그루. 섬 전역을 돌아다니며 태우는 전장으로, 사방의 바다도 보입니다.",short="사방이 바다인 섬 전체를 전소.",trees=280,tree="palm",color={.30,.70,.88}},
    {id="beginner",name="초심자의 숲",subtitle="좁은 개활지 · 듬성듬성한 나무",desc="처음 시작하기 좋은 좁고 여유로운 숲. 온대 숲과 같은 나무들이지만 훨씬 듬성듬성 나 있습니다.",short="좁고 나무가 듬성듬성한 초심자 숲.",trees=70,preview="forest",color={.62,.78,.42}},
}
local byId,images={},{}
Maps.species={
    mangrove={"mangrove","avicennia","nypa"},
    madagascar={"baobab","tamarind","commiphora"},
    island={"palm","seaalmond","pandanus"},
}
for i,def in ipairs(Maps.catalog) do def.index=i;byId[def.id]=def end
function Maps.get(id) return byId[id] or Maps.catalog[1] end
function Maps.treeTarget(id,stage)
    local def=Maps.get(id)
    if def.id=="island" then return math.min(520,def.trees+((stage or 1)-1)*60) end
    if def.id=="beginner" then return def.trees+((stage or 1)-1)*25 end
    return def.trees+((stage or 1)-1)*45
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
    if not world or world.clearcutMap~="island" then return x,y end
    local limit=1-(margin or 18)/Maps.island.radiusY
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
        world.overviewBounds={x=world.width/2,y=world.height/2-55,w=3100,h=1850}
    elseif def.id=="beginner" then
        world.width,world.height=1900,1200
    end
    if Maps.species[def.id] then
        world.images.treeVariants={}
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
    if world.clearcutMap==nil or world.clearcutMap=="forest" then return end
    for _,list in ipairs({world.forestScenery.ground,world.forestScenery.actors}) do
        for i=#list,1,-1 do
            local p=list[i]
            if not Maps.canPlant(world,p.x,p.y) or (p.kind=="leaves" and world.clearcutMap~="madagascar") then table.remove(list,i) end
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
