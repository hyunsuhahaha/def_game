local Maps=require("src.clearcut_maps")
local Globe={}
local mapImage,shader
local TAU=math.pi*2

local function clamp(v,a,b)return math.max(a,math.min(b,v))end
local function wrap(a)return (a+math.pi)%TAU-math.pi end
local function rad(v)return v*math.pi/180 end

function Globe.layout(w,h)
    local top,bottom=112,76
    local available=h-top-bottom
    local r=math.floor(math.min(360,w*.245,available*.46))
    local cx=math.floor(math.max(28+r,w*.30));local cy=math.floor(top+available*.50)
    return {cx=cx,cy=cy,r=r,x=cx-r,y=cy-r,w=r*2,h=r*2}
end

local function stateFor(game)
    if game.globeSelectState then return game.globeSelectState end
    local def=Maps.catalog[game.clearcutMapFocus or 1] or Maps.catalog[1]
    local s={yaw=rad(def.globeLon),pitch=rad(def.globeLat)*.62,targetYaw=nil,targetPitch=nil,
        dragging=false,moved=false,velocity=0,pitchVelocity=0,hover=nil}
    game.globeSelectState=s;return s
end
Globe.stateFor=stateFor

function Globe.focus(game,index,snap)
    local def=Maps.catalog[index];if not def then return end
    game.clearcutMapFocus=index
    local s=stateFor(game);local yaw=rad(def.globeLon);local pitch=clamp(rad(def.globeLat)*.62,-.88,.88)
    s.velocity,s.pitchVelocity=0,0
    if snap then s.yaw,s.pitch=yaw,pitch;s.targetYaw,s.targetPitch=nil,nil
    else s.targetYaw,s.targetPitch=yaw,pitch end
end

function Globe.update(game,dt)
    local s=stateFor(game)
    if s.dragging then return end
    if s.targetYaw then
        local d=wrap(s.targetYaw-s.yaw);local k=1-math.exp(-dt*8)
        s.yaw=wrap(s.yaw+d*k);s.pitch=s.pitch+(s.targetPitch-s.pitch)*k
        if math.abs(d)<.002 and math.abs(s.targetPitch-s.pitch)<.002 then s.yaw,s.pitch=s.targetYaw,s.targetPitch;s.targetYaw,s.targetPitch=nil,nil end
    else
        s.yaw=wrap(s.yaw+(s.velocity or 0)*dt);s.pitch=clamp(s.pitch+(s.pitchVelocity or 0)*dt,-1.02,1.02)
        local damp=math.exp(-dt*5.5);s.velocity=(s.velocity or 0)*damp;s.pitchVelocity=(s.pitchVelocity or 0)*damp
    end
end

function Globe.project(game,latDeg,lonDeg,w,h)
    local s=stateFor(game);local l=Globe.layout(w,h);local lat,lon=rad(latDeg),rad(lonDeg)
    local x=math.cos(lat)*math.sin(lon);local y=math.sin(lat);local z=math.cos(lat)*math.cos(lon)
    local cy,sy=math.cos(s.yaw),math.sin(s.yaw)
    local x1=cy*x-sy*z;local z1=sy*x+cy*z
    local cp,sp=math.cos(s.pitch),math.sin(s.pitch)
    local y2=cp*y-sp*z1;local z2=sp*y+cp*z1
    return l.cx+x1*l.r,l.cy-y2*l.r,z2
end

function Globe.markers(game,w,h)
    local out={}
    for i,def in ipairs(Maps.catalog)do
        local x,y,z=Globe.project(game,def.globeLat,def.globeLon,w,h)
        out[i]={x=x,y=y,z=z,r=17,index=i,def=def,visible=z>.045}
    end
    return out
end

function Globe.at(game,x,y,w,h)
    local best,bestD
    for _,m in ipairs(Globe.markers(game,w,h))do if m.visible then
        local dx,dy=x-m.x,y-m.y;local d=dx*dx+dy*dy
        if d<=m.r*m.r and (not bestD or d<bestD)then best,bestD=m.index,d end
    end end
    return best
end

function Globe.inside(game,x,y,w,h)
    local l=Globe.layout(w,h);local dx,dy=x-l.cx,y-l.cy;return dx*dx+dy*dy<=l.r*l.r
end

function Globe.mousepressed(game,x,y,button,w,h)
    if button~=1 or not Globe.inside(game,x,y,w,h)then return false end
    local s=stateFor(game);s.dragging=true;s.moved=false;s.pressX,s.pressY=x,y;s.dragYaw,s.dragPitch=s.yaw,s.pitch
    s.lastX,s.lastY=x,y;s.pressMarker=Globe.at(game,x,y,w,h);s.targetYaw,s.targetPitch=nil,nil;s.velocity,s.pitchVelocity=0,0
    return true
end

function Globe.mousemoved(game,x,y,dx,dy,w,h)
    local s=stateFor(game);if not s.dragging then return false end
    local l=Globe.layout(w,h);local totalX,totalY=x-s.pressX,y-s.pressY
    if totalX*totalX+totalY*totalY>36 then s.moved=true end
    s.yaw=wrap(s.dragYaw-totalX/l.r*1.55);s.pitch=clamp(s.dragPitch+totalY/l.r*1.12,-1.02,1.02)
    s.velocity=clamp(-(dx or 0)/l.r*14,-5,5);s.pitchVelocity=clamp((dy or 0)/l.r*9,-3,3);s.lastX,s.lastY=x,y
    return true
end

function Globe.mousereleased(game,x,y,button,w,h)
    local s=stateFor(game);if button~=1 or not s.dragging then return nil end
    s.dragging=false
    local hit=Globe.at(game,x,y,w,h)
    if not s.moved and hit and hit==s.pressMarker then s.velocity,s.pitchVelocity=0,0;return hit end
end

local function load()
    if mapImage then return end
    mapImage=love.graphics.newImage("assets/ui/globe-world-pixel-v1.png");mapImage:setFilter("nearest","nearest");mapImage:setWrap("repeat","clamp")
    if love.graphics.newShader then shader=love.graphics.newShader("assets/shaders/stage-select-globe.glsl") end
end

function Globe.draw(game,w,h,time)
    load();local s=stateFor(game);local l=Globe.layout(w,h);local previous=love.graphics.getShader and love.graphics.getShader() or nil
    love.graphics.setColor(0,0,0,.42);love.graphics.circle("fill",l.cx+12,l.cy+18,l.r+7)
    love.graphics.setColor(.08,.40,.38,.13);love.graphics.circle("fill",l.cx,l.cy,l.r+18)
    if shader then shader:send("globeYaw",s.yaw);shader:send("globePitch",s.pitch);love.graphics.setShader(shader)end
    love.graphics.setColor(1,1,1,1);love.graphics.draw(mapImage,l.x,l.y,0,l.w/mapImage:getWidth(),l.h/mapImage:getHeight())
    if shader then love.graphics.setShader(previous)end
    love.graphics.setLineWidth(2);love.graphics.setColor(.34,.83,.72,.72);love.graphics.circle("line",l.cx,l.cy,l.r+1)
    love.graphics.setLineWidth(1);love.graphics.setColor(1,1,1,.15);love.graphics.circle("line",l.cx-3,l.cy-4,l.r-8)
    love.graphics.setColor(.95,.62,.18,.24);love.graphics.line(l.cx-l.r-18,l.cy,l.cx-l.r+12,l.cy);love.graphics.line(l.cx+l.r-12,l.cy,l.cx+l.r+18,l.cy)
    return Globe.markers(game,w,h)
end

return Globe
