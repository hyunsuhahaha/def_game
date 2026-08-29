-- Dedicated world-tree attacks. Every visible attack uses the authored atlas;
-- gameplay geometry remains owned by clearcut_mode's telegraphs.
local Art={}
local image,quads,warningImage,warningQuads

local function load()
    if image then return end
    image=love.graphics.newImage("assets/fx/worldtree/worldtree-attacks-atlas-v2.png")
    image:setFilter("nearest","nearest")
    warningImage=love.graphics.newImage("assets/fx/worldtree/worldtree-telegraphs-atlas-v1.png")
    warningImage:setFilter("nearest","nearest")
    quads={}
    for row=0,4 do for frame=0,5 do
        quads[row*6+frame+1]=love.graphics.newQuad(frame*384,row*384,384,384,image:getDimensions())
    end end
    warningQuads={}
    for row=0,3 do for frame=0,5 do
        warningQuads[row*6+frame+1]=love.graphics.newQuad(frame*384,row*384,384,384,warningImage:getDimensions())
    end end
end

local function warningFrame(timer,duration)
    return math.max(1,math.min(6,1+math.floor((1-math.max(0,timer)/math.max(.01,duration))*6)))
end

local function warningCircle(row,frame,x,y,radius,alpha)
    local nativeRadius=row==2 and 138 or 123
    local oy=row==0 and 238 or 192
    local scale=radius/nativeRadius
    love.graphics.setColor(1,1,1,alpha)
    love.graphics.draw(warningImage,warningQuads[row*6+frame],x,y,0,scale,scale,192,oy)
end

local function warningCapsule(row,frame,x1,y1,x2,y2,halfWidth,alpha)
    local dx,dy=x2-x1,y2-y1
    local length=math.sqrt(dx*dx+dy*dy)
    local angle=math.atan2(dy,dx)
    local nativeHalf=row==3 and 51 or 36
    local oy=row==3 and 224 or 192
    love.graphics.setColor(1,1,1,alpha)
    love.graphics.draw(warningImage,warningQuads[row*6+frame],(x1+x2)*.5,(y1+y2)*.5,
        angle,length/340,halfWidth/nativeHalf,192,oy)
    -- Swept-circle collision includes both endpoint discs. Draw the authored
    -- circular warning at each endpoint so the visible footprint matches it.
    warningCircle(0,frame,x1,y1,halfWidth,alpha)
    warningCircle(0,frame,x2,y2,halfWidth,alpha)
end

function Art.drawBranchWarning(d,t)
    load()
    local progress=math.max(0,math.min(1,(d.fallTime or 0)/math.max(.01,d.fallDuration or 1.15)))
    local frame=math.max(1,math.min(6,1+math.floor(progress*6)))
    local pulse=.78+math.sin((t or 0)*15)*.14
    local half=(d.length or 300)*.5;local c,s=math.cos(d.angle or 0),math.sin(d.angle or 0)
    warningCapsule(3,frame,d.x-c*half,d.y-s*half,d.x+c*half,d.y+s*half,d.halfWidth or 34,pulse)
    love.graphics.setColor(1,1,1,1)
end

function Art.drawFallingBranch(d,t)
    load()
    local progress=math.max(0,math.min(1,(d.fallTime or 0)/math.max(.01,d.fallDuration or 1.15)))
    local frame=math.max(1,math.min(6,1+math.floor(progress*6)))
    local sx=(d.length or 300)/340
    local sy=sx
    love.graphics.setColor(1,1,1,math.min(1,(d.life or 1)*2))
    love.graphics.draw(image,quads[18+frame],d.x,d.y-d.h,d.angle,sx,sy,192,192)
    love.graphics.setColor(1,1,1,1)
end

function Art.drawBranchImpact(d,t)
    load()
    local progress=math.max(0,math.min(1,(d.impactAge or 0)/.45))
    local frame=math.max(3,math.min(6,3+math.floor(progress*4)))
    local sx=(d.length or 300)/340
    local sy=(d.halfWidth or 34)/51
    local alpha=math.max(0,1-(d.impactAge or 0)/1.05)
    love.graphics.setColor(1,1,1,alpha)
    love.graphics.draw(image,quads[24+frame],d.x,d.y,d.angle,sx,sy,192,224)
    love.graphics.setColor(1,1,1,1)
end

local function frameFor(tel)
    return math.max(3,math.min(6,3+math.floor((1-math.max(0,tel.timer)/.25)*4)))
end

function Art.drawWarning(tel,t)
    load()
    local frame=warningFrame(tel.timer,tel.warnDuration or .8)
    local alpha=.80+math.sin((t or 0)*12)*.12
    if tel.worldTreeAttack=="rootBurst" then
        warningCircle(0,frame,tel.x,tel.y,tel.radius or 62,alpha)
    elseif tel.worldTreeAttack=="vineWhip" then
        warningCapsule(1,frame,tel.x1,tel.y1,tel.x2,tel.y2,tel.halfWidth or 64,alpha)
    else
        warningCircle(2,frame,tel.x,tel.y,tel.radius or 420,alpha)
    end
    love.graphics.setColor(1,1,1,1)
    return true
end

function Art.draw(tel,t)
    load()
    if tel.phase=="warn" then return Art.drawWarning(tel,t) end
    local frame=frameFor(tel)
    local alpha=math.min(1,math.max(0,tel.timer)/.12)
    love.graphics.setColor(1,1,1,alpha)
    if tel.worldTreeAttack=="rootBurst" then
        local scale=(tel.radius or 62)/123
        love.graphics.draw(image,quads[frame],tel.x,tel.y,0,scale,scale,192,320)
    elseif tel.worldTreeAttack=="vineWhip" then
        local dx,dy=tel.x2-tel.x1,tel.y2-tel.y1
        local length=math.sqrt(dx*dx+dy*dy)
        local angle=math.atan2(dy,dx)
        local sx=length/340
        local sy=((tel.halfWidth or 64)*2)/72
        love.graphics.draw(image,quads[6+frame],(tel.x1+tel.x2)*.5,(tel.y1+tel.y2)*.5,angle,sx,sy,192,192)
    else
        local scale=(tel.radius or 420)/138
        love.graphics.draw(image,quads[12+frame],tel.x,tel.y,0,scale,scale,192,192)
    end
    love.graphics.setColor(1,1,1,1)
    return true
end

return Art
