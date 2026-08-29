-- World-locked forest light and shade. These authored pixel patches are drawn
-- into the projected ground canvas, never as a screen overlay, so camera motion
-- cannot make them slide over the terrain or deform upright sprites.
local Lighting={}
local CELL,COLS=256,3
local art

local profiles={
    forest={shadow=11,sun=7,damp=4,shadowAlpha=.92,sunAlpha=.92,dampAlpha=.82,scale=1.00},
    beginner={shadow=5,sun=10,damp=2,shadowAlpha=.68,sunAlpha=1.00,dampAlpha=.58,scale=.94},
    mangrove={shadow=9,sun=5,damp=12,shadowAlpha=.88,sunAlpha=.74,dampAlpha=1.00,scale=1.05},
    madagascar={shadow=6,sun=12,damp=2,shadowAlpha=.68,sunAlpha=1.00,dampAlpha=.50,scale=1.00},
    island={shadow=7,sun=11,damp=3,shadowAlpha=.72,sunAlpha=1.00,dampAlpha=.60,scale=1.02},
}

local function ensureArt()
    if art then return art end
    local image=love.graphics.newImage("assets/scenery/forest/forest-light-patterns-pixel-v1.png")
    image:setFilter("nearest","nearest")
    local quads={}
    for row=0,2 do for col=0,COLS-1 do
        quads[row*COLS+col+1]=love.graphics.newQuad(col*CELL,row*CELL,CELL,CELL,image:getDimensions())
    end end
    art={image=image,quads=quads};return art
end

local function mapSeed(id)
    local seed=7369
    for index=1,#(id or "forest") do seed=(seed*131+(id or "forest"):byte(index))%2147483647 end
    return seed
end

function Lighting.generate(world,stage)
    local id=world.clearcutMap or "forest";local profile=profiles[id] or profiles.forest
    local seed=(mapSeed(id)+(stage or 1)*19001)%2147483647
    local function random() seed=(seed*16807)%2147483647;return(seed-1)/2147483646 end
    local data={biome=id,patches={}}
    local bounds=world.playBounds or{x=0,y=0,w=world.width,h=world.height}
    local Maps=require("src.clearcut_maps")
    local function add(kind,index,alpha)
        for attempt=1,18 do
            local x=bounds.x+110+random()*math.max(1,bounds.w-220)
            local y=bounds.y+90+random()*math.max(1,bounds.h-180)
            if Maps.canPlant(world,x,y) then
                local broad=.88+random()*.46
                data.patches[#data.patches+1]={kind=kind,x=x,y=y,variant=1+math.floor(random()*3),
                    sx=profile.scale*broad*(kind=="sun" and .74 or 1.0),
                    sy=profile.scale*(.64+random()*.24)*(kind=="damp" and 1.12 or 1),
                    angle=(random()-.5)*(kind=="sun" and .28 or .48),alpha=alpha,index=index}
                return
            end
        end
    end
    for i=1,profile.shadow do add("shadow",i,profile.shadowAlpha) end
    for i=1,profile.sun do add("sun",i,profile.sunAlpha) end
    for i=1,profile.damp do add("damp",i,profile.dampAlpha) end
    world.forestLighting=data
    return data
end

function Lighting.drawGround(world)
    local data=world and world.forestLighting;if not data then return end
    local render=ensureArt()
    local row={shadow=0,sun=1,damp=2}
    -- Stable ordering prevents brightness from changing between runs where
    -- translucent patches overlap. Positions, scale and alpha never animate.
    for _,patch in ipairs(data.patches) do
        local quad=render.quads[row[patch.kind]*COLS+patch.variant]
        love.graphics.setColor(1,1,1,patch.alpha)
        love.graphics.draw(render.image,quad,math.floor(patch.x+.5),math.floor(patch.y+.5),patch.angle,
            patch.sx,patch.sy,CELL*.5,CELL*.5)
    end
    love.graphics.setColor(1,1,1,1)
end

return Lighting
