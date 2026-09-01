-- 세계수 타격 시 수관에서 쏟아지는 목재를 실제 draw 호출로 기록한다.
-- 게임 창을 띄우지 않고 눈으로 확인하기 위한 캡처다.
package.path="./?.lua;./?/init.lua;"..package.path

local fixture=require("scripts.forest_render_fixture")
local Mode=require("src.clearcut_mode")
local catalog=require("src.forest_enemy_catalog")

local mode=Mode.new()
mode.scoreAttack=true
mode.enemies={}

local tree={x=200,y=380,hp=260,maxHp=260,scoreWorldTree=true,def={radius=420}}
mode.scoreWorldTree=tree
mode.scoreWorldTreeHp=tree.hp

local game={
    player={x=200,y=410},
    world={nodes={},playBounds={x=0,y=0,w=400,h=420},
        images={lumber=love.graphics.newImage("assets/lumber-drop-v1.png")}},
    camera={trauma=0},
    setNotice=function() end,
}

-- 여러 번 때린 뒤 잠시 흐른 상태를 잡는다. 갓 뿌려진 것과 떨어지는 중인 것이
-- 한 화면에 함께 보여야 "우수수" 로 읽힌다.
for swing=1,5 do
    tree.hp=tree.hp-16
    mode:updateScoreWorldTree(1/60,game)
    for _=1,10 do mode:updateWorldTreeLumber(1/60) end
end
tree.hp=tree.hp-16
mode:updateScoreWorldTree(1/60,game)
for _=1,3 do mode:updateWorldTreeLumber(1/60) end

assert(#mode.worldTreeLumber>0,"쏟아진 목재가 하나도 없다")
local highest,lowest=0,1e9
for _,piece in ipairs(mode.worldTreeLumber) do
    highest=math.max(highest,piece.height); lowest=math.min(lowest,piece.height)
end

fixture.reset()
love.graphics.setColor(.30,.47,.17,1)
love.graphics.rectangle("fill",0,0,400,420)
-- 세계수 자리를 기둥으로만 표시한다. 목재가 수관에서 나오는지 보기 위한 기준선이다.
local crown=catalog.worldtree.height
love.graphics.setColor(.16,.30,.14,1)
love.graphics.rectangle("fill",tree.x-26,tree.y-crown,52,crown)
love.graphics.setColor(.24,.44,.20,1)
love.graphics.ellipse("fill",tree.x,tree.y-crown,86,30)
mode:drawWorldTreeLumber(game)

local capture=assert(os.getenv("WORLD_TREE_LUMBER_CAPTURE"),"WORLD_TREE_LUMBER_CAPTURE is required")
fixture.save(capture)
print(string.format("WORLD_TREE_LUMBER_CAPTURE_OK pieces=%d crown=%d highest=%.0f lowest=%.0f",
    #mode.worldTreeLumber,crown,highest,lowest))
