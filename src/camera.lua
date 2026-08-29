local WorldProjection=require("src.world_projection")
local Camera = {}
Camera.__index = Camera
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end

function Camera.new(x, y)
    return setmetatable({
        x=x,y=y,zoom=1,trauma=0,shakeScale=1,shakeClock=0,shakeX=0,shakeY=0,
        renderX=x,renderY=y,renderZoom=1,roll=0,pitch=1,
        inertiaX=0,inertiaY=0,inertiaVX=0,inertiaVY=0,
        rollVelocity=0,zoomKick=0,lastTargetX=x,lastTargetY=y,
        cinematic=nil,perspective=false,userZoom=1,
        mode="default",skyviewBlend=0,skyviewFrom=0,skyviewTarget=0,
        skyviewTime=0,skyviewDuration=.6,
    }, Camera)
end

function Camera:setMode(mode,duration)
    mode=mode=="skyview" and "skyview" or "default"
    local target=mode=="skyview" and 1 or 0
    if self.mode==mode and self.skyviewTarget==target then return end
    self.mode=mode
    self.skyviewFrom=self.skyviewBlend or 0
    self.skyviewTarget=target
    self.skyviewTime=0
    self.skyviewDuration=clamp(duration or .6,.4,.8)
end

function Camera:updateMode(dt)
    local target=self.skyviewTarget or 0
    if math.abs((self.skyviewBlend or 0)-target)<.0001 then
        self.skyviewBlend=target
        return
    end
    self.skyviewTime=math.min(self.skyviewDuration,(self.skyviewTime or 0)+dt)
    local t=self.skyviewTime/math.max(.001,self.skyviewDuration)
    t=t*t*(3-2*t)
    self.skyviewBlend=(self.skyviewFrom or 0)+(target-(self.skyviewFrom or 0))*t
end

local function perspectiveExtents(camera,w,h,zoom)
    local left,top,right,bottom=0,0,0,0
    local angle=-(camera.roll or 0);local c,s=math.cos(angle),math.sin(angle)
    for _,point in ipairs({{0,0},{w*.5,0},{w,0},{0,h*.5},{w,h*.5},{0,h},{w*.5,h},{w,h}}) do
        local flatX,flatY=WorldProjection.unproject(point[1],point[2],w,h,camera.pitch,camera.skyviewBlend)
        local dx,dy=flatX-w*.5,flatY-h*.5
        local rx,ry=dx*c-dy*s,dx*s+dy*c
        rx,ry=rx/zoom,ry/zoom
        left,right=math.max(left,-rx),math.max(right,rx)
        top,bottom=math.max(top,-ry),math.max(bottom,ry)
    end
    return left,top,right,bottom
end

local function retainProjectedTarget(camera,targetX,targetY,cameraX,cameraY,zoom,w,h)
    local c,s=math.cos(camera.roll or 0),math.sin(camera.roll or 0)
    local dx,dy=(targetX-cameraX)*zoom,(targetY-cameraY)*zoom
    local flatX=w*.5+dx*c-dy*s
    local flatY=h*.5+dx*s+dy*c
    local screenX,screenY=WorldProjection.project(flatX,flatY,w,h,camera.pitch,camera.skyviewBlend)
    -- The foot anchor may reach the lower edge, while the character body needs
    -- more clearance above it. Only edge-clamped views need this correction;
    -- ordinary tracking remains centered on the target.
    local safeX=clamp(screenX,56,w-56)
    local safeY=clamp(screenY,116,h-48)
    if safeX==screenX and safeY==screenY then return cameraX,cameraY end
    local desiredFlatX,desiredFlatY=WorldProjection.unproject(safeX,safeY,w,h,camera.pitch,camera.skyviewBlend)
    local shiftFlatX,shiftFlatY=flatX-desiredFlatX,flatY-desiredFlatY
    return cameraX+(shiftFlatX*c+shiftFlatY*s)/zoom,
        cameraY+(-shiftFlatX*s+shiftFlatY*c)/zoom
end

-- Short world-space camera direction.  It is deliberately small: pixel art
-- keeps its grid while the foreground/background appear to carry momentum.
function Camera:impulse(dx,dy,roll,zoom)
    -- A full-screen mesh magnifies tiny camera impulses into visible wobble.
    -- Keep impact energy in particles/actor animation and admit only a trace
    -- of positional recoil to a projected camera.
    local perspectiveScale=self.perspective and .08 or 1
    self.inertiaVX=self.inertiaVX+(dx or 0)*perspectiveScale
    self.inertiaVY=self.inertiaVY+(dy or 0)*perspectiveScale
    self.rollVelocity=self.rollVelocity+(roll or 0)*perspectiveScale
    local zoomLimit=self.perspective and .008 or .12
    self.zoomKick=clamp(self.zoomKick+(zoom or 0)*perspectiveScale,-zoomLimit,zoomLimit)
end

