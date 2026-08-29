-- Biome-authored floor dressing. Every map owns a distinct atlas, material
-- vocabulary and placement ecology; only projection/draw machinery is shared.
local Floor={}

local CELL_W,CELL_H,COLS=128,96,5
local catalogs={
    forest={file="assets/scenery/forest/forest-floor-decal-atlas-pixel-v1.png",
        kinds={soil=1,leaves=2,shortGrass=3,trampled=4,fern=5,branch=6,stones=7,moss=8,sawdust=9,drag=10},
        macro={"moss","trampled","soil","moss","leaves","trampled"},path={"soil","trampled"},edge={"stones","branch"},
        clearing={"trampled","soil"},active={"soil","leaves"},felled={"soil","sawdust","drag","trampled"}},
    beginner={file="assets/scenery/biomes/beginner-floor-decal-atlas-pixel-v1.png",
        kinds={meadow=1,clover=2,trimmed=3,flowers=4,bracken=5,cones=6,chalk=7,chips=8,sawdust=9,ruts=10},
        macro={"meadow","flowers","meadow","clover","trimmed","meadow"},path={"meadow","ruts"},edge={"chalk","cones"},
        clearing={"trimmed","meadow"},active={"clover","cones"},felled={"meadow","sawdust","ruts","chips"}},
    mangrove={file="assets/scenery/biomes/mangrove-floor-decal-atlas-pixel-v1.png",
        kinds={mud=1,puddle=2,roots=3,waxLeaves=4,sedge=5,fern=6,shells=7,burrows=8,wetChips=9,groove=10},
        macro={"mud","puddle","mud","puddle","waxLeaves","mud"},path={"mud","groove"},edge={"shells","roots"},
        clearing={"mud","puddle"},active={"mud","waxLeaves"},felled={"mud","wetChips","groove","waxLeaves"}},
    madagascar={file="assets/scenery/biomes/madagascar-floor-decal-atlas-pixel-v1.png",
        kinds={laterite=1,cracked=2,dryGrass=3,thorn=4,baobabLitter=5,pods=6,limestone=7,rosette=8,sawdust=9,groove=10},
        macro={"laterite","cracked","laterite","cracked","dryGrass","laterite"},path={"laterite","groove"},edge={"limestone","thorn"},
        clearing={"cracked","laterite"},active={"laterite","baobabLitter"},felled={"laterite","sawdust","groove","cracked"}},
    island={file="assets/scenery/biomes/island-floor-decal-atlas-pixel-v1.png",
        kinds={sand=1,coral=2,shells=3,beachGrass=4,vine=5,frond=6,husk=7,volcanic=8,fibre=9,sandDrag=10},
        macro={"sand","vine","sand","beachGrass","sand","vine"},path={"sand","sandDrag"},edge={"coral","husk"},
        clearing={"sand","vine"},active={"vine","frond"},felled={"sand","fibre","sandDrag","husk"}},
    greatforest={file="assets/scenery/biomes/greatforest-floor-decal-atlas-pixel-v1.png",
        kinds={rootMat=1,needles=2,deepMoss=3,mushrooms=4,bark=5,lichenStone=6,nurseLog=7,giantFern=8,paleSawdust=9,rootDrag=10},
        macro={"deepMoss","rootMat","needles","deepMoss","nurseLog","rootMat"},path={"needles","rootDrag"},edge={"lichenStone","bark"},
        clearing={"rootMat","deepMoss"},active={"needles","giantFern"},felled={"rootMat","paleSawdust","rootDrag","bark"}},
}
local art={}

local function catalogFor(id)return catalogs[id]or catalogs.forest end
local function ensureArt(id)
    id=catalogs[id]and id or"forest";if art[id]then return art[id]end
    local catalog=catalogs[id];local image=love.graphics.newImage(catalog.file);image:setFilter("nearest","nearest")
    local quads={};for index=1,10 do local zero=index-1;quads[index]=love.graphics.newQuad((zero%COLS)*CELL_W,math.floor(zero/COLS)*CELL_H,CELL_W,CELL_H,image:getDimensions())end
    art[id]={image=image,quads=quads};return art[id]
