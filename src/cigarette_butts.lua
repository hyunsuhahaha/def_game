-- Gameplay-only lingering embers. Times/probabilities are game tuning, not physics.
-- Absolute event times keep rolls and spark arrivals independent of render FPS.
local Butts = {lifetime=7, firstAttempt=.15, interval=.55, coldLifetime=1.5, baseChance=.90}

-- The flight owns endpoints and elapsed time, not a mutable x/y pair. Keep the
-- visible arc, billboard anchor and swept hit test on this single trajectory so
-- a newly thrown cigarette is valid from its very first rendered frame.
function Butts.flightPosition(flight,elapsed)
    elapsed=elapsed == nil and (flight.t or 0) or elapsed
    if flight.fallsOffMap then
        local approach=math.max(1e-6,flight.approachDur or 0)
        if elapsed>approach then
            local fallDuration=math.max(1e-6,flight.fallDuration or 1.4)
            local fall=math.max(0,math.min(1,(elapsed-approach)/fallDuration))
            -- Once it clears the ridge, the butt is no longer on a ground arc:
            -- it tumbles down the screen until it is genuinely out of view.
            local x=flight.x1+(flight.dropDrift or 0)*(fall+.12*math.sin(fall*math.pi*3))
            local y=flight.y1+(flight.dropDistance or 2600)*fall*fall
            return x,y,math.max(0,math.min(1,elapsed/math.max(1e-6,flight.dur or 0)))
        end
        local progress=math.max(0,math.min(1,elapsed/approach))
        local x=flight.x0+(flight.x1-flight.x0)*progress
        local y=flight.y0+(flight.y1-flight.y0)*progress-math.sin(progress*math.pi)*120
        return x,y,progress*(approach/math.max(approach,flight.dur or approach))
    end
    local duration=math.max(1e-6,flight.dur or 0)
    local progress=math.max(0,math.min(1,elapsed/duration))
    local x=flight.x0+(flight.x1-flight.x0)*progress
    local y=flight.y0+(flight.y1-flight.y0)*progress-math.sin(progress*math.pi)*120
    return x,y,progress
end

function Butts.fallProgress(flight,elapsed)
    if not flight.fallsOffMap then return 0 end
    elapsed=elapsed == nil and (flight.t or 0) or elapsed
    return math.max(0,math.min(1,(elapsed-(flight.approachDur or 0))/math.max(1e-6,flight.fallDuration or 1.4)))
end

function Butts.tip(butt,time)
    local progress=math.max(0,math.min(1,(time-butt.bornAt)/Butts.lifetime))
    local offset=(.482-progress*.18)*32
    return butt.x+math.cos(butt.angle)*offset,butt.y+math.sin(butt.angle)*offset
end

local function release(transfer)
    if transfer.target.cigaretteEmber == transfer then transfer.target.cigaretteEmber=nil end
end

function Butts.reset(mode)
    for _,transfer in ipairs(mode.emberTransfers or {}) do release(transfer) end
    for _,flight in ipairs(mode.molotovs or {}) do if flight.target then flight.target.igniting=nil end end
    mode.cigaretteButts,mode.emberTransfers,mode.emberArrivals,mode.cigaretteLandingImpacts={}, {}, {}, {}
    -- 나무→나무 확산 스파크(같은 이펙트를 재사용하는 별도 배열)도 함께 초기화한다.
    mode.treeSparks,mode.treeSparkArrivals={}, {}
    mode.smokerGroundTime=0
    mode.cigaretteHitStop=0
end

local function candidate(butt,mode,nodes)
    local target,targetKind,nearest=nil,nil,butt.radius*butt.radius+1
    for _,node in ipairs(nodes) do
        if node.rushTree and node.active and not node.burning and not node.cigaretteEmber then
            local distance=(node.x-butt.x)^2+(node.y-butt.y)^2
            if distance<=butt.radius^2 and distance<nearest then target,targetKind,nearest=node,"tree",distance end
        end
    end
    for _,enemy in ipairs(mode.enemies or {}) do
        if enemy.def and enemy.def.category=="plant" and enemy.hp>0 and not enemy.burning and not enemy.cigaretteEmber then
            local distance=(enemy.x-butt.x)^2+(enemy.y-butt.y)^2
            if distance<=butt.radius^2 and distance<nearest then target,targetKind,nearest=enemy,"enemy",distance end
        end
    end
    return target,targetKind,math.sqrt(nearest)
