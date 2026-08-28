local Maps=require("src.clearcut_maps")
local Life=require("src.biome_life")
local Intro={}
local atlas,quads
local CELL_W,CELL_H,FRAMES=96,64,6
local DURATION,ENTRY_AT,STARTLE_AT,ARRIVE_AT=5.0,1.05,1.42,3.42
local speciesRow={forest=1,beginner=1,mangrove=2,madagascar=3,island=4}
local birdOffsets={{-250,-118},{-178,-168},{-96,-116},{38,-176},{136,-120},{232,-154},{-284,-54},{282,-72},{-24,-218},{196,-230}}

local function clamp(v,a,b)return math.max(a,math.min(b,v))end
local function smooth(q)q=clamp(q,0,1);return q*q*(3-2*q)end

local function load()
    if atlas then return end
    atlas=love.graphics.newImage("assets/fx/stage-intro/stage-intro-birds-atlas-pixel-v1.png");atlas:setFilter("nearest","nearest")
    quads={};for row=1,4 do quads[row]={};for frame=1,FRAMES do quads[row][frame]=love.graphics.newQuad((frame-1)*CELL_W,(row-1)*CELL_H,CELL_W,CELL_H,atlas:getDimensions())end end
end

function Intro.active(game)return game.clearcut and game.clearcut.intro~=nil end

function Intro.begin(game)
    local mode=game.clearcut;if not mode or mode.sandbox then return end
    local tx,ty=game.player.x,game.player.y;local id=mode.mapId or "forest";local birds={}
    for i,p in ipairs(birdOffsets)do
        birds[i]={x=tx+p[1],y=ty+p[2],homeX=tx+p[1],homeY=ty+p[2],phase=i*.83,
            scale=.76+(i%4)*.07,delay=STARTLE_AT+(i-1)*.045,flying=false,vx=0,vy=0}
    end
    mode.intro={t=0,duration=DURATION,mapId=id,targetX=tx,targetY=ty,entryX=tx-238,entryY=ty+70,
        baseZoom=game.world.stageZoom or game.camera.zoom or .84,birds=birds,startled=false}
    game.player.introHidden=true;game.player.isMoving=false;game.player.x,game.player.y=tx-238,ty+70
    game.camera.x,game.camera.y,game.camera.zoom=tx,ty-22,(game.world.stageZoom or .84)*1.16
    game.noticeTime=0
end

local function finish(game)
    local intro=game.clearcut and game.clearcut.intro;if not intro then return end
    game.player.introHidden=false;game.player.isMoving=false;game.player.x,game.player.y=intro.targetX,intro.targetY
    game.camera.x,game.camera.y,game.camera.zoom=intro.targetX,intro.targetY,intro.baseZoom
    game.clearcut.intro=nil
    local def=Maps.get(game.clearcut.mapId);game:setNotice(def.name.." · 1구역 작전 개시","food")
end
Intro.finish=finish

function Intro.skip(game)
    local intro=game.clearcut and game.clearcut.intro;if not intro then return false end
    if not intro.startled then Life.startle(game.world,intro.targetX,intro.targetY,520);intro.startled=true end
    finish(game);return true
end

