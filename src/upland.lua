-- Stage 11+ score-attack field: dry upland with growth across the whole field.
local Upland={START_TIER=11}
local shader,image

function Upland.isTreeZone(world,x,y)
    local b=world.playBounds or {x=0,y=0,w=world.width,h=world.height}
    return x>=b.x+110 and x<=b.x+b.w-110 and y>=b.y+145 and y<=b.y+b.h-115
end

function Upland.sampleTree(world,index,attempt)
    local b=world.playBounds or {x=0,y=0,w=world.width,h=world.height}
    -- Low-discrepancy coverage across the whole field, with small random
    -- offsets so consecutive growth neither piles up nor forms straight rows.
    local n=(index or 1)+((attempt or 1)-1)*97
    local u=(n*.754877666+(love.math.random()-.5)*.08)%1
    local v=(n*.569840291+(love.math.random()-.5)*.08)%1
    return b.x+110+u*(b.w-220),b.y+145+v*(b.h-260)
end

function Upland.configure(world,tier)
    if not world.uplandBaseSize then world.uplandBaseSize={w=world.width,h=world.height}end
    local base=world.uplandBaseSize
    world.width,world.height=base.w*2,base.h*2
    world.upland=true;world.lakeside=false;world.lakeOpening=nil;world.northBackdrop=false
    world.clearcutTier=tier
    local shore=require("src.lakeside").bounds({width=base.w,height=base.h},10)
    local growth=1-.82^math.max(0,tier-11)
    local w=shore.w*2+(world.width*.995-shore.w*2)*growth
    local h=shore.h*2+(world.height*.995-shore.h*2)*growth
    world.playBounds={x=(world.width-w)/2,y=(world.height-h)/2,w=w,h=h}
    world.cameraTopReveal=0
    world.cameraBounds={x=-world.width*.12,y=-world.height*.18,w=world.width*1.24,h=world.height*1.36}
    world.stageZoom=.68;world.overviewBounds=nil
end

function Upland.drawGround(world)
    if not world.upland then return false end
    if not shader then
        shader=love.graphics.newShader("assets/shaders/upland-ground-v2.glsl")
        image=love.graphics.newImage("assets/scenery/upland/upland-environment-pixel-v2.png")
        image:setFilter("nearest","nearest")
    end
    local old=love.graphics.getShader();local w,h=world.width,world.height
    local ox,oy,sw,sh=-w*2,-h*2,w*5,h*5
    local base=world.uplandBaseSize or {w=w,h=h}
    shader:send("worldSize",{base.w,base.h});shader:send("terrainOrigin",{ox,oy});shader:send("terrainSize",{sw,sh})
    love.graphics.setShader(shader);love.graphics.setColor(1,1,1,1)
    love.graphics.draw(image,ox,oy,0,sw/image:getWidth(),sh/image:getHeight())
    love.graphics.setShader(old)
    return true
end

return Upland
