-- 벌목장 한복판의 화덕 피자. 굽는 연료는 목재가 아니라 불이다.
--
-- 장작(목재)을 연료로 매기면 안 된다. 목재 수입은 재생 단계와 경과 시간에 따라
-- 0.14 x 1.75^(단계-1) x 2^(초/60) 으로 들어오므로 "장작 20" 같은 고정값은 몇 분
-- 만에 사실상 0이 된다. score_world_tree.lua 가 인게임 3택을 통째로 걷어낸 이유와
-- 정확히 같은 함정이다 — 요구량은 선형인데 수입이 지수라 비용이 사라진다.
--
-- 그래서 화덕은 반경 안에서 **지금 타고 있는 나무 수**만 먹는다. 이 값은 확산 확률,
-- 비, 플레이어의 조준으로 정해지므로 재생 단계가 올라간다고 저절로 커지지 않는다.
-- 그리고 진짜 값은 따로 치른다 — 화덕 옆 나무를 남겨야 화덕이 도는데, 남긴 나무는
-- 나무 허용량을 차지한다. 허용량은 이 모드에서 인플레이션이 없는 유일한 통화다.
--
-- 구워진 조각은 두더지와 졸업 원숭이가 알아서 걸어와서 먹는다. 플레이어는 아무것도
-- 누르지 않는다. 배달이 아니라 회식이라 화덕 앞에 모이는 그림이 나오고, 대신 왕복
-- 시간만큼 벌목을 쉰다. 그 손해를 확실히 이기도록 버프는 애매하지 않게 크다.
local Oven={}
local Maps=require("src.clearcut_maps")
local body,slice,hearthFire,aura,bodyQuads,sliceQuads,hearthFireQuads,auraBackQuads,auraFrontQuads

-- 기본 수치. 연구 노드가 전부 이 위에 더해진다.
--
-- 조각당 화력과 버프 지속은 함께 읽어야 한다. 동료 N명이 계속 버프 상태로 있으려면
-- 초당 N/지속 조각이 필요하고, 실제 공급은 (타는 나무 x 그루당 화력)/조각당 화력이다.
-- 즉 전원 상시가 되는 지점은 `타는 나무 = N x 조각당화력 / (지속 x 그루당화력)`.
-- 기본값(75, 30초, 그루당 1)에서 동료 3명이면 7.5그루를 계속 태워야 한다.
--
-- 이 값이 낮으면 화덕이 항상 꽉 차서 그냥 영구 스탯이 되고, 그러면 연구 트리의
-- 고정 수치와 구분되지 않는다. 화덕의 존재 이유는 **불을 크게 낼수록 동료가 세지는
-- 환산율**이지 늘 켜져 있는 배수가 아니다. 플레이어가 조작하는 것은 조각 배분이
-- 아니라(그건 전부 자동이다) 어디를 얼마나 태우느냐 하나뿐이다.
--
-- 주기를 늘릴 때 지속까지 같이 깎으면 안 된다. 버프가 짧게 깜빡거리면 화면에서
-- 누가 먹었는지 읽히지 않는다. 희소하게 나오되 한 번 먹으면 오래 가야 한다.
Oven.BASE_RADIUS=260        -- 열을 걷어오는 반경
Oven.BASE_HEAT_PER_TREE=1.0 -- 타는 나무 한 그루가 초당 올리는 화력
Oven.BASE_SLICE_COST=75     -- 조각 하나에 필요한 화력
Oven.BASE_SLICES=6          -- 한 판
Oven.BASE_CALL=520          -- 이 거리 안의 동료만 먹으러 온다
Oven.BASE_DURATION=30       -- 버프 지속
Oven.EAT_TIME=.8            -- 앉아서 먹는 시간
Oven.ARRIVE=64              -- 화덕 앞으로 인정하는 거리
Oven.FIREWORK_BURN_DURATION=4 -- 폭죽 직격 뒤 화실이 직접 타는 시간

local function traits(mode)return mode.permanentTraits or{} end

function Oven.radius(mode)
    return Oven.BASE_RADIUS+math.max(0,traits(mode).scoreOvenRadius or 0)
end
function Oven.heatPerTree(mode)
    return Oven.BASE_HEAT_PER_TREE+math.max(0,traits(mode).scoreOvenHeat or 0)
