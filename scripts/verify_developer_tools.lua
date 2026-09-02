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

for _,action in ipairs({7,8,9,6})do game:useTestOption(action)end
assert(table.concat(game.characterTraits.progresses,",")=="70,80,90,100" and game.testMessage:find("300/300단계",1,true),
    "developer trait presets did not persist or report 70/80/90/100 percent")

for _,size in ipairs({{960,540},{1280,720}})do
    local layout=game:testOptionLayout(size[1],size[2])
    assert(#layout.actions==9,"developer tool layout lost a trait preset action")
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

game:useTestOption(2)
assert(game.testGrantNextRun,"next-run resource reservation failed")
assert(game:consumeTestNextRunResources() and game.food==1000000 and game.ore==1000000 and game.wood==1000000 and game.stone==1000000 and game.seeds==1000000,
    "next-run resource grant failed")
assert(not game:consumeTestNextRunResources() and game.food==1000000,"next-run resources were consumed more than once")

game:useTestOption(3)
assert(game.testLevelsNextRun==20 and game.testMessage:find("+20",1,true),"next-run +20 reservation failed")
assert(game:consumeTestNextRunLevels()==20 and game.runLevel==21 and game.pendingLevels==20 and game.testLevelsNextRun==0,
    "standard run did not consume exactly twenty levels")
assert(game:consumeTestNextRunLevels()==0 and game.runLevel==21,"next-run levels were consumed more than once")

game.clearcut={level=1,pending=0,xpNext=10,openUpgradeChoices=function(self,g)g.mode="clearcut_upgrade";self.opened=true end}
game.testLevelsNextRun,game.testLevelsNextRunManual=20,true
assert(game:consumeTestNextRunLevels()==20 and game.clearcut.level==21 and game.clearcut.pending==20,"clearcut next-run levels failed")
game.testReturnMode="playing";game:useTestOption(3)
assert(game.clearcut.level==31 and game.clearcut.pending==30,"current clearcut +10 failed")
game:useTestOption(8)
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

print("DEVELOPER_TOOLS_OK research_coin=1m traits=70/80/90/100 resources=next_once levels=current10+next20 "..
    "responsive=960x540+ modes=standard+rush+clearcut reset=confirmed")
