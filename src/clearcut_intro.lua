local Maps=require("src.clearcut_maps")
local Life=require("src.biome_life")
local Intro={}
local birdAtlas,birdQuads,debrisAtlas,debrisQuads
local CELL_W,CELL_H,FRAMES=160,112,8
local DEBRIS_CELL,DEBRIS_FRAMES=32,8
local DURATION,ENTRY_AT,STARTLE_AT,ARRIVE_AT=5.0,1.05,1.42,3.42
local speciesRow={forest=1,beginner=1,mangrove=2,madagascar=3,island=4}
local clusters={
    {x=-270,y=-142,dx=-1.00,dy=-.62,count=4,depths={.58,.94,1.46,.78}},
    {x=252,y=-166,dx=.96,dy=-.67,count=4,depths={.66,1.04,1.58,.84}},
    {x=-302,y=56,dx=-.92,dy=-.43,count=3,depths={.60,1.22,.89}},
    {x=286,y=38,dx=.88,dy=-.48,count=3,depths={.68,1.40,.98}},
}
local function clamp(v,a,b)return math.max(a,math.min(b,v))end
local function smooth(q)q=clamp(q,0,1);return q*q*(3-2*q)end
local function load()
    if birdAtlas then return end
    birdAtlas=love.graphics.newImage("assets/fx/stage-intro/stage-intro-birds-atlas-pixel-v2.png");birdAtlas:setFilter("nearest","nearest")
    debrisAtlas=love.graphics.newImage("assets/fx/stage-intro/stage-intro-debris-atlas-pixel-v2.png");debrisAtlas:setFilter("nearest","nearest")
    birdQuads={};for row=1,4 do birdQuads[row]={};for frame=1,FRAMES do birdQuads[row][frame]=love.graphics.newQuad((frame-1)*CELL_W,(row-1)*CELL_H,CELL_W,CELL_H,birdAtlas:getDimensions())end end
    debrisQuads={};for frame=1,DEBRIS_FRAMES do debrisQuads[frame]=love.graphics.newQuad((frame-1)*DEBRIS_CELL,0,DEBRIS_CELL,DEBRIS_CELL,debrisAtlas:getDimensions())end
end
local function makeBirds(tx,ty)
    local birds={};local index=0
    for ci,c in ipairs(clusters)do for j=1,c.count do
        index=index+1;local spread=j-(c.count+1)/2;local fan=spread*.19
        local hx=tx+c.x+spread*24+(ci%2==0 and j*4 or -j*3);local hy=ty+c.y+math.abs(spread)*13-(j%2)*9
        birds[index]={x=hx,y=hy,homeX=hx,homeY=hy,phase=index*.91,cluster=ci,depth=c.depths[j],
            delay=STARTLE_AT+(ci-1)*.12+(j-1)*.052,flying=false,
            dirX=c.dx-c.dy*fan,dirY=c.dy+c.dx*fan,vx=0,vy=0,curve=((index%2)*2-1)*(22+ci*4)}
    end end
    return birds
end
local function spawnBurst(intro,c,ci)
    if intro.launched[ci]then return end;intro.launched[ci]=true
    for i=1,16 do
        local a=i/16*math.pi*2+ci*.61;local leaf=i%3~=0;local life=1.55+(i%5)*.16
        intro.debris[#intro.debris+1]={x=intro.targetX+c.x+(i%3-1)*9,y=intro.targetY+c.y+(i%4-2)*6,
            vx=math.cos(a)*(34+(i%5)*10)+c.dx*54,vy=math.sin(a)*(18+(i%4)*8)-28,rot=a,
            spin=((i%2)*2-1)*(2.2+(i%4)*.7),life=life,maxLife=life,frame=leaf and ((i+ci)%6+1)or(7+i%2),
            scale=leaf and(.68+(i%3)*.14)or(.76+(i%2)*.14),depth=(i%4==0)and .74 or 1.08}
    end
end
local function kickTrees(game,intro,c,ci)
    local cx,cy=intro.targetX+c.x,intro.targetY+c.y;local nearest,nearestD
    for _,node in ipairs(game.world.nodes or{})do if node.active~=false then
        local dx,dy=node.x-cx,node.y-cy;local d=dx*dx+dy*dy
        if not nearestD or d<nearestD then nearest,nearestD=node,d end
        if d<225*225 then node.swayVel=(node.swayVel or 0)+(dx>=0 and 1 or -1)*(2.3+ci*.25);intro.swayNodes[node]=true end
    end end
    if nearest and not intro.swayNodes[nearest]then nearest.swayVel=(ci%2==0 and -1 or 1)*2.4;intro.swayNodes[nearest]=true end
