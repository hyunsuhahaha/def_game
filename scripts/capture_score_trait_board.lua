package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
love.mouse={getPosition=function()return -100,-100 end,isDown=function()return false end}

local Store=require("src.character_traits")
local Board=require("src.character_trait_board")
local Game=require("src.game")
local loader
for i=1,30 do local name,value=debug.getupvalue(Game.new,i);if name=="loadClearcutSprites"then loader=value;break end end
local sprites=assert(loader,"clearcut sprite loader missing")()
local background=love.graphics.newImage("assets/lobby-forest-lofi-day-pixel-v4.png");background:setFilter("nearest","nearest")
local fonts={}
for name,size in pairs({micro=12,small=14,body=17,heading=21,big=28,title=36,display=48})do fonts[name]=love.graphics.newFont("assets/font-korean-regular.ttf",size)end
local function capture(w,h,path,job)
    love.graphics.getDimensions=function()return w,h end
    love.graphics.getWidth=function()return w end
    love.graphics.getHeight=function()return h end
    local store=Store.new(true);store.data.currency=240
    local board=Board.new(store,fonts,sprites);board.time=1.2
    if job and job~="fire"then board:selectJob(job)end
    fixture.reset();fixture.time=1.2
    local iw,ih=background:getDimensions();local scale=math.max(w/iw,h/ih)*1.025
    love.graphics.setColor(1,1,1,1);love.graphics.draw(background,(w-iw*scale)/2,(h-ih*scale)/2,0,scale,scale)
    love.graphics.setColor(.02,.08,.055,.18);love.graphics.rectangle("fill",0,0,w,h)
    board:draw();fixture.save(path)
end
capture(1280,720,"docs/previews/score-trait-board-draws.json")
capture(1280,720,"docs/previews/score-trait-board-universal-draws.json","universal")
capture(2048,1038,"docs/previews/score-trait-board-wide-draws.json")
capture(2048,1038,"docs/previews/score-trait-board-universal-wide-draws.json","universal")
print("SCORE_TRAIT_BOARD_CAPTURE_OK 1280x720+2048x1038 universal=1280x720+2048x1038 window=none")