function Camera:updateShake(dt)
    self.shakeClock=(self.shakeClock or 0)+dt
    -- Projected ground and every billboard share this offset, so procedural
    -- shake reads as violent whole-screen vibration in 2.5D. Disable that
    -- displacement there; hit flashes, particles and sprites still react.
    local amplitude=(self.trauma or 0)^2*(self.perspective and 0 or 7)*(self.shakeScale or 0)
    local clock=self.shakeClock
    local x=(math.sin(clock*13.1)+math.sin(clock*19.7+.8)*.38)*amplitude/1.38
    local y=(math.sin(clock*16.3+1.4)+math.sin(clock*23.2)*.32)*amplitude/1.32
    self.shakeX=math.floor(x*2+.5)/2
    self.shakeY=math.floor(y*2+.5)/2
end

function Camera:focus(x,y,duration,zoom)
    self.cinematic={x=x,y=y,time=duration or 2.5,duration=duration or 2.5,zoom=zoom or 1.08}
end

-- Scripted scenes sometimes author x/y/zoom directly and return before the
-- ordinary camera update. Mirror those authored values into the render pose.
function Camera:syncRender(resetMotion)
    self.renderX,self.renderY,self.renderZoom=self.x,self.y,self.zoom
    if resetMotion then
        self.inertiaX,self.inertiaY,self.inertiaVX,self.inertiaVY=0,0,0,0
        self.roll,self.rollVelocity,self.zoomKick=0,0,0
        self.shakeX,self.shakeY=0,0
        self.cinematic=nil
        self.lastTargetX,self.lastTargetY=self.x,self.y
    end
end

function Camera:update(dt, target, world)
    local w, h = love.graphics.getDimensions()
    local pitch=clamp(self.pitch or 1,.72,1)
    if world.overviewBounds then
        local b=world.overviewBounds
        local overviewZoom=math.min(w/b.w,h/b.h)*(self.userZoom or 1)
        self.x,self.y,self.zoom=b.x,b.y,overviewZoom
        self.renderX,self.renderY,self.renderZoom,self.roll=self.x,self.y,self.zoom,0
        self.trauma=math.max(0,self.trauma-dt*(self.perspective and 2.6 or 1.8))
        self:updateShake(dt)
        return
    end
    local focus=self.cinematic
    if focus then
        focus.time=math.max(0,focus.time-dt)
        if focus.time<=0 then self.cinematic=nil;focus=nil end
    end
    local targetX,targetY=focus and focus.x or target.x,focus and focus.y or target.y
    local desiredZoom=self.zoom
    if focus then
        local edge=math.min(1,(focus.duration-focus.time)/.28,focus.time/.38)
        desiredZoom=self.zoom*(1+(focus.zoom-1)*math.max(0,edge))
    end
    local b=world.playBounds or {x=0,y=0,w=world.width,h=world.height}
    local leftExtent,topExtent,rightExtent,bottomExtent
    if self.perspective then
        local baseLeft,baseTop,baseRight,baseBottom=perspectiveExtents(self,w,h,1)
        local fitZoom=math.max((baseLeft+baseRight)/b.w,(baseTop+baseBottom)/b.h)
        -- Keep ordinary landscape views inside the current stage. A severe
        -- aspect mismatch (notably a tall portrait window) would require a
        -- huge zoom and a fixed midpoint, so preserve the authored zoom there.
        if w>=h or fitZoom<=desiredZoom*1.25 then desiredZoom=math.max(desiredZoom,fitZoom) end
        leftExtent,topExtent,rightExtent,bottomExtent=perspectiveExtents(self,w,h,desiredZoom)
    else
        leftExtent,rightExtent=w/(2*desiredZoom),w/(2*desiredZoom)
        topExtent,bottomExtent=h/(2*desiredZoom*pitch),h/(2*desiredZoom*pitch)
    end
    local minX,maxX=b.x+leftExtent,b.x+b.w-rightExtent
    local minY,maxY=b.y+topExtent,b.y+b.h-bottomExtent
    -- A portrait viewport can see more world than the current stage footprint.
    -- In that case there is no valid clamped camera interval: follow the actor
    -- instead of freezing at the stage midpoint and letting them leave frame.
    local tx=minX>maxX and targetX or math.max(minX,math.min(maxX,targetX))
    local ty=minY>maxY and targetY or math.max(minY,math.min(maxY,targetY))
    if self.perspective and targetX>=b.x and targetX<=b.x+b.w and targetY>=b.y and targetY<=b.y+b.h then
        tx,ty=retainProjectedTarget(self,targetX,targetY,tx,ty,desiredZoom,w,h)
    end
    local targetDX,targetDY=targetX-(self.lastTargetX or targetX),targetY-(self.lastTargetY or targetY)
    self.lastTargetX,self.lastTargetY=targetX,targetY
    local motionScale=self.perspective and .08 or 1
    self.inertiaVX=self.inertiaVX-targetDX*.24*motionScale
    self.inertiaVY=self.inertiaVY-targetDY*.15*motionScale
    self.rollVelocity=self.rollVelocity+clamp(targetDX*-.000045*motionScale,-.0025,.0025)
    local smoothing = 1 - math.exp(-dt * 7)
    self.x = self.x + (tx - self.x) * smoothing
    self.y = self.y + (ty - self.y) * smoothing
    self.inertiaVX,self.inertiaVY=self.inertiaVX*math.exp(-dt*7.5),self.inertiaVY*math.exp(-dt*7.5)
    self.inertiaX=(self.inertiaX+self.inertiaVX*dt)*math.exp(-dt*5.2)
    self.inertiaY=(self.inertiaY+self.inertiaVY*dt)*math.exp(-dt*5.2)
    self.rollVelocity=self.rollVelocity*math.exp(-dt*8)
    local rollLimit=self.perspective and 0 or .018
    self.roll=clamp((self.roll+self.rollVelocity*dt)*math.exp(-dt*5.5),-rollLimit,rollLimit)
    self.zoomKick=self.zoomKick*math.exp(-dt*6.5)
    local inertiaLimitX=self.perspective and 1.5 or 22
    local inertiaLimitY=self.perspective and 1 or 14
    self.renderX=self.x+clamp(self.inertiaX,-inertiaLimitX,inertiaLimitX)
    self.renderY=self.y+clamp(self.inertiaY,-inertiaLimitY,inertiaLimitY)
    self.renderZoom=desiredZoom*(1+self.zoomKick)
    self.trauma = math.max(0, self.trauma - dt * (self.perspective and 5.5 or 1.8))
    self:updateShake(dt)
