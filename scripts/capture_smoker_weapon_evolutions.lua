package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local Mode=require("src.clearcut_mode")
local Art=require("src.smoker_weapon_art")
local bg=love.graphics.newImage("assets/maps/forest-preview-v1.png")
local smoker=love.graphics.newImage("assets/characters/ingame/smoker-atlas-pixel-v2.png")
local tree=love.graphics.newImage("assets/trees/broadleaf-tree-cartoon-v3.png")
local smokerQuad=love.graphics.newQuad(0,0,96,192,smoker:getDimensions())
local bw,bh=bg:getDimensions()

for frame=0,5 do
 fixture.reset();fixture.time=frame*.12
 love.graphics.setColor(1,1,1,.72);love.graphics.draw(bg,0,0,0,640/bw,360/bh)
 love.graphics.setColor(.02,.05,.04,.55);love.graphics.rectangle("fill",0,0,640,360)
 love.graphics.setColor(.16,.34,.19,.75);love.graphics.rectangle("fill",0,245,640,115)
 love.graphics.setColor(1,1,1,1)
 love.graphics.draw(smoker,smokerQuad,125,308,0,.61,.61,48,190)
 love.graphics.draw(smoker,smokerQuad,385,308,0,.61,.61,48,190)
 local vape=Mode.new();vape.job="fire";vape.smokerEvolution="vape";vape.vapeCharge=frame/5
 local firework=Mode.new();firework.job="fire";firework.skillBranches.molotov="fireworks"
 Art.drawHeld(vape,{player={x=125,y=308,facing=1}},fixture.time)
 Art.drawHeld(firework,{player={x=385,y=308,facing=1}},fixture.time)
 Art.drawProjectile({kind="vape_gust",x=172,y=239,age=frame/5*.50,maxLife=.52,range=540,angle=-.08})
 if frame<3 then
  Art.drawProjectile({kind="firework",x=442+frame*35,y=239-frame*24,age=(frame+1)*.12,dur=.5,angle=-.42})
 else
  Art.drawProjectile({kind="firework_burst",x=500,y=178,age=(frame-3)*.16+.05,life=1,radius=180})
 end
 fixture.save("docs/previews/smoker-weapon-evolutions-draws-"..frame..".json")
end

-- 30 fps inhale -> compression -> rooted-tree pressure response review.
for frame=0,47 do
 fixture.reset();fixture.time=frame/30
 love.graphics.setColor(1,1,1,.78);love.graphics.draw(bg,0,0,0,640/bw,360/bh)
 love.graphics.setColor(.025,.06,.04,.30);love.graphics.rectangle("fill",0,0,640,360)
 love.graphics.setColor(.16,.34,.19,.72);love.graphics.rectangle("fill",0,270,640,90)
 local blast=math.max(0,(frame-23)/24);local bend=blast*blast*.36
 love.graphics.setColor(0,0,0,.28);love.graphics.ellipse("fill",493,317,58,10)
 love.graphics.setColor(1,1,1,1);love.graphics.draw(tree,493,311,bend,.72,.72,tree:getWidth()/2,tree:getHeight()*.91)
 love.graphics.draw(smoker,smokerQuad,118,315,0,.61,.61,48,190)
 local vape=Mode.new();vape.job="fire";vape.smokerEvolution="vape";vape.vapeCharge=frame<24 and frame/23 or 0;vape.vapeKick=frame>=24 and math.max(0,1-(frame-24)/5)or 0
 Art.drawHeld(vape,{player={x=118,y=315,facing=1}},fixture.time)
 if frame>=24 then
  Art.drawProjectile({kind="vape_gust",x=160,y=246,age=(frame-24)/30,maxLife=.72,range=570,angle=0})
  for i=1,32 do
   local age=(frame-24)/30;local life=1.05
   local stream=(i%4)*7
   if age<life then Art.drawWindLeaf({x=410+stream+age*(170+i*5),y=190+(i%7)*17-age*(110-i*1.7)+math.sin(age*10+i)*12,frame=1+(i+frame)%8,age=age,life=life,scale=.72+(i%4)*.16,angle=age*(10+i*.7)+i})end
  end
 end
 fixture.save("docs/previews/smoker-vape-pressure-v2-draws-"..frame..".json")
