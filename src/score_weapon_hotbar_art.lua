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

local function frame(x,y,size,selected)
    love.graphics.setColor(0,0,0,.72);love.graphics.rectangle("fill",x+3,y+4,size,size)
    love.graphics.setColor(selected and{.92,.88,.66,1}or{.30,.32,.30,.98});love.graphics.rectangle("fill",x,y,size,size)
    love.graphics.setColor(selected and{1,.96,.76,1}or{.52,.54,.50,1});love.graphics.rectangle("fill",x+3,y+3,size-6,size-6)
    love.graphics.setColor(.055,.065,.06,.98);love.graphics.rectangle("fill",x+7,y+7,size-14,size-14)
    love.graphics.setColor(.13,.15,.14,.96);love.graphics.rectangle("fill",x+9,y+9,size-18,size-18)
    if selected then
        love.graphics.setColor(1,.66,.18,.34);love.graphics.rectangle("fill",x+7,y+7,size-14,size-14)
        love.graphics.setColor(1,.76,.30,1);love.graphics.setLineWidth(2);love.graphics.rectangle("line",x+1,y+1,size-2,size-2)
    end
end

function Art.draw(selected,w,h)
    load()
    for index=1,3 do
        local x,y,size=Art.rect(index,w,h)
        local active=index==(selected or 1)
        if active then y=y-4 end
        frame(x,y,size,active)
        local cx,cy=x+size/2,y+size/2
        love.graphics.setColor(1,1,1,1)
        if index==1 then
            love.graphics.draw(cigarette,cx,cy,0,.19,.19,128,24)
        elseif index==2 then
            love.graphics.draw(axe,cx,cy,0,.30,.30,80,80)
        else
            love.graphics.draw(equipment,fireworkQuad,cx,cy,0,.43,.43,64,48)
        end
    end
    love.graphics.setLineWidth(1)
end

return Art
