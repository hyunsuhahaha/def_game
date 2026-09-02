local BombMonkey={}
local Maps=require("src.clearcut_maps")
BombMonkey.FUSE_FRAMES=24

local bombImage,monkeyImage,explosionImage,bombQuads,monkeyQuads,explosionQuads

local function load()
    if bombImage then return true end
    local okBomb,bomb=pcall(love.graphics.newImage,"assets/automation/monkey-bomb-atlas-pixel-v1.png")
    local okMonkey,monkey=pcall(love.graphics.newImage,"assets/characters/companions/graduate-monkey-atlas-pixel-v3.png")
    local okExplosion,explosion=pcall(love.graphics.newImage,"assets/fx/monkey-bomb-explosion-atlas-pixel-v1.png")
    if not okBomb or not okMonkey or not okExplosion then return false end
    bomb:setFilter("nearest","nearest");monkey:setFilter("nearest","nearest");explosion:setFilter("nearest","nearest")
    bombImage,monkeyImage,explosionImage=bomb,monkey,explosion;bombQuads={};monkeyQuads={};explosionQuads={}
    for i=0,BombMonkey.FUSE_FRAMES do bombQuads[i+1]=love.graphics.newQuad(i*128,0,128,128,bomb:getDimensions())end
    for i=0,5 do monkeyQuads[i+1]=love.graphics.newQuad(i*128,0,128,128,monkey:getDimensions())end
    for i=0,7 do explosionQuads[i+1]=love.graphics.newQuad(i*256,0,256,256,explosion:getDimensions())end
    return true
end

local function activeBombs(mode,owner)
    local count=0
    for _,bomb in ipairs(mode.monkeyBombs or{})do if bomb.owner==owner then count=count+1 end end
    return count
end

local function spawnMonkey(mode,game,index,wanted)
    local angle=(index-1)*math.pi*2/math.max(1,wanted)
    local x,y=Maps.constrain(game.world,game.player.x+math.cos(angle)*220,game.player.y+math.sin(angle)*170,70)
    mode.bombMonkeySequence=(mode.bombMonkeySequence or 0)+1
    mode.bombMonkeys[#mode.bombMonkeys+1]={id=mode.bombMonkeySequence,x=x,y=y,targetX=x,targetY=y,
        facing=1,life=index*.19,dropTimer=2.5+index*1.1,carrying=true,index=index}
end

local function chooseTarget(mode,value,game,wanted)
    local phase=(value.life or 0)*.18+(value.index-1)*math.pi*2/math.max(1,wanted)
    local distance=190+((value.id*53)%90)
    value.targetX,value.targetY=Maps.constrain(game.world,game.player.x+math.cos(phase)*distance,
        game.player.y+math.sin(phase)*distance*.72,75)
end

local function move(mode,value,dt,game,wanted)
    local dx,dy=(value.targetX or value.x)-value.x,(value.targetY or value.y)-value.y
    if dx*dx+dy*dy<28^2 then chooseTarget(mode,value,game,wanted);dx,dy=value.targetX-value.x,value.targetY-value.y end
    local distance=math.sqrt(dx*dx+dy*dy)
    if distance<1 then value.moving=false;return end
    local step=math.min(distance,78*dt);value.facing=dx<0 and-1 or 1;value.moving=true
    value.x,value.y=Maps.constrain(game.world,value.x+dx/distance*step,value.y+dy/distance*step,70)
end

local function drop(mode,value)
    mode.monkeyBombSequence=(mode.monkeyBombSequence or 0)+1
    mode.monkeyBombs[#mode.monkeyBombs+1]={id=mode.monkeyBombSequence,owner=value.id,
        x=value.x+value.facing*24,y=value.y+4,state="unlit",fuse=0,life=0}
    value.carrying=false;value.rearm=.8
    value.dropTimer=math.max(4,10-(mode.permanentTraits.scoreBombInterval or 0))
end

local function fireNearby(mode,bomb,world)
    if mode.rainSuppressFire then return false end
    local stream=mode.flameStream
    if stream and mode.flameStreamCovers
        and mode.flameStreamCovers(stream.x,stream.y,stream.nx,stream.ny,stream.reach,stream.halfWidth,bomb.x,bomb.y)then return true end
    for _,butt in ipairs(mode.cigaretteButts or{})do
        if butt.phase=="smolder"and(butt.x-bomb.x)^2+(butt.y-bomb.y)^2<=72^2 then return true end
    end
    for _,node in ipairs(world.nodes or{})do
        if node.active and node.burning and(node.x-bomb.x)^2+(node.y-bomb.y)^2<=125^2 then return true end
    end
    for _,spot in ipairs(mode.oilTrail or{})do
        if spot.ignited and(spot.x-bomb.x)^2+(spot.y-bomb.y)^2<=96^2 then return true end
    end
    return false
end

