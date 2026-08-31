package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
love.graphics.rotate=love.graphics.rotate or function()end
love.graphics.getDimensions=function()return 1280,720 end
love.graphics.getWidth=function()return 1280 end
love.graphics.getHeight=function()return 720 end
love.mouse={getPosition=function()return 0,0 end,isDown=function()return false end}
love.keyboard={isDown=function()return false end}

local Game=require("src.game")
local World=require("src.world")
local Player=require("src.player")
local Camera=require("src.camera")
local Traits=require("src.character_traits").new(true)
local loader
for index=1,30 do local name,value=debug.getupvalue(Game.new,index);if name=="loadClearcutSprites"then loader=value;break end end
local sprites=assert(loader)()
local game=setmetatable({characterTraits=Traits,clearcutSprites=sprites,tools={axe={speed=.8}},wood=0},Game)
function game:resetRun()
    self.world=World.new()
    self.player=Player.new(1600,1000,self.world.images.workerWalk,self.world.images.workerActions,self.world.images.workerRepair)
    self.camera=Camera.new(1600,1000)
end
function game:setNotice()end
game.feedback={last=nil,play=function(self,kind,strong)self.last={kind=kind,strong=strong}end}

game:startClearcutScoreAttack()
local mode=game.clearcut
mode.scoreWeaponSlot=2
game.world.nodes={}
local drum={id=99,x=game.player.x+110,y=game.player.y,state="settled",hp=8,maxHp=8,angle=0,squash=1,hitFlash=0}
mode.oilDrums={drum}
mode.aimPoint=function()return drum.x,drum.y end

assert(not mode:updateScoreAxeAttack(0,game,true),"axe dealt damage on input instead of its contact frame")
assert(mode.scoreAxeAction and drum.hp==8 and game.player.autoAxeClock~=nil,"axe wind-up/action was not started")
local contact=mode.scoreAxeAction.contactTime
mode:updateScoreAxeAttack(contact-.001,game,true)
assert(drum.hp==8 and #mode.scoreAxeImpacts==0,"drum was hit before the blade contact frame")
assert(mode:updateScoreAxeAttack(.002,game,true),"contact frame did not report an impact")
assert(drum.hp==4 and #mode.scoreAxeImpacts==1 and drum.hitKickTime>0,"first drum dent lacks damage/contact feedback")
assert(mode.scoreAxeAction.hitStop>0 and game.feedback.last and game.feedback.last.kind=="metal","drum hit lacks contact hold or metal sound")
mode:updateScoreAxeAttack(.01,game,true)
assert(drum.hp==4 and #mode.scoreAxeImpacts==1,"one swing applied its contact damage more than once")

-- Finish recovery, bypass only the cooldown wait, then verify the second
-- authored contact tips the drum and starts its existing oil-spill system.
for _=1,30 do mode:updateScoreAxeAttack(.03,game,false)end
mode.axeCooldown=0
mode:updateScoreAxeAttack(0,game,true)
local secondContact=mode.scoreAxeAction.contactTime
mode:updateScoreAxeAttack(secondContact+.001,game,true)
assert(drum.hp==0 and drum.state=="spilled"and #mode.oilDrumSpills==1,"second axe contact did not break/spill the drum")
assert(game.feedback.last.strong==true,"breaking hit did not use the strong metal response")

for _=1,30 do mode:updateScoreAxeAttack(.03,game,false)end
mode.axeCooldown=0
local leftDrum={id=100,x=game.player.x-110,y=game.player.y,state="settled",hp=8,maxHp=8,angle=0,squash=1,hitFlash=0}
mode.oilDrums={leftDrum};mode.aimPoint=function()return leftDrum.x,leftDrum.y end
mode:updateScoreAxeAttack(0,game,true)
assert(game.player.facing==-1 and leftDrum.hp==8,"left-facing wind-up is reversed or damages immediately")
mode:updateScoreAxeAttack(mode.scoreAxeAction.contactTime+.001,game,true)
assert(leftDrum.hp==4 and leftDrum.hitDirection==-1,"left-facing blade contact did not mirror toward the target")

local source=assert(io.open("src/gray_oil_cat_art.lua","rb")):read("*a")
assert(source:find("oil%-drum%-damage%-atlas%-pixel%-v2%.png"),"runtime still loads the undamaged one-frame drum")
local axeSource=assert(io.open("src/score_axe_art.lua","rb")):read("*a")
assert(not axeSource:find("axe%-atlas%-v1%.png")and axeSource:find("oil%-drum%-axe%-hit%-atlas%-pixel%-v1%.png"),
    "the old rotating axe overlay remains or the contact atlas is missing")
local playerSource=assert(io.open("src/player.lua","rb")):read("*a")
assert(playerSource:find("scoreAxeFrames")and playerSource:find("scoreAxeEquipped"),
    "the authored full-body axe action atlas is not selected by the player renderer")
assert(sprites.fire.scoreAxeImage and #game.player.scoreAxeFrames==6,"six-frame full-body axe atlas was not loaded")
print("SCORE_AXE_DRUM_OK full-body-swing contact-frame damage dent+kick+metal+hitstop second-hit=spill")
