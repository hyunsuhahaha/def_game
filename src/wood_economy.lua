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
-- 재생 단계는 난이도만 올리고 보상은 그대로였다. 인크리멘탈의 프레스티지는 "더 어려운
-- 판을 여는 대신 수입이 오르는" 거래인데 앞의 절반만 있었던 셈이다. 시작 단계가 그
-- 판의 영구 등급이고, 이번 판에 올린 단계는 밀어붙인 보너스다.
--
--   배수 = 1 + (시작 단계 - 1) x 0.15 + (이번 판 상승 단계) x 0.10
--
-- 1단계는 x1.00 이라 초반 밸런스는 그대로다. 6단계 x1.75, 10단계 x2.35.
WoodEconomy.tierIncomeStep=.15
WoodEconomy.tierPushStep=.10

function WoodEconomy.tierMultiplier(startTier,highestTier)
    local start=math.max(1,math.floor(startTier or 1))
    local gained=math.max(0,math.floor((highestTier or start)-start))
    return 1+(start-1)*WoodEconomy.tierIncomeStep+gained*WoodEconomy.tierPushStep
end

-- 배수를 개당 코인에 곱하면 정수 반올림에 먹힌다. 활엽수는 개당 2코인이라 x1.15가
-- 2.3 -> 2로 깎여 1단계와 수입이 같아진다. 그래서 수종 행은 기본 단가로 두고 배수는
-- 별도 보너스 행으로 뺀다. 정산 연출에서 "재생 단계 보너스"가 직접 세어지므로
-- 단계를 올릴 이유가 플레이어에게 그대로 보인다.
function WoodEconomy.settlement(mapId,inventory,startTier,highestTier)
    local rows,base={},0
    for _,def in ipairs(WoodEconomy.catalog(mapId))do
        local count=math.max(0,math.floor((inventory or{})[def.id]or 0))
        if count>0 then
            local coin=def.coin*WoodEconomy.researchCoinMultiplier
            rows[#rows+1]={id=def.id,name=def.name,count=count,remaining=count,converted=0,coin=coin,color=def.color}
            base=base+count*coin
        end
    end
    local multiplier=WoodEconomy.tierMultiplier(startTier,highestTier)
    local bonus=math.floor(base*(multiplier-1)+.5)
    if bonus>0 then
        rows[#rows+1]={id="tier_bonus",name="재생 단계 보너스",count=bonus,remaining=bonus,converted=0,coin=1,
            color={.98,.80,.32},bonus=true}
    end
    return rows,base+bonus,multiplier
end

return WoodEconomy
