local Geometry=require("src.combat_geometry")
local Maps=require("src.clearcut_maps")
local Builder={}

Builder.nodes={
    {id="builder_damage",name="건설자재 피해 상승",desc="굴러가는 자재의 피해가 단계마다 300 증가합니다.",effect="damage",value=300,max=5,costs={20000,30000,45000,65000,90000},wx=1100,wy=850,icon="fist"},
    {id="builder_speed",name="자재 굴림 속도 상승",desc="자재의 굴림 속도가 단계마다 120 증가합니다.",effect="speed",value=120,max=4,costs={18000,30000,50000,80000},wx=1500,wy=850,icon="road",requires={{"builder_damage",1}}},
    {id="builder_interval",name="크레인 작업속도 상승",desc="자재 투하 주기가 단계마다 0.12초 짧아집니다.",effect="interval",value=.12,max=5,costs={22000,38000,60000,95000,140000},wx=1100,wy=1200,icon="clock",requires={{"builder_damage",1}}},
    {id="builder_radius",name="콘크리트 관 크기 상승",desc="자재의 크기와 실제 충돌 반경이 단계마다 10 증가합니다.",effect="radius",value=10,max=4,costs={35000,60000,95000,145000},wx=1500,wy=1200,icon="split",requires={{"builder_speed",2}}},
    {id="builder_range",name="자재 굴림 거리 상승",desc="자재가 굴러가는 최대 거리가 단계마다 200 증가합니다.",effect="range",value=200,max=4,costs={30000,55000,90000,140000},wx=1900,wy=850,icon="map",requires={{"builder_speed",1}}},
    {id="builder_payload",name="동시 자재 투하 증가",desc="한 번의 크레인 작업에서 나란히 굴리는 자재가 1개 증가합니다.",effect="payload",value=1,max=2,costs={180000,350000},wx=1900,wy=1200,icon="split",requires={{"builder_radius",2},{"builder_interval",3}}},
    {id="builder_boss",name="세계수 철거 피해 상승",desc="세계수에 주는 자재 충돌 피해가 단계마다 50% 증가합니다.",effect="boss",value=.5,max=4,costs={70000,120000,200000,320000},wx=2300,wy=850,icon="fist",requires={{"builder_range",2}}},
    {id="builder_capacity",name="건설 현장 허용량 상승",desc="현장의 나무 허용량이 단계마다 15그루 증가합니다.",effect="capacity",value=15,max=4,costs={45000,80000,140000,240000},wx=2300,wy=1200,icon="map",requires={{"builder_payload",1}}},
    {id="builder_move",name="건설업자 이동속도 상승",desc="건설업자의 이동속도가 단계마다 8% 증가합니다.",effect="move",value=.08,max=4,costs={20000,35000,60000,100000},wx=1100,wy=1550,icon="road",requires={{"builder_interval",1}}},
    {id="builder_final",name="철거 자재 피해 두 배",desc="모든 건설자재의 충돌 피해가 2배가 됩니다.",effect="final",value=1,max=1,costs={600000},wx=2300,wy=1550,icon="capstone",capstone=true,requires={{"builder_damage",5},{"builder_boss",4},{"builder_payload",2}}},
}
for _,node in ipairs(Builder.nodes)do
    node.job="builder";node.scoreMode=true;node.targetTier=12;node.short=node.name
    node.color={.94,.65,.22}
end
local short={"자재 피해 +300","굴림 속도 +120","투하 주기 -0.12초","자재 반경 +10","굴림 거리 +200",
    "동시 투하 +1","세계수 피해 +50%","허용량 +15","이동속도 +8%","자재 피해 ×2"}
for index,node in ipairs(Builder.nodes)do node.short=short[index]end

function Builder.stats(store)
    local v={}
    for _,node in ipairs(Builder.nodes)do v[node.effect]=(store:getLevel(node.id)or 0)*node.value end
    return {damage=(900+v.damage)*(1+v.final),speed=680+v.speed,interval=1.35-v.interval,
        radius=42+v.radius,range=1100+v.range,payload=1+v.payload,boss=1+v.boss,
        capacity=v.capacity,moveSpeed=320*(1+v.move)}
