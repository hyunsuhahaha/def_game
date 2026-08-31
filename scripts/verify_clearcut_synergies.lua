package.path="./?.lua;./?/init.lua;"..package.path

local function read(path)
    local file=assert(io.open(path,"rb"));local value=file:read("*a");file:close();return value
end

local source=read("src/clearcut_mode.lua")
for _,removed in ipairs({
    "clearcut_synergies","synergy_ui","Synergies.","SynergyUI.","synergyTier",
    "synergyCounts","drawSkillTracker","drawSynergyTooltip","recordSynergyFell",
    "updateSynergyBursts"
})do
    assert(not source:find(removed,1,true),"removed synergy runtime remains: "..removed)
end
assert(not io.open("src/clearcut_synergies.lua","rb"),"removed synergy rules module still exists")
assert(not io.open("src/synergy_ui.lua","rb"),"removed synergy UI module still exists")

local Mode=require("src.clearcut_mode")
local mode=Mode.new()
assert(mode.synergyCounts==nil and mode.synergyFellCounters==nil and mode.friendlyGrowthBursts==nil,
    "new runs still allocate removed synergy state")
assert(mode:skillArea("thorn_aura")==1 and mode:autoSkillCooldown("thorn_aura")==1,
    "base skill multipliers changed while removing synergy bonuses")

print("CLEARCUT_SYNERGIES_REMOVED runtime=rules+state+HUD+cards")
