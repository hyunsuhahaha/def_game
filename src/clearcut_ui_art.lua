local Art={}

local palettes={
    health={{.30,.025,.02,1},{.62,.055,.035,1},{.92,.12,.07,1},{1,.38,.16,1}},
    forest={{.025,.12,.035,1},{.08,.34,.08,1},{.20,.68,.14,1},{.50,.94,.28,1}},
    xp={{.18,.08,.01,1},{.46,.20,.02,1},{.88,.43,.04,1},{1,.74,.18,1}},
    boss={{.25,.015,.01,1},{.55,.03,.02,1},{.86,.07,.04,1},{1,.32,.13,1}}
}

-- Hard-edged four-band shading: readable as a pixel bar, never a UI prop.
function Art.bar(x,y,w,h,value,kind,flash)
    value=math.max(0,math.min(1,value or 0));local p=palettes[kind]or palettes.forest
    love.graphics.setColor(.025,.03,.025,.88);love.graphics.rectangle("fill",math.floor(x)-2,math.floor(y)-2,math.floor(w)+4,math.floor(h)+4)
    love.graphics.setColor(.12,.13,.11,.95);love.graphics.rectangle("fill",math.floor(x),math.floor(y),math.floor(w),math.floor(h))
    local fw=math.floor(w*value);if fw<=0 then return end
    local bands={math.max(1,math.floor(h*.22)),math.max(1,math.floor(h*.28)),math.max(1,math.floor(h*.30))};bands[4]=h-bands[1]-bands[2]-bands[3]
    local yy=math.floor(y)
    for i,bh in ipairs(bands)do if bh>0 then local c=p[5-i];love.graphics.setColor(c[1],c[2],c[3],flash and math.min(1,c[4]+.08)or c[4]);love.graphics.rectangle("fill",math.floor(x),yy,fw,bh);yy=yy+bh end end
end

function Art.button(x,y,w,h,label,font,kind,active)
    local mx,my=love.mouse.getPosition();local hover=active~=false and mx>=x and mx<=x+w and my>=y and my<=y+h
    local amber=kind=="amber"
    local base=amber and (hover and {.96,.47,.08,1}or{.64,.25,.035,.98}) or (hover and {.20,.43,.30,1}or{.14,.20,.16,.96})
    local edge=amber and (hover and {1,.84,.36,1}or{.96,.52,.10,1}) or (hover and {.56,.92,.68,1}or{.38,.65,.48,1})
    love.graphics.setColor(base);love.graphics.rectangle("fill",x,y,w,h)
    love.graphics.setColor(base[1]*.72,base[2]*.72,base[3]*.72,1);love.graphics.rectangle("fill",x,y+h*.68,w,h*.32)
    love.graphics.setColor(math.min(1,base[1]+.12),math.min(1,base[2]+.12),math.min(1,base[3]+.12),1);love.graphics.rectangle("fill",x,y,w,2)
    love.graphics.setColor(edge);love.graphics.rectangle("fill",x,y+h-3,w,3)
    love.graphics.setFont(font);love.graphics.setColor(active==false and {.5,.5,.48,.7}or{1,.96,.84,1});love.graphics.printf(label,x,y+h/2-font:getHeight()/2,w,"center")
    return hover
end
return Art
