local Siege={}
local debrisImage,debrisQuads

local function load()
    if debrisImage then return end
    debrisImage=love.graphics.newImage("assets/fx/worldtree-siege-debris-atlas-v1.png")
    debrisImage:setFilter("nearest","nearest")
    debrisQuads={}
    for i=0,7 do debrisQuads[i+1]=love.graphics.newQuad(i*96,0,96,96,debrisImage:getDimensions()) end
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
            vx=side*95,vy=28,angle=side*.25,spin=side*2.4,life=2.4,scale=stage==3 and 1.25 or 1}
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
    local stage=Siege.damageStage(e)
    if stage>(e.worldTreeDamageStage or 0) then
        for s=(e.worldTreeDamageStage or 0)+1,stage do Siege.spawnDamageDebris(mode,e,s,game) end
    end
    e.worldTreeDamageStage=stage
end

function Siege.updateDebris(mode,dt)
    mode.worldTreeDebris=mode.worldTreeDebris or {}
    for i=#mode.worldTreeDebris,1,-1 do
        local d=mode.worldTreeDebris[i]
        d.life=d.life-dt;d.x=d.x+d.vx*dt;d.y=d.y+d.vy*dt
        d.vx=d.vx*math.exp(-1.1*dt);d.vy=d.vy*math.exp(-1.6*dt)
        d.h=d.h+d.vh*dt;d.vh=d.vh-(d.kind=="branch" and 720 or 430)*dt
        d.angle=d.angle+d.spin*dt
        if d.h<0 then d.h=0;d.vh=math.abs(d.vh)*(d.kind=="branch" and .08 or .2);d.spin=d.spin*.35 end
        if d.life<=0 then table.remove(mode.worldTreeDebris,i) end
    end
end

function Siege.queue(mode,queue)
    for _,value in ipairs(mode.worldTreeDebris or {}) do local d=value
        queue[#queue+1]={x=d.x,y=d.y+.15,anchorY=d.y,draw=function()
            load();local alpha=math.min(1,d.life*2)
            love.graphics.setColor(1,1,1,alpha)
            local scale=(d.kind=="branch" and .92 or .38)*(d.scale or 1)
            love.graphics.draw(debrisImage,debrisQuads[d.frame],d.x,d.y-d.h,d.angle,scale,scale,48,48)
        end}
    end
end

return Siege
