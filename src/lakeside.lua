-- One fixed lakeshore. Tier changes open inland space, never stretch the art.
local Lake={}
local image,shader
local boundaryArt={}
function Lake.bounds(world,tier)
    local growth=math.min(1,math.max(0,(tier-1)/4))
    local tail=tier>5 and 1-.82^(tier-5)or 0
    local w=world.width*(.75+.15*growth+.03*tail)
    local h=world.height*(.70+.15*growth+.03*tail)
    return {x=world.width*.93-w,y=world.height*.88-h,w=w,h=h}
end
function Lake.configure(world,tier)
    local previous=world.lakeside and world.playBounds
    world.lakeside=true;world.northBackdrop=false
    world.cameraTopReveal=0;world.playBounds=Lake.bounds(world,tier)
    local b=world.playBounds
    world.cameraBounds={x=b.x-world.width*.12,y=b.y-world.height*.25,
        w=b.w+world.width*.24,h=b.h+world.height*.40}
    if previous and (previous.w~=b.w or previous.h~=b.h) then
        world.lakeOpening={from=previous,t=0,duration=1.35}
    end
end
function Lake.update(world,dt)
    local fx=world.lakeOpening
    if fx then fx.t=math.min(fx.duration,fx.t+dt);if fx.t>=fx.duration then world.lakeOpening=nil end end
end
function Lake.drawGround(world)
    if not world.lakeside then return false end
    if not image then
        image=love.graphics.newImage("assets/scenery/lakeside/lakeside-environment-pixel-v1.png")
        image:setFilter("nearest","nearest")
        shader=love.graphics.newShader("assets/shaders/lakeside-ground.glsl")
    end
    local old=love.graphics.getShader()
    shader:send("clock",love.timer.getTime())
    love.graphics.setShader(shader);love.graphics.setColor(1,1,1,1)
    -- Overscan is presentation only, never spawn/movement terrain. Mirrored
    -- woodland/water texels also cover extreme viewport aspect ratios.
    love.graphics.draw(image,-world.width*4,-world.height*4,0,world.width*9/image:getWidth(),world.height*9/image:getHeight())
    love.graphics.setShader(old)
    return true
end
local function inside(b,x,y)
    return x>=b.x and x<=b.x+b.w and y>=b.y and y<=b.y+b.h
end
function Lake.queue(world,queue)
    if not world.lakeside then return end
    local b,fx=world.playBounds,world.lakeOpening
    -- Never reuse harvestable tree silhouettes for non-interactive boundaries.
    -- Sparse low props identify closed land without looking like objectives.
    local seed=7319
    local function random()seed=(seed*16807)%2147483647;return(seed-1)/2147483646 end
    for row=0,math.ceil(world.height/145)do for col=0,math.ceil(world.width/155)do
        local hash=math.floor(random()*9999)
        local x=col*155+(random()-.5)*140
        local y=row*145+(random()-.5)*130
        local current=inside(b,x,y)
        local alpha=not current and 1 or(fx and not inside(fx.from,x,y)and 1-fx.t/fx.duration or 0)
        if alpha>0 and hash%3==0 and x>=-70 and x<=world.width and y>=-80 and y<=world.height then
            local kind=hash%2==0 and "fern"or "rock"
            local def=require("src.forest_scenery").catalog[kind]
            if not boundaryArt[kind]then
                boundaryArt[kind]=love.graphics.newImage(def.file)
                boundaryArt[kind]:setFilter("nearest","nearest")
            end
            local prop=boundaryArt[kind]
            local scale=def.width/prop:getWidth()*(.45+(hash%5)*.035)
            queue[#queue+1]={x=x,y=y,anchorY=y,draw=function()
                love.graphics.setColor(.84,.89,.80,alpha)
                love.graphics.draw(prop,x,y,0,scale,scale,prop:getWidth()/2,prop:getHeight()*def.foot)
            end}
        end
    end end
end
return Lake
