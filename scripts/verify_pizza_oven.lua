package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local Oven=require("src.pizza_oven")
local Traits=require("src.character_traits")

local function tree(x,y,burning)
    return{rushTree=true,active=true,x=x,y=y,rushHp=20,rushMaxHp=20,burning=burning or false}
end

local function newWorld(trees)
    local world={nodes={},width=3200,height=2000}
    for _,node in ipairs(trees)do world.nodes[#world.nodes+1]=node end
    return world
end

local function newMode(traits)
    return{scoreAttack=true,permanentTraits=traits,moleCompanions={},pizzaOven=nil,rainSuppressFire=false}
end

local function companion(x,y)
    return{x=x,y=y,speed=200,damage=4,attackDuration=.62,facing=1,walkClock=0,state="seek"}
end

local CENTER_X,CENTER_Y=1600,1000

-- 1. 잠긴 상태에서는 아무것도 서지 않는다.
do
    local mode=newMode({})
    local game={world=newWorld({}),player={x=0,y=0}}
    Oven.update(mode,.1,game)
    assert(mode.pizzaOven==nil,"locked oven still placed itself on the map")
end

-- 2. 화덕은 맵 한가운데에 서고, 불이 없으면 화력이 전혀 오르지 않는다.
--    목재가 아무리 쌓여도 굽지 않는다는 것이 이 설비의 핵심 규칙이다.
do
    local mode=newMode({scoreOvenUnlock=1})
    local game={world=newWorld({tree(CENTER_X+80,CENTER_Y,false),tree(CENTER_X-80,CENTER_Y,false)}),player={x=0,y=0}}
    Oven.update(mode,.1,game)
    local oven=mode.pizzaOven
    assert(oven,"unlocked oven did not appear")
    assert(math.abs(oven.x-CENTER_X)<1 and math.abs(oven.y-CENTER_Y)<1,"oven did not stand at map center")
    for _=1,600 do Oven.update(mode,.05,game)end
    assert(oven.heat==0 and oven.slices==0,"oven baked with no burning tree in range")
end

-- 3. 반경 안에서 타는 나무만 연료가 된다. 반경 밖의 불은 무시한다.
do
    local mode=newMode({scoreOvenUnlock=1})
    local inside={tree(CENTER_X+100,CENTER_Y,true),tree(CENTER_X-100,CENTER_Y,true)}
    local outside=tree(CENTER_X+900,CENTER_Y,true)
    local game={world=newWorld({inside[1],inside[2],outside}),player={x=0,y=0}}
    Oven.update(mode,.001,game)
    local oven=mode.pizzaOven
    assert(Oven.burningNearby(mode,oven,game)==2,"oven counted a burning tree outside its radius")
    -- 그루당 초당 1, 조각당 75 이므로 두 그루면 37.5초에 한 조각이다.
    for _=1,1800 do Oven.update(mode,.02,game)end
    assert(oven.slices==0,"two burning trees baked a slice before reaching 75 heat")
    for _=1,80 do Oven.update(mode,.02,game)end
    assert(oven.slices==1,"two burning trees over 37.5s did not bake exactly one slice, got "..oven.slices)
end

-- 4. 판이 다 차면 더 굽지 않고 화력이 무한히 고이지도 않는다.
do
    local mode=newMode({scoreOvenUnlock=1})
    local trees={}
    for i=1,8 do trees[i]=tree(CENTER_X+i*20,CENTER_Y,true)end
    local game={world=newWorld(trees),player={x=0,y=0}}
    for _=1,4000 do Oven.update(mode,.02,game)end
    local oven=mode.pizzaOven
    assert(oven.slices==Oven.BASE_SLICES,"oven exceeded or missed its slice cap, got "..oven.slices)
    assert(oven.heat<Oven.BASE_SLICE_COST,"oven banked unlimited heat after filling the tray")
end

-- 5. 비가 오면 화덕이 선다. `젖은 장작`이 그 구간을 부분적으로 사 준다.
do
    local trees={tree(CENTER_X,CENTER_Y,true),tree(CENTER_X+40,CENTER_Y,true)}
    local game={world=newWorld(trees),player={x=0,y=0}}
    local dry=newMode({scoreOvenUnlock=1})
    dry.rainSuppressFire=true
    for _=1,200 do Oven.update(dry,.02,game)end
    assert(dry.pizzaOven.heat==0 and dry.pizzaOven.slices==0,"rain did not stop the unupgraded oven")
    local wet=newMode({scoreOvenUnlock=1,scoreOvenRain=.4})
    wet.rainSuppressFire=true
    for _=1,200 do Oven.update(wet,.02,game)end
    assert(wet.pizzaOven.heat>0,"wet firewood research did not keep any heat during rain")
end

-- 6. 호출 거리 밖의 동료는 아예 부르지 않는다. 왕복 손실의 상한이 이 규칙 하나다.
do
    local mode=newMode({scoreOvenUnlock=1})
    local game={world=newWorld({tree(CENTER_X,CENTER_Y,true)}),player={x=0,y=0}}
    Oven.update(mode,.001,game)
    local oven=mode.pizzaOven
    local near=companion(CENTER_X+200,CENTER_Y)
    local far=companion(CENTER_X+Oven.BASE_CALL+400,CENTER_Y)
    mode.moleCompanions={near,far}
    oven.slices=2
    Oven.reserve(mode,oven,game)
    assert(near.ovenState=="walk","companion inside the call radius was not summoned")
    assert(far.ovenState==nil,"companion outside the call radius was summoned into a long round trip")
    assert(oven.slices==1,"reserving a slice did not take it off the tray")
end

-- 7. 조각은 보내는 순간 차감되므로 예약 수가 조각 수를 넘을 수 없다.
--    도착해서 빈손으로 돌아가는 헛걸음이 구조적으로 불가능해야 한다.
do
    local mode=newMode({scoreOvenUnlock=1})
    local game={world=newWorld({tree(CENTER_X,CENTER_Y,true)}),player={x=0,y=0}}
    Oven.update(mode,.001,game)
    local oven=mode.pizzaOven
    local crew={}
    for i=1,5 do crew[i]=companion(CENTER_X+120+i*10,CENTER_Y) end
    mode.moleCompanions=crew
    oven.slices=2
    Oven.reserve(mode,oven,game)
    local sent=0
    for _,value in ipairs(crew)do if value.ovenState then sent=sent+1 end end
    assert(sent==2 and oven.slices==0,"reservation count did not match available slices, sent "..sent)
end

-- 8. 왕복 → 식사 → 버프. 그리고 버프가 실제로 수치에 반영된다.
do
    local mode=newMode({scoreOvenUnlock=1})
    local game={world=newWorld({tree(CENTER_X,CENTER_Y,true)}),player={x=0,y=0}}
    Oven.update(mode,.001,game)
    local oven=mode.pizzaOven
    local diner=companion(CENTER_X+300,CENTER_Y)
    mode.moleCompanions={diner}
    oven.slices=1
    Oven.reserve(mode,oven,game)
    local handled=false
    for _=1,400 do
        handled=Oven.updateDiner(mode,diner,.02,game)
        if not handled then break end
    end
    assert(diner.ovenState==nil,"companion never finished its trip to the oven")
    assert(math.abs(diner.feastT-Oven.BASE_DURATION)<1e-6,"feast duration was not applied")
    assert(diner.feastPower==1,"base feast power should be 1")
    assert(oven.servedTotal==1,"oven did not record the serving")
end

-- 9. 곱빼기가 없으면 배부른 동료는 다시 부르지 않고, 있으면 중첩된다.
do
    local game={world=newWorld({tree(CENTER_X,CENTER_Y,true)}),player={x=0,y=0}}
    local plain=newMode({scoreOvenUnlock=1})
    Oven.update(plain,.001,game)
    local fed=companion(CENTER_X+150,CENTER_Y)
    fed.feastT,fed.feastPower=10,1
    plain.moleCompanions={fed}
    plain.pizzaOven.slices=3
    Oven.reserve(plain,plain.pizzaOven,game)
    assert(fed.ovenState==nil,"a fed companion was called back without the stacking capstone")

    local stacked=newMode({scoreOvenUnlock=1,scoreOvenStack=1})
    Oven.update(stacked,.001,game)
    local greedy=companion(CENTER_X+150,CENTER_Y)
    greedy.feastT,greedy.feastPower=10,1
    stacked.moleCompanions={greedy}
    stacked.pizzaOven.slices=3
    Oven.reserve(stacked,stacked.pizzaOven,game)
    assert(greedy.ovenState=="walk","stacking capstone did not call the fed companion back")
    for _=1,400 do if not Oven.updateDiner(stacked,greedy,.02,game)then break end end
    assert(greedy.feastPower==2,"stacked serving did not add a second helping, got "..tostring(greedy.feastPower))
end

-- 10. 버프는 시간이 지나면 정확히 풀린다.
do
    local mode=newMode({scoreOvenUnlock=1})
    local game={world=newWorld({}),player={x=0,y=0}}
    Oven.update(mode,.001,game)
    local diner=companion(CENTER_X,CENTER_Y)
    diner.feastT,diner.feastPower=1.0,1
    mode.moleCompanions={diner}
    for _=1,80 do Oven.update(mode,.02,game)end
    assert(diner.feastT==0 and diner.feastPower==nil,"feast buff did not expire cleanly")
end

-- 11. 공급이 실제로 모자라야 한다. 조각 배분은 전부 자동이므로 플레이어의 선택은
--     걸려 있지 않다. 걸려 있는 것은 환산율이다 — 조각이 남아돌면 화덕은 늘 꽉 차
--     있고, 그러면 연구 트리의 고정 수치와 구분되지 않는 영구 배수가 된다.
do
    local mode=newMode({scoreOvenUnlock=1})
    -- 동료 N명 상시 유지에 필요한 공급은 초당 N/지속 조각이다.
    local perSecond=1/Oven.BASE_SLICE_COST                  -- 불 한 그루가 뽑는 조각
    local sustained=perSecond*Oven.BASE_DURATION            -- 그루당 몇 명분인가
    assert(sustained<.5,"one burning tree alone sustains "..sustained.." companions; the oven is a flat permanent buff")
    local treesForThree=3*Oven.BASE_SLICE_COST/Oven.BASE_DURATION
    assert(treesForThree>=6,"three companions stay permanently fed on "..treesForThree.." burning trees")
    -- 주기를 늘리려고 지속을 깎으면 안 된다. 짧은 버프는 화면에서 깜빡거려 누가
    -- 먹었는지 읽히지 않는다. 희소하게 나오되 한 번 먹으면 오래 가야 한다.
    assert(Oven.BASE_DURATION>=30,"feast duration was cut instead of slowing production")
    -- 반경 안에서 그만큼 태우는 것이 기본 화덕의 실제 목표치다.
    assert(Oven.radius(mode)==260,"base radius drifted from the scarcity assumption")
end

-- 12. 연구 갈래 총계. 수치가 흔들리면 여기서 잡는다.
do
    local store=Traits.new(true)
    local count,ranks,cost=0,0,0
    local effects={}
    for _,node in ipairs(store:getScoreAttackNodes("universal"))do
        if node.id:match("^universal_oven")then
            count=count+1;ranks=ranks+node.max
            for _,value in ipairs(node.costs)do cost=cost+value end
            effects[node.effect]=(effects[node.effect]or 0)+node.value*node.max
            assert(node.scoreMode,"oven node is missing scoreMode")
        end
    end
    assert(count==10,"oven research node count changed, got "..count)
    assert(ranks==29,"oven research rank total changed, got "..ranks)
    assert(cost==2866,"oven research cost total changed, got "..cost)
    assert(effects.scoreOvenRadius==200,"radius branch total changed")
    assert(math.abs(effects.scoreOvenHeat-1.0)<1e-6,"heat branch total changed")
    assert(math.abs(effects.scoreOvenSliceCost-21)<1e-6,"dough branch total changed")
    assert(effects.scoreOvenCall==540,"call branch total changed")
    assert(effects.scoreOvenDuration==20,"duration branch total changed")
    assert(math.abs(effects.scoreOvenPower-1.4)<1e-6,"power branch total changed")
    assert(math.abs(effects.scoreOvenRain-.4)<1e-6,"rain branch total changed")

    -- 만렙 화덕의 실제 성능. 조각당 5.5 화력, 최대 9조각, 호출 1060.
    local maxed={scoreOvenUnlock=1,scoreOvenRadius=200,scoreOvenHeat=1.0,scoreOvenSliceCost=21,
        scoreOvenSlices=3,scoreOvenCall=540,scoreOvenDuration=20,scoreOvenPower=1.4,scoreOvenRain=.4,scoreOvenStack=1}
    local mode=newMode(maxed)
    assert(Oven.radius(mode)==460,"maxed radius wrong")
    assert(math.abs(Oven.heatPerTree(mode)-2.0)<1e-6,"maxed heat wrong")
    assert(math.abs(Oven.sliceCost(mode)-54)<1e-6,"maxed slice cost wrong")
    assert(Oven.maxSlices(mode)==9,"maxed slice count wrong")
    assert(Oven.callRadius(mode)==1060,"maxed call radius wrong")
    assert(Oven.feastDuration(mode)==50,"maxed duration wrong")
    assert(math.abs(Oven.feastPower(mode)-2.4)<1e-6,"maxed power wrong")
    assert(Oven.stacks(mode),"maxed oven lost its stacking capstone")
end

fixture.reset()
Oven.queue({pizzaOven={x=0,y=0,slices=3,life=1,fire=.5,flare=0}},{})
Oven.load()
print("PIZZA_OVEN_OK fuel=burning_trees_only center_placed=true radius=260 slice_cost=75 tray=6 "..
      "call=520 reservation=no_wasted_trips feast=30s_x2 rain_stops=true stacking_capstone=true nodes=10 ranks=29")
