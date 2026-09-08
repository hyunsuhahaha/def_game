local fixture=require("scripts.forest_render_fixture")
local Store=require("src.character_traits")
local Board=require("src.character_trait_board")
love.mouse={getPosition=function()return -100,-100 end,isDown=function()return false end}
for _,size in ipairs({{960,540},{1280,720},{2048,1038}})do
    local w,h=unpack(size)
    love.graphics.getDimensions=function()return w,h end
    local store=Store.new(true);store.data.currency=1000000
    local board=Board.new(store,{},{})
    board:draw()
    assert(#board.tabBoxes==2 and board.selectedJob=="all")
    for _,box in ipairs(board.tabBoxes)do
        assert(box.y>board.viewport.y+board.viewport.h and box.y+box.h<=h)
    end
    local box=board.tabBoxes[2]
    assert(board:mousepressed(box.x+2,box.y+2,1)=="selected")
    assert(board.selectedJob=="builder" and board.buyButtonBox==nil and board.drag==nil)
    board:draw()
    assert(board.selectedNodeId=="builder_damage" and not board.buyButtonBox)
    assert(not store:status("builder_damage"),"locked builder can be purchased")
    assert(store.data.currency==1000000 and not store.data.jobMasterFire)
    store:maxAll()
    board:keypressed("1");board:draw();board:draw()
    assert(board.selectedJob=="all","master state overrides user's research tab")
    local count=#store:getScoreAttackNodes("fire")+#store:getScoreAttackNodes("universal")
    assert(#board:nodesFor("all")==count,"master smoker nodes lost")
    board:keypressed("2");board:draw()
    assert(board.selectedJob=="builder" and store:getLevel("builder_damage")>0)
end
print("RESEARCH_CHARACTER_TABS_OK bottom mouse+keys locked-preview master-switch no-currency-mutation three-resolutions")
