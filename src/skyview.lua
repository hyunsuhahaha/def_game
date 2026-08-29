-- Region-specific sunny panorama for the render-only SKYVIEW camera mode.
-- The playable ground remains a projected world mesh; this fills only the
-- atmosphere above its horizon and never participates in simulation.
local SkyView={horizonRatio=.285}
local images={}
local valid={forest=true,mangrove=true,madagascar=true,island=true}

local function load(id)
    id=valid[id] and id or "forest"
    if images[id] then return images[id] end
    local path="assets/scenery/skyview/"..id.."-sun-skyview-pixel-v2.png"
    local image=love.graphics.newImage(path)
    image:setFilter("nearest","nearest")
    images[id]=image
    return image
end

function SkyView.draw(camera,world)
    local blend=camera and camera.skyviewBlend or 0
    if blend<=.001 then return false end
    local image=load(world and world.clearcutMap or "forest")
    local width,height=love.graphics.getDimensions()
    local horizon=height*SkyView.horizonRatio
    -- The authored 2172x448 crop places the sun safely in the upper sky and
    -- the detailed biome horizon immediately behind the projected ground.
    -- Four percent horizontal overscan leaves room for the restrained camera
    -- parallax without exposing an empty strip at either edge.
    local scale=math.max(width/image:getWidth()*1.04,(horizon+52)/image:getHeight())
    local imageW=image:getWidth()*scale
    local x=(width-imageW)*.5
    local worldWidth=world and world.width or 0
    local drift=((camera and camera.renderX) or worldWidth*.5)-worldWidth*.5
    x=x-drift*.008
    love.graphics.push("all")
    love.graphics.setBlendMode("alpha")
    love.graphics.setScissor(0,0,width,math.ceil(horizon+54))
    love.graphics.setColor(1,1,1,blend)
    love.graphics.draw(image,math.floor(x),0,0,scale,scale)
    love.graphics.setScissor()
    love.graphics.pop()
    return true
end

return SkyView
