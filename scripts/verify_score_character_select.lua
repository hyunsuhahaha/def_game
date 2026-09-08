local game=dofile("scripts/verify_job_master.lua")
local Select=require("src.score_character_select")
local Lobby=require("src.lobby")
local fixture=require("scripts.forest_render_fixture")
local store=game.characterTraits
local backgroundUpdates=0
local idle=setmetatable({mode="score_character_select",settings={musicVolume=1},
    achievements={update=function()end},achievementBoard={update=function()end},camera={updateMode=function()end},
    lobby={syncAudio=function()end,update=function()backgroundUpdates=backgroundUpdates+1 end}},getmetatable(game))
idle:update(.1)
assert(backgroundUpdates==1,"character selector must update lobby only, never the prior combat run")
assert(Select.current(game)=="builder")
Select.open(game);assert(game.mode=="score_character_select"and game.scoreCharacterFocus==2)
Select.keypressed(game,"left");Select.keypressed(game,"return")
assert(game.mode=="lobby"and game.selectedScoreCharacter=="fire")
game:startClearcutScoreAttack(1,false)
assert(not game.clearcut.jobMaster and not game.player.construction,"smoker choice still forces the crane")
Select.open(game);Select.keypressed(game,"right");Select.keypressed(game,"return")
game:startClearcutScoreAttack(1,false)
assert(game.clearcut.jobMaster and game.player.construction,"crane choice did not start the selected machine")
game:retryClearcut();assert(game.player.construction,"retry lost the selected character")

store.data.jobMasterFire=false
local id="fire_score_prewarm";local before=store.data.levels[id];store.data.levels[id]=0
Select.open(game);Select.keypressed(game,"right")
assert(not Select.confirm(game)and game.mode=="score_character_select","locked crane can be selected")
Select.keypressed(game,"escape");assert(game.mode=="lobby","cancel failed")
assert(Lobby.keypressed({menuFocus=1},"c")=="score_character_select")
assert(Lobby.keypressed({menuFocus=1},"d")==nil,"D still starts defense")
local fonts={}
for name,size in pairs({micro=12,small=14,body=18,heading=21,title=36,display=48})do
    fonts[name]=love.graphics.newFont("assets/font-korean-pixel.ttf",size)
end
game.fonts=fonts;game.lobby=Lobby.new({},fonts)
for _,size in ipairs({{960,540},{1280,720}})do
    local w,h=size[1],size[2]
    love.graphics.getDimensions=function()return w,h end
    love.graphics.getWidth=function()return w end;love.graphics.getHeight=function()return h end
    for _,unlocked in ipairs({false,true})do
        store.data.jobMasterFire=unlocked
        Select.open(game)
        local layout=Select.layout(w,h)
        local b=layout.cards[2]
        Select.mousepressed(game,b.x+10,b.y+10,1)
        assert(game.scoreCharacterFocus==2)
        fixture.reset();Select.draw(game)
        fixture.save("docs/previews/character-select-"..w.."-"..tostring(unlocked)..".json")
        assert(layout.confirm.y+layout.confirm.h<=h and b.x+b.w<=w,"selection layout exceeds viewport")
        Select.mousepressed(game,layout.confirm.x+5,layout.confirm.y+5,1)
        assert((game.mode=="lobby")==unlocked,"mouse bypassed character lock")
    end
    fixture.reset();game.lobby:drawMenu(game,40,80,420,44,10,fonts.heading,fonts.small)
    local box=assert(game.lobby.characterSelectBox)
    assert(game.lobby:mousepressed(box.x+30,box.y+10,1)=="score_character_select","lobby selection click is not connected")
end
store.data.jobMasterFire=true;store.data.levels[id]=before
print("SCORE_CHARACTER_SELECT_OK lobby-key+click defense-removed locked+unlocked keyboard+mouse cancel real-start retry 960+1280")