end
function Oven.sliceCost(mode)
    return math.max(2.5,Oven.BASE_SLICE_COST-math.max(0,traits(mode).scoreOvenSliceCost or 0))
end
function Oven.maxSlices(mode)
    return Oven.BASE_SLICES+math.floor(math.max(0,traits(mode).scoreOvenSlices or 0))
end
function Oven.callRadius(mode)
    return Oven.BASE_CALL+math.max(0,traits(mode).scoreOvenCall or 0)
end
function Oven.feastDuration(mode)
    return Oven.BASE_DURATION+math.max(0,traits(mode).scoreOvenDuration or 0)
end
function Oven.feastPower(mode)
    return 1+math.max(0,traits(mode).scoreOvenPower or 0)
end
-- 비가 오면 불이 죽으므로 화덕도 선다. `젖은 장작`이 그 구간을 일부 사 준다.
function Oven.rainKeep(mode)
    return math.min(1,math.max(0,traits(mode).scoreOvenRain or 0))
end
function Oven.stacks(mode)
    return (traits(mode).scoreOvenStack or 0)>0
end

-- 화덕 안에는 피자를 그리지 않는다. 지금 타는 나무에서 실제 화력이 들어올 때만
-- 전용 화실 불꽃을 강하게 재생하고, 남은 열만 있으면 낮은 잔불로 보여 준다.
function Oven.fireVisualState(mode)
    local oven=mode and mode.pizzaOven
    if not oven then return false,0,false end
    local rate=math.max(0,oven.heatRate or 0)
    local active=rate>0
    local stored=math.max(0,math.min(1,(oven.heat or 0)/Oven.sliceCost(mode)))
    local intensity=math.max(math.max(0,oven.fire or 0),active and math.min(1,.34+rate/8) or stored*.28)
    return intensity>.025,intensity,active
end

function Oven.spawn(mode,game)
    if (traits(mode).scoreOvenUnlock or 0)<=0 then return nil end
    if mode.pizzaOven then return mode.pizzaOven end
    -- 화덕은 돌아다니지 않는다. 맵 한가운데에 서서, 어디까지 벨지의 기준점이 된다.
    local world=game.world
    local x,y=Maps.constrain(world,(world.width or 3200)*.5,(world.height or 2000)*.5,90)
    mode.pizzaOven={x=x,y=y,heat=0,heatRate=0,slices=0,life=0,fire=0,flare=0,bakedTotal=0,servedTotal=0}
    return mode.pizzaOven
end

-- 폭죽이 화덕 본체를 맞히면 주변 불목이 없어도 화실이 직접 붙는다. 한 번의 직격은
-- 타는 나무 한 그루와 같은 화력을 4초만 보태므로 화덕의 핵심인 불목 운영을 대체하지
-- 않지만, 전용 화실 불꽃과 실제 열 생산이 함께 켜져 "맞았는데 무반응"인 상태는 없다.
function Oven.igniteInRadius(mode,x,y,radius)
    if mode.rainSuppressFire then return false end
    local oven=mode.pizzaOven
    if not oven then return false end
    local bodyRadius=72
    if (oven.x-x)^2+(oven.y-y)^2>(radius+bodyRadius)^2 then return false end
    oven.fireworkBurnTimer=math.max(oven.fireworkBurnTimer or 0,Oven.FIREWORK_BURN_DURATION)
    oven.fireworkIgnitedAt=mode.smokerGroundTime or 0
    oven.flare=math.max(.55,oven.flare or 0)
    return true
end

-- 반경 안에서 실제로 타고 있는 나무 수. 화덕의 유일한 연료다.
function Oven.burningNearby(mode,oven,game)
    local radius=Oven.radius(mode)
    local count=0
    for _,node in ipairs(game.world.nodes or{})do
        if node.rushTree and node.active and node.burning then
            local dx,dy=node.x-oven.x,node.y-oven.y
            if dx*dx+dy*dy<=radius*radius then count=count+1 end
        end
    end
    return count
end

local function companions(mode)
    local list=mode.moleCompanions or{}
    if #list==0 and mode.moleCompanion then return{mode.moleCompanion} end
    return list
