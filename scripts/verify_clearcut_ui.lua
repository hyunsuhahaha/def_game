package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
love.mouse={getPosition=function()return -100,-100 end}
local width,height=1280,720
love.graphics.getDimensions=function()return width,height end
love.graphics.getWidth=function()return width end;love.graphics.getHeight=function()return height end
local Mode=require("src.clearcut_mode")
local Art=require("src.clearcut_ui_art")
local fonts={};for name,size in pairs({micro=12,small=14,body=17,heading=21,big=28,title=36,display=48})do fonts[name]=love.graphics.newFont("assets/font-korean-regular.ttf",size)end
local result={victory=true,operationName="온대림 전면 철거",bossName="고목 감시자",elapsed=247,wood=3820,trees=60,total=60,
    maxMulti=9,maxChain=14,level=12,stage=1,regrowPulses=6,treesRevived=41,rootedCount=3,beeSwarms=4,kills=7,zonesSecured=6,zonesTotal=6,traitEarned=60}
for _,size in ipairs({{960,540},{1280,720},{1920,1080}})do
    width,height=size[1],size[2];local mode=Mode.new();local game={result=result}
    fixture.reset();mode:drawResults(game,fonts)
    local successText,retry=false,false
    for _,cmd in ipairs(fixture.commands)do
        if cmd.text and cmd.text:find("철거 완료",1,true)then successText=true end
        if cmd.text and cmd.text:find("다시 도전",1,true)then retry=true end
    end
    assert(successText and retry and game.clearcutResultButtons.research,"focused result UI did not render")
    for _,box in pairs(game.clearcutResultButtons or{})do assert(box.x>=0 and box.y>=0 and box.x+box.w<=width and box.y+box.h<=height,"result button escaped viewport")end
end
fixture.reset();Art.bar(10,10,320,14,.64,"health");local rectangles=0;for _,cmd in ipairs(fixture.commands)do if cmd.op=="rectangle"then rectangles=rectangles+1 end;assert(not cmd.file,"minimal bar loaded a decorative asset")end
assert(rectangles>=6,"pixel bar lost stepped shading")
local modeSource=assert(io.open("src/clearcut_mode.lua","rb"));local modeText=modeSource:read("*a");modeSource:close()
assert(modeText:find('"COMBO"',1,true),"fighting-game combo label missing")
assert(not modeText:find("연속 채집 ×",1,true),"boxed harvest combo copy returned")
assert(not modeText:find("HUDArt.panel",1,true)and not modeText:find("resultBoard",1,true),"decorative card/board returned to clearcut UI")
local intro=assert(io.open("src/clearcut_intro.lua","rb"));local source=intro:read("*a");intro:close()
assert(not source:find("작전 개시",1,true)and not source:find("전투 시작",1,true)and not source:find("작업 시작",1,true),"start banner copy returned")
print("CLEARCUT_UI_V5_OK hud=minimal_pixel_bars combo=number_only results=record_reward_actions responsive=960..1920 start_banner=removed")
