-- Run-local trait synergies. A skill contributes each tag once as soon as it
-- is learned; additional ranks strengthen the skill but do not inflate traits.
local Synergies={}

Synergies.skillTags={
    wide_blade={"impact","momentum"},berserker={"momentum","impact"},shockwave={"impact","field"},
    molotov={"ignition","momentum"},dry_forest={"ignition","field"},oil_drum={"ignition","impact"},
    straw_bale={"ignition","field"},smoke_ring={"field","momentum"},
    fork_feast={"harvest","impact"},buffet_fork={"harvest","momentum"},clean_plate={"harvest","field"},
    seconds_please={"harvest","momentum"},forced_growth={"growth","harvest"},
    pile_driving={"impact","momentum"},heavy_machinery={"impact","momentum"},demolition={"impact","ignition"},
    site_clearance={"field","impact"},detector={"impact","momentum"},burrow_uproot={"impact","field"},
    brute_force={"momentum","impact"},monologue={"field","momentum"},revival_meeting={"field","growth"},
    footnote={"momentum","field"},loud_voice={"field","impact"},saliva_gland={"growth","field"},
    bat_swarm={"wild","momentum"},thorn_aura={"growth","field"},crow_strike={"wild","momentum"},
    vine_whip={"growth","impact"},boomerang_axe={"momentum","impact"},seed_mine={"growth","field"},
    chain_lightning={"momentum","impact"},
}

Synergies.definitions={
    {id="wild",name="야생",color={.72,.52,.86},thresholds={2},
        text={[2]="박쥐·까마귀의 공격 주기 -22%, 피해 +18%"}},
    {id="growth",name="생장",color={.48,.82,.32},thresholds={2,4},
        text={[2]="생장 스킬 범위 +14%, 12그루마다 발아 파동",[4]="발아 파동이 7그루마다 더 넓고 강하게 발생"}},
    {id="momentum",name="기동",color={.42,.78,.92},thresholds={2,4},
        text={[2]="공용 자동 스킬 주기 -10%, 투사체 속도 +10%",[4]="공용 자동 스킬 주기 -25%, 투사체 속도 +25%"}},
    {id="field",name="장판",color={.66,.72,.38},thresholds={2,4},
        text={[2]="장판 태그 공용 스킬 범위 +12%",[4]="범위 +28%, 지속 피해 주기 -28%"}},
    {id="impact",name="강타",color={1,.58,.24},thresholds={2,4},
        text={[2]="공용 자동 스킬 피해 +12%, 12그루마다 벌목 충격파",[4]="공용 자동 스킬 피해 +28%, 충격파가 7그루마다 강화"}},
    {id="ignition",name="점화",color={1,.36,.12},thresholds={2,4},
        text={[2]="불씨 전이 확률 +18%, 범위 +14%",[4]="불씨 전이 확률 +38%, 범위 +32%"}},
    {id="harvest",name="수확",color={.92,.78,.30},thresholds={2,4},
        text={[2]="목재 경험치 +12%",[4]="목재 경험치 +28%"}},
}

local byId={}
for _,def in ipairs(Synergies.definitions)do byId[def.id]=def end

function Synergies.attach(definitions)
    for _,def in ipairs(definitions)do def.tags=Synergies.skillTags[def.id] or {} end
end

function Synergies.counts(mode)
    local counts={}
    for id,level in pairs(mode.levels or {})do
        if level>0 then for _,tag in ipairs(Synergies.skillTags[id] or {})do counts[tag]=(counts[tag] or 0)+1 end end
    end
    return counts
end

function Synergies.tier(mode,id)
    local counts=Synergies.counts(mode);mode.synergyCounts=counts
    local count=counts[id] or 0
    local tier=0;local def=byId[id]
    if def then for _,threshold in ipairs(def.thresholds)do if count>=threshold then tier=threshold end end end
    return tier,count
end

function Synergies.refresh(mode) mode.synergyCounts=Synergies.counts(mode);return mode.synergyCounts end
function Synergies.forTag(id)return byId[id]end
function Synergies.tagsFor(id)return Synergies.skillTags[id] or {}end
function Synergies.previewCount(mode,skill,tag)
    local current=(mode.synergyCounts or Synergies.counts(mode))[tag] or 0
    return current,current+(mode:levelOf(skill)>0 and 0 or 1)
end
function Synergies.nextThreshold(id,count)
    local def=byId[id];if not def then return nil end
    for _,threshold in ipairs(def.thresholds)do if threshold>count then return threshold end end
    return def.thresholds[#def.thresholds]
end

function Synergies.cooldownMultiplier(mode)
    local tier=Synergies.tier(mode,"momentum");return tier>=4 and .75 or (tier>=2 and .90 or 1)
end
function Synergies.projectileSpeedMultiplier(mode)
    local tier=Synergies.tier(mode,"momentum");return tier>=4 and 1.25 or (tier>=2 and 1.10 or 1)
end
function Synergies.areaMultiplier(mode,id)
    local value=1
    local growth=Synergies.tier(mode,"growth")
    local field=Synergies.tier(mode,"field")
    local tags=Synergies.skillTags[id] or {}
    for _,tag in ipairs(tags)do
        if tag=="growth" and growth>=2 then value=value*1.14 end
        if tag=="field" then value=value*(field>=4 and 1.28 or (field>=2 and 1.12 or 1)) end
    end
    return value
end
function Synergies.damageMultiplier(mode,id)
    local impact=Synergies.tier(mode,"impact")
    local wild=Synergies.tier(mode,"wild")
    local value=impact>=4 and 1.28 or (impact>=2 and 1.12 or 1)
    for _,tag in ipairs(Synergies.skillTags[id] or {})do if tag=="wild" and wild>=2 then value=value*1.18 end end
    return value
end
function Synergies.tickMultiplier(mode)
    local tier=Synergies.tier(mode,"field");return tier>=4 and .72 or 1
end
function Synergies.wildCooldownMultiplier(mode)return Synergies.tier(mode,"wild")>=2 and .78 or 1 end
function Synergies.woodXpMultiplier(mode)
    local tier=Synergies.tier(mode,"harvest");return tier>=4 and 1.28 or (tier>=2 and 1.12 or 1)
end
function Synergies.ignitionChanceMultiplier(mode)
    local tier=Synergies.tier(mode,"ignition");return tier>=4 and 1.38 or (tier>=2 and 1.18 or 1)
end
function Synergies.ignitionRadiusMultiplier(mode)
    local tier=Synergies.tier(mode,"ignition");return tier>=4 and 1.32 or (tier>=2 and 1.14 or 1)
end

return Synergies
