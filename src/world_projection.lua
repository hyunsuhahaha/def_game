-- Unified pseudo-perspective for the playable world.
-- Simulation stays in world coordinates; the complete world render is warped
-- through this one projection so terrain, spacing, sprites and FX cannot drift
-- into separate visual coordinate systems.
local Projection={rows=56,overscanX=.38,overscanY=.38,horizonRatio=.285}
local cache={}

local function clamp(value,low,high)
    return math.max(low,math.min(high,value))
end

function Projection.factor(flatY,height,pitch)
    -- The ordinary 2.5D camera is intentionally affine. A depth-dependent
    -- scale made every root, decal and floor texel grow and shrink as it moved
    -- vertically across the screen, which read as a rippling floor. Strong
    -- convergence belongs to the explicit skyview presentation mode only.
    return 1
end

local function skyProject(flatX,flatY,width,height)
    local u=clamp(flatY/height,0,1.8)
    local curve=u^1.22
    local scale=.34+1.0*curve
    local x=width*.5+(flatX-width*.5)*scale
    local y=height*Projection.horizonRatio+height*(1-Projection.horizonRatio)*curve
    return x,y,scale
end

function Projection.project(flatX,flatY,width,height,pitch,skyviewBlend)
    pitch=pitch or .76
    local perspective=Projection.factor(flatY,height,pitch)
    local baseX=flatX
    local baseY=height*.5+(flatY-height*.5)*pitch
    local blend=clamp(skyviewBlend or 0,0,1)
    if blend<=0 then return baseX,baseY,perspective end
    local skyX,skyY,skyScale=skyProject(flatX,flatY,width,height)
    return baseX+(skyX-baseX)*blend,baseY+(skyY-baseY)*blend,
        perspective+(skyScale-perspective)*blend
end

function Projection.unproject(screenX,screenY,width,height,pitch,skyviewBlend)
    pitch=pitch or .76
    local blend=clamp(skyviewBlend or 0,0,1)
    if blend<=0 and screenX==width*.5 and screenY==height*.5 then
        return width*.5,height*.5,Projection.factor(height*.5,height,pitch)
    end
    -- Projected Y is monotonic. A fixed binary solve keeps input and rendering
    -- on the exact same curve, including the clamped far/near scale regions.
    local low,high=-height*1.5,height*2.5
    for _=1,30 do
        local middle=(low+high)*.5
        local _,projectedY=Projection.project(width*.5,middle,width,height,pitch,blend)
        if projectedY<screenY then low=middle else high=middle end
    end
    local flatY=(low+high)*.5
    local centerX=Projection.project(width*.5,flatY,width,height,pitch,blend)
    local unitX=Projection.project(width*.5+1,flatY,width,height,pitch,blend)
    local perspective=unitX-centerX
    local flatX=width*.5+(screenX-width*.5)/perspective
    return flatX,flatY,perspective
end

local function vertex(canvasX,canvasY,width,height,padX,padY,canvasW,canvasH,pitch,skyviewBlend)
    local x,y=Projection.project(canvasX-padX,canvasY-padY,width,height,pitch,skyviewBlend)
    return {x,y,canvasX/canvasW,canvasY/canvasH,1,1,1,1}
end

