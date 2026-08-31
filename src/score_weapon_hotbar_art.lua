local Art={}
local cigarette,axe,equipment,fireworkQuad
local SLOT,GAP=58,4

local function load()
    if cigarette then return end
    cigarette=love.graphics.newImage("assets/characters/ingame/smoker-cigarette-pixel-v2.png")
    axe=love.graphics.newImage("assets/fx/supplement/axe-atlas-v1.png")
    equipment=love.graphics.newImage("assets/characters/ingame/smoker-weapon-evolution-equipment-v1.png")
    for _,image in ipairs({cigarette,axe,equipment})do image:setFilter("nearest","nearest")end
    fireworkQuad=love.graphics.newQuad(128,0,128,96,256,96)
end

function Art.rect(index,w,h)
    local total=SLOT*3+GAP*2
    return math.floor((w-total)/2)+(index-1)*(SLOT+GAP),h-SLOT-12,SLOT,SLOT
end

-- 잠긴 슬롯은 프레임을 어둡게 눌러 "지금 쓸 수 없다"를 실루엣만으로 읽히게 한다.
local function frame(x,y,size,selected,locked)
    love.graphics.setColor(0,0,0,.72);love.graphics.rectangle("fill",x+3,y+4,size,size)
    love.graphics.setColor(selected and{.92,.88,.66,1}or locked and{.19,.20,.19,.98}or{.30,.32,.30,.98});love.graphics.rectangle("fill",x,y,size,size)
    love.graphics.setColor(selected and{1,.96,.76,1}or locked and{.31,.32,.30,1}or{.52,.54,.50,1});love.graphics.rectangle("fill",x+3,y+3,size-6,size-6)
    love.graphics.setColor(.055,.065,.06,.98);love.graphics.rectangle("fill",x+7,y+7,size-14,size-14)
    love.graphics.setColor(.13,.15,.14,.96);love.graphics.rectangle("fill",x+9,y+9,size-18,size-18)
    if selected then
        love.graphics.setColor(1,.66,.18,.34);love.graphics.rectangle("fill",x+7,y+7,size-14,size-14)
        love.graphics.setColor(1,.76,.30,1);love.graphics.setLineWidth(2);love.graphics.rectangle("line",x+1,y+1,size-2,size-2)
    end
end

-- 자물쇠 픽셀 글리프. 9x10 고정 그리드. 고리는 밝은 금속으로 그려야 어두운 슬롯
-- 위에서 실루엣이 읽힌다(어두운 외곽선만으로 그리면 배경에 묻혀 사각형으로 보인다).
local lockRows={
    "   lll   ",
    "  l   l  ",
    " l     l ",
    " l     l ",
    "ooooooooo",
    "obbbbbbbo",
    "obbbobbbo",
    "obbbobbbo",
    "obbbbbbbo",
    "ooooooooo",
}
local lockPalette={
    l={.86,.88,.92,1},   -- 고리: 밝은 금속
    o={.06,.07,.06,1},   -- 외곽선·열쇠구멍
    b={.84,.72,.34,1},   -- 몸통: 놋쇠
}

local function drawLock(cx,cy,scale)
    local w=#lockRows[1]
    local originX=math.floor(cx-w*scale/2)
    local originY=math.floor(cy-#lockRows*scale/2)
    for row=1,#lockRows do
        for col=1,w do
            local color=lockPalette[lockRows[row]:sub(col,col)]
            if color then
                love.graphics.setColor(color)
                love.graphics.rectangle("fill",originX+(col-1)*scale,originY+(row-1)*scale,scale,scale)
            end
        end
    end
end

-- locked[index]=true 인 슬롯은 아이콘을 어둡게 깔고 자물쇠를 얹는다. 영구 연구로
-- 열리는 무기가 이미 쓸 수 있는 것처럼 보이면, 눌렀을 때 조용히 거부당한다.
function Art.draw(selected,w,h,locked)
    load()
    locked=locked or {}
    for index=1,3 do
        local x,y,size=Art.rect(index,w,h)
        local shut=locked[index]==true
        local active=index==(selected or 1) and not shut
        if active then y=y-4 end
        frame(x,y,size,active,shut)
        local cx,cy=x+size/2,y+size/2
        love.graphics.setColor(1,1,1,shut and .22 or 1)
        if index==1 then
            love.graphics.draw(cigarette,cx,cy,0,.19,.19,128,24)
        elseif index==2 then
            love.graphics.draw(axe,cx,cy,0,.30,.30,80,80)
        else
            love.graphics.draw(equipment,fireworkQuad,cx,cy,0,.43,.43,64,48)
        end
        if shut then drawLock(cx,cy,3) end
    end
    love.graphics.setColor(1,1,1,1)
    love.graphics.setLineWidth(1)
end

return Art
