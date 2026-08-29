-- Dedicated world-tree attacks. Every visible attack uses the authored atlas;
-- gameplay geometry remains owned by clearcut_mode's telegraphs.
local Art={}
local image,quads

local function load()
    if image then return end
    image=love.graphics.newImage("assets/fx/worldtree/worldtree-attacks-atlas-v1.png")
    image:setFilter("nearest","nearest")
    quads={}
    for row=0,4 do for frame=0,5 do
        quads[row*6+frame+1]=love.graphics.newQuad(frame*256,row*256,256,256,image:getDimensions())
    end end
end

function Art.drawBranchWarning(d,t)
    load()
    local progress=math.max(0,math.min(1,(d.fallTime or 0)/math.max(.01,d.fallDuration or 1.15)))
    local frame=math.max(1,math.min(4,1+math.floor(progress*4)))
    local pulse=.70+math.sin((t or 0)*15)*.18
    local sx=(d.length or 300)/226
    local sy=(d.halfWidth or 34)/34
    love.graphics.setColor(1,1,1,pulse)
    love.graphics.draw(image,quads[24+frame],d.x,d.y,d.angle,sx,sy,128,146)
    love.graphics.setColor(1,1,1,1)
end

function Art.drawFallingBranch(d,t)
    load()
    local progress=math.max(0,math.min(1,(d.fallTime or 0)/math.max(.01,d.fallDuration or 1.15)))
    local frame=math.max(1,math.min(6,1+math.floor(progress*6)))
    local sx=(d.length or 300)/226
    local sy=sx
    love.graphics.setColor(1,1,1,math.min(1,(d.life or 1)*2))
    love.graphics.draw(image,quads[18+frame],d.x,d.y-d.h,d.angle,sx,sy,128,128)
    love.graphics.setColor(1,1,1,1)
end

function Art.drawBranchImpact(d,t)
    load()
    local progress=math.max(0,math.min(1,(d.impactAge or 0)/.45))
    local frame=math.max(3,math.min(6,3+math.floor(progress*4)))
    local sx=(d.length or 300)/226
    local sy=(d.halfWidth or 34)/34
    local alpha=math.max(0,1-(d.impactAge or 0)/1.05)
    love.graphics.setColor(1,1,1,alpha)
    love.graphics.draw(image,quads[24+frame],d.x,d.y,d.angle,sx,sy,128,146)
    love.graphics.setColor(1,1,1,1)
end

local function frameFor(tel)
    if tel.phase=="warn" then
        local duration=tel.warnDuration or .8
        return math.max(1,math.min(3,1+math.floor((1-math.max(0,tel.timer)/duration)*3)))
    end
    return math.max(3,math.min(6,3+math.floor((1-math.max(0,tel.timer)/.25)*4)))
end

function Art.draw(tel,t)
    load()
    local frame=frameFor(tel)
    local alpha=tel.phase=="warn" and (.62+math.sin((t or 0)*10)*.12) or math.min(1,math.max(0,tel.timer)/.12)
    love.graphics.setColor(1,1,1,alpha)
    if tel.worldTreeAttack=="rootBurst" then
        local scale=(tel.radius or 62)/82
        love.graphics.draw(image,quads[frame],tel.x,tel.y,0,scale,scale,128,214)
    elseif tel.worldTreeAttack=="vineWhip" then
        local dx,dy=tel.x2-tel.x1,tel.y2-tel.y1
        local length=math.sqrt(dx*dx+dy*dy)
        local angle=math.atan2(dy,dx)
        local sx=length/226
        local sy=((tel.halfWidth or 64)*2)/48
        love.graphics.draw(image,quads[6+frame],(tel.x1+tel.x2)*.5,(tel.y1+tel.y2)*.5,angle,sx,sy,128,128)
    else
        local scale=(tel.radius or 420)/92
        love.graphics.draw(image,quads[12+frame],tel.x,tel.y,0,scale,scale,128,128)
    end
    love.graphics.setColor(1,1,1,1)
    return true
end

return Art
