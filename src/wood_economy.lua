local WoodEconomy={}

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
function WoodEconomy.settlement(mapId,inventory)
    local rows,total={},0
    for _,def in ipairs(WoodEconomy.catalog(mapId))do
        local count=math.max(0,math.floor((inventory or{})[def.id]or 0))
        if count>0 then
            rows[#rows+1]={id=def.id,name=def.name,count=count,remaining=count,converted=0,coin=def.coin,color=def.color}
            total=total+count*def.coin
        end
    end
    return rows,total
end

return WoodEconomy
