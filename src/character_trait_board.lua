local UI = require("src.ui")
local Frontend = require("src.frontend_ui")

local CharacterTraitBoard = {}
CharacterTraitBoard.__index = CharacterTraitBoard

-- 기존 작업자 연구 화면은 삭제하지 않았다. 현재 프로토타입이 흡연자 기록전이므로
-- 로비에서는 실제 적용되는 두 연구군만 의도적으로 노출한다.
local archivedJobOrder = {"physical", "fire", "toxic", "developer", "miner", "philosopher", "universal"}
local ACTIVE_DEVELOPMENT_MODE="score_attack"
local jobOrder = ACTIVE_DEVELOPMENT_MODE=="score_attack" and {"fire","universal"} or archivedJobOrder
local jobNames = {physical="생계형 나무꾼", fire="흡연자", toxic="비건 단체 회장", developer="부동산 개발업자", miner="코인 채굴꾼", philosopher="차라투스트라는 이렇게 말했다", universal="공용 복지"}
local jobTabNames = {philosopher="차라투스트라"}

local function inside(box, x, y)
    return box and x >= box.x and x <= box.x + box.w and y >= box.y and y <= box.y + box.h
end

local function clamp(value, low, high)
    return math.max(low, math.min(high, value))
end

local function nodeColor(node, alpha)
    local color = node.color or {.75,.68,.42}
    return color[1], color[2], color[3], alpha or 1
end

local function vivid(color, alpha)
    local maxc=math.max(color[1],color[2],color[3])
    local boost=maxc>0 and math.min(1.35,.96/maxc) or 1
    return math.min(1,color[1]*boost+.04),math.min(1,color[2]*boost+.04),math.min(1,color[3]*boost+.04),alpha or 1
end

local function drawDiamond(cx,cy,r,mode)
    love.graphics.polygon(mode,cx,cy-r,cx+r,cy,cx,cy+r,cx-r,cy)
end

local function requirementsMet(store, node)
    for _, requirement in ipairs(store:getRequirements(node)) do
        if store:getLevel(requirement[1]) < requirement[2] then return false end
    end
    return true
end

