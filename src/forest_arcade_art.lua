-- Approved small arcade silhouettes. Art transforms never change combat state.
local catalog = require("src.forest_arcade_catalog")
for kind,spec in pairs(require("src.biome_enemy_catalog")) do catalog[kind]=spec end
for kind,spec in pairs(require("src.attack_plant_catalog")) do catalog[kind]=spec end
for kind,spec in pairs(require("src.biome_boss_catalog")) do catalog[kind]=spec end
local Art = {}
local assets, material, prismImage, prismQuads
Art.SIEGE_GROUND_SINK=36

local function load()
    if assets then return end
    assets = {}
    material = love.graphics.newShader("assets/shaders/forest-arcade-light.glsl")
    prismImage=love.graphics.newImage("assets/enemies/arcade/regrowth-prism-rotation-atlas-v1.png")
    prismImage:setFilter("nearest","nearest")
    prismQuads={}
    for row=0,3 do
        prismQuads[row+1]={}
        for frame=0,23 do
            prismQuads[row+1][frame+1]=love.graphics.newQuad(frame*64,row*64,64,64,prismImage:getDimensions())
        end
    end
    for kind, spec in pairs(catalog) do
        local image = love.graphics.newImage(spec.file)
        image:setFilter("nearest", "nearest")
        local frames = {}
        for i = 0, 11 do
            frames[i+1] = love.graphics.newQuad((i%6)*spec.cell, math.floor(i/6)*spec.cell,
                spec.cell, spec.cell, image:getDimensions())
        end
        assets[kind] = {image=image,frames=frames}
    end
end

function Art.footY(e) return e.y + e.def.radius * .65 end

local function drawSiegeShadow(e,pose)
    -- Root contact, not a canopy-sized oval: broad soft ellipses made the
    -- massive tree read as a hovering billboard. These short lobes sit only
    -- under the weight-bearing root clusters.
    local y=pose.footY+7
    love.graphics.setColor(.055,.052,.024,.34*pose.alpha)
    love.graphics.ellipse("fill",e.x,y,185*pose.shadowScale,25*pose.shadowScale)
    love.graphics.setColor(.07,.062,.026,.27*pose.alpha)
    love.graphics.ellipse("fill",e.x-242*pose.shadowScale,y-3,134*pose.shadowScale,16*pose.shadowScale)
    love.graphics.ellipse("fill",e.x+245*pose.shadowScale,y-2,138*pose.shadowScale,17*pose.shadowScale)
end

local function drawSiegeSoilLip(e,pose)
    -- A small foreground soil lip hides the lowest root pixels, making the
    -- trunk look planted into the world instead of pasted on top of it.
    local x,y=e.x,pose.footY+8
    love.graphics.setColor(.20,.16,.065,.82*pose.alpha)
    love.graphics.rectangle("fill",x-148,y-3,300,12)
    love.graphics.rectangle("fill",x-102,y-10,210,8)
    love.graphics.rectangle("fill",x-28,y-14,62,5)
    love.graphics.setColor(.36,.28,.10,.66*pose.alpha)
    love.graphics.rectangle("fill",x-78,y-7,34,4);love.graphics.rectangle("fill",x+25,y-9,46,4)
    love.graphics.setColor(.10,.09,.035,.48*pose.alpha)
    love.graphics.rectangle("fill",x-42,y+7,52,4);love.graphics.rectangle("fill",x+54,y+5,29,3)
end

