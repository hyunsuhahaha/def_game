local Siege={}
local debrisImage,debrisQuads,emergenceImage,emergenceQuads
local CombatGeometry=require("src.combat_geometry")
local AttackArt=require("src.worldtree_attack_art")

local function load()
    if debrisImage then return end
    debrisImage=love.graphics.newImage("assets/fx/worldtree-siege-debris-atlas-v1.png")
    debrisImage:setFilter("nearest","nearest")
    debrisQuads={}
    for i=0,7 do debrisQuads[i+1]=love.graphics.newQuad(i*96,0,96,96,debrisImage:getDimensions()) end
    emergenceImage=love.graphics.newImage("assets/fx/worldtree/worldtree-emergence-atlas-v2.png")
    emergenceImage:setFilter("nearest","nearest")
    emergenceQuads={}
    for frame=0,5 do emergenceQuads[frame+1]=love.graphics.newQuad(frame*512,0,512,384,emergenceImage:getDimensions()) end
end

local function smooth(p)p=math.max(0,math.min(1,p));return p*p*(3-2*p)end

function Siege.startEmergence(mode,e,game)
    mode.worldTreeEmergence={boss=e,t=0,phaseT=0,phase="skyLead",skyLead=1.15,riseDuration=4.8,
        returnDuration=.8,duration=6.75,crownBreach=false,trunkImpact=false,canopyBurst=false,impact=false}
    e.worldTreeEmerging=true;e.worldTreeGrounded=true;e.worldTreeEmergenceProgress=0
    e.entranceAlpha=0;e.entranceOffsetY=1720;e.entranceScaleX=.86;e.entranceScaleY=.92
    e.moving=false
end

local function cameraBeat(game,vertical,trauma)
    if not game.camera then return end
    if game.camera.impulse then game.camera:impulse(0,vertical,0,.025) end
    game.camera.trauma=math.min(.42,(game.camera.trauma or 0)+trauma)
end

local function dirtBurst(mode,e,count,spread)
    mode.worldTreeDebris=mode.worldTreeDebris or {}
    for i=1,count do
        local side=i%2==0 and -1 or 1
        local life=.7+love.math.random()*.5
        mode.worldTreeDebris[#mode.worldTreeDebris+1]={kind="soil",frame=5+(i%4),x=e.x+side*(36+love.math.random()*spread),
            y=e.y+e.def.radius*.65-love.math.random()*18,h=8+love.math.random()*38,vh=65+love.math.random()*145,
            vx=side*(24+love.math.random()*105),vy=-8+love.math.random()*16,angle=love.math.random()*6.28,
            spin=(-1+love.math.random()*2)*7,life=life,scale=.62+love.math.random()*.48,color={.72,.54,.28}}
    end
end

local function canopyBurst(mode,e)
    mode.worldTreeDebris=mode.worldTreeDebris or {}
    for i=1,22 do
        local side=i%2==0 and -1 or 1
        mode.worldTreeDebris[#mode.worldTreeDebris+1]={kind="leaf",frame=1+(i%4),x=e.x+side*(32+love.math.random()*245),y=e.y-love.math.random()*24,
            h=250+love.math.random()*410,vh=42+love.math.random()*68,vx=side*(22+love.math.random()*62),vy=-24+love.math.random()*48,
            angle=love.math.random()*6.28,spin=(-1+love.math.random()*2)*5.5,life=2.3+love.math.random()*1.1}
    end
end

