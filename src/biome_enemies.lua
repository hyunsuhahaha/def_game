-- Regional fauna. Attack patterns are game fiction, not wildlife behaviour claims.
local Enemies={}
Enemies.definitions={
    crocodile={name="늪지 바다악어",category="animal",hp=40,speed=70,damage=12,radius=26,color={.30,.42,.20},hitCooldown=1.3,reward=7,biomeAttack=true},
    angryLemur={name="화난 알락꼬리여우원숭이",category="animal",hp=14,speed=170,damage=5,radius=15,color={.65,.66,.59},hitCooldown=.95,reward=3,biomeAttack=true},
    marshCrab={name="늪지 집게게",category="animal",hp=14,speed=90,damage=6,radius=15,color={.73,.34,.18},hitCooldown=1.1,reward=3},
    shoreCrab={name="해변 집게게",category="animal",hp=24,speed=95,damage=7,radius=17,color={.79,.40,.20},hitCooldown=1.1,reward=4},
}
local replacements={
    mangrove={squirrel="marshCrab",boar="crocodile",turret="vineSprout"},
    madagascar={squirrel="angryLemur",boar="angryLemur",turret="vineSprout"},
    island={squirrel="shoreCrab",boar="shoreCrab",turret="vineSprout"},
}
function Enemies.resolve(map,kind) return replacements[map] and replacements[map][kind] or kind end
function Enemies.spawnPoint(world,player,kind,x,y)
    if kind~="crocodile" or not world then return x,y end
    local w,h=world.width,world.height
    local function water(px,py)
        py=math.max(120,math.min(h-120,py));px=math.max(120,math.min(w-120,px))
        local vx=w*.32+math.sin(py/240)*110
        local hy=h*.65+math.sin(px/340)*125
        if math.abs(px-vx)<math.abs(py-hy) then return vx,py else return px,hy end
    end
    x,y=water(x,y)
    if player and (x-player.x)^2+(y-player.y)^2<260^2 then
        -- A crocodile must not materialise under the player after projection.
        local a,b=water(w*.32,player.y<h/2 and h-180 or 180)
        x,y=a,b
    end
    return x,y
end
local function distanceToSegment(px,py,x1,y1,x2,y2)
    local dx,dy=x2-x1,y2-y1;local d=dx*dx+dy*dy
    local t=d>0 and math.max(0,math.min(1,((px-x1)*dx+(py-y1)*dy)/d)) or 0
    return (px-x1-dx*t)^2+(py-y1-dy*t)^2
end
function Enemies.update(e,dt,mode,game)
    if not e.def.biomeAttack then return false end
    local croc=e.kind=="crocodile"
    local remaining=dt
    e.biomeState=e.biomeState or "stalk"
    e.biomeTimer=e.biomeTimer or (.8+(e.seed or 0)%1)
    -- Small substeps preserve windup and swept contact even with a long frame.
    while remaining>0 do
        local step=math.min(.025,remaining);remaining=remaining-step
        local dx,dy=game.player.x-e.x,game.player.y-e.y
        local distance=math.sqrt(dx*dx+dy*dy)
        e.biomeTimer=e.biomeTimer-step
        if e.biomeState=="stalk" then
            if distance>e.def.radius+24 then
                local move=math.min(distance-e.def.radius-24,e.def.speed*(e.speedMul or 1)*step)
                e.x,e.y=e.x+dx/distance*move,e.y+dy/distance*move
            end
            if distance<(croc and 360 or 225) and e.biomeTimer<=0 then
                e.biomeState,e.biomeTimer="warn",croc and .65 or .32
                e.warnDuration=e.biomeTimer
                e.attackDX,e.attackDY=dx/math.max(.001,distance),dy/math.max(.001,distance)
                e.attackLength=croc and 220 or 145;e.attackHit=false
                e.visualAttack=.24
            end
        elseif e.biomeState=="warn" then
            e.visualAttack=.24
            if e.biomeTimer<=0 then e.biomeState="lunge";e.biomeTimer=croc and .42 or .26;e.lungeDuration=e.biomeTimer end
        elseif e.biomeState=="lunge" then
            local x,y=e.x,e.y
            local speed=e.attackLength/e.lungeDuration
            e.x,e.y=e.x+e.attackDX*speed*step,e.y+e.attackDY*speed*step
            e.x,e.y=require("src.clearcut_maps").constrain(game.world,e.x,e.y,e.def.radius+8)
            if not e.attackHit and distanceToSegment(game.player.x,game.player.y,x,y,e.x,e.y)<(e.def.radius+16)^2 then
                mode:damagePlayer(e.def.damage*(e.dmgMul or 1),game);e.attackHit=true
            end
            e.hopHeight=croc and 0 or math.sin(math.max(0,e.biomeTimer)/e.lungeDuration*math.pi)*20
            if e.biomeTimer<=0 then e.biomeState="recover";e.biomeTimer=croc and .9 or .45;e.hopHeight=0 end
        elseif e.biomeTimer<=0 then
            e.biomeState="stalk";e.biomeTimer=croc and 1.5 or .9
        end
    end
    return true
end
function Enemies.drawWarning(e)
    if e.biomeState~="warn" then return end
    local dx,dy=e.attackDX,e.attackDY
    local x,y=math.floor(e.x),math.floor(e.y)
    local tx,ty=math.floor(x+dx*e.attackLength),math.floor(y+dy*e.attackLength)
    love.graphics.setLineStyle("rough")
    love.graphics.setColor(.16,.07,.035,.9);love.graphics.setLineWidth(7);love.graphics.line(x,y,tx,ty)
    love.graphics.setColor(1,.64,.22,1);love.graphics.setLineWidth(3);love.graphics.line(x,y,tx,ty)
    love.graphics.line(tx-dx*14-dy*8,ty-dy*14+dx*8,tx,ty,tx-dx*14+dy*8,ty-dy*14-dx*8)
    love.graphics.setLineWidth(1)
end
return Enemies
