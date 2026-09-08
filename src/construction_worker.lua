local Geometry=require("src.combat_geometry")
local Maps=require("src.clearcut_maps")
local Builder={}

Builder.nodes={
    {id="builder_damage",name="건설자재 피해 상승",desc="굴러가는 자재의 피해가 단계마다 300 증가합니다.",effect="damage",value=300,max=5,costs={20000,30000,45000,65000,90000},wx=1100,wy=850,icon="fist"},
    {id="builder_speed",name="자재 굴림 속도 상승",desc="자재의 굴림 속도가 단계마다 120 증가합니다.",effect="speed",value=120,max=4,costs={18000,30000,50000,80000},wx=1500,wy=850,icon="road",requires={{"builder_damage",1}}},
    {id="builder_interval",name="크레인 작업속도 상승",desc="자재 투하 주기가 단계마다 0.12초 짧아집니다.",effect="interval",value=.12,max=5,costs={22000,38000,60000,95000,140000},wx=1100,wy=1200,icon="clock",requires={{"builder_damage",1}}},
    {id="builder_radius",name="콘크리트 관 크기 상승",desc="자재의 크기와 실제 충돌 반경이 단계마다 10 증가합니다.",effect="radius",value=10,max=4,costs={35000,60000,95000,145000},wx=1500,wy=1200,icon="split",requires={{"builder_speed",2}}},
    {id="builder_range",name="자재 굴림 거리 상승",desc="자재가 굴러가는 최대 거리가 단계마다 200 증가합니다.",effect="range",value=200,max=4,costs={30000,55000,90000,140000},wx=1900,wy=850,icon="map",requires={{"builder_speed",1}}},
    {id="builder_payload",name="콘크리트 관 길이 상승",desc="원통 하나의 길이와 충돌 폭이 단계마다 반경의 2배만큼 증가합니다.",effect="payload",value=1,max=2,costs={180000,350000},wx=1900,wy=1200,icon="split",requires={{"builder_radius",2},{"builder_interval",3}}},
    {id="builder_boss",name="세계수 철거 피해 상승",desc="세계수에 주는 자재 충돌 피해가 단계마다 50% 증가합니다.",effect="boss",value=.5,max=4,costs={70000,120000,200000,320000},wx=2300,wy=850,icon="fist",requires={{"builder_range",2}}},
    {id="builder_capacity",name="건설 현장 허용량 상승",desc="현장의 나무 허용량이 단계마다 15그루 증가합니다.",effect="capacity",value=15,max=4,costs={45000,80000,140000,240000},wx=2300,wy=1200,icon="map",requires={{"builder_payload",1}}},
    {id="builder_move",name="크레인 이동속도 상승",desc="크레인 본체의 이동속도가 단계마다 8% 증가합니다.",effect="move",value=.08,max=4,costs={20000,35000,60000,100000},wx=1100,wy=1550,icon="road",requires={{"builder_interval",1}}},
    {id="builder_final",name="철거 자재 피해 두 배",desc="모든 건설자재의 충돌 피해가 2배가 됩니다.",effect="final",value=1,max=1,costs={600000},wx=2300,wy=1550,icon="capstone",capstone=true,requires={{"builder_damage",5},{"builder_boss",4},{"builder_payload",2}}},
}
for _,node in ipairs(Builder.nodes)do
    node.job="builder";node.scoreMode=true;node.targetTier=12;node.short=node.name
    node.color={.94,.65,.22}
end
local short={"자재 피해 +300","굴림 속도 +120","투하 주기 -0.12초","자재 반경 +10","굴림 거리 +200",
    "원통 길이 상승","세계수 피해 +50%","허용량 +15","이동속도 +8%","자재 피해 ×2"}
for index,node in ipairs(Builder.nodes)do node.short=short[index]end

function Builder.stats(store)
    local v={}
    for _,node in ipairs(Builder.nodes)do v[node.effect]=(store:getLevel(node.id)or 0)*node.value end
    return {damage=(900+v.damage)*(1+v.final),speed=680+v.speed,interval=1.35-v.interval,
        radius=42+v.radius,range=1100+v.range,payload=1+v.payload,boss=1+v.boss,
        capacity=v.capacity,moveSpeed=320*(1+v.move)}
end

function Builder.setup(mode,game)
    mode.construction={stats=Builder.stats(game.characterTraits),loads={},flyingTrees={},cooldown=0,
        towerX=game.player.x,towerY=game.player.y,clock=0,launchDistance=280,dropHeight=320}
    mode.scoreTreeAllowance=mode.scoreTreeAllowance+mode.construction.stats.capacity
    mode.scoreBaseAllowance=mode.scoreTreeAllowance
end

