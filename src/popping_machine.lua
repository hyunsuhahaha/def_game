local Art={}
local machine,grain,impact,machineQuads,grainQuads,impactQuads

local function load()
    if machine then return end
    machine=love.graphics.newImage("assets/automation/popping-machine-atlas-pixel-v1.png")
    grain=love.graphics.newImage("assets/projectiles/puffed-rice-atlas-pixel-v1.png")
    impact=love.graphics.newImage("assets/fx/puffed-rice-impact-atlas-pixel-v1.png")
    machine:setFilter("nearest","nearest");grain:setFilter("nearest","nearest");impact:setFilter("nearest","nearest")
    machineQuads={};grainQuads={};impactQuads={}
    for i=0,5 do machineQuads[i+1]=love.graphics.newQuad(i*256,0,256,192,machine:getDimensions())end
    for i=0,3 do grainQuads[i+1]=love.graphics.newQuad(i*128,0,128,128,grain:getDimensions())end
    for i=0,5 do impactQuads[i+1]=love.graphics.newQuad(i*192,0,192,192,impact:getDimensions())end
end

local function target(mode,x,y,used,range)
    local best,bestD
    for _,node in ipairs(mode._popperWorld.nodes or{})do
        if node.rushTree and node.active and not node.treeEmergence and not used[node]then
            local d=(node.x-x)^2+(node.y-y)^2
            if d<=range*range and(not bestD or d<bestD)then best,bestD=node,d end
        end
    end
    return best
end

local function fireNearby(mode,machineValue)
    if mode.rainSuppressFire then return false end
    if mode.flameStream and mode.flameStreamCovers then local s=mode.flameStream
        if mode.flameStreamCovers(s.x,s.y,s.nx,s.ny,s.reach,s.halfWidth,machineValue.x,machineValue.y)then return true end
    end
    for _,node in ipairs(mode._popperWorld.nodes or{})do
        if node.active and node.burning and(node.x-machineValue.x)^2+(node.y-machineValue.y)^2<=125^2 then return true end
    end
    for _,spot in ipairs(mode.oilTrail or{})do
        if spot.ignited and(spot.x-machineValue.x)^2+(spot.y-machineValue.y)^2<=95^2 then return true end
    end
    return false
end

