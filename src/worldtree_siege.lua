local Siege={}
local debrisImage,debrisQuads,emergenceImage,emergenceQuads
local CombatGeometry=require("src.combat_geometry")

local function load()
    if debrisImage then return end
    debrisImage=love.graphics.newImage("assets/fx/worldtree-siege-debris-atlas-v1.png")
    debrisImage:setFilter("nearest","nearest")
    debrisQuads={}
    for i=0,7 do debrisQuads[i+1]=love.graphics.newQuad(i*96,0,96,96,debrisImage:getDimensions()) end
    emergenceImage=love.graphics.newImage("assets/fx/boss-entrance/boss-entrance-fx-atlas-pixel-v1.png")
    emergenceImage:setFilter("nearest","nearest")
    emergenceQuads={}
    for frame=0,5 do emergenceQuads[frame+1]=love.graphics.newQuad(frame*256,0,256,256,emergenceImage:getDimensions()) end
end

local function smooth(p)p=math.max(0,math.min(1,p));return p*p*(3-2*p)end

function Siege.startEmergence(mode,e,game)
    mode.worldTreeEmergence={boss=e,t=0,duration=3.35,crownBreach=false,trunkImpact=false,canopyBurst=false,impact=false}
    e.worldTreeEmerging=true;e.worldTreeGrounded=true;e.worldTreeEmergenceProgress=0
    e.entranceAlpha=0;e.entranceOffsetY=1320;e.entranceScaleX=.86;e.entranceScaleY=.92
    e.moving=false
end

local function cameraBeat(game,vertical,trauma)
    if not game.camera then return end
    if game.camera.impulse then game.camera:impulse(0,vertical,0,.025) end
    game.camera.trauma=math.min(.42,(game.camera.trauma or 0)+trauma)
end

local function dirtBurst(game,e,count,spread,color)
    if not (game.world and game.world.addParticle) then return end
    for i=1,count do
        local side=i%2==0 and -1 or 1
        game.world:addParticle(e.x+side*(36+love.math.random()*spread),e.y+e.def.radius*.65-love.math.random()*18,color,true,false)
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
    state.t=math.min(state.duration,state.t+dt)
    local p=state.t/state.duration
    local rise=smooth((p-.04)/.84)
    e.worldTreeEmerging=true;e.hp=e.maxHp;e.visualHit=0;e.visualAttack=0;e.moving=false
    e.worldTreeEmergenceProgress=p
    e.entranceOffsetY=(1-rise)*1320
    e.entranceAlpha=math.min(1,math.max(0,(p-.025)*14))
    e.entranceScaleX=.86+smooth((p-.04)/.66)*.14+math.sin(p*math.pi)*.035
    e.entranceScaleY=.92+rise*.08+math.sin(p*math.pi)*.022
    if p>=.26 and not state.crownBreach then
        state.crownBreach=true
        cameraBeat(game,22,.055)
        dirtBurst(game,e,10,150,{.46,.31,.12})
    end
    if p>=.58 and not state.trunkImpact then
        state.trunkImpact=true
        cameraBeat(game,34,.075)
        dirtBurst(game,e,14,220,{.55,.36,.13})
    end
    if p>=.42 and not state.canopyBurst then
        state.canopyBurst=true
        canopyBurst(mode,e)
        cameraBeat(game,18,.035)
    end
    if p>=.89 and not state.impact then
        state.impact=true
        cameraBeat(game,56,.14)
        dirtBurst(game,e,28,280,{.58,.39,.16})
    end
    if state.t>=state.duration then
        e.worldTreeEmerging=false;e.worldTreeEmergenceProgress=nil
        e.entranceAlpha,e.entranceOffsetY,e.entranceScaleX,e.entranceScaleY=nil,nil,nil,nil
        e.slamTimer=e.def.slamInterval;e.summonTimer=e.def.summonInterval
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
        local side=stage==2 and -1 or 1
        mode.worldTreeDebris[#mode.worldTreeDebris+1]={kind="branch",frame=5+stage%4,x=e.x+side*145,y=e.y-10,h=390,vh=45,
            vx=side*95,vy=28,angle=side*.25,spin=side*2.4,life=2.4,scale=stage==3 and 1.25 or 1,
            damage=stage==3 and 28 or 24}
    end
    if game.world and game.world.addParticle then
        for i=1,10+stage*4 do game.world:addParticle(e.x+(love.math.random()-.5)*180,e.y-love.math.random()*35,{.63,.39,.16},true,false) end
    end
end

