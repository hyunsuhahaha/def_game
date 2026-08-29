package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local Mode=require("src.clearcut_mode")
local width,height=1280,720
love.graphics.getDimensions=function()return width,height end
love.graphics.getWidth=function()return width end;love.graphics.getHeight=function()return height end
local mouseX,mouseY=150,372
love.mouse={getPosition=function()return mouseX,mouseY end,isDown=function()return false end}
love.keyboard={isDown=function()return false end}
local function font(path,size)
 return{path=path,size=size,getHeight=function()return size end,
  getWidth=function(_,s)return #tostring(s)*size*.52 end,
  getWrap=function(_,s,w)local chars=math.max(1,math.floor(w/(size*.52)));local lines={};s=tostring(s)
   for i=1,#s,chars do lines[#lines+1]=s:sub(i,i+chars-1)end;return w,lines end}
end
local regular="assets/font-korean-regular.ttf";local bold="assets/font-korean-bold.ttf"
local fonts={micro=font(regular,12),small=font(regular,14),body=font(regular,18),heading=font(bold,20),title=font(bold,32),big=font(bold,28)}
local mode=Mode.new();mode.job="fire";mode.level=12;mode.levels={thorn_aura=1,bat_swarm=1,molotov=1}
mode.choices={mode:getUpgradeDefinition("seed_mine"),mode:getUpgradeDefinition("boomerang_axe"),mode:getUpgradeDefinition("crow_strike")}
mode.totalWood=120;mode.pending=1;mode.choicesRevealAt=-2;mode.selectionKind="upgrade"
local game={mode="clearcut_upgrade",setNotice=function()end}
fixture.time=2;fixture.reset();mode:drawSelectionContent(game,fonts,width,height)
fixture.save("docs/previews/clearcut-synergy-draft-ui-draws.json")

mode.branchChoiceSkill="seed_mine";mode.branchChoices=require("src.clearcut_skill_branches").forSkill("seed_mine")
mode.selectionKind="branch";mode.choicesRevealAt=-2;mouseX,mouseY=-100,-100
fixture.reset();mode:drawSelectionContent(game,fonts,width,height)
fixture.save("docs/previews/clearcut-synergy-branch-ui-draws.json")

-- Separate left-rail hover fixture at real HUD coordinates.
mouseX,mouseY=60,272;fixture.reset();mode:drawSkillTracker(fonts)
fixture.save("docs/previews/clearcut-synergy-hud-ui-draws.json")
print("CLEARCUT_SYNERGY_UI_CAPTURE_OK card_hover=seed-growth HUD_hover=active window=none")