function Siege.updateEmergence(mode,dt,game)
    local state=mode.worldTreeEmergence
    if not state then return false end
    local e=state.boss
    if not e or e.hp<=0 then mode.worldTreeEmergence=nil;return false end
    state.t=math.min(state.duration+.4,state.t+dt)
    state.phaseT=state.phaseT+dt
    if state.phase=="skyLead" and state.phaseT>=state.skyLead then
        state.phase,state.phaseT="rise",0
    elseif state.phase=="rise" and state.phaseT>=state.riseDuration then
        state.phase,state.phaseT="return",0
    end
    local riseP=state.phase=="skyLead" and 0 or math.min(1,state.phaseT/state.riseDuration)
    if state.phase=="return" then riseP=1 end
    local rise=smooth(riseP)
    e.worldTreeEmerging=true;e.hp=e.maxHp;e.visualHit=0;e.visualAttack=0;e.moving=false
    e.worldTreeEmergenceProgress=riseP
    e.entranceOffsetY=(1-rise)*1720
    e.entranceAlpha=riseP<=0 and 0 or math.min(1,riseP*7)
    e.entranceScaleX=.86+rise*.14+math.sin(riseP*math.pi)*.028
    e.entranceScaleY=.92+rise*.08+math.sin(riseP*math.pi)*.018
    if riseP>=.18 and not state.crownBreach then
        state.crownBreach=true
        cameraBeat(game,12,.025)
        dirtBurst(mode,e,12,150)
    end
    if riseP>=.52 and not state.trunkImpact then
        state.trunkImpact=true
        cameraBeat(game,16,.035)
        dirtBurst(mode,e,18,220)
    end
    if riseP>=.36 and not state.canopyBurst then
        state.canopyBurst=true
        canopyBurst(mode,e)
        cameraBeat(game,9,.018)
    end
    if riseP>=.92 and not state.impact then
        state.impact=true
        cameraBeat(game,22,.055)
        dirtBurst(mode,e,34,280)
    end
    if state.phase=="return" and (state.cameraReturned or state.phaseT>=state.returnDuration+.2) then
        e.worldTreeEmerging=false;e.worldTreeEmergenceProgress=nil
        e.entranceAlpha,e.entranceOffsetY,e.entranceScaleX,e.entranceScaleY=nil,nil,nil,nil
        if e.scoreWorldTree then
            -- 기록 모드의 거대형은 외형과 등장 연출만 계승한다. HP 개념이 없는
            -- 모드라 캠페인 공격 패턴은 등장 종료 뒤에도 절대 켜지지 않는다.
            e.slamTimer,e.summonTimer,e.rootSpikeTimer,e.vineWhipTimer=math.huge,math.huge,math.huge,math.huge
        else
            e.slamTimer=e.def.slamInterval;e.summonTimer=e.def.summonInterval
        end
        mode.worldTreeEmergence=nil
        return false
    end
    return true
end

function Siege.damageStage(e)
    local p=math.max(0,e.hp)/math.max(1,e.maxHp)
    if p>.75 then return 0 elseif p>.50 then return 1 elseif p>.25 then return 2 else return 3 end
end

function Siege.spawnDamageDebris(mode,e,stage,game)
    mode.worldTreeDebris=mode.worldTreeDebris or {}
    local leaves=stage==1 and 12 or (stage==2 and 20 or 30)
    for i=1,leaves do
        local side=(i%2==0) and -1 or 1
        mode.worldTreeDebris[#mode.worldTreeDebris+1]={kind="leaf",frame=1+(i%4),x=e.x+side*(45+love.math.random()*190),y=e.y-love.math.random()*35,
            h=210+love.math.random()*470,vh=30+love.math.random()*80,vx=side*(18+love.math.random()*55),vy=-18+love.math.random()*36,
            angle=love.math.random()*6.28,spin=(-1+love.math.random()*2)*5,life=2.2+love.math.random()*1.2}
    end
    if stage>=2 then
        local player=game and game.player
        local targetX,targetY=player and player.x or e.x,player and player.y or e.y+e.def.radius
        local fromX,fromY=targetX-e.x,targetY-e.y
        local angle=math.atan2(fromY,fromX)
        local length=stage==3 and 350 or 310
        mode.worldTreeDebris[#mode.worldTreeDebris+1]={kind="branch",frame=5+stage%4,x=targetX,y=targetY,h=560,vh=-54,
            vx=0,vy=0,angle=angle,spin=(stage==2 and -1 or 1)*.32,life=2.35,scale=1,
            length=length,halfWidth=stage==3 and 42 or 36,fallTime=0,fallDuration=1.18,
            sourceX=e.x,sourceY=e.y,damage=stage==3 and 28 or 24}
    end
    dirtBurst(mode,e,10+stage*4,180)
end

function Siege.updateBoss(mode,e,dt,game)
    e.fixedX,e.fixedY=e.fixedX or e.x,e.fixedY or e.y
    e.x,e.y=e.fixedX,e.fixedY
    e.knockTimer,e.knockVX,e.knockVY=nil,nil,nil
    e.airborneT,e.airborneDuration,e.airbornePeak,e.airborneVX,e.airborneVY=nil,nil,nil,nil,nil
    local emerging=Siege.updateEmergence(mode,dt,game)
    if emerging then e.hp=e.maxHp;return true end
    local stage=Siege.damageStage(e)
    if e.scoreWorldTree then
        -- 기록 모드는 외형과 등장 연출만 재사용한다. 체력 구간 파편에는 플레이어를
        -- 겨냥하는 낙하 가지까지 섞여 있으므로 공격 타이머와 별도로 차단해야 한다.
        e.worldTreeDamageStage=stage
        return false
    end
    if stage>(e.worldTreeDamageStage or 0) then
        for s=(e.worldTreeDamageStage or 0)+1,stage do Siege.spawnDamageDebris(mode,e,s,game) end
    end
    e.worldTreeDamageStage=stage
    return false
end

