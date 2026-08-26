-- One recipe catalog for eligibility, acquisition cards, progress and HUD names.
local UI = require("src.ui")
local Fusions = {}
Fusions.definitions = {
    {id="wildfire",job="fire",name="산불",needs={"molotov","oil_drum"},color={1,.5,.18},
        desc="3초마다 꽁초를 추가 투척합니다. 붙은 불의 확산 반경이 35%, 확산 확률이 50% 증가합니다. 꽁초의 잔류·불씨 전이 과정은 유지됩니다."},
    {id="collapse",job="physical",name="벌목 붕괴",needs={"shockwave","domino"},color={1,.7,.25},
        desc="도미노로 쓰러진 나무도 같은 방향으로 다음 나무를 쓰러뜨립니다. 살아 있는 나무가 이어지는 동안 연쇄 붕괴가 계속됩니다."},
    {id="deadGround",name="죽은 땅",needs={"herbicide","root_cutting"},color={.68,.55,.86},
        desc="앞으로 베는 모든 나무의 자리가 확정적으로 불모지가 됩니다. 불·맹독·중장비로 쓰러뜨린 나무에도 적용됩니다."},
    {id="frenzy",job="physical",name="무한 야근",needs={"berserker","shockwave"},color={1,.76,.3},
        desc="10콤보부터 도끼 타격마다 반경 145의 충격파가 발생합니다. 주변 나무에 3 피해, 적에게 12 피해를 줍니다. 콤보가 끊기면 해제됩니다."},
    {id="necrosis",job="toxic",name="생태계 다이어트",needs={"toxic_rain","root_cutting"},color={.6,.85,.38},
        desc="직접 살포와 주기적 맹독 범위에 닿은 나무와 그루터기를 즉시 불모지로 만듭니다. 나무를 먼저 쓰러뜨릴 필요가 없습니다."},
    {id="newtown",job="developer",name="뉴타운 계획",needs={"heavy_machinery","site_clearance"},color={1,.65,.25},
        desc="돌진 종료 지점의 반경 160을 추가로 정지합니다. 범위 안의 나무와 그루터기는 모두 불모지가 되어 다시 자라지 않습니다."},
    {id="goldrush",job="miner",name="골드러시",needs={"deep_scan","jackpot"},color={1,.82,.25},
        desc="4초마다 근처 무작위 지점에서 자동으로 큰 굴착이 발생합니다. '발견!' 확률도 함께 오릅니다."},
}

function Fusions.forJob(mode)
    local result={}
    for _,def in ipairs(Fusions.definitions) do
        if not def.job or def.job==mode.job then result[#result+1]=def end
    end
    return result
end

function Fusions.ready(mode,def)
    if mode.evolutions[def.id] or (def.job and def.job~=mode.job) then return false end
    for _,id in ipairs(def.needs) do
        local skill=mode:getUpgradeDefinition(id)
        if not skill or mode:levelOf(id)<skill.max then return false end
    end
    return true
end

function Fusions.nextReady(mode)
    for _,def in ipairs(Fusions.definitions) do if Fusions.ready(mode,def) then return def end end
end

function Fusions.recipeText(mode,def)
    local parts={}
    for _,id in ipairs(def.needs) do
        local skill=assert(mode:getUpgradeDefinition(id),"unknown fusion ingredient: "..id)
        parts[#parts+1]=skill.name.." "..math.min(skill.max,mode:levelOf(id)).."/"..skill.max
    end
    return table.concat(parts," + ")
end

function Fusions.activeNames(mode)
    local names={}
    for _,def in ipairs(Fusions.definitions) do
        if mode.evolutions[def.id] then names[#names+1]=def.name end
    end
    return names
end

function Fusions.drawAcquisition(mode,fonts,w,h)
    local def=mode.fusionChoice
    if not def then return end
    if not w then w,h=love.graphics.getDimensions() end
    local cw,ch=math.min(760,w-48),420
    local x,y=(w-cw)/2,math.max(24,(h-ch)/2)
    UI.panel(x,y,cw,ch,def.color,.98)
    love.graphics.setFont(fonts.small);love.graphics.setColor(def.color)
    love.graphics.printf("조합 만렙 달성 · 확정 융합",x+24,y+24,cw-48,"center")
    love.graphics.setFont(fonts.title);love.graphics.setColor(1,.9,.62)
    love.graphics.printf(def.name,x+24,y+62,cw-48,"center")
    local iw=(cw-88)/2
    for i,id in ipairs(def.needs) do
        local skill=mode:getUpgradeDefinition(id)
        local ix=x+28+(i-1)*(iw+32)
        UI.panel(ix,y+132,iw,70,skill.color,.95)
        love.graphics.setFont(fonts.body);love.graphics.setColor(1,1,1)
        love.graphics.printf(skill.name,ix+8,y+142,iw-16,"center")
        love.graphics.setFont(fonts.small);love.graphics.setColor(1,.8,.35)
        love.graphics.printf("MAX · Lv."..skill.max,ix+8,y+172,iw-16,"center")
    end
    love.graphics.setFont(fonts.heading);love.graphics.setColor(1,.85,.45)
    love.graphics.printf("+",x+cw/2-16,y+150,32,"center")
    love.graphics.setFont(fonts.body);love.graphics.setColor(.86,.9,.85)
    love.graphics.printf(def.desc,x+38,y+222,cw-76,"center")
    love.graphics.setFont(fonts.small);love.graphics.setColor(.7,.8,.74)
    love.graphics.printf("재료 스킬 유지 · 추가 레벨/상자 필요 없음 · 이번 런 동안 유지",x+24,y+312,cw-48,"center")
    local box={x=x+36,y=y+348,w=cw-72,h=46}
    mode.choiceBoxes={box};mode.rerollBox=nil;mode.banishBox=nil
    local mx,my=mode:selectionMousePosition()
    UI.button(box.x,box.y,box.w,box.h,"[1 / Enter] 융합 획득",true,fonts.heading,mx,my)
end

function Fusions.drawProgress(mode,fonts,width)
    local rows=Fusions.forJob(mode)
    local w=width or love.graphics.getDimensions()
    local cw=math.min(1060,w-48)
    local x,y=(w-cw)/2,608
    UI.panel(x,y,cw,30+#rows*22,{1,.72,.24},.96)
    love.graphics.setFont(fonts.small);love.graphics.setColor(1,.83,.4)
    love.graphics.print("융합 조합 — 두 스킬 모두 MAX면 즉시 획득 카드 등장",x+14,y+7)
    for i,def in ipairs(rows) do
        local state=mode.evolutions[def.id] and "획득" or "준비"
        for _,id in ipairs(def.needs) do
            if mode.banished[id] and mode:levelOf(id)<mode:getUpgradeDefinition(id).max then state="재료 제외됨" end
        end
        love.graphics.setColor(mode.evolutions[def.id] and {1,.83,.4} or {.76,.84,.78})
        love.graphics.print("["..state.."] "..def.name.."  ·  "..Fusions.recipeText(mode,def),x+14,y+8+i*22)
    end
end

return Fusions
