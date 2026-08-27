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

function Art.spawn(mode,x,y,angle,level,curveFlip,halfWidth,hand)
    mode.minerClawFx=mode.minerClawFx or {}
    mode.minerClawMarks=mode.minerClawMarks or {}
    halfWidth=halfWidth or defaultHalfWidth(level)
    local shared={x=x,y=y,angle=angle,level=level,curveFlip=curveFlip or 1,halfWidth=halfWidth,hand=hand or 1}
    mode.minerClawFx[#mode.minerClawFx+1]={x=shared.x,y=shared.y,angle=shared.angle,level=shared.level,
        curveFlip=shared.curveFlip,halfWidth=shared.halfWidth,hand=shared.hand,life=.22,maxLife=.22}
    mode.minerClawMarks[#mode.minerClawMarks+1]={x=shared.x,y=shared.y,angle=shared.angle,level=shared.level,
        curveFlip=shared.curveFlip,halfWidth=shared.halfWidth,hand=shared.hand,life=6,maxLife=6}
    if #mode.minerClawMarks>90 then table.remove(mode.minerClawMarks,1) end
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
        local scale=(mark.halfWidth or defaultHalfWidth(mark.level))/39
        love.graphics.setColor(.34,.25,.18,alpha*.82)
        love.graphics.draw(image,quads[tier][5],math.floor(mark.x+.5),math.floor(mark.y+.5),mark.angle,scale,scale*(mark.curveFlip or 1),96,64)
    end
    -- A very short contact animation reveals the same scratches at that point.
    for _,fx in ipairs(mode.minerClawFx or {}) do
        local p=math.max(0,math.min(.999,1-fx.life/fx.maxLife))
        local frame=math.floor(p*5)+1
        local tier=tierFor(fx.level)
        local scale=(fx.halfWidth or defaultHalfWidth(fx.level))/39
        love.graphics.setColor(1,1,1,math.min(1,fx.life/.05))
        love.graphics.draw(image,quads[tier][frame],math.floor(fx.x+.5),math.floor(fx.y+.5),fx.angle,scale,scale*(fx.curveFlip or 1),96,64)
    end
    love.graphics.setColor(unpack(previous))
end

return Art
