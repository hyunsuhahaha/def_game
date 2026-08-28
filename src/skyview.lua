-- Screen-space atmospheric layers for the render-only skyview camera mode.
-- The playable ground remains a projected world mesh; these layers only fill
-- the area above its horizon and never participate in simulation or collision.
local SkyView={horizonRatio=.285}
local layers

local function load()
    if layers then return layers end
    local root="assets/scenery/skyview/"
    layers={
        sky=love.graphics.newImage(root.."sky-clear-pixel-v1.png"),
        mountains=love.graphics.newImage(root.."horizon-mountains-pixel-v1.png"),
        forest=love.graphics.newImage(root.."horizon-forest-pixel-v1.png"),
        mist=love.graphics.newImage(root.."horizon-mist-pixel-v1.png"),
    }
    for _,image in pairs(layers) do image:setFilter("nearest","nearest") end
    return layers
end

local function coverWidth(image,width,bottom,alpha,parallax)
    local scale=width/image:getWidth()
    local height=image:getHeight()*scale
    local drift=(parallax or 0)*math.sin(love.timer.getTime()*.045)
    love.graphics.setColor(1,1,1,alpha)
    love.graphics.draw(image,math.floor(drift),math.floor(bottom-height),0,scale,scale)
end

function SkyView.draw(camera)
    local blend=camera and camera.skyviewBlend or 0
    if blend<=.001 then return end
    local art=load()
    local width,height=love.graphics.getDimensions()
    local horizon=height*SkyView.horizonRatio
    love.graphics.push("all")
    love.graphics.setBlendMode("alpha")
    -- The full sky is already a stepped pixel ramp. The lower layers overlap
    -- it at the same authored horizon, creating atmospheric depth without a
    -- flat color card behind the world.
    local skyScale=math.max(width/art.sky:getWidth(),(horizon+132)/art.sky:getHeight())
    local skyW=art.sky:getWidth()*skyScale
    love.graphics.setColor(1,1,1,blend)
    love.graphics.draw(art.sky,math.floor((width-skyW)*.5),0,0,skyScale,skyScale)
    coverWidth(art.mountains,width,horizon+7,blend*.96,-5)
    coverWidth(art.forest,width,horizon+9,blend,3)
    coverWidth(art.mist,width,horizon+31,blend*.82,-2)
    love.graphics.pop()
end

return SkyView