end
function Intro.active(game)return game.clearcut and game.clearcut.intro~=nil end
function Intro.begin(game)
    local mode=game.clearcut;if not mode or mode.sandbox then return end
    local tx,ty=game.player.x,game.player.y;local id=mode.mapId or"forest"
    mode.intro={t=0,duration=DURATION,mapId=id,targetX=tx,targetY=ty,entryX=tx-238,entryY=ty+70,
        baseZoom=game.world.stageZoom or game.camera.zoom or .84,birds=makeBirds(tx,ty),debris={},launched={},swayNodes={},startled=false,kick=0,stepClock=0}
    game.player.introHidden=true;game.player.isMoving=false;game.player.x,game.player.y=tx-238,ty+70
    game.camera.x,game.camera.y,game.camera.zoom=tx,ty-22,(game.world.stageZoom or .84)*1.16;game.noticeTime=0
end
local function clearSway(intro)for node in pairs(intro.swayNodes or{})do node.swayAngle=0;node.swayVel=0 end end
local function finish(game)
    local intro=game.clearcut and game.clearcut.intro;if not intro then return end;clearSway(intro)
    game.player.introHidden=false;game.player.isMoving=false;game.player.x,game.player.y=intro.targetX,intro.targetY
    game.camera.x,game.camera.y,game.camera.zoom=intro.targetX,intro.targetY,intro.baseZoom;game.clearcut.intro=nil
    local def=Maps.get(game.clearcut.mapId);game:setNotice(def.name.." · 1구역 작전 개시","food")
end
Intro.finish=finish
function Intro.skip(game)
    local intro=game.clearcut and game.clearcut.intro;if not intro then return false end
    if not intro.startled then Life.startle(game.world,intro.targetX,intro.targetY,520);intro.startled=true end
    finish(game);return true
end
local function spawnFootstep(intro,x,y)
    local n=#intro.debris+1;intro.debris[#intro.debris+1]={x=x-8+(n%3)*7,y=y+20,vx=-18+(n%4)*11,vy=-18-(n%3)*5,
        rot=n*.77,spin=((n%2)*2-1)*2.8,life=.58,maxLife=.58,frame=(n%6)+1,scale=.34,depth=1.03}
end
function Intro.update(game,dt)
    local intro=game.clearcut and game.clearcut.intro;if not intro then return false end
    intro.t=math.min(intro.duration,intro.t+dt);Life.update(game.world,dt)
    if not intro.startled and intro.t>=STARTLE_AT then intro.startled=true;intro.kick=1;Life.startle(game.world,intro.targetX,intro.targetY,620)end
    if intro.t<ENTRY_AT then game.player.introHidden=true;game.player.isMoving=false else
        game.player.introHidden=false;local q=smooth((intro.t-ENTRY_AT)/(ARRIVE_AT-ENTRY_AT))
        game.player.x=intro.entryX+(intro.targetX-intro.entryX)*q;game.player.y=intro.entryY+(intro.targetY-intro.entryY)*q
        game.player.facing=1;game.player.isMoving=q<.995
        if game.player.isMoving then game.player.walkClock=game.player.walkClock+dt*8;intro.stepClock=intro.stepClock+dt
            if intro.stepClock>=.24 then intro.stepClock=intro.stepClock-.24;spawnFootstep(intro,game.player.x,game.player.y)end end
    end
    for ci,c in ipairs(clusters)do local launch=STARTLE_AT+(ci-1)*.12;if intro.t>=launch and not intro.launched[ci]then spawnBurst(intro,c,ci);kickTrees(game,intro,c,ci)end end
    for i,b in ipairs(intro.birds)do
        if not b.flying and intro.t>=b.delay then b.flying=true;b.vx=b.dirX*(112+b.depth*28+i*1.5);b.vy=b.dirY*(104+b.depth*20)-16 end
        if b.flying then local age=intro.t-b.delay;b.vx=b.vx+b.dirX*(38+13*b.depth)*dt;b.vy=b.vy-22*dt+math.sin(age*3.1+b.phase)*b.curve*dt
            b.x=b.x+b.vx*dt;b.y=b.y+b.vy*dt+math.sin(age*2.4+b.phase)*7*dt
        else b.x=b.homeX+math.sin(intro.t*.7+b.phase)*2;b.y=b.homeY+math.sin(intro.t*1.1+b.phase)*1.5 end
    end
    for i=#intro.debris,1,-1 do local p=intro.debris[i];p.life=p.life-dt;if p.life<=0 then table.remove(intro.debris,i)else
        p.vy=p.vy+31*dt;p.vx=p.vx*.995;p.x=p.x+p.vx*dt;p.y=p.y+p.vy*dt;p.rot=p.rot+p.spin*dt end end
    for node in pairs(intro.swayNodes)do local vel=(node.swayVel or 0)+(-(node.swayAngle or 0)*42-(node.swayVel or 0)*6.8)*dt
        node.swayVel=vel;node.swayAngle=clamp((node.swayAngle or 0)+vel*dt,-.28,.28)end
    intro.kick=math.max(0,intro.kick-dt*3.8);local zoomQ=smooth(intro.t/intro.duration);local impact=math.sin(intro.kick*math.pi*3)*intro.kick
    game.camera.x=intro.targetX+(1-zoomQ)*24+impact*7;game.camera.y=intro.targetY-22*(1-zoomQ)-impact*4
    game.camera.zoom=intro.baseZoom*(1.16-.16*zoomQ+intro.kick*.025)
    if intro.t>=intro.duration then finish(game)end;return true
