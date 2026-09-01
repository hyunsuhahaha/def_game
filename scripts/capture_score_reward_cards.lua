-- 세계수 처치 3택 카드를 실제 draw 호출로 기록한다.
-- 배타 축 표시가 카드 안에 들어가는지 눈으로 확인하기 위한 캡처다.
package.path="./?.lua;./?/init.lua;"..package.path

local fixture=require("scripts.forest_render_fixture")
local Mode=require("src.clearcut_mode")
local ScoreWorldTree=require("src.score_world_tree")

local mode=Mode.new()
mode.scoreAttack=true

-- 축이 겹치지 않는 세 장을 고정으로 세운다. 무작위였다면 캡처마다 그림이 달라진다.
mode.scoreRewardChoices={
    ScoreWorldTree.get("flashover"),
    ScoreWorldTree.get("clear_cut"),
    ScoreWorldTree.get("windfall"),
}

-- fixture 는 실제 창이 없어 getDimensions 를 제공하지 않는다. 1280x720 으로 고정한다.
love.graphics.getDimensions=function() return 1280,720 end

local fonts={
    big=love.graphics.newFont(30),body=love.graphics.newFont(20),
    small=love.graphics.newFont(16),micro=love.graphics.newFont(13),
}

fixture.reset()
mode:drawScoreRewards({},fonts)

local capture=assert(os.getenv("SCORE_REWARD_CARDS_CAPTURE"),"SCORE_REWARD_CARDS_CAPTURE is required")
fixture.save(capture)
print(string.format("SCORE_REWARD_CARDS_CAPTURE_OK cards=%d pool=%d",
    #mode.scoreRewardChoices,#ScoreWorldTree.rewards))
