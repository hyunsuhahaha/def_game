local UI = require("src.ui")
local Frontend = require("src.frontend_ui")
local TraitNodeArt = require("src.trait_node_art")

local CharacterTraitBoard = {}
CharacterTraitBoard.__index = CharacterTraitBoard

-- 기존 캐릭터별 연구 데이터는 삭제하지 않았다. 활성 플레이에는 선택 단계가 없으므로
-- 로비에서는 실제 적용되는 두 연구군만 의도적으로 노출한다.
local archivedJobOrder = {"physical", "fire", "toxic", "developer", "miner", "philosopher", "universal"}
local ACTIVE_DEVELOPMENT_MODE="score_attack"
-- 활성 게임에는 캐릭터/직업 선택이 없다. 기존 저장 호환용 "fire"와 "universal"
-- 연구 그룹만 한 연구망에 합쳐 보여주고 선택 탭은 만들지 않는다.
local scoreAttackGroups = {"fire","universal"}
local jobOrder = ACTIVE_DEVELOPMENT_MODE=="score_attack" and {"all"} or archivedJobOrder
local jobNames = {physical="생계형 나무꾼", fire="흡연자", toxic="비건 단체 회장", developer="부동산 개발업자", miner="코인 채굴꾼", philosopher="차라투스트라는 이렇게 말했다", universal="공용 복지"}
local jobTabNames = {philosopher="차라투스트라"}
local STRUCTURE={.32,.78,.62}
local WARM={1,.73,.24}
local scoreBoardCopy={
    fire={title="무기 · 전투",detail="담배·도끼·폭죽과 착화 성능을 영구 강화한다."},
    universal={title="동료 · 설비",detail="로봇·두더지·고양이와 현장 설비를 영구 강화한다."},
}

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
        store=store, fonts=fonts, sprites=sprites,researchBackground=nil,selectedJob=jobOrder[1],activeDevelopmentMode=ACTIVE_DEVELOPMENT_MODE,
        tabBoxes={}, nodeBoxes={}, nodeHover={}, particles={}, time=0,
        message="", messageTime=0, messageKind="ok", unlockFx=nil,
        selectedNodeId=first and first.id or"fire_score_prewarm", blockedNode=nil, blockedTime=0, tabPulse=0,
        canvasW=4100,canvasH=2650,panX=1100,panY=920,zoom=.80,referenceZoom=.80,panVX=0,panVY=0,drag=nil,viewport=nil,viewInitialized=false,crispFonts={},
        minimapBox=nil,resetViewBox=nil
    }, CharacterTraitBoard)
end

