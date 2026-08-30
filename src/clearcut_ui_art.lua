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

-- Results use a compact physical-control silhouette instead of the old flat
-- colour strip: clipped pixel corners, a separate key well, and three stepped
-- material bands keep it readable without turning it into a large card.
function Art.resultButton(x,y,w,h,label,key,font,kind,active)
    x,y,w,h=math.floor(x+.5),math.floor(y+.5),math.floor(w+.5),math.floor(h+.5)
    local mx,my=love.mouse.getPosition();local hover=active~=false and mx>=x and mx<=x+w and my>=y and my<=y+h
    local amber=kind=="amber";local lift=hover and-2 or 0;y=y+lift
    local cut=math.max(3,math.floor(h*.12));local shape={x+cut,y,x+w-cut,y,x+w,y+cut,x+w,y+h-cut,x+w-cut,y+h,x+cut,y+h,x,y+h-cut,x,y+cut}
    local shadow={};for i=1,#shape,2 do shadow[#shadow+1]=shape[i]+3;shadow[#shadow+1]=shape[i+1]+4 end
    love.graphics.setColor(0,0,0,.58);love.graphics.polygon("fill",shadow)
    local edge=amber and(hover and{1,.72,.20}or{.76,.39,.09})or(hover and{.52,.86,.61}or{.29,.49,.35})
    love.graphics.setColor(edge);love.graphics.polygon("fill",shape)
    local inset=2;local inner={x+cut+inset,y+inset,x+w-cut-inset,y+inset,x+w-inset,y+cut+inset,x+w-inset,y+h-cut-inset,x+w-cut-inset,y+h-inset,x+cut+inset,y+h-inset,x+inset,y+h-cut-inset,x+inset,y+cut+inset}
    local top=amber and(hover and{.35,.17,.045}or{.20,.105,.035})or(hover and{.095,.18,.125}or{.055,.105,.073})
    love.graphics.setColor(top);love.graphics.polygon("fill",inner)
    love.graphics.setColor(top[1]*.58,top[2]*.58,top[3]*.58,.98);love.graphics.rectangle("fill",x+2,y+math.floor(h*.63),w-4,math.floor(h*.32))
    love.graphics.setColor(edge[1],edge[2],edge[3],.34);love.graphics.rectangle("fill",x+cut+3,y+3,w-cut*2-6,2)

    local keyW=key=="ENTER"and math.floor(h*1.12)or math.floor(h*.72);local keyH=math.floor(h*.62)
    local keyX=x+math.floor(h*.25);local keyY=y+math.floor((h-keyH)/2)
    love.graphics.setColor(.018,.025,.020,1);love.graphics.rectangle("fill",keyX-2,keyY-2,keyW+4,keyH+5)
    love.graphics.setColor(edge[1],edge[2],edge[3],.78);love.graphics.rectangle("fill",keyX,keyY,keyW,keyH)
    love.graphics.setColor(.07,.08,.07,1);love.graphics.rectangle("fill",keyX+2,keyY+2,keyW-4,keyH-5)
    love.graphics.setColor(.20,.22,.19,1);love.graphics.rectangle("fill",keyX+3,keyY+3,keyW-6,2)
    love.graphics.setFont(font);love.graphics.setColor(.94,.92,.80,1)
    local keyScale=key=="ENTER"and .78 or 1
    love.graphics.push();love.graphics.translate(keyX+keyW/2,keyY+keyH/2);love.graphics.scale(keyScale,keyScale)
    love.graphics.printf(key,-keyW/(2*keyScale),-font:getHeight()/2,keyW/keyScale,"center");love.graphics.pop()
    local labelX=keyX+keyW+math.floor(h*.22);local labelW=x+w-labelX-math.floor(h*.35)
    love.graphics.setColor(active==false and{.48,.49,.45,.65}or{.96,.93,.80,1});love.graphics.printf(label,labelX,y+h/2-font:getHeight()/2,labelW,"left")
    -- A two-pixel action chevron adds direction without a decorative icon tile.
    local ax=x+w-math.floor(h*.28);local ay=y+math.floor(h*.50)
    love.graphics.setColor(edge);love.graphics.rectangle("fill",ax-4,ay-3,2,2);love.graphics.rectangle("fill",ax-2,ay-1,2,2);love.graphics.rectangle("fill",ax-4,ay+1,2,2)
    return hover
end
return Art
