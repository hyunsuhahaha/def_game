-- Layered forest-floor dressing. All marks are visual-only ground decals:
-- no collision, targeting, harvest count or combat RNG is touched.
local Floor={}

local CELL_W,CELL_H,COLS=128,96,5
local kinds={soil=1,leaves=2,shortGrass=3,trampled=4,fern=5,
    branch=6,stones=7,moss=8,sawdust=9,drag=10}
local image,quads

local function ensureArt()
    if image then return end
    image=love.graphics.newImage("assets/scenery/forest/forest-floor-decal-atlas-pixel-v1.png")
    image:setFilter("nearest","nearest")
    quads={}
    for index=1,10 do
        local zero=index-1
        quads[index]=love.graphics.newQuad((zero%COLS)*CELL_W,math.floor(zero/COLS)*CELL_H,
            CELL_W,CELL_H,image:getDimensions())
    end
end

local function mapSeed(id)
    local seed=0
    for index=1,#(id or "forest") do seed=(seed*131+(id or "forest"):byte(index))%2147483647 end
    return seed
end

local function valid(world,x,y)
    return require("src.clearcut_maps").canPlant(world,x,y)
end

function Floor.generate(world,stage)
    local data={macro={},decals={},stage=stage or 1,clusters=0,path=0}
    world.forestFloor=data
    local seed=(48017+mapSeed(world.clearcutMap)+(stage or 1)*17713)%2147483647
    local function random()
        seed=(seed*16807)%2147483647
        return (seed-1)/2147483646
    end
    local w,h=world.width,world.height
    local function add(list,kind,x,y,scale,angle,alpha,cluster)
        if x<80 or x>w-80 or y<65 or y>h-65 or not valid(world,x,y) then return end
        list[#list+1]={kind=kind,x=x,y=y,scale=scale,angle=angle or 0,
            flip=random()<.5 and -1 or 1,alpha=alpha or 1,cluster=cluster}
    end

    -- Three broad material masses stop the map reading as one green sheet.
    local macroThemes={"moss","trampled","soil","moss","leaves","trampled"}
    for index,kind in ipairs(macroThemes) do
        local x=w*(.13+((index*37)%83)/100*.74)
        local y=h*(.14+((index*61)%79)/100*.70)
        if (x-w*.5)^2+(y-h*.5)^2>270^2 then
            add(data.macro,kind,x,y,1.65+random()*.55,(random()-.5)*.65,.18+random()*.12,"macro")
        end
    end

    -- A worn logging route crosses the whole playable area, bends around the
    -- arrival clearing, and creates a deliberate long-distance eye line.
    local pathStep=105
    for y=95,h-95,pathStep do
        local x=w*.5+math.sin(y/310+(stage or 1)*.62)*115
        add(data.macro,(math.floor(y/pathStep)%4==0) and "soil" or "trampled",
            x,y,1.08+random()*.18,(random()-.5)*.16,.36,"path")
        data.path=data.path+1
        if math.floor(y/pathStep)%2==0 then
            local side=random()<.5 and -1 or 1
            add(data.decals,random()<.5 and "stones" or "branch",x+side*(82+random()*34),y+22,
                .56+random()*.18,(random()-.5)*.8,.72,"pathEdge")
        end
    end

    -- A quieter central felling clearing: broad wear at the rim, deliberately
    -- sparse in the exact player arrival/combat readability circle.
    for index=1,9 do
        local angle=index/9*math.pi*2
        local radius=205+(index%3)*34
        add(data.macro,index%3==0 and "soil" or "trampled",w*.5+math.cos(angle)*radius,
            h*.5+math.sin(angle)*radius*.62,1.05+(index%2)*.25,angle*.18,.44,"clearing")
    end

    -- Cluster cells are either dense or intentionally empty. Each chosen cell
    -- gets one material family rather than an even random sprinkle.
    local themes={
        {"leaves","branch","shortGrass"},{"moss","fern","stones"},
        {"trampled","shortGrass","branch"},{"soil","stones","moss"},
    }
    for gy=1,3 do
        for gx=1,5 do
            if random()<.64 then
                local cx=(gx-.5)/5*w+(random()-.5)*120
                local cy=(gy-.5)/3*h+(random()-.5)*90
                local centerDx,centerDy=cx-w*.5,cy-h*.5
                if centerDx*centerDx+centerDy*centerDy>235^2 then
                    data.clusters=data.clusters+1
                    local theme=themes[1+math.floor(random()*#themes)]
                    local count=6+math.floor(random()*6)
                    for index=1,count do
                        local angle=random()*math.pi*2
                        local radius=math.sqrt(random())
                        local x=cx+math.cos(angle)*radius*(105+random()*70)
                        local y=cy+math.sin(angle)*radius*(55+random()*45)
                        local kind=theme[1+math.floor(random()*#theme)]
                        add(data.decals,kind,x,y,.48+random()*.46,(random()-.5)*.9,
                            .58+random()*.30,"cluster"..data.clusters)
                    end
                end
            end
        end
    end
    return data
end

local function readability(alpha,x,y,player,actorSource)
    local factor=1
    if player then
        local dx,dy=x-player.x,(y-player.y)*1.25
        local distance=math.sqrt(dx*dx+dy*dy)
        if distance<150 then factor=math.min(factor,.18+.82*distance/150) end
    end
    for _,enemy in ipairs(actorSource and actorSource.enemies or {}) do
        local dx,dy=x-enemy.x,(y-enemy.y)*1.25
        local distance=math.sqrt(dx*dx+dy*dy)
        if distance<92 then factor=math.min(factor,.35+.65*distance/92) end
    end
    return alpha*factor
end

local function drawDecal(prop,player,actorSource,alphaOverride)
    local alpha=readability(alphaOverride or prop.alpha,prop.x,prop.y,player,actorSource)
    if alpha<.025 then return end
    love.graphics.setColor(1,1,1,alpha)
    love.graphics.draw(image,quads[kinds[prop.kind]],prop.x,prop.y,prop.angle,
        prop.scale*prop.flip,prop.scale,CELL_W*.5,CELL_H*.5)
end

local function drawTreeEvidence(world,player,actorSource)
    for index,node in ipairs(world.nodes or {}) do
        if node.rushTree then
            local base={x=node.x,y=node.y,angle=0,flip=index%2==0 and -1 or 1}
            if node.active then
                if index%3==0 then
                    base.kind,base.scale,base.alpha="soil",.62,.28
                    drawDecal(base,player,actorSource)
                end
                if index%4==0 then
                    base.kind,base.scale,base.angle,base.alpha="leaves",.55,(index%5-2)*.12,.48
                    drawDecal(base,player,actorSource)
                end
            else
                love.graphics.setColor(0,0,0,node.giantTree and .24 or .18)
                love.graphics.ellipse("fill",node.x+3,node.y+6,node.giantTree and 38 or 26,node.giantTree and 11 or 8)
                base.kind,base.scale,base.alpha="soil",.94,.78;drawDecal(base,player,actorSource)
                base.kind,base.scale,base.angle,base.alpha="sawdust",.72,(index%5-2)*.12,.92;drawDecal(base,player,actorSource)
                local direction=node.fallDir or (index%2==0 and -1 or 1)
                base.kind,base.x,base.y,base.scale,base.angle,base.alpha="drag",
                    node.x+direction*66,node.y+10,.82,direction<0 and math.pi or 0,.64
                drawDecal(base,player,actorSource)
                base.kind,base.x,base.y,base.scale,base.alpha="trampled",
                    node.x-direction*24,node.y+18,.60,.72
                drawDecal(base,player,actorSource)
            end
        end
    end
end

function Floor.drawGround(world,player,actorSource)
    local data=world and world.forestFloor
    if not data then return end
    ensureArt()
    for _,prop in ipairs(data.macro) do drawDecal(prop,player,actorSource) end
    for _,prop in ipairs(data.decals) do drawDecal(prop,player,actorSource) end
    drawTreeEvidence(world,player,actorSource)
    love.graphics.setColor(1,1,1,1)
end

return Floor
