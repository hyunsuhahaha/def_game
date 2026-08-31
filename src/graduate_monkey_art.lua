-- 무기 졸업 동료의 공용 몸체. 모든 졸업 동료는 같은 원숭이를 쓰고 손에 든 무기만
-- 다르다. 그래서 몸체 아틀라스에는 무기를 굽지 않고, 무기는 프레임별 손 앵커에 붙이는
-- 별도 프롭으로 그린다(AGENTS.md의 장비 규칙). 졸업 동료를 추가할 때는 프롭만 그린다.
--
-- 몸체 자산: 사용자가 고른 3안 원본을 고정 모델로 쓰는 scripts/build_graduate_monkey_selected.py
-- 장비 자산: scripts/build_graduate_monkey.py (몸체와 독립)
local Art = {}

local CELL, PX, FOOT = 128, 2, 118
local PROP = 64

-- {손 앵커 x, y (그리드), 프롭 각도(라디안)}. 빌드 스크립트가 출력한 값 그대로다.
local POSE = {
    walk = {{44,42,0},{44,41,0},{44,42,0},{44,43,0},{44,41,0},{44,42,0}},
    axe = {{45,42,-.35},{45,41,-.95},{56,31,-1.55},{56,31,.75},{40,42,1.45},{45,42,.15}},
    cigarette = {{45,42,-.2},{45,41,-.45},{45,41,-.6},{40,42,.05},{40,42,.15},{45,42,0}},
    firework = {{40,42,-.15},{40,42,-.25},{56,31,-.3},{56,31,-.15},{40,42,-.05},{45,42,-.15}},
}
local PROPS = {
    axe={row=0,gripX=9*PX,gripY=26*PX},
    cigarette={row=1,gripX=7*PX,gripY=18*PX},
    firework={row=2,gripX=10*PX,gripY=21*PX},
}

local body, props, frames, propQuads

local function load()
    if body then return true end
    local ok, image = pcall(love.graphics.newImage, "assets/characters/companions/graduate-monkey-atlas-pixel-v3.png")
    if not ok then return false end
    local okProps, propImage = pcall(love.graphics.newImage, "assets/characters/companions/graduate-monkey-props-pixel-v2.png")
    if not okProps then return false end
    image:setFilter("nearest", "nearest")
    propImage:setFilter("nearest", "nearest")
    body, props = image, propImage
    frames = {walk={},axe={},cigarette={},firework={}}
    local rows={walk=0,axe=1,cigarette=2,firework=3}
    for name,row in pairs(rows)do
        for i=0,5 do frames[name][i+1]=love.graphics.newQuad(i*CELL,row*CELL,CELL,CELL,image:getDimensions())end
    end
    propQuads = {}
    for name, spec in pairs(PROPS) do
        propQuads[name] = love.graphics.newQuad(0, spec.row * PROP, PROP, PROP, propImage:getDimensions())
    end
    return true
end

-- 동료 생성 시 스프라이트 자리에 그대로 넣을 수 있는 표. drawMoleCompanion이 쓰는
-- 필드 이름(walkFeet/actionFeet/nativeFacing)을 맞춰 두어 기존 그리기 경로를 재사용한다.
function Art.sprite()
    if not load() then return nil end
    local feet = {}
    for i = 1, 6 do feet[i] = FOOT end
    return {image=body,nativeFacing=1,walkFeet=feet,axeFeet=feet,cigaretteFeet=feet,fireworkFeet=feet,
        graduateMonkey = true}, frames, CELL, CELL
end

-- 몸체를 그린 뒤 손 앵커에 무기를 얹는다. 좌우 반전 시 각도도 함께 뒤집어야
-- 도끼가 반대쪽 손에서 거꾸로 돌지 않는다.
function Art.drawProp(companion, row, frame, flip, foot, bob, scale)
    if not load() then return false end
    local propName=companion.prop
    if not propName then return false end
    local quad = propQuads[propName]
    local spec=PROPS[propName]
    local pose = POSE[row] and POSE[row][frame]
    if not quad or not pose or not spec then return false end
    local anchorX, anchorY = pose[1] * PX, pose[2] * PX
    local x = companion.x + (anchorX - CELL / 2) * scale * flip
    local y = companion.y - bob + (anchorY - foot) * scale
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(props,quad,x,y,pose[3]*flip,scale*flip,scale,spec.gripX,spec.gripY)
    return true
end

Art.CELL, Art.FOOT = CELL, FOOT
return Art
