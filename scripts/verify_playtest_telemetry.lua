package.path="./?.lua;./?/init.lua;"..package.path

local files={}
love={filesystem={
    getInfo=function(path)return files[path]and{}or nil end,
    append=function(path,text)files[path]=(files[path]or"")..text;return true end,
}}

local Telemetry=require("src.playtest_telemetry")
local mode={permanentTraits={scoreRocketUnlock=1},actionAudit={scoreAxe=3,fireworkShot=7,bombExplosion=2}}
local traits={scoreProgress=function()return 31,100 end,getRegenTier=function()return 6 end}
local telemetry=Telemetry.new(mode,traits,"test")
telemetry:frame(1/60);telemetry:frame(1/20);telemetry:input("key","space");telemetry:input("mouse",1)
local result={startingRegenTier=5,highestRegenTier=7,elapsed=123.4,trees=88,lumberCoinTotal=900,
    totalTreesSpawned=101,peakActiveTrees=18,treeAllowance=20,peakTreesPerSecond=9,failureReason="score_overcrowded"}
assert(telemetry:finish(result),"telemetry did not append")
assert(not telemetry:finish(result),"telemetry appended the same run twice")
local output=files[Telemetry.FILE]
assert(output:find("research_pct",1,true)and output:find("firework",1,true)and output:find(",6,5,7,",1,true),"CSV header, build, or tiers missing")
assert(select(2,output:gsub("\n",""))==2,"CSV should contain one header and one run")
print("PLAYTEST_TELEMETRY_OK one-row-per-run raw-frame-sampling local-only")
