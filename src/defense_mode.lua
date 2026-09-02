local Defense={visibleStages=4,ringCount=4,coreRadius=110,speed=48,ringSpacing=60,
    firstRadius=840,spawnRadius=1080,mapScale=1.6,treesPerStage=96,
    baseHealthMultiplier=2,healthPerStage=.25,spawnInterval=1.25}

function Defense.centerX(world)return world.width*.5 end
function Defense.centerY(world)return world.height*.5 end
function Defense.radiusForSlot(slot)return Defense.firstRadius+(slot-1)*Defense.ringSpacing end
function Defense.treeCount()return Defense.visibleStages*Defense.treesPerStage end

local function baseHealth(variant)return({12,9,7,16})[variant]end
local function stageHealth(variant,stage)return math.ceil(baseHealth(variant)*Defense.baseHealthMultiplier*(1+(stage-1)*Defense.healthPerStage))end
local function newTree(index)
    local variant=(index-1)%4+1
    return {kind="tree",work=0,workTime=1,active=false,respawn=0,rushTree=true,
        treeVariant=variant,scoreBaseHp=baseHealth(variant),scoreHpMultiplier=1}
end

local function availableNodes(world,count)
    local nodes={}
    for _,node in ipairs(world.nodes)do
        if not node.active and(not node.fallT or node.fallT>=(node.fallDur or 1))then nodes[#nodes+1]=node;if #nodes==count then return nodes end end
    end
    while #nodes<count do local node=newTree(#world.nodes+1);world.nodes[#world.nodes+1]=node;nodes[#nodes+1]=node end
    return nodes
end

local function spawnStage(mode,game,stage,radius,nodes)
    local cx,cy=Defense.centerX(game.world),Defense.centerY(game.world)
    nodes=nodes or availableNodes(game.world,Defense.treesPerStage)
    local offset=(stage%2)*math.pi/Defense.treesPerStage
    for slot,node in ipairs(nodes)do
        local angle=(slot-1)/Defense.treesPerStage*math.pi*2+offset
        local variant=(slot+stage-2)%4+1;local hp=stageHealth(variant,stage)
        node.kind,node.active,node.rushTree="tree",true,true
        node.treeVariant,node.scoreBaseHp=variant,baseHealth(variant)
        node.defenseRing,node.defenseStage,node.defenseAngle=stage,stage,angle
        node.x,node.y=cx+math.cos(angle)*radius,cy+math.sin(angle)*radius
        node.rushHp,node.rushMaxHp,node.scoreHpMultiplier=hp,hp,hp/baseHealth(variant)
        node.beehive,node.giantTree,node.treeEmergence=nil,nil,nil
        node.burning,node.burnTimer,node.fallT,node.uprooted,node.damageStage=nil,nil,nil,nil,nil
        node.swayAngle,node.swayVel=0,0
    end
    mode.defenseStageGroups[#mode.defenseStageGroups+1]={stage=stage,nodes=nodes}
    mode.totalTreesSpawned=(mode.totalTreesSpawned or 0)+#nodes
    return nodes
end

function Defense.populate(mode,game)
    local world,target=game.world,Defense.treeCount()
    while #world.nodes<target do world.nodes[#world.nodes+1]=newTree(#world.nodes+1)end
    while #world.nodes>target do table.remove(world.nodes)end
    mode.defenseStageGroups={};mode.totalTreesSpawned=0
    local index=0
    for stage=1,Defense.visibleStages do
        local nodes={};for _=1,Defense.treesPerStage do index=index+1;nodes[#nodes+1]=world.nodes[index]end
        spawnStage(mode,game,stage,Defense.radiusForSlot(stage),nodes)
    end
    mode.defenseNextStage=Defense.visibleStages+1;mode.defenseSpawnTimer=Defense.spawnInterval
    mode.defenseStagesCleared,mode.defenseRingsCleared=0,0
    local cx,cy=Defense.centerX(world),Defense.centerY(world);game.player.x,game.player.y=cx,cy
    mode.initialTrees,mode.remainingTrees=target,target;mode.peakActiveTrees=target
end

function Defense.nearestDistance(mode,world)
    local cx,cy=Defense.centerX(world),Defense.centerY(world);local nearest=math.huge
    for _,node in ipairs(world.nodes)do if node.active and node.rushTree and node.defenseStage then
        local dx,dy=node.x-cx,node.y-cy;nearest=math.min(nearest,math.sqrt(dx*dx+dy*dy))
    end end
    return nearest
end

function Defense.update(mode,game,dt)
    if game.result then return true end
    local world=game.world;local cx,cy=Defense.centerX(world),Defense.centerY(world);local active=0
    for _,node in ipairs(world.nodes)do if node.active and node.rushTree and node.defenseStage then
        active=active+1;local dx,dy=node.x-cx,node.y-cy;local radius=math.sqrt(dx*dx+dy*dy)
        local nextRadius=math.max(0,radius-Defense.speed*dt)
        if radius>0 then node.x,node.y=cx+dx/radius*nextRadius,cy+dy/radius*nextRadius end
        if nextRadius<=Defense.coreRadius then mode.failureReason="defense_core_breached";mode:finish(game,false);return true end
    end end
    for _,group in ipairs(mode.defenseStageGroups or{})do
        if not group.counted then
            local alive=false;for _,node in ipairs(group.nodes)do if node.active and node.defenseStage==group.stage then alive=true;break end end
            if not alive then group.counted=true;mode.defenseStagesCleared=(mode.defenseStagesCleared or 0)+1;mode.defenseRingsCleared=mode.defenseStagesCleared end
        end
    end
    mode.defenseSpawnTimer=(mode.defenseSpawnTimer or Defense.spawnInterval)-dt
    while mode.defenseSpawnTimer<=0 do
        local stage=mode.defenseNextStage;mode.defenseNextStage=stage+1;mode.defenseSpawnTimer=mode.defenseSpawnTimer+Defense.spawnInterval
        local nodes=spawnStage(mode,game,stage,Defense.spawnRadius);active=active+#nodes
        if game.setNotice then game:setNotice(string.format("디펜스 %d단계 접근 — 나무 체력 +%d%%",stage,math.floor((stage-1)*Defense.healthPerStage*100)),"food")end
    end
    mode.remainingTrees=active;mode.peakActiveTrees=math.max(mode.peakActiveTrees or 0,active)
    return false
end

local function polygonPoints(cx,cy,radius,sides)
    local points={};for index=0,sides-1 do local angle=index/sides*math.pi*2-math.pi*.5
        points[#points+1]=math.floor(cx+math.cos(angle)*radius+.5);points[#points+1]=math.floor(cy+math.sin(angle)*radius+.5)
    end;return points
end
function Defense.drawGround(mode,world)
    local cx,cy=Defense.centerX(world),Defense.centerY(world);local pulse=.5+.5*math.sin((mode.elapsed or 0)*3)
    love.graphics.setColor(.06,.19,.12,.72);love.graphics.polygon("fill",polygonPoints(cx,cy,Defense.coreRadius,16))
    love.graphics.setLineWidth(5);love.graphics.setColor(1,.36,.14,.82+pulse*.18);love.graphics.polygon("line",polygonPoints(cx,cy,Defense.coreRadius,16))
    love.graphics.setLineWidth(2);love.graphics.setColor(.48,.82,.42,.28);love.graphics.polygon("line",polygonPoints(cx,cy,Defense.spawnRadius,32))
    love.graphics.setLineWidth(1)
end
function Defense.queue(mode,queue,world)if mode.defenseMode then queue[#queue+1]={y=-300000,ground=true,draw=function()Defense.drawGround(mode,world)end}end end
return Defense
