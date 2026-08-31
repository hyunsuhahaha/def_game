-- 졸업 동료(원숭이 + 무기 프롭)를 실제 drawMoleCompanion 경로로 그려서 창 없이 검수한다.
package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local Mode=require("src.clearcut_mode")
local Art=require("src.graduate_monkey_art")

local mode=Mode.new()
-- assert(f(),msg)는 다중 반환값을 하나로 잘라먹는다. 받고 나서 확인한다.
local sprite,frames,fw,fh=Art.sprite()
assert(sprite and frames,"graduate monkey atlas missing")
local function jack(x,y,state,frameClock,attackT)
    return {kind="lumberjack",prop="axe",x=x,y=y,sprite=sprite,frames=frames,fw=fw,fh=fh,
        state=state,facing=1,walkClock=frameClock,attackT=attackT,attackDuration=.62,drawScale=.34}
end
local row={}
for i=0,5 do row[#row+1]=jack(70+i*78,120,"walk",i,0) end
for i=0,5 do row[#row+1]=jack(70+i*78,250,"attack",0,(i/6)*.62) end
row[#row+1]=jack(560,120,"walk",1,0);row[#row].facing=-1
row[#row+1]=jack(560,250,"attack",0,.31);row[#row].facing=-1
fixture.reset()
for _,companion in ipairs(row)do mode:drawMoleCompanion(companion)end
fixture.save(os.getenv("GRADUATE_MONKEY_CAPTURE") or "docs/previews/graduate-monkey-runtime-draws.json")
print("GRADUATE_MONKEY_CAPTURE_OK walk=6 swing=6 flipped=2 window=none")