function CharacterTraitBoard:nodesFor(job)
    if self.activeDevelopmentMode=="score_attack"then
        local merged={}
        for _,group in ipairs(scoreAttackGroups)do
            for _,node in ipairs(self.store:getScoreAttackNodes(group))do merged[#merged+1]=node end
        end
        return merged
    end
    return self.store:getNodes(job)
end

function CharacterTraitBoard:selectJob(job)
    if self.selectedJob == job then return end
    local nodes=self:nodesFor(job)
    self.selectedJob, self.selectedNodeId = job, nodes[1]and nodes[1].id or nil
    self.tabPulse, self.messageTime, self.blockedTime = 1, 0, 0
    self.panX,self.panY,self.zoom,self.referenceZoom,self.panVX,self.panVY,self.viewInitialized=1100,job=="fire"and 920 or 850,.80,.80,0,0,false
end

function CharacterTraitBoard:crispFont(size,bold)
    size=math.max(10,math.floor(size+.5));local key=(bold and"b"or"r")..size
    if self.crispFonts[key]then return self.crispFonts[key]end
    if not love.graphics.newFont then return bold and(self.fonts.heading or self.fonts.body)or(self.fonts.small or self.fonts.body)end
    local path=bold and"assets/font-korean-bold.ttf"or"assets/font-korean-regular.ttf"
    self.crispFonts[key]=love.graphics.newFont(path,size)
    return self.crispFonts[key]
end

function CharacterTraitBoard:fitResearchTree()
    if not self.viewport then return end
    local nodes=self:nodesFor(self.selectedJob);if #nodes==0 then return end
    local minX,maxX,minY,maxY=math.huge,-math.huge,math.huge,-math.huge
    for _,node in ipairs(nodes)do local x,y=self:nodeWorld(node);minX,maxX=math.min(minX,x),math.max(maxX,x);minY,maxY=math.min(minY,y),math.max(maxY,y)end
    -- 합친 연구판의 정중앙은 흡연자 갈래와 공용 갈래 사이의 빈 곳이라, 열자마자
    -- 어느 쪽 트리도 제대로 안 보인다. 진행이 시작되는 뿌리 노드에 시점을 맞춘다.
    local root=self.store:getNode("fire_score_prewarm")
    if root then self.panX,self.panY=self:nodeWorld(root)
    else self.panX,self.panY=(minX+maxX)/2,(minY+maxY)/2 end
    -- 연구판을 한 판으로 합치면서 내용이 화면보다 훨씬 커졌다(1280x720에서 가로 64%,
    -- 세로 46%만 보인다). 전체를 한눈에 보려면 어디까지 물러날 수 있어야 하는지를
    -- 여기서 계산해 두고, 휠 축소 하한으로 쓴다.
    self.contentW,self.contentH=math.max(1,maxX-minX),math.max(1,maxY-minY)
    self.contentCX,self.contentCY=(minX+maxX)/2,(minY+maxY)/2
    -- Reset returns to the authored reference spacing. Zoom stays a readability
    -- adjustment upward; downward it may pull back far enough to see the whole tree.
    self.referenceZoom=clamp((self.viewport.w/1748)*.80,.56,.80)
    self.zoom=self.referenceZoom
    self.panVX,self.panVY,self.viewInitialized=0,0,true
    self:clampCamera()
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
        self:fitResearchTree()
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

-- 축소 하한은 "트리 전체가 여백까지 포함해 화면에 들어오는 배율"이다. 그보다 더
-- 물러나면 아무 정보도 늘지 않고 노드만 작아지므로 거기서 멈춘다. 내용이 화면보다
-- 작으면 기존처럼 좁은 가독성 조정폭(reference*.85)만 남는다.
function CharacterTraitBoard:minZoom()
    local reference=self.referenceZoom or .80
    if not self.viewport or not self.contentW then return reference*.85 end
    local margin=220
    local fit=math.min(self.viewport.w/(self.contentW+margin),self.viewport.h/(self.contentH+margin))
    return math.min(reference*.85,fit)
end

function CharacterTraitBoard:wheelmoved(_,delta)
    if delta==0 or not self.viewport then return end
    local mx,my=love.mouse.getPosition()
    if not inside(self.viewport,mx,my) then return end
    local beforeX=self.panX+(mx-(self.viewport.x+self.viewport.w/2))/self.zoom
    local beforeY=self.panY+(my-(self.viewport.y+self.viewport.h/2))/self.zoom
    local reference=self.referenceZoom or .80
    self.zoom=clamp(self.zoom*(delta>0 and 1.08 or 1/1.08),self:minZoom(),reference*1.15)
    self.panVX,self.panVY=0,0
    self.panX=beforeX-(mx-(self.viewport.x+self.viewport.w/2))/self.zoom
    self.panY=beforeY-(my-(self.viewport.y+self.viewport.h/2))/self.zoom
    -- 트리 전체가 들어가는 배율까지 물러났다면 가운데로 맞춘다. 커서 기준으로만
    -- 축소하면 다 들어갈 배율인데도 화면이 치우쳐 끝 가지가 잘려 보인다.
    if self.contentW and self.viewport.w/self.zoom>=self.contentW and self.viewport.h/self.zoom>=self.contentH then
        self.panX,self.panY=self.contentCX,self.contentCY
    end
    self:clampCamera()
end

function CharacterTraitBoard:nodeWorld(node)
    -- 기록전 연구는 수가 적어 한 화면에 전부 읽혀야 한다. 저장 데이터의 좌표를
    -- 바꾸지 않고 화면에서만 뿌리->가지 방향의 고정 배치를 사용한다.
    local scoreLayout={
        fire_score_prewarm={1100,850},
        fire_score_filter={750,850},fire_score_spark={400,850},
        fire_score_lighter={1450,850},fire_score_ash={1800,850},
        fire_score_launch={1100,600},fire_score_drag={1100,350},
        fire_score_heat={1100,1100},fire_score_stock={1100,1350},
        -- 무기 슬롯 갈래. 담배 척추(prewarm→heat→stock) 아래로 후반 해금 두 개가 이어지고,
        -- 공용/도끼는 왼쪽, 폭죽 강화는 해금 아래 한 줄로 편다.
        fire_score_edge={400,1100},
        fire_score_axe_area={400,1350},fire_score_axe_speed={750,1350},
        fire_score_axe_targets={400,1600},fire_score_axe_execute={750,1600},
        fire_score_axe_shock={400,1850},fire_score_axe_chain={750,1850},
        fire_score_axe_crew={575,2100},
        fire_score_alwayssmoke={1100,1600},fire_score_autothrow={1100,1850},
        fire_score_rocket_unlock={1100,2100},
        fire_score_rocket_radius={400,2350},fire_score_rocket_damage={750,2350},
        fire_score_rocket_speed={1100,2350},fire_score_rocket_ignite={1450,2350},
        fire_score_rocket_cooldown={1800,2350},
        -- 공용 연구는 흡연자 갈래와 같은 좌표를 쓰고 있었다(각자 다른 탭이었으므로).
        -- 한 판으로 합치면서 흡연자 오른쪽으로 통째로 옮긴다.
        universal_yard={2600,850},universal_robot_start={3000,850},universal_robot_motor={3400,850},
        universal_oil_drum={3800,850},universal_gray_cat={3800,1100},
        universal_gray_cat_chance={3800,1350},universal_gray_cat_delay={3800,1600},
        universal_gray_cat_speed={3400,1100},
        universal_mole_companion={3000,1100},
        universal_mole_damage={2600,1350},universal_mole_speed={3000,1350},universal_mole_attack_speed={3400,1350},
        universal_mole_claw={2600,1600},universal_mole_extra={3000,1600},universal_mole_dual={2600,1850},
    }
    local fixed=scoreLayout[node.id]
    if fixed then return fixed[1],fixed[2] end
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
    local rr,gg,bb=.28,.57,.36
    local locked=not active and not available
    local z=self.zoom or .8
    love.graphics.setLineWidth(math.max(4,(active and 13 or 10)*z))
    if locked then love.graphics.setColor(.34,.35,.34,.30) else love.graphics.setColor(rr,gg,bb,active and .18 or .10) end
    love.graphics.line(x1,y1,x2,y2)
    love.graphics.setLineWidth(math.max(2,(active and 7 or 5)*z))
    if locked then love.graphics.setColor(.31,.32,.31,.72) else love.graphics.setColor(rr,gg,bb,active and 1 or .72) end
    love.graphics.line(x1,y1,x2,y2)
    love.graphics.setLineWidth(1); love.graphics.setColor(.92,.96,.89,active and .42 or .08);love.graphics.line(x1,y1-1,x2,y2-1)
    if active then
        local travel=(self.time*.72 + (to.x or 0)*.7 + (to.y or 0)*.3)%1
        love.graphics.setColor(.78,1,1,.96)
        love.graphics.circle("fill",x1+(x2-x1)*travel,y1+(y2-y1)*travel,math.max(3,5*z))
    end
    love.graphics.setLineWidth(1)
end

function CharacterTraitBoard:drawNode(box, node, level, statusOk, requirementReady, hovered)
    local cx,cy,r=box.cx,box.cy,(node.capstone and 38 or 32)*(box.scale or 1)
    local unlocked=level>0
    local pulse=.5+math.sin(self.time*3+cx*.01)*.5
    local selected=node.id==self.selectedNodeId
    local root=node.id=="fire_score_prewarm" or node.id=="universal_robot_start"
    local function shape(mode,ox,oy,extra)
        if root then drawHex(cx+(ox or 0),cy+(oy or 0),r+(extra or 0),mode)
        else love.graphics.rectangle(mode,cx-r-(extra or 0)+(ox or 0),cy-r-(extra or 0)+(oy or 0),(r+(extra or 0))*2,(r+(extra or 0))*2,2,2)end
    end
    if requirementReady and level<node.max then love.graphics.setColor(.30,.62,.38,.12+pulse*.08);shape("fill",0,0,12+(hovered and 3 or 0))end
    love.graphics.setColor(0,0,0,.18);shape("fill",3,5,6)
    if unlocked then love.graphics.setColor(.32,.61,.39,1)
    elseif requirementReady then love.graphics.setColor(.92,.93,.89,1)
    else love.graphics.setColor(.38,.39,.38,.96)end
    shape("fill",0,0,4)
    love.graphics.setLineWidth(selected and 5 or (hovered and 4 or 2))
    love.graphics.setColor(selected and {.23,.58,.34,1} or (unlocked and {.20,.48,.29,1} or {.27,.28,.27,1}));shape("line",0,0,5)
    if selected then
        love.graphics.setLineWidth(2);love.graphics.setColor(.22,.62,.34,.62+pulse*.28)
        local q=r+14
        love.graphics.line(cx-q,cy-8,cx-q,cy-q,cx-8,cy-q)
        love.graphics.line(cx+q,cy-8,cx+q,cy-q,cx+8,cy-q)
        love.graphics.line(cx-q,cy+8,cx-q,cy+q,cx-8,cy+q)
        love.graphics.line(cx+q,cy+8,cx+q,cy+q,cx+8,cy+q)
    end
    if level>0 then
        love.graphics.setLineWidth(3); love.graphics.setColor(.18,.45,.27,1)
        drawRing(cx,cy,r+12,-math.pi/2,-math.pi/2+math.pi*2*(level/node.max),math.max(8,node.max*8))
    end
    local iconAlpha=unlocked and 1 or (requirementReady and .92 or .38)
    if not TraitNodeArt.draw(node.icon,cx,cy,r*1.28,iconAlpha)then
        love.graphics.setColor(unlocked and {1,1,.94,1} or {.12,.13,.12,iconAlpha});drawGlyph(node.icon,cx,cy,r*.82)
    end
    if statusOk and not unlocked then
        love.graphics.setColor(.58,1,.52,.95); love.graphics.rectangle("fill",cx+r*.42,cy-r*.78,9,3); love.graphics.rectangle("fill",cx+r*.42+3,cy-r*.78-3,3,9)
    end
    local pipW=math.max(3,math.floor(r*.14));local gap=2
    local totalW=node.max*pipW+(node.max-1)*gap
    for i=1,node.max do
        love.graphics.setColor(i<=level and {.20,.52,.30,1} or {.43,.44,.42,.72})
        love.graphics.rectangle("fill",cx-totalW/2+(i-1)*(pipW+gap),cy+r*.72,pipW,3)
    end
    love.graphics.setLineWidth(1)
end

local function wrappedHeight(font,text,width)
    if font.getWrap then local _,lines=font:getWrap(text,width);return math.max(1,#lines)*font:getHeight()end
    return math.max(1,math.ceil(#tostring(text)/math.max(1,math.floor(width/(font:getHeight()*.55)))))*font:getHeight()
end

function CharacterTraitBoard:drawCharacterDossier(x,y,w,h,job,focusNode)
    local fonts=self.fonts
    local group=self.store:getJobs()[job]
    local palette=group.palette
    love.graphics.setColor(.006,.018,.014,.76); love.graphics.rectangle("fill",x,y,w,h,7,7)
    love.graphics.setColor(WARM); love.graphics.rectangle("fill",x,y,4,h,3,3)
    love.graphics.setColor(STRUCTURE[1],STRUCTURE[2],STRUCTURE[3],.54); love.graphics.rectangle("line",x+.5,y+.5,w-1,h-1,7,7)
    for i=1,18 do
        local px=x+14+((i*73)%math.max(20,w-28));local py=y+12+((i*109)%math.max(20,h-24))
        love.graphics.setColor(i%4==0 and WARM[1]or STRUCTURE[1],i%4==0 and WARM[2]or STRUCTURE[2],i%4==0 and WARM[3]or STRUCTURE[3],i%3==0 and .10 or .035)
        love.graphics.rectangle("fill",px,py,2+(i%3),1+(i%2))
    end
    love.graphics.setFont(fonts.small); love.graphics.setColor(WARM)
    love.graphics.print("연구 대상  /  "..jobNames[job],x+20,y+18)
    local compact=h<430
    local copy=scoreBoardCopy[job]
    local tagline=copy and copy.title or group.tagline
    local doctrine=copy and copy.detail or group.doctrine
    local taglineFont=compact and fonts.small or fonts.heading
    love.graphics.setFont(taglineFont); love.graphics.setColor(1,.96,.81)
    love.graphics.printf(tagline,x+20,y+48,w-40,"left")
    local doctrineY=y+48+wrappedHeight(taglineFont,tagline,w-40)+12
    love.graphics.setColor(STRUCTURE[1],STRUCTURE[2],STRUCTURE[3],.48);love.graphics.rectangle("fill",x+20,doctrineY-6,w-40,1)
    love.graphics.setFont(compact and fonts.small or fonts.body); love.graphics.setColor(.72,.78,.70)
    love.graphics.printf(doctrine,x+20,doctrineY,w-40,"left")
    -- 공용 특성 탭은 특정 캐릭터가 아니므로 초상화를 아예 생략한다. 전용 스프라이트가
    -- 있는 직업은 해당 고정 모델을 사용하고, 아직 없는 직업만 physical로 폴백한다.
    local sprite = job ~= "universal" and (self.sprites[job] or self.sprites.physical) or nil
    if sprite then
        local fw,fh=sprite.image:getWidth()/6,sprite.image:getHeight()/2
        local frame=math.floor(self.time*4)%6
        local quad=love.graphics.newQuad(frame*fw,0,fw,fh,sprite.image:getDimensions())
        local detailH=compact and 148 or math.min(210,math.max(170,h*.23))
        local detailY=y+h-detailH-14
        local spriteTop=doctrineY+wrappedHeight(compact and fonts.small or fonts.body,doctrine,w-40)+18
        local spriteBottom=detailY-16
        local scale=math.min((w-44)/fw,math.max(56,spriteBottom-spriteTop)/fh)
        local feetY=spriteBottom
        love.graphics.setColor(0,0,0,.38); love.graphics.ellipse("fill",x+w/2,feetY+2,w*.27,11)
        love.graphics.setColor(1,1,1,1)
        love.graphics.draw(sprite.image,quad,x+w/2,feetY,0,scale,scale,fw/2,(sprite.walkFeet or {})[frame+1] or 190)
    end
    local detailH=compact and 148 or math.min(210,math.max(170,h*.23))
    local detailY=y+h-detailH-14
    love.graphics.setColor(.018,.024,.028,.99); love.graphics.rectangle("fill",x+12,detailY,w-24,detailH,5,5)
    love.graphics.setColor(focusNode.color[1],focusNode.color[2],focusNode.color[3],.9); love.graphics.rectangle("fill",x+12,detailY,4,detailH,2,2)
    love.graphics.setColor(1,1,1,.055);love.graphics.rectangle("fill",x+22,detailY+8,w-46,1)
    local level=self.store:getLevel(focusNode.id)
    local ok,reason,cost=self.store:status(focusNode.id)
    love.graphics.setFont(fonts.heading); love.graphics.setColor(.96,.94,.84)
    love.graphics.printf(self:nodeLabel(focusNode),x+28,detailY+14,w-54,"left")
    love.graphics.setFont(fonts.small); love.graphics.setColor(.72,.79,.69)
    love.graphics.printf(focusNode.desc,x+28,detailY+48,w-54,"left")
    love.graphics.setColor(focusNode.color[1],focusNode.color[2],focusNode.color[3],.95)
    love.graphics.print("단계 "..level.." / "..focusNode.max,x+28,detailY+88)
    if level>=focusNode.max then
        self.buyButtonBox=nil
        love.graphics.setColor(.58,.63,.55,1)
        love.graphics.printf("연구 완료",x+28,detailY+122,w-54,"left")
    elseif ok then
        self.buyButtonBox={x=x+28,y=detailY+118,w=w-56,h=38}
        Frontend.button(self.buyButtonBox,"강화  ·  "..cost.." P",fonts.small,{primary=true,accent=focusNode.color})
    else
        self.buyButtonBox=nil
        love.graphics.setColor(.58,.63,.55,1)
        love.graphics.printf(reason,x+28,detailY+122,w-54,"left")
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
    local textScale=clamp(math.min(w/1280,h/720),1,1.42)
    local fonts={
        micro=self:crispFont(12*textScale,false),small=self:crispFont(14*textScale,false),
        body=self:crispFont(17*textScale,false),heading=self:crispFont(21*textScale,true),
        big=self:crispFont(28*textScale,true),title=self:crispFont(36*textScale,true),
    }
    -- Reference-matched upgrade workspace: neutral paper field, faint vignette and
    -- sparse dust only. No forest photo or decorative game-world backdrop.
    love.graphics.setColor(.88,.89,.85,1);love.graphics.rectangle("fill",0,0,w,h)
    for i=1,14 do
        local inset=(i-1)*math.max(3,math.floor(math.min(w,h)/170))
        love.graphics.setColor(.18,.19,.17,.012+i*.003)
        love.graphics.rectangle("line",inset+.5,inset+.5,w-inset*2-1,h-inset*2-1)
    end
    for i=1,38 do
        local px=(i*191)%w;local py=(i*113+37)%h;local s=1+(i%3)
        love.graphics.setColor(.34,.36,.32,i%5==0 and .10 or .045);love.graphics.rectangle("fill",px,py,s,s)
    end
    local titleY=18*textScale;local subtitleY=titleY+fonts.title:getHeight()-2*textScale
    local tabY=subtitleY+fonts.small:getHeight()+10*textScale
    local tabH=#jobOrder>1 and 44*textScale or 0;local infoY=tabY+tabH+(#jobOrder>1 and 10*textScale or 0);local infoH=88*textScale
    local graphY=infoY+infoH+10*textScale;local footerH=34*textScale
    self.backBox={x=26*textScale,y=18*textScale,w=132*textScale,h=40*textScale}
    Frontend.button(self.backBox,"← 돌아가기",fonts.small,{accent=STRUCTURE})
    local titleX=184*textScale
    love.graphics.setFont(fonts.title); love.graphics.setColor(.18,.19,.17); love.graphics.print("강화하기",titleX,titleY)
    love.graphics.setFont(fonts.small); love.graphics.setColor(.38,.40,.37); love.graphics.print("중앙 장비에서 네 방향으로 연구를 확장합니다",titleX,subtitleY)
    love.graphics.setFont(fonts.small);love.graphics.setColor(.38,.40,.37);love.graphics.printf("연구 코인",w-250*textScale,20*textScale,118*textScale,"right")
    love.graphics.setFont(fonts.big);love.graphics.setColor(.24,.54,.32);love.graphics.printf(tostring(self.store.data.currency),w-126*textScale,16*textScale,100*textScale,"right")

    self.tabBoxes={}
    if #jobOrder>1 then
    local tabGap=8*textScale
    local tabCount=#jobOrder
    local tabW=math.min(260*textScale,(w-52*textScale-tabGap*(tabCount-1))/tabCount)
    local startX=(w-(tabW*tabCount+tabGap*(tabCount-1)))/2
    for i,job in ipairs(jobOrder) do
        local box={x=startX+(i-1)*(tabW+tabGap),y=tabY,w=tabW,h=tabH}
        self.tabBoxes[i]=box
        local selected=job==self.selectedJob
        love.graphics.setColor(selected and {.95,.96,.92,1}or{.73,.74,.71,.84}); love.graphics.rectangle("fill",box.x,box.y,box.w,box.h,3,3)
        local vr,vg,vb=selected and .25 or .36,selected and .60 or .38,selected and .35 or .36
        love.graphics.setColor(vr,vg,vb,selected and 1 or .48)
        love.graphics.rectangle("fill",box.x,box.y,selected and 4 or 2,box.h,2,2)
        if selected then love.graphics.rectangle("fill",box.x+10,box.y+box.h-2,box.w-20,2) end
        love.graphics.setFont(fonts.body); love.graphics.setColor(selected and {.14,.17,.14,1} or {.31,.32,.30,1})
        love.graphics.printf(i.."  "..(jobTabNames[job] or jobNames[job]),box.x,box.y+(box.h-fonts.body:getHeight())/2,box.w,"center")
    end
    end

    local nodes=self:nodesFor(self.selectedJob)
    local focus=self.store:getNode(self.selectedNodeId) or nodes[1]
    local infoW=math.min(760*textScale,w-72*textScale);local infoX=(w-infoW)/2
    love.graphics.setColor(.94,.95,.91,.98);love.graphics.rectangle("fill",infoX,infoY,infoW,infoH,3,3)
    love.graphics.setColor(.27,.29,.26,.82);love.graphics.setLineWidth(2);love.graphics.rectangle("line",infoX+.5,infoY+.5,infoW-1,infoH-1,3,3);love.graphics.setLineWidth(1)
    local level=self.store:getLevel(focus.id);local ok,reason,cost=self.store:status(focus.id)
    love.graphics.setFont(fonts.body);love.graphics.setColor(.15,.16,.14);love.graphics.print(focus.name,infoX+22*textScale,infoY+11*textScale)
    love.graphics.setFont(fonts.micro or fonts.small);love.graphics.setColor(.34,.36,.33);love.graphics.print(focus.desc,infoX+22*textScale,infoY+39*textScale)
    love.graphics.setColor(.23,.55,.31);love.graphics.print("단계 "..level.." / "..focus.max,infoX+22*textScale,infoY+64*textScale)
    local actionW=190*textScale;local actionX=infoX+infoW-actionW-16*textScale
    if level>=focus.max then
        self.buyButtonBox=nil;love.graphics.setColor(.35,.39,.34);love.graphics.printf("연구 완료",actionX,infoY+57*textScale,actionW,"center")
    elseif ok then
        self.buyButtonBox={x=actionX,y=infoY+44*textScale,w=actionW,h=34*textScale}
        Frontend.button(self.buyButtonBox,"강화  ·  "..cost.." 코인",fonts.small,{primary=true,accent=STRUCTURE})
    else
        self.buyButtonBox=nil;love.graphics.setColor(.43,.40,.37);love.graphics.printf(reason,actionX,infoY+55*textScale,actionW,"center")
    end

    local graph={x=30*textScale,y=graphY,w=w-60*textScale,h=h-graphY-footerH}
    self.viewport=graph
    if not self.viewInitialized then self:fitResearchTree()else self:clampCamera()end
    love.graphics.setColor(.94,.95,.91,.14); love.graphics.rectangle("fill",graph.x,graph.y,graph.w,graph.h)
    love.graphics.setScissor(graph.x,graph.y,graph.w,graph.h)
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
    local uiScale=textScale
    -- Node bodies, labels and connection gaps share the same zoom basis. Node
    -- size is deliberately smaller than the branch step so the spacing reads:
    -- the gap between two nodes, not the nodes themselves, carries the layout.
    -- 간격(nodeWorld x zoom)은 건드리지 않고 노드 크기만 줄인다.
    -- 하한 .55에서 멈추면 축소할수록 노드가 상대적으로 커져 간격을 잡아먹는다.
    -- 전체 조망 배율까지 비율을 유지하도록 하한을 낮춘다.
    local nodeScale=clamp((self.zoom or .8)*1.5,.32,1.60)
    local labelFont=self:crispFont(clamp(24*(self.zoom or .8),11,26),true)
    -- 라벨 폭은 96px 아래로 줄지 않는다. 전체 조망까지 축소하면 노드 간격이 그보다
    -- 좁아져 라벨이 서로 겹쳐 글자 죽이 된다. 조망 구간에서는 라벨을 빼고 아이콘과
    -- 연결선으로 구조만 읽게 한다 — 이름은 확대하거나 노드를 클릭하면 상단에 나온다.
    local showLabels=(self.zoom or .8)>=(self.referenceZoom or .8)*.85-1e-6
    for _,node in ipairs(nodes) do
        local cx,cy=self:nodePosition(graph,node)
        if cx>=graph.x-80 and cx<=graph.x+graph.w+80 and cy>=graph.y-80 and cy<=graph.y+graph.h+80 then
            local radius=(node.capstone and 48 or 42)*nodeScale
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
            local nodeR=(node.capstone and 38 or 32)*nodeScale
            if showLabels then
                local labelW=clamp(178*(self.zoom or .8),96,178)
                local wx=self:nodeWorld(node)
                local vertical=math.abs(wx-1100)<8 and node.id~="fire_score_prewarm" and node.id~="universal_robot_start"
                local labelX=vertical and (box.cx+nodeR+9) or (box.cx-labelW/2)
                local labelY=vertical and (box.cy-10*uiScale) or (box.cy+nodeR+13*uiScale)
                local labelH=labelFont:getHeight()+6
                love.graphics.setColor(.88,.89,.85,(hovered or node.id==self.selectedNodeId)and .96 or .82)
                love.graphics.rectangle("fill",labelX,labelY-3,labelW,labelH,2,2)
                love.graphics.setFont(labelFont); love.graphics.setColor(hovered and {.12,.15,.12,1} or {.25,.27,.24,.94})
                love.graphics.printf(node.short or self:nodeLabel(node),labelX+5,labelY+1,labelW-10,vertical and "left" or "center")
            end
        end
    end
    self:drawUnlockFx()
    love.graphics.setScissor()
    self.minimapBox=nil;self.resetViewBox=nil
    love.graphics.setColor(.27,.28,.26,.88);love.graphics.rectangle("fill",0,h-footerH,w,footerH)
    love.graphics.setFont(fonts.micro or fonts.small);love.graphics.setColor(.94,.95,.91,.88)
    love.graphics.printf("클릭  강화 선택     ·     드래그  트리 이동     ·     휠  확대/축소",0,h-footerH+(footerH-fonts.small:getHeight())/2,w,"center")
    if self.messageTime>0 then
        local width=math.min(520,w*.46)
        love.graphics.setColor(.94,.95,.91,.98); love.graphics.rectangle("fill",w/2-width/2,h-82,width,38,3,3)
        local success=self.messageKind=="ok"
        love.graphics.setColor(success and {.24,.58,.32,1} or {.72,.28,.20,1}); love.graphics.rectangle("fill",w/2-width/2,h-82,4,38,2,2)
        love.graphics.setFont(fonts.body); love.graphics.printf(self.message,w/2-width/2+12,h-72,width-24,"center")
    end
end

return CharacterTraitBoard