function Intro.update(game,dt)
    local intro=game.clearcut and game.clearcut.intro;if not intro then return false end
    intro.t=math.min(intro.duration,intro.t+dt)
    Life.update(game.world,dt)
    if not intro.startled and intro.t>=STARTLE_AT then
        intro.startled=true;Life.startle(game.world,intro.targetX,intro.targetY,620)
    end
    if intro.t<ENTRY_AT then
        game.player.introHidden=true;game.player.isMoving=false
    else
        game.player.introHidden=false
        local q=smooth((intro.t-ENTRY_AT)/(ARRIVE_AT-ENTRY_AT))
        game.player.x=intro.entryX+(intro.targetX-intro.entryX)*q
        game.player.y=intro.entryY+(intro.targetY-intro.entryY)*q
        game.player.facing=1;game.player.isMoving=q<.995
        if game.player.isMoving then game.player.walkClock=game.player.walkClock+dt*8 end
    end
    for i,b in ipairs(intro.birds)do
        if not b.flying and intro.t>=b.delay then
            b.flying=true;local side=(b.homeX-intro.targetX)>=0 and 1 or -1
            b.vx=side*(155+i*9);b.vy=-115-(i%4)*22
        end
        if b.flying then
            b.vx=b.vx+(b.vx>=0 and 36 or -36)*dt;b.vy=b.vy-13*dt
            b.x,b.y=b.x+b.vx*dt,b.y+b.vy*dt
        else
            b.x=b.homeX+math.sin(intro.t*.7+b.phase)*2;b.y=b.homeY+math.sin(intro.t*1.1+b.phase)*1.5
        end
    end
    local zoomQ=smooth(intro.t/intro.duration)
    game.camera.x=intro.targetX+(1-zoomQ)*24;game.camera.y=intro.targetY-22*(1-zoomQ)
    game.camera.zoom=intro.baseZoom*(1.16-.16*zoomQ)
    if intro.t>=intro.duration then finish(game) end
    return true
end

function Intro.drawWorld(game)
    local intro=game.clearcut and game.clearcut.intro;if not intro then return end
    load();local row=speciesRow[intro.mapId] or 1
    for i,b in ipairs(intro.birds)do if b.flying then
        local frame=b.flying and (math.floor((intro.t-b.delay)*12+i)%FRAMES+1) or 5
        local facing=b.flying and (b.vx>=0 and 1 or -1) or (i%2==0 and -1 or 1)
        local width=(b.flying and 54 or 43)*b.scale;local scale=width/CELL_W
        love.graphics.setColor(.015,.035,.028,b.flying and .13 or .18);love.graphics.ellipse("fill",b.x,b.y+17,width*.26,3)
        love.graphics.setColor(1,1,1,1);love.graphics.draw(atlas,quads[row][frame],math.floor(b.x),math.floor(b.y),0,scale*facing,scale,CELL_W/2,CELL_H/2)
    end end
end

function Intro.drawScreen(game)
    local intro=game.clearcut and game.clearcut.intro;if not intro then return end
    local w,h=love.graphics.getDimensions();local f=game.fonts;local def=Maps.get(intro.mapId);local t=intro.t
    local fade=clamp(1-t/.72,0,1);if fade>0 then love.graphics.setColor(0,0,0,fade);love.graphics.rectangle("fill",0,0,w,h)end
    local bars=clamp(1-math.max(0,t-3.7)/1.1,0,1);local bh=math.floor(h*.065*bars)
    if bh>0 then love.graphics.setColor(.005,.012,.01,.94);love.graphics.rectangle("fill",0,0,w,bh);love.graphics.rectangle("fill",0,h-bh,w,bh)end
    local titleAlpha=clamp(t/.35,0,1)*clamp((1.68-t)/.38,0,1)
    if titleAlpha>0 then
        love.graphics.setFont(f.micro);love.graphics.setColor(def.color[1],def.color[2],def.color[3],titleAlpha);love.graphics.printf("작전 구역 01",0,h*.19,w,"center")
        love.graphics.setFont(f.display);love.graphics.setColor(.97,.95,.84,titleAlpha);love.graphics.printf(def.name,0,h*.19+28,w,"center")
    end
    local goAlpha=clamp((t-3.45)/.22,0,1)*clamp((4.65-t)/.35,0,1)
    if goAlpha>0 then
        love.graphics.setColor(.006,.016,.012,goAlpha*.68);love.graphics.rectangle("fill",w/2-108,h*.67-8,216,48)
        love.graphics.setFont(f.big);love.graphics.setColor(1,.76,.28,goAlpha);love.graphics.printf("작전 개시",0,h*.67,w,"center")
    end
    if t>.75 and t<3.9 then love.graphics.setFont(f.micro);love.graphics.setColor(.72,.78,.71,.58);love.graphics.printf("SPACE / 클릭  건너뛰기",0,h-bh-27,w,"center")end
end

return Intro