local function explode(mode,bomb,game)
    local radius=180+(mode.permanentTraits.scoreBombRadius or 0)
    local damage=14+(mode.permanentTraits.scoreBombDamage or 0)
    local felled=0
    for _,node in ipairs(game.world.nodes or{})do
        if node.rushTree and node.active and(node.x-bomb.x)^2+(node.y-bomb.y)^2<=(radius+24)^2 then
            if mode:damageTreeWithSmokerWeapon(node,damage,game)then felled=felled+1 end
        end
    end
    for _,enemy in ipairs(mode.enemies or{})do
        if enemy.hp>0 and(enemy.x-bomb.x)^2+(enemy.y-bomb.y)^2<=radius^2 then
            enemy.hp=enemy.hp-(24+damage*1.5);enemy.visualHit=.18
        end
    end
    mode.maxChain=math.max(mode.maxChain or 0,felled)
    mode.bombExplosions=mode.bombExplosions or{}
    mode.bombExplosions[#mode.bombExplosions+1]={x=bomb.x,y=bomb.y,age=0,life=.78,radius=radius}
    if game.feedback then game.feedback:play("popper",true)end
    if game.camera then game.camera.trauma=math.min(1,(game.camera.trauma or 0)+.28)end
end

function BombMonkey.igniteInRadius(mode,x,y,radius)
    if mode.rainSuppressFire then return 0 end
    local count=0
    for _,bomb in ipairs(mode.monkeyBombs or{})do
        if bomb.state=="unlit"and(bomb.x-x)^2+(bomb.y-y)^2<=radius^2 then bomb.state,bomb.fuse="lit",0;count=count+1 end
    end
    return count
end

function BombMonkey.update(mode,dt,game)
    if not mode.scoreAttack or(mode.permanentTraits.scoreBombMonkey or 0)<=0 then return false end
    mode.bombMonkeys=mode.bombMonkeys or{};mode.monkeyBombs=mode.monkeyBombs or{};mode.bombExplosions=mode.bombExplosions or{}
    local wanted=1+math.floor(mode.permanentTraits.scoreBombExtra or 0)
    while #mode.bombMonkeys<wanted do spawnMonkey(mode,game,#mode.bombMonkeys+1,wanted)end
    for _,value in ipairs(mode.bombMonkeys)do
        value.life=value.life+dt;move(mode,value,dt,game,wanted)
        value.dropTimer=(value.dropTimer or 0)-dt
        if not value.carrying then value.rearm=(value.rearm or 0)-dt;if value.rearm<=0 then value.carrying=true end end
        if value.carrying and value.dropTimer<=0 and activeBombs(mode,value.id)<2 then drop(mode,value)end
    end
    for index=#mode.monkeyBombs,1,-1 do local bomb=mode.monkeyBombs[index]
        bomb.life=bomb.life+dt
        if mode.rainSuppressFire and bomb.state=="lit"then bomb.state,bomb.fuse="unlit",0 end
        if bomb.state=="unlit"and fireNearby(mode,bomb,game.world)then bomb.state,bomb.fuse="lit",0 end
        if bomb.state=="lit"then
            bomb.fuse=bomb.fuse+dt
            local fuseTime=math.max(1,2.6-(mode.permanentTraits.scoreBombFuse or 0))
            if bomb.fuse>=fuseTime then explode(mode,bomb,game);table.remove(mode.monkeyBombs,index)end
        end
    end
    for index=#mode.bombExplosions,1,-1 do local value=mode.bombExplosions[index]
        value.age=value.age+dt;if value.age>=value.life then table.remove(mode.bombExplosions,index)end
    end
    return true
end

function BombMonkey.queue(mode,queue)
    if not load()then return end
    for _,entry in ipairs(mode.bombMonkeys or{})do local value=entry;queue[#queue+1]={x=value.x,y=value.y,anchorY=value.y,sortBias=.003,draw=function()
        local frame=value.moving and math.floor(value.life*8)%6+1 or 1
        local bob=value.moving and math.abs(math.sin(value.life*8))*2 or 0
        love.graphics.setColor(0,0,0,.28);love.graphics.ellipse("fill",value.x,value.y+4,25,7)
        love.graphics.setColor(1,1,1,1);love.graphics.draw(monkeyImage,monkeyQuads[frame],value.x,value.y-bob,0,.46*value.facing,.46,64,118)
        if value.carrying then
            love.graphics.draw(bombImage,bombQuads[1],value.x+value.facing*18,value.y-33-bob,0,.30*value.facing,.30,64,64)
        end
    end}end
    for _,entry in ipairs(mode.monkeyBombs or{})do local bomb=entry;queue[#queue+1]={x=bomb.x,y=bomb.y,anchorY=bomb.y,sortBias=.001,draw=function()
        local frame=1
        if bomb.state=="lit"then
            local fuseTime=math.max(1,2.6-(mode.permanentTraits.scoreBombFuse or 0))
            local progress=math.min(.999,bomb.fuse/fuseTime)
            frame=2+math.floor(progress*BombMonkey.FUSE_FRAMES)
        end
        local pulse=frame>1+math.floor(BombMonkey.FUSE_FRAMES*.72)and(1+math.sin(bomb.life*18)*.06)or 1
        love.graphics.setColor(0,0,0,.3);love.graphics.ellipse("fill",bomb.x,bomb.y+7,30,8)
        love.graphics.setColor(1,1,1,1);love.graphics.draw(bombImage,bombQuads[frame],bomb.x,bomb.y,0,.48*pulse,.48*pulse,64,58)
    end}end
    for _,entry in ipairs(mode.bombExplosions or{})do local value=entry;queue[#queue+1]={x=value.x,y=value.y,anchorY=value.y,sortBias=.08,draw=function()
        local progress=math.min(.999,value.age/value.life)
        local frame=math.min(8,math.floor(progress*8)+1)
        local scale=(value.radius or 180)/118
        love.graphics.setColor(1,1,1,1);love.graphics.draw(explosionImage,explosionQuads[frame],value.x,value.y-18,0,scale,scale,128,128)
    end}end
end

function BombMonkey.load()return load()end
return BombMonkey