function Art.spawn(mode,game)
    if(mode.permanentTraits.scorePopperUnlock or 0)<=0 then return false end
    local live=0;for _,v in ipairs(mode.poppingMachines)do if v.life<48 then live=live+1 end end
    if live>=1+math.floor(mode.permanentTraits.scorePopperExtra or 0)then return false end
    local Maps=require("src.clearcut_maps");local angle=love.math.random()*math.pi*2
    local x,y=Maps.constrain(game.world,game.player.x+math.cos(angle)*220,game.player.y+math.sin(angle)*150,70)
    mode.poppingMachineSequence=mode.poppingMachineSequence+1
    local value={id=mode.poppingMachineSequence,x=x,y=y,state="cold",heat=0,life=0,shotCooldown=0,facing=1,shake=0}
    mode.poppingMachines[#mode.poppingMachines+1]=value;return value
end

local function launch(mode,value)
    local first=target(mode,value.x,value.y,{},720)
    if not first then value.state,value.heat="cold",0;return false end
    local dx=first.x-value.x;value.facing=dx<0 and-1 or 1;value.state,value.recoil="recoil",.28
    mode.puffedRiceShots[#mode.puffedRiceShots+1]={x=value.x+value.facing*75,y=value.y-65,fromX=value.x+value.facing*75,fromY=value.y-65,
        target=first,t=0,dur=.30,used={},contacts=0,maxContacts=3+math.floor(mode.permanentTraits.scorePopperBounces or 0),
        damage=4+(mode.permanentTraits.scorePopperDamage or 0),spin=0}
    if mode._popperGame and mode._popperGame.feedback then mode._popperGame.feedback:play("popper",true)end
    if mode._popperGame and mode._popperGame.camera then
        mode._popperGame.camera.trauma=math.min(1,(mode._popperGame.camera.trauma or 0)+.18)
    end
    return true
end

function Art.update(mode,dt,game)
    if not mode.scoreAttack or(mode.permanentTraits.scorePopperUnlock or 0)<=0 then return false end
    mode._popperWorld,mode._popperGame=game.world,game
    mode.poppingMachineTimer=mode.poppingMachineTimer-dt
    if mode.poppingMachineTimer<=0 then mode.poppingMachineTimer=28;Art.spawn(mode,game)end
    for i=#mode.poppingMachines,1,-1 do local v=mode.poppingMachines[i]
        v.life=v.life+dt;v.shake=math.max(0,(v.shake or 0)-dt);v.recoil=math.max(0,(v.recoil or 0)-dt)
        if mode.rainSuppressFire and v.state=="heating"then v.state,v.heat="cold",0 end
        if v.state=="cold"and fireNearby(mode,v)then v.state="heating" end
        if v.state=="heating"then
            v.heat=v.heat+dt;v.shake=.08
            local heatTime=math.max(1.2,2.8-(mode.permanentTraits.scorePopperHeat or 0))
            if v.heat>=heatTime then launch(mode,v);v.heat=0 end
        elseif v.state=="recoil"and v.recoil<=0 then v.state="cold"end
        if v.life>=48 then table.remove(mode.poppingMachines,i)end
    end
    for i=#mode.puffedRiceShots,1,-1 do local p=mode.puffedRiceShots[i]
        if not p.target or not p.target.active then
            local replacement=target(mode,p.x,p.y,p.used,620)
            if replacement then p.fromX,p.fromY,p.target,p.t,p.dur=p.x,p.y,replacement,0,.22 else p.target=nil end
        end
        if not p.target then table.remove(mode.puffedRiceShots,i)else
            p.t=math.min(p.dur,p.t+dt);p.spin=p.spin+dt*9;local u=p.t/p.dur
            p.x=p.fromX+(p.target.x-p.fromX)*u;p.y=p.fromY+(p.target.y-p.fromY)*u-math.sin(u*math.pi)*68
            if p.t>=p.dur then
                local hit=p.target;p.x,p.y=hit.x,hit.y-28;p.used[hit]=true;p.contacts=p.contacts+1
                hit.rushHp=(hit.rushHp or hit.rushMaxHp or 1)-p.damage
                if game.world.impactNode then game.world:impactNode(hit,game,true)end
                if hit.rushHp<=0 then mode:fellTree(hit,game)end
                -- 생존 여부와 무관하게 남은 접촉 횟수만 보고 다음 나무로 직행한다.
                local nextTarget=p.contacts<p.maxContacts and target(mode,hit.x,hit.y,p.used,620)or nil
                local angle=nextTarget and math.atan2(nextTarget.y-hit.y,nextTarget.x-hit.x)
                    or math.atan2(hit.y-p.fromY,hit.x-p.fromX)
                mode.puffedRiceImpacts[#mode.puffedRiceImpacts+1]={x=hit.x,y=hit.y-42,age=0,life=.48,angle=angle}
                if nextTarget then p.fromX,p.fromY,p.target,p.t,p.dur=hit.x,hit.y-28,nextTarget,0,.22
                else table.remove(mode.puffedRiceShots,i)end
            end
        end
    end
    for i=#mode.puffedRiceImpacts,1,-1 do local v=mode.puffedRiceImpacts[i];v.age=v.age+dt;if v.age>=v.life then table.remove(mode.puffedRiceImpacts,i)end end
    return true
end

function Art.queue(mode,queue)
    load()
    for _,v in ipairs(mode.poppingMachines or{})do queue[#queue+1]={x=v.x,y=v.y,anchorY=v.y,sortBias=.002,draw=function()
        local frame=v.state=="cold"and 1 or(v.state=="recoil"and 5 or math.min(4,2+math.floor((v.heat or 0)*1.5)))
        local jitter=(v.shake or 0)>0 and math.sin((v.life or 0)*70)*2 or 0
        love.graphics.setColor(0,0,0,.32);love.graphics.ellipse("fill",v.x,v.y+5,58,13)
        love.graphics.setColor(1,1,1,1);love.graphics.draw(machine,machineQuads[frame],v.x+jitter,v.y,0,.68*v.facing,.68,128,174)
    end}end
    for _,p in ipairs(mode.puffedRiceShots or{})do queue[#queue+1]={x=p.x,y=p.y,anchorY=p.y,sortBias=.01,draw=function()
        local frame=math.floor((p.spin or 0)*1.6)%4+1;love.graphics.setColor(1,1,1,1);love.graphics.draw(grain,grainQuads[frame],p.x,p.y,p.spin,.52,.52,64,64)
    end}end
    for _,v in ipairs(mode.puffedRiceImpacts or{})do queue[#queue+1]={x=v.x,y=v.y,anchorY=v.y,sortBias=.02,draw=function()
        local frame=math.min(6,math.floor(v.age/v.life*6)+1);love.graphics.setColor(1,1,1,1);love.graphics.draw(impact,impactQuads[frame],v.x,v.y,v.angle or 0,.82,.82,96,96)
    end}end
end

function Art.load()load()end
return Art
