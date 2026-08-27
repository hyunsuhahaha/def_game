local UI = require("src.ui")

local CharacterTraitBoard = {}
CharacterTraitBoard.__index = CharacterTraitBoard

local jobOrder = {"physical", "fire", "toxic", "developer", "miner", "philosopher", "universal"}
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
        points[#points+1], points[#points+1] = cx+math.cos(angle)*radius, cy+math.sin(angle)*radius
    end
    love.graphics.line(points)
end

local function drawHex(cx, cy, radius, mode)
    local points = {}
    for i=0,5 do
        local angle = -math.pi/2 + i*math.pi/3
        points[#points+1], points[#points+1] = cx+math.cos(angle)*radius, cy+math.sin(angle)*radius
    end
    love.graphics.polygon(mode, points)
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
    elseif icon=="tooth" or icon=="tongs" then
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
    return setmetatable({
        store=store, fonts=fonts, sprites=sprites, selectedJob="physical",
        tabBoxes={}, nodeBoxes={}, nodeHover={}, particles={}, time=0,
        message="", messageTime=0, messageKind="ok", unlockFx=nil,
        selectedNodeId="physical_quota", blockedNode=nil, blockedTime=0, tabPulse=0,
        canvasW=3300,canvasH=1900,panX=820,panY=950,zoom=.86,drag=nil,viewport=nil,
        minimapBox=nil,resetViewBox=nil
    }, CharacterTraitBoard)
end

function CharacterTraitBoard:selectJob(job)
    if self.selectedJob == job then return end
    self.selectedJob, self.selectedNodeId = job, self.store:getNodes(job)[1].id
    self.tabPulse, self.messageTime, self.blockedTime = 1, 0, 0
    self.panX,self.panY,self.zoom=820,950,.86
end

function CharacterTraitBoard:clampCamera()
    if not self.viewport then return end
    local halfW=self.viewport.w/(2*self.zoom)
    local halfH=self.viewport.h/(2*self.zoom)
    self.panX=clamp(self.panX,math.min(halfW,self.canvasW/2),math.max(self.canvasW-halfW,self.canvasW/2))
    self.panY=clamp(self.panY,math.min(halfH,self.canvasH/2),math.max(self.canvasH-halfH,self.canvasH/2))
end

function CharacterTraitBoard:buyAt(x,y)
    for _,box in ipairs(self.nodeBoxes) do
        if inside(box,x,y) then
            self.selectedNodeId=box.id
            local ok,message=self.store:buy(box.id)
            self.message,self.messageTime=message,2.5
            self.messageKind=ok and "ok" or "blocked"
            if ok then self:burst(box,box.node); self.blockedNode=nil
            else self.blockedNode,self.blockedTime=box.id,.34 end
            return ok and "bought" or "blocked"
        end
    end
end

function CharacterTraitBoard:update(dt)
    self.time = self.time + dt
    self.messageTime = math.max(0, self.messageTime-dt)
    self.blockedTime = math.max(0, self.blockedTime-dt)
    self.tabPulse = math.max(0, self.tabPulse-dt*2.5)
    if self.drag then
        local mx,my=love.mouse.getPosition()
        if love.mouse.isDown(1) then
            local dx,dy=mx-self.drag.x,my-self.drag.y
            if dx*dx+dy*dy>20 then self.drag.moved=true end
            self.panX=self.drag.panX-dx/self.zoom
            self.panY=self.drag.panY-dy/self.zoom
            self:clampCamera()
        else
            if not self.drag.moved then self:buyAt(mx,my) end
            self.drag=nil
        end
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
    if button ~= 1 then return end
    if inside(self.backBox, x, y) then return "back" end
    for i, box in ipairs(self.tabBoxes) do
        if inside(box, x, y) then self:selectJob(jobOrder[i]); return "selected" end
    end
    if inside(self.resetViewBox,x,y) then
        self.panX,self.panY,self.zoom=820,950,.86
        return "reset_view"
    end
    if inside(self.minimapBox,x,y) then
        self.panX=(x-self.minimapBox.x)/self.minimapBox.w*self.canvasW
        self.panY=(y-self.minimapBox.y)/self.minimapBox.h*self.canvasH
        self:clampCamera(); return "minimap"
    end
    if inside(self.viewport,x,y) then
        self.drag={x=x,y=y,panX=self.panX,panY=self.panY,moved=false}
        return "dragging"
    end
end

function CharacterTraitBoard:wheelmoved(_,delta)
    if delta==0 or not self.viewport then return end
    local mx,my=love.mouse.getPosition()
    if not inside(self.viewport,mx,my) then return end
    local beforeX=self.panX+(mx-(self.viewport.x+self.viewport.w/2))/self.zoom
    local beforeY=self.panY+(my-(self.viewport.y+self.viewport.h/2))/self.zoom
    self.zoom=clamp(self.zoom*(delta>0 and 1.12 or 1/1.12),.48,1.28)
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
    love.graphics.setLineWidth(active and 8 or 5)
    love.graphics.setColor(color[1],color[2],color[3],active and .10 or .035)
    love.graphics.line(x1,y1,x2,y2)
    love.graphics.setLineWidth(active and 2.5 or 1.25)
    love.graphics.setColor(color[1],color[2],color[3],active and .92 or (available and .38 or .12))
    love.graphics.line(x1,y1,x2,y2)
    if active then
        local travel=(self.time*.55 + to.x*.7 + to.y*.3)%1
        love.graphics.setColor(1,.96,.78,.92)
        love.graphics.circle("fill",x1+(x2-x1)*travel,y1+(y2-y1)*travel,3.2)
    end
    love.graphics.setLineWidth(1)
end

function CharacterTraitBoard:drawNode(box, node, level, statusOk, requirementReady, hovered)
    local cx,cy,r=box.cx,box.cy,(node.capstone and 25 or 20)*(box.scale or 1)
    local rr,gg,bb=nodeColor(node)
    local unlocked=level>0
    local pulse=.5+math.sin(self.time*3+cx*.01)*.5
    if requirementReady and level<node.max then
        love.graphics.setColor(rr,gg,bb,(statusOk and .10 or .045)+pulse*.035)
        love.graphics.circle("fill",cx,cy,r+12+(hovered and 3 or 0))
    end
    love.graphics.setColor(.004,.012,.009,.72); love.graphics.circle("fill",cx+2,cy+5,r+5)
    love.graphics.setColor(rr,gg,bb,unlocked and .24 or .075)
    if node.capstone then drawHex(cx,cy,r+5,"fill") else love.graphics.circle("fill",cx,cy,r+5) end
    love.graphics.setColor(unlocked and .10 or .025,unlocked and .12 or .04,unlocked and .10 or .035,.98)
    if node.capstone then drawHex(cx,cy,r,"fill") else love.graphics.circle("fill",cx,cy,r) end
    love.graphics.setLineWidth(hovered and 3 or 1.7)
    love.graphics.setColor(rr,gg,bb,unlocked and 1 or (requirementReady and .62 or .24))
    if node.capstone then drawHex(cx,cy,r+1,"line") else love.graphics.circle("line",cx,cy,r+1) end
    if level>0 then
        love.graphics.setLineWidth(3); love.graphics.setColor(rr,gg,bb,.95)
        drawRing(cx,cy,r+7,-math.pi/2,-math.pi/2+math.pi*2*(level/node.max),math.max(8,node.max*8))
    end
    love.graphics.setColor(unlocked and {1,.96,.82,1} or {rr,gg,bb,requirementReady and .72 or .28})
    drawGlyph(node.icon,cx,cy,r*.72)
    love.graphics.setLineWidth(1)
end

function CharacterTraitBoard:drawCharacterDossier(x,y,w,h,job,focusNode)
    local fonts=self.fonts
    local group=self.store:getJobs()[job]
    local palette=group.palette
    love.graphics.setColor(.012,.03,.022,.88); love.graphics.rectangle("fill",x,y,w,h,14,14)
    love.graphics.setColor(palette[1],palette[2],palette[3],.7); love.graphics.rectangle("fill",x,y,4,h,3,3)
    love.graphics.setColor(1,1,1,.09); love.graphics.rectangle("line",x+.5,y+.5,w-1,h-1,14,14)
    love.graphics.setFont(fonts.small); love.graphics.setColor(palette[1],palette[2],palette[3],.9)
    love.graphics.print("연구 대상  /  "..jobNames[job],x+20,y+18)
    love.graphics.setFont(fonts.body); love.graphics.setColor(.96,.94,.82)
    love.graphics.printf(group.tagline,x+20,y+46,w-40,"left")
    love.graphics.setFont(fonts.small); love.graphics.setColor(.65,.72,.64)
    love.graphics.printf(group.doctrine,x+20,y+76,w-40,"left")
    -- 공용 특성 탭은 특정 캐릭터가 아니므로 초상화를 아예 생략한다. 전용 스프라이트가
    -- 있는 직업은 해당 고정 모델을 사용하고, 아직 없는 직업만 physical로 폴백한다.
    local sprite = job ~= "universal" and (self.sprites[job] or self.sprites.physical) or nil
    if sprite then
        local fw,fh=sprite.image:getWidth()/6,sprite.image:getHeight()/2
        local frame=math.floor(self.time*4)%6
        local quad=love.graphics.newQuad(frame*fw,0,fw,fh,sprite.image:getDimensions())
        local scale=math.min((w-44)/fw,(h*.42)/fh)
        love.graphics.setColor(0,0,0,.28); love.graphics.ellipse("fill",x+w/2,y+h*.56,w*.26,12)
        love.graphics.setColor(1,1,1,1)
        love.graphics.draw(sprite.image,quad,x+w/2,y+h*.58,0,scale,scale,fw/2,(sprite.walkFeet or {})[frame+1] or 190)
    end
    local detailY=y+h-150
    love.graphics.setColor(.04,.075,.052,.94); love.graphics.rectangle("fill",x+12,detailY,w-24,136,8,8)
    love.graphics.setColor(focusNode.color[1],focusNode.color[2],focusNode.color[3],.8); love.graphics.rectangle("fill",x+12,detailY,3,136,2,2)
    local level=self.store:getLevel(focusNode.id)
    local ok,reason,cost=self.store:status(focusNode.id)
    love.graphics.setFont(fonts.heading); love.graphics.setColor(.96,.94,.84)
    love.graphics.printf(self:nodeLabel(focusNode),x+28,detailY+14,w-54,"left")
    love.graphics.setFont(fonts.small); love.graphics.setColor(.72,.79,.69)
    love.graphics.printf(focusNode.desc,x+28,detailY+46,w-54,"left")
    love.graphics.setColor(focusNode.color[1],focusNode.color[2],focusNode.color[3],.95)
    love.graphics.print("단계 "..level.." / "..focusNode.max,x+28,detailY+78)
    local state=level>=focusNode.max and "연구 완료" or (ok and ("클릭하여 해금  ·  "..cost.." P") or reason)
    love.graphics.setColor(ok and {1,.82,.38,1} or {.58,.63,.55,1})
    love.graphics.printf(state,x+28,detailY+104,w-54,"left")
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
    love.graphics.setColor(.008,.022,.015,.78); love.graphics.rectangle("fill",0,0,w,h)
    for i=0,14 do
        love.graphics.setColor(palette[1],palette[2],palette[3],.018*(1-i/15))
        love.graphics.circle("fill",w*.68,h*.54,120+i*36)
    end
    self.backBox={x=26,y=22,w=132,h=40}
    UI.button(self.backBox.x,self.backBox.y,self.backBox.w,self.backBox.h,"← 돌아가기",true,fonts.small)
    love.graphics.setFont(fonts.title); love.graphics.setColor(.98,.96,.84); love.graphics.print("캐릭터 연구망",184,22)
    love.graphics.setFont(fonts.small); love.graphics.setColor(.66,.73,.64); love.graphics.print("성과 포인트로 영구 노드를 활성화합니다",184,55)
    UI.panel(w-226,18,196,52,{palette[1],palette[2],palette[3],1},.96)
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
        love.graphics.setColor(.015,.038,.027,selected and .97 or .76); love.graphics.rectangle("fill",box.x,box.y,box.w,box.h,6,6)
        love.graphics.setColor(jobPalette[1],jobPalette[2],jobPalette[3],selected and 1 or .24)
        love.graphics.rectangle("fill",box.x,box.y,selected and 4 or 2,box.h,2,2)
        if selected then love.graphics.rectangle("fill",box.x+10,box.y+box.h-2,box.w-20,2) end
        love.graphics.setFont(fonts.body); love.graphics.setColor(selected and {1,.96,.84,1} or {.63,.69,.61,1})
        love.graphics.printf(i.."  "..(jobTabNames[job] or jobNames[job]),box.x,box.y+12,box.w,"center")
    end

    local dossier={x=30,y=150,w=math.min(300,w*.235),h=h-176}
    local graph={x=dossier.x+dossier.w+20,y=150,w=w-dossier.x-dossier.w-50,h=h-176}
    self.viewport=graph
    self:clampCamera()
    love.graphics.setColor(.004,.014,.009,.91); love.graphics.rectangle("fill",graph.x,graph.y,graph.w,graph.h,12,12)
    love.graphics.setScissor(graph.x,graph.y,graph.w,graph.h)

    -- 카메라와 함께 움직이는 월드 격자: 현재 화면이 큰 연구 공간의 일부라는 감각을 준다.
    local grid=160
    local left=self.panX-graph.w/(2*self.zoom)
    local right=self.panX+graph.w/(2*self.zoom)
    local top=self.panY-graph.h/(2*self.zoom)
    local bottom=self.panY+graph.h/(2*self.zoom)
    for wx=math.floor(left/grid)*grid,right,grid do
        local sx=graph.x+graph.w/2+(wx-self.panX)*self.zoom
        love.graphics.setColor(palette[1],palette[2],palette[3],wx%480==0 and .055 or .022)
        love.graphics.line(sx,graph.y,sx,graph.y+graph.h)
    end
    for wy=math.floor(top/grid)*grid,bottom,grid do
        local sy=graph.y+graph.h/2+(wy-self.panY)*self.zoom
        love.graphics.setColor(palette[1],palette[2],palette[3],wy%480==0 and .055 or .022)
        love.graphics.line(graph.x,sy,graph.x+graph.w,sy)
    end

    local nodes=self.store:getNodes(self.selectedJob)
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
    local hoveredNode=nil
    local nodeScale=clamp(self.zoom,.72,1.04)
    for _,node in ipairs(nodes) do
        local cx,cy=self:nodePosition(graph,node)
        if cx>=graph.x-80 and cx<=graph.x+graph.w+80 and cy>=graph.y-80 and cy<=graph.y+graph.h+80 then
            local radius=(node.capstone and 31 or 27)*nodeScale
            local box={id=node.id,node=node,cx=cx,cy=cy,x=cx-radius,y=cy-radius,w=radius*2,h=radius*2,scale=nodeScale}
            self.nodeBoxes[#self.nodeBoxes+1]=box
            local hovered=inside(box,mx,my) and not self.drag
            if hovered then hoveredNode=node; self.selectedNodeId=node.id end
            local target=hovered and 1 or 0
            self.nodeHover[node.id]=(self.nodeHover[node.id] or 0)+(target-(self.nodeHover[node.id] or 0))*.22
            local ok=self.store:status(node.id)
            local shake=0
            if self.blockedNode==node.id and self.blockedTime>0 then shake=math.sin(self.blockedTime*95)*4*self.blockedTime/.34 end
            box.cx=box.cx+shake
            self:drawNode(box,node,self.store:getLevel(node.id),ok,requirementsMet(self.store,node),hovered)
            if self.zoom>=.58 then
                love.graphics.setFont(fonts.small); love.graphics.setColor(hovered and {1,.94,.78,1} or {.70,.75,.67,.72})
                love.graphics.printf(self:nodeLabel(node),box.cx-88,box.cy+31*nodeScale,176,"center")
            end
        end
    end
    self:drawUnlockFx()
    love.graphics.setScissor()
    love.graphics.setColor(1,1,1,.065); love.graphics.rectangle("line",graph.x+.5,graph.y+.5,graph.w-1,graph.h-1,12,12)

    -- 고정 HUD: 탐색 조작, 초기 위치, 미니맵을 월드 위에 겹쳐 둔다.
    love.graphics.setColor(.006,.018,.012,.93); love.graphics.rectangle("fill",graph.x+10,graph.y+10,graph.w-20,38,7,7)
    love.graphics.setFont(fonts.small); love.graphics.setColor(palette[1],palette[2],palette[3],.88)
    love.graphics.print("대형 영구 연구망  ·  "..#nodes.."개 노드",graph.x+24,graph.y+22)
    love.graphics.setColor(.62,.70,.62,.78)
    love.graphics.printf("빈 공간 드래그 이동  ·  휠 확대/축소  ·  노드 클릭 해금",graph.x+220,graph.y+22,graph.w-244,"right")
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
    self:drawCharacterDossier(dossier.x,dossier.y,dossier.w,dossier.h,self.selectedJob,hoveredNode or focus)
    if self.messageTime>0 then
        local width=math.min(520,w*.46)
        love.graphics.setColor(.008,.02,.014,.96); love.graphics.rectangle("fill",w/2-width/2,h-54,width,38,7,7)
        local success=self.messageKind=="ok"
        love.graphics.setColor(success and {1,.82,.35,1} or {1,.43,.32,1}); love.graphics.rectangle("fill",w/2-width/2,h-54,4,38,2,2)
        love.graphics.setFont(fonts.body); love.graphics.printf(self.message,w/2-width/2+12,h-44,width-24,"center")
    end
end

return CharacterTraitBoard
