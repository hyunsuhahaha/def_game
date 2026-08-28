local Frontend = {}

Frontend.colors = {
    ink={.012,.025,.022,1}, panel={.025,.050,.043,1}, ivory={.95,.93,.82,1},
    muted={.60,.69,.63,1}, amber={.95,.62,.18,1}, rust={.78,.24,.12,1}, teal={.22,.63,.55,1}
}

local function inside(b,x,y) return b and x>=b.x and x<=b.x+b.w and y>=b.y and y<=b.y+b.h end
Frontend.inside=inside

function Frontend.backdrop(w,h,accent,alpha)
    accent=accent or Frontend.colors.teal
    love.graphics.setColor(.006,.015,.013,alpha or .94); love.graphics.rectangle("fill",0,0,w,h)
    for i=0,18 do
        local t=i/18
        love.graphics.setColor(accent[1],accent[2],accent[3],.035*(1-t))
        love.graphics.circle("fill",w*.72,h*.42,80+i*42)
    end
    love.graphics.setLineWidth(1)
    for x=-h,w+h,64 do love.graphics.setColor(1,1,1,.018); love.graphics.line(x,0,x-h,h) end
    for y=0,h,4 do love.graphics.setColor(0,0,0,.018); love.graphics.rectangle("fill",0,y,w,1) end
    love.graphics.setColor(.95,.62,.18,.20); love.graphics.rectangle("fill",0,0,w,3)
end

function Frontend.frame(x,y,w,h,accent,opts)
    opts=opts or {}; accent=accent or Frontend.colors.amber
    love.graphics.setColor(0,0,0,.46); love.graphics.rectangle("fill",x+8,y+10,w,h,opts.radius or 5,opts.radius or 5)
    love.graphics.setColor(.018,.037,.032,opts.alpha or .97); love.graphics.rectangle("fill",x,y,w,h,opts.radius or 5,opts.radius or 5)
    love.graphics.setColor(.075,.105,.088,.92); love.graphics.rectangle("line",x+.5,y+.5,w-1,h-1,opts.radius or 5,opts.radius or 5)
    love.graphics.setColor(accent[1],accent[2],accent[3],opts.selected and .95 or .55)
    love.graphics.rectangle("fill",x,y,opts.selected and 5 or 3,h,2,2)
    love.graphics.rectangle("fill",x+12,y,w-24,2)
    love.graphics.setColor(1,1,1,.055); love.graphics.line(x+12,y+8,x+w-12,y+8)
    if opts.corner~=false then
        love.graphics.setColor(accent[1],accent[2],accent[3],.55)
        love.graphics.line(x+w-22,y+1,x+w-1,y+1,x+w-1,y+22)
        love.graphics.line(x+1,y+h-22,x+1,y+h-1,x+22,y+h-1)
    end
end

function Frontend.label(text,x,y,font,accent)
    accent=accent or Frontend.colors.amber
    love.graphics.setFont(font); love.graphics.setColor(accent); love.graphics.print(string.upper(text),x,y)
    local width=font.getWidth and font:getWidth(text) or 90
    love.graphics.setColor(accent[1],accent[2],accent[3],.35); love.graphics.rectangle("fill",x+width+12,y+font:getHeight()/2,width<110 and 70 or 40,1)
end

function Frontend.badge(text,x,y,w,font,accent)
    accent=accent or Frontend.colors.teal
    love.graphics.setColor(accent[1],accent[2],accent[3],.15); love.graphics.rectangle("fill",x,y,w,24,3,3)
    love.graphics.setColor(accent[1],accent[2],accent[3],.72); love.graphics.rectangle("line",x+.5,y+.5,w-1,23,3,3)
    love.graphics.setFont(font); love.graphics.printf(text,x,y+5,w,"center")
end

