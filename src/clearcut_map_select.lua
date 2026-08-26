local Maps=require("src.clearcut_maps")
local UI=require("src.ui")
local Select={}
local previews={}
function Select.boxes(w,h)
    local gap,margin=18,math.max(24,w*.045)
    local cw=(w-margin*2-gap)/2
    local rows=math.ceil(#Maps.catalog/2)
    local ch=math.min(260,(h-180-gap*(rows-1))/rows)
    local boxes={}
    for i=1,#Maps.catalog do boxes[i]={x=margin+((i-1)%2)*(cw+gap),y=116+math.floor((i-1)/2)*(ch+gap),w=cw,h=ch} end
    return boxes
end
function Select.at(x,y)
    for i,b in ipairs(Select.boxes(love.graphics.getDimensions())) do
        if x>=b.x and x<=b.x+b.w and y>=b.y and y<=b.y+b.h then return i end
    end
end
function Select.draw(game)
    local w,h=love.graphics.getDimensions();local f=game.fonts
    love.graphics.setColor(.025,.045,.045,1);love.graphics.rectangle("fill",0,0,w,h)
    love.graphics.setFont(f.title);love.graphics.setColor(1,.83,.43)
    love.graphics.printf("이번엔 어디를 태울까?",0,27,w,"center")
    love.graphics.setFont(f.small);love.graphics.setColor(.70,.80,.74)
    love.graphics.printf("맵 선택  ·  캐릭터와 융합 스킬은 그대로, 다른 지형에서 시작합니다",0,78,w,"center")
    local hovered=Select.at(love.mouse.getPosition())
    for i,b in ipairs(Select.boxes(w,h)) do
        local def=Maps.catalog[i]
        UI.panel(b.x,b.y,b.w,b.h,{unpack(def.color)},hovered==i and 1 or .9)
        local previewId=def.preview or def.id
        if not previews[previewId] then
            previews[previewId]=love.graphics.newImage("assets/maps/"..previewId.."-preview-v1.png")
            previews[previewId]:setFilter("nearest","nearest")
        end
        local image=previews[previewId];local pw=b.w*.40
        local scale=math.min((pw-24)/image:getWidth(),(b.h-30)/image:getHeight())
        love.graphics.setColor(1,1,1,1)
        love.graphics.draw(image,b.x+12+(pw-24)/2,b.y+b.h/2,0,scale,scale,image:getWidth()/2,image:getHeight()/2)
        local tx,tw=b.x+pw,b.w-pw-18
        love.graphics.setFont(f.heading);love.graphics.setColor(1,.91,.70)
        love.graphics.printf(i.."  "..def.name,tx,b.y+17,tw,"left")
        love.graphics.setFont(f.small);love.graphics.setColor(def.color)
        love.graphics.printf(def.subtitle,tx,b.y+52,tw,"left")
        love.graphics.setColor(.73,.80,.75)
        love.graphics.printf(b.h<210 and (def.short or def.subtitle) or def.desc,tx,b.y+85,tw,"left")
        love.graphics.setColor(.85,.81,.60)
        love.graphics.printf("첫 숲 "..def.trees.."그루",tx,b.y+b.h-28,tw,"left")
    end
    love.graphics.setFont(f.small);love.graphics.setColor(.7,.78,.73)
    love.graphics.printf("숫자 1–"..#Maps.catalog.." / 클릭으로 출발  ·  ESC 캐릭터 선택으로",0,h-36,w,"center")
end
return Select
