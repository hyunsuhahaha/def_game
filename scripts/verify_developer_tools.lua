package.path="./?.lua;./?/init.lua;"..package.path
require("scripts.forest_render_fixture")
local Game=require("src.game")

local resets={progression=0,traits=0,achievements=0}
local game=setmetatable({
    food=0,ore=0,wood=0,stone=0,seeds=0,
    runLevel=1,runXP=0,runXPNext=18,pendingLevels=0,runType=nil,
    progression={data={currency=0},addCurrency=function(self,n)self.data.currency=self.data.currency+n end,reset=function()resets.progression=resets.progression+1 end},
    characterTraits={data={currency=0},addCurrency=function(self,n)self.data.currency=self.data.currency+n end,
        setScoreProgress=function(self,percent)self.progresses=self.progresses or{};self.progresses[#self.progresses+1]=percent;return percent*3,300 end,
        reset=function()resets.traits=resets.traits+1 end},
    achievements={reset=function()resets.achievements=resets.achievements+1 end},
    upgrades={rollChoices=function(self)self.rolled=true end},
},Game)

game.testReturnMode="lobby";game:useTestOption(1)
assert(game.characterTraits.data.currency==1000000 and game.progression.data.currency==0,"developer research coin grant failed")

for action=6,15 do game:useTestOption(action)end
assert(table.concat(game.characterTraits.progresses,",")=="10,20,30,40,50,60,70,80,90,100" and game.testMessage:find("300/300단계",1,true),
    "developer trait presets did not persist or report every 10 percent step")

for _,size in ipairs({{960,540},{1280,720}})do
    local layout=game:testOptionLayout(size[1],size[2])
    assert(#layout.actions==13,"developer tool layout action count is wrong")
    local found={}
    for _,action in ipairs(layout.actions)do found[action.index]=true end
    assert(found[1]and found[4]and found[16]and not found[2]and not found[3]and not found[5],
        "developer tool layout did not replace the unused resource/level actions")
    assert(layout.panel.x>=0 and layout.panel.y>=0 and layout.back.y+layout.back.h<=size[2],
        "developer tool panel clipped at "..size[1].."x"..size[2])
    for first=1,#layout.actions do for second=first+1,#layout.actions do
        local a,b=layout.actions[first],layout.actions[second]
        assert(a.x+a.w<=b.x or b.x+b.w<=a.x or a.y+a.h<=b.y or b.y+b.h<=a.y,
            "developer tool actions overlap at "..size[1].."x"..size[2])
    end end
    assert(layout.actions[#layout.actions].y+layout.actions[#layout.actions].h<=layout.message.y
        and layout.message.y+layout.message.h<=layout.back.y,
        "developer status message overlaps a control at "..size[1].."x"..size[2])
end

game.clearcut={level=1,pending=0,xpNext=10,openUpgradeChoices=function(self,g)g.mode="clearcut_upgrade";self.opened=true end}
game.testLevelsNextRun,game.testLevelsNextRunManual=20,true
assert(game:consumeTestNextRunLevels()==20 and game.clearcut.level==21 and game.clearcut.pending==20,"clearcut next-run levels failed")
game.testReturnMode="playing"
game:useTestOption(13)
assert(game.characterTraits.progresses[#game.characterTraits.progresses]==80 and game.testMessage:find("재시작 후 전체 적용",1,true),
    "active-run trait preset did not explain when spawn-time traits take effect")
game:closeTestOptions()
assert(game.mode=="clearcut_upgrade" and game.clearcut.opened,"closing developer tools did not open clearcut choices")

game.clearcut=nil;game.rush={level=1,pending=0,xpNext=10,rollChoices=function(self)self.rolled=true end}
game.testLevelsNextRun,game.testLevelsNextRunManual=20,true
assert(game:consumeTestNextRunLevels()==20 and game.rush.level==21 and game.rush.pending==20,"rush next-run levels failed")
game.testReturnMode="playing";game:closeTestOptions()
assert(game.mode=="rush_upgrade" and game.rush.rolled,"closing developer tools did not open rush choices")

game.testReturnMode="lobby";game:useTestOption(4)
assert(game.testResetArmed and game.testResetTime==4,"developer reset confirmation did not arm")
game:useTestOption(4)
assert(resets.progression==1 and resets.traits==1 and resets.achievements==1 and not game.testResetArmed,"developer reset did not clear every permanent store")

game.startClearcutScoreAttack=function(self,tier,tutorialMode)
    self.startedTutorialTier,self.startedTutorialMode=tier,tutorialMode
    self.clearcut={scoreAttack=true,scoreTutorialRun=tutorialMode==true};self.mode="playing"
end
game.clearcut={scoreAttack=true};game.testReturnMode="playing";game.mode="test_options";game:useTestOption(16)
assert(game.startedTutorialTier==1 and game.startedTutorialMode==true and game.clearcut.scoreTutorialRun,
    "developer tutorial replay did not replace the current run with an isolated tutorial")

print("DEVELOPER_TOOLS_OK research_coin=1m tutorial=replay_no_save traits=10..100_step10 "..
    "responsive=960x540+ reset=confirmed removed=resources+levels")