function Frontend.button(box,label,font,opts)
    opts=opts or {}; local mx,my=love.mouse.getPosition(); local hover=inside(box,mx,my) and opts.enabled~=false
    local accent=opts.accent or Frontend.colors.amber; local lift=hover and 3 or 0; local y=box.y-lift
    love.graphics.setColor(0,0,0,.45); love.graphics.rectangle("fill",box.x+4,y+7,box.w,box.h,5,5)
    if opts.primary then
        love.graphics.setColor(accent[1]+(hover and .04 or 0),accent[2]+(hover and .06 or 0),accent[3],1)
    else love.graphics.setColor(.045+(hover and .025 or 0),.075+(hover and .025 or 0),.063+(hover and .02 or 0),.98) end
    love.graphics.rectangle("fill",box.x,y,box.w,box.h,4,4)
    love.graphics.setColor(accent[1],accent[2],accent[3],hover and 1 or .62); love.graphics.rectangle("line",box.x+.5,y+.5,box.w-1,box.h-1,4,4)
    love.graphics.rectangle("fill",box.x,y,4,box.h)
    love.graphics.setFont(font)
    local textW=opts.key and (box.w-76) or box.w
    if opts.primary then love.graphics.setColor(.07,.065,.025,1) else love.graphics.setColor(.92,.92,.82,opts.enabled==false and .35 or 1) end
    love.graphics.printf(label,box.x+(opts.align=="left" and 18 or 0),y+box.h/2-font:getHeight()/2,textW-(opts.align=="left" and 18 or 0),opts.align or "center")
    if opts.key then
        love.graphics.setColor(opts.primary and {.12,.10,.04,.55} or {1,1,1,.08}); love.graphics.rectangle("fill",box.x+box.w-66,y+12,52,box.h-24,3,3)
        love.graphics.setColor(opts.primary and {.09,.07,.02,1} or {.82,.84,.76,1}); love.graphics.printf(opts.key,box.x+box.w-66,y+box.h/2-font:getHeight()/2,52,"center")
    end
    return hover
end

function Frontend.toggle(box,on,font,label,detail,accent)
    accent=accent or Frontend.colors.teal
    Frontend.frame(box.x,box.y,box.w,box.h,accent,{selected=on,corner=false})
    love.graphics.setFont(font); love.graphics.setColor(.94,.93,.84); love.graphics.print(label,box.x+20,box.y+14)
    if detail then love.graphics.setColor(.57,.65,.59); love.graphics.print(detail,box.x+20,box.y+39) end
    local sw,sh=58,28; local sx,sy=box.x+box.w-sw-20,box.y+(box.h-sh)/2
    love.graphics.setColor(on and accent or {.13,.16,.14,1}); love.graphics.rectangle("fill",sx,sy,sw,sh,14,14)
    love.graphics.setColor(on and {.96,.91,.65,1} or {.48,.53,.49,1}); love.graphics.circle("fill",sx+(on and sw-14 or 14),sy+14,9)
end

function Frontend.sliderValueAt(box,x)
    local trackX,trackW=box.x+20,box.w-40
    return math.max(0,math.min(1,(x-trackX)/trackW))
end

function Frontend.slider(box,value,font,label,detail,accent)
    accent=accent or Frontend.colors.teal
    value=math.max(0,math.min(1,value or 0))
    Frontend.frame(box.x,box.y,box.w,box.h,accent,{corner=false})
    love.graphics.setFont(font);love.graphics.setColor(.94,.93,.84);love.graphics.print(label,box.x+20,box.y+11)
    love.graphics.setColor(accent[1],accent[2],accent[3],.16);love.graphics.rectangle("fill",box.x+box.w-102,box.y+9,82,24,3,3)
    love.graphics.setColor(accent);love.graphics.printf(string.format("%d%%",math.floor(value*100+.5)),box.x+box.w-102,box.y+13,82,"center")
    if detail then love.graphics.setColor(.57,.65,.59);love.graphics.print(detail,box.x+20,box.y+36) end
    local tx,tw,ty=box.x+20,box.w-40,box.y+box.h-18
    love.graphics.setColor(.10,.14,.12,1);love.graphics.rectangle("fill",tx,ty,tw,6,3,3)
    love.graphics.setColor(accent[1],accent[2],accent[3],.88);love.graphics.rectangle("fill",tx,ty,tw*value,6,3,3)
    local knobX=tx+tw*value
    love.graphics.setColor(.02,.035,.03,1);love.graphics.circle("fill",knobX,ty+3,9)
    love.graphics.setColor(.96,.91,.65,1);love.graphics.circle("fill",knobX,ty+3,6)
end

function Frontend.footer(w,h,text,font)
    love.graphics.setColor(.008,.018,.015,.94); love.graphics.rectangle("fill",0,h-36,w,36)
    love.graphics.setColor(1,1,1,.08); love.graphics.line(0,h-36,w,h-36)
    love.graphics.setFont(font); love.graphics.setColor(.58,.66,.60); love.graphics.printf(text,24,h-27,w-48,"center")
end

return Frontend
