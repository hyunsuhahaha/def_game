package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
love.graphics.getDimensions=function()return 1280,720 end
love.graphics.getWidth=function()return 1280 end
love.graphics.getHeight=function()return 720 end
love.mouse={getPosition=function()return -100,-100 end,isDown=function()return false end}

local Store=require("src.character_traits")
local Board=require("src.character_trait_board")
local Game=require("src.game")
local loader
for i=1,30 do local name,value=debug.getupvalue(Game.new,i);if name=="loadClearcutSprites"then loader=value;break end end
local sprites=assert(loader,"clearcut sprite loader missing")()
local fonts={}
for name,size in pairs({micro=12,small=14,body=17,heading=21,big=28,title=36,display=48})do fonts[name]=love.graphics.newFont("assets/font-korean-regular.ttf",size)end
local store=Store.new(true);store.data.currency=240
local board=Board.new(store,fonts,sprites);board.time=1.2
fixture.reset();fixture.time=1.2;board:draw()
fixture.save("docs/previews/score-trait-board-draws.json")
print("SCORE_TRAIT_BOARD_CAPTURE_OK 1280x720 window=none")
