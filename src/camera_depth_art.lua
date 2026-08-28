-- Screen-edge canopy layer. The ground and depth-sorted actors are the back
-- and middle planes; this near plane reacts more strongly to camera inertia.
local Art={}

function Art.drawFront(game)
    local camera,world=game.camera,game.world
    local variants=world and world.images and world.images.treeVariants
    if not camera or not variants or #variants==0 then return end
    local w,h=love.graphics.getDimensions()
    local motion=math.min(1,(math.abs(camera.inertiaX or 0)+math.abs(camera.inertiaY or 0))/20+(camera.cinematic and .58 or .08))
    local alpha=.18+motion*.22
    local driftX=-(camera.inertiaX or 0)*3.15
    local driftY=-(camera.inertiaY or 0)*2.35
    love.graphics.push("all")
    -- Near trunks and crowns cross the bottom edge at a stronger scale than
    -- gameplay trees, creating a readable foreground plane while remaining
    -- outside collision and target selection.
    love.graphics.setScissor(0,math.floor(h*.62),w,math.ceil(h*.38))
    for i,side in ipairs({-1,1}) do
        local sprite=variants[(i-1)%#variants+1]
        local scale=(h*.72)/sprite:getHeight()
        local x=side<0 and -sprite:getWidth()*scale*.09 or w+sprite:getWidth()*scale*.09
        x=x+driftX*(side<0 and 1.16 or .84)
        love.graphics.setColor(.66,.78,.59,alpha)
        love.graphics.draw(sprite,x,h+sprite:getHeight()*scale*.13+driftY,(camera.roll or 0)*-2.8,
            scale*side,scale,sprite:getWidth()/2,sprite:getHeight())
    end
    love.graphics.setScissor()

    -- A restrained overhead crown closes the third plane. It moves in the
    -- opposite direction to the camera target, which makes ordinary walking
    -- reveal depth without rotating the entire scene further.
    local crown=variants[1]
    local crownScale=(w*.34)/crown:getWidth()
    love.graphics.setScissor(0,0,w,math.ceil(h*.24))
    love.graphics.setColor(.48,.65,.43,alpha*.72)
    love.graphics.draw(crown,w*.18+driftX*1.35,-crown:getHeight()*crownScale*.42+driftY*.8,
        (camera.roll or 0)*-1.8,crownScale,crownScale,crown:getWidth()/2,crown:getHeight()/2)
    love.graphics.draw(crown,w*.82+driftX*.72,-crown:getHeight()*crownScale*.47+driftY*.55,
        (camera.roll or 0)*-1.5,-crownScale,crownScale,crown:getWidth()/2,crown:getHeight()/2)
    love.graphics.setScissor()
    love.graphics.pop()
end

return Art
