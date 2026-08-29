local Plants={}
local Geometry=require("src.combat_geometry")
Plants.definitions={
    thornHunter={name="가시덩굴 사냥꾼",category="plant",hp=46,speed=0,damage=8,radius=27,reward=7,plantAttack=true,range=350,attackInterval=2.4},
    hammerBloom={name="망치 식인꽃",category="plant",hp=68,speed=0,damage=15,radius=31,reward=9,plantAttack=true,range=205,attackInterval=3.0},
    seedPod={name="폭발 씨앗 꼬투리",category="plant",hp=38,speed=0,damage=5,radius=25,reward=7,plantAttack=true,range=390,attackInterval=2.8},
    bambooCannon={name="대나무 압축포",category="plant",hp=54,speed=0,damage=12,radius=28,reward=9,plantAttack=true,range=470,attackInterval=3.4},
    resinSprayer={name="송진 분사목",category="plant",hp=62,speed=0,damage=5,radius=30,reward=9,plantAttack=true,range=330,attackInterval=3.8},
}

local function aim(e,game)
    local dx,dy=game.player.x-e.x,game.player.y-e.y; local d=math.sqrt(dx*dx+dy*dy)
    if d<.001 then return 1,0,0 end
    return dx/d,dy/d,d
end
local projectileRadius={plantSeed=12,bambooBolt=18,resinBlob=14}
local function shoot(mode,e,kind,speed,life,damage,spread)
    local nx,ny=e.attackDX,e.attackDY
    if spread and spread~=0 then local c,s=math.cos(spread),math.sin(spread);nx,ny=nx*c-ny*s,nx*s+ny*c end
    mode.projectiles[#mode.projectiles+1]={x=e.x+nx*22,y=e.y-12+ny*12,vx=nx*speed,vy=ny*speed,life=life,damage=damage*(e.dmgMul or 1),kind=kind,hitRadius=projectileRadius[kind],color={.82,.62,.18}}
end
local function telegraph(mode,e,x,y,r,kind,delay,damage)
    mode.bossTelegraphs[#mode.bossTelegraphs+1]={x=x,y=y,radius=r,phase="warn",timer=delay,damage=damage*(e.dmgMul or 1),plantKind=kind}
end
function Plants.update(e,dt,mode,game)
    if not e.def.plantAttack then return false end
    e.plantState=e.plantState or "idle"; e.plantTimer=(e.plantTimer or (.6+(e.seed or 0)%1.2))-dt
    local nx,ny,dist=aim(e,game); e.facing=nx<0 and -1 or 1
    if e.plantState=="idle" then
        if e.plantTimer<=0 and dist<=e.def.range then
            e.attackDX,e.attackDY=nx,ny;e.targetX,e.targetY=game.player.x,game.player.y
            e.plantState="windup";e.plantTimer=e.kind=="hammerBloom" and .72 or .62;e.windupDuration=e.plantTimer;e.visualAttack=.24
        end
    elseif e.plantState=="windup" then
        e.visualAttack=.24
        if e.plantTimer<=0 then
            local dmg=e.def.damage
            if e.kind=="thornHunter" then
                for n=1,3 do local q=n/3;telegraph(mode,e,e.x+(e.targetX-e.x)*q,e.y+(e.targetY-e.y)*q,25,"thornRoot",.10+n*.08,dmg) end
            elseif e.kind=="hammerBloom" then telegraph(mode,e,e.targetX,e.targetY,52,"hammer",.08,dmg)
            elseif e.kind=="seedPod" then for _,a in ipairs({-.24,-.12,0,.12,.24}) do shoot(mode,e,"plantSeed",245,1.8,dmg,a) end
            elseif e.kind=="bambooCannon" then shoot(mode,e,"bambooBolt",480,1.05,dmg,0)
            else
                local p={x=e.x,y=e.y-16,vx=(e.targetX-e.x)/.7,vy=(e.targetY-e.y)/.7,life=.7,damage=dmg*(e.dmgMul or 1),kind="resinBlob",hitRadius=projectileRadius.resinBlob,color={.92,.57,.12},targetX=e.targetX,targetY=e.targetY}
                mode.projectiles[#mode.projectiles+1]=p
            end
            e.plantState="recover";e.plantTimer=.5;e.recoverDuration=.5
        end
    elseif e.plantTimer<=0 then e.plantState="idle";e.plantTimer=e.def.attackInterval end
    return true
end

function Plants.onProjectileExpired(mode,p)
    if p.kind~="resinBlob" then return false end
    mode.resinPuddles[#mode.resinPuddles+1]={x=p.targetX or p.x,y=p.targetY or p.y,life=4.5,maxLife=4.5,radius=48}
    return true
end
function Plants.updateWorld(mode,dt,game)
    for i=#mode.resinPuddles,1,-1 do
        local p=mode.resinPuddles[i];p.life=p.life-dt
        local dx,dy=game.player.x-p.x,game.player.y-p.y
        if Geometry.circleOverlapsTarget(p.x,p.y,p.radius,game.player,Geometry.PLAYER_RADIUS) then mode.rootedTimer=math.max(mode.rootedTimer,.12) end
        if p.life<=0 then table.remove(mode.resinPuddles,i) end
    end
end

local fx,quads,projectileFx,projectileQuads
local function loadFx()
    if fx then return end
    fx=love.graphics.newImage("assets/fx/nature-counterattack-atlas-v1.png");fx:setFilter("nearest","nearest");quads={}
    for i=0,11 do quads[i+1]=love.graphics.newQuad((i%6)*160,math.floor(i/6)*160,160,160,fx:getDimensions()) end
end
local function loadProjectileFx()
    if projectileFx then return true end
    -- Logic-only verification stubs intentionally omit the image API.
    if not (love and love.graphics and love.graphics.newImage) then return false end
    projectileFx=love.graphics.newImage("assets/fx/attack-plants/attack-plant-projectiles-atlas-v2.png")
    projectileFx:setFilter("nearest","nearest");projectileQuads={}
    for row=0,3 do for frame=0,5 do projectileQuads[row*6+frame+1]=love.graphics.newQuad(frame*160,row*160,160,160,projectileFx:getDimensions()) end end
    return true
end
function Plants.drawWarning(e)
    if e.plantState~="windup" then return end
    local x2,y2=e.targetX,e.targetY; love.graphics.setLineStyle("rough")
    love.graphics.setColor(.11,.08,.035,.86);love.graphics.setLineWidth(7);love.graphics.line(e.x,e.y,x2,y2)
    local c=e.kind=="resinSprayer" and {.94,.58,.14,1} or {.86,.74,.28,1}
    love.graphics.setColor(c);love.graphics.setLineWidth(2);love.graphics.line(e.x,e.y,x2,y2);love.graphics.setLineWidth(1)
end
function Plants.drawProjectile(p)
    local rows={plantSeed=0,bambooBolt=1,resinBlob=2};local row=rows[p.kind];if row==nil then return end
    if not loadProjectileFx() then return end;local frame=math.floor((love.timer.getTime()+(p.x+p.y)*.001)*12)%6
    local scale=p.kind=="plantSeed" and .23 or (p.kind=="bambooBolt" and .34 or .24)
    love.graphics.push();love.graphics.translate(math.floor(p.x+.5),math.floor(p.y+.5));love.graphics.rotate(math.atan2(p.vy,p.vx))
    love.graphics.setColor(1,1,1,1);love.graphics.draw(projectileFx,projectileQuads[row*6+frame+1],0,0,0,scale,scale,80,80);love.graphics.pop()
end
function Plants.drawWorld(mode,t)
    if not loadProjectileFx() then return end
    for _,p in ipairs(mode.resinPuddles) do
        local a=math.min(1,p.life);local frame=math.floor((t+p.x*.003)*8)%6;local scale=p.radius/72
        love.graphics.setColor(1,1,1,a);love.graphics.draw(projectileFx,projectileQuads[19+frame],math.floor(p.x+.5),math.floor(p.y+.5),0,scale,scale,80,89)
    end
    love.graphics.setColor(1,1,1,1)
end
function Plants.drawTelegraph(tel)
    if not (tel.rootQuake or tel.branchFall or tel.plantKind) then return false end
    loadFx()
    if tel.phase=="warn" then
        local col=tel.branchFall and {1,.74,.18,.8} or {.78,.38,.12,.78}
        love.graphics.setColor(col);love.graphics.setLineWidth(2);love.graphics.circle("line",tel.x,tel.y,tel.radius);love.graphics.setLineWidth(1)
    else
        local row=tel.branchFall and 1 or 0;local frame=math.min(5,math.floor((1-math.max(0,tel.timer)/.25)*6))
        love.graphics.setColor(1,1,1,1);love.graphics.draw(fx,quads[row*6+frame+1],tel.x,tel.y,0,1,1,80,145)
    end
    return true
end
return Plants
