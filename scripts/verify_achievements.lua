package.path="./?.lua;./?/init.lua;"..package.path
love={filesystem={getInfo=function()return nil end,write=function()return true end,read=function()return nil end}}
local A=require("src.achievements")
local a=A.new(true)
-- 37 = 기존 27 + 벌목 기록 모드 전용 10(재생 단계 4, 세계수 2, 반복 2, 한 판 1, 누적 코인 1).
assert(#a:getDefinitions()==37,"achievement catalog must contain 37 entries")
local species=0 for _,d in ipairs(a:getDefinitions())do if d.category=="species"then species=species+1 end end
assert(species==13,"all 13 tree species need a 100-tree achievement")
for _=1,100 do a:recordTree("forest",1,"physical")end
assert(a:isUnlocked("first_cut") and a:isUnlocked("forest_100") and a:isUnlocked("species_broadleaf"),"tree achievements did not unlock")
assert(a.data.points==6,"tree achievement points incorrect")
assert(#a.queue==3,"unlock popup queue missing")
-- 기록 모드 지표. best_stage 는 캠페인 스테이지라 항상 1이어서, 이 게임의 진척 축인
-- 재생 단계가 기록되지 않으면 "최고 기록 갱신"이라는 재도전 동력이 사라진다.
local score=A.new(true)
score:recordRun({scoreAttack=true,trees=120,maxChain=4,stage=1,highestRegenTier=5,lumberCoinTotal=340})
assert(score.data.stats.best_regen_tier==5,"재생 단계가 최고 기록으로 남지 않는다")
assert(score.data.stats.runs==1 and score.data.stats.total_coins==340,"기록 모드 누적 통계가 쌓이지 않는다")
assert(score:isUnlocked("tier_3") and score:isUnlocked("tier_5"),"재생 단계 업적이 열리지 않는다")
assert(not score:isUnlocked("tier_8"),"도달하지 않은 단계 업적이 열렸다")
score:recordRun({scoreAttack=true,trees=90,maxChain=2,stage=1,highestRegenTier=3,lumberCoinTotal=200})
assert(score.data.stats.best_regen_tier==5,"최고 기록이 낮은 판에 덮어써졌다")
assert(score.data.stats.runs==2 and score.data.stats.total_coins==540,"누적이 판마다 더해지지 않는다")
local campaign=A.new(true)
campaign:recordRun({trees=50,maxChain=1,stage=2})
assert((campaign.data.stats.runs or 0)==0,"캠페인 런이 기록 모드 판수로 잡힌다")

local encoded=A.encode(a.data);local restored=A.decode(encoded)
assert(restored.stats.species_broadleaf==100 and restored.unlocked.species_broadleaf,"achievement save migration failed")
for _,map in ipairs({"forest","mangrove","madagascar","island"})do a:recordMapClear(map)end
assert(a:isUnlocked("first_operation") and a:isUnlocked("all_operations"),"operation achievements did not unlock")
local operationSave=A.decode(A.encode(a.data));assert(operationSave.clears.island and operationSave.stats.unique_operations==4,"operation clear save failed")
local migrated=A.decode("version=1\nstat_maps_seen=6\nstat_unique_operations=6\nmap_forest=1\nmap_beginner=1\nmap_greatforest=1\nclear_forest=1\nclear_beginner=1\nclear_greatforest=1\n")
assert(not migrated.maps.beginner and not migrated.clears.beginner and not migrated.maps.greatforest and not migrated.clears.greatforest and migrated.stats.maps_seen==1 and migrated.stats.unique_operations==1,"removed map survived save migration")
local ok=select(1,a:buy("brass_edge"));assert(ok and a:effects().treeDamage==1,"achievement reward purchase/effect failed")
a:setBest("best_chain",20);assert(a:isUnlocked("chain_20"),"best-stat achievement failed")
local clearcut=assert(io.open("src/clearcut_mode.lua","rb")):read("*a")
assert(clearcut:find("recordTree",1,true) and clearcut:find('add("vegan_eaten"',1,true) and clearcut:find('add("bosses"',1,true) and clearcut:find("recordMapClear",1,true),"gameplay achievement hooks missing")
print("ACHIEVEMENTS_OK total=37 species=13 operations=4 rewards=4 popup=queued save=v1 removed_map=migrated")