end
local function mapSeed(id)local seed=0;for index=1,#(id or"forest")do seed=(seed*131+(id or"forest"):byte(index))%2147483647 end;return seed end
local function valid(world,x,y)return require("src.clearcut_maps").canPlant(world,x,y)end

local function regionThemes(world,x,y)
    local id=world.clearcutMap or"forest"
    if id=="mangrove"then
        local bank=require("src.clearcut_maps").channelDistance(x,y,world.width,world.height)
        if bank<175 then return{{"puddle","roots","shells","burrows"},{"mud","sedge","waxLeaves"}}end
        return{{"sedge","fern","waxLeaves"},{"mud","roots","wetChips"}}
    elseif id=="madagascar"then
        local trail=math.abs(y-world.height*.48-math.sin(x/330)*145)
        if trail<230 then return{{"laterite","cracked","limestone"},{"pods","dryGrass","groove"}}end
        return{{"dryGrass","thorn","rosette"},{"cracked","baobabLitter","limestone"}}
    elseif id=="island"then
        local coast=require("src.clearcut_maps").islandDistance(x,y,world.width,world.height)
        if coast>.60 then return{{"sand","coral","shells","beachGrass"},{"frond","husk","sandDrag"}}end
        return{{"vine","frond","husk","volcanic"},{"beachGrass","vine","shells"}}
    elseif id=="beginner"then return{{"meadow","clover","flowers","trimmed"},{"bracken","cones","chalk","chips"}}end
    if id=="greatforest"then
        local ridge=math.sin(x/410)+math.cos(y/355)
        if ridge>.45 then return{{"rootMat","bark","nurseLog"},{"deepMoss","lichenStone","mushrooms"}}end
        return{{"needles","giantFern","bark"},{"deepMoss","mushrooms","lichenStone"}}
    end
    return{{"leaves","branch","shortGrass"},{"moss","fern","stones"},{"trampled","shortGrass","branch"},{"soil","stones","moss"}}
end

