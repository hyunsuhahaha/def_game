-- 로비에서 생활하는 해금 동물 동료. 전투 수치와는 완전히 분리된 표현 계층이다.
-- 승인된 전투 몸체를 걷기에 그대로 쓰고, 별도 고정 픽셀 수면 아틀라스만 추가한다.
local Companions={}

local FRAMES=6
local INTERACTION_KINDS={"cat_wand","banana_toss","mole_peek","chase_train"}
local PROP_ROWS={feather=0,banana=1,sparkle=2,dirt=3,puff=4}
local ART={
    monkey={
        walk="assets/characters/companions/graduate-monkey-atlas-pixel-v3.png",
        sleep="assets/characters/companions/lobby-monkey-sleep-atlas-pixel-v1.png",
        cellW=128,cellH=128,foot=118,scale=.42,nativeFacing=1,speed=24,shadowX=18,shadowY=5,
    },
    mole={
        walk="assets/characters/ingame/coin-miner-mole-atlas-pixel-v3.png",
        sleep="assets/characters/companions/lobby-mole-sleep-atlas-pixel-v1.png",
        cellW=192,cellH=384,foot=380,scale=.29,nativeFacing=-1,speed=19,shadowX=24,shadowY=7,
    },
    cat={
        walk="assets/characters/companions/gray-oil-cat-atlas-pixel-v1.png",
        sleep="assets/characters/companions/lobby-cat-sleep-atlas-pixel-v1.png",
        cellW=128,cellH=128,foot=118,scale=.60,nativeFacing=-1,speed=31,shadowX=21,shadowY=5,
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
            quads.sleep[frame+1]=love.graphics.newQuad(frame*spec.cellW,0,
                spec.cellW,spec.cellH,sleep:getDimensions())
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
        x1=math.floor(width*.39),x2=math.floor(width*.88),
        y1=math.floor(height*.70),y2=math.floor(height*.895),
    }
end

local function point(actor,bounds)
    return bounds.x1+(bounds.x2-bounds.x1)*random(actor),
        bounds.y1+(bounds.y2-bounds.y1)*random(actor)
end

local function beginWalk(actor,bounds)
    actor.targetX,actor.targetY=point(actor,bounds)
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
    actor.targetX,actor.targetY=point(actor,bounds)
    if index%3==0 then actor.state,actor.timer="sleep",6+random(actor)*4
    elseif index%3==1 then actor.state,actor.timer="walk",0
    else actor.state,actor.timer="idle",1.5+random(actor)*2 end
    return actor
end

function Companions.new()
    return{animals={},byId={},bounds=boundsFor(1280,720),time=0,seed=73129,
        nextInteraction=7,interactionCursor=0,interactionHistory={}}
end

local clearActorInteraction
function Companions.sync(state,traits,width,height)
    if not state then return 0 end
    local bounds=boundsFor(width or 1280,height or 720)
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
        if(not kind or actor.kind==kind)and not excluded[actor]then
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
    elseif kind=="mole_peek"then return interaction.x+(index==1 and 0 or 48),interaction.y
    else return interaction.x-(index-1)*34,interaction.y+(index-1)*3 end
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
        y=bounds.y1+(bounds.y2-bounds.y1)*(.30+.48*stateRandom(state))}
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
        interaction.lureX=interaction.x+18+math.sin(t*2.05)*42
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
            local x=interaction.runX-interaction.runDirection*(index-1)*34
            moveTo(actor,x,interaction.y+(index-1)*3,55-index*4,dt)
            actor.facing=interaction.runDirection
        end
    end
    if interaction.clock>=interaction.duration then finishInteraction(state)end
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
                if actor.stops%3==actor.seed%3 then
                    actor.state,actor.timer="sleep",6+random(actor)*6
                else
                    actor.state,actor.timer="idle",1.5+random(actor)*3
                end
            else
                if math.abs(dx)>1 then actor.facing=dx<0 and -1 or 1 end
                local speed=(ART[actor.kind].speed or 20)*(actor.kind=="cat"and(.88+.12*math.sin(actor.clock*.7))or 1)
                local step=math.min(distance,speed*dt)
                actor.x,actor.y=actor.x+dx/distance*step,actor.y+dy/distance*step
            end
        else
            actor.timer=(actor.timer or 0)-dt
            if actor.timer<=0 then beginWalk(actor,bounds)end
        end
    end
end

local function drawPixelZ(x,y,size)
    love.graphics.rectangle("fill",x,y,size*4,size)
    love.graphics.rectangle("fill",x+size*3,y+size,size,size)
    love.graphics.rectangle("fill",x+size*2,y+size*2,size,size)
    love.graphics.rectangle("fill",x+size,y+size*3,size,size)
    love.graphics.rectangle("fill",x,y+size*4,size*4,size)
end

local function drawSleepMark(actor,scale,light,time)
    local phase=((time or 0)*7+actor.seed%11)%12
    local rise=math.floor(phase*.5)
    local tint=.68+.32*(light or 1)
    local direction=actor.facing or 1
    local headHeight=actor.kind=="mole"and 58 or(actor.kind=="cat"and 48 or 45)
    local x=math.floor(actor.x+direction*10)
    local y=math.floor(actor.y-headHeight-rise)
    local alpha=.72+.22*math.sin((time or 0)*1.6+actor.seed%7)
    love.graphics.setColor(.76*tint,.92*tint,.79*tint,alpha)
    for index=0,2 do
        local size=index==2 and 2 or 1
        local px=x+direction*index*9-(direction<0 and size*4 or 0)
        local py=y-index*10
        drawPixelZ(px,py,size)
    end
end

local function drawActor(actor,light,time)
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
    local scale=spec.scale
    local flip=(actor.facing or 1)*spec.nativeFacing
    local brightness=.57+.43*(light or 1)
    love.graphics.setColor(0,0,0,.22*(.72+.28*(light or 1)))
    love.graphics.ellipse("fill",math.floor(actor.x),math.floor(actor.y+2),spec.shadowX,spec.shadowY)
    love.graphics.setColor(brightness,brightness,brightness,1)
    local image=asleep and entry.sleep or entry.walk
    local drawY=actor.y-bob+(actor.renderOffsetY or 0)-(actor.interactionLift or 0)
    love.graphics.draw(image,entry.quads[row][frame],math.floor(actor.x),math.floor(drawY),0,
        scale*flip,scale,spec.cellW/2,spec.foot)
    if asleep then drawSleepMark(actor,scale,light,time)end
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

function Companions.draw(state,light,pass,splitY)
    if not state then return 0 end
    table.sort(state.animals,function(a,b)
        if a.y==b.y then return a.id<b.id end
        return a.y<b.y
    end)
    local drawn=0
    for _,actor in ipairs(state.animals)do
        local selected=not pass or(pass=="behind"and actor.y<(splitY or math.huge))or
            (pass=="front"and actor.y>=(splitY or-math.huge))
        if selected then drawActor(actor,light,state.time);drawn=drawn+1 end
    end
    drawInteraction(state,light,pass,splitY)
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
end

-- 네 상호작용을 같은 조건에서 오프스크린 캡처하기 위한 결정적 진입점.
function Companions.prepareInteractionPreview(state,kind)
    if not state or not interactionActors(state,kind)then return false end
    if not startInteraction(state,kind,true)then return false end
    updateInteraction(state,0)
    return true
end

Companions.INTERACTION_KINDS=INTERACTION_KINDS

return Companions
