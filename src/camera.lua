local WorldProjection=require("src.world_projection")
local Camera = {}
Camera.__index = Camera

function Camera.new(x, y)
    return setmetatable({
        x=x,y=y,zoom=1,trauma=0,shakeScale=1,
        renderX=x,renderY=y,renderZoom=1,roll=0,pitch=1,
        inertiaX=0,inertiaY=0,inertiaVX=0,inertiaVY=0,
        rollVelocity=0,zoomKick=0,lastTargetX=x,lastTargetY=y,
        cinematic=nil,perspective=false,
    }, Camera)
end

local function clamp(v,a,b) return math.max(a,math.min(b,v)) end

local function perspectiveHalfExtents(camera,w,h,zoom)
    local halfW,halfH=0,0
    local angle=-(camera.roll or 0);local c,s=math.cos(angle),math.sin(angle)
    for _,point in ipairs({{0,0},{w*.5,0},{w,0},{0,h*.5},{w,h*.5},{0,h},{w*.5,h},{w,h}}) do
        local flatX,flatY=WorldProjection.unproject(point[1],point[2],w,h,camera.pitch)
        local dx,dy=flatX-w*.5,flatY-h*.5
        local rx,ry=dx*c-dy*s,dx*s+dy*c
        halfW,halfH=math.max(halfW,math.abs(rx)/zoom),math.max(halfH,math.abs(ry)/zoom)
    end
    return halfW,halfH
end

-- Short world-space camera direction.  It is deliberately small: pixel art
-- keeps its grid while the foreground/background appear to carry momentum.
function Camera:impulse(dx,dy,roll,zoom)
    self.inertiaVX=self.inertiaVX+(dx or 0)
    self.inertiaVY=self.inertiaVY+(dy or 0)
    self.rollVelocity=self.rollVelocity+(roll or 0)
    self.zoomKick=clamp(self.zoomKick+(zoom or 0),-.08,.12)
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
        self.cinematic=nil
        self.lastTargetX,self.lastTargetY=self.x,self.y
    end
end

function Camera:update(dt, target, world)
    local w, h = love.graphics.getDimensions()
    local pitch=clamp(self.pitch or 1,.72,1)
    if world.overviewBounds then
        local b=world.overviewBounds
        self.x,self.y,self.zoom=b.x,b.y,math.min(w/b.w,h/b.h)
        self.renderX,self.renderY,self.renderZoom,self.roll=self.x,self.y,self.zoom,0
        self.trauma=math.max(0,self.trauma-dt*1.8)
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
    local halfW, halfH
    if self.perspective then
        local baseW,baseH=perspectiveHalfExtents(self,w,h,1)
        desiredZoom=math.max(desiredZoom,baseW*2/b.w,baseH*2/b.h)
        halfW,halfH=perspectiveHalfExtents(self,w,h,desiredZoom)
    else halfW,halfH=w/(2*desiredZoom),h/(2*desiredZoom*pitch) end
    local minX,maxX=b.x+halfW,b.x+b.w-halfW
    local minY,maxY=b.y+halfH,b.y+b.h-halfH
    local tx=minX>maxX and b.x+b.w/2 or math.max(minX,math.min(maxX,targetX))
    local ty=minY>maxY and b.y+b.h/2 or math.max(minY,math.min(maxY,targetY))
    local targetDX,targetDY=targetX-(self.lastTargetX or targetX),targetY-(self.lastTargetY or targetY)
    self.lastTargetX,self.lastTargetY=targetX,targetY
    self.inertiaVX=self.inertiaVX-targetDX*.24
    self.inertiaVY=self.inertiaVY-targetDY*.15
    self.rollVelocity=self.rollVelocity+clamp(targetDX*-.000045,-.006,.006)
    local smoothing = 1 - math.exp(-dt * 7)
    self.x = self.x + (tx - self.x) * smoothing
    self.y = self.y + (ty - self.y) * smoothing
    self.inertiaVX,self.inertiaVY=self.inertiaVX*math.exp(-dt*7.5),self.inertiaVY*math.exp(-dt*7.5)
    self.inertiaX=(self.inertiaX+self.inertiaVX*dt)*math.exp(-dt*5.2)
    self.inertiaY=(self.inertiaY+self.inertiaVY*dt)*math.exp(-dt*5.2)
    self.rollVelocity=self.rollVelocity*math.exp(-dt*8)
    self.roll=clamp((self.roll+self.rollVelocity*dt)*math.exp(-dt*5.5),-.018,.018)
    self.zoomKick=self.zoomKick*math.exp(-dt*6.5)
    self.renderX=self.x+clamp(self.inertiaX,-22,22)
    self.renderY=self.y+clamp(self.inertiaY,-14,14)
    self.renderZoom=desiredZoom*(1+self.zoomKick)
    self.trauma = math.max(0, self.trauma - dt * 1.8)
end

function Camera:attach(viewWidth,viewHeight,rawPerspectivePass)
    local w, h = viewWidth or love.graphics.getWidth(), viewHeight or love.graphics.getHeight()
    local shake = self.trauma * self.trauma * 9 * (self.shakeScale or 0)
    love.graphics.push()
    love.graphics.translate(w / 2 + love.math.random(-shake, shake), h / 2 + love.math.random(-shake, shake))
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
    if self.perspective then flatX,flatY=WorldProjection.unproject(screenX,screenY,w,h,self.pitch) end
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
    local flatX=w*.5+dx*c-dy*s
    local flatY=h*.5+dx*s+dy*c
    if self.perspective then return WorldProjection.project(flatX,flatY,w,h,self.pitch) end
    return flatX,h*.5+(flatY-h*.5)*clamp(self.pitch or 1,.72,1),1
end

return Camera
