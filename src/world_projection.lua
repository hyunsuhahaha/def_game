-- Unified pseudo-perspective for the playable world.
-- Simulation stays in world coordinates; the complete world render is warped
-- through this one projection so terrain, spacing, sprites and FX cannot drift
-- into separate visual coordinate systems.
local Projection={nearScale=.78,farScale=1.12,rows=56,overscanX=.38,overscanY=.38}
local cache={}

local function clamp(value,low,high)
    return math.max(low,math.min(high,value))
end

function Projection.factor(flatY,height,pitch)
    pitch=pitch or .76
    local groundY=height*.5+(flatY-height*.5)*pitch
    local depth=clamp(groundY/height,0,1)
    return Projection.nearScale+(Projection.farScale-Projection.nearScale)*depth
end

function Projection.project(flatX,flatY,width,height,pitch)
    pitch=pitch or .76
    local perspective=Projection.factor(flatY,height,pitch)
    local x=width*.5+(flatX-width*.5)*perspective
    local y=height*.5+(flatY-height*.5)*pitch*perspective
    return x,y,perspective
end

function Projection.unproject(screenX,screenY,width,height,pitch)
    pitch=pitch or .76
    if screenX==width*.5 and screenY==height*.5 then
        return width*.5,height*.5,Projection.factor(height*.5,height,pitch)
    end
    -- Projected Y is monotonic. A fixed binary solve keeps input and rendering
    -- on the exact same curve, including the clamped far/near scale regions.
    local low,high=-height*1.5,height*2.5
    for _=1,30 do
        local middle=(low+high)*.5
        local _,projectedY=Projection.project(width*.5,middle,width,height,pitch)
        if projectedY<screenY then low=middle else high=middle end
    end
    local flatY=(low+high)*.5
    local perspective=Projection.factor(flatY,height,pitch)
    local flatX=width*.5+(screenX-width*.5)/perspective
    return flatX,flatY,perspective
end

local function vertex(canvasX,canvasY,width,height,padX,padY,canvasW,canvasH,pitch)
    local x,y=Projection.project(canvasX-padX,canvasY-padY,width,height,pitch)
    return {x,y,canvasX/canvasW,canvasY/canvasH,1,1,1,1}
end

local function rebuild(width,height,pitch)
    local padX=math.ceil(width*Projection.overscanX)
    local padY=math.ceil(height*Projection.overscanY)
    local canvasW,canvasH=width+padX*2,height+padY*2
    local canvas=love.graphics.newCanvas(canvasW,canvasH,{format="rgba8",dpiscale=1})
    canvas:setFilter("nearest","nearest")
    local vertices={}
    for row=0,Projection.rows-1 do
        local y0=canvasH*row/Projection.rows
        local y1=canvasH*(row+1)/Projection.rows
        local a=vertex(0,y0,width,height,padX,padY,canvasW,canvasH,pitch)
        local b=vertex(canvasW,y0,width,height,padX,padY,canvasW,canvasH,pitch)
        local c=vertex(canvasW,y1,width,height,padX,padY,canvasW,canvasH,pitch)
        local d=vertex(0,y1,width,height,padX,padY,canvasW,canvasH,pitch)
        vertices[#vertices+1]=a;vertices[#vertices+1]=b;vertices[#vertices+1]=c
        vertices[#vertices+1]=a;vertices[#vertices+1]=c;vertices[#vertices+1]=d
    end
    local mesh=love.graphics.newMesh(vertices,"triangles","static")
    mesh:setTexture(canvas)
    cache={width=width,height=height,pitch=pitch,padX=padX,padY=padY,
        canvasW=canvasW,canvasH=canvasH,canvas=canvas,mesh=mesh}
end

function Projection.begin(camera)
    local width,height=love.graphics.getDimensions()
    local pitch=camera.pitch or .76
    if not cache.canvas or cache.width~=width or cache.height~=height or cache.pitch~=pitch then
        rebuild(width,height,pitch)
    end
    cache.previousCanvas=love.graphics.getCanvas()
    love.graphics.setCanvas({cache.canvas,stencil=true})
    love.graphics.clear(.08,.11,.12,1)
    return cache.canvasW,cache.canvasH
end

function Projection.finish()
    love.graphics.setCanvas(cache.previousCanvas)
    love.graphics.push("all")
    love.graphics.setBlendMode("alpha","premultiplied")
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(cache.mesh)
    love.graphics.pop()
end

return Projection