function Art.pose(e, t)
    local artKey=e.artKey or e.kind
    local spec = assert(catalog[artKey], "unknown forest art: " .. tostring(artKey))
    local clock = e.visualTime or t or 0
    local moving = e.moving and e.def.speed > 0
    local cycle = clock * (moving and 11 or 4) + (e.seed or 0)
    local frame = moving and (math.floor(cycle)%6+1) or (spec.motion==2 and math.floor(cycle*.65)%6+1 or 1)
    if spec.siege then
        local pct=math.max(0,e.hp)/math.max(1,e.maxHp)
        local stage=pct>.75 and 0 or (pct>.50 and 1 or (pct>.25 and 2 or 3))
        if e.worldTreeEmerging then
            local ep=math.max(0,math.min(1,e.worldTreeEmergenceProgress or 0))
            frame=1+(math.floor(ep*12)%3)
        else
            frame=stage*3+(math.floor(clock*2.2)%3)+1
        end
    end
    local recoil = math.min(1, (e.visualAttack or 0)/.24)
    if recoil > 0 and not spec.siege then frame = 10 + math.min(2, math.floor((1-recoil)*3)) end
    if e.plantState=="windup" then
        frame=7+math.min(2,math.floor((1-math.max(0,e.plantTimer)/(e.windupDuration or .62))*3))
    elseif e.plantState=="recover" then
        frame=10+math.min(2,math.floor((1-math.max(0,e.plantTimer)/(e.recoverDuration or .5))*3))
    elseif e.biomeState=="warn" then
        frame=7+math.min(2,math.floor((1-math.max(0,e.biomeTimer)/(e.warnDuration or .65))*3))
    elseif e.biomeState=="lunge" then
        frame=10+math.min(2,math.floor((1-math.max(0,e.biomeTimer)/e.lungeDuration)*3))
    elseif e.bossState=="warn" then
        frame=7+math.min(2,math.floor((1-math.max(0,e.bossTimer)/(e.bossWarnDuration or .9))*3))
    elseif e.bossState=="attack" or e.bossState=="recover" then
        frame=10+math.min(2,math.floor((e.bossActionFrame or 0)*3))
    end
    if e.reaperState == "charging" then frame=8 end
    -- The shrine body is intentionally stable. Its old six-frame idle cycle
    -- advanced at 2.6 fps and read as hitching; only the dedicated 24-frame
    -- centre prism rotates continuously now. Casting swaps once to a brighter
    -- authored body pose without pumping the entire silhouette every tick.
    if spec.prism then frame=e.planterCasting and 7 or 1 end
    local facing = e.facing or spec.facing
    local flip = (e.kind == "squirrel" or spec.biome or spec.directional) and facing/spec.facing or 1
    local scale = spec.width/spec.bodyWidth
    local bob = moving and math.abs(math.sin(cycle*math.pi/3))*1.3 or 0
    local lean = moving and math.sin(cycle*math.pi/3)*.025 or 0
    if spec.siege then bob,lean=0,0 end
    if e.reaperState == "dashing" then lean=-facing*.13 end
    local squash = spec.siege and 0 or recoil*.045
    local introX,introY=e.entranceOffsetX or 0,e.entranceOffsetY or 0
    local introSX,introSY=e.entranceScaleX or 1,e.entranceScaleY or 1
    local footY=Art.footY(e)
    local groundSink=spec.siege and Art.SIEGE_GROUND_SINK or 0
    local emergenceCutoff=1
    if spec.siege then
        local belowGround=groundSink+(e.entranceOffsetY or 0)
        emergenceCutoff=math.max(0,math.min(.999,spec.foot/spec.cell-belowGround/(spec.cell*scale*introSY)))
    end
    return {spec=spec,frame=frame,flip=flip,scale=scale,
        x=e.x+introX,y=footY+groundSink-bob-(e.hopHeight or 0)+introY,footY=footY,groundSink=groundSink,emergenceCutoff=emergenceCutoff,angle=lean,
        sx=scale*flip*(1+squash)*introSX,sy=scale*(1-squash)*introSY,height=spec.height*scale*introSY,
        alpha=e.entranceAlpha or 1,shadowScale=introSX}
end

local function drawPrism(e,pose,t)
    local spec=pose.spec
    if not spec.prism then return end
    local clock=e.visualTime or t or 0
    local fps=e.planterCasting and 24 or 20
    local frame=math.floor(clock*fps+(e.seed or 0)*2)%24+1
    local row=(spec.prismRow or 0)+1
    local scale=(spec.prismWidth or 22)/64*(e.planterCasting and 1.06 or 1)
    love.graphics.setColor(1,1,1,pose.alpha)
    love.graphics.draw(prismImage,prismQuads[row][frame],pose.x,pose.y-(spec.prismYOffset or 30),0,
        scale,scale,32,32)
end

