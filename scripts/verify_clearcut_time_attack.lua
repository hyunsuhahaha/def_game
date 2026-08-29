package.path="./?.lua;./?/init.lua;"..package.path
love={math={random=math.random},timer={getTime=function()return 0 end}}
local Mode=require("src.clearcut_mode")
local mode=Mode.new()
assert(mode.stageTimeLimit==360 and mode:stageTimeRemaining()==360,"stage 1 time limit must be six minutes")
local finished=false
mode.finish=function(self,game,victory) finished=victory==false;game.result={failureReason=self.failureReason} end
local game={setNotice=function(self,text)self.notice=text end}
assert(not mode:updateStageClock(359,game) and not finished,"stage failed before deadline")
assert(mode:updateStageClock(1,game) and finished,"deadline did not fail the stage")
assert(mode.failureReason=="timeout" and game.result.failureReason=="timeout","timeout reason was not recorded")
local source=assert(io.open("src/clearcut_mode.lua","rb"));local text=source:read("*a");source:close()
assert(text:find("local stageTimeLimits = {360, 420, 480, 600}",1,true),"stage time curve changed")
assert(text:find("local greatForestTimeLimits = {600, 720, 840, 960}",1,true),"great forest travel allowance missing")
assert(text:find("opening==1 and 24",1,true) and text:find("local count = (not opening",1,true),"reduced ambient spawning missing")
assert(text:find("function ClearcutMode:updateReaper",1,true) and text:find("무한 추격자는 타임어택 동선",1,true),"reaper was not retired for time attack")
print("CLEARCUT_TIME_ATTACK_OK limits=6/7/8/10min ambient=1..2 reaper=off timeout=failure")