end

-- 조각은 **보내는 순간 카운터에서 뺀다.** 그게 곧 예약이라, 도착했더니 딴 놈이
-- 먹어버려서 빈손으로 돌아가는 경우가 원천적으로 생기지 않는다. 헛걸음 한 번이면
-- 이 설비는 그냥 짜증나는 물건이 된다.
function Oven.reserve(mode,oven,game)
    if oven.slices<=0 then return false end
    local call=Oven.callRadius(mode)
    local stack=Oven.stacks(mode)
    local sent=false
    for _,companion in ipairs(companions(mode))do
        if oven.slices<=0 then break end
        local busy=companion.ovenState~=nil
        local fed=(companion.feastT or 0)>0
        -- 곱빼기가 없으면 이미 배부른 놈은 부르지 않는다. 있으면 겹쳐 먹으러 온다.
        if not busy and (stack or not fed) and not (companion.kind=="lumberjack" and not companion.prop) then
            local dx,dy=oven.x-companion.x,oven.y-companion.y
            if dx*dx+dy*dy<=call*call then
                companion.ovenState,companion.ovenEatT,companion.ovenStuck="walk",0,0
                companion.target=nil
                oven.slices=oven.slices-1
                sent=true
            end
        end
    end
    return sent
end

-- 두더지/원숭이가 화덕에 다녀오는 동안의 이동·식사. 벌목 루프보다 먼저 돌고,
-- 여기서 true 를 돌려주면 그 프레임의 나무 탐색은 통째로 건너뛴다.
function Oven.updateDiner(mode,companion,dt,game)
    if not companion.ovenState then return false end
    local oven=mode.pizzaOven
    if not oven then
        companion.ovenState,companion.ovenEatT=nil,0
        return false
    end
    if companion.ovenState=="eat" then
        companion.ovenEatT=(companion.ovenEatT or 0)+dt
        -- 앉아서 먹는 동안은 걷는 프레임을 느리게 돌려 우물거리는 정도로만 움직인다.
        companion.state="walk"
        companion.walkClock=(companion.walkClock or 0)+dt*3.0
        if companion.ovenEatT>=Oven.EAT_TIME then
            local power=Oven.feastPower(mode)
            -- 곱빼기는 남은 조각을 한 놈이 몰아 먹는 것이므로 배율이 겹쳐 쌓인다.
            local wasFed=(companion.feastT or 0)>0
            companion.feastPower=wasFed and(companion.feastPower or 0)+power or power
            companion.feastT=Oven.feastDuration(mode)
            -- 곱빼기로 시간을 갱신해도 이미 켜진 오라는 꺼졌다 다시 켜지지 않는다.
            companion.feastFxClock=wasFed and(companion.feastFxClock or 0)or 0
            companion.ovenState,companion.ovenEatT=nil,0
            oven.servedTotal=(oven.servedTotal or 0)+1
            oven.flare=.55
            if game and game.feedback then game.feedback:play("harvest",true) end
        end
        return true
    end
    local dx,dy=oven.x-companion.x,oven.y-companion.y
    local distance=math.sqrt(dx*dx+dy*dy)
    if math.abs(dx)>2 then companion.facing=dx<0 and -1 or 1 end
    if distance<=Oven.ARRIVE then
        companion.ovenState,companion.ovenEatT,companion.ovenStuck="eat",0,0
        return true
    end
    local step=math.min(distance-Oven.ARRIVE,(companion.speed or 210)*dt)
    local oldX,oldY=companion.x,companion.y
    companion.x,companion.y=Maps.constrain(game.world,
        companion.x+dx/distance*step,companion.y+dy/distance*step,42)
    -- 지형에 막혀 제자리걸음이면 포기하고 조각을 돌려놓는다. 계속 벽을 밀고 있으면
    -- 그 동료는 판이 끝날 때까지 일을 안 한다.
    if (companion.x-oldX)^2+(companion.y-oldY)^2<.01 then
        companion.ovenStuck=(companion.ovenStuck or 0)+dt
        if companion.ovenStuck>=.6 then
            companion.ovenState,companion.ovenEatT,companion.ovenStuck=nil,0,0
            oven.slices=math.min(Oven.maxSlices(mode),oven.slices+1)
            return false
        end
    else
        companion.ovenStuck=0
    end
    companion.state="walk"
    companion.walkClock=(companion.walkClock or 0)+dt*7.5
    return true
