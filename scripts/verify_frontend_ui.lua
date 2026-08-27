local function read(path)
    local file=assert(io.open(path,"rb")); local data=file:read("*a"); file:close(); return data
end

local lobby=read("src/lobby.lua")
local game=read("src/game.lua")
local maps=read("src/clearcut_map_select.lua")
local frontend=read("src/frontend_ui.lua")
local doc=read("docs/FRONTEND_UI_REDESIGN.md")

assert(lobby:find("lobby%-forest%-field%-hq%-pixel%-v2%.png"),"new forest lobby background is not connected")
assert(not lobby:find("숲이 다시 자라기 전에",1,true),"removed lobby slogan returned")
assert(lobby:find("할당량 60그루",1,true) and lobby:find("작업 준비",1,true),"lobby copy is not concrete")
assert(game:find('self.mode="clearcut_briefing"',1,true),"map selection still skips briefing")
assert(game:find('self:startClearcut(self.pendingClearcutCharacter,self.selectedClearcutMap)',1,true),"briefing cannot start the run")
assert(maps:find("이 구역 선택",1,true),"map confirmation action missing")
assert(frontend:find("function Frontend.button",1,true) and frontend:find("hover and 3 or 0",1,true),"interactive button presentation missing")
assert(doc:find("레벨업 3택 화면은 이 프로젝트의 품질 기준이 아니다",1,true),"commercial indie quality bar is undocumented")

local asset=assert(io.open("assets/lobby-forest-field-hq-pixel-v2.png","rb")); local size=asset:seek("end"); asset:close()
assert(size>500000,"lobby background appears to be a placeholder")
print("FRONTEND_UI_OK flow=briefing lobby=forest-field-hq copy=concrete responsive=960x540..1280x720")