end

function Builder.setup(mode,game)
    mode.construction={stats=Builder.stats(game.characterTraits),loads={},cooldown=0,
        towerX=game.player.x-210,towerY=game.player.y+170,clock=0}
    mode.scoreTreeAllowance=mode.scoreTreeAllowance+mode.construction.stats.capacity
    mode.scoreBaseAllowance=mode.scoreTreeAllowance
end

function Builder.update(mode,game,dt,held,tx,ty)
    local c=mode.construction;if not c then return end
    c.clock=c.clock+dt;c.cooldown=math.max(0,c.cooldown-dt)
    local actor=game.player;actor.speed=c.stats.moveSpeed
    c.controlX,c.controlY=actor.x,actor.y
    if held==nil then held=love.mouse.isDown(1)end
    if not tx then tx,ty=game.camera:screenToWorld(love.mouse.getPosition())end
    c.aimX,c.aimY=tx,ty
    if held and c.cooldown<=0 then
        local dx,dy=tx-actor.x,ty-actor.y;local distance=math.sqrt(dx*dx+dy*dy)
        if distance<1 then dx,dy,distance=actor.facing or 1,0,1 end
        dx,dy=dx/distance,dy/distance;actor.facing=dx<0 and-1 or 1
        for lane=1,c.stats.payload do
            local offset=(lane-(c.stats.payload+1)/2)*c.stats.radius*2.1
            local x,y=Maps.constrain(game.world,actor.x+dx*65-dy*offset,actor.y+dy*65+dx*offset,c.stats.radius)
            c.loads[#c.loads+1]={x=x,y=y,nx=dx,ny=dy,age=0,height=160,roll=0,
                travelled=0,hit={},stats=c.stats}
        end
        c.cooldown=c.stats.interval;c.action=0
    end
    if c.action then
        c.action=c.action+dt;actor:setClearcutAction(math.min(.99,c.action/.6))
        if c.action>=.6 then c.action=nil;actor:clearClearcutAction()end
    end
    for index=#c.loads,1,-1 do
        local load=c.loads[index];local oldAge=load.age;load.age=load.age+dt
        load.height=160*(1-math.min(1,load.age/.4)^2)
        -- Damage starts on ground contact. Sweep the full travelled segment so
        -- fast material cannot tunnel through a tree between rendered frames.
        local groundDt=math.max(0,load.age-.4)-math.max(0,oldAge-.4)
        if groundDt>0 then
            local distance=math.min(load.stats.range-load.travelled,load.stats.speed*groundDt)
            local ax,ay=load.x,load.y
            load.x,load.y=Maps.constrain(game.world,ax+load.nx*distance,ay+load.ny*distance,load.stats.radius)
            load.travelled=load.travelled+distance;load.roll=load.travelled/load.stats.radius
            for _,node in ipairs(game.world.nodes)do
                if node.rushTree and node.active and not load.hit[node]
                    and Geometry.sweptCircleOverlapsTarget(ax,ay,load.x,load.y,load.stats.radius,node,24)then
                    load.hit[node]=true
                    mode:damageTreeWithSmokerWeapon(node,load.stats.damage,game)
                end
            end
            for _,enemy in ipairs(mode.enemies)do
                if enemy.hp>0 and not enemy.worldTreeEmerging and not load.hit[enemy]
                    and Geometry.sweptCircleOverlapsTarget(ax,ay,load.x,load.y,load.stats.radius,enemy)then
                    load.hit[enemy]=true;enemy.hp=enemy.hp-load.stats.damage*(enemy.scoreWorldTree and load.stats.boss or 1)
                    enemy.visualHit=.18
                end
            end
            if load.travelled>=load.stats.range or (load.x-ax)^2+(load.y-ay)^2<.001 then table.remove(c.loads,index)end
        end
    end
end

function Builder.queue(mode,queue)
    if mode.construction then require("src.construction_art").queue(mode.construction,queue)end
end
return Builder
