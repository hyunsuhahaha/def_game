local Maps=require("src.clearcut_maps")
local F=require("src.frontend_ui")
local Select={}; local previews={}
local function imageFor(def)
 local id=def.preview or def.id
 if not previews[id] then previews[id]=love.graphics.newImage("assets/maps/"..id.."-preview-v1.png"); previews[id]:setFilter("nearest","nearest") end
 return previews[id]
end
function Select.boxes(w,h)
 local x,y,bw,bh=34,136,math.min(340,w*.29),math.max(64,math.min(82,(h-204-(#Maps.catalog-1)*10)/#Maps.catalog)); local boxes={}
 for i=1,#Maps.catalog do boxes[i]={x=x,y=y+(i-1)*(bh+10),w=bw,h=bh} end
 return boxes
end
function Select.at(x,y) for i,b in ipairs(Select.boxes(love.graphics.getDimensions())) do if F.inside(b,x,y) then return i end end end
function Select.focus(game)
 local hover=Select.at(love.mouse.getPosition()); if hover then game.clearcutMapFocus=hover end
 game.clearcutMapFocus=math.max(1,math.min(#Maps.catalog,game.clearcutMapFocus or 1)); return game.clearcutMapFocus
end
function Select.draw(game)
 local w,h=love.graphics.getDimensions(); local f=game.fonts; local focus=Select.focus(game); local def=Maps.catalog[focus]; local accent=def.color
 F.backdrop(w,h,accent,1)
 love.graphics.setFont(f.small); love.graphics.setColor(accent); love.graphics.print("작업 구역",34,24)
 love.graphics.setFont(f.title); love.graphics.setColor(.97,.95,.85); love.graphics.print("작업 구역 선택",34,50)
 love.graphics.setFont(f.small); love.graphics.setColor(.55,.64,.58); love.graphics.print("초기 수목 수와 지형을 확인합니다.",34,96)
 local boxes=Select.boxes(w,h); local mx,my=love.mouse.getPosition()
 for i,b in ipairs(boxes) do
  local d=Maps.catalog[i]; local selected=i==focus; F.frame(b.x,b.y,b.w,b.h,d.color,{selected=selected,alpha=selected and .99 or .84,corner=false})
  love.graphics.setFont(f.heading); love.graphics.setColor(selected and {.98,.95,.82,1} or {.62,.68,.62,1}); love.graphics.print(string.format("%02d",i),b.x+17,b.y+15); love.graphics.print(d.name,b.x+58,b.y+15)
  love.graphics.setFont(f.small); love.graphics.setColor(selected and d.color or {.43,.50,.45,1}); love.graphics.print(d.short,b.x+58,b.y+43)
 end
 local rx=boxes[1].x+boxes[1].w+28; local rw=w-rx-34; local ry=136; local rh=h-204
 F.frame(rx,ry,rw,rh,accent,{selected=true})
 local compact=h<620; local img=imageFor(def); local imageH=math.min(rh*(compact and .48 or .56),330); local scale=math.max(rw/img:getWidth(),imageH/img:getHeight()); local iw,ih=img:getDimensions()
 love.graphics.setScissor(rx+4,ry+4,rw-8,imageH); love.graphics.setColor(1,1,1,1); love.graphics.draw(img,rx+rw/2,ry+imageH/2,0,scale,scale,iw/2,ih/2)
 for i=0,12 do local t=i/12; love.graphics.setColor(.012,.025,.021,t*.7); love.graphics.rectangle("fill",rx+4,ry+imageH-80+t*80,rw-8,80/12+1) end
 love.graphics.setScissor(); F.badge("1 / 4단계",rx+20,ry+18,100,f.small,accent)
 local ty=ry+imageH+18; F.label(def.subtitle,rx+22,ty,f.small,accent)
 love.graphics.setFont(f.big); love.graphics.setColor(.98,.96,.86); love.graphics.print(def.name,rx+22,ty+27)
 love.graphics.setFont(f.body); love.graphics.setColor(.68,.75,.69); love.graphics.printf(compact and def.short or def.desc,rx+22,ty+68,rw-44,"left")
 local statY=ry+rh-(compact and 52 or 70); love.graphics.setColor(1,1,1,.08); love.graphics.line(rx+22,statY-14,rx+rw-22,statY-14)
 local stats={{"초기 수목",def.trees.."그루"},{"확장 단계","4구역"},{"현장 상태","미개척"}}
 for i,s in ipairs(stats) do local sx=rx+22+(i-1)*(rw-44)/3; love.graphics.setFont(f.small); love.graphics.setColor(.48,.57,.51); love.graphics.print(s[1],sx,statY); love.graphics.setFont(f.heading); love.graphics.setColor(i==1 and accent or F.colors.ivory); love.graphics.print(s[2],sx,statY+22) end
 game.clearcutMapBackBox={x=34,y=h-52,w=136,h=36}; game.clearcutMapConfirmBox={x=w-330,y=h-62,w=296,h=46}
 F.button(game.clearcutMapBackBox,"← 작업자",f.small,{accent=F.colors.teal}); F.button(game.clearcutMapConfirmBox,"이 구역 선택",f.body,{primary=true,key="ENT",align="left",accent=accent})
end
return Select
