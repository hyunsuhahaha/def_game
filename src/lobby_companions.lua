-- 로비에서 생활하는 해금 동물 동료. 전투 수치와는 완전히 분리된 표현 계층이다.
-- 승인된 전투 몸체를 걷기에 그대로 쓰고, 별도 고정 픽셀 수면 아틀라스만 추가한다.
local Companions={}

local FRAMES=6
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
    return{animals={},byId={},bounds=boundsFor(1280,720),time=0}
end

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
    return #state.animals
end

function Companions.update(state,dt)
    if not state then return end
    state.time=(state.time or 0)+dt
    local bounds=state.bounds or boundsFor(1280,720)
    for _,actor in ipairs(state.animals or{})do
        actor.clock=(actor.clock or 0)+dt
        if actor.state=="walk"then
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
    elseif actor.state=="walk"then frame=math.floor((actor.clock or 0)*7)%FRAMES+1
    else frame=1 end
    local spec=entry.spec
    local bob=actor.state=="walk"and math.floor(math.abs(math.sin((actor.clock or 0)*math.pi*3))*2)or 0
    local scale=spec.scale
    local flip=(actor.facing or 1)*spec.nativeFacing
    local brightness=.57+.43*(light or 1)
    love.graphics.setColor(0,0,0,.22*(.72+.28*(light or 1)))
    love.graphics.ellipse("fill",math.floor(actor.x),math.floor(actor.y+2),spec.shadowX,spec.shadowY)
    love.graphics.setColor(brightness,brightness,brightness,1)
    local image=asleep and entry.sleep or entry.walk
    love.graphics.draw(image,entry.quads[row][frame],math.floor(actor.x),math.floor(actor.y-bob),0,
        scale*flip,scale,spec.cellW/2,spec.foot)
    if asleep then drawSleepMark(actor,scale,light,time)end
    love.graphics.setColor(1,1,1,1)
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

return Companions
