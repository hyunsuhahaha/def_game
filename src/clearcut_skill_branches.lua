-- Run-local mutually exclusive attack branches: mid-rank specializations and
-- the smoker's max-rank base-weapon evolution share one guaranteed chooser.
local Branches={}
Branches.definitions={
    molotov={
        {id="vape",name="전자담배",desc="기본 공격이 빠른 청록색 증기탄 연사로 바뀝니다. 증기는 여러 나무와 몬스터를 관통하고, 기존 꽁초는 자동 패시브로 계속 떨어집니다.",color={.25,.88,.84}},
        {id="fireworks",name="폭죽 발사기",desc="기본 공격이 느린 폭죽 로켓으로 바뀝니다. 착탄하면 여러 색의 불꽃놀이가 넓게 터지고, 기존 꽁초는 자동 패시브로 계속 떨어집니다.",color={1,.48,.20}},
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
Branches.triggerLevels={molotov=6,seed_mine=3,boomerang_axe=3}
local byId={}
for skill,list in pairs(Branches.definitions)do for _,def in ipairs(list)do def.skill=skill;byId[def.id]=def end end
function Branches.forSkill(id)return Branches.definitions[id]end
function Branches.triggerLevel(id)return Branches.triggerLevels[id]end
function Branches.get(id)return byId[id]end
function Branches.active(mode,skill,id)return mode.skillBranches and mode.skillBranches[skill]==id end
return Branches
