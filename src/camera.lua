local Camera = {}
Camera.__index = Camera

function Camera.new(x, y)
    return setmetatable({
        x=x,y=y,zoom=1,trauma=0,shakeScale=1,
        renderX=x,renderY=y,renderZoom=1,roll=0,
        inertiaX=0,inertiaY=0,inertiaVX=0,inertiaVY=0,
        rollVelocity=0,zoomKick=0,lastTargetX=x,lastTargetY=y,
        cinematic=nil,
    }, Camera)
end

local function clamp(v,a,b) return math.max(a,math.min(b,v)) end

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
    local halfW, halfH = w / (2 * desiredZoom), h / (2 * desiredZoom)
    local b=world.playBounds or {x=0,y=0,w=world.width,h=world.height}
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

function Camera:attach()
    local w, h = love.graphics.getDimensions()
    local shake = self.trauma * self.trauma * 9 * (self.shakeScale or 0)
    love.graphics.push()
    love.graphics.translate(w / 2 + love.math.random(-shake, shake), h / 2 + love.math.random(-shake, shake))
    love.graphics.rotate(self.roll or 0)
    love.graphics.scale(self.renderZoom or self.zoom)
    love.graphics.translate(-(self.renderX or self.x), -(self.renderY or self.y))
end

function Camera:detach() love.graphics.pop() end

function Camera:visibleBounds()
    local w, h = love.graphics.getDimensions()
    local z=self.renderZoom or self.zoom;local x,y=self.renderX or self.x,self.renderY or self.y
    local pad=math.abs(math.sin(self.roll or 0))*math.max(w,h)/z
    return x-w/(2*z)-pad,y-h/(2*z)-pad,x+w/(2*z)+pad,y+h/(2*z)+pad
end

function Camera:screenToWorld(screenX, screenY)
    local w, h = love.graphics.getDimensions()
    local z=self.renderZoom or self.zoom;local dx,dy=(screenX-w/2)/z,(screenY-h/2)/z
    local a=-(self.roll or 0);local c,s=math.cos(a),math.sin(a)
    return (self.renderX or self.x)+dx*c-dy*s,(self.renderY or self.y)+dx*s+dy*c
end

return Camera