local function meshVertices(width,height,pitch,skyviewBlend,padX,padY,canvasW,canvasH)
    local vertices={}
    for row=0,Projection.rows-1 do
        local y0=canvasH*row/Projection.rows
        local y1=canvasH*(row+1)/Projection.rows
        local a=vertex(0,y0,width,height,padX,padY,canvasW,canvasH,pitch,skyviewBlend)
        local b=vertex(canvasW,y0,width,height,padX,padY,canvasW,canvasH,pitch,skyviewBlend)
        local c=vertex(canvasW,y1,width,height,padX,padY,canvasW,canvasH,pitch,skyviewBlend)
        local d=vertex(0,y1,width,height,padX,padY,canvasW,canvasH,pitch,skyviewBlend)
        vertices[#vertices+1]=a;vertices[#vertices+1]=b;vertices[#vertices+1]=c
        vertices[#vertices+1]=a;vertices[#vertices+1]=c;vertices[#vertices+1]=d
    end
    return vertices
end

local function rebuild(width,height,pitch,skyviewBlend,skyPad)
    -- The low skyview camera narrows distant X spacing strongly. Supply a
    -- wider source canvas only while that mode is visible so the projected
    -- ground still reaches both screen edges below the horizon.
    local padX=math.ceil(width*(Projection.overscanX+(skyPad and .76 or 0)))
    local padY=math.ceil(height*Projection.overscanY)
    local canvasW,canvasH=width+padX*2,height+padY*2
    local canvas=love.graphics.newCanvas(canvasW,canvasH,{format="rgba8",dpiscale=1})
    -- The ground is continuously minified by the pseudo-perspective mesh.
    -- Nearest minification chooses a different source texel at every tiny
    -- camera step, making grass and floor decals crawl. Bilinear minification
    -- plus anisotropy stabilizes that oblique surface; magnification remains
    -- nearest so foreground pixel clusters stay crisp. Upright billboards are
    -- rendered after this canvas and retain their own nearest filters.
    canvas:setFilter("linear","nearest",8)
    local vertices=meshVertices(width,height,pitch,skyviewBlend,padX,padY,canvasW,canvasH)
    local mesh=love.graphics.newMesh(vertices,"triangles","dynamic")
    mesh:setTexture(canvas)
    cache={width=width,height=height,pitch=pitch,skyviewBlend=skyviewBlend,skyPad=skyPad,padX=padX,padY=padY,
        canvasW=canvasW,canvasH=canvasH,canvas=canvas,mesh=mesh}
end

function Projection.begin(camera)
    local width,height=love.graphics.getDimensions()
    local pitch=camera.pitch or .76
    local skyviewBlend=math.floor(clamp(camera.skyviewBlend or 0,0,1)*48+.5)/48
    local skyPad=skyviewBlend>0
    if not cache.canvas or cache.width~=width or cache.height~=height or cache.pitch~=pitch or cache.skyPad~=skyPad then
        rebuild(width,height,pitch,skyviewBlend,skyPad)
    elseif cache.skyviewBlend~=skyviewBlend then
        cache.mesh:setVertices(meshVertices(width,height,pitch,skyviewBlend,cache.padX,cache.padY,cache.canvasW,cache.canvasH))
        cache.skyviewBlend=skyviewBlend
    end
    cache.previousCanvas=love.graphics.getCanvas()
    love.graphics.setCanvas({cache.canvas,stencil=true})
    -- Keep the canvas transparent outside authored terrain. This allows the
    -- north panorama to show through without turning it into simulated ground.
    love.graphics.clear(0,0,0,0)
    return cache.canvasW,cache.canvasH
end

function Projection.finish(camera)
    love.graphics.setCanvas(cache.previousCanvas)
    love.graphics.push("all")
    love.graphics.setBlendMode("alpha","premultiplied")
    love.graphics.setColor(1,1,1,1)
    local blend=clamp(camera and camera.skyviewBlend or cache.skyviewBlend or 0,0,1)
    if blend>0 then
        local top=math.floor(cache.height*Projection.horizonRatio*blend)
        love.graphics.setScissor(0,top,cache.width,cache.height-top)
    end
    love.graphics.draw(cache.mesh)
    love.graphics.pop()
end

function Projection.drawBillboards(queue,camera)
    if not queue then return end
    local zoom=camera.renderZoom or camera.zoom
    for _,item in ipairs(queue) do
        local anchorY=item.anchorY or item.y
        local screenX,screenY,screenScale=camera:worldToScreen(item.x,anchorY)
        -- Nearest-filtered upright sprites shimmer when their foot anchor
        -- repeatedly crosses fractional screen pixels. Keep exact Y for depth
        -- ordering, but rasterize the billboard anchor on the integer grid.
        item.screenX,item.screenY=math.floor(screenX+.5),math.floor(screenY+.5)
        item.screenScale=screenScale
        item.screenSort=(math.abs(item.y)>50000 and item.y or screenY)+(item.sortBias or 0)
    end
    table.sort(queue,function(a,b) return a.screenSort<b.screenSort end)
    love.graphics.setBlendMode("alpha")
    for _,item in ipairs(queue) do
        local uniform=zoom*item.screenScale
        love.graphics.push()
        love.graphics.translate(item.screenX,item.screenY)
        -- Vertical sprites are billboards: ground position receives pitch,
        -- their pixels receive one uniform perspective scale on both axes.
        love.graphics.scale(uniform,uniform)
        love.graphics.translate(-item.x,-(item.anchorY or item.y))
        item.draw()
        love.graphics.pop()
    end
end

return Projection