end

function Oven.update(mode,dt,game)
    if not mode.scoreAttack or (traits(mode).scoreOvenUnlock or 0)<=0 then return false end
    local oven=mode.pizzaOven or Oven.spawn(mode,game)
    if not oven then return false end
    oven.life=oven.life+dt
    oven.flare=math.max(0,(oven.flare or 0)-dt)

    if mode.rainSuppressFire then oven.fireworkBurnTimer=0 end
    local directFire=(oven.fireworkBurnTimer or 0)>0
    if directFire then oven.fireworkBurnTimer=math.max(0,oven.fireworkBurnTimer-dt) end
    local burning=Oven.burningNearby(mode,oven,game)
    local heatSources=burning+(directFire and 1 or 0)
    local rate=heatSources*Oven.heatPerTree(mode)
    if mode.rainSuppressFire then rate=rate*Oven.rainKeep(mode) end
    -- 아궁이 그림도 비가 적용된 실제 유효 화력을 따른다. 주변 나무가 시각적으로
    -- burning 상태여도 빗속에서 rate가 0이면 화덕만 활활 타는 모순이 생기면 안 된다.
    local fireTarget=rate>0 and math.min(1,heatSources/4) or 0
    oven.fire=oven.fire+(fireTarget-oven.fire)*math.min(1,dt*2.4)
    oven.heatRate=rate
    oven.heat=oven.heat+rate*dt

    local cost,cap=Oven.sliceCost(mode),Oven.maxSlices(mode)
    while oven.heat>=cost and oven.slices<cap do
        oven.heat=oven.heat-cost
        oven.slices=oven.slices+1
        oven.bakedTotal=(oven.bakedTotal or 0)+1
        oven.flare=.4
        if game and game.feedback then game.feedback:play("ember_land") end
    end
    -- 판이 다 차면 더 굽지 않는다. 화력이 무한히 고이면 비 구간이 공짜가 된다.
    if oven.slices>=cap then oven.heat=math.min(oven.heat,cost*.9) end

    Oven.reserve(mode,oven,game)

    for _,companion in ipairs(companions(mode))do
        if (companion.feastT or 0)>0 then
            companion.feastT=companion.feastT-dt
            companion.feastFxClock=(companion.feastFxClock or 0)+dt
            if companion.feastT<=0 then
                companion.feastT,companion.feastPower,companion.feastFxClock=0,nil,nil
            end
        end
    end
    return true
end

-- 그리기 ---------------------------------------------------------------------

local function load()
    if body then return end
    local ok,image=pcall(love.graphics.newImage,"assets/automation/pizza-oven-atlas-pixel-v1.png")
    if not ok then return end
    body=image;body:setFilter("nearest","nearest")
    bodyQuads={}
    for i=0,5 do bodyQuads[i+1]=love.graphics.newQuad(i*256,0,256,192,body:getDimensions()) end
    local sliceOk,sliceImage=pcall(love.graphics.newImage,"assets/automation/pizza-slice-atlas-pixel-v1.png")
    if sliceOk then
        slice=sliceImage;slice:setFilter("nearest","nearest")
        sliceQuads={}
        for i=0,3 do sliceQuads[i+1]=love.graphics.newQuad(i*96,0,96,96,slice:getDimensions()) end
    end
    local fireOk,fireImage=pcall(love.graphics.newImage,"assets/automation/pizza-oven-hearth-fire-atlas-pixel-v2.png")
    if fireOk then
        hearthFire=fireImage;hearthFire:setFilter("nearest","nearest")
        hearthFireQuads={}
        for i=0,7 do hearthFireQuads[i+1]=love.graphics.newQuad(i*128,0,128,96,hearthFire:getDimensions()) end
    end
    local auraOk,auraImage=pcall(love.graphics.newImage,"assets/fx/companion-feast-aura-atlas-pixel-v1.png")
    if auraOk then
        aura=auraImage;aura:setFilter("nearest","nearest")
        auraBackQuads={};auraFrontQuads={}
        for i=0,5 do
            auraBackQuads[i+1]=love.graphics.newQuad(i*192,0,192,192,aura:getDimensions())
            auraFrontQuads[i+1]=love.graphics.newQuad(i*192,192,192,192,aura:getDimensions())
        end
    end
