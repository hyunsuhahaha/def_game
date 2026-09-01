-- 로비에서 생활하는 해금 동물 동료. 전투 수치와는 완전히 분리된 표현 계층이다.
-- 승인된 전투 몸체를 걷기에 그대로 쓰고, 별도 고정 픽셀 수면 아틀라스만 추가한다.
local Companions={}

local FRAMES=6
local INTERACTION_KINDS={"cat_wand","banana_toss","mole_peek","chase_train"}
local PROP_ROWS={feather=0,banana=1,sparkle=2,dirt=3,puff=4}
local ART={
    monkey={
        walk="assets/characters/companions/graduate-monkey-atlas-pixel-v3.png",
        sleep="assets/characters/companions/lobby-monkey-sleep-atlas-pixel-v2.png",
        cellW=128,cellH=128,foot=118,sleepCellW=192,sleepCellH=160,sleepFoot=152,
        scale=.42,nativeFacing=1,speed=24,shadowX=18,sleepShadowX=31,shadowY=5,
    },
    mole={
        walk="assets/characters/ingame/coin-miner-mole-atlas-pixel-v3.png",
        sleep="assets/characters/companions/lobby-mole-sleep-atlas-pixel-v2.png",
        cellW=192,cellH=384,foot=380,sleepCellW=320,sleepCellH=384,sleepFoot=380,
        scale=.29,nativeFacing=-1,speed=19,shadowX=24,sleepShadowX=42,shadowY=7,
    },
    cat={
        walk="assets/characters/companions/gray-oil-cat-atlas-pixel-v1.png",
        sleep="assets/characters/companions/lobby-cat-sleep-atlas-pixel-v2.png",
        cellW=128,cellH=128,foot=118,sleepCellW=192,sleepCellH=160,sleepFoot=152,
        scale=.60,nativeFacing=-1,speed=31,shadowX=21,sleepShadowX=39,shadowY=5,
    },
}
Companions.ART=ART

local loaded={}
local loadedProps
local function load(kind)
    if loaded[kind]~=nil then return loaded[kind]or nil end
    local spec=ART[kind]
    local result
    local ok=pcall(function()
        local walk=love.graphics.newImage(spec.walk)
        local sleep=love.graphics.newImage(spec.sleep)
        walk:setFilter("nearest","nearest");sleep:setFilter("nearest","nearest")
        local quads={walk={},sleep={}}
        for frame=0,FRAMES-1 do
            quads.walk[frame+1]=love.graphics.newQuad(frame*spec.cellW,0,
                spec.cellW,spec.cellH,walk:getDimensions())
            quads.sleep[frame+1]=love.graphics.newQuad(frame*spec.sleepCellW,0,
                spec.sleepCellW,spec.sleepCellH,sleep:getDimensions())
        end
        result={walk=walk,sleep=sleep,quads=quads,spec=spec}
    end)
    loaded[kind]=(ok and result)or false
    return loaded[kind]or nil
end

local function loadProps()
    if loadedProps~=nil then return loadedProps or nil end
    local result
    local ok=pcall(function()
        local image=love.graphics.newImage("assets/characters/companions/lobby-interaction-props-atlas-pixel-v1.png")
        image:setFilter("nearest","nearest")
        local quads={}
        for row=0,4 do
            quads[row]={}
            for frame=0,FRAMES-1 do
                quads[row][frame+1]=love.graphics.newQuad(frame*64,row*64,64,64,image:getDimensions())
            end
        end
        result={image=image,quads=quads}
    end)
    loadedProps=(ok and result)or false
    return loadedProps or nil
end

local function level(traits,id)
    if not traits or not traits.getLevel then return 0 end
    return math.max(0,math.floor(traits:getLevel(id)or 0))
end