end

local function igniteTarget(mode,butt,target,targetKind,at,game,instant)
    if mode.rainSuppressFire or target.burning then return false end
    if targetKind=="enemy" then
        if target.hp<=0 or not mode:igniteEnemy(target,game,0,at) then return false end
        target.visualHit=math.max(target.visualHit or 0,instant and .20 or .16)
        target.impactKick=math.max(target.impactKick or 0,instant and .10 or .07)
        target.impactKickDir=(target.x-butt.x)>=0 and 1 or -1
    else
        if not target.active then return false end
        mode:beginTreeBurn(target,0)
        target.cigaretteIgnitedAt=at
        target.hitFlash=math.max(target.hitFlash or 0,instant and .22 or .18)
        target.hitShake=math.max(target.hitShake or 0,instant and .08 or .11)
        local direction=(target.x-butt.x)>=0 and 1 or -1
        target.swayVel=(target.swayVel or 0)+direction*(instant and 1.85 or 1.45)
    end
    mode.emberArrivals[#mode.emberArrivals+1]={x=target.x,y=target.y,startAt=at,
        expiresAt=at+(instant and .28 or .72),duration=instant and .28 or .72,
        scale=instant and (targetKind=="enemy"and .52 or .68)or nil,
        targetKind=targetKind,seed=butt.angle or 0,instant=instant}
    if instant then
        mode.cigaretteHitStop=math.max(mode.cigaretteHitStop or 0,.03)
        if game and game.feedback then game.feedback:play("butt_hit",true) end
    elseif game and game.feedback then game.feedback:play("ignite",true) end
    return true
end

