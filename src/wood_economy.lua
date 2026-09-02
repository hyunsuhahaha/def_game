local WoodEconomy={}

-- 짧아진 기록 모드 한 판으로도 로비 연구를 실제 구매할 수 있도록, 모든 수종의
-- 목재→연구 코인 변환 단가에 동일한 전역 배율을 적용한다.
WoodEconomy.researchCoinMultiplier=2

local catalogs={
    forest={
        {id="broadleaf",name="활엽수 목재",coin=1,color={.72,.45,.20}},
        {id="pine",name="소나무 목재",coin=1,color={.56,.42,.20}},
        {id="birch",name="자작나무 목재",coin=2,color={.86,.80,.63}},
        {id="maple",name="단풍나무 목재",coin=2,color={.82,.34,.17}},
    },
    mangrove={
        {id="mangrove",name="맹그로브 목재",coin=2,color={.48,.33,.18}},
        {id="avicennia",name="아비케니아 목재",coin=2,color={.64,.55,.38}},
        {id="nypa",name="니파야자 목재",coin=3,color={.70,.54,.21}},
    },
    madagascar={
        {id="baobab",name="바오밥 목재",coin=3,color={.76,.53,.27}},
        {id="tamarind",name="타마린드 목재",coin=2,color={.46,.29,.16}},
        {id="commiphora",name="코미포라 목재",coin=3,color={.72,.43,.23}},
    },
    island={
        {id="palm",name="야자 목재",coin=2,color={.68,.48,.18}},
        {id="seaalmond",name="씨아몬드 목재",coin=3,color={.59,.34,.18}},
        {id="pandanus",name="판다누스 목재",coin=3,color={.78,.60,.24}},
    },
}

function WoodEconomy.catalog(mapId)return catalogs[mapId]or catalogs.forest end
function WoodEconomy.forTree(mapId,variant)
    local list=WoodEconomy.catalog(mapId)
    return list[math.max(1,math.min(#list,math.floor(variant or 1)))]
end
-- 실제 1단계 약 20코인, 기존 8단계 약 2,600코인에는 나무 공급량 증가가 이미 들어 있다.
-- 총수입 목표를 단계마다 약 2.6배로 잡고 그 공급량 증가를 제외하면, 목재 단가 쪽은
-- 단계마다 1.44배가 맞다. 시작 단계나 한 판의 최고 단계가 아니라 나무를 벤 순간의
-- 재생 단계만 사용한다.
WoodEconomy.tierIncomeGrowth=1.44

function WoodEconomy.tierMultiplier(tier)
    tier=math.max(1,math.floor(tier or 1))
    return WoodEconomy.tierIncomeGrowth^(tier-1)
end

-- 배수를 개당 코인에 곱하면 정수 반올림에 먹힌다. 활엽수는 개당 2코인이라 2단계의
-- 2.88이 3으로 왜곡된다. 그래서 수종 행은 기본 단가로 두고 배수는
-- 별도 보너스 행으로 뺀다. 정산 연출에서 "재생 단계 보너스"가 직접 세어지므로
-- 단계를 올릴 이유가 플레이어에게 그대로 보인다.
function WoodEconomy.settlementByTier(mapId,inventoriesByTier,fallbackTier,runBonus)
    local rows,base,bonusTotal={},0,0
    local totals={}
    for _,def in ipairs(WoodEconomy.catalog(mapId))do
        local count=0
        for _,inventory in pairs(inventoriesByTier or{})do
            count=count+math.max(0,math.floor((inventory or{})[def.id]or 0))
        end
        if count>0 then
            local coin=def.coin*WoodEconomy.researchCoinMultiplier
            rows[#rows+1]={id=def.id,name=def.name,count=count,remaining=count,converted=0,coin=coin,color=def.color}
            base=base+count*coin
            totals[def.id]=coin
        end
    end

    local tiers={}
    for tier in pairs(inventoriesByTier or{})do tiers[#tiers+1]=math.max(1,math.floor(tonumber(tier)or fallbackTier or 1)) end
    table.sort(tiers)
    for _,tier in ipairs(tiers)do
        local tierBase=0
        for id,coin in pairs(totals)do
            tierBase=tierBase+math.max(0,math.floor((inventoriesByTier[tier]or{})[id]or 0))*coin
        end
        local multiplier=WoodEconomy.tierMultiplier(tier)+(runBonus or 0)
        local bonus=math.floor(tierBase*(multiplier-1)+.5)
        if bonus>0 then
            rows[#rows+1]={id="tier_bonus_"..tier,name="재생 "..tier.."단계 보너스",count=bonus,remaining=bonus,converted=0,coin=1,
                color={.98,.80,.32},bonus=true,tier=tier}
            bonusTotal=bonusTotal+bonus
        end
    end
    local effective=base>0 and(base+bonusTotal)/base or WoodEconomy.tierMultiplier(fallbackTier)
    return rows,base+bonusTotal,effective
end

-- 오래된 테스트·세이브처럼 단계별 재고가 없는 호출은 최고 도달 단계의 재고로 정산한다.
function WoodEconomy.settlement(mapId,inventory,startTier,highestTier,runBonus)
    local tier=math.max(1,math.floor(highestTier or startTier or 1))
    return WoodEconomy.settlementByTier(mapId,{[tier]=inventory or{}},tier,runBonus)
end

return WoodEconomy