function Builder.update(mode,game,dt,held,tx,ty)
    local c=mode.construction;if not c then return end
    c.contactDust=c.contactDust or {}
    for i=#c.contactDust,1,-1 do
        local p=c.contactDust[i];p.age=p.age+dt
        if p.age>=.65 then table.remove(c.contactDust,i)end
    end
    local function contact(load,impact)
        for i=-3,3 do
            if #c.contactDust>=112 then table.remove(c.contactDust,1)end
            local s=load.halfLength*i/3
            c.contactDust[#c.contactDust+1]={x=load.x-load.ny*s-load.nx*load.stats.radius*.65,
                y=load.y+load.nx*s-load.ny*load.stats.radius*.65,age=0,scale=load.stats.radius/(impact and 65 or 110)}
        end
    end
    for i=#c.flyingTrees,1,-1 do
        local tree=c.flyingTrees[i]
        tree.t=math.min(tree.duration,tree.t+dt)
        local u=tree.t/tree.duration
        tree.x,tree.y=tree.startX+tree.nx*tree.distance*u,tree.startY+tree.ny*tree.distance*u
        tree.height=math.sin(u*math.pi)*320
        tree.angle=(tree.nx<0 and -1 or 1)*u*math.pi*1.7
        if u>=1 then
            game.world:spawnFallImpact({x=tree.x,y=tree.y,rushMaxHp=5,fallDir=tree.nx<0 and -1 or 1,fallReach=25},game)
            table.remove(c.flyingTrees,i)
        end
    end
    c.clock=c.clock+dt;c.cooldown=math.max(0,c.cooldown-dt)
    local actor=game.player;actor.speed=c.stats.moveSpeed
    c.towerX,c.towerY=actor.x,actor.y
    c.controlX,c.controlY=actor.x,actor.y
    if held==nil then held=love.mouse.isDown(1)end
    if not tx then tx,ty=game.camera:screenToWorld(love.mouse.getPosition())end
    c.aimX,c.aimY=tx,ty
    if held and c.cooldown<=0 then
        local dx,dy=tx-actor.x,ty-actor.y;local distance=math.sqrt(dx*dx+dy*dy)
        if distance<1 then dx,dy,distance=actor.facing or 1,0,1 end
        dx,dy=dx/distance,dy/distance;actor.facing=dx<0 and-1 or 1
        do
            local x,y=Maps.constrain(game.world,actor.x+dx*c.launchDistance,actor.y+dy*c.launchDistance,c.stats.radius)
            c.loads[#c.loads+1]={x=x,y=y,nx=dx,ny=dy,age=0,height=c.dropHeight,roll=0,
                halfLength=c.stats.radius*(2+c.stats.payload),travelled=0,hit={},stats=c.stats}
        end
        c.cooldown=c.stats.interval;c.action=0
    end
    if c.action then
        c.action=c.action+dt;actor:setClearcutAction(math.min(.99,c.action/.6))
        if c.action>=.6 then c.action=nil;actor:clearClearcutAction()end
    end
    for index=#c.loads,1,-1 do
        local load=c.loads[index];local oldAge=load.age;load.age=load.age+dt
        load.height=c.dropHeight*(1-math.min(1,load.age/.4)^2)
        -- Damage starts on ground contact. Sweep the full travelled segment so
        -- fast material cannot tunnel through a tree between rendered frames.
        local groundDt=math.max(0,load.age-.4)-math.max(0,oldAge-.4)
        if groundDt>0 then
            if oldAge<=.4 then
                contact(load,true)
            end
            -- Build momentum instead of instantly shooting off at full speed.
            local ramp=math.min(1,(load.age-.4)/.7)
            local distance=math.min(load.stats.range-load.travelled,load.stats.speed*groundDt*(.22+.78*ramp))
            local ax,ay=load.x,load.y
            load.x,load.y=Maps.constrain(game.world,ax+load.nx*distance,ay+load.ny*distance,load.stats.radius)
            load.travelled=load.travelled+distance;load.roll=load.travelled/load.stats.radius
            if load.travelled-(load.lastDust or 0)>=load.stats.radius*.9 then
                contact(load,false);load.lastDust=load.travelled
            end
            local function overlaps(target,override)
                local x,y=target.x-ax,target.y-ay
                local along=x*load.nx+y*load.ny
                local across=-x*load.ny+y*load.nx
                local travel=(load.x-ax)*load.nx+(load.y-ay)*load.ny
                local u=math.max(0,-along,along-travel)
                local v=math.max(0,math.abs(across)-load.halfLength)
                local radius=load.stats.radius+Geometry.targetRadius(target,override)
                return u*u+v*v<=radius*radius
            end
            for _,node in ipairs(game.world.nodes)do
                if node.rushTree and node.active and not load.hit[node]
                    and overlaps(node,24)then
                    load.hit[node]=true
                    mode:damageTreeWithSmokerWeapon(node,load.stats.damage,game)
                    if not node.active then
                        local im,scale=game.world:treeRenderSpec(node)
                        if #c.flyingTrees>=80 then table.remove(c.flyingTrees,1)end
                        c.flyingTrees[#c.flyingTrees+1]={image=im,scale=game.world.treeVisual.scale*scale,
                            startX=node.x,startY=node.y,x=node.x,y=node.y,nx=load.nx,ny=load.ny,
                            distance=560+load.stats.radius*2,t=0,duration=1.15,height=0,angle=0}
                        node.fallT=nil;node.uprooted=true
                    end
                end
            end
            for _,enemy in ipairs(mode.enemies)do
                if enemy.hp>0 and not enemy.worldTreeEmerging and not load.hit[enemy]
                    and overlaps(enemy)then
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