end

function Camera:attach(viewWidth,viewHeight,rawPerspectivePass)
    local w, h = viewWidth or love.graphics.getWidth(), viewHeight or love.graphics.getHeight()
    love.graphics.push()
    love.graphics.translate(w / 2 + (self.shakeX or 0), h / 2 + (self.shakeY or 0))
    love.graphics.rotate(self.roll or 0)
    local z=self.renderZoom or self.zoom
    local pitch=rawPerspectivePass and 1 or clamp(self.pitch or 1,.72,1)
    love.graphics.scale(z,z*pitch)
    love.graphics.translate(-(self.renderX or self.x), -(self.renderY or self.y))
end

function Camera:detach() love.graphics.pop() end

function Camera:visibleBounds()
    local w, h = love.graphics.getDimensions()
    if self.perspective then
        local points={{0,0},{w*.5,0},{w,0},{0,h*.5},{w,h*.5},{0,h},{w*.5,h},{w,h}}
        local left,top,right,bottom=math.huge,math.huge,-math.huge,-math.huge
        for _,point in ipairs(points) do
            local x,y=self:screenToWorld(point[1],point[2])
            left,top=math.min(left,x),math.min(top,y)
            right,bottom=math.max(right,x),math.max(bottom,y)
        end
        return left,top,right,bottom
    end
    local z=self.renderZoom or self.zoom;local x,y=self.renderX or self.x,self.renderY or self.y
    local pitch=clamp(self.pitch or 1,.72,1)
    local pad=math.abs(math.sin(self.roll or 0))*math.max(w,h)/(z*pitch)
    return x-w/(2*z)-pad,y-h/(2*z*pitch)-pad,x+w/(2*z)+pad,y+h/(2*z*pitch)+pad
end

function Camera:screenToWorld(screenX, screenY)
    local w, h = love.graphics.getDimensions()
    local flatX,flatY=screenX,screenY
    if self.perspective then flatX,flatY=WorldProjection.unproject(screenX,screenY,w,h,self.pitch,self.skyviewBlend) end
    flatX,flatY=flatX-(self.shakeX or 0),flatY-(self.shakeY or 0)
    local z=self.renderZoom or self.zoom;local dx,dy=flatX-w/2,flatY-h/2
    local a=-(self.roll or 0);local c,s=math.cos(a),math.sin(a)
    local rx,ry=dx*c-dy*s,dx*s+dy*c
    local pitch=self.perspective and 1 or clamp(self.pitch or 1,.72,1)
    return (self.renderX or self.x)+rx/z,(self.renderY or self.y)+ry/(z*pitch)
end

function Camera:worldToScreen(worldX,worldY)
    local w,h=love.graphics.getDimensions()
    local z=self.renderZoom or self.zoom
    local dx,dy=(worldX-(self.renderX or self.x))*z,(worldY-(self.renderY or self.y))*z
    local c,s=math.cos(self.roll or 0),math.sin(self.roll or 0)
    local flatX=w*.5+dx*c-dy*s+(self.shakeX or 0)
    local flatY=h*.5+dx*s+dy*c+(self.shakeY or 0)
    if self.perspective then return WorldProjection.project(flatX,flatY,w,h,self.pitch,self.skyviewBlend) end
    return flatX,h*.5+(flatY-h*.5)*clamp(self.pitch or 1,.72,1),1
end

return Camera