end

-- 피자를 먹은 동안 몸과 장비가 함께 커진다. 중첩은 전투 수치만 크게 만들고
-- 실루엣은 최대 18%에서 멈춰 화면을 가리지 않는다.
function Oven.feastScale(companion)
    if not companion or(companion.feastT or 0)<=0 then return 1 end
    local power=math.max(1,companion.feastPower or 1)
    local target=math.min(1.18,1.14+(power-1)*.025)
    local fade=math.min(1,(companion.feastFxClock or 0)/.18,companion.feastT/.25)
    return 1+(target-1)*math.max(0,fade)
end

-- 드래곤볼식 불꽃 실루엣만 빌리되 광량과 입자는 눌렀다. 뒤 레이어가 몸을
-- 감싸고 앞 레이어는 발밑만 지나가므로 얼굴과 들고 있는 장비를 가리지 않는다.
function Oven.drawFeastAura(companion,front)
    if not companion or(companion.feastT or 0)<=0 then return end
    load()
    local quads=front and auraFrontQuads or auraBackQuads
    if not aura or not quads then return end
    local clock=companion.feastFxClock or 0
    local frame=math.floor(clock*10)%6+1
    local fade=math.min(1,clock/.18,companion.feastT/.25)
    local power=math.min(3,math.max(1,companion.feastPower or 1))
    local scale=.52*(1+(power-1)*.025)
    love.graphics.setColor(1,1,1,math.max(0,fade)*.92)
    love.graphics.draw(aura,quads[frame],companion.x,companion.y,0,scale,scale,96,160)
    love.graphics.setColor(1,1,1,1)
end

function Oven.queue(mode,queue)
    local oven=mode.pizzaOven
    if not oven then return end
    load()
    queue[#queue+1]={x=oven.x,y=oven.y,anchorY=oven.y,sortBias=.002,draw=function()
        love.graphics.setColor(0,0,0,.34);love.graphics.ellipse("fill",oven.x,oven.y+6,64,15)
        love.graphics.setColor(1,1,1,1)
        if body and bodyQuads then
            local frame=math.max(1,math.min(6,1+math.floor((oven.fire or 0)*4.99)))
            local jitter=(oven.flare or 0)>0 and math.sin((oven.life or 0)*64)*1.5 or 0
            love.graphics.draw(body,bodyQuads[frame],oven.x+jitter,oven.y,0,.70,.70,128,176)
        end
        if hearthFire and hearthFireQuads then
            local visible,intensity,active=Oven.fireVisualState(mode)
            if visible then
                local frame=math.floor((oven.life or 0)*(active and 14 or 6))%8+1
                local sx=.62+intensity*.08
                local sy=.47+intensity*.24
                love.graphics.setColor(1,1,1,active and .98 or .58)
                love.graphics.draw(hearthFire,hearthFireQuads[frame],oven.x,oven.y-32,0,sx,sy,64,84)
                love.graphics.setColor(1,1,1,1)
            end
        end
        if slice and sliceQuads then
            -- 구워진 조각은 화덕 위 선반에 실제로 쌓여 보인다. 몇 조각 남았는지가
            -- 숫자가 아니라 그림으로 읽혀야 누구를 부를지 판단이 된다.
            -- 아틀라스의 철제 선반은 캔버스 y=44 에 있다. 원점 (128,176)·배율 .70
            -- 기준으로 월드 y-92 이므로, 조각이 그 위에 얹혀 보이도록 -110 에서
            -- 시작해 위로 쌓는다.
            for index=1,oven.slices do
                local column=(index-1)%3
                local row=math.floor((index-1)/3)
                local sx=oven.x-36+column*36
                local sy=oven.y-110-row*22+math.sin((oven.life or 0)*2.2+index)*1.5
                love.graphics.setColor(1,1,1,1)
                love.graphics.draw(slice,sliceQuads[(index-1)%4+1],sx,sy,0,.46,.46,48,48)
            end
        end
    end}
end

function Oven.load()load()end
return Oven