local function branchHitsPlayer(d,player)
    local length=d.length or 310
    local halfWidth=d.halfWidth or 36
    local dx,dy=math.cos(d.angle)*length*.5,math.sin(d.angle)*length*.5
    return CombatGeometry.segmentDistanceSquared(player.x,player.y,d.x-dx,d.y-dy,d.x+dx,d.y+dy)
        <=(halfWidth+CombatGeometry.PLAYER_RADIUS)^2
end

function Siege.updateDebris(mode,dt,game)
    mode.worldTreeDebris=mode.worldTreeDebris or {}
    for i=#mode.worldTreeDebris,1,-1 do
        local d=mode.worldTreeDebris[i]
        if d.kind=="branch" and not d.landed then d.fallTime=(d.fallTime or 0)+dt end
        if d.kind=="branch" and d.landed then d.impactAge=(d.impactAge or 0)+dt end
        d.life=d.life-dt;d.x=d.x+d.vx*dt;d.y=d.y+d.vy*dt
        d.vx=d.vx*math.exp(-1.1*dt);d.vy=d.vy*math.exp(-1.6*dt)
        local previousH=d.h
        d.h=d.h+d.vh*dt;d.vh=d.vh-(d.kind=="branch" and 720 or 430)*dt
        d.angle=d.angle+d.spin*dt
        if d.h<=0 then
            d.h=0
            if d.kind=="branch" and previousH>0 and not d.landed then
                d.landed=true;d.vx,d.vy,d.vh,d.spin=0,0,0,0
                if game and game.player and branchHitsPlayer(d,game.player) then
                    d.hitPlayer=true
                    mode:damagePlayer(d.damage or 24,game)
                end
                if game and game.camera then game.camera.trauma=math.min(1,(game.camera.trauma or 0)+.12) end
                for n=1,26 do
                    local along=(love.math.random()-.5)*(d.length or 310)
                    local side=(love.math.random()-.5)*(d.halfWidth or 36)
                    local c,s=math.cos(d.angle),math.sin(d.angle)
                    local life=.55+love.math.random()*.45
                    mode.worldTreeDebris[#mode.worldTreeDebris+1]={kind=n%3==0 and "leaf" or "soil",frame=n%3==0 and 1+n%4 or 5+n%4,
                        x=d.x+c*along-s*side,y=d.y+s*along+c*side,h=4+love.math.random()*20,vh=55+love.math.random()*120,
                        vx=(love.math.random()-.5)*110,vy=(love.math.random()-.5)*35,angle=love.math.random()*6.28,
                        spin=(love.math.random()-.5)*10,life=life,scale=.55+love.math.random()*.4,color=n%3==0 and nil or {.72,.54,.28}}
                end
            else
                d.vh=math.abs(d.vh)*(d.kind=="branch" and .08 or .2);d.spin=d.spin*.35
            end
        end
        if d.life<=0 then table.remove(mode.worldTreeDebris,i) end
    end
end

function Siege.queue(mode,queue)
    local emergence=mode.worldTreeEmergence
    if emergence and emergence.boss then
        local e=emergence.boss
        local groundY=e.y+e.def.radius*.65
        queue[#queue+1]={x=e.x,y=groundY-.2,anchorY=e.y,draw=function()
            load();local p=emergence.phase=="skyLead" and math.min(1,emergence.phaseT/emergence.skyLead)*.18
                or (emergence.phase=="rise" and math.min(1,emergence.phaseT/emergence.riseDuration) or 1)
            local frame=math.max(1,math.min(6,1+math.floor(p*6)))
            local alpha=emergence.phase=="skyLead" and p*.75 or math.min(1,.48+p*1.4)
            love.graphics.setColor(1,1,1,alpha)
            love.graphics.draw(emergenceImage,emergenceQuads[frame],e.x,groundY+22,0,1.9,1.48,256,306)
        end}
    end
    for _,value in ipairs(mode.worldTreeDebris or {}) do local d=value
        if d.kind=="branch" and not d.landed then
            queue[#queue+1]={y=-180000+d.y*.001,ground=true,draw=function()
                AttackArt.drawBranchWarning(d,love.timer.getTime())
            end}
        elseif d.kind=="branch" and d.landed then
            queue[#queue+1]={y=-180000+d.y*.001,ground=true,draw=function()
                AttackArt.drawBranchImpact(d,love.timer.getTime())
            end}
        end
        queue[#queue+1]={x=d.x,y=d.y+.15,anchorY=d.y,draw=function()
            load();local alpha=math.min(1,d.life*2);local c=d.color or {1,1,1}
            love.graphics.setColor(c[1],c[2],c[3],alpha)
            if d.kind=="branch" then AttackArt.drawFallingBranch(d,love.timer.getTime())
            else
                local scale=.38*(d.scale or 1)
                love.graphics.draw(debrisImage,debrisQuads[d.frame],d.x,d.y-d.h,d.angle,scale,scale,48,48)
            end
        end}
    end
end

return Siege
