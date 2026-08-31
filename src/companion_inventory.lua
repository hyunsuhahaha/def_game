-- Two-slot player loadout + one equipment slot per graduation monkey.
-- The presentation borrows Minecraft's plain square inventory grammar: icon-only
-- cells, a selected stack carried by the cursor, and no card descriptions.
local Inventory={}
local props,monkey,propQuads,monkeyQuad
local SLOT,GAP=64,8
local names={cigarette="담배",axe="도끼",firework="폭죽 로켓"}

local function load()
    if props then return end
    props=love.graphics.newImage("assets/characters/companions/graduate-monkey-props-pixel-v2.png")
    monkey=love.graphics.newImage("assets/characters/companions/graduate-monkey-atlas-pixel-v3.png")
    for _,image in ipairs({props,monkey})do image:setFilter("nearest","nearest")end
    propQuads={axe=love.graphics.newQuad(0,0,64,64,64,192),cigarette=love.graphics.newQuad(0,64,64,64,64,192),firework=love.graphics.newQuad(0,128,64,64,64,192)}
    monkeyQuad=love.graphics.newQuad(0,0,128,128,768,512)
end

local function rect(x,y,w,h)return{x=x,y=y,w=w,h=h}end
local function inside(b,x,y)return b and x>=b.x and x<=b.x+b.w and y>=b.y and y<=b.y+b.h end
function Inventory.layout(w,h,monkeyCount)
    local pw,ph=math.min(760,w-40),math.min(460,h-40);local x,y=math.floor((w-pw)/2),math.floor((h-ph)/2)
    local result={panel=rect(x,y,pw,ph),close=rect(x+pw-50,y+16,32,32),bag={},player={},monkeys={}}
    local bagX=x+42
    for i=1,3 do result.bag[i]=rect(bagX+(i-1)*(SLOT+GAP),y+126,SLOT,SLOT)end
    local playerX=x+42
    for i=1,2 do result.player[i]=rect(playerX+(i-1)*(SLOT+GAP),y+274,SLOT,SLOT)end
    local monkeyX=x+470
    for i=1,math.max(1,monkeyCount or 0)do result.monkeys[i]=rect(monkeyX+((i-1)%3)*(SLOT+54),y+274+math.floor((i-1)/3)*112,SLOT,SLOT)end
    return result
end

local function slot(b,active)
    love.graphics.setColor(.05,.055,.05,.96);love.graphics.rectangle("fill",b.x+4,b.y+5,b.w,b.h)
    love.graphics.setColor(active and{.82,.74,.42,1}or{.34,.36,.32,1});love.graphics.rectangle("fill",b.x,b.y,b.w,b.h)
    love.graphics.setColor(.12,.13,.12,1);love.graphics.rectangle("fill",b.x+5,b.y+5,b.w-10,b.h-10)
    love.graphics.setColor(active and{1,.88,.42,1}or{.54,.56,.50,1});love.graphics.setLineWidth(active and 3 or 2);love.graphics.rectangle("line",b.x+.5,b.y+.5,b.w-1,b.h-1)
end
function Inventory.drawWeapon(id,cx,cy,alpha)
    if not id then return end;load();love.graphics.setColor(1,1,1,alpha or 1)
    local quad=propQuads[id];if quad then love.graphics.draw(props,quad,cx,cy,0,.78,.78,32,32)end
end

function Inventory.draw(mode,fonts,w,h)
    load();local monkeys=mode:graduationMonkeys();local layout=Inventory.layout(w,h,#monkeys);mode.companionInventoryLayout=layout
    love.graphics.setColor(0,0,0,.74);love.graphics.rectangle("fill",0,0,w,h)
    local p=layout.panel;love.graphics.setColor(.10,.115,.10,.99);love.graphics.rectangle("fill",p.x,p.y,p.w,p.h)
    love.graphics.setColor(.58,.60,.52,1);love.graphics.setLineWidth(3);love.graphics.rectangle("line",p.x+.5,p.y+.5,p.w-1,p.h-1)
    love.graphics.setFont(fonts.heading);love.graphics.setColor(.95,.93,.82);love.graphics.print("장비 가방",p.x+32,p.y+22)
    love.graphics.setFont(fonts.small);love.graphics.setColor(.64,.68,.60);love.graphics.print("아이콘을 집어 플레이어 2칸 또는 원숭이 장비 칸에 놓으세요",p.x+32,p.y+58)
    love.graphics.setColor(.8,.82,.74);love.graphics.print("보유 장비 · 클릭해서 집기",p.x+42,p.y+96)
    local catalog={"cigarette","axe","firework"}
    local function assigned(id)
        for i=1,2 do if (mode.scoreEquippedWeapons or{})[i]==id then return"P"..i end end
        for i,value in ipairs(monkeys)do if value.prop==id then return"M"..i end end
        return"가방"
    end
    for i,b in ipairs(layout.bag)do local id=catalog[i];local unlocked=mode:scoreWeaponUnlocked(i)
        slot(b,mode.inventoryHeld==id);Inventory.drawWeapon(id,b.x+32,b.y+32,unlocked and 1 or .16)
        love.graphics.setColor(unlocked and{1,.86,.48}or{.45,.46,.42});love.graphics.print(unlocked and assigned(id)or"잠김",b.x+5,b.y+44)
    end
    love.graphics.setColor(.8,.82,.74);love.graphics.print("플레이어 장착 · 숫자키 1 / 2",p.x+42,p.y+240)
    for i,b in ipairs(layout.player)do slot(b,(mode.scoreWeaponSlot or 1)==i);Inventory.drawWeapon(mode.scoreEquippedWeapons[i],b.x+32,b.y+32,1)
        love.graphics.setColor(1,.9,.55);love.graphics.print(tostring(i),b.x+6,b.y+4)end
    love.graphics.setColor(.8,.82,.74);love.graphics.print("졸업 원숭이 · 한 마리당 무기 1개",p.x+360,p.y+240)
    for i,b in ipairs(layout.monkeys)do
        local portraitX=b.x-96;love.graphics.setColor(.08,.09,.08,1);love.graphics.rectangle("fill",portraitX,b.y-18,78,92)
        love.graphics.setColor(1,1,1,1);love.graphics.draw(monkey,monkeyQuad,portraitX-6,b.y-10,0,.68,.68)
        love.graphics.setColor(.72,.75,.67);love.graphics.print("원숭이 #"..i,portraitX,b.y+74)
        slot(b,false);Inventory.drawWeapon(monkeys[i]and monkeys[i].prop,b.x+32,b.y+32,1)
    end
    love.graphics.setColor(.8,.82,.74);love.graphics.print("I 또는 ESC 닫기",p.x+p.w-144,p.y+26)
    if mode.inventoryHeld then local mx,my=love.mouse.getPosition();Inventory.drawWeapon(mode.inventoryHeld,mx,my,.95)end
    love.graphics.setColor(1,1,1,1);love.graphics.setLineWidth(1)
end

function Inventory.hit(layout,x,y)
    for i,b in ipairs(layout.bag or{})do if inside(b,x,y)then return"bag",i end end
    for i,b in ipairs(layout.player or{})do if inside(b,x,y)then return"player",i end end
    for i,b in ipairs(layout.monkeys or{})do if inside(b,x,y)then return"monkey",i end end
    if inside(layout.close,x,y)then return"close",1 end
end
Inventory.names=names
return Inventory
