local UI = require("src.ui")

local RushMode = {}
RushMode.__index = RushMode

local definitions = {
    {id="twin_axe", name="쌍날 도끼", desc="한 번에 타격하는 나무가 2그루 증가합니다.", max=4, color={1,.62,.18}},
    {id="wide_swing", name="넓은 휘두르기", desc="광역 벌목 반경이 45 증가합니다.", max=5, color={.35,.9,.5}},
    {id="chain_fell", name="연쇄 벌목", desc="나무가 쓰러질 때 주변 나무로 충격이 연쇄됩니다.", max=4, color={1,.78,.2}},
    {id="magnet", name="강력 자석", desc="목재 자동 흡수 반경과 속도가 증가합니다.", max=5, color={.3,.82,1}},
    {id="overdrive", name="과충전 도끼", desc="도끼 타격 속도가 22% 빨라집니다.", max=5, color={1,.38,.22}},
    {id="rich_yield", name="풍성한 수확", desc="나무 한 그루가 목재를 2개 더 떨어뜨립니다.", max=5, color={.75,.48,1}}
}

local byId = {}
for _, def in ipairs(definitions) do byId[def.id] = def end

local function formatTime(value)
    value = math.max(0, math.floor(value))
    return string.format("%02d:%02d", math.floor(value / 60), value % 60)
end

function RushMode.new()
    return setmetatable({
        levels={}, choices={}, level=1, xp=0, xpNext=10, pending=0,
        totalWood=0, treesFelled=0, combatTier=0, elapsed=0,
        firstWindowWood=0, lastWindowWood=0, maxMulti=1, maxChain=0,
        axeCooldown=0, axeRange=185
    }, RushMode)
end

function RushMode:levelOf(id) return self.levels[id] or 0 end
function RushMode:pickupRadius() return 135 + self:levelOf("magnet") * 95 end
function RushMode:pickupSpeed() return 12 + self:levelOf("magnet") * 4 end