local function desiredAnimals(traits)
    local desired={}
    local veteran=level(traits,"universal_veteran_crew")
    local function add(kind,prefix,count)
        for index=1,count do desired[#desired+1]={id=prefix..index,kind=kind}end
    end
    if level(traits,"fire_score_axe_crew")>0 then add("monkey","axe_monkey_",1+veteran)end
    if level(traits,"fire_score_rocket_crew")>0 then add("monkey","rocket_monkey_",1+veteran)end
    if level(traits,"fire_score_popper_unlock")>0 then
        add("monkey","popper_monkey_",1+math.min(1,level(traits,"fire_score_popper_extra")))
    end
    if level(traits,"universal_mole_companion")>0 then
        add("mole","mole_",1+math.min(2,level(traits,"universal_mole_extra")))
    end
    if level(traits,"universal_gray_cat")>0 then add("cat","gray_cat_",1)end
    return desired
end

local function hash(text)
    local value=2166136261
    for index=1,#text do value=(value*16777619+text:byte(index))%2147483647 end
    return math.floor(value)
end

local function random(actor)
    actor.seed=(actor.seed*1103515245+12345)%2147483648
    return actor.seed/2147483648
end

local function stateRandom(state)
    state.seed=((state.seed or 9173)*1103515245+12345)%2147483648
    return state.seed/2147483648
end

local function boundsFor(width,height)
    return{
        x1=math.floor(width*.14),x2=math.floor(width*.90),
        y1=math.floor(height*.70),y2=math.floor(height*.895),
        width=width,height=height,
    }
end

local function bodyRadius(kind,asleep)
    if asleep then return kind=="monkey"and 35 or(kind=="mole"and 47 or 48)end
    return kind=="monkey"and 19 or(kind=="mole"and 27 or 23)
end

local function depthScaleForY(y,bounds)
    local span=math.max(1,bounds.y2-bounds.y1)
    local depth=math.max(0,math.min(1,((y or bounds.y1)-bounds.y1)/span))
    return .78+depth*.30
end
Companions.depthScaleForY=depthScaleForY

local function blockedByGroundProp(x,y,bounds,clearance)
    clearance=clearance or 0
    local function insideEllipse(cx,cy,rx,ry)
        local dx=(x-cx)/math.max(1,rx+clearance)
        local dy=(y-cy)/math.max(1,ry+clearance*.42)
        return dx*dx+dy*dy<1
    end
    if insideEllipse(bounds.width*.525,bounds.height*.93,bounds.width*.055,bounds.height*.045)or
        insideEllipse(bounds.width*.785,bounds.height*.945,bounds.width*.078,bounds.height*.034)then return true end
    for _,obstacle in ipairs(bounds.scenery or{})do
        if insideEllipse(obstacle.x,obstacle.y,obstacle.rx,obstacle.ry)then return true end
    end
    return false
end

local function clearPath(actor,fromX,fromY,toX,toY,bounds)
    if not fromX or not fromY then return true end
    local clearance=bodyRadius(actor.kind,false)
    for step=1,12 do
        local t=step/12
        if blockedByGroundProp(fromX+(toX-fromX)*t,fromY+(toY-fromY)*t,bounds,clearance)then
            return false
        end
    end
    return true
end

local function blockedByAmenity(x,y,bounds,clearance)
    for _,amenity in ipairs(bounds.amenities or{})do
        local rx=amenity.kind=="swing"and 82 or amenity.kind=="cat_tower"and 70 or 62
        local dx=(x-amenity.x)/math.max(1,rx+(clearance or 0))
        local dy=(y-amenity.y)/math.max(1,38+(clearance or 0)*.35)
        if dx*dx+dy*dy<1 then return true end
    end
    return false
end

local function pushOffAmenities(actor,bounds,clearance)
    for _,amenity in ipairs(bounds.amenities or{})do
        local rx=(amenity.kind=="swing"and 82 or amenity.kind=="cat_tower"and 70 or 62)+(clearance or 0)
        local ry=38+(clearance or 0)*.35
        local dx,dy=(actor.x-amenity.x)/math.max(1,rx),(actor.y-amenity.y)/math.max(1,ry)
        local length=math.sqrt(dx*dx+dy*dy)
        if length<1 then
            if length<.001 then dx,dy,length=0,-1,1 end
            actor.x=amenity.x+dx/length*(rx+2);actor.y=amenity.y+dy/length*(ry+2)
        end
    end
    actor.x=math.max(bounds.x1,math.min(bounds.x2,actor.x));actor.y=math.max(bounds.y1,math.min(bounds.y2,actor.y))
end

local function point(actor,bounds,fromX,fromY)
    local x,y
    local clearance=bodyRadius(actor.kind,true)
    for _=1,24 do
        x=bounds.x1+(bounds.x2-bounds.x1)*random(actor)
        y=bounds.y1+(bounds.y2-bounds.y1)*random(actor)
        if not blockedByGroundProp(x,y,bounds,clearance)and not blockedByAmenity(x,y,bounds,clearance)and
            clearPath(actor,fromX,fromY,x,y,bounds)then
            return x,y
        end
    end
    return bounds.x1+(bounds.x2-bounds.x1)*.18,bounds.y1+(bounds.y2-bounds.y1)*.25
end

local function amenityFits(actor,amenity)
    return amenity.kind=="ball"or(amenity.kind=="sand"and actor.kind=="mole")or
        (amenity.kind=="cat_tower"and actor.kind=="cat")or
        (amenity.kind=="swing"and(actor.kind=="monkey"or actor.kind=="cat"))
end

local function clearAmenity(actor)
    if actor.playAmenityRef and actor.playAmenityRef.reservedBy==actor.id then
        actor.playAmenityRef.reservedBy=nil
    end
    actor.playAmenity=nil;actor.playAmenityRef=nil;actor.playClock=nil
    actor.renderOffsetX=nil;actor.renderOffsetY=nil;actor.interactionLift=nil
    actor.shadowOffsetX=nil;actor.shadowAlpha=nil;actor.swingFrame=nil
end

local function beginWalk(actor,bounds,amenities)
    clearAmenity(actor)
    local usable={}
    for _,amenity in ipairs(amenities or{})do
        if amenityFits(actor,amenity)and not amenity.reservedBy and
            not blockedByGroundProp(amenity.x,amenity.y,bounds,bodyRadius(actor.kind,false))and
            clearPath(actor,actor.x,actor.y,amenity.x,amenity.y,bounds)then usable[#usable+1]=amenity end
    end
    if #usable>0 and random(actor)<.55 then
        local amenity=usable[math.floor(random(actor)*#usable)+1]
        actor.playAmenity=amenity.kind;actor.playAmenityRef=amenity;amenity.reservedBy=actor.id
        actor.targetX=amenity.x+(amenity.kind=="cat_tower"and-30 or 0)
        actor.targetY=amenity.y
    else actor.targetX,actor.targetY=point(actor,bounds,actor.x,actor.y)end
    actor.state,actor.timer="walk",0
end

local function moveTo(actor,x,y,speed,dt)
    local dx,dy=x-actor.x,y-actor.y
    local distance=math.sqrt(dx*dx+dy*dy)
    actor.interactionMoving=distance>1
    if distance<=1 then actor.x,actor.y=x,y;return true end
    if math.abs(dx)>1 then actor.facing=dx<0 and -1 or 1 end
    local step=math.min(distance,(speed or ART[actor.kind].speed)*dt)
    actor.x,actor.y=actor.x+dx/distance*step,actor.y+dy/distance*step
    return distance-step<=1
end

local function makeActor(item,index,bounds)
    local actor={id=item.id,kind=item.kind,seed=hash(item.id),clock=index*.43,
        facing=index%2==0 and -1 or 1,stops=index}
    actor.x,actor.y=point(actor,bounds)
    actor.targetX,actor.targetY=point(actor,bounds,actor.x,actor.y)
    if index%3==0 then actor.state,actor.timer="sleep",6+random(actor)*4
    elseif index%3==1 then actor.state,actor.timer="walk",0
    else actor.state,actor.timer="idle",1.5+random(actor)*2 end
    return actor
end

function Companions.new()
    return{animals={},byId={},bounds=boundsFor(1280,720),time=0,seed=73129,
        nextInteraction=7,interactionCursor=0,interactionHistory={}}
end

function Companions.setAmenities(state,amenities)
    if not state then return end
    local oldById={};for _,old in ipairs(state.amenities or{})do oldById[old.id]=old end
    local newById={}
    for _,amenity in ipairs(amenities or{})do
        local old=oldById[amenity.id]
        if old then amenity.reservedBy=old.reservedBy end
        newById[amenity.id]=amenity
    end
    state.amenities=amenities or{}
    state.bounds.amenities=state.amenities
    for _,actor in ipairs(state.animals or{})do if actor.playAmenityRef then
        actor.playAmenityRef=newById[actor.playAmenityRef.id]
        if not actor.playAmenityRef then clearAmenity(actor)end
    end end
    local alive={};for _,actor in ipairs(state.animals or{})do alive[actor.id]=true end
    for _,amenity in ipairs(state.amenities)do
        if amenity.reservedBy and not alive[amenity.reservedBy]then amenity.reservedBy=nil end
    end
    for _,actor in ipairs(state.animals or{})do if not actor.playAmenity then
        local clearance=bodyRadius(actor.kind,actor.state=="sleep")
        if blockedByAmenity(actor.x,actor.y,state.bounds,clearance)then pushOffAmenities(actor,state.bounds,clearance)end
        if blockedByAmenity(actor.targetX or actor.x,actor.targetY or actor.y,state.bounds,clearance)then
            actor.targetX,actor.targetY=point(actor,state.bounds,actor.x,actor.y)
        end
    end end
end

function Companions.setScenery(state,obstacles)
    if not state then return end
    state.scenery=obstacles or{}
    state.bounds.scenery=obstacles or{}
    for _,actor in ipairs(state.animals or{})do
        local clearance=bodyRadius(actor.kind,actor.state=="sleep")
        if actor.state~="interaction"and not actor.playAmenity and
            blockedByGroundProp(actor.x,actor.y,state.bounds,clearance)then
            actor.x,actor.y=point(actor,state.bounds)
        end
        if blockedByGroundProp(actor.targetX or actor.x,actor.targetY or actor.y,state.bounds,clearance)or
            not clearPath(actor,actor.x,actor.y,actor.targetX or actor.x,actor.targetY or actor.y,state.bounds)then
            actor.targetX,actor.targetY=point(actor,state.bounds,actor.x,actor.y)
        end
    end
end

function Companions.isSceneryBlocked(state,actor,x,y,asleep)
    if not state or not actor then return false end
    return blockedByGroundProp(x,y,state.bounds,bodyRadius(actor.kind,asleep==true))
end

local clearActorInteraction
function Companions.sync(state,traits,width,height)
    if not state then return 0 end
    local bounds=boundsFor(width or 1280,height or 720)
    bounds.scenery=state.bounds and state.bounds.scenery or{}
    state.bounds=bounds
    local wanted,keep=desiredAnimals(traits),{}
    for index,item in ipairs(wanted)do
        local actor=state.byId[item.id]
        if not actor then
            actor=makeActor(item,index,bounds)
            state.byId[item.id]=actor
        end
        actor.x=math.max(bounds.x1,math.min(bounds.x2,actor.x))
        actor.y=math.max(bounds.y1,math.min(bounds.y2,actor.y))
        actor.targetX=math.max(bounds.x1,math.min(bounds.x2,actor.targetX or actor.x))
        actor.targetY=math.max(bounds.y1,math.min(bounds.y2,actor.targetY or actor.y))
        keep[item.id]=true
    end
    for id in pairs(state.byId)do if not keep[id]then state.byId[id]=nil end end
    state.animals={}
    for _,item in ipairs(wanted)do state.animals[#state.animals+1]=state.byId[item.id]end
    if state.interaction then
        for _,actor in ipairs(state.interaction.actors)do
            if not keep[actor.id]then
                for _,participant in ipairs(state.interaction.actors)do
                    if keep[participant.id]then clearActorInteraction(participant,bounds)end
                end
                state.interaction=nil;state.nextInteraction=4;break
            end
        end
    end
    return #state.animals
end

local function available(state,kind,count,excluded)
    local found={};excluded=excluded or{}
    for _,actor in ipairs(state.animals or{})do
        if(not kind or actor.kind==kind)and not excluded[actor]and
            actor.state~="sleep"and actor.state~="interaction"and actor.state~="play"then
            found[#found+1]=actor
            if #found==count then return found end
        end
    end
end

local function interactionActors(state,kind)
    if kind=="cat_wand"then
        local monkey=available(state,"monkey",1);local cat=available(state,"cat",1)
        return monkey and cat and{monkey[1],cat[1]}or nil
    elseif kind=="banana_toss"then return available(state,"monkey",2)
    elseif kind=="mole_peek"then
        local mole=available(state,"mole",1);if not mole then return nil end
        local watcher
        for _,actor in ipairs(state.animals)do if actor~=mole[1]and actor.kind~="mole"then watcher=actor;break end end
        return watcher and{mole[1],watcher}or nil
    elseif kind=="chase_train"then
        local picked,used={},{}
        for _,wantedKind in ipairs({"monkey","mole","cat"})do
            local found=available(state,wantedKind,1,used)
            if found then picked[#picked+1]=found[1];used[found[1]]=true end
        end
        if #picked<3 then
            for _,actor in ipairs(state.animals)do if not used[actor]then
                picked[#picked+1]=actor;used[actor]=true;if #picked==3 then break end
            end end
        end
        return #picked==3 and picked or nil
    end
end

clearActorInteraction=function(actor,bounds)
    actor.interactionRole=nil;actor.interactionMoving=nil;actor.interactionLift=nil
    actor.renderOffsetY=nil
    beginWalk(actor,bounds)
end

local function finishInteraction(state)
    local interaction=state.interaction;if not interaction then return end
    for _,actor in ipairs(interaction.actors)do clearActorInteraction(actor,state.bounds)end
    state.interactionHistory[#state.interactionHistory+1]=interaction.kind
    if #state.interactionHistory>8 then table.remove(state.interactionHistory,1)end
    state.interaction=nil
    state.nextInteraction=9+stateRandom(state)*8
end

local function targetFormation(interaction,index)
    local kind=interaction.kind
    if kind=="cat_wand"then return interaction.x+(index==1 and -42 or 48),interaction.y
    elseif kind=="banana_toss"then return interaction.x+(index==1 and -48 or 48),interaction.y
    elseif kind=="mole_peek"then return interaction.x+(index==1 and 0 or 62),interaction.y
    else return interaction.x-(index-1)*52,interaction.y+(index-1)*4 end
end

local function startInteraction(state,forcedKind,preview)
    if state.interaction then finishInteraction(state)end
    local chosen,actors
    for offset=1,#INTERACTION_KINDS do
        local index=forcedKind and offset or((state.interactionCursor+offset-1)%#INTERACTION_KINDS+1)
        local kind=forcedKind or INTERACTION_KINDS[index]
        actors=interactionActors(state,kind)
        if actors then chosen=kind;state.interactionCursor=index;break end
        if forcedKind then break end
    end
    if not chosen then state.nextInteraction=5;return false end
    local bounds=state.bounds
    local margin=chosen=="banana_toss"and 92 or 76
    local width=math.max(1,bounds.x2-bounds.x1-margin*2)
    local interaction={kind=chosen,actors=actors,phase=preview and"play"or"gather",clock=preview and 2.2 or 0,
        duration=chosen=="chase_train"and 8 or 7,
        x=bounds.x1+margin+width*stateRandom(state),
        y=bounds.y1+(bounds.y2-bounds.y1)*(.20+.40*stateRandom(state))}
    interaction.runX=interaction.x
    for index,actor in ipairs(actors)do
        actor.state="interaction";actor.timer=0;actor.interactionRole=index
        if preview then actor.x,actor.y=targetFormation(interaction,index)end
    end
    state.interaction=interaction;state.nextInteraction=math.huge
    return true
end

local function updateInteraction(state,dt)
    local interaction=state.interaction;if not interaction then return end
    if interaction.phase=="gather"then
        local ready=true
        for index,actor in ipairs(interaction.actors)do
            local x,y=targetFormation(interaction,index)
            ready=moveTo(actor,x,y,(ART[actor.kind].speed or 20)*1.35,dt)and ready
        end
        interaction.clock=interaction.clock+dt
        if ready or interaction.clock>4 then interaction.phase="play";interaction.clock=0 end
        return
    end

    interaction.clock=interaction.clock+dt
    local t=interaction.clock
    if interaction.kind=="cat_wand"then
        local monkey,cat=interaction.actors[1],interaction.actors[2]
        monkey.facing=1;monkey.interactionMoving=false
        interaction.lureX=interaction.x+32+math.sin(t*2.05)*30
        interaction.lureY=interaction.y-22-math.abs(math.sin(t*2.05))*18
        moveTo(cat,interaction.lureX,interaction.y,58,dt)
        cat.facing=interaction.lureX<cat.x and -1 or 1
        local leap=math.max(0,math.sin(t*4.1))
        cat.interactionLift=math.floor(leap*10)
    elseif interaction.kind=="banana_toss"then
        local left,right=interaction.actors[1],interaction.actors[2]
        left.facing=1;right.facing=-1;left.interactionMoving=false;right.interactionMoving=false
        local throw=(t%1.6)/1.6
        local catcher=math.floor(t/1.6)%2==0 and right or left
        catcher.interactionLift=throw>.72 and math.floor(math.sin((throw-.72)/.28*math.pi)*7)or 0
    elseif interaction.kind=="mole_peek"then
        local mole,watcher=interaction.actors[1],interaction.actors[2]
        mole.facing=1;watcher.facing=-1;mole.interactionMoving=false;watcher.interactionMoving=false
        local cycle=t%3.2
        if cycle<1.05 then mole.renderOffsetY=math.floor(cycle/1.05*30)
        elseif cycle<1.9 then mole.renderOffsetY=30
        elseif cycle<2.25 then mole.renderOffsetY=math.floor((2.25-cycle)/.35*30)
        else mole.renderOffsetY=0 end
        watcher.interactionLift=cycle>1.82 and cycle<2.38 and math.floor(math.sin((cycle-1.82)/.56*math.pi)*9)or 0
    elseif interaction.kind=="chase_train"then
        local bounds=state.bounds
        interaction.runDirection=interaction.runDirection or 1
        interaction.runX=interaction.runX+interaction.runDirection*42*dt
        if interaction.runX>bounds.x2-20 then interaction.runDirection=-1
        elseif interaction.runX<bounds.x1+75 then interaction.runDirection=1 end
        for index,actor in ipairs(interaction.actors)do
            local x=interaction.runX-interaction.runDirection*(index-1)*52
            moveTo(actor,x,interaction.y+(index-1)*4,55-index*4,dt)
            actor.facing=interaction.runDirection
        end
    end
    if interaction.clock>=interaction.duration then finishInteraction(state)end
end

local function footprint(actor)
    return bodyRadius(actor.kind,actor.state=="sleep")*depthScaleForY(actor.y,actor._bounds)
end

local function separateActors(state)
    local animals,bounds=state.animals or{},state.bounds
    for _,actor in ipairs(animals)do actor._bounds=bounds end
    for _=1,2 do
        for left=1,#animals-1 do for right=left+1,#animals do
            local a,b=animals[left],animals[right]
            local lockA=a.state=="interaction"or a.state=="play"
            local lockB=b.state=="interaction"or b.state=="play"
            if not(lockA and lockB)then
                local dx,dy=b.x-a.x,b.y-a.y
                local distance=math.sqrt(dx*dx+dy*dy)
                local minimum=footprint(a)+footprint(b)+3
                if distance<minimum then
                    if distance<.01 then
                        dx=((a.seed+b.seed)%2==0)and 1 or-1;dy=.25;distance=math.sqrt(1.0625)
                    end
                    local overlap=minimum-distance
                    local shareA,shareB=.5,.5
                    if lockA then shareA,shareB=0,1 elseif lockB then shareA,shareB=1,0 end
                    a.x=a.x-dx/distance*overlap*shareA;a.y=a.y-dy/distance*overlap*shareA*.35
                    b.x=b.x+dx/distance*overlap*shareB;b.y=b.y+dy/distance*overlap*shareB*.35
                    a.x=math.max(bounds.x1,math.min(bounds.x2,a.x));a.y=math.max(bounds.y1,math.min(bounds.y2,a.y))
                    b.x=math.max(bounds.x1,math.min(bounds.x2,b.x));b.y=math.max(bounds.y1,math.min(bounds.y2,b.y))
                end
            end
        end end
    end
    for _,actor in ipairs(animals)do actor._bounds=nil end
end

local function keepActorsOffScenery(state)
    local bounds=state.bounds
    local ellipses={
        {x=bounds.width*.525,y=bounds.height*.93,rx=bounds.width*.055,ry=bounds.height*.045},
        {x=bounds.width*.785,y=bounds.height*.945,rx=bounds.width*.078,ry=bounds.height*.034},
    }
    for _,obstacle in ipairs(bounds.scenery or{})do ellipses[#ellipses+1]=obstacle end
    for _,actor in ipairs(state.animals or{})do
        if actor.state~="interaction"and not actor.playAmenity then
            local clearance=bodyRadius(actor.kind,actor.state=="sleep")
            for _,obstacle in ipairs(ellipses)do
                local rx=obstacle.rx+clearance;local ry=obstacle.ry+clearance*.42
                local dx=(actor.x-obstacle.x)/math.max(1,rx)
                local dy=(actor.y-obstacle.y)/math.max(1,ry)
                local length=math.sqrt(dx*dx+dy*dy)
                if length<1 then
                    if length<.001 then dx,dy,length=0,-1,1 end
                    actor.x=obstacle.x+dx/length*(rx+2)
                    actor.y=obstacle.y+dy/length*(ry+2)
                end
            end
            actor.x=math.max(bounds.x1,math.min(bounds.x2,actor.x))
            actor.y=math.max(bounds.y1,math.min(bounds.y2,actor.y))
        end
    end
end

local SWING_ANGLES={-.36,-.24,0,.24,.36,.24,0,-.24}
local function startAmenityPlay(actor)
    actor.state="play";actor.playClock=0
    local duration={ball=6.2,sand=6.4,cat_tower=5.4,swing=7.2}
    actor.timer=duration[actor.playAmenity]or 5
    actor.interactionMoving=false
end

local function updateAmenityPlay(actor,dt)
    actor.timer=(actor.timer or 0)-dt;actor.playClock=(actor.playClock or 0)+dt
    local t,kind=actor.playClock,actor.playAmenity
    actor.renderOffsetX=0;actor.renderOffsetY=0;actor.interactionLift=0
    actor.shadowOffsetX=0;actor.shadowAlpha=1
    if kind=="ball"then
        local phase=t*2.3
        actor.renderOffsetX=math.floor(math.sin(phase)*22)
        actor.shadowOffsetX=actor.renderOffsetX
        actor.interactionLift=math.floor(math.max(0,math.sin(phase*2))*8)
        actor.facing=math.cos(phase)>=0 and 1 or-1
        actor.interactionMoving=true
    elseif kind=="sand"then
        local cycle=t%3.2
        if cycle<.75 then actor.renderOffsetY=math.floor(cycle/.75*23)
        elseif cycle<1.65 then actor.renderOffsetY=23
        elseif cycle<2.15 then actor.renderOffsetY=math.floor((2.15-cycle)/.5*23)
        else actor.renderOffsetY=0 end
        actor.shadowAlpha=cycle<2.15 and .35 or 1
    elseif kind=="cat_tower"then
        if t<1.6 then
            local u=t/1.6;actor.renderOffsetX=math.floor(u*30);actor.renderOffsetY=math.floor(-u*76)
            actor.facing=1;actor.interactionMoving=true;actor.shadowAlpha=1-u*.65
        elseif t<2.75 then
            actor.renderOffsetX=30;actor.renderOffsetY=-76;actor.facing=-1;actor.shadowAlpha=.3
        elseif t<4.15 then
            local u=(t-2.75)/1.4
            actor.renderOffsetX=math.floor(30+58*u)
            actor.renderOffsetY=math.floor(-76*(1-u)-math.sin(u*math.pi)*22)
            actor.facing=1;actor.interactionMoving=true;actor.shadowOffsetX=math.floor(actor.renderOffsetX*u)
            actor.shadowAlpha=.3+.7*u
        else
            local settle=math.max(0,math.sin((t-4.15)*8)*(1-(t-4.15)/1.25))
            actor.renderOffsetX=88;actor.shadowOffsetX=88;actor.interactionLift=math.floor(settle*6)
        end
    elseif kind=="swing"then
        if t<5.6 then
            local frame=math.floor(t*5)%8+1;local angle=SWING_ANGLES[frame]
            actor.swingFrame=frame
            actor.renderOffsetX=math.floor(math.sin(angle)*58)
            actor.renderOffsetY=math.floor(-82+math.cos(angle)*58)
            actor.facing=(frame<=4 or frame==8)and 1 or-1
            actor.shadowAlpha=.42;actor.shadowOffsetX=math.floor(actor.renderOffsetX*.35)
        else
            local u=math.min(1,(t-5.6)/1.2);local angle=SWING_ANGLES[5]
            local startX,startY=math.sin(angle)*58,-82+math.cos(angle)*58
            actor.swingFrame=5;actor.renderOffsetX=math.floor(startX*(1-u)+35*u)
            actor.renderOffsetY=math.floor(startY*(1-u)-math.sin(u*math.pi)*12)
            actor.facing=1;actor.shadowAlpha=.42+.58*u;actor.shadowOffsetX=actor.renderOffsetX
        end
    end
end

local function finishAmenityPlay(actor,bounds,amenities)
    if actor.playAmenity=="cat_tower"or actor.playAmenity=="swing"or actor.playAmenity=="ball"then
        actor.x=math.max(bounds.x1,math.min(bounds.x2,actor.x+(actor.renderOffsetX or 0)))
    end
    beginWalk(actor,bounds,amenities)
end

function Companions.update(state,dt)
    if not state then return end
    state.time=(state.time or 0)+dt
    local bounds=state.bounds or boundsFor(1280,720)
    if state.interaction then updateInteraction(state,dt)
    else
        state.nextInteraction=(state.nextInteraction or 7)-dt
        if state.nextInteraction<=0 then startInteraction(state)end
    end
    for _,actor in ipairs(state.animals or{})do
        actor.clock=(actor.clock or 0)+dt
        if actor.state=="interaction"then
            -- Pair/group movement is controlled by updateInteraction.
        elseif actor.state=="walk"then
            local dx,dy=(actor.targetX or actor.x)-actor.x,(actor.targetY or actor.y)-actor.y
            local distance=math.sqrt(dx*dx+dy*dy)
            if distance<1 then
                actor.stops=(actor.stops or 0)+1
                if actor.playAmenity then
                    startAmenityPlay(actor)
                elseif actor.stops%3==actor.seed%3 then
                    actor.state,actor.timer="sleep",6+random(actor)*6
                else
                    actor.state,actor.timer="idle",1.5+random(actor)*3
                end
            else
                if math.abs(dx)>1 then actor.facing=dx<0 and -1 or 1 end
                local speed=(ART[actor.kind].speed or 20)*depthScaleForY(actor.y,bounds)*
                    (actor.kind=="cat"and(.88+.12*math.sin(actor.clock*.7))or 1)
                local step=math.min(distance,speed*dt)
                actor.x,actor.y=actor.x+dx/distance*step,actor.y+dy/distance*step
            end
        elseif actor.state=="play"then
            updateAmenityPlay(actor,dt)
            if actor.timer<=0 then finishAmenityPlay(actor,bounds,state.amenities)end
        else
            actor.timer=(actor.timer or 0)-dt
            if actor.timer<=0 then beginWalk(actor,bounds,state.amenities)end
        end
    end
    separateActors(state)
    keepActorsOffScenery(state)
end

local function drawPixelZ(x,y,size)
    love.graphics.rectangle("fill",x,y,size*4,size)
    love.graphics.rectangle("fill",x+size*3,y+size,size,size)
    love.graphics.rectangle("fill",x+size*2,y+size*2,size,size)
    love.graphics.rectangle("fill",x+size,y+size*3,size,size)
    love.graphics.rectangle("fill",x,y+size*4,size*4,size)
end

local function drawSleepMark(actor,depth,light,time)
    local phase=((time or 0)*7+actor.seed%11)%12
    local rise=math.floor(phase*.5)
    local tint=.68+.32*(light or 1)
    local direction=actor.facing or 1
    local headHeight=actor.kind=="mole"and 58 or(actor.kind=="cat"and 48 or 45)
    local x=math.floor(actor.x+direction*10*depth)
    local y=math.floor(actor.y-headHeight*depth-rise)
    local alpha=.72+.22*math.sin((time or 0)*1.6+actor.seed%7)
    love.graphics.setColor(.76*tint,.92*tint,.79*tint,alpha)
    for index=0,2 do
        local size=index==2 and 2 or 1
        local px=x+direction*index*9-(direction<0 and size*4 or 0)
        local py=y-index*10
        drawPixelZ(px,py,size)
    end
end

local function drawActor(actor,light,time,bounds)
    local entry=load(actor.kind)
    if not entry then return end
    local asleep=actor.state=="sleep"
    local row=asleep and"sleep"or"walk"
    local frame
    if asleep then frame=math.floor((actor.clock or 0)*2.2)%FRAMES+1
    elseif actor.state=="walk"or(actor.state=="interaction"and actor.interactionMoving)then
        frame=math.floor((actor.clock or 0)*7)%FRAMES+1
    else frame=1 end
    local spec=entry.spec
    local moving=actor.state=="walk"or(actor.state=="interaction"and actor.interactionMoving)
    local bob=moving and math.floor(math.abs(math.sin((actor.clock or 0)*math.pi*3))*2)or 0
    local depth=depthScaleForY(actor.y,bounds)
    local scale=spec.scale*depth
    local flip=(actor.facing or 1)*spec.nativeFacing
    local brightness=.57+.43*(light or 1)
    love.graphics.setColor(0,0,0,.22*(.72+.28*(light or 1))*(actor.shadowAlpha or 1))
    love.graphics.ellipse("fill",math.floor(actor.x+(actor.shadowOffsetX or 0)),math.floor(actor.y+2),
        (asleep and spec.sleepShadowX or spec.shadowX)*depth,spec.shadowY*depth)
    love.graphics.setColor(brightness,brightness,brightness,1)
    local image=asleep and entry.sleep or entry.walk
    local cellW=asleep and spec.sleepCellW or spec.cellW
    local foot=asleep and spec.sleepFoot or spec.foot
    local drawX=actor.x+(actor.renderOffsetX or 0)
    local drawY=actor.y-bob+(actor.renderOffsetY or 0)-(actor.interactionLift or 0)
    love.graphics.draw(image,entry.quads[row][frame],math.floor(drawX),math.floor(drawY),0,
        scale*flip,scale,cellW/2,foot)
    if asleep then drawSleepMark(actor,depth,light,time)end
    love.graphics.setColor(1,1,1,1)
end

local function drawProp(props,name,frame,x,y,scale,originY,flip)
    local row=PROP_ROWS[name]
    love.graphics.draw(props.image,props.quads[row][frame%FRAMES+1],math.floor(x),math.floor(y),0,
        (flip or 1)*scale,scale,32,originY or 32)
end

local function drawInteraction(state,light,pass,splitY)
    local interaction=state.interaction;if not interaction or interaction.phase~="play"then return end
    local selected=not pass or(pass=="behind"and interaction.y<(splitY or math.huge))or
        (pass=="front"and interaction.y>=(splitY or-math.huge))
    if not selected then return end
    local props=loadProps();if not props then return end
    local frame=math.floor(interaction.clock*8)%FRAMES
    local brightness=.62+.38*(light or 1)
    love.graphics.setColor(brightness,brightness,brightness,1)
    if interaction.kind=="cat_wand"then
        local monkey,cat=interaction.actors[1],interaction.actors[2]
        local handX,handY=monkey.x+9,monkey.y-25
        local tipX,tipY=monkey.x+34,monkey.y-42
        local lureX=interaction.lureX or interaction.x+24
        local lureY=interaction.lureY or interaction.y-28
        love.graphics.setLineWidth(4);love.graphics.setColor(.07*brightness,.11*brightness,.08*brightness,1)
        love.graphics.line(math.floor(handX),math.floor(handY),math.floor(tipX),math.floor(tipY))
        love.graphics.setLineWidth(2);love.graphics.setColor(.67*brightness,.48*brightness,.25*brightness,1)
        love.graphics.line(math.floor(handX),math.floor(handY-1),math.floor(tipX),math.floor(tipY-1))
        love.graphics.setLineWidth(1);love.graphics.setColor(.88*brightness,.77*brightness,.48*brightness,1)
        love.graphics.line(math.floor(tipX),math.floor(tipY),math.floor(lureX),math.floor(lureY+7))
        love.graphics.setColor(brightness,brightness,brightness,1)
        drawProp(props,"feather",frame,lureX,lureY+8,.46,52,cat.facing)
        if cat.interactionLift and cat.interactionLift>6 then
            drawProp(props,"sparkle",frame,cat.x,cat.y-22,.23,32,1)
        end
    elseif interaction.kind=="banana_toss"then
        local left,right=interaction.actors[1],interaction.actors[2]
        local cycle=math.floor(interaction.clock/1.6)%2
        local t=(interaction.clock%1.6)/1.6
        local fromX,toX=left.x,right.x;if cycle==1 then fromX,toX=toX,fromX end
        local x=fromX+(toX-fromX)*t
        local y=interaction.y-28-math.sin(t*math.pi)*38
        drawProp(props,"banana",frame,x,y,.45,32,cycle==0 and 1 or -1)
        if t>.88 then drawProp(props,"sparkle",frame,toX,interaction.y-25,.28,32,1)end
    elseif interaction.kind=="mole_peek"then
        local mole=interaction.actors[1]
        drawProp(props,"dirt",frame,mole.x,mole.y+5,.58,48,1)
        local cycle=interaction.clock%3.2
        if cycle>1.86 and cycle<2.38 then
            drawProp(props,"puff",frame,mole.x,mole.y-18,.38,32,1)
            drawProp(props,"sparkle",frame,interaction.actors[2].x,interaction.y-39,.22,32,1)
        end
    elseif interaction.kind=="chase_train"then
        for index,actor in ipairs(interaction.actors)do
            if(math.floor(interaction.clock*7)+index)%3==0 then
                drawProp(props,"puff",frame,actor.x-actor.facing*15,actor.y+1,.28,32,1)
            end
        end
    end
    love.graphics.setLineWidth(1);love.graphics.setColor(1,1,1,1)
end

function Companions.draw(state,light,pass,splitY,groundOffsetX)
    if not state then return 0 end
    love.graphics.push()
    love.graphics.translate(math.floor(groundOffsetX or 0),0)
    table.sort(state.animals,function(a,b)
        if a.y==b.y then return a.id<b.id end
        return a.y<b.y
    end)
    local drawn=0
    for _,actor in ipairs(state.animals)do
        local selected=not pass or(pass=="behind"and actor.y<(splitY or math.huge))or
            (pass=="front"and actor.y>=(splitY or-math.huge))
        if selected then drawActor(actor,light,state.time,state.bounds);drawn=drawn+1 end
    end
    drawInteraction(state,light,pass,splitY)
    love.graphics.pop()
    return drawn
end

-- 오프스크린 검수에서 걷기·휴식·수면을 한 화면에 강제로 배치한다.
function Companions.preparePreview(state)
    local bounds=state and state.bounds
    if not bounds then return end
    local count=math.max(1,#state.animals)
    for index,actor in ipairs(state.animals)do
        actor.x=bounds.x1+(bounds.x2-bounds.x1)*(index-.5)/count
        actor.y=bounds.y1+(bounds.y2-bounds.y1)*(.22+((index-1)%3)*.31)
        actor.facing=index%2==0 and -1 or 1
        actor.state=({"walk","idle","sleep"})[(index-1)%3+1]
        actor.timer=8
        actor.targetX=math.min(bounds.x2,actor.x+42*actor.facing)
        actor.targetY=actor.y
    end
    -- 가장 작은 고양이는 전경 나무 사이에 완전히 묻히지 않도록 검수 장면의
    -- 가까운 공터에 둔다. 실제 플레이에서는 다른 동료처럼 계속 산책한다.
    for _,actor in ipairs(state.animals)do if actor.kind=="cat"then
        actor.x=bounds.x1+(bounds.x2-bounds.x1)*.28
        actor.y=bounds.y1+(bounds.y2-bounds.y1)*.86
        actor.targetX=actor.x+36;actor.targetY=actor.y
    end end
    for _,actor in ipairs(state.animals)do
        local clearance=bodyRadius(actor.kind,actor.state=="sleep")
        if blockedByGroundProp(actor.x,actor.y,bounds,clearance)then
            actor.x,actor.y=point(actor,bounds)
        end
        if blockedByGroundProp(actor.targetX,actor.targetY,bounds,clearance)or
            not clearPath(actor,actor.x,actor.y,actor.targetX,actor.targetY,bounds)then
            actor.targetX,actor.targetY=point(actor,bounds,actor.x,actor.y)
        end
    end
    separateActors(state)
    keepActorsOffScenery(state)
end

-- 네 상호작용을 같은 조건에서 오프스크린 캡처하기 위한 결정적 진입점.
function Companions.prepareInteractionPreview(state,kind)
    if not state or not interactionActors(state,kind)then return false end
    if not startInteraction(state,kind,true)then return false end
    updateInteraction(state,0)
    return true
end

-- 구매한 놀이터를 동료가 실제로 사용하는 장면을 결정적으로 검수한다.
function Companions.prepareAmenityPreview(state,kind)
    if not state then return false end
    local amenity
    for _,candidate in ipairs(state.amenities or{})do
        if candidate.kind==kind then amenity=candidate;break end
    end
    if not amenity then return false end
    if state.interaction then finishInteraction(state)end
    local selected
    for _,actor in ipairs(state.animals or{})do
        if amenityFits(actor,amenity)then
            clearAmenity(actor)
            actor.x,actor.y=amenity.x+(kind=="cat_tower"and-30 or 0),amenity.y
            actor.targetX,actor.targetY=amenity.x,amenity.y
            actor.playAmenity=kind;actor.playAmenityRef=amenity;amenity.reservedBy=actor.id
            startAmenityPlay(actor);updateAmenityPlay(actor,0)
            actor.interactionRole=nil;actor.interactionMoving=nil
            selected=actor;break
        end
    end
    if not selected then return false end
    -- 동작 검수 장면에서는 비참여 동료를 시설 밖에 세워 접점과 실루엣을 가리지 않는다.
    local index=0
    for _,actor in ipairs(state.animals or{})do if actor~=selected then
        clearAmenity(actor);index=index+1
        actor.x=state.bounds.x1+index*54;actor.y=state.bounds.y1+index*12
        actor.targetX,actor.targetY=actor.x,actor.y;actor.state="idle";actor.timer=20
    end end
    return true
end

function Companions.prepareScalePreview(state,asleep)
    if not state then return false end
    if state.interaction then finishInteraction(state)end
    local bounds=state.bounds
    local byKind={}
    for _,actor in ipairs(state.animals)do if not byKind[actor.kind]then byKind[actor.kind]=actor end end
    if not(byKind.monkey and byKind.mole and byKind.cat)then return false end
    state.animals={byKind.monkey,byKind.mole,byKind.cat}
    for index,kind in ipairs({"monkey","mole","cat"})do
        local actor=byKind[kind]
        actor.x=bounds.x1+100+(index-1)*185;actor.y=bounds.y1+(bounds.y2-bounds.y1)*.80
        actor.facing=1;actor.state=asleep and"sleep"or"idle";actor.timer=20
        actor.interactionRole=nil;actor.interactionMoving=nil;actor.interactionLift=nil;actor.renderOffsetY=nil
    end
    separateActors(state)
    keepActorsOffScenery(state)
    return true
end

function Companions.prepareDepthPreview(state)
    if not state then return false end
    if state.interaction then finishInteraction(state)end
    local monkeys={}
    for _,actor in ipairs(state.animals)do if actor.kind=="monkey"then
        monkeys[#monkeys+1]=actor;if #monkeys==3 then break end
    end end
    if #monkeys<3 then return false end
    local bounds=state.bounds
    state.animals=monkeys
    for index,actor in ipairs(monkeys)do
        local depth=(index-1)/2
        actor.x=bounds.x1+48+(index-1)*118
        actor.y=bounds.y1+(bounds.y2-bounds.y1)*(.08+.84*depth)
        actor.targetX,actor.targetY=actor.x,actor.y
        actor.facing=1;actor.state=index==2 and"sleep"or"idle";actor.timer=20
        actor.interactionRole=nil;actor.interactionMoving=nil;actor.interactionLift=nil
        actor.renderOffsetX=nil;actor.renderOffsetY=nil
    end
    separateActors(state)
    keepActorsOffScenery(state)
    return true
end

Companions.INTERACTION_KINDS=INTERACTION_KINDS

return Companions
