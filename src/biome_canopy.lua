-- Screen-space foreground foliage. It frames the projected world after all
-- billboards, while the HUD remains cleanly readable above it.
local Canopy={}

local atlasW,atlasH=1024,256
local cache={}
local definitions={
    forest={alpha=.96,vines={.22,.46,.72,.86},phase=.1},
    beginner={alpha=.72,vines={.28,.74},phase=1.4},
    mangrove={alpha=.98,vines={.18,.39,.63,.82},phase=2.1},
    madagascar={alpha=.66,vines={.31,.70},phase=3.2},
    island={alpha=.98,vines={.16,.35,.61,.79,.91},phase=4.3},
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
    love.graphics.draw(art.image,art.tuft,w*.50-64*scale+math.sin(time*.18+def.phase)*16,0,0,scale,scale,0,0)
    for index,fraction in ipairs(def.vines)do
        local quad=index%2==0 and art.vineB or art.vineA
        local phase=def.phase+index*1.71
        local sway=math.sin(time*.72+phase)*.022+math.sin(time*.31+phase)*.009
        local y=-8*scale-(index%3)*7*scale
        love.graphics.draw(art.image,quad,w*fraction+math.sin(time*.24+phase)*7,y,sway,scale,scale,64,0)
    end
    love.graphics.pop()
end

return Canopy
