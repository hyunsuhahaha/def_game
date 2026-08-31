-- 무기 졸업 동료의 공용 몸체. 모든 졸업 동료는 같은 원숭이를 쓰고 손에 든 무기만
-- 다르다. 그래서 몸체 아틀라스에는 무기를 굽지 않고, 무기는 프레임별 손 앵커에 붙이는
-- 별도 프롭으로 그린다(AGENTS.md의 장비 규칙). 졸업 동료를 추가할 때는 프롭만 그린다.
--
-- 자산: scripts/build_graduate_monkey.py
local Art = {}

local CELL, PX, FOOT = 128, 4, 116
local PROP = 48
local GRIP_X, GRIP_Y = 6 * PX, 9 * PX

-- {손 앵커 x, y (그리드), 프롭 각도(라디안)}. 빌드 스크립트가 출력한 값 그대로다.
local POSE = {
    walk = {{24, 23, 0}, {24, 22, 0}, {23, 23, 0}, {24, 24, 0}, {24, 22, 0}, {23, 23, 0}},
    action = {{27, 20, -.40}, {29, 16, -1.05}, {29, 12, -1.70}, {24, 25, 1.20}, {22, 27, 1.85}, {24, 24, .35}},
}
local PROPS = {axe = 0}

local body, props, frames, propQuads

local function load()
    if body then return true end
    local ok, image = pcall(love.graphics.newImage, "assets/characters/companions/graduate-monkey-atlas-pixel-v1.png")
    if not ok then return false end
    local okProps, propImage = pcall(love.graphics.newImage, "assets/characters/companions/graduate-monkey-props-pixel-v1.png")
    if not okProps then return false end
    image:setFilter("nearest", "nearest")
    propImage:setFilter("nearest", "nearest")
    body, props = image, propImage
    frames = {walk = {}, action = {}}
    for i = 0, 5 do
        frames.walk[i + 1] = love.graphics.newQuad(i * CELL, 0, CELL, CELL, image:getDimensions())
        frames.action[i + 1] = love.graphics.newQuad(i * CELL, CELL, CELL, CELL, image:getDimensions())
    end
    propQuads = {}
    for name, index in pairs(PROPS) do
        propQuads[name] = love.graphics.newQuad(0, index * PROP, PROP, PROP, propImage:getDimensions())
    end
    return true
end

-- 동료 생성 시 스프라이트 자리에 그대로 넣을 수 있는 표. drawMoleCompanion이 쓰는
-- 필드 이름(walkFeet/actionFeet/nativeFacing)을 맞춰 두어 기존 그리기 경로를 재사용한다.
function Art.sprite()
    if not load() then return nil end
    local feet = {}
    for i = 1, 6 do feet[i] = FOOT end
    return {image = body, nativeFacing = 1, walkFeet = feet, actionFeet = feet,
        graduateMonkey = true}, frames, CELL, CELL
end

-- 몸체를 그린 뒤 손 앵커에 무기를 얹는다. 좌우 반전 시 각도도 함께 뒤집어야
-- 도끼가 반대쪽 손에서 거꾸로 돌지 않는다.
function Art.drawProp(companion, row, frame, flip, foot, bob, scale)
    if not load() then return false end
    local quad = propQuads[companion.prop or "axe"]
    local pose = POSE[row] and POSE[row][frame]
    if not quad or not pose then return false end
    local anchorX, anchorY = pose[1] * PX, pose[2] * PX
    local x = companion.x + (anchorX - CELL / 2) * scale * flip
    local y = companion.y - bob + (anchorY - foot) * scale
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(props, quad, x, y, pose[3] * flip, scale * flip, scale, GRIP_X, GRIP_Y)
    return true
end

Art.CELL, Art.FOOT = CELL, FOOT
return Art
