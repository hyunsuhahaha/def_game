-- Score-mode axe equipment and its authored drum-contact animation.
-- Damage remains in clearcut_mode; this module only owns cached pixels/timing.
local Art={}
local axe,impact,impactQuads
local AXE_W,AXE_H=160,160
local IMPACT_W,IMPACT_H,IMPACT_FRAMES=192,160,6

local function load()
    if axe then return end
    axe=love.graphics.newImage("assets/fx/supplement/axe-atlas-v1.png")
    impact=love.graphics.newImage("assets/fx/oil-drum-axe-hit-atlas-pixel-v1.png")
    axe:setFilter("nearest","nearest");impact:setFilter("nearest","nearest")
    impactQuads={}
    for frame=0,IMPACT_FRAMES-1 do
        impactQuads[frame+1]=love.graphics.newQuad(frame*IMPACT_W,0,IMPACT_W,IMPACT_H,impact:getDimensions())
    end
end

function Art.load()load();return true end

local function smoothstep(value)return value*value*(3-2*value)end

-- The source axe runs from the authored handle pivot (27,133) toward the
-- blade at roughly -45 degrees. Rotate around that hand contact instead of
-- orbiting a centered icon, so the blade actually crosses the target point.
function Art.drawHeld(mode,game)
    load()
    local player=game.player
    local facing=player.facing or 1
    local action=mode.scoreAxeAction
    local progress=action and math.max(0,math.min(1,(action.elapsed or 0)/(action.duration or .42)))or nil
    local desired
    if progress then
        if progress<.22 then
            local p=smoothstep(progress/.22);desired=-.48+(-1.72+.48)*p
        elseif progress<.56 then
            local p=smoothstep((progress-.22)/.34);desired=-1.72+( .16+1.72)*p
        elseif progress<.68 then desired=.16
        else
            local p=smoothstep((progress-.68)/.32);desired=.16+(-.48-.16)*p
        end
    else desired=-.48 end
    if facing<0 then desired=math.pi-desired end
    local native=facing>0 and-.78 or(-math.pi+.78)
    local rotation=desired-native
    local scale=.39
    local handX=player.x+facing*18
    local handY=player.y-68
    local contactPunch=progress and progress>=.48 and progress<=.68 and 2 or 0
    love.graphics.setColor(0,0,0,.18)
    love.graphics.ellipse("fill",handX+facing*19,handY+47,20,5)
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(axe,math.floor(handX+facing*contactPunch+.5),math.floor(handY+.5),rotation,
        scale*facing,scale,27,133)
end

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
