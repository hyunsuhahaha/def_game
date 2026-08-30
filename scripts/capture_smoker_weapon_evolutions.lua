package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local Mode=require("src.clearcut_mode")
local Art=require("src.smoker_weapon_art")
local bg=love.graphics.newImage("assets/maps/forest-preview-v1.png")
local smoker=love.graphics.newImage("assets/characters/ingame/smoker-atlas-pixel-v2.png")
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
 local vape=Mode.new();vape.job="fire";vape.skillBranches.molotov="vape"
 local firework=Mode.new();firework.job="fire";firework.skillBranches.molotov="fireworks"
 Art.drawHeld(vape,{player={x=125,y=308,facing=1}},fixture.time)
 Art.drawHeld(firework,{player={x=385,y=308,facing=1}},fixture.time)
 Art.drawProjectile({kind="vape",x=185+frame*28,y=239-math.sin(frame*.8)*9,age=frame*.11,maxLife=.72,angle=-.08})
 if frame<3 then
  Art.drawProjectile({kind="firework",x=442+frame*35,y=239-frame*24,age=(frame+1)*.12,dur=.5,angle=-.42})
 else
  Art.drawProjectile({kind="firework_burst",x=500,y=178,age=(frame-3)*.16+.05,life=1,radius=180})
 end
 fixture.save("docs/previews/smoker-weapon-evolutions-draws-"..frame..".json")
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
choice.branchChoices=require("src.clearcut_skill_branches").forSkill("molotov");choice.selectionKind="branch";choice.choicesRevealAt=-2
fixture.time=2;fixture.reset();choice:drawSelectionContent({mode="clearcut_upgrade",setNotice=function()end},fonts,width,height)
fixture.save("docs/previews/smoker-weapon-evolution-choice-draws.json")
print("SMOKER_WEAPON_EVOLUTION_CAPTURE_OK overview=6 firework=30fps window=none")
