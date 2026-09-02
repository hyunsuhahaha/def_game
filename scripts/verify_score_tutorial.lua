package.path="./?.lua;./?/init.lua;"..package.path

local Traits=require("src.character_traits")
local Tutorial=require("src.score_tutorial")

local function source(path)local f=assert(io.open(path,"rb"));local s=f:read("*a");f:close();return s end
local gameSource,modeSource=source("src/game.lua"),source("src/clearcut_mode.lua")
assert(gameSource:find("ScoreTutorial.start%(self.clearcut,self%)"),"score run start is not connected to tutorial")
assert(modeSource:find("recordScoreRunCompleted",1,true)and modeSource:find("not self.scorePractice and not self.defenseMode",1,true)
    and modeSource:find("not self.scoreTutorialTestRun",1,true),
    "ordinary score result is not connected to tutorial run count")

local traits=Traits.new(true)
assert(not traits:shouldStartScoreTutorial(),"fresh first run must stay unguided")
assert(traits:recordScoreRunCompleted()==1 and traits:shouldStartScoreTutorial(),"second run tutorial did not unlock")

local mode={scoreAttack=true,actionAudit={scoreAxe=0,cigaretteFlick=0}}
local game={characterTraits=traits}
assert(Tutorial.start(mode,game)and mode.scoreTutorial.step==1,"second score run tutorial did not start")
mode.actionAudit.scoreAxe=1;Tutorial.update(mode,game,.016)
assert(mode.scoreTutorial.step==2,"axe action did not advance tutorial")
mode.actionAudit.cigaretteFlick=1;Tutorial.update(mode,game,.016)
assert(mode.scoreTutorial.step==3,"ranged action did not advance tutorial")
Tutorial.update(mode,game,Tutorial.FINAL_DURATION)
assert(mode.scoreTutorial==nil and traits.data.scoreTutorialSeen,"tutorial did not persist completion")

local encoded=Traits.encode(traits.data)
local decoded=Traits.decode(encoded)
assert(decoded.scoreRunsCompleted==1 and decoded.scoreTutorialSeen,"tutorial save fields did not round-trip")
assert(Traits.decode("version=6\ncurrency=12\nregenTier=1\n").scoreTutorialSeen,"progressed legacy save was not migrated")
assert(not Traits.decode("version=6\ncurrency=0\nregenTier=1\n").scoreTutorialSeen,"clean legacy save lost second-run tutorial")

for _,variant in ipairs({{scoreAttack=true,scorePractice=true},{scoreAttack=true,defenseMode=true},{scoreAttack=false}})do
    local blockedTraits=Traits.new(true);blockedTraits.data.scoreRunsCompleted=1
    assert(not Tutorial.start(variant,{characterTraits=blockedTraits}),"tutorial leaked into excluded mode")
end

local replayTraits=Traits.new(true)
local replay={scoreAttack=true,actionAudit={}}
assert(Tutorial.forceStart(replay)and replay.scoreTutorial.persist==false,"developer replay did not start without persistence")
replay.scoreTutorial.step=3
Tutorial.update(replay,{characterTraits=replayTraits},Tutorial.FINAL_DURATION)
assert(replay.scoreTutorial==nil and not replayTraits.data.scoreTutorialSeen,"developer replay changed the real tutorial save")

local fixture=require("scripts.forest_render_fixture")
local fonts={heading=love.graphics.newFont("assets/font-korean-bold.ttf",24),micro=love.graphics.newFont("assets/font-korean-pixel.ttf",14)}
for step=1,3 do
    fixture.reset();Tutorial.draw({scoreTutorial={step=step}},fonts,1280,720)
    assert(#fixture.commands>=5,"tutorial step did not draw its compact panel")
end

print("SCORE_TUTORIAL_OK first=free second=guided steps=axe+ranged+loss_meta persistent=true dev_replay=no_save exclusions=practice+defense")