function Siege.updateBoss(mode,e,dt,game)
    e.fixedX,e.fixedY=e.fixedX or e.x,e.fixedY or e.y
    e.x,e.y=e.fixedX,e.fixedY
    e.knockTimer,e.knockVX,e.knockVY=nil,nil,nil
    e.airborneT,e.airborneDuration,e.airbornePeak,e.airborneVX,e.airborneVY=nil,nil,nil,nil,nil
    local emerging=Siege.updateEmergence(mode,dt,game)
    if emerging then e.hp=e.maxHp;return true end
    local stage=Siege.damageStage(e)
    if stage>(e.worldTreeDamageStage or 0) then
        for s=(e.worldTreeDamageStage or 0)+1,stage do Siege.spawnDamageDebris(mode,e,s,game) end
    end
    e.worldTreeDamageStage=stage
    return false
end

local function branchHitsPlayer(d,player)
    local length=82*(d.scale or 1)
    local halfWidth=18*(d.scale or 1)
    local dx,dy=math.cos(d.angle)*length*.5,math.sin(d.angle)*length*.5
    return CombatGeometry.segmentDistanceSquared(player.x,player.y,d.x-dx,d.y-dy,d.x+dx,d.y+dy)
        <=(halfWidth+CombatGeometry.PLAYER_RADIUS)^2
end

function Siege.updateDebris(mode,dt,game)
    mode.worldTreeDebris=mode.worldTreeDebris or {}
    for i=#mode.worldTreeDebris,1,-1 do
        local d=mode.worldTreeDebris[i]
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
            load();local p=emergence.t/emergence.duration
            local frame=math.max(1,math.min(6,math.floor(p*7)+1))
            local alpha=math.min(1,p*5,(1-p)*7+.18)
            love.graphics.setColor(1,1,1,alpha)
            love.graphics.draw(emergenceImage,emergenceQuads[frame],e.x,groundY+14,0,2.85,1.72,128,190)
        end}
        queue[#queue+1]={x=e.x,y=groundY+.25,anchorY=e.y,draw=function()
            local p=emergence.t/emergence.duration
            local rootBurst=math.max(0,1-math.abs(p-.26)/.13)*.62
            local trunkBurst=math.max(0,1-math.abs(p-.58)/.13)*.78
            local finalBurst=math.max(0,1-math.abs(p-.89)/.16)
            local curtain=math.max(0,math.min(1,(p-.14)/.12,(.94-p)/.12))*.48
            local burst=math.max(rootBurst,trunkBurst,finalBurst,curtain)
            if burst<=0 then return end
            for i=1,22 do
                local side=i%2==0 and -1 or 1
                local lane=math.floor((i-1)/2)
                local px=e.x+side*(42+lane*30)
                local py=groundY+8-math.sin((i*.73)%3.14)*68*burst+(i%4)*5
                local size=3+(i%4)*2
                love.graphics.setColor(.10,.07,.025,.68*burst)
                love.graphics.rectangle("fill",math.floor(px-size-1),math.floor(py-size),size*2+2,size*2+1)
                love.graphics.setColor(i%3==0 and {.72,.48,.18,.94*burst} or {.43,.28,.09,.92*burst})
                love.graphics.rectangle("fill",math.floor(px-size+1),math.floor(py-size+1),size*2-1,size*2-2)
            end
        end}
    end
    for _,value in ipairs(mode.worldTreeDebris or {}) do local d=value
        if d.kind=="branch" and not d.landed then
            queue[#queue+1]={y=-180000+d.y*.001,ground=true,draw=function()
                local pulse=.65+math.sin((d.life or 0)*14)*.15
                love.graphics.push();love.graphics.translate(d.x,d.y);love.graphics.rotate(d.angle)
                love.graphics.setColor(.15,.08,.025,.48);love.graphics.ellipse("fill",0,0,45*(d.scale or 1),18*(d.scale or 1))
                love.graphics.setColor(1,.55,.18,pulse);love.graphics.setLineWidth(2)
                love.graphics.ellipse("line",0,0,45*(d.scale or 1),18*(d.scale or 1));love.graphics.setLineWidth(1)
                love.graphics.pop()
            end}
        end
        queue[#queue+1]={x=d.x,y=d.y+.15,anchorY=d.y,draw=function()
            load();local alpha=math.min(1,d.life*2)
            love.graphics.setColor(1,1,1,alpha)
            local scale=(d.kind=="branch" and .92 or .38)*(d.scale or 1)
            love.graphics.draw(debrisImage,debrisQuads[d.frame],d.x,d.y-d.h,d.angle,scale,scale,48,48)
        end}
    end
end

return Siege
