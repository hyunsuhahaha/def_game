-- Stage 11+ score-attack field: dry, open upland with trees in broad groves.
local Upland={START_TIER=11}
local shader,image

local groves={
    {.22,.24,.19,.16},{.78,.22,.20,.19},
    {.15,.76,.23,.20},{.79,.78,.25,.18},{.51,.53,.20,.16},
}

function Upland.isTreeZone(world,x,y)
    local w,h=world.width,world.height
    local nx,ny=x/w,y/h
    if x<105 or x>w-105 or y<145 or y>h-115 then return false end
    -- Two wide, bent haul roads meet in the crane yard. They are continuous
    -- openings, not arbitrary holes punched between tiny tree islands.
    if ((nx-.5)/.045)^2+((ny-.5)/.065)^2<1 then return false end
    for index,g in ipairs(groves)do
        local dx=(nx-g[1])/g[3];local dy=(ny-g[2])/g[4]
        local edge=dx*dx+dy*dy+math.sin(nx*31+index)*.09+math.sin(ny*27-index)*.07
        if edge<1 then return true end
    end
    return false
end

local function random(seed)
    seed=(seed*16807)%2147483647
    return seed,(seed-1)/2147483646
end

function Upland.sampleTree(world,index,attempt)
    local seed=(7919+(index or 1)*104729+(attempt or 1)*1543)%2147483647
    local r
    local grove=groves[1+(math.floor(((index or 1)-1)/18)+math.floor(((attempt or 1)-1)/30))%#groves]
    seed,r=random(seed);local angle=r*math.pi*2
    -- Keep every generated target inside the body of a grove. The looser
    -- outer silhouette remains available for later growth without producing
    -- isolated trees between the six main woodland masses.
    seed,r=random(seed);local radius=math.sqrt(r)*math.min(.80,260/(world.width*grove[3]))
    local x=world.width*(grove[1]+math.cos(angle)*grove[3]*radius)
    local y=world.height*(grove[2]+math.sin(angle)*grove[4]*radius)
    return x,y
end

function Upland.clusterTrees(world,nodes)
    local placed={}
    for index,node in ipairs(nodes or{})do
        if node.rushTree and node.active and not node.giantTree then
            for attempt=1,180 do
                local x,y=Upland.sampleTree(world,index,attempt)
                local clear=Upland.isTreeZone(world,x,y)
                if clear then
                    for _,p in ipairs(placed)do
                        if (p.x-x)^2+(p.y-y)^2<54^2 then clear=false;break end
                    end
                end
                if clear then node.x,node.y=x,y;placed[#placed+1]={x=x,y=y};break end
            end
        end
    end
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
