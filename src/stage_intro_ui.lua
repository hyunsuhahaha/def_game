local UI={}
local function clamp(v,a,b)return math.max(a,math.min(b,v))end
local function smooth(v)v=clamp(v,0,1);return v*v*(3-2*v)end
local function centered(font,text,y,w,color,alpha)
    love.graphics.setFont(font);love.graphics.setColor(.01,.015,.01,alpha*.88);love.graphics.printf(text,2,y+2,w,"center")
    love.graphics.setColor(color[1],color[2],color[3],alpha);love.graphics.printf(text,0,y,w,"center")
end
function UI.drawBars(w,h,bars)
    local bh=math.floor(h*.055*bars);if bh<=0 then return 0 end
    love.graphics.setColor(.002,.006,.004,.94);love.graphics.rectangle("fill",0,0,w,bh);love.graphics.rectangle("fill",0,h-bh,w,bh)
    return bh
end
function UI.drawTitle(game,intro,def,alpha)
    if alpha<=0 then return end;local w,h=love.graphics.getDimensions();local a=alpha*smooth((intro.t-.12)/.24)
    centered(game.fonts.micro,"1구역",h*.16,w,{.70,.78,.65},a)
    centered(game.fonts.title,def.name,h*.16+25,w,{.98,.94,.78},a)
end
function UI.drawHint(game,intro,alpha,bh)
    if alpha<=0 then return end;local w,h=love.graphics.getDimensions()
    local dashUnlocked=game.clearcut and(game.clearcut.permanentTraits.scoreDashUnlock or 0)>0
    centered(game.fonts.micro,dashUnlocked and"SPACE / 클릭  건너뛰기"or"클릭  건너뛰기",h-bh-24,w,{.65,.70,.64},alpha*.75)
end
return UI
