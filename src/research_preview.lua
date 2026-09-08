-- Read-only purchase feedback. Values come from the same authored rank effects
-- consumed by CharacterTraits; this never modifies saves, costs or effect order.
local Preview={}
local labels={
    scoreRange={"사거리",1,""},scoreArea={"착화 반경",1,""},
    scoreProjectileSpeed={"꽁초 비행 속도",100,"%"},scoreIgnitionChance={"착화 확률",100,"%p"},
    scoreTreeDamage={"나무 피해",1,""},scoreAxeHeavy={"최대 체력 비례 피해",100,"%p"},
    scoreAxeShock={"충격파 강화",1,"단계"},scoreAxePierce={"충격파 연쇄 깊이",1,""},
    scoreAutoThrowRate={"자동 투척 간격 감소",100,"%"},
    scoreMoleClawTier={"발톱 범위 강화",1,"단계"},
    scoreMoleBurrowSpeed={"땅굴 이동속도",100,"%"},scoreMoleBurrowDamage={"땅굴 경로 피해",1,""},
    scoreMoleBurrowCooldown={"땅굴 재사용시간 감소",1,"초"},
    scoreOilSplashCount={"기름 자국 수",1,"개"},scoreOilPatchScale={"기름 자국 크기",100,"%"},
    scoreGrayCatChance={"고양이 출동 확률 보너스",100,"%p"},scoreGrayCatDelay={"고양이 대기시간 감소",1,"초"},
    scoreGrayCatSpeed={"고양이 등장 속도",100,"%"},scoreGrayCatExitSpeed={"고양이 퇴장 속도",100,"%"},
    scoreOvenHeat={"화덕 화력",100,"%"},scoreOvenSliceCost={"조각당 필요 화력 감소",1,""},
    scoreOvenDuration={"식사 지속시간",1,"초"},scoreOvenPower={"식사 효과 배율 보너스",100,"%"},
}
local unlocks={scoreAutoThrow="자동 투척 해금 · 2.6초마다 꽁초 발사",scoreRocketTwin="폭죽 쌍발 해금",
    scoreRocketCluster="폭죽 자탄 5발 해금",scoreRocketFinale="폭죽 삼단 지연 폭발 해금",scoreMoleDualClaw="두더지 양손 공격 해금"}
local function number(n)return string.format("%.2f",n):gsub("0+$",""):gsub("%.$","")end
function Preview.describe(node,level)
    if not node or not node.rankEffects or level>=node.max then return nil end
    local rank=node.rankEffects[level+1];local keys={}
    for key in pairs(rank)do keys[#keys+1]=key end
    table.sort(keys)
    local parts={}
    for _,key in ipairs(keys)do
        if unlocks[key]then parts[#parts+1]=unlocks[key]
        elseif labels[key]then
            local def=labels[key];local before=0
            for i=1,level do before=before+(node.rankEffects[i][key]or 0)end
            if key=="scoreAutoThrowRate"then
                parts[#parts+1]="자동 투척 간격 "..number(2.6/(1+before)).." → "..number(2.6/(1+before+rank[key])).."초"
            elseif key=="scoreGrayCatChance"then
                parts[#parts+1]="고양이 출동 확률 "..number(math.min(.95,.35+before)*100).." → "..number(math.min(.95,.35+before+rank[key])*100).."%"
            else
                parts[#parts+1]=def[1].." +"..number(rank[key]*def[2])..def[3]
                    .." (연구 누적 "..number(before*def[2]).." → "..number((before+rank[key])*def[2])..def[3]..")"
            end
        else return nil end
    end
    return table.concat(parts," · ")
end
return Preview