end

-- Dedicated 30 fps gameplay-scale firework review sequence.
for frame=0,29 do
 fixture.reset();fixture.time=frame/30
 love.graphics.setColor(1,1,1,.76);love.graphics.draw(bg,0,0,0,640/bw,360/bh)
 love.graphics.setColor(.015,.035,.028,.64);love.graphics.rectangle("fill",0,0,640,360)
 love.graphics.setColor(.13,.27,.15,.78);love.graphics.rectangle("fill",0,276,640,84)
 Art.drawProjectile({kind="firework_burst",x=320,y=182,age=frame/30,life=1,radius=180})
 fixture.save("docs/previews/smoker-firework-burst-v2-draws-"..frame..".json")
end
local width,height=1280,720
love.graphics.getDimensions=function()return width,height end;love.graphics.getWidth=function()return width end;love.graphics.getHeight=function()return height end
love.mouse={getPosition=function()return -100,-100 end,isDown=function()return false end};love.keyboard={isDown=function()return false end}
local function font(path,size)return{path=path,size=size,getHeight=function()return size end,getWidth=function(_,s)return #tostring(s)*size*.52 end,
 getWrap=function(_,s,w)local chars=math.max(1,math.floor(w/(size*.52)));local lines={};s=tostring(s);for i=1,#s,chars do lines[#lines+1]=s:sub(i,i+chars-1)end;return w,lines end}end
local regular,bold="assets/font-korean-regular.ttf","assets/font-korean-bold.ttf"
local fonts={micro=font(regular,12),small=font(regular,14),body=font(regular,18),heading=font(bold,20),title=font(bold,32),big=font(bold,28)}
local choice=Mode.new();choice.job="fire";choice.level=18;choice.levels.molotov=6;choice.branchChoiceSkill="molotov"
choice.branchChoices=require("src.clearcut_skill_branches").smokerEvolutionChoices();choice.selectionKind="branch";choice.choicesRevealAt=-2
fixture.time=2;fixture.reset();choice:drawSelectionContent({mode="clearcut_upgrade",setNotice=function()end},fonts,width,height)
fixture.save("docs/previews/smoker-weapon-evolution-choice-draws.json")

local spectacle=Mode.new();spectacle.scoreAttack=true;spectacle.job="fire"
spectacle.permanentTraits.scoreRocketUnlock=1;spectacle.permanentTraits.scoreRocketTwin=1
spectacle.permanentTraits.scoreRocketCluster=1;spectacle.permanentTraits.scoreRocketFinale=1
local spectacleGame={player={x=112,y=304,facing=1,gather=1,clearClearcutAction=function()end},tools={axe={speed=1}},
 camera={screenToWorld=function()return 420,178 end},world={nodes={}},setNotice=function()end}
spectacle:updateFireworkAttack(1,spectacleGame,true)
local reviewTimes={.08,.46,.70,.92};local reviewTime=0
for index,targetTime in ipairs(reviewTimes)do
 while reviewTime+1/60<=targetTime do spectacle:updateSmokerWeaponProjectiles(1/60,spectacleGame);reviewTime=reviewTime+1/60 end
 fixture.reset();fixture.time=targetTime
 love.graphics.setColor(1,1,1,.76);love.graphics.draw(bg,0,0,0,640/bw,360/bh)
 love.graphics.setColor(.015,.035,.028,.64);love.graphics.rectangle("fill",0,0,640,360)
 love.graphics.setColor(.13,.27,.15,.78);love.graphics.rectangle("fill",0,276,640,84)
 love.graphics.setColor(1,1,1,1);love.graphics.draw(smoker,smokerQuad,112,304,0,.61,.61,48,190)
 for _,projectile in ipairs(spectacle.smokerWeaponProjectiles)do Art.drawProjectile(projectile)end
 fixture.save("docs/previews/firework-research-traits-v1-draws-"..index..".json")
end
print("SMOKER_WEAPON_EVOLUTION_CAPTURE_OK overview=6 vape=48frames@30fps firework=30fps window=none")