function RushMode:setup(game)
    game.runType, game.rush = "rush", self
    game.time, game.ended, game.victory = 180, false, false
    game.player.x, game.player.y = 1600, 1510
    game.player.speed, game.player.capacity, game.player.gather = 300, 99999, 1.15
    game.camera.x, game.camera.y, game.camera.zoom = game.player.x, game.player.y, .86
    game.world.nodes, game.world.drops, game.world.enemies, game.world.buildings = {}, {}, {}, {}
    game.world.theme = "forest"
    game.world.treeVisual.scale = .18
    game.world.treeVisual.shadowRx, game.world.treeVisual.shadowRy, game.world.treeVisual.frontBias = 58, 8, 82
    local attempts = 0
    while #game.world.nodes < 78 and attempts < 1800 do
        attempts = attempts + 1
        local x = love.math.random(115, game.world.width - 115)
        local y = love.math.random(1240, game.world.height - 90)
        local dx, dy = x - game.world.core.x, y - game.world.core.y
        local trailX = game.world.core.x + math.sin((y - 1240) * .006) * 115
        local clearCore = dx*dx + dy*dy > 345*345
        local clearTrail = math.abs(x - trailX) > 88
        local separated = true
        for _, node in ipairs(game.world.nodes) do
            local ndx, ndy = x - node.x, y - node.y
            if ndx*ndx + ndy*ndy < 132*132 then separated = false; break end
        end
        if clearCore and clearTrail and separated then
            local variantCount = #(game.world.images.treeVariants or {game.world.images.tree})
            local treeVariant = ((#game.world.nodes * 3 + 1) % variantCount) + 1
            game.world.nodes[#game.world.nodes+1] = {kind="tree",x=x,y=y,work=0,workTime=1,active=true,respawn=0,rushTree=true,rushHp=2,rushMaxHp=2,treeVariant=treeVariant}
        end
    end
    game.world.wall.maxHp, game.world.wall.hp = 520, 520
    game.world.wall.damageReduction = .18
    game.world.core.damage, game.world.core.fireRate, game.world.core.range = 25, 1.65, 720
    game.world.spawnTimer = 4
    game.world:addTurret("autocannon", 1)
    game:setNotice("채집 러시 시작 — 나무를 쓸어 전선을 폭주시켜라!", "food")
end

function RushMode:update(dt, game)
    self.elapsed = math.min(180, self.elapsed + dt)
    if self.elapsed <= 30 then self.firstWindowWood = self.totalWood end
    if self.elapsed >= 150 then self.lastWindowWood = self.totalWood - (self.woodAt150 or self.totalWood); self.woodAt150 = self.woodAt150 or self.totalWood end
    for _, building in ipairs(game.world.buildings) do if building.fuel then building.fuel = 1 end end
    self:updateHeldAxe(dt, game)
end

function RushMode:closestTreeInAxeRange(game)
    local bestNode, bestDistance
    local range2 = self.axeRange * self.axeRange
    for _, node in ipairs(game.world.nodes) do
        if node.rushTree and node.active then
            local dx, dy = node.x - game.player.x, node.y - game.player.y
            local distance = dx * dx + dy * dy
            if distance <= range2 and (not bestDistance or distance < bestDistance) then
                bestNode, bestDistance = node, distance
            end
        end
    end
    return bestNode
end

function RushMode:updateHeldAxe(dt, game, heldOverride)
    local held = heldOverride
    if held == nil then held = love.mouse.isDown(1) end
    game.player.axeHolding = held
    game.player.axeRange = self.axeRange
    self.axeCooldown = math.max(0, self.axeCooldown - dt)
    if not held or self.axeCooldown > 0 then return false end
    local target = self:closestTreeInAxeRange(game)
    if not target then return false end
    game.player:cancelInteraction()
    game.player:playAutoAxeSwing(target.x)
    self:hitTree(target, game)
    local speed = (game.tools.axe.speed or 1) * game.player.gather
    self.axeCooldown = .62 / speed
    return true
end

function RushMode:onWood(amount, game)
    self.totalWood, self.xp = self.totalWood + amount, self.xp + amount
    game.wood = self.totalWood
    while self.xp >= self.xpNext do
        self.xp = self.xp - self.xpNext
        self.level, self.pending = self.level + 1, self.pending + 1
        self.xpNext = math.floor(10 + (self.level - 1) * 6.5)
    end
    local nextTier = math.min(4, math.floor((self.totalWood + 20) / 55))
    if nextTier > self.combatTier then
        for tier = self.combatTier + 1, nextTier do game.world:addTurret(tier == 4 and "rail" or "autocannon", math.min(5,tier+1)) end
        self.combatTier = nextTier
        game.world.core.damage = 25 * (1 + self.combatTier * .38)
        game.world.core.fireRate = 1.65 * (1 + self.combatTier * .24)
        game.world:resourcePulse(game,"wood",self.combatTier,"자동 화력 "..self.combatTier.."단계")
        game:setNotice("목재가 전선으로 전달됨 — 자동 화력 "..self.combatTier.."단계!", "food")
    end
    if self.pending > 0 and game.mode == "playing" and not os.getenv("LAST_HAUL_SELF_TEST") then self:rollChoices(); game.mode="rush_upgrade" end
end

function RushMode:rollChoices()
    local pool = {}
    for _, def in ipairs(definitions) do if self:levelOf(def.id) < def.max then pool[#pool+1]=def end end
    for i=#pool,2,-1 do local j=love.math.random(i); pool[i],pool[j]=pool[j],pool[i] end
    self.choices={}
    for i=1,math.min(3,#pool) do self.choices[i]=pool[i] end
end

function RushMode:choose(index, game)
    local def=self.choices[index]
    if not def then return false end
    self.levels[def.id]=self:levelOf(def.id)+1
    if def.id=="overdrive" then game.player.gather=game.player.gather*1.22 end
    self.pending=math.max(0,self.pending-1)
    game:setNotice(def.name.." Lv."..self:levelOf(def.id),"food")
    if self.pending>0 then self:rollChoices() else game.mode="playing" end
    return true
end

function RushMode:fellTree(node, game)
    if not node.active then return false end
    node.active,node.respawn,node.rushHp=false,7+love.math.random()*3,0
    local amount=3+self:levelOf("rich_yield")*2
    game.world:harvestBurst(node,game,amount,"목재")
    game.world:spawnDrop("wood",amount,node.x,node.y-10,42,30,1.5)
    self.treesFelled=self.treesFelled+1
    return true
end

function RushMode:hitTree(primary, game)
    if not primary.active then return end
    local radius=75+self:levelOf("wide_swing")*45
    local targetCount=1+self:levelOf("twin_axe")*2
    local candidates={}
    for _,node in ipairs(game.world.nodes) do
        if node.rushTree and node.active then
            local dx,dy=node.x-primary.x,node.y-primary.y
            local d2=dx*dx+dy*dy
            if d2<=radius*radius then candidates[#candidates+1]={node=node,d2=d2} end
        end
    end
    table.sort(candidates,function(a,b) return a.d2<b.d2 end)
    local felled={}
    local hits=math.min(targetCount,#candidates)
    self.maxMulti=math.max(self.maxMulti,hits)
    for i=1,hits do
        local node=candidates[i].node
        node.rushHp=(node.rushHp or node.rushMaxHp)-1
        game.world:impactNode(node,game,false)
        if node.rushHp<=0 and self:fellTree(node,game) then felled[#felled+1]=node end
    end
    local chainLevel=self:levelOf("chain_fell")
    local chainCount,queue=0,{}
    for _,node in ipairs(felled) do queue[#queue+1]=node end
    local cursor,maxChain=1,chainLevel*2
    while cursor<=#queue and chainCount<maxChain do
        local source=queue[cursor]; cursor=cursor+1
        local nextNode,best
        for _,node in ipairs(game.world.nodes) do
            if node.rushTree and node.active then
                local dx,dy=node.x-source.x,node.y-source.y
                local d2=dx*dx+dy*dy
                if d2<=(135+chainLevel*45)^2 and (not best or d2<best) then nextNode,best=node,d2 end
            end
        end
        if nextNode then
            nextNode.rushHp=0
            game.world:impactNode(nextNode,game,true)
            if self:fellTree(nextNode,game) then queue[#queue+1]=nextNode; chainCount=chainCount+1 end
        end
    end
    self.maxChain=math.max(self.maxChain,chainCount)
end

function RushMode:finish(game, victory)
    if game.result then return end
    game.ended,game.victory=true,victory==true
    local last=self.lastWindowWood
    local growth=self.firstWindowWood>0 and last/self.firstWindowWood or 0
    game.result={elapsed=math.floor(self.elapsed),wood=self.totalWood,trees=self.treesFelled,maxMulti=self.maxMulti,maxChain=self.maxChain,tier=self.combatTier,first=self.firstWindowWood,last=last,growth=growth}
    game.mode="rush_results"
end

function RushMode:drawHUD(game,fonts)
    local w,h=love.graphics.getDimensions()
    UI.panel(16,16,360,124,{.35,1,.52,1},.94)
    love.graphics.setFont(fonts.big); love.graphics.setColor(1,1,1); love.graphics.print(formatTime(game.time),32,27)
    love.graphics.setFont(fonts.body); love.graphics.setColor(.95,.7,.25); love.graphics.print("채집 러시 실험실",155,35)
    love.graphics.setFont(fonts.small); love.graphics.setColor(.72,.9,.76); love.graphics.print(string.format("목재 %d   쓰러뜨린 나무 %d",self.totalWood,self.treesFelled),32,76)
    love.graphics.print(string.format("동시 타격 %d   연쇄 %d   자동 화력 %d단계",self.maxMulti,self.maxChain,self.combatTier),32,101)
    UI.panel(w/2-150,16,300,62,{1,.68,.2,1},.9)
    love.graphics.setColor(.9,.95,.9); love.graphics.printf("계속 캐면 전선이 자동으로 강해집니다",w/2-140,29,280,"center")
    UI.bar(w/2-132,53,264,9,self.xp/self.xpNext,{.35,1,.55,1})
    love.graphics.setFont(fonts.small); love.graphics.setColor(.75,.86,.8); love.graphics.printf("생산 레벨 "..self.level.."  ·  다음 3택 "..math.max(0,self.xpNext-self.xp),w/2-140,66,280,"center")
    love.graphics.setColor(.04,.07,.055,.86); love.graphics.rectangle("fill",16,h-52,565,36,8,8)
    love.graphics.setColor(.82,.9,.84); love.graphics.print("마우스 누른 채 이동: 범위 자동 벌목  ·  WASD: 이동  ·  ESC: 로비",30,h-43)
    self:drawBattleMonitor(game,fonts)
end

function RushMode:drawBattleMonitor(game,fonts)
    local screenW=love.graphics.getWidth()
    local x,y,w,h=screenW-430,16,414,174
    local wallRatio=math.max(0,game.world.wall.hp/game.world.wall.maxHp)
    local accent=wallRatio>.45 and {.32,.88,1,1} or wallRatio>.2 and {1,.72,.2,1} or {1,.25,.18,1}
    UI.panel(x,y,w,h,accent,.96)
    love.graphics.setFont(fonts.small); love.graphics.setColor(.82,.91,.94)
    love.graphics.print("실시간 전선 중계",x+14,y+9)
    love.graphics.setColor(accent); love.graphics.printf(string.format("적 %d  ·  방벽 %d%%",#game.world.enemies,math.floor(wallRatio*100)),x+170,y+9,w-184,"right")
    local vx,vy,vw,vh=x+10,y+34,w-20,h-44
    love.graphics.setColor(.018,.028,.032,1); love.graphics.rectangle("fill",vx,vy,vw,vh,5,5)
    love.graphics.setScissor(vx,vy,vw,vh)
    love.graphics.push()
    local scale=vw/game.world.width
    love.graphics.translate(vx,vy+vh-6)
    love.graphics.scale(scale,scale)
    love.graphics.translate(0,-(game.world.wall.y+170))
    game.world:draw(game.player)
    love.graphics.pop()
    love.graphics.setScissor()
    love.graphics.setColor(0,0,0,.52); love.graphics.rectangle("fill",vx,vy,vw,21)
    love.graphics.setFont(fonts.small); love.graphics.setColor(.85,.9,.9)
    love.graphics.printf("▲ 적 진입 방향     자동 포탑 전투     ▼ 방어벽",vx,vy+3,vw,"center")
    love.graphics.setColor(accent); love.graphics.setLineWidth(2); love.graphics.rectangle("line",vx+.5,vy+.5,vw-1,vh-1,5,5)
end

function RushMode:drawSelection(game,fonts)
    local w,h=love.graphics.getDimensions()
    love.graphics.setColor(.015,.035,.025,.84); love.graphics.rectangle("fill",0,0,w,h)
    love.graphics.setFont(fonts.title); love.graphics.setColor(1,.82,.3); love.graphics.printf("채집 방식 진화",0,66,w,"center")
    love.graphics.setFont(fonts.small); love.graphics.setColor(.72,.88,.76); love.graphics.printf("스킬 하나를 선택합니다.",0,112,w,"center")
    local gap,cardW,cardH=24,math.min(320,(w-96)/3),360
    local startX=w/2-(cardW*3+gap*2)/2
    self.choiceBoxes={}
    for i,def in ipairs(self.choices) do
        local x,y=startX+(i-1)*(cardW+gap),165
        self.choiceBoxes[i]={x=x,y=y,w=cardW,h=cardH}
        UI.panel(x,y,cardW,cardH,{def.color[1],def.color[2],def.color[3],1},.97)
        love.graphics.setColor(def.color[1],def.color[2],def.color[3],.18); love.graphics.circle("fill",x+cardW/2,y+105,62)
        love.graphics.setColor(def.color); love.graphics.setLineWidth(6); love.graphics.circle("line",x+cardW/2,y+105,38)
        love.graphics.setFont(fonts.big); love.graphics.setColor(1,1,1); love.graphics.printf(tostring(i),x,y+85,cardW,"center")
        love.graphics.setFont(fonts.heading); love.graphics.printf(def.name,x+16,y+190,cardW-32,"center")
        love.graphics.setFont(fonts.body); love.graphics.setColor(.72,.82,.77); love.graphics.printf(def.desc,x+28,y+242,cardW-56,"center")
        love.graphics.setColor(1,.75,.25); love.graphics.printf("Lv."..self:levelOf(def.id).." → Lv."..(self:levelOf(def.id)+1),x+20,y+318,cardW-40,"center")
    end
end

function RushMode:choiceAt(x,y)
    for i,box in ipairs(self.choiceBoxes or {}) do if x>=box.x and x<=box.x+box.w and y>=box.y and y<=box.y+box.h then return i end end
end

function RushMode:drawResults(game,fonts)
    local w,h,r=love.graphics.getWidth(),love.graphics.getHeight(),game.result
    love.graphics.setColor(0,0,0,.84); love.graphics.rectangle("fill",0,0,w,h)
    UI.panel(w/2-330,h/2-250,660,500,{.35,1,.52,1},.98)
    love.graphics.setFont(fonts.title); love.graphics.setColor(1,1,1); love.graphics.printf("3분 채집 러시 완료",w/2-300,h/2-220,600,"center")
    love.graphics.setFont(fonts.small); love.graphics.setColor(.7,.85,.76); love.graphics.printf("핵심 재미 검증 보고서",w/2-300,h/2-170,600,"center")
    local rows={{"총 목재",r.wood},{"쓰러뜨린 나무",r.trees},{"최대 동시 타격",r.maxMulti},{"최대 연쇄 벌목",r.maxChain},{"최종 자동 화력",r.tier.."단계"},{"첫 30초 / 마지막 30초",r.first.." / "..r.last},{"채집 성장 배율",string.format("%.1fx",r.growth)}}
    for i,row in ipairs(rows) do local y=h/2-132+(i-1)*38; love.graphics.setColor(i%2==0 and {.07,.12,.1,.9} or {.045,.085,.07,.9}); love.graphics.rectangle("fill",w/2-270,y,540,32,4,4); love.graphics.setColor(.72,.82,.76); love.graphics.print(row[1],w/2-250,y+7); love.graphics.setColor(1,.75,.25); love.graphics.printf(tostring(row[2]),w/2+40,y+7,270,"center") end
    UI.button(w/2-250,h/2+196,240,48,"로비로",true,fonts.body); UI.button(w/2+10,h/2+196,240,48,"다시 실험",true,fonts.body)
end

return RushMode
