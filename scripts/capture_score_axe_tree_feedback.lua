package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
love.graphics.rotate=love.graphics.rotate or function()end
love.graphics.getDimensions=function()return 320,360 end
love.graphics.getWidth=function()return 320 end
love.graphics.getHeight=function()return 360 end
love.keyboard={isDown=function()return false end}
love.mouse={getPosition=function()return 0,0 end,isDown=function()return false end}

local World=require("src.world")
local Player=require("src.player")
local ClearcutMode=require("src.clearcut_mode")
local walk=love.graphics.newImage("assets/characters/ingame/smoker-atlas-pixel-v2.png")
local dummy=love.graphics.newImage("assets/characters/ingame/smoker-atlas-pixel-v2.png")
local axe=love.graphics.newImage("assets/characters/ingame/smoker-score-axe-atlas-pixel-v4.png")
local cigarette=require("src.cigarette_sprite").load()
local sprite={image=walk,scoreAxeImage=axe,cigarette=cigarette,scale=.61,nativeFacing=1,
    walkFeet={190,190,190,190,190,190},actionFeet={190,190,190,190,190,190},
    walkMouth={{68,29},{73,29},{68,42},{74,29},{75,36},{73,29}},
    actionMouth={{34,30},{34,30},{31,29},{35,32},{65,32},{66,31}},
    scoreAxeFeet={222,222,222,222,222,222},scoreAxeBladeX=42,scoreAxeBladeY=-65,
    scoreAxeMouth={{123,80},{142,61},{127,82},{124,83},{126,81},{127,80}}}

local labels={"일반 접촉","벌목 성공","상시 흡연"}
for index=1,3 do
    love.graphics.push();love.graphics.translate((index-1)*320,0)
    love.graphics.setColor(.31,.48,.16,1);love.graphics.rectangle("fill",0,0,320,360)
    local world=World.new();world:useArcadeForest();world.width,world.height=320,360;world.hideBase=true
    world.arcadeForest=false;world.theme="forest";world.treeVisual.scale=1
    world.nodes={};world.buildings={};world.helpers={};world.drops={};world.enemies={}
    local player=Player.new(85,285,dummy,dummy,dummy);player:setClearcutSprite(sprite,"fire")
    player.facing=1;player.axeHolding=true;player.scoreAxeEquipped=true;player.hideAxeRange=true
    player.autoAxeDuration=.45;player.autoAxeClock=.45*.53;player.autoAxeTargetX,player.autoAxeTargetY=127,285
    local node={kind="tree",rushTree=true,active=true,x=127,y=285,rushHp=index==2 and 4 or 8,rushMaxHp=8,treeVariant=1}
    world.nodes={node}
    local game={player=player,camera={trauma=0},feedback={play=function()end}}
    local impact={kind="axe",x=127,y=220,dir=1}
    world:impactNode(node,game,index==2,impact)
    if index==2 then node.active=false;world:harvestBurst(node,game,4,"목재",impact);node.fallT=node.fallDur*.34 end
    world:updateEffects(.045,game)
    world:draw(player)
    if index==3 then
        local mode=ClearcutMode.new();mode.scoreAttack=true;mode.job="fire";mode.scoreActiveWeapon="axe"
        mode.permanentTraits.scoreAlwaysSmoking=1;mode.smoking={phase="reload",t=1.2,dur=2,loaded=false}
        mode:drawSmokerCigarette(game)
    end
    love.graphics.setColor(1,.95,.75,1);love.graphics.print(labels[index],104,328)
    love.graphics.pop()
end
fixture.save("docs/previews/score-axe-tree-feedback-v2-draws.json")
print("SCORE_AXE_TREE_CAPTURE_OK normal+fell+always-smoking window=none")