function Art.drawBody(e, t)
    load()
    local pose=Art.pose(e,t)
    local kick=e.impactKick or 0
    if kick>0 then
        local p=1-math.min(1,kick/.10)
        pose.x=pose.x+(e.impactKickDir or 1)*math.sin(p*math.pi)*3
    end
    local asset=assets[e.artKey or e.kind]
    if pose.spec.siege then drawSiegeShadow(e,pose) else
        love.graphics.setColor(.08,.07,.035,.28*pose.alpha)
        love.graphics.ellipse("fill",e.x,pose.footY,pose.spec.width*.40*pose.shadowScale,math.max(3,pose.spec.width*.105*pose.shadowScale))
    end
    local previous=love.graphics.getShader()
    love.graphics.setShader(material)
    material:send("hurt",math.min(1,(e.visualHit or 0)/.14))
    material:send("elite",e.elite and 1 or 0)
    material:send("plague",e.plagueMarked and 1 or 0)
    material:send("emergenceCutoff",pose.emergenceCutoff or 1)
    local emergenceP=math.max(0,math.min(1,e.worldTreeEmergenceProgress or 0))
    material:send("emergenceWarp",e.worldTreeEmerging and math.sin(emergenceP*math.pi)*.026 or 0)
    material:send("emergencePhase",emergenceP*8.4)
    love.graphics.setColor(1,1,1,pose.alpha)
    love.graphics.draw(asset.image,asset.frames[pose.frame],pose.x,pose.y,pose.angle,
        pose.sx,pose.sy,pose.spec.cell/2,pose.spec.foot)
    love.graphics.setShader(previous)
    if pose.spec.siege then drawSiegeSoilLip(e,pose) end
    drawPrism(e,pose,t)
end

-- Draw a defeated enemy while another gameplay effect carries it. This keeps the
-- real enemy sprite/material instead of replacing the victim with a generic blob.
function Art.drawCarried(e, t, x, y, carryScale, angle)
    load()
    local originalX, originalY, originalMoving = e.x, e.y, e.moving
    e.x, e.y, e.moving = 0, 0, false
    local pose = Art.pose(e, t)
    local asset = assets[e.artKey or e.kind]
    local previous = love.graphics.getShader()
    love.graphics.push("all")
    love.graphics.translate(math.floor(x + .5), math.floor(y + .5))
    love.graphics.rotate(angle or 0)
    love.graphics.scale(carryScale or 1)
    love.graphics.setShader(material)
    material:send("hurt", 0)
    material:send("elite", e.elite and 1 or 0)
    material:send("plague", 0)
    material:send("emergenceCutoff",1)
    material:send("emergenceWarp",0)
    material:send("emergencePhase",0)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(asset.image, asset.frames[pose.frame], pose.x, pose.y, pose.angle,
        pose.sx, pose.sy, pose.spec.cell / 2, pose.spec.foot)
    love.graphics.setShader(previous)
    drawPrism(e,pose,t)
    love.graphics.pop()
    e.x, e.y, e.moving = originalX, originalY, originalMoving
end

function Art.drawSprout(x,y,grow,t)
    load()
    local spec=catalog.vineSprout
    local scale=spec.width/spec.bodyWidth*(.2+grow*.55)
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(assets.vineSprout.image,assets.vineSprout.frames[1],x,y,
        math.sin(t*8)*.03*(1-grow),scale,scale,spec.cell/2,spec.foot)
end

function Art.drawHealth(e,t)
    if e.worldTreeEmerging then return end
    local pose=Art.pose(e,t)
    local alpha=e.entranceAlpha or 1
    if alpha<=.05 then return end
    local w=math.max(e.def.radius*2.2,pose.spec.width*.85)
    local x,y=math.floor(e.x-w/2),math.floor(pose.y-pose.height-9)
    local pct=math.max(0,math.min(1,e.hp/e.maxHp))
    love.graphics.setColor(.14,.10,.07,.95*alpha); love.graphics.rectangle("fill",x-1,y-1,w+2,6)
    love.graphics.setColor(.9,.3,.19,alpha); love.graphics.rectangle("fill",x,y,math.floor(w*pct),4)
    love.graphics.setColor(1,.71,.45,.8*alpha); love.graphics.rectangle("fill",x,y,math.floor(w*pct),1)
end

return Art
