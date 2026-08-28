-- Screen-edge canopy layer. The ground and depth-sorted actors are the back
-- and middle planes; this near plane reacts more strongly to camera inertia.
local Art={}

function Art.drawFront(game)
    local camera,world=game.camera,game.world
    local variants=world and world.images and world.images.treeVariants
    if not camera or not variants or #variants==0 then return end
    local w,h=love.graphics.getDimensions()
    local motion=math.min(1,(math.abs(camera.inertiaX or 0)+math.abs(camera.inertiaY or 0))/20+(camera.cinematic and .58 or .08))
    local alpha=.10+motion*.17
    local driftX=-(camera.inertiaX or 0)*2.2
    local driftY=-(camera.inertiaY or 0)*1.7
    love.graphics.push("all")
    love.graphics.setScissor(0,math.floor(h*.68),w,math.ceil(h*.32))
    for i,side in ipairs({-1,1}) do
        local sprite=variants[(i-1)%#variants+1]
        local scale=(h*.57)/sprite:getHeight()
        local x=side<0 and -sprite:getWidth()*scale*.09 or w+sprite:getWidth()*scale*.09
        x=x+driftX*(side<0 and 1.16 or .84)
        love.graphics.setColor(.72,.82,.66,alpha)
        love.graphics.draw(sprite,x,h+sprite:getHeight()*scale*.17+driftY,(camera.roll or 0)*-2.4,
            scale*side,scale,sprite:getWidth()/2,sprite:getHeight())
    end
    love.graphics.setScissor()
    love.graphics.pop()
end

return Art
