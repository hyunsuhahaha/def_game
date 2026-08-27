local F=require("src.frontend_ui")
local Lobby={}; Lobby.__index=Lobby
local function inside(b,x,y) return F.inside(b,x,y) end
function Lobby.new(images,fonts)
 local bg=love.graphics.newImage("assets/lobby-forest-field-hq-pixel-v2.png"); bg:setFilter("linear","linear",8)
 return setmetatable({images=images,fonts=fonts,background=bg,time=0,clearcutHover=0,displayFont=love.graphics.newFont("assets/font-korean-bold.ttf",52),microFont=love.graphics.newFont("assets/font-korean-bold.ttf",12)},Lobby)
end
function Lobby:update(dt) self.time=self.time+dt; local mx,my=love.mouse.getPosition(); local target=inside(self.clearcutBox,mx,my) and 1 or 0; self.clearcutHover=self.clearcutHover+(target-self.clearcutHover)*math.min(1,dt*11) end
function Lobby:keypressed(key)
 if key=="return" or key=="space" or key=="c" then return "clearcut" elseif key=="t" then return "character_traits" elseif key=="d" then return "character_codex" elseif key=="p" then return "skill_sandbox" end
end
function Lobby:mousepressed(x,y,button)
 if button~=1 then return end
 if inside(self.clearcutBox,x,y) then return "clearcut" elseif inside(self.traitsBox,x,y) then return "character_traits" elseif inside(self.codexBox,x,y) then return "character_codex" elseif inside(self.sandboxBox,x,y) then return "skill_sandbox" elseif inside(self.settingsBox,x,y) then return "settings" end
end
function Lobby:drawBackground(w,h)
 local iw,ih=self.background:getDimensions(); local scale=math.max(w/iw,h/ih)*1.025; local dw,dh=iw*scale,ih*scale
 love.graphics.setColor(1,1,1,1); love.graphics.draw(self.background,(w-dw)/2+math.sin(self.time*.12)*4,(h-dh)/2,0,scale,scale)
 love.graphics.setColor(.008,.020,.016,.18); love.graphics.rectangle("fill",0,0,w,h)
 for i=0,24 do local t=i/24; love.graphics.setColor(.005,.016,.012,.9*(1-t)^2); love.graphics.rectangle("fill",t*w*.72,0,w*.72/24+2,h) end
 for i=0,12 do local t=i/12; love.graphics.setColor(.004,.012,.01,.6*(1-t)); love.graphics.rectangle("fill",0,h-170+t*170,w,170/12+1) end
end
function Lobby:draw()
 local w,h=love.graphics.getDimensions(); local f=self.fonts; local micro=self.microFont or self.labelFont or f.small; self:drawBackground(w,h)
 love.graphics.setColor(.01,.025,.02,.92); love.graphics.rectangle("fill",0,0,w,76); love.graphics.setColor(.94,.61,.18,.7); love.graphics.rectangle("fill",0,74,w,2)
 love.graphics.setFont(micro); love.graphics.setColor(.95,.91,.76); love.graphics.print("LAST HAUL",34,20); love.graphics.setColor(.48,.58,.52); love.graphics.print("벌목 사무소",34,43)
 local nav={{"스킬 연습장","sandboxBox"},{"인물 기록","codexBox"},{"특성 연구","traitsBox"},{"환경 설정","settingsBox"}}; local nw,ng,ny=116,8,18; local nx=w-32-(nw*#nav+ng*(#nav-1))
 for i,item in ipairs(nav) do local b={x=nx+(i-1)*(nw+ng),y=ny,w=nw,h=42}; self[item[2]]=b; F.button(b,item[1],micro,{accent=i==4 and F.colors.teal or F.colors.amber}) end
 local left=math.max(42,w*.05); local compact=h<620; local top=compact and 90 or math.max(112,h*.16); local panelW=math.min(520,w*.45)
 F.label("벌목 계약서  /  01",left,top,micro,F.colors.amber)
 love.graphics.setFont(self.displayFont); love.graphics.setColor(.98,.97,.89); love.graphics.print("온대림 1구역",left-2,top+34); love.graphics.print("할당량 60그루",left-2,top+92)
 love.graphics.setFont(f.body); love.graphics.setColor(.77,.82,.75); love.graphics.printf("초기 작업 구역입니다.\n작업자와 구역을 정한 뒤 출발합니다.",left,top+166,panelW-30,"left")
 local dossierY=top+(compact and 220 or 238); local dossierH=compact and 82 or 112; F.frame(left,dossierY,panelW,dossierH,F.colors.teal,{alpha=.91}); F.label("준비 상태",left+20,dossierY+12,micro,F.colors.teal)
 local pulse=.55+math.sin(self.time*3)*.18; love.graphics.setColor(.35,.88,.56,pulse); love.graphics.circle("fill",left+25,dossierY+57,5)
 love.graphics.setFont(f.heading); love.graphics.setColor(.93,.92,.82); love.graphics.print("작업자 미배정 · 구역 미선택",left+42,dossierY+39); if not compact then love.graphics.setFont(f.small); love.graphics.setColor(.55,.64,.58); love.graphics.print("두 항목을 정하면 작업을 시작할 수 있습니다.",left+20,dossierY+76) end
 self.clearcutBox={x=left,y=math.min(h-132,dossierY+dossierH+20),w=panelW,h=76}; F.button(self.clearcutBox,"작업 준비",f.heading,{primary=true,key="ENT",align="left",accent=F.colors.amber})
 love.graphics.setFont(micro); love.graphics.setColor(.48,.55,.50); love.graphics.print("BUILD 0.9  ·  SAVE ONLINE",left,h-29); love.graphics.setColor(.66,.72,.66); love.graphics.printf("ESC  종료",0,h-29,w-34,"right")
end
return Lobby
