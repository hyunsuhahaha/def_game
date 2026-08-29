local Bosses={}

Bosses.definitions={
    stumpWarden={name="잘린 숲의 감시목",category="plant",hp=680,speed=46,damage=13,radius=58,color={.58,.43,.20},hitCooldown=1,boss=true,finalBoss=true,biomeBoss=true,reward=0},
    hollowOak={name="속빈 고목왕",category="plant",hp=1250,speed=38,damage=18,radius=82,color={.52,.43,.22},hitCooldown=1,boss=true,finalBoss=true,biomeBoss=true,reward=0},
    rootjaw={name="뿌리턱 악어왕",category="animal",hp=1380,speed=54,damage=20,radius=88,color={.25,.52,.42},hitCooldown=1,boss=true,finalBoss=true,biomeBoss=true,reward=0},
    baobabTyrant={name="바오밥 폭군",category="plant",hp=1160,speed=72,damage=19,radius=70,color={.78,.48,.24},hitCooldown=.9,boss=true,finalBoss=true,biomeBoss=true,reward=0},
    islandHermit={name="섬등 소라게",category="animal",hp=1460,speed=48,damage=20,radius=80,color={.72,.38,.62},hitCooldown=1,boss=true,finalBoss=true,biomeBoss=true,reward=0},
}

Bosses.byMap={beginner="stumpWarden",forest="hollowOak",mangrove="rootjaw",madagascar="baobabTyrant",island="islandHermit"}
Bosses.names={beginner="초심자 벌목 계약",forest="온대림 전면 철거",mangrove="수로 봉쇄 작전",madagascar="바오밥 회랑 진입",island="무인도 전소 작전"}
function Bosses.forMap(id)return Bosses.byMap[id] or Bosses.byMap.forest end
function Bosses.operationName(id)return Bosses.names[id] or Bosses.names.forest end
function Bosses.stageCap(id)return id=="beginner" and 3 or 4 end

