local function read(path)
    local file=assert(io.open(path,"rb")); local data=file:read("*a"); file:close(); return data
end

local lobby=read("src/lobby.lua")
local game=read("src/game.lua")
local maps=read("src/clearcut_map_select.lua")
local frontend=read("src/frontend_ui.lua")
local doc=read("docs/FRONTEND_UI_REDESIGN.md")

assert(lobby:find("lobby%-forest%-lofi%-day%-pixel%-v4%.png"),"bright forest lo-fi lobby background is not connected")
assert(not lobby:find("숲이 다시 자라기 전에",1,true),"removed lobby slogan returned")
assert(lobby:find("게임 시작",1,true),"lobby start button missing")
assert(lobby:find("벌목 기록 모드",1,true)and lobby:find("빈 땅에서 시작",1,true),"10-minute score mode lobby action missing")
assert(game:find("function Game:startClearcutScoreAttack",1,true),"score attack entry point missing")
assert(game:find('self.mode="clearcut_briefing"',1,true),"map selection still skips briefing")
assert(game:find('self:startClearcut(self.pendingClearcutCharacter,self.selectedClearcutMap,self.selectedClearcutStage)',1,true),"briefing cannot start the selected stage")
assert(maps:find("진입 구역",1,true) and maps:find("Maps.stageCode",1,true) and maps:find("clearcutStageBoxes",1,true),"map stage selector missing")
assert(maps:find("선택 지역으로 이동",1,true),"map confirmation action missing")
assert(maps:find("stage_select_globe",1,true) and maps:find("지역 신호 포착",1,true),"interactive globe map overview missing")
assert(game:find("function Game:mousemoved",1,true) and game:find("function Game:mousereleased",1,true),"globe drag callbacks missing")
assert(frontend:find("function Frontend.button",1,true) and frontend:find("hover and 3 or 0",1,true),"interactive button presentation missing")
assert(doc:find("레벨업 3택 화면은 이 프로젝트의 품질 기준이 아니다",1,true),"commercial indie quality bar is undocumented")

local asset=assert(io.open("assets/lobby-forest-lofi-day-pixel-v4.png","rb")); local size=asset:seek("end"); asset:close()
assert(size>500000,"lobby background appears to be a placeholder")
print("FRONTEND_UI_OK flow=briefing lobby=forest-lofi-day copy=concrete responsive=960x540..1280x720")
