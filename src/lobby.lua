local F=require("src.frontend_ui")
local Lobby={}; Lobby.__index=Lobby
local function inside(b,x,y) return F.inside(b,x,y) end
function Lobby.new(images,fonts)
 local bg=love.graphics.newImage("assets/lobby-forest-field-hq-pixel-v2.png"); bg:setFilter("linear","linear",8)
 return setmetatable({images=images,fonts=fonts,background=bg,time=0,clearcutHover=0},Lobby)
end
function Lobby:update(dt) self.time=self.time+dt; local mx,my=love.mouse.getPosition(); local target=inside(self.clearcutBox,mx,my) and 1 or 0; self.clearcutHover=self.clearcutHover+(target-self.clearcutHover)*math.min(1,dt*11) end
function Lobby:keypressed(key)
 if key=="return" or key=="space" or key=="c" then return "clearcut" elseif key=="a" then return "achievements" elseif key=="t" then return "character_traits" elseif key=="d" then return "character_codex" elseif key=="p" then return "skill_sandbox" end
end
function Lobby:mousepressed(x,y,button)
 if button~=1 then return end
 if inside(self.clearcutBox,x,y) then return "clearcut" elseif inside(self.achievementBox,x,y) then return "achievements" elseif inside(self.traitsBox,x,y) then return "character_traits" elseif inside(self.codexBox,x,y) then return "character_codex" elseif inside(self.sandboxBox,x,y) then return "skill_sandbox" elseif inside(self.settingsBox,x,y) then return "settings" end
end
function Lobby:drawBackground(w,h)
 local iw,ih=self.background:getDimensions(); local scale=math.max(w/iw,h/ih)*1.025; local dw,dh=iw*scale,ih*scale
 love.graphics.setColor(1,1,1,1); love.graphics.draw(self.background,(w-dw)/2+math.sin(self.time*.12)*4,(h-dh)/2,0,scale,scale)
 love.graphics.setColor(.008,.020,.016,.18); love.graphics.rectangle("fill",0,0,w,h)
 for i=0,24 do local t=i/24; love.graphics.setColor(.005,.016,.012,.9*(1-t)^2); love.graphics.rectangle("fill",t*w*.72,0,w*.72/24+2,h) end
 for i=0,12 do local t=i/12; love.graphics.setColor(.004,.012,.01,.6*(1-t)); love.graphics.rectangle("fill",0,h-170+t*170,w,170/12+1) end
end
function Lobby:draw()
 local w,h=love.graphics.getDimensions(); local f=self.fonts; self:drawBackground(w,h)
 local bw,bh=math.min(420,w*.6),110
 self.clearcutBox={x=(w-bw)/2,y=h*.72-bh/2,w=bw,h=bh}
 F.button(self.clearcutBox,"게임 시작",f.title or f.heading,{primary=true,key="ENT",accent=F.colors.amber})
end
return Lobby