local function drawRing(cx, cy, radius, fromAngle, toAngle, segments)
    local points = {}
    segments = segments or 28
    for i=0,segments do
        local angle = fromAngle + (toAngle-fromAngle) * i / segments
        points[#points+1] = cx+math.cos(angle)*radius
        points[#points+1] = cy+math.sin(angle)*radius
    end
    love.graphics.line(unpack(points))
end

local function drawHex(cx, cy, radius, mode)
    local points = {}
    for i=0,5 do
        local angle = -math.pi/2 + i*math.pi/3
        points[#points+1] = cx+math.cos(angle)*radius
        points[#points+1] = cy+math.sin(angle)*radius
    end
    love.graphics.polygon(mode, unpack(points))
end

local function drawGlyph(icon, cx, cy, size)
    local s = size
    love.graphics.setLineWidth(math.max(1.4,s*.12))
    if icon=="axe" or icon=="sharpen" or icon=="split" or icon=="stump" or icon=="fist" then
        love.graphics.line(cx-s*.46,cy+s*.42,cx+s*.32,cy-s*.38)
        love.graphics.polygon("fill",cx+s*.08,cy-s*.38,cx+s*.46,cy-s*.48,cx+s*.34,cy-s*.08)
    elseif icon=="clock" or icon=="moon" then
        love.graphics.circle("line",cx,cy,s*.48)
        love.graphics.line(cx,cy,cx,cy-s*.28,cx+s*.24,cy+s*.10)
    elseif icon=="document" or icon=="report" or icon=="policy" or icon=="certificate" or icon=="coupon" then
        love.graphics.rectangle("line",cx-s*.36,cy-s*.46,s*.72,s*.92,2,2)
        love.graphics.line(cx-s*.22,cy-s*.16,cx+s*.20,cy-s*.16,cx-s*.22,cy+s*.04,cx+s*.12,cy+s*.04,cx-s*.22,cy+s*.24,cx+s*.22,cy+s*.24)
    elseif icon=="cigarette" or icon=="filter" or icon=="pack" then
        love.graphics.push(); love.graphics.translate(cx,cy); love.graphics.rotate(-.42)
        love.graphics.rectangle("fill",-s*.48,-s*.11,s*.70,s*.22,2,2)
        love.graphics.setColor(1,.34,.12,1); love.graphics.rectangle("fill",s*.22,-s*.11,s*.20,s*.22,2,2)
        love.graphics.pop()
    elseif icon=="ember" or icon=="warning" or icon=="blast" then
        love.graphics.polygon("fill",cx,cy-s*.50,cx+s*.40,cy+s*.03,cx+s*.18,cy+s*.46,cx-s*.22,cy+s*.42,cx-s*.40,cy+s*.02)
        love.graphics.setColor(.18,.08,.03,.75); love.graphics.polygon("fill",cx,cy-s*.08,cx+s*.15,cy+s*.30,cx-s*.14,cy+s*.30)
    elseif icon=="smoke" or icon=="ash" or icon=="wind" or icon=="question" then
        love.graphics.circle("line",cx-s*.20,cy+s*.10,s*.22)
        love.graphics.circle("line",cx+s*.10,cy-s*.04,s*.28)
        love.graphics.line(cx-s*.42,cy+s*.32,cx+s*.42,cy+s*.32)
    elseif icon=="leaf" or icon=="heartleaf" or icon=="basket" then
        love.graphics.polygon("line",cx-s*.44,cy+s*.14,cx-s*.10,cy-s*.45,cx+s*.45,cy-s*.26,cx+s*.28,cy+s*.34,cx-s*.18,cy+s*.46)
        love.graphics.line(cx-s*.30,cy+s*.34,cx+s*.27,cy-s*.24)
    elseif icon=="tooth" or icon=="tongs" or icon=="fork" then
        love.graphics.line(cx-s*.34,cy-s*.42,cx-s*.14,cy+s*.38,cx,cy+s*.02,cx+s*.14,cy+s*.38,cx+s*.34,cy-s*.42)
    elseif icon=="stamp" or icon=="ruler" or icon=="machine" or icon=="map" or icon=="helmet" or icon=="tower" or icon=="road" then
        love.graphics.rectangle("line",cx-s*.40,cy-s*.28,s*.80,s*.60,2,2)
        love.graphics.line(cx-s*.40,cy-s*.28,cx,cy-s*.48,cx+s*.40,cy-s*.28)
        love.graphics.line(cx-s*.18,cy+s*.30,cx-s*.18,cy,cx+s*.18,cy,cx+s*.18,cy+s*.30)
    elseif icon=="coins" or icon=="donation" or icon=="lunch" then
        love.graphics.circle("line",cx-s*.12,cy-s*.08,s*.31)
        love.graphics.circle("line",cx+s*.16,cy+s*.14,s*.31)
    else
        love.graphics.polygon("line",cx,cy-s*.48,cx+s*.44,cy,cx,cy+s*.48,cx-s*.44,cy)
        love.graphics.circle("fill",cx,cy,s*.10)
    end
    love.graphics.setLineWidth(1)
end

function CharacterTraitBoard.new(store, fonts, sprites)
    local first=store:getScoreAttackNodes("fire")[1]
    return setmetatable({
        store=store, fonts=fonts, sprites=sprites, selectedJob="fire",activeDevelopmentMode=ACTIVE_DEVELOPMENT_MODE,
        tabBoxes={}, nodeBoxes={}, nodeHover={}, particles={}, time=0,
        message="", messageTime=0, messageKind="ok", unlockFx=nil,
        selectedNodeId=first and first.id or"fire_score_prewarm", blockedNode=nil, blockedTime=0, tabPulse=0,
        canvasW=2200,canvasH=1700,panX=1000,panY=800,zoom=.62,panVX=0,panVY=0,drag=nil,viewport=nil,
        minimapBox=nil,resetViewBox=nil
    }, CharacterTraitBoard)
end

function CharacterTraitBoard:nodesFor(job)
    if self.activeDevelopmentMode=="score_attack"then return self.store:getScoreAttackNodes(job)end
    return self.store:getNodes(job)
end

function CharacterTraitBoard:selectJob(job)
    if self.selectedJob == job then return end
    local nodes=self:nodesFor(job)
    self.selectedJob, self.selectedNodeId = job, nodes[1]and nodes[1].id or nil
    self.tabPulse, self.messageTime, self.blockedTime = 1, 0, 0
    self.panX,self.panY,self.zoom,self.panVX,self.panVY=1000,800,.62,0,0
end

function CharacterTraitBoard:clampCamera()
    if not self.viewport then return end
    local halfW=self.viewport.w/(2*self.zoom)
    local halfH=self.viewport.h/(2*self.zoom)
    self.panX=clamp(self.panX,math.min(halfW,self.canvasW/2),math.max(self.canvasW-halfW,self.canvasW/2))
    self.panY=clamp(self.panY,math.min(halfH,self.canvasH/2),math.max(self.canvasH-halfH,self.canvasH/2))
end

function CharacterTraitBoard:selectAt(x,y)
    for _,box in ipairs(self.nodeBoxes) do
        if inside(box,x,y) then
            self.selectedNodeId=box.id
            return "selected"
        end
    end
end

function CharacterTraitBoard:buySelected()
    local id=self.selectedNodeId
    if not id then return end
    local box
    for _,b in ipairs(self.nodeBoxes) do if b.id==id then box=b; break end end
    local ok,message=self.store:buy(id)
    self.message,self.messageTime=message,2.5
    self.messageKind=ok and "ok" or "blocked"
    if ok and box then self:burst(box,box.node); self.blockedNode=nil
    elseif not ok then self.blockedNode,self.blockedTime=id,.34 end
    return ok and "bought" or "blocked"
end

function CharacterTraitBoard:update(dt)
    self.time = self.time + dt
    self.messageTime = math.max(0, self.messageTime-dt)
    self.blockedTime = math.max(0, self.blockedTime-dt)
    self.tabPulse = math.max(0, self.tabPulse-dt*2.5)
    if self.drag then
        local mx,my=love.mouse.getPosition()
        if love.mouse.isDown(self.drag.button or 1) then
            local dx,dy=mx-self.drag.x,my-self.drag.y
            if dx*dx+dy*dy>9 then self.drag.moved=true end
            self.panX=self.drag.panX-dx/self.zoom*1.16
            self.panY=self.drag.panY-dy/self.zoom*1.16
            local frameDx,frameDy=mx-(self.drag.lastX or mx),my-(self.drag.lastY or my)
            self.panVX=-frameDx/self.zoom/math.max(dt,.001)*1.16
            self.panVY=-frameDy/self.zoom/math.max(dt,.001)*1.16
            self.drag.lastX,self.drag.lastY=mx,my
            self:clampCamera()
        else
            if not self.drag.moved and (self.drag.button or 1)==1 then self:selectAt(mx,my) end
            self.drag=nil
        end
    else
        self.panX=self.panX+self.panVX*dt; self.panY=self.panY+self.panVY*dt
        local damping=math.exp(-dt*7); self.panVX,self.panVY=self.panVX*damping,self.panVY*damping
        if math.abs(self.panVX)<1 then self.panVX=0 end
        if math.abs(self.panVY)<1 then self.panVY=0 end
        self:clampCamera()
    end
    if self.unlockFx then
        self.unlockFx.life = self.unlockFx.life-dt
        if self.unlockFx.life <= 0 then self.unlockFx=nil end
    end
    for i=#self.particles,1,-1 do
        local p=self.particles[i]
        p.life=p.life-dt; p.x=p.x+p.vx*dt; p.y=p.y+p.vy*dt
        p.vx=p.vx*(1-dt*1.8); p.vy=p.vy*(1-dt*1.8)+32*dt
        if p.life<=0 then table.remove(self.particles,i) end
    end
end

function CharacterTraitBoard:keypressed(key)
    if key == "escape" or key == "t" then return "back" end
    local index = tonumber(key)
    if index and jobOrder[index] then self:selectJob(jobOrder[index]) end
end

function CharacterTraitBoard:burst(box, node)
    local r,g,b=nodeColor(node)
    self.unlockFx={x=box.cx,y=box.cy,life=1,maxLife=1,color={r,g,b},node=node}
    for i=1,34 do
        local angle=(i/34)*math.pi*2 + math.random()*.12
        local speed=75+math.random()*170
        self.particles[#self.particles+1]={x=box.cx,y=box.cy,vx=math.cos(angle)*speed,vy=math.sin(angle)*speed,life=.55+math.random()*.55,maxLife=1,color={r,g,b}}
    end
end

function CharacterTraitBoard:mousepressed(x, y, button)
    if button ~= 1 and button ~= 2 then return end
    if inside(self.backBox, x, y) then return "back" end
    for i, box in ipairs(self.tabBoxes) do
        if inside(box, x, y) then self:selectJob(jobOrder[i]); return "selected" end
    end
    if button==1 and inside(self.buyButtonBox,x,y) then return self:buySelected() end
    if inside(self.resetViewBox,x,y) then
        self.panX,self.panY,self.zoom,self.panVX,self.panVY=1000,800,.62,0,0
        return "reset_view"
    end
    if inside(self.minimapBox,x,y) then
        self.panX=(x-self.minimapBox.x)/self.minimapBox.w*self.canvasW
        self.panY=(y-self.minimapBox.y)/self.minimapBox.h*self.canvasH
        self.panVX,self.panVY=0,0
        self:clampCamera(); return "minimap"
    end
    if inside(self.viewport,x,y) then
        self.panVX,self.panVY=0,0
        self.drag={x=x,y=y,lastX=x,lastY=y,panX=self.panX,panY=self.panY,moved=false,button=button}
        return "dragging"
    end
end

function CharacterTraitBoard:wheelmoved(_,delta)
    if delta==0 or not self.viewport then return end
    local mx,my=love.mouse.getPosition()
    if not inside(self.viewport,mx,my) then return end
    local beforeX=self.panX+(mx-(self.viewport.x+self.viewport.w/2))/self.zoom
    local beforeY=self.panY+(my-(self.viewport.y+self.viewport.h/2))/self.zoom
    self.zoom=clamp(self.zoom*(delta>0 and 1.22 or 1/1.22),.36,1.60)
    self.panVX,self.panVY=0,0
    self.panX=beforeX-(mx-(self.viewport.x+self.viewport.w/2))/self.zoom
    self.panY=beforeY-(my-(self.viewport.y+self.viewport.h/2))/self.zoom
    self:clampCamera()
end

function CharacterTraitBoard:nodeWorld(node)
    return node.wx or (200+(node.x or .5)*1600),node.wy or (500+(node.y or .5)*900)
end

function CharacterTraitBoard:nodeLabel(node)
    return node.name
end

function CharacterTraitBoard:nodePosition(bounds, node)
    local wx,wy=self:nodeWorld(node)
    return bounds.x+bounds.w/2+(wx-self.panX)*self.zoom,bounds.y+bounds.h/2+(wy-self.panY)*self.zoom
end

function CharacterTraitBoard:drawConnection(bounds, from, to, active, available, color)
    local x1,y1=self:nodePosition(bounds,from)
    local x2,y2=self:nodePosition(bounds,to)
    local rr,gg,bb=vivid(color)
    local locked=not active and not available
    love.graphics.setLineWidth(active and 10 or 7)
    if locked then love.graphics.setColor(.92,.04,.30,.10) else love.graphics.setColor(rr,gg,bb,active and .22 or .11) end
    love.graphics.line(x1,y1,x2,y2)
    love.graphics.setLineWidth(active and 3.5 or 2.25)
    if locked then love.graphics.setColor(.98,.08,.36,.62) else love.graphics.setColor(rr,gg,bb,active and 1 or .78) end
    love.graphics.line(x1,y1,x2,y2)
    love.graphics.setLineWidth(1); love.graphics.setColor(1,1,1,active and .30 or .12)
    love.graphics.line(x1,y1-1,x2,y2-1)
    if active then
        local travel=(self.time*.72 + (to.x or 0)*.7 + (to.y or 0)*.3)%1
        love.graphics.setColor(.78,1,1,.96)
        love.graphics.circle("fill",x1+(x2-x1)*travel,y1+(y2-y1)*travel,4)
    end
    love.graphics.setLineWidth(1)
end

function CharacterTraitBoard:drawNode(box, node, level, statusOk, requirementReady, hovered)
    local cx,cy,r=box.cx,box.cy,(node.capstone and 31 or 26)*(box.scale or 1)
    local rr,gg,bb=vivid(node.color or {.75,.68,.42})
    local unlocked=level>0
    local pulse=.5+math.sin(self.time*3+cx*.01)*.5
    if requirementReady and level<node.max then
        love.graphics.setColor(rr,gg,bb,(statusOk and .18 or .08)+pulse*.07)
        drawDiamond(cx,cy,r+17+(hovered and 4 or 0),"fill")
    end
    love.graphics.setColor(0,0,0,.58); drawDiamond(cx+3,cy+6,r+9,"fill")
    love.graphics.setColor(rr,gg,bb,unlocked and .34 or (requirementReady and .16 or .07)); drawDiamond(cx,cy,r+8,"fill")
    love.graphics.setColor(.008,.014,.026,.99); drawDiamond(cx,cy,r+2,"fill")
    love.graphics.setLineWidth(hovered and 4 or (unlocked and 3 or 2))
    love.graphics.setColor(rr,gg,bb,unlocked and 1 or (requirementReady and .88 or .42)); drawDiamond(cx,cy,r+5,"line")
    love.graphics.setLineWidth(1); love.graphics.setColor(.82,1,1,unlocked and .48 or .16); drawDiamond(cx,cy-1,r,"line")
    if level>0 then
        love.graphics.setLineWidth(3); love.graphics.setColor(rr,gg,bb,1)
        drawRing(cx,cy,r+12,-math.pi/2,-math.pi/2+math.pi*2*(level/node.max),math.max(8,node.max*8))
    end
    love.graphics.setColor(unlocked and {1,1,.88,1} or {rr,gg,bb,requirementReady and .92 or .45})
    drawGlyph(node.icon,cx,cy,r*.82)
    if statusOk and not unlocked then
        love.graphics.setColor(.58,1,.52,.95); love.graphics.rectangle("fill",cx+r*.42,cy-r*.78,9,3); love.graphics.rectangle("fill",cx+r*.42+3,cy-r*.78-3,3,9)
    end
    love.graphics.setLineWidth(1)
end

function CharacterTraitBoard:drawCharacterDossier(x,y,w,h,job,focusNode)
    local fonts=self.fonts
    local group=self.store:getJobs()[job]
    local palette=group.palette
    love.graphics.setColor(.008,.012,.045,.96); love.graphics.rectangle("fill",x,y,w,h,10,10)
    love.graphics.setColor(palette[1],palette[2],palette[3],.7); love.graphics.rectangle("fill",x,y,4,h,3,3)
    love.graphics.setColor(palette[1],palette[2],palette[3],.36); love.graphics.rectangle("line",x+.5,y+.5,w-1,h-1,10,10)
    love.graphics.setFont(fonts.small); love.graphics.setColor(palette[1],palette[2],palette[3],.9)
    love.graphics.print("연구 대상  /  "..jobNames[job],x+20,y+18)
    local compact=h<430
    love.graphics.setFont(compact and fonts.small or fonts.body); love.graphics.setColor(.96,.94,.82)
    love.graphics.printf(group.tagline,x+20,y+46,w-40,"left")
    love.graphics.setFont(fonts.small); love.graphics.setColor(.65,.72,.64)
    love.graphics.printf(group.doctrine,x+20,y+(compact and 72 or 76),w-40,"left")
    -- 공용 특성 탭은 특정 캐릭터가 아니므로 초상화를 아예 생략한다. 전용 스프라이트가
    -- 있는 직업은 해당 고정 모델을 사용하고, 아직 없는 직업만 physical로 폴백한다.
    local sprite = job ~= "universal" and (self.sprites[job] or self.sprites.physical) or nil
    if sprite then
        local fw,fh=sprite.image:getWidth()/6,sprite.image:getHeight()/2
        local frame=math.floor(self.time*4)%6
        local quad=love.graphics.newQuad(frame*fw,0,fw,fh,sprite.image:getDimensions())
        local scale=math.min((w-44)/fw,(h*(compact and .25 or .42))/fh)
        love.graphics.setColor(0,0,0,.28); love.graphics.ellipse("fill",x+w/2,y+h*.56,w*.26,12)
        love.graphics.setColor(1,1,1,1)
        love.graphics.draw(sprite.image,quad,x+w/2,y+h*.58,0,scale,scale,fw/2,(sprite.walkFeet or {})[frame+1] or 190)
    end
    local detailY=y+h-150
    love.graphics.setColor(.025,.035,.085,.98); love.graphics.rectangle("fill",x+12,detailY,w-24,136,6,6)
    love.graphics.setColor(focusNode.color[1],focusNode.color[2],focusNode.color[3],.8); love.graphics.rectangle("fill",x+12,detailY,3,136,2,2)
    local level=self.store:getLevel(focusNode.id)
    local ok,reason,cost=self.store:status(focusNode.id)
    love.graphics.setFont(fonts.heading); love.graphics.setColor(.96,.94,.84)
    love.graphics.printf(self:nodeLabel(focusNode),x+28,detailY+14,w-54,"left")
    love.graphics.setFont(fonts.small); love.graphics.setColor(.72,.79,.69)
    love.graphics.printf(focusNode.desc,x+28,detailY+46,w-54,"left")
    love.graphics.setColor(focusNode.color[1],focusNode.color[2],focusNode.color[3],.95)
    love.graphics.print("단계 "..level.." / "..focusNode.max,x+28,detailY+78)
    if level>=focusNode.max then
        self.buyButtonBox=nil
        love.graphics.setColor(.58,.63,.55,1)
        love.graphics.printf("연구 완료",x+28,detailY+104,w-54,"left")
    elseif ok then
        self.buyButtonBox={x=x+28,y=detailY+100,w=w-56,h=32}
        Frontend.button(self.buyButtonBox,"강화  ·  "..cost.." P",fonts.small,{primary=true,accent=focusNode.color})
    else
        self.buyButtonBox=nil
        love.graphics.setColor(.58,.63,.55,1)
        love.graphics.printf(reason,x+28,detailY+104,w-54,"left")
    end
end

function CharacterTraitBoard:drawUnlockFx()
    local fx=self.unlockFx
    if fx then
        local progress=1-fx.life/fx.maxLife
        local r,g,b=fx.color[1],fx.color[2],fx.color[3]
        love.graphics.setLineWidth(4*(1-progress)+1); love.graphics.setColor(r,g,b,(1-progress)*.9)
        love.graphics.circle("line",fx.x,fx.y,28+progress*88)
        love.graphics.setLineWidth(1); love.graphics.setColor(1,.96,.76,(1-progress)*.24)
        love.graphics.circle("fill",fx.x,fx.y,50*(1-progress))
    end
    for _,p in ipairs(self.particles) do
        local alpha=clamp(p.life/p.maxLife,0,1)
        love.graphics.setColor(p.color[1],p.color[2],p.color[3],alpha)
        love.graphics.polygon("fill",p.x,p.y-3,p.x+3,p.y,p.x,p.y+3,p.x-3,p.y)
    end
end

function CharacterTraitBoard:draw()
    local w,h=love.graphics.getDimensions()
    local fonts=self.fonts
    local group=self.store:getJobs()[self.selectedJob]
    local palette=group.palette
    Frontend.backdrop(w,h,palette,.76)
    love.graphics.setColor(.008,.006,.075,.82); love.graphics.rectangle("fill",0,0,w,h)
    for i=0,14 do
        love.graphics.setColor(palette[1],palette[2],palette[3],.018*(1-i/15))
        love.graphics.circle("fill",w*.68,h*.54,120+i*36)
    end
    self.backBox={x=26,y=22,w=132,h=40}
    Frontend.button(self.backBox,"← 돌아가기",fonts.small,{accent=palette})
    love.graphics.setFont(fonts.micro or fonts.small); love.graphics.setColor(palette); love.graphics.print("벌목 기록 모드",184,16)
    love.graphics.setFont(fonts.title); love.graphics.setColor(.98,.96,.84); love.graphics.print("기록전 영구 연구",184,32)
    love.graphics.setFont(fonts.small); love.graphics.setColor(.66,.73,.64); love.graphics.print("첫 불씨·투척·연소·나무 허용량을 강화합니다",184,68)
    Frontend.frame(w-226,18,196,52,palette,{selected=true})
    love.graphics.setFont(fonts.small); love.graphics.setColor(.62,.68,.58); love.graphics.print("보유 성과 포인트",w-207,25)
    love.graphics.setFont(fonts.heading); love.graphics.setColor(1,.84,.38); love.graphics.print(tostring(self.store.data.currency).." P",w-207,42)

    local tabY,tabGap=86,8
    local tabCount=#jobOrder
    local tabW=math.min(232,(w-52-tabGap*(tabCount-1))/tabCount)
    local startX=(w-(tabW*tabCount+tabGap*(tabCount-1)))/2
    self.tabBoxes={}
    for i,job in ipairs(jobOrder) do
        local box={x=startX+(i-1)*(tabW+tabGap),y=tabY,w=tabW,h=44}
        self.tabBoxes[i]=box
        local selected=job==self.selectedJob
        local jobPalette=self.store:getJobs()[job].palette
        love.graphics.setColor(.008,.012,.052,selected and .99 or .88); love.graphics.rectangle("fill",box.x,box.y,box.w,box.h,4,4)
        local vr,vg,vb=vivid(jobPalette)
        love.graphics.setColor(vr,vg,vb,selected and 1 or .48)
        love.graphics.rectangle("fill",box.x,box.y,selected and 4 or 2,box.h,2,2)
        if selected then love.graphics.rectangle("fill",box.x+10,box.y+box.h-2,box.w-20,2) end
        love.graphics.setFont(fonts.body); love.graphics.setColor(selected and {1,1,.90,1} or {.72,.78,.82,1})
        love.graphics.printf(i.."  "..(jobTabNames[job] or jobNames[job]),box.x,box.y+12,box.w,"center")
    end

    local dossier={x=30,y=150,w=math.min(300,w*.235),h=h-176}
    local graph={x=dossier.x+dossier.w+20,y=150,w=w-dossier.x-dossier.w-50,h=h-176}
    self.viewport=graph
    self:clampCamera()
    love.graphics.setColor(.004,.006,.055,.96); love.graphics.rectangle("fill",graph.x,graph.y,graph.w,graph.h,10,10)
    love.graphics.setScissor(graph.x,graph.y,graph.w,graph.h)

    -- 카메라와 함께 움직이는 월드 격자: 현재 화면이 큰 연구 공간의 일부라는 감각을 준다.
    local grid=160
    local left=self.panX-graph.w/(2*self.zoom)
    local right=self.panX+graph.w/(2*self.zoom)
    local top=self.panY-graph.h/(2*self.zoom)
    local bottom=self.panY+graph.h/(2*self.zoom)
    for wx=math.floor(left/grid)*grid,right,grid do
        local sx=graph.x+graph.w/2+(wx-self.panX)*self.zoom
        love.graphics.setColor(.14,.52,.78,wx%480==0 and .11 or .045)
        love.graphics.line(sx,graph.y,sx,graph.y+graph.h)
    end
    for wy=math.floor(top/grid)*grid,bottom,grid do
        local sy=graph.y+graph.h/2+(wy-self.panY)*self.zoom
        love.graphics.setColor(.38,.18,.68,wy%480==0 and .10 or .04)
        love.graphics.line(graph.x,sy,graph.x+graph.w,sy)
    end

    local nodes=self:nodesFor(self.selectedJob)
    local nodeById={}
    for _,node in ipairs(nodes) do nodeById[node.id]=node end
    for _,node in ipairs(nodes) do
        for _,requirement in ipairs(self.store:getRequirements(node)) do
            local parent=nodeById[requirement[1]]
            if parent then
                local parentReady=self.store:getLevel(parent.id)>=requirement[2]
                self:drawConnection(graph,parent,node,parentReady and self.store:getLevel(node.id)>0,parentReady,node.color)
            end
        end
    end

    local mx,my=love.mouse.getPosition()
    self.nodeBoxes={}
    local nodeScale=clamp(self.zoom,.68,1.18)
    for _,node in ipairs(nodes) do
        local cx,cy=self:nodePosition(graph,node)
        if cx>=graph.x-80 and cx<=graph.x+graph.w+80 and cy>=graph.y-80 and cy<=graph.y+graph.h+80 then
            local radius=(node.capstone and 42 or 37)*nodeScale
            local box={id=node.id,node=node,cx=cx,cy=cy,x=cx-radius,y=cy-radius,w=radius*2,h=radius*2,scale=nodeScale}
            self.nodeBoxes[#self.nodeBoxes+1]=box
            local hovered=inside(box,mx,my) and not self.drag
            local target=hovered and 1 or 0
            self.nodeHover[node.id]=(self.nodeHover[node.id] or 0)+(target-(self.nodeHover[node.id] or 0))*.22
            local ok=self.store:status(node.id)
            local shake=0
            if self.blockedNode==node.id and self.blockedTime>0 then shake=math.sin(self.blockedTime*95)*4*self.blockedTime/.34 end
            box.cx=box.cx+shake
            self:drawNode(box,node,self.store:getLevel(node.id),ok,requirementsMet(self.store,node),hovered)
            if self.zoom>=.50 then
                local labelY=box.cy+39*nodeScale
                if hovered or node.id==self.selectedNodeId then love.graphics.setColor(.004,.006,.035,.88); love.graphics.rectangle("fill",box.cx-92,labelY-2,184,22,4,4) end
                love.graphics.setFont(fonts.small); love.graphics.setColor(hovered and {1,1,.82,1} or {.82,.88,.92,.90})
                love.graphics.printf(self:nodeLabel(node),box.cx-88,labelY+2,176,"center")
            end
        end
    end
    self:drawUnlockFx()
    love.graphics.setScissor()
    love.graphics.setColor(.24,.82,1,.34); love.graphics.rectangle("line",graph.x+.5,graph.y+.5,graph.w-1,graph.h-1,10,10)

    -- 고정 HUD: 탐색 조작, 초기 위치, 미니맵을 월드 위에 겹쳐 둔다.
    love.graphics.setColor(.004,.008,.035,.96); love.graphics.rectangle("fill",graph.x+10,graph.y+10,graph.w-20,38,5,5)
    love.graphics.setFont(fonts.small); love.graphics.setColor(palette[1],palette[2],palette[3],.88)
    love.graphics.print("기록전 적용 연구  ·  "..#nodes.."개 노드",graph.x+24,graph.y+22)
    love.graphics.setColor(.72,.80,.86,.88)
    love.graphics.printf("좌/우 드래그 이동  ·  휠 확대/축소  ·  클릭 해금",graph.x+220,graph.y+22,graph.w-244,"right")
    self.resetViewBox={x=graph.x+16,y=graph.y+58,w=94,h=28}
    love.graphics.setColor(.04,.09,.06,.92); love.graphics.rectangle("fill",self.resetViewBox.x,self.resetViewBox.y,self.resetViewBox.w,self.resetViewBox.h,5,5)
    love.graphics.setColor(.72,.80,.69,.72); love.graphics.rectangle("line",self.resetViewBox.x+.5,self.resetViewBox.y+.5,self.resetViewBox.w-1,self.resetViewBox.h-1,5,5)
    love.graphics.setFont(fonts.small); love.graphics.printf("시작점으로",self.resetViewBox.x,self.resetViewBox.y+7,self.resetViewBox.w,"center")

    self.minimapBox={x=graph.x+graph.w-174,y=graph.y+58,w=156,h=96}
    love.graphics.setColor(.005,.016,.011,.94); love.graphics.rectangle("fill",self.minimapBox.x,self.minimapBox.y,self.minimapBox.w,self.minimapBox.h,5,5)
    love.graphics.setColor(palette[1],palette[2],palette[3],.35); love.graphics.rectangle("line",self.minimapBox.x+.5,self.minimapBox.y+.5,self.minimapBox.w-1,self.minimapBox.h-1,5,5)
    for _,node in ipairs(nodes) do
        local wx,wy=self:nodeWorld(node)
        local nx=self.minimapBox.x+wx/self.canvasW*self.minimapBox.w
        local ny=self.minimapBox.y+wy/self.canvasH*self.minimapBox.h
        local level=self.store:getLevel(node.id)
        love.graphics.setColor(node.color[1],node.color[2],node.color[3],level>0 and .95 or .38)
        love.graphics.rectangle("fill",nx-1.5,ny-1.5,node.capstone and 4 or 3,node.capstone and 4 or 3)
    end
    local visibleW=graph.w/self.zoom/self.canvasW*self.minimapBox.w
    local visibleH=graph.h/self.zoom/self.canvasH*self.minimapBox.h
    local viewX=self.minimapBox.x+self.panX/self.canvasW*self.minimapBox.w-visibleW/2
    local viewY=self.minimapBox.y+self.panY/self.canvasH*self.minimapBox.h-visibleH/2
    love.graphics.setColor(1,.9,.52,.72); love.graphics.rectangle("line",viewX,viewY,visibleW,visibleH)

    local focus=self.store:getNode(self.selectedNodeId) or nodes[1]
    self:drawCharacterDossier(dossier.x,dossier.y,dossier.w,dossier.h,self.selectedJob,focus)
    if self.messageTime>0 then
        local width=math.min(520,w*.46)
        love.graphics.setColor(.008,.02,.014,.96); love.graphics.rectangle("fill",w/2-width/2,h-54,width,38,7,7)
        local success=self.messageKind=="ok"
        love.graphics.setColor(success and {1,.82,.35,1} or {1,.43,.32,1}); love.graphics.rectangle("fill",w/2-width/2,h-54,4,38,2,2)
        love.graphics.setFont(fonts.body); love.graphics.printf(self.message,w/2-width/2+12,h-44,width-24,"center")
    end
end

return CharacterTraitBoard