function Floor.generate(world,stage)
    local id=world.clearcutMap or"forest";local catalog=catalogFor(id)
    local data={macro={},decals={},stage=stage or 1,clusters=0,path=0,biome=id};world.forestFloor=data
    local seed=(48017+mapSeed(id)+(stage or 1)*17713)%2147483647
    local function random()seed=(seed*16807)%2147483647;return(seed-1)/2147483646 end
    local w,h=world.width,world.height
    local function add(list,kind,x,y,scale,angle,alpha,cluster)
        if not catalog.kinds[kind]or x<80 or x>w-80 or y<65 or y>h-65 or not valid(world,x,y)then return end
        list[#list+1]={kind=kind,x=x,y=y,scale=scale,angle=angle or 0,flip=random()<.5 and-1 or 1,alpha=alpha or 1,cluster=cluster}
    end
    for index,kind in ipairs(catalog.macro)do
        local x=w*(.13+((index*37)%83)/100*.74);local y=h*(.14+((index*61)%79)/100*.70)
        if(x-w*.5)^2+(y-h*.5)^2>270^2 then add(data.macro,kind,x,y,1.65+random()*.55,(random()-.5)*.65,.18+random()*.12,"macro")end
    end
    local pathStep=105
    for y=95,h-95,pathStep do
        local x=w*.5+math.sin(y/310+(stage or 1)*.62)*115
        add(data.macro,catalog.path[math.floor(y/pathStep)%4==0 and 1 or 2],x,y,1.08+random()*.18,(random()-.5)*.16,.36,"path");data.path=data.path+1
        if math.floor(y/pathStep)%2==0 then local side=random()<.5 and-1 or 1;add(data.decals,catalog.edge[random()<.5 and 1 or 2],x+side*(82+random()*34),y+22,.56+random()*.18,(random()-.5)*.8,.72,"pathEdge")end
    end
    for index=1,9 do local angle=index/9*math.pi*2;local radius=205+(index%3)*34;add(data.macro,catalog.clearing[index%3==0 and 2 or 1],w*.5+math.cos(angle)*radius,h*.5+math.sin(angle)*radius*.62,1.05+(index%2)*.25,angle*.18,.44,"clearing")end
    local gridX,gridY=id=="greatforest" and 9 or 5,id=="greatforest" and 6 or 3
    for gy=1,gridY do for gx=1,gridX do if random()<(id=="greatforest" and .78 or .64) then
        local cx=(gx-.5)/gridX*w+(random()-.5)*120;local cy=(gy-.5)/gridY*h+(random()-.5)*90;local centerDx,centerDy=cx-w*.5,cy-h*.5
        if centerDx*centerDx+centerDy*centerDy>235^2 then
            data.clusters=data.clusters+1;local themes=regionThemes(world,cx,cy);local theme=themes[1+math.floor(random()*#themes)];local count=6+math.floor(random()*6)
            for index=1,count do local angle=random()*math.pi*2;local radius=math.sqrt(random());local x=cx+math.cos(angle)*radius*(105+random()*70);local y=cy+math.sin(angle)*radius*(55+random()*45);add(data.decals,theme[1+math.floor(random()*#theme)],x,y,.48+random()*.46,(random()-.5)*.9,.58+random()*.30,"cluster"..data.clusters)end
        end
    end end end
    return data
end

local function readability(alpha,x,y,player,actorSource)
    local factor=1
    if player then local dx,dy=x-player.x,(y-player.y)*1.25;local distance=math.sqrt(dx*dx+dy*dy);if distance<150 then factor=math.min(factor,.18+.82*distance/150)end end
    for _,enemy in ipairs(actorSource and actorSource.enemies or{})do local dx,dy=x-enemy.x,(y-enemy.y)*1.25;local distance=math.sqrt(dx*dx+dy*dy);if distance<92 then factor=math.min(factor,.35+.65*distance/92)end end
    return alpha*factor
end
local function drawDecal(catalog,render,prop,player,actorSource,alphaOverride)
    local alpha=readability(alphaOverride or prop.alpha,prop.x,prop.y,player,actorSource);if alpha<.025 then return end
    love.graphics.setColor(1,1,1,alpha);love.graphics.draw(render.image,render.quads[catalog.kinds[prop.kind]],prop.x,prop.y,prop.angle,prop.scale*prop.flip,prop.scale,CELL_W*.5,CELL_H*.5)
end
local function drawTreeEvidence(world,catalog,render,player,actorSource)
    for index,node in ipairs(world.nodes or{})do if node.rushTree then
        local base={x=node.x,y=node.y,angle=0,flip=index%2==0 and-1 or 1}
        if node.active then
            if index%3==0 then base.kind,base.scale,base.alpha=catalog.active[1],.62,.28;drawDecal(catalog,render,base,player,actorSource)end
            if index%4==0 then base.kind,base.scale,base.angle,base.alpha=catalog.active[2],.55,(index%5-2)*.12,.48;drawDecal(catalog,render,base,player,actorSource)end
        else
            love.graphics.setColor(0,0,0,node.giantTree and .24 or .18);love.graphics.ellipse("fill",node.x+3,node.y+6,node.giantTree and 38 or 26,node.giantTree and 11 or 8)
            base.kind,base.scale,base.alpha=catalog.felled[1],.94,.78;drawDecal(catalog,render,base,player,actorSource)
            base.kind,base.scale,base.angle,base.alpha=catalog.felled[2],.72,(index%5-2)*.12,.92;drawDecal(catalog,render,base,player,actorSource)
            local direction=node.fallDir or(index%2==0 and-1 or 1)
            base.kind,base.x,base.y,base.scale,base.angle,base.alpha=catalog.felled[3],node.x+direction*66,node.y+10,.82,direction<0 and math.pi or 0,.64;drawDecal(catalog,render,base,player,actorSource)
            base.kind,base.x,base.y,base.scale,base.alpha=catalog.felled[4],node.x-direction*24,node.y+18,.60,.72;drawDecal(catalog,render,base,player,actorSource)
        end
    end end
end
function Floor.drawGround(world,player,actorSource)
    local data=world and world.forestFloor;if not data then return end
    local catalog=catalogFor(data.biome);local render=ensureArt(data.biome)
    for _,prop in ipairs(data.macro)do drawDecal(catalog,render,prop,player,actorSource)end
    for _,prop in ipairs(data.decals)do drawDecal(catalog,render,prop,player,actorSource)end
    drawTreeEvidence(world,catalog,render,player,actorSource);love.graphics.setColor(1,1,1,1)
end
return Floor