end
local function drawDebris(intro,back)
    load();for _,p in ipairs(intro.debris)do if(p.depth<.9)==back then local alpha=clamp(p.life/.25,0,1);love.graphics.setColor(1,1,1,alpha)
        love.graphics.draw(debrisAtlas,debrisQuads[p.frame],math.floor(p.x),math.floor(p.y),p.rot,p.scale*p.depth,p.scale*p.depth,DEBRIS_CELL/2,DEBRIS_CELL/2)end end
end
local function drawBirds(intro,back)
    load();local row=speciesRow[intro.mapId]or 1
    for i,b in ipairs(intro.birds)do if b.flying and((b.depth<.9)==back)then local age=math.max(0,intro.t-b.delay)
        local frame=(math.floor(age*(10.5+2*b.depth)+b.phase*2)%FRAMES)+1;local facing=b.vx>=0 and 1 or -1;local scale=(58*b.depth)/CELL_W
        local alpha=clamp((1.68-age)/.28,0,1)*clamp((3.28-intro.t)/.24,0,1)*clamp((DURATION-intro.t)/.35,0,1)
        local flightTilt=clamp(b.vy/math.max(math.abs(b.vx),1)*.11,-.14,.14)+math.sin(age*5+b.phase)*.025
        love.graphics.setColor(.005,.014,.012,.07*alpha);love.graphics.ellipse("fill",b.x,b.y+25*b.depth,24*b.depth,3*b.depth)
        love.graphics.setColor(1,1,1,alpha);love.graphics.draw(birdAtlas,birdQuads[row][frame],math.floor(b.x),math.floor(b.y),flightTilt,scale*facing,scale,CELL_W/2,CELL_H/2)
    end end
end
function Intro.drawWorldBack(game)local intro=game.clearcut and game.clearcut.intro;if intro then drawBirds(intro,true);drawDebris(intro,true)end end
function Intro.drawWorldFront(game)local intro=game.clearcut and game.clearcut.intro;if intro then drawBirds(intro,false);drawDebris(intro,false)end end
function Intro.drawWorld(game)Intro.drawWorldBack(game);Intro.drawWorldFront(game)end
function Intro.drawScreen(game)
    local intro=game.clearcut and game.clearcut.intro;if not intro then return end
    local w,h=love.graphics.getDimensions();local f=game.fonts;local def=Maps.get(intro.mapId);local t=intro.t
    local fade=clamp(1-t/.72,0,1);if fade>0 then love.graphics.setColor(0,0,0,fade);love.graphics.rectangle("fill",0,0,w,h)end
    local bars=clamp(1-math.max(0,t-3.7)/1.1,0,1);local bh=math.floor(h*.065*bars)
    if bh>0 then love.graphics.setColor(.005,.012,.01,.94);love.graphics.rectangle("fill",0,0,w,bh);love.graphics.rectangle("fill",0,h-bh,w,bh)end
    local titleAlpha=clamp(t/.35,0,1)*clamp((1.68-t)/.38,0,1)
    if titleAlpha>0 then love.graphics.setFont(f.micro);love.graphics.setColor(def.color[1],def.color[2],def.color[3],titleAlpha);love.graphics.printf("작전 구역 01",0,h*.19,w,"center");love.graphics.setFont(f.display);love.graphics.setColor(.97,.95,.84,titleAlpha);love.graphics.printf(def.name,0,h*.19+28,w,"center")end
    local goAlpha=clamp((t-3.45)/.22,0,1)*clamp((4.65-t)/.35,0,1)
    if goAlpha>0 then love.graphics.setColor(.006,.016,.012,goAlpha*.68);love.graphics.rectangle("fill",w/2-108,h*.67-8,216,48);love.graphics.setFont(f.big);love.graphics.setColor(1,.76,.28,goAlpha);love.graphics.printf("작전 개시",0,h*.67,w,"center")end
    if t>.75 and t<3.9 then love.graphics.setFont(f.micro);love.graphics.setColor(.72,.78,.71,.58);love.graphics.printf("SPACE / 클릭  건너뛰기",0,h-bh-27,w,"center")end
end
return Intro
