local Camera = {}
Camera.__index = Camera

function Camera.new(x, y)
    return setmetatable({x = x, y = y, zoom = 1, trauma = 0, shakeScale = 1}, Camera)
end

function Camera:update(dt, target, world)
    local w, h = love.graphics.getDimensions()
    if world.overviewBounds then
        local b=world.overviewBounds
        self.x,self.y,self.zoom=b.x,b.y,math.min(w/b.w,h/b.h)
        self.trauma=math.max(0,self.trauma-dt*1.8)
        return
    end
    local halfW, halfH = w / (2 * self.zoom), h / (2 * self.zoom)
    local b=world.playBounds or {x=0,y=0,w=world.width,h=world.height}
    local minX,maxX=b.x+halfW,b.x+b.w-halfW
    local minY,maxY=b.y+halfH,b.y+b.h-halfH
    local tx=minX>maxX and b.x+b.w/2 or math.max(minX,math.min(maxX,target.x))
    local ty=minY>maxY and b.y+b.h/2 or math.max(minY,math.min(maxY,target.y))
    local smoothing = 1 - math.exp(-dt * 7)
    self.x = self.x + (tx - self.x) * smoothing
    self.y = self.y + (ty - self.y) * smoothing
    self.trauma = math.max(0, self.trauma - dt * 1.8)
end

function Camera:attach()
    local w, h = love.graphics.getDimensions()
    local shake = self.trauma * self.trauma * 9 * (self.shakeScale or 0)
    love.graphics.push()
    love.graphics.translate(w / 2 + love.math.random(-shake, shake), h / 2 + love.math.random(-shake, shake))
    love.graphics.scale(self.zoom)
    love.graphics.translate(-self.x, -self.y)
end

function Camera:detach() love.graphics.pop() end

function Camera:visibleBounds()
    local w, h = love.graphics.getDimensions()
    return self.x - w / (2*self.zoom), self.y - h / (2*self.zoom), self.x + w / (2*self.zoom), self.y + h / (2*self.zoom)
end

function Camera:screenToWorld(screenX, screenY)
    local w, h = love.graphics.getDimensions()
    return self.x + (screenX - w / 2) / self.zoom, self.y + (screenY - h / 2) / self.zoom
end

return Camera