-- The landing itself now lights one nearby target immediately. The persistent
-- butt still owns the later probabilistic spread, so its seven-second area role
-- remains intact while the throw has an immediate, readable result.
local function land(mode,flight,at,game)
    if flight.target then flight.target.igniting=nil end
    local butt={x=flight.x1,y=flight.y1,bornAt=at,expiresAt=at+Butts.lifetime,
        nextAttemptAt=at+Butts.firstAttempt,radius=flight.radius or (90+mode:levelOf("molotov")*20),
        angle=flight.landingAngle or .25,phase="smolder",attempts=0,wildfire=flight.wildfire}
    mode.cigaretteButts[#mode.cigaretteButts+1]=butt
    mode.cigaretteLandingImpacts=mode.cigaretteLandingImpacts or {}
    mode.cigaretteLandingImpacts[#mode.cigaretteLandingImpacts+1]={
        x=butt.x,y=butt.y,startAt=at,expiresAt=at+.42,angle=butt.angle
    }
    if game and game.feedback then game.feedback:play("ember_land",false) end
    if not mode.rainSuppressFire then
        local target,targetKind=candidate(butt,mode,game.world.nodes)
        if target then igniteTarget(mode,butt,target,targetKind,at,game,true) end
    end
    return butt
end

local function attempt(mode,butt,at,game)
    butt.attempts=butt.attempts+1; butt.lastAttemptAt=at
    butt.nextAttemptAt=at+Butts.interval
    local target,targetKind,distance=candidate(butt,mode,game.world.nodes)
    if not target then return end
    local heat=1-.15*(at-butt.bornAt)/Butts.lifetime
    local routeMultiplier=mode.skillBranch and mode:skillBranch("molotov")=="flame_route"and 1.35 or 1
    local permanentChance=mode.permanentTraits and mode.permanentTraits.cigaretteIgnitionChance or 0
    -- 불쏘시개(세계수 보상)의 대가. 설명에는 있었지만 실제로는 깎이지 않아서
    -- 순수 상향으로 굴러가고 있었다.
    local tinder=mode.scoreReward and mode:scoreReward("tinder") and .5 or 1
    local chance=math.min(.96,(Butts.baseChance+mode:levelOf("dry_forest")*.02+permanentChance)*routeMultiplier)
        *heat*(1-.12*distance/butt.radius)*tinder
    if love.math.random()>=chance then return end
    local duration=.12+.10*distance/butt.radius
    local tipX,tipY=Butts.tip(butt,at)
    local transfer={x=tipX,y=tipY,tx=target.x,ty=target.y,target=target,targetKind=targetKind,
        startAt=at,arrivesAt=at+duration,duration=duration,butt=butt}
    target.cigaretteEmber=transfer -- reserve one eligible target without marking it burning
    butt.lastTransferAt=at
    mode.emberTransfers[#mode.emberTransfers+1]=transfer
end

local function arrive(mode,transfer,at,game)
    local node=transfer.target
    local owned=node.cigaretteEmber==transfer
    release(transfer)
    if not owned or mode.rainSuppressFire or node.burning then return end
    if (node.x-transfer.butt.x)^2+(node.y-transfer.butt.y)^2>transfer.butt.radius^2 then return end
    igniteTarget(mode,transfer.butt,node,transfer.targetKind,at,game,false)
end

function Butts.update(mode,dt,game)
    if dt<=0 then return end
    local start=mode.smokerGroundTime or 0
    local finish=start+dt
    -- Landing creates the persistent ground object and one immediate ignition.
    for i=#mode.molotovs,1,-1 do
        local flight=mode.molotovs[i]
        local remaining=math.max(0,flight.dur-flight.t)
        flight.t=flight.t+dt
        if remaining<=dt then
            if flight.fallsOffMap then
                if flight.target then flight.target.igniting=nil end
            else
                land(mode,flight,start+remaining,game)
            end
            table.remove(mode.molotovs,i)
        end
    end
    if mode.rainSuppressFire then
        for _,transfer in ipairs(mode.emberTransfers) do release(transfer) end
        mode.emberTransfers={}
        mode.emberArrivals={}
        for _,butt in ipairs(mode.cigaretteButts) do
            if butt.phase=="smolder" then
                butt.phase="wet"; butt.extinguishedAt=math.max(start,butt.bornAt)
                butt.coldUntil=butt.extinguishedAt+Butts.coldLifetime
            end
        end
    else
        -- Arrival wins ties, then expiry, then attempts. Never roll at/after expiry.
        while true do
            local event,object,index,at=nil,nil,nil,finish+1
            for i,transfer in ipairs(mode.emberTransfers) do
                if transfer.arrivesAt<at then event,object,index,at="arrive",transfer,i,transfer.arrivesAt end
            end
            for _,butt in ipairs(mode.cigaretteButts) do
                if butt.phase=="smolder" then
                    if butt.expiresAt<at then event,object,at="expire",butt,butt.expiresAt end
                    if butt.nextAttemptAt<butt.expiresAt and butt.nextAttemptAt<at then event,object,at="attempt",butt,butt.nextAttemptAt end
                end
            end
            if not event or at>finish+1e-9 then break end
            if event=="arrive" then arrive(mode,object,at,game); table.remove(mode.emberTransfers,index)
            elseif event=="expire" then object.phase="cold"; object.extinguishedAt=at; object.coldUntil=at+Butts.coldLifetime
            else attempt(mode,object,at,game) end
        end
    end
    for i=#mode.cigaretteButts,1,-1 do
        local butt=mode.cigaretteButts[i]
        if butt.coldUntil and finish>=butt.coldUntil then table.remove(mode.cigaretteButts,i) end
    end
    for i=#mode.emberArrivals,1,-1 do if finish>=mode.emberArrivals[i].expiresAt then table.remove(mode.emberArrivals,i) end end
    for i=#(mode.cigaretteLandingImpacts or {}),1,-1 do
        if finish>=mode.cigaretteLandingImpacts[i].expiresAt then table.remove(mode.cigaretteLandingImpacts,i) end
    end
    mode.smokerGroundTime=finish
end

return Butts
