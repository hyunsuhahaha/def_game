-- Gameplay-only lingering embers. Times/probabilities are game tuning, not physics.
-- Absolute event times keep rolls and spark arrivals independent of render FPS.
local Butts = {lifetime=7, firstAttempt=1.1, interval=1, coldLifetime=1.5, baseChance=.42}

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
    mode.cigaretteButts,mode.emberTransfers,mode.emberArrivals={}, {}, {}
    mode.smokerGroundTime=0
end

local function land(mode,flight,at,game)
    if flight.target then flight.target.igniting=nil end
    local butt={x=flight.x1,y=flight.y1,bornAt=at,expiresAt=at+Butts.lifetime,
        nextAttemptAt=at+Butts.firstAttempt,radius=flight.radius or (90+mode:levelOf("molotov")*20),
        angle=flight.landingAngle or .25,phase="smolder",attempts=0}
    mode.cigaretteButts[#mode.cigaretteButts+1]=butt
    if game then
        mode:damageEnemiesInRadius(flight.x1,flight.y1,butt.radius,8+mode:levelOf("molotov")*5,game)
        mode:igniteEnemiesInRadius(flight.x1,flight.y1,butt.radius,game,0)
    end
    return butt
end

local function candidate(butt,nodes)
    local target,nearest=nil,butt.radius*butt.radius+1
    for _,node in ipairs(nodes) do
        if node.rushTree and node.active and not node.burning and not node.cigaretteEmber then
            local distance=(node.x-butt.x)^2+(node.y-butt.y)^2
            if distance<=butt.radius^2 and distance<nearest then target,nearest=node,distance end
        end
    end
    return target,math.sqrt(nearest)
end

local function attempt(mode,butt,at,game)
    butt.attempts=butt.attempts+1; butt.lastAttemptAt=at
    butt.nextAttemptAt=at+Butts.interval
    local target,distance=candidate(butt,game.world.nodes)
    if not target then return end
    local heat=1-.35*(at-butt.bornAt)/Butts.lifetime
    local chance=math.min(.75,Butts.baseChance+mode:levelOf("dry_forest")*.06)*heat*(1-.35*distance/butt.radius)
    if love.math.random()>=chance then return end
    local duration=.55+.25*distance/butt.radius
    local tipX,tipY=Butts.tip(butt,at)
    local transfer={x=tipX,y=tipY,tx=target.x,ty=target.y,target=target,
        startAt=at,arrivesAt=at+duration,duration=duration,butt=butt}
    target.cigaretteEmber=transfer -- reserve one tree, without marking it burning
    butt.lastTransferAt=at
    mode.emberTransfers[#mode.emberTransfers+1]=transfer
end

local function arrive(mode,transfer,at)
    local node=transfer.target
    local owned=node.cigaretteEmber==transfer
    release(transfer)
    if not owned or mode.rainSuppressFire or not node.active or node.burning then return end
    if (node.x-transfer.butt.x)^2+(node.y-transfer.butt.y)^2>transfer.butt.radius^2 then return end
    node.burning,node.burnTimer,node.fireTickTimer=true,0,0
    node.spreadDepth,node.emberChained=0,nil
    node.cigaretteIgnitedAt=at
    mode.emberArrivals[#mode.emberArrivals+1]={x=node.x,y=node.y,startAt=at,expiresAt=at+.65}
end

function Butts.update(mode,dt,game)
    if dt<=0 then return end
    local start=mode.smokerGroundTime or 0
    local finish=start+dt
    -- Landing only creates a ground object. No ignition or enemy damage here.
    for i=#mode.molotovs,1,-1 do
        local flight=mode.molotovs[i]
        local remaining=math.max(0,flight.dur-flight.t)
        flight.t=flight.t+dt
        if remaining<=dt then land(mode,flight,start+remaining,game); table.remove(mode.molotovs,i) end
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
            if event=="arrive" then arrive(mode,object,at); table.remove(mode.emberTransfers,index)
            elseif event=="expire" then object.phase="cold"; object.extinguishedAt=at; object.coldUntil=at+Butts.coldLifetime
            else attempt(mode,object,at,game) end
        end
    end
    for i=#mode.cigaretteButts,1,-1 do
        local butt=mode.cigaretteButts[i]
        if butt.coldUntil and finish>=butt.coldUntil then table.remove(mode.cigaretteButts,i) end
    end
    for i=#mode.emberArrivals,1,-1 do if finish>=mode.emberArrivals[i].expiresAt then table.remove(mode.emberArrivals,i) end end
    mode.smokerGroundTime=finish
end

return Butts
