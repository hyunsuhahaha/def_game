-- Score-mode axe equipment and its authored drum-contact animation.
-- Damage remains in clearcut_mode; this module only owns cached pixels/timing.
local Art={}
local impact,impactQuads
local IMPACT_W,IMPACT_H,IMPACT_FRAMES=192,160,6

local function load()
    if impact then return end
    impact=love.graphics.newImage("assets/fx/oil-drum-axe-hit-atlas-pixel-v1.png")
    impact:setFilter("nearest","nearest")
    impactQuads={}
    for frame=0,IMPACT_FRAMES-1 do
        impactQuads[frame+1]=love.graphics.newQuad(frame*IMPACT_W,0,IMPACT_W,IMPACT_H,impact:getDimensions())
    end
end

function Art.load()load();return true end

function Art.impact(mode,x,y,facing)
    mode.scoreAxeImpacts=mode.scoreAxeImpacts or{}
    mode.scoreAxeImpacts[#mode.scoreAxeImpacts+1]={x=x,y=y,facing=facing or 1,age=0,life=.24}
end

function Art.update(mode,dt)
    for index=#(mode.scoreAxeImpacts or{}),1,-1 do
        local value=mode.scoreAxeImpacts[index]
        value.age=value.age+dt
        if value.age>=value.life then table.remove(mode.scoreAxeImpacts,index)end
    end
end

function Art.drawImpact(value)
    load()
    local progress=math.max(0,math.min(.999,(value.age or 0)/(value.life or .24)))
    local frame=math.floor(progress*IMPACT_FRAMES)+1
    local scale=.58
    love.graphics.setColor(1,1,1,1-progress*.18)
    love.graphics.draw(impact,impactQuads[frame],math.floor(value.x+.5),math.floor(value.y+.5),0,
        scale*(value.facing or 1),scale,91,84)
    love.graphics.setColor(1,1,1,1)
end

return Art
