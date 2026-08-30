-- Run-local mutually exclusive attack branches: mid-rank specializations and
-- the smoker's max-rank base-weapon evolution share one guaranteed chooser.
local Branches={}
Branches.definitions={
    molotov={
        {id="flame_route",name="화염 농축",desc="꽁초의 불씨 전이 범위와 확률, 비행 직격 피해, 연소 피해와 불 확산이 강해집니다. 6레벨에는 전자담배로 자동 진화합니다.",color={1,.32,.10}},
        {id="butt_volley_route",name="줄꽁초",desc="한 번 던질 때 꽁초 3개비가 부채꼴로 퍼져 각각 바닥에 남습니다. 6레벨에는 폭죽 발사기로 자동 진화합니다.",color={1,.66,.18}},
    },
    seed_mine={
        {id="heavy_mine",name="대형 지뢰",desc="폭발 반경 +42%, 피해 +35%. 더 크고 느린 한 방으로 숲 한 구역을 비웁니다.",color={.86,.55,.20}},
        {id="scatter_mine",name="산탄 지뢰",desc="본체 폭발 뒤 작은 씨앗 6개가 흩어져 짧은 지연 후 다시 폭발합니다.",color={.78,.68,.26}},
        {id="sprout_mine",name="발아 지뢰",desc="폭발 자리에 4초간 덩굴밭이 남아 나무와 적을 반복 타격합니다.",color={.42,.76,.30}},
    },
    boomerang_axe={
        {id="broad_axe",name="넓은 도끼",desc="회전 피격 폭 +45%, 피해 +18%. 화면을 넓게 쓸어냅니다.",color={.78,.72,.58}},
        {id="rapid_return",name="빠른 왕복",desc="비행 속도 +55%, 발사 주기 -35%. 짧고 빠르게 계속 왕복합니다.",color={.48,.78,.92}},
        {id="ricochet_axe",name="튕기는 도끼",desc="나가는 도중 몬스터를 맞히면 최대 3회 다른 몬스터에게 방향을 꺾습니다.",color={.82,.48,.28}},
    },
}
Branches.triggerLevels={molotov=3,seed_mine=3,boomerang_axe=3}
Branches.smokerEvolutions={
    {id="vape",skill="molotov",name="전자담배",desc="화염 농축 경로의 완성. 기본 공격이 빠른 청록색 증기탄 연사로 바뀌고 여러 나무와 몬스터를 관통합니다.",color={.25,.88,.84}},
    {id="fireworks",skill="molotov",name="폭죽 발사기",desc="줄꽁초 경로의 완성. 기본 공격이 느린 폭죽 로켓으로 바뀌고 착탄 지점에 다색 불꽃놀이가 폭발합니다.",color={1,.48,.20}},
}
Branches.smokerEvolutionByRoute={flame_route="vape",butt_volley_route="fireworks"}
local byId={}
for skill,list in pairs(Branches.definitions)do for _,def in ipairs(list)do def.skill=skill;byId[def.id]=def end end
for _,def in ipairs(Branches.smokerEvolutions)do byId[def.id]=def end
function Branches.forSkill(id)return Branches.definitions[id]end
function Branches.triggerLevel(id)return Branches.triggerLevels[id]end
function Branches.get(id)return byId[id]end
function Branches.isChoice(skill,id)for _,def in ipairs(Branches.definitions[skill]or{})do if def.id==id then return true end end return false end
function Branches.smokerEvolutionFor(route)return Branches.smokerEvolutionByRoute[route]end
function Branches.smokerEvolutionChoices()return Branches.smokerEvolutions end
function Branches.active(mode,skill,id)return mode.skillBranches and mode.skillBranches[skill]==id end
return Branches