local function line(mode,x1,y1,x2,y2,width,delay,damage,tag)
    mode.bossTelegraphs[#mode.bossTelegraphs+1]={kind="line",x1=x1,y1=y1,x2=x2,y2=y2,halfWidth=width,phase="warn",timer=delay,warnDuration=delay,damage=damage,bossTag=tag}
end
local function circle(mode,x,y,r,delay,damage,tag)
    mode.bossTelegraphs[#mode.bossTelegraphs+1]={x=x,y=y,radius=r,phase="warn",timer=delay,warnDuration=delay,damage=damage,bossTag=tag,plantKind="hammer"}
end
local function target(e,game)
    local dx,dy=game.player.x-e.x,game.player.y-e.y;local d=math.sqrt(dx*dx+dy*dy)
    if d<.01 then return 1,0,0 end return dx/d,dy/d,d
end
local function beginRecover(e,time)
    e.bossState="recover";e.bossTimer=time;e.bossActionFrame=1
end
local function beginAttack(e,kind,warn,game)
    local nx,ny,dist=target(e,game);e.bossState="warn";e.bossTimer=warn;e.bossWarnDuration=warn;e.bossAttack=kind;e.lockDX,e.lockDY=nx,ny;e.lockDistance=dist;e.lockX,e.lockY=game.player.x,game.player.y;e.visualAttack=.24
end

local function choose(e,mode,game)
    e.bossSequence=(e.bossSequence or 0)+1;local n=e.bossSequence
    if e.kind=="stumpWarden" then beginAttack(e,n%2==0 and "stumpLines" or "stumpSlam",.85,game)
    elseif e.kind=="hollowOak" then beginAttack(e,n%2==0 and "oakLanes" or "oakFists",1.0,game)
    elseif e.kind=="rootjaw" then beginAttack(e,n%3==0 and "tail" or "charge",1.0,game)
    elseif e.kind=="baobabTyrant" then beginAttack(e,n%3==0 and "seeds" or "leap",.78,game)
    else beginAttack(e,n%2==0 and "wave" or "shellCharge",1.05,game) end
end

local function fire(e,mode,game)
    local dmg=e.def.damage*(e.dmgMul or 1);local kind=e.bossAttack
    if kind=="stumpSlam" then
        for i=1,3 do local a=i/3*math.pi*2+e.bossSequence;circle(mode,game.player.x+math.cos(a)*80,game.player.y+math.sin(a)*55,48,.12+i*.08,dmg,"stump") end;beginRecover(e,1.15)
    elseif kind=="stumpLines" then
        local nx,ny=e.lockDX,e.lockDY;local px,py=-ny,nx
        line(mode,e.x+px*70,e.y+py*70,e.x+px*70+nx*390,e.y+py*70+ny*390,34,.18,dmg,"stump")
        line(mode,e.x-px*70,e.y-py*70,e.x-px*70+nx*390,e.y-py*70+ny*390,34,.18,dmg,"stump");beginRecover(e,1.1)
    elseif kind=="oakFists" then
        local nx,ny=e.lockDX,e.lockDY;local px,py=-ny,nx;circle(mode,e.lockX+px*75,e.lockY+py*75,68,.18,dmg,"oak");circle(mode,e.lockX-px*75,e.lockY-py*75,68,.18,dmg,"oak");beginRecover(e,1.55)
    elseif kind=="oakLanes" then
        local nx,ny=e.lockDX,e.lockDY;local px,py=-ny,nx
        for _,side in ipairs({-1,1}) do line(mode,e.x+px*side*105,e.y+py*side*105,e.x+nx*470+px*side*105,e.y+ny*470+py*side*105,42,.2,dmg,"oak") end
        beginRecover(e,1.35)
    elseif kind=="charge" or kind=="shellCharge" then
        e.bossState="attack";e.bossTimer=kind=="charge" and .62 or .74;e.bossAttackDuration=e.bossTimer;e.bossActionFrame=0;e.chargeHit=false
    elseif kind=="tail" then circle(mode,e.x,e.y,210,.18,dmg*.85,"mangrove");beginRecover(e,1.4)
    elseif kind=="leap" then
        e.bossState="attack";e.bossTimer=.62;e.bossAttackDuration=.62;e.bossStartX,e.bossStartY=e.x,e.y;e.bossActionFrame=0;e.leapHit=false
        circle(mode,e.lockX,e.lockY,82,.60,dmg,"madagascar")
    elseif kind=="seeds" then
        local base=math.atan2(e.lockDY,e.lockDX)
        for _,a in ipairs({-.34,-.17,0,.17,.34}) do local q=base+a;mode.projectiles[#mode.projectiles+1]={x=e.x,y=e.y-20,vx=math.cos(q)*225,vy=math.sin(q)*225,life=2.2,damage=dmg*.45,kind="plantSeed",color={.75,.45,.16}} end
        beginRecover(e,1.25)
    elseif kind=="wave" then
        local px,py=-e.lockDY,e.lockDX;local gap=105
        for _,side in ipairs({-1,1}) do line(mode,e.x+px*side*gap-e.lockDX*330,e.y+py*side*gap-e.lockDY*330,e.x+px*side*gap+e.lockDX*420,e.y+py*side*gap+e.lockDY*420,54,.28,dmg*.7,"island") end
        beginRecover(e,1.45)
    end
end

function Bosses.update(e,dt,mode,game)
    if not e.def.biomeBoss then return false end
    e.enraged=e.hp<=e.maxHp*.5
    e.bossState=e.bossState or "idle";e.bossTimer=(e.bossTimer or 1.8)-dt;e.bossActionFrame=math.min(1,(e.bossActionFrame or 0)+dt*2.4)
    if e.bossState=="idle" then
        local nx,ny,dist=target(e,game);if dist>190 then local s=e.def.speed*(e.speedMul or 1);e.x,e.y=e.x+nx*s*dt,e.y+ny*s*dt;e.moving=true end
        if e.bossTimer<=0 then choose(e,mode,game) end
    elseif e.bossState=="warn" then if e.bossTimer<=0 then fire(e,mode,game) end
    elseif e.bossState=="attack" then
        local duration=e.bossAttackDuration or 1;local p=1-math.max(0,e.bossTimer)/duration;e.bossActionFrame=p
        if e.bossAttack=="leap" then e.x=e.bossStartX+(e.lockX-e.bossStartX)*p;e.y=e.bossStartY+(e.lockY-e.bossStartY)*p;e.hopHeight=math.sin(p*math.pi)*95
        else
            local speed=e.bossAttack=="charge" and 650 or 560;local ox,oy=e.x,e.y;e.x,e.y=e.x+e.lockDX*speed*dt,e.y+e.lockDY*speed*dt
            local rx,ry=game.player.x-ox,game.player.y-oy;local sx,sy=e.x-ox,e.y-oy;local l=sx*sx+sy*sy;local q=l>0 and math.max(0,math.min(1,(rx*sx+ry*sy)/l)) or 0;local dx,dy=game.player.x-(ox+sx*q),game.player.y-(oy+sy*q)
            if not e.chargeHit and dx*dx+dy*dy<=(e.def.radius+24)^2 then e.chargeHit=true;mode:damagePlayer(e.def.damage*(e.dmgMul or 1),game) end
        end
        if e.bossTimer<=0 then e.hopHeight=0;beginRecover(e,e.enraged and .75 or 1.15) end
    else
        if e.bossTimer<=0 then e.bossState="idle";e.bossTimer=e.enraged and 1.35 or 2.1;e.bossActionFrame=0 end
    end
    return true
end

return Bosses
