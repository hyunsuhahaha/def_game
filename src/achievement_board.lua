local F=require("src.frontend_ui")
local Board={};Board.__index=Board
local iconOrder={axe=1,rings=2,crown=3,spark=4,map=5,fire=6,fork=7,claw=8,tree=9,medal=10}
local categories={{"all","전체"},{"species","수종"},{"field","누적"},{"challenge","도전"},{"character","인물"},{"collection","수집"}}
local function easeOut(t)return 1-(1-math.max(0,math.min(1,t)))^3 end
function Board.new(achievements,fonts)
 local image=love.graphics.newImage("assets/ui/achievement-icons-pixel-v1.png");image:setFilter("nearest","nearest")
 local quads={};for k,i in pairs(iconOrder)do quads[k]=love.graphics.newQuad((i-1)*64,0,64,64,image:getDimensions())end
 return setmetatable({achievements=achievements,fonts=fonts,image=image,quads=quads,category="all",scroll=0,rewardBoxes={},tabBoxes={},message=""},Board)
end
function Board:drawIcon(name,x,y,size,alpha)
 love.graphics.setColor(1,1,1,alpha or 1);love.graphics.draw(self.image,self.quads[name] or self.quads.medal,x,y,0,size/64,size/64,32,32)
end
function Board:filtered()
 local out={};for _,d in ipairs(self.achievements:getDefinitions())do if self.category=="all" or d.category==self.category then out[#out+1]=d end end
 table.sort(out,function(a,b)local au,bu=self.achievements:isUnlocked(a.id),self.achievements:isUnlocked(b.id);if au~=bu then return au end return a.id<b.id end);return out
end
function Board:update(dt)self.messageTime=math.max(0,(self.messageTime or 0)-dt)end
function Board:wheelmoved(_,dy)self.scroll=math.max(0,self.scroll-dy*86)end
function Board:keypressed(key)if key=="escape" then return "back" end end
function Board:mousepressed(x,y,button)
 if button~=1 then return end
 if F.inside(self.backBox,x,y)then return "back" end
 for _,b in ipairs(self.tabBoxes)do if F.inside(b,x,y)then self.category=b.id;self.scroll=0;return end end
 for _,b in ipairs(self.rewardBoxes)do if F.inside(b,x,y)then local ok,msg=self.achievements:buy(b.id);self.message=msg;self.messageTime=2.8;return ok and "bought" or nil end end
end
function Board:drawCard(def,x,y,w,h)
 local unlocked=self.achievements:isUnlocked(def.id);local progress=self.achievements:progress(def);local ratio=math.min(1,progress/def.goal)
 F.frame(x,y,w,h,unlocked and F.colors.amber or F.colors.teal,{alpha=.96,selected=unlocked,corner=false})
 self:drawIcon(def.icon,x+42,y+h/2,52,unlocked and 1 or .44)
 love.graphics.setFont(self.fonts.heading);love.graphics.setColor(unlocked and {.98,.91,.67} or {.72,.77,.70});love.graphics.print(def.name,x+80,y+12)
 love.graphics.setFont(self.fonts.small);love.graphics.setColor(.54,.62,.56);love.graphics.printf(def.desc,x+80,y+41,w-172,"left")
 love.graphics.setColor(.045,.065,.055,1);love.graphics.rectangle("fill",x+80,y+h-18,w-170,7,3,3)
 love.graphics.setColor(unlocked and F.colors.amber or F.colors.teal);love.graphics.rectangle("fill",x+80,y+h-18,(w-170)*ratio,7,3,3)
 love.graphics.setFont(self.fonts.micro);love.graphics.setColor(unlocked and F.colors.amber or {.62,.69,.63});love.graphics.printf(unlocked and "완료" or (progress.." / "..def.goal),x+w-88,y+15,68,"right")
 love.graphics.setColor(unlocked and F.colors.amber or {.48,.55,.49});love.graphics.printf("+"..def.points.." P",x+w-88,y+h-30,68,"right")
end
function Board:draw()
 local w,h=love.graphics.getDimensions();local f=self.fonts;local compact=h<620
 love.graphics.setColor(.004,.012,.010,.91);love.graphics.rectangle("fill",0,0,w,h)
 love.graphics.setColor(.95,.62,.18,.72);love.graphics.rectangle("fill",0,0,w,3)
 love.graphics.setFont(f.micro);love.graphics.setColor(F.colors.amber);love.graphics.print("작업 기록실  /  업적",30,20)
 love.graphics.setFont(f.title);love.graphics.setColor(.98,.96,.86);love.graphics.print("벌목 실적 기록",30,43)
 local count=#self.achievements:getDefinitions();love.graphics.setFont(f.small);love.graphics.setColor(.57,.66,.59);love.graphics.print(string.format("달성 %d / %d",self.achievements:unlockedCount(),count),30,88)
 self.backBox={x=w-164,y=24,w=134,h=42};F.button(self.backBox,"지휘실로",f.small,{accent=F.colors.teal,key="ESC"})
 local pointW=190;F.frame(w-pointW-184,24,pointW,56,F.colors.amber,{selected=true,corner=false});self:drawIcon("medal",w-pointW-156,52,42);love.graphics.setFont(f.micro);love.graphics.setColor(.61,.67,.58);love.graphics.print("업적 포인트",w-pointW-126,34);love.graphics.setFont(f.heading);love.graphics.setColor(1,.78,.27);love.graphics.print(self.achievements.data.points.." P",w-pointW-126,51)
 self.tabBoxes={};local tx,ty=190,82;for _,c in ipairs(categories)do local b={x=tx,y=ty,w=72,h=30,id=c[1]};self.tabBoxes[#self.tabBoxes+1]=b;local selected=self.category==c[1];love.graphics.setColor(selected and {.95,.62,.18,.94} or {.045,.072,.061,.96});love.graphics.rectangle("fill",b.x,b.y,b.w,b.h,3,3);love.graphics.setColor(selected and {.12,.08,.02} or {.72,.76,.69});love.graphics.setFont(f.micro);love.graphics.printf(c[2],b.x,b.y+8,b.w,"center");tx=tx+78 end
 local margin,gap,top,bottom=30,18,124,48;local usable=w-margin*2-gap;local leftW=math.floor(usable*.65);local rightW=usable-leftW
 F.frame(margin,top,leftW,h-top-bottom,F.colors.teal,{alpha=.94});F.label("달성 기록",margin+18,top+14,f.micro,F.colors.teal)
 local list=self:filtered();local cols=leftW>=690 and 2 or 1;local cardGap=12;local cardW=(leftW-36-cardGap*(cols-1))/cols;local cardH=92;local contentTop=top+48;local rows=math.ceil(#list/cols);local maxScroll=math.max(0,rows*(cardH+cardGap)-(h-contentTop-bottom-14));self.scroll=math.min(self.scroll,maxScroll)
 love.graphics.setScissor(margin+8,contentTop,leftW-16,h-contentTop-bottom)
 for i,def in ipairs(list)do local col=(i-1)%cols;local row=math.floor((i-1)/cols);self:drawCard(def,margin+18+col*(cardW+cardGap),contentTop+row*(cardH+cardGap)-self.scroll,cardW,cardH)end
 love.graphics.setScissor()
 local rx=margin+leftW+gap;F.frame(rx,top,rightW,h-top-bottom,F.colors.amber,{alpha=.96,selected=true});F.label("기념품 진열장",rx+18,top+14,f.micro,F.colors.amber)
 love.graphics.setFont(f.small);love.graphics.setColor(.58,.65,.57);love.graphics.printf("업적 포인트로 영구 보상을 한 번씩 진열합니다.",rx+18,top+40,rightW-36,"left")
 self.rewardBoxes={};local rewardH=compact and 66 or 82;local rewardStep=compact and 74 or 94;local ry=top+(compact and 68 or 82);for _,r in ipairs(self.achievements:getRewards())do local bought=self.achievements.data.purchased[r.id];local b={x=rx+16,y=ry,w=rightW-32,h=rewardH,id=r.id};self.rewardBoxes[#self.rewardBoxes+1]=b;F.frame(b.x,b.y,b.w,b.h,bought and F.colors.teal or F.colors.amber,{selected=bought,corner=false});self:drawIcon(r.icon,b.x+37,b.y+b.h/2,compact and 44 or 50,bought and .7 or 1);love.graphics.setFont(f.body);love.graphics.setColor(bought and {.64,.74,.67} or {.96,.91,.76});love.graphics.print(r.name,b.x+72,b.y+(compact and 7 or 13));love.graphics.setFont(f.small);love.graphics.setColor(.53,.61,.55);love.graphics.print(r.desc,b.x+72,b.y+(compact and 32 or 41));love.graphics.setFont(f.micro);love.graphics.setColor(bought and F.colors.teal or F.colors.amber);love.graphics.printf(bought and "진열 완료" or (r.cost.." P"),b.x+b.w-98,b.y+(compact and 10 or 16),78,"right");ry=ry+rewardStep end
 if (self.messageTime or 0)>0 then love.graphics.setFont(f.small);love.graphics.setColor(F.colors.amber);love.graphics.printf(self.message,rx+18,h-bottom-33,rightW-36,"center")end
 F.footer(w,h,"마우스 휠  기록 이동    ·    보상 클릭  진열    ·    ESC  지휘실",f.small)
end
function Board:drawPopup()
 local p=self.achievements.popup;if not p then return end
 local w=love.graphics.getWidth();local t=p.t;local enter=easeOut(math.min(1,t/.38));local leave=math.max(0,math.min(1,(p.dur-t)/.42));local a=math.min(enter,leave);local pw,ph=420,78;local x=w-pw-22+(1-enter)*90;local y=94
 love.graphics.push("all")
 for i=1,12 do local life=math.max(0,1-t/1.35);if life>0 then local ang=i*2.399;local rr=(22+t*72)*(0.72+(i%3)*.14);local px=x+56+math.cos(ang)*rr;local py=y+38+math.sin(ang)*rr*.5+t*24;local c=i%3==0 and F.colors.amber or (i%3==1 and F.colors.teal or {.76,.28,.14});love.graphics.setColor(c[1],c[2],c[3],life*a);love.graphics.rectangle("fill",math.floor(px),math.floor(py),i%2==0 and 5 or 3,i%2==0 and 3 or 5)end end
 love.graphics.setColor(0,0,0,.48*a);love.graphics.rectangle("fill",x+6,y+8,pw,ph,5,5);love.graphics.setColor(.018,.037,.030,.98*a);love.graphics.rectangle("fill",x,y,pw,ph,5,5);love.graphics.setColor(.95,.62,.18,.9*a);love.graphics.rectangle("fill",x,y,5,ph);love.graphics.rectangle("line",x+.5,y+.5,pw-1,ph-1,5,5);love.graphics.setColor(1,.82,.34,.12*a);love.graphics.rectangle("fill",x+6,y+6,pw-12,3)
 self:drawIcon(p.def.icon,x+42,y+39,58,a);love.graphics.setFont(self.fonts.micro);love.graphics.setColor(1,.67,.20,a);love.graphics.print("업적 달성",x+83,y+12);love.graphics.setFont(self.fonts.heading);love.graphics.setColor(.98,.95,.82,a);love.graphics.print(p.def.name,x+83,y+30);love.graphics.setFont(self.fonts.small);love.graphics.setColor(.63,.72,.65,a);love.graphics.print("업적 포인트 +"..p.def.points.." P",x+83,y+56)
 love.graphics.pop()
end
return Board
