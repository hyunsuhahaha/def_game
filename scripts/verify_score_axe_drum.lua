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
game.world.nodes={}
local drum={id=99,x=game.player.x+42,y=game.player.y,state="settled",hp=8,maxHp=8,angle=0,squash=1,hitFlash=0}
mode.oilDrums={drum}
mode.aimPoint=function()return drum.x,drum.y end

assert(not mode:updateScoreAxeAttack(0,game,true),"axe dealt damage on input instead of its contact frame")
assert(mode.scoreAxeAction and drum.hp==8 and game.player.autoAxeClock~=nil,"axe wind-up/action was not started")
local attackX,attackY=game.player.x,game.player.y
love.keyboard.isDown=function(key)return key=="d"end
game.player:update(.01,game.world,game)
love.keyboard.isDown=function()return false end
assert(game.player.x>attackX and game.player.y==attackY and game.player.isMoving,
    "axe attack incorrectly blocked movement input")
game.player.x,game.player.y,game.player.autoAxeClock=attackX,attackY,0
local startDrawX=game.player:autoAxeRenderPosition()
local contact=mode.scoreAxeAction.contactTime
mode:updateScoreAxeAttack(contact-.001,game,true)
assert(drum.hp==8 and #mode.scoreAxeImpacts==0,"drum was hit before the blade contact frame")
local contactDrawX=game.player:autoAxeRenderPosition()
local bladeX,bladeY=game.player:scoreAxeBladePosition()
assert(contactDrawX==startDrawX and contactDrawX==game.player.x and math.abs(drum.x-bladeX)<1,
    "axe attack moved the player instead of striking in place")
assert(mode:updateScoreAxeAttack(.002,game,true),"contact frame did not report an impact")
assert(drum.hp==4 and #mode.scoreAxeImpacts==1 and drum.hitKickTime>0,"first drum dent lacks damage/contact feedback")
assert(mode.scoreAxeAction.hitStop>0 and game.feedback.last and game.feedback.last.kind=="metal","drum hit lacks contact hold or metal sound")
local lockedFacing=game.player.facing
mode.aimPoint=function()return game.player.x-42,game.player.y end
mode:updateScoreAxeAttack(.01,game,true)
assert(drum.hp==4 and #mode.scoreAxeImpacts==1 and game.player.facing==lockedFacing,
    "one swing applied damage twice or changed direction after locking its target")
mode.aimPoint=function()return drum.x,drum.y end

-- 접촉 시간만 맞고 보이는 날이 대상에서 벗어나면 피해가 없어야 한다.
for _=1,30 do mode:updateScoreAxeAttack(.03,game,false)end
mode.axeCooldown=0;drum.hp,drum.state=8,"settled"
mode:updateScoreAxeAttack(0,game,true)
drum.x=drum.x+90
mode:updateScoreAxeAttack(mode.scoreAxeAction.contactTime+.001,game,true)
assert(drum.hp==8 and mode.scoreAxeAction.hitStop==0,
    "visible axe blade missed the drum but timer-only damage or hit-stop still landed")
drum.x,drum.hp=game.player.x+42,4

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
local leftDrum={id=100,x=game.player.x-42,y=game.player.y,state="settled",hp=8,maxHp=8,angle=0,squash=1,hitFlash=0}
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

mode.permanentTraits.scoreAlwaysSmoking=1
mode.scoreActiveWeapon="axe";mode.smoking={phase="reload",t=.4,dur=2,loaded=false}
game.player.scoreAxeEquipped=true;game.player.autoAxeClock=0;game.player.autoAxeDuration=.45
game.player.autoAxeTargetX,game.player.autoAxeTargetY=game.player.x+70,game.player.y
local mouthStart=mode:smokerMouthPose(game)
game.player.autoAxeClock=.45*.53
local mouthContact=mode:smokerMouthPose(game)
assert(math.abs(mouthContact-mouthStart)<5,"axe mouth anchor moved with a removed body lunge")
fixture.reset();mode:drawHeldSmoker(game,.5)
local cigaretteDrawn=false
for _,command in ipairs(fixture.commands)do
    if command.op=="draw"and command.file:find("smoker%-cigarette%-pixel%-v2%.png")then cigaretteDrawn=true end
end
assert(cigaretteDrawn,"always-smoking trait reloads during axe swings but draws no cigarette or smoke")
print("SCORE_AXE_DRUM_OK stationary-full-body-swing target-lock contact-frame damage dent+kick+metal+hitstop second-hit=spill")
