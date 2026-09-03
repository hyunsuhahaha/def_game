local Achievements={};Achievements.__index=Achievements
local SafeSave=require("src.safe_save")

local species={
 {key="broadleaf",name="활엽수"},{key="pine",name="소나무"},{key="birch",name="자작나무"},{key="maple",name="단풍나무"},
 {key="mangrove",name="맹그로브"},{key="avicennia",name="아비케니아"},{key="nypa",name="니파야자"},
 {key="baobab",name="바오밥"},{key="tamarind",name="타마린드"},{key="commiphora",name="코미포라"},
 {key="palm",name="야자나무"},{key="seaalmond",name="씨아몬드"},{key="pandanus",name="판다누스"},
}
local mapSpecies={forest={"broadleaf","pine","birch","maple"},mangrove={"mangrove","avicennia","nypa"},madagascar={"baobab","tamarind","commiphora"},island={"palm","seaalmond","pandanus"}}
local validMaps={forest=true,mangrove=true,madagascar=true,island=true}
local definitions={
 {id="first_cut",name="첫 출근",desc="나무를 처음 쓰러뜨렸다.",stat="total_trees",goal=1,points=1,category="field",icon="axe"},
 {id="forest_100",name="숲 한 구역분",desc="누적 나무 100그루를 쓰러뜨린다.",stat="total_trees",goal=100,points=2,category="field",icon="rings"},
 {id="forest_1000",name="그루터기 천지",desc="누적 나무 1,000그루를 쓰러뜨린다.",stat="total_trees",goal=1000,points=5,category="field",icon="rings"},
 {id="forest_5000",name="위성사진이 달라졌다",desc="누적 나무 5,000그루를 쓰러뜨린다.",stat="total_trees",goal=5000,points=12,category="field",icon="crown"},
 {id="run_200",name="퇴근은 없다",desc="한 번의 작업에서 200그루를 쓰러뜨린다.",stat="best_run_trees",goal=200,points=4,category="challenge",icon="axe"},
 {id="chain_20",name="도미노 벌목",desc="연쇄 벌목 20회를 기록한다.",stat="best_chain",goal=20,points=4,category="challenge",icon="spark"},
 {id="stage_4",name="숲의 안쪽",desc="한 번의 작업에서 4단계에 도달한다.",stat="best_stage",goal=4,points=5,category="challenge",icon="map"},
 {id="boss_10",name="생태계 민원 처리",desc="보스를 누적 10마리 쓰러뜨린다.",stat="bosses",goal=10,points=5,category="challenge",icon="crown"},
 {id="fire_500",name="재떨이 없는 숲",desc="흡연자로 나무 500그루를 태우거나 벤다.",stat="job_fire_trees",goal=500,points=5,category="character",icon="fire"},
 {id="vegan_100",name="샐러드바 단골",desc="비건 단체 회장으로 나무 100그루를 먹는다.",stat="vegan_eaten",goal=100,points=4,category="character",icon="fork"},
 {id="miner_300",name="뿌리째 계산",desc="코인 채굴꾼으로 나무 300그루를 처리한다.",stat="job_miner_trees",goal=300,points=4,category="character",icon="claw"},
 {id="all_maps",name="전국 출장",desc="서로 다른 벌목 구역 4곳에서 작업한다.",stat="maps_seen",goal=4,points=6,category="collection",icon="map"},
 {id="first_operation",name="철수로 확보",desc="지역 최종 작전을 처음 완료한다.",stat="operations_cleared",goal=1,points=5,category="challenge",icon="crown"},
 {id="all_operations",name="전국 강제집행",desc="서로 다른 지역 최종 작전 4개를 완료한다.",stat="unique_operations",goal=4,points=15,category="collection",icon="map"},
 -- 벌목 기록 모드 전용. 기존 업적은 대부분 캠페인 작전 기반이라 기록 모드에서는
 -- 달성할 수 없었다. 재생 단계·세계수·반복 플레이를 목표로 세운다.
 {id="tier_3",name="두 번째 숲",desc="재생 3단계에 도달한다.",stat="best_regen_tier",goal=3,points=2,category="challenge",icon="rings"},
 {id="tier_5",name="숲이 되받아친다",desc="재생 5단계에 도달한다.",stat="best_regen_tier",goal=5,points=4,category="challenge",icon="rings"},
 {id="tier_8",name="통제선 붕괴",desc="재생 8단계에 도달한다.",stat="best_regen_tier",goal=8,points=8,category="challenge",icon="crown"},
 {id="tier_12",name="숲이 이긴 적 없다",desc="재생 12단계에 도달한다.",stat="best_regen_tier",goal=12,points=20,category="challenge",icon="crown"},
 {id="world_tree_1",name="첫 세계수",desc="세계수를 처음 쓰러뜨린다.",stat="world_trees",goal=1,points=2,category="field",icon="tree"},
 {id="world_tree_25",name="세계수 벌목반",desc="세계수를 누적 25그루 쓰러뜨린다.",stat="world_trees",goal=25,points=6,category="field",icon="tree"},
 {id="runs_25",name="출근 도장 25개",desc="벌목 기록 모드를 25번 마친다.",stat="runs",goal=25,points=3,category="field",icon="clock"},
 {id="runs_100",name="이 일이 천직이다",desc="벌목 기록 모드를 100번 마친다.",stat="runs",goal=100,points=8,category="field",icon="clock"},
 {id="run_600",name="하루에 다 밀었다",desc="한 번의 작업에서 600그루를 쓰러뜨린다.",stat="best_run_trees",goal=600,points=8,category="challenge",icon="crown"},
 {id="coins_10000",name="목재 재벌",desc="누적 연구 코인 10,000을 번다.",stat="total_coins",goal=10000,points=10,category="collection",icon="rings"},
}
for _,s in ipairs(species) do definitions[#definitions+1]={id="species_"..s.key,name=s.name.." 전문반",desc=s.name.."를 누적 100그루 쓰러뜨린다.",stat="species_"..s.key,goal=100,points=3,category="species",icon="tree"} end

local rewards={
 {id="brass_edge",name="황동 숫돌",desc="도끼·발톱 피해 +1",cost=5,icon="axe"},
 {id="field_flask",name="찌그러진 물통",desc="최대 체력 +10",cost=7,icon="medal"},
 {id="haul_badge",name="목재 검수 도장",desc="목재 획득량 +8%",cost=9,icon="rings"},
 {id="compass_pin",name="현장반 나침반",desc="이동 속도 +5%",cost=12,icon="map"},
}
local byId,rewardById={},{}
for _,d in ipairs(definitions) do byId[d.id]=d end
for _,d in ipairs(rewards) do rewardById[d.id]=d end
local function defaults() return {points=0,stats={},unlocked={},purchased={},maps={},clears={}} end
local function clampInt(v)return math.max(0,math.floor(tonumber(v) or 0))end
function Achievements.decode(text)
 local d=defaults()
 for k,v in (text or ""):gmatch("([%w_]+)=([%d]+)") do local n=clampInt(v)
  if k=="points" then d.points=n elseif k:match("^stat_") then d.stats[k:sub(6)]=n elseif k:match("^unlock_") and byId[k:sub(8)] then d.unlocked[k:sub(8)]=n>0 elseif k:match("^buy_") and rewardById[k:sub(5)] then d.purchased[k:sub(5)]=n>0 elseif k:match("^map_") and validMaps[k:sub(5)] then d.maps[k:sub(5)]=n>0 elseif k:match("^clear_") and validMaps[k:sub(7)] then d.clears[k:sub(7)]=n>0 end
 end
 local maps,clears=0,0;for _ in pairs(d.maps)do maps=maps+1 end;for _ in pairs(d.clears)do clears=clears+1 end
 d.stats.maps_seen,d.stats.unique_operations=maps,clears
 return d
end
function Achievements.encode(d)
 local out={"version=1","points="..clampInt(d.points)}
 local function sorted(t,prefix,bool) local keys={} for k in pairs(t or {}) do keys[#keys+1]=k end table.sort(keys);for _,k in ipairs(keys) do out[#out+1]=prefix..k.."="..(bool and (t[k] and 1 or 0) or clampInt(t[k])) end end
 sorted(d.stats,"stat_",false);sorted(d.unlocked,"unlock_",true);sorted(d.purchased,"buy_",true);sorted(d.maps,"map_",true);sorted(d.clears,"clear_",true)
 return table.concat(out,"\n").."\n"
end
function Achievements.new(memoryOnly)
 local self=setmetatable({memoryOnly=memoryOnly,file="achievements.sav",data=defaults(),queue={},popup=nil,time=0},Achievements)
 local text=not memoryOnly and SafeSave.read(self.file)or nil;if text then self.data=Achievements.decode(text)end
 return self
end
function Achievements:save()if self.memoryOnly then return true end return SafeSave.write(self.file,Achievements.encode(self.data))end
function Achievements:getDefinitions()return definitions end
function Achievements:getRewards()return rewards end
function Achievements:progress(def)return math.min(def.goal,self.data.stats[def.stat] or 0)end
function Achievements:isUnlocked(id)return self.data.unlocked[id]==true end
function Achievements:check()
 local gained={}
 for _,def in ipairs(definitions) do if not self.data.unlocked[def.id] and (self.data.stats[def.stat] or 0)>=def.goal then self.data.unlocked[def.id]=true;self.data.points=self.data.points+def.points;self.queue[#self.queue+1]=def;gained[#gained+1]=def end end
 if #gained>0 then self:save() end return gained
end
function Achievements:add(stat,amount) self.data.stats[stat]=clampInt((self.data.stats[stat] or 0)+(amount or 1));local g=self:check();self:save();return g end
function Achievements:setBest(stat,value)self.data.stats[stat]=math.max(self.data.stats[stat] or 0,clampInt(value));local g=self:check();self:save();return g end
function Achievements:recordTree(mapId,variant,job)
 local keys=mapSpecies[mapId] or mapSpecies.forest;local key=keys[math.max(1,math.min(#keys,variant or 1))]
 self.data.stats.total_trees=(self.data.stats.total_trees or 0)+1
 self.data.stats["species_"..key]=(self.data.stats["species_"..key] or 0)+1
 if job then self.data.stats["job_"..job.."_trees"]=(self.data.stats["job_"..job.."_trees"] or 0)+1 end
 if validMaps[mapId] and not self.data.maps[mapId] then self.data.maps[mapId]=true;local n=0 for _ in pairs(self.data.maps)do n=n+1 end self.data.stats.maps_seen=n end
 local g=self:check();if (self.data.stats.total_trees or 0)%10==0 then self:save() end;return g
end
-- best_stage 는 캠페인 스테이지라 기록 모드에서는 항상 1이다. 이 게임의 진척 축인
-- 재생 단계가 기록되지 않아 "최고 기록 갱신"이라는 재도전 동력이 없었다.
function Achievements:recordRun(r)
 self:setBest("best_run_trees",r.trees or 0);self:setBest("best_chain",r.maxChain or 0);self:setBest("best_stage",r.stage or 0)
 if r.scoreAttack then
  self:setBest("best_regen_tier",r.highestRegenTier or r.regenTier or 1)
  self:setBest("best_run_coins",r.lumberCoinTotal or 0)
  self.data.stats.runs=clampInt((self.data.stats.runs or 0)+1)
  self.data.stats.total_coins=clampInt((self.data.stats.total_coins or 0)+(r.lumberCoinTotal or 0))
  self:check();self:save()
 end
end
function Achievements:recordMapClear(mapId)
 if not validMaps[mapId] then return {} end
 self.data.stats.operations_cleared=(self.data.stats.operations_cleared or 0)+1
 if not self.data.clears[mapId] then self.data.clears[mapId]=true;local n=0 for _ in pairs(self.data.clears)do n=n+1 end self.data.stats.unique_operations=n end
 local g=self:check();self:save();return g
end
function Achievements:isMapCleared(mapId)return self.data.clears[mapId]==true end
function Achievements:buy(id)
 local r=rewardById[id];if not r then return false,"존재하지 않는 보상" end
 if self.data.purchased[id] then return false,"이미 진열한 보상" end
 if self.data.points<r.cost then return false,"업적 포인트 "..r.cost.." P 필요" end
 self.data.points=self.data.points-r.cost;self.data.purchased[id]=true;self:save();return true,r.name.." 진열 완료"
end
function Achievements:effects()return {treeDamage=self.data.purchased.brass_edge and 1 or 0,maxHp=self.data.purchased.field_flask and 10 or 0,woodYield=self.data.purchased.haul_badge and 1.08 or 1,moveSpeed=self.data.purchased.compass_pin and 1.05 or 1}end
function Achievements:update(dt)
 self.time=self.time+dt
 if not self.popup and #self.queue>0 then self.popup={def=table.remove(self.queue,1),t=0,dur=4.2} end
 if self.popup then self.popup.t=self.popup.t+dt;if self.popup.t>=self.popup.dur then self.popup=nil end end
end
function Achievements:unlockedCount()local n=0 for _ in pairs(self.data.unlocked)do n=n+1 end return n end
function Achievements:reset()self.data=defaults();self.queue={};self.popup=nil;self:save()end
Achievements.species=species
return Achievements
