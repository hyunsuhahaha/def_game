-- Localised cartoon-pixel gouges. Nothing is drawn between mole and target.
local Art={}
local image,quads

local function load()
    if image then return end
    image=love.graphics.newImage("assets/fx/mole-claw/mole-claw-swipe-cartoon-pixel-v1.png")
    image:setFilter("nearest","nearest")
    quads={}
    for tier=0,2 do
        quads[tier+1]={}
        for frame=0,4 do quads[tier+1][frame+1]=love.graphics.newQuad(frame*192,tier*128,192,128,image:getDimensions()) end
    end
end

local function tierFor(level) return level>=5 and 3 or (level>=3 and 2 or 1) end

local function defaultHalfWidth(level)
    local tier=tierFor(level)
    return 39*(.66+(tier-1)*.08)
end

function Art.spawn(mode,x,y,angle,level,curveFlip,halfWidth,hand,dual)
    mode.minerClawFx=mode.minerClawFx or {}
    mode.minerClawMarks=mode.minerClawMarks or {}
    halfWidth=halfWidth or defaultHalfWidth(level)
    local shared={x=x,y=y,angle=angle,level=level,curveFlip=curveFlip or 1,halfWidth=halfWidth,hand=hand or 1,dual=dual==true}
    mode.minerClawFx[#mode.minerClawFx+1]={x=shared.x,y=shared.y,angle=shared.angle,level=shared.level,
        curveFlip=shared.curveFlip,halfWidth=shared.halfWidth,hand=shared.hand,dual=shared.dual,life=.22,maxLife=.22}
    mode.minerClawMarks[#mode.minerClawMarks+1]={x=shared.x,y=shared.y,angle=shared.angle,level=shared.level,
        curveFlip=shared.curveFlip,halfWidth=shared.halfWidth,hand=shared.hand,dual=shared.dual,life=6,maxLife=6}
    if #mode.minerClawMarks>90 then table.remove(mode.minerClawMarks,1) end
end

local function drawEntry(entry,quad,displayAngle)
    local angle=displayAngle or entry.angle
    if not entry.dual then
        local scale=(entry.halfWidth or defaultHalfWidth(entry.level))/39
        love.graphics.draw(image,quad,math.floor(entry.x+.5),math.floor(entry.y+.5),angle,
            scale,scale*(entry.curveFlip or 1),96,64)
        return
    end
    -- Rank six is one composite effect event. The two authored hand trails are
    -- drawn inside it, so adding targets can never add more FX objects.
    local halfWidth=entry.halfWidth or defaultHalfWidth(entry.level)
    local offset=halfWidth*.28
    local handWidth=halfWidth-offset
    local scale=handWidth/39
    local px,py=-math.sin(angle),math.cos(angle)
    love.graphics.draw(image,quad,math.floor(entry.x+px*offset+.5),math.floor(entry.y+py*offset+.5),angle,
        scale,scale*(entry.curveFlip or 1),96,64)
    love.graphics.draw(image,quad,math.floor(entry.x-px*offset+.5),math.floor(entry.y-py*offset+.5),angle,
        scale,scale*-(entry.curveFlip or 1),96,64)
end

function Art.update(mode,dt)
    for _,list in ipairs({mode.minerClawFx or {},mode.minerClawMarks or {}}) do
        for i=#list,1,-1 do
            list[i].life=list[i].life-dt
            if list[i].life<=0 then table.remove(list,i) end
        end
    end
end

function Art.draw(mode,game,t)
    if #(mode.minerClawFx or {})==0 and #(mode.minerClawMarks or {})==0 then return end
    load()
    local previous={love.graphics.getColor()}
    -- The completed gouge remains at the struck world coordinate for six seconds.
    for _,mark in ipairs(mode.minerClawMarks or {}) do
        local tier=tierFor(mark.level)
        local alpha=math.min(.86,mark.life/.8*.86)
        -- The atlas reaches 39 native pixels to either side of its centre.
        -- Scaling from the gameplay half-width keeps the visible gouge and hit
        -- envelope identical at every upgrade level.
        love.graphics.setColor(.34,.25,.18,alpha*.82)
        drawEntry(mark,quads[tier][5])
    end
    -- A very short contact animation reveals the same scratches at that point.
    for _,fx in ipairs(mode.minerClawFx or {}) do
        local p=math.max(0,math.min(.999,1-fx.life/fx.maxLife))
        local frame=math.floor(p*5)+1
        local tier=tierFor(fx.level)
        love.graphics.setColor(1,1,1,math.min(1,fx.life/.05))
        drawEntry(fx,quads[tier][frame])
    end
    love.graphics.setColor(unpack(previous))
end

local function projectedAngle(entry,camera)
    if not camera or not camera.perspective or not camera.worldToScreen then return entry.angle end
    local reach=64;local x1,y1=camera:worldToScreen(entry.x,entry.y)
    local x2,y2=camera:worldToScreen(entry.x+math.cos(entry.angle)*reach,entry.y+math.sin(entry.angle)*reach)
    return math.atan2 and math.atan2(y2-y1,x2-x1) or math.atan((y2-y1)/(x2-x1))
end

function Art.queue(mode,queue,camera)
    if #(mode.minerClawFx or {})==0 and #(mode.minerClawMarks or {})==0 then return end
    load()
    for _,value in ipairs(mode.minerClawMarks or {}) do
        local mark=value
        local angle=projectedAngle(mark,camera)
        queue[#queue+1]={x=mark.x,y=mark.y,anchorY=mark.y,draw=function()
            local previous={love.graphics.getColor()};local tier=tierFor(mark.level)
            love.graphics.setColor(.34,.25,.18,math.min(.86,mark.life/.8*.86)*.82)
            drawEntry(mark,quads[tier][5],angle);love.graphics.setColor(unpack(previous))
        end}
    end
    for _,value in ipairs(mode.minerClawFx or {}) do
        local fx=value
        local angle=projectedAngle(fx,camera)
        queue[#queue+1]={x=fx.x,y=fx.y+.01,anchorY=fx.y,draw=function()
            local previous={love.graphics.getColor()};local p=math.max(0,math.min(.999,1-fx.life/fx.maxLife))
            local frame=math.floor(p*5)+1;local tier=tierFor(fx.level)
            love.graphics.setColor(1,1,1,math.min(1,fx.life/.05));drawEntry(fx,quads[tier][frame],angle)
            love.graphics.setColor(unpack(previous))
        end}
    end
end

return Art
