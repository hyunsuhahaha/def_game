-- Screen-space foreground foliage. It frames the projected world after all
-- billboards, while the HUD remains cleanly readable above it.
local Canopy={}

local atlasW,atlasH=1024,256
local cache={}
local definitions={
    forest={alpha=.88,vineAlpha=.46,vineScale=.68,vines={.07,.93},tuftAlpha=.38,phase=.1},
    beginner={alpha=.66,vineAlpha=.30,vineScale=.58,vines={.08},tuftAlpha=.28,phase=1.4},
    mangrove={alpha=.90,vineAlpha=.50,vineScale=.70,vines={.065,.935},tuftAlpha=.34,phase=2.1},
    madagascar={alpha=.62,vineAlpha=.28,vineScale=.58,vines={.08},tuftAlpha=.24,phase=3.2},
    island={alpha=.90,vineAlpha=.44,vineScale=.68,vines={.06,.94},tuftAlpha=.32,phase=4.3},
}

local function ensure(id)
    id=definitions[id]and id or"forest"
    if cache[id]then return cache[id]end
    local image=love.graphics.newImage("assets/scenery/canopy/"..id.."-foreground-canopy-atlas-pixel-v1.png")
    image:setFilter("nearest","nearest")
    local result={image=image,
        left=love.graphics.newQuad(0,0,320,256,atlasW,atlasH),
        right=love.graphics.newQuad(320,0,320,256,atlasW,atlasH),
        vineA=love.graphics.newQuad(640,0,128,256,atlasW,atlasH),
        vineB=love.graphics.newQuad(768,0,128,256,atlasW,atlasH),
        tuft=love.graphics.newQuad(896,0,128,256,atlasW,atlasH)}
    cache[id]=result
    return result
end

function Canopy.draw(world,camera,time)
    if not world or not world.clearcutMap then return end
    local id=definitions[world.clearcutMap]and world.clearcutMap or"forest"
    local def,art=definitions[id],ensure(id)
    local w,h=love.graphics.getDimensions()
    local scale=math.max(.78,math.min(1.18,h/720))
    local parallax=((camera and camera.renderX or camera and camera.x or 0)*.018)%(46*scale)
    love.graphics.push("all")
    love.graphics.setColor(1,1,1,def.alpha)
    love.graphics.draw(art.image,art.left,-20*scale-parallax,0,0,scale,scale)
    love.graphics.draw(art.image,art.right,w-300*scale+parallax,0,0,scale,scale)
    local tuftScale=scale*.68
    love.graphics.setColor(1,1,1,def.alpha*def.tuftAlpha)
    love.graphics.draw(art.image,art.tuft,w*.50-64*tuftScale+math.sin(time*.18+def.phase)*8,0,0,tuftScale,tuftScale,0,0)
    love.graphics.setColor(1,1,1,def.alpha*def.vineAlpha)
    for index,fraction in ipairs(def.vines)do
        local quad=index%2==0 and art.vineB or art.vineA
        local phase=def.phase+index*1.71
        local vineScale=scale*def.vineScale
        local sway=math.sin(time*.58+phase)*.012+math.sin(time*.27+phase)*.004
        local y=-10*vineScale-(index%2)*5*vineScale
        love.graphics.draw(art.image,quad,w*fraction+math.sin(time*.20+phase)*3,y,sway,vineScale,vineScale,64,0)
    end
    love.graphics.pop()
end

return Canopy
