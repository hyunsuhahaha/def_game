local Camera = require("src.camera")
local World = require("src.world")
local Player = require("src.player")
local Lobby = require("src.lobby")
local UI = require("src.ui")
local Frontend = require("src.frontend_ui")
local Progression = require("src.progression")
local TraitTree = require("src.trait_tree")
local Feedback = require("src.feedback")
local RunUpgrades = require("src.run_upgrades")
local RushMode = require("src.rush_mode")
local ClearcutMode = require("src.clearcut_mode")
local ClearcutIntro = require("src.clearcut_intro")
local WorldProjection = require("src.world_projection")
local SkyView = require("src.skyview")
local NorthBackdrop = require("src.north_backdrop")
local CharacterTraits = require("src.character_traits")
local CharacterTraitBoard = require("src.character_trait_board")
local CharacterStory = require("src.character_story")
local Buildings = require("src.buildings")
local Cigarette = require("src.cigarette_sprite")
local VeganForkArt = require("src.vegan_fork_art")
local Achievements = require("src.achievements")
local AchievementBoard = require("src.achievement_board")
local resourceLabels = {wood = "목재", stone = "돌", ore = "광석", food = "식량"}
local VIEW_PITCH_MIN,VIEW_PITCH_MAX=.72,1

local Game = {}
Game.__index = Game

local function radial(size)
    local data, c = love.image.newImageData(size, size), (size - 1) / 2
    data:mapPixel(function(x, y) local d = math.min(1, math.sqrt((x - c)^2 + (y - c)^2) / c); return 1, .82, .55, (1 - d)^2 * .34 end)
    local img = love.graphics.newImage(data); img:setFilter("linear", "linear"); return img
end

local function makeFonts()
    local regular, bold = "assets/font-korean-regular.ttf", "assets/font-korean-bold.ttf"
    return {micro = love.graphics.newFont(bold, 12), small = love.graphics.newFont(regular, 14), body = love.graphics.newFont(regular, 17), heading = love.graphics.newFont(bold, 21), big = love.graphics.newFont(bold, 28), title = love.graphics.newFont(bold, 36), display = love.graphics.newFont(bold, 48)}
end

local function loadClearcutSprites()
    local specs = {
        physical = {file="logger-atlas-pixel-v2.png", walkFeet={190,190,190,190,190,190}, actionFeet={190,190,190,190,190,190}, scale=.61},
        fire = {file="smoker-atlas-pixel-v2.png", walkFeet={190,190,190,190,190,190}, actionFeet={190,190,190,190,190,190}, scale=.61},
        toxic = {file="vegan-atlas-pixel-v3.png", walkFeet={190,190,190,190,190,190}, actionFeet={190,190,190,190,190,190}, scale=.75,nativeFacing=1},
        developer = {file="developer-atlas-pixel-v2.png", walkFeet={190,190,190,190,190,190}, actionFeet={190,190,190,190,190,190}, scale=.61},
        -- The authored philosopher source faces right.
        philosopher = {file="philosopher-atlas-pixel-v2.png", walkFeet={190,190,190,190,190,190}, actionFeet={190,190,190,190,190,190}, scale=.61, nativeFacing=1},
        -- The mole source faces left. Keep that authored orientation explicit so
        -- the shared renderer mirrors it toward movement/aim correctly.
        -- Its first claw poses crouch heavily; these factors keep body mass stable.
        miner = {file="coin-miner-mole-atlas-pixel-v3.png", walkFeet={380,380,380,380,380,380}, actionFeet={380,380,380,380,380,380}, scale=.48,
            nativeFacing=-1, actionFacing={1,-1,-1,1,1,1}, actionScale={1.28,1.48,1.52,1,1,1}}
    }
    -- The source smoker sheet turns left during the first four action poses.
    -- Normalize those cells at draw time; keep the original atlas untouched.
    specs.fire.actionFacing = {-1, -1, -1, -1, 1, 1}
    specs.fire.walkMouth = {{68,29},{73,29},{68,42},{74,29},{75,36},{73,29}}
    specs.fire.actionMouth = {{34,30},{34,30},{31,29},{35,32},{65,32},{66,31}}
    for _, spec in pairs(specs) do
        spec.image = love.graphics.newImage("assets/characters/ingame/" .. spec.file)
        spec.image:setFilter("nearest", "nearest")
    end
    specs.fire.cigarette = Cigarette.load()
    specs.toxic.veganArt = VeganForkArt.load()
    return specs
end

function Game.new()
    local self = setmetatable({}, Game)
    self.fonts, self.light, self.feedback = makeFonts(), radial(512), Feedback.new()
    self.clearcutSprites = loadClearcutSprites()
    self.clearcutMachineryImage = love.graphics.newImage("assets/characters/ingame/developer-bulldozer-pixel-v2.png")
    self.clearcutMachineryImage:setFilter("nearest", "nearest")
    self.settings = {fullscreen = love.window.getFullscreen(), screenShake = true, viewPitch = .76}
    self.tools = {
        axe = {name = "나무 도끼", speed = .8, type = "벌목"},
        hoe = {name = "나무 괭이", speed = 1, type = "농사"},
        pickaxe = {name = "나무 곡괭이", speed = .75, type = "채광"},
        water = {name = "휴대 급수기", speed = 1, type = "농사 보조"},
        hammer = {name = "나무 수리 망치", speed = 1, type = "방벽 수리"}
    }
    self.wallCosts = {{wood = 0, stone = 0}, {wood = 12, stone = 8}, {wood = 22, stone = 16}, {wood = 36, stone = 28}}
    local temporaryProfile = os.getenv("LAST_HAUL_SELF_TEST") or os.getenv("LAST_HAUL_CAPTURE_META") or os.getenv("LAST_HAUL_CAPTURE_RESULTS") or os.getenv("LAST_HAUL_CAPTURE_TEST_OPTIONS") or os.getenv("LAST_HAUL_CAPTURE_TURRET_PROMPT") or os.getenv("LAST_HAUL_CAPTURE_TURRET_PLACEMENT") or os.getenv("LAST_HAUL_CAPTURE_BOSS_ENTRANCE") or os.getenv("LAST_HAUL_CAPTURE_ACHIEVEMENTS") or os.getenv("LAST_HAUL_CAPTURE_ACHIEVEMENT_POPUP") or os.getenv("LAST_HAUL_CAPTURE_SKYVIEW")
    self.progression = Progression.new(temporaryProfile ~= nil)
    self.characterTraits = CharacterTraits.new(temporaryProfile ~= nil)
    self.achievements = Achievements.new(temporaryProfile ~= nil)
    self.world = World.new(); self.lobby = Lobby.new(self.world.images, self.fonts)
    self.traitTree = TraitTree.new(self.progression, self.fonts, self.world.images, self.world.buildingIcons)
    self.characterTraitBoard = CharacterTraitBoard.new(self.characterTraits, self.fonts, self.clearcutSprites)
    self.achievementBoard = AchievementBoard.new(self.achievements, self.fonts)
    self.mode, self.notice, self.noticeKind, self.noticeTime = "lobby", "", "core", 0
    self.storyJob, self.storyPage, self.storyForced = nil, 1, false
    self.sandboxMode = false
    self:resetRun(); self.mode = "lobby"
    return self
end

function Game:resetRun()
    self.runType, self.rush, self.clearcut = nil, nil, nil
    self.world = World.new()
    self.player = Player.new(1600, 1470, self.world.images.workerWalk, self.world.images.workerActions, self.world.images.workerRepair)
    self.camera = Camera.new(self.player.x, self.player.y)
    self.camera.pitch = 1
    self.camera.perspective = false
    self.camera.shakeScale = self.settings.screenShake and 1 or 0
    self.food, self.ore, self.wood, self.stone, self.seeds = 0, 0, 0, 0, 8
    self.time, self.ended, self.victory, self.hoverNode, self.hoverWall, self.hoverBuilding, self.nearTurret = 15 * 60, false, false, nil, false, nil, nil
    self.paused = false
    self.runStats, self.result, self.prestiged = {harvested = 0}, nil, false
    self.upgrades, self.runLevel, self.runXP, self.runXPNext, self.pendingLevels = RunUpgrades.new(), 1, 0, 18, 0
    self.runXPVisual, self.runXPPulse, self.lastXPGain = 0, 0, 0
    local meta = self.progression:effects()
    self.world:setTurretSlotLimit(meta.turretSlots)
    self.turretSlotLimit = self.world.turretSlotLimit
    self.player.gather = self.player.gather * meta.gather
    self.player.capacity = self.player.capacity + meta.capacity
    self.player.speed = self.player.speed * meta.move
    self.seeds, self.ore = self.seeds + meta.seeds, self.ore + meta.ore
    self.wood, self.stone = self.wood + meta.materials, self.stone + meta.materials
    self.world.core.damage = self.world.core.damage * meta.damage
    self.world.core.fireRate = self.world.core.fireRate * meta.fireRate
    self.world.wall.hpMultiplier, self.world.wall.damageReduction = meta.wallHp, meta.wallGuard
    self.world.wall.maxHp = math.floor(self.world.wall.maxHp * meta.wallHp + .5)
    self.world.wall.hp = self.world.wall.maxHp
    self.repairBonus, self.rewardMultiplier = meta.repair, meta.reward
    self.harvestBonus = meta.harvestBonus
    self.buildCostMultiplier = meta.buildCost
    self.metaFuelEfficiency = meta.fuelEff
    self.metaProduceBonus = meta.produceBonus
    self.world.core.maxHp = math.floor(self.world.core.maxHp * meta.coreHp + .5)
    self.world.core.hp = self.world.core.maxHp
    self.world.spawnTimer = self.world.spawnTimer + meta.prepTime
    if meta.startTurret then
        local slot = self.world:firstAvailableTurretSlot()
        if slot then self.world:addBuilding("autocannon_turret", slot.x, slot.y, slot.index) end
    end
    self:consumeTestNextRunResources()
end

function Game:startRun()
    self:resetRun(); self:consumeTestNextRunLevels(); self.mode = "playing"; self:setNotice("작전 시작 — 자원을 생산해 거점을 지키세요", "core")
    if self.pendingLevels > 0 then self.upgrades:rollChoices(self); self.mode = "upgrade" end
end

function Game:startRush()
    self:resetRun()
    self.rush=RushMode.new()
    self.rush:setup(self)
    self:consumeTestNextRunLevels()
    self.mode="playing"
    if self.rush.pending>0 then self.rush:rollChoices();self.mode="rush_upgrade" end
end

function Game:startClearcut(characterId, mapId, stage)
    mapId=mapId or (self.clearcut and self.clearcut.mapId) or self.selectedClearcutMap or "forest"
    stage=stage or (self.clearcut and self.clearcut.stage) or self.selectedClearcutStage or 1
    self:resetRun()
    self.clearcut=ClearcutMode.new()
    self.clearcut.job = characterId
    self.clearcut.mapId=require("src.clearcut_maps").get(mapId).id
    self.clearcut.stage=stage
    self.selectedClearcutMap=self.clearcut.mapId
    self.selectedClearcutStage=stage
    self.player:setClearcutSprite(self.clearcutSprites[characterId] or self.clearcutSprites.physical, characterId)
    self.clearcut:setup(self)
    self:consumeTestNextRunLevels()
    self.selectedClearcutStage=self.clearcut.stage
    -- The simulation remains top-down world space. Rendering and pointer input
    -- share one nonlinear projection that narrows both axes into the distance.
    self:enableClearcutPerspective()
    self.mode="playing"
    ClearcutIntro.begin(self)
    if self.clearcut.pending>0 then self.clearcut:openUpgradeChoices(self) end
end
function Game:setNotice(text, kind) self.notice, self.noticeKind, self.noticeTime = text, kind or "core", 2.2 end

function Game:viewTiltAmount()
    local settings=self.settings or {}
    return (VIEW_PITCH_MAX-(settings.viewPitch or .76))/(VIEW_PITCH_MAX-VIEW_PITCH_MIN)
end

function Game:setViewTilt(amount)
    amount=math.max(0,math.min(1,amount or 0))
    self.settings=self.settings or {}
    self.settings.viewPitch=VIEW_PITCH_MAX-(VIEW_PITCH_MAX-VIEW_PITCH_MIN)*amount
    if self.camera and self.camera.perspective then self.camera.pitch=self.settings.viewPitch end
end

function Game:enableClearcutPerspective()
    local settings=self.settings or {}
    self.camera.pitch=math.max(VIEW_PITCH_MIN,math.min(VIEW_PITCH_MAX,settings.viewPitch or .76))
    self.camera.perspective=true
end

function Game:grantTestRunResources()
    self.food, self.ore, self.wood, self.stone, self.seeds = self.food + 1000000, self.ore + 1000000, self.wood + 1000000, self.stone + 1000000, self.seeds + 1000000
end

function Game:consumeTestNextRunResources()
    if not self.testGrantNextRun then return false end
    self.testGrantNextRun=false
    self:grantTestRunResources()
    return true
end

function Game:grantTestLevels(count)
    count = math.max(1, math.floor(count or 10))
    local track=self.clearcut or self.rush
    if track then
        for _=1,count do
            track.level,track.pending=track.level+1,track.pending+1
            track.xpNext=math.floor(10+(track.level-1)*6.5)
        end
        return count
    end
    for _ = 1, count do self:addRunXP(math.max(0, self.runXPNext - self.runXP)) end
    return count
end

function Game:consumeTestNextRunLevels()
    local count=math.max(0,math.floor(self.testLevelsNextRun or 0))
    if count<=0 then return 0 end
    local manual=self.testLevelsNextRunManual
    self.testLevelsNextRun,self.testLevelsNextRunManual=0,false
    self:grantTestLevels(count)
    if not manual then self:autoResolvePendingUpgrades() end
    return count
end

-- 테스트 메뉴로 예약된 "다음 런 시작 레벨" 지급은 3택 화면을 20번 직접 눌러야 해서
-- 번거로우므로, 매 픽마다 무작위로 하나를 자동 선택해 즉시 소진한다.
function Game:autoResolvePendingUpgrades()
    if self.clearcut then
        local c=self.clearcut
        local guard=0
        while (c.pending>0 or c.selectionKind=="fusion" or c.selectionKind=="arcana") and guard<200 do
            guard=guard+1
            if c.selectionKind=="fusion" then
                c:chooseFusion(1,self)
            elseif c.selectionKind=="arcana" then
                if c.arcanaChoices and #c.arcanaChoices>0 then c:chooseArcana(love.math.random(#c.arcanaChoices),self)
                else c.selectionKind="upgrade" end
            else
                c:rollChoices()
                if not c.choices or #c.choices==0 then break end
                c:choose(love.math.random(#c.choices),self)
            end
        end
        c.choices, c.choiceBoxes, c.specialCard = {}, {}, nil
    end
    if self.rush then
        local r=self.rush
        while r.pending>0 do
            r:rollChoices()
            if not r.choices or #r.choices==0 then break end
            r:choose(love.math.random(#r.choices),self)
        end
        r.choices={}
    end
    while self.pendingLevels>0 do
        self.upgrades:rollChoices(self)
        local choices=self.upgrades.choices
        if not choices or #choices==0 then break end
        if self.upgrades:choose(love.math.random(#choices),self) then self.pendingLevels=math.max(0,self.pendingLevels-1)
        else break end
    end
end

function Game:openTestOptions(returnMode)
    self.testReturnMode, self.mode, self.testMessage, self.testResetArmed, self.testResetTime = returnMode or self.mode, "test_options", "테스트 기능은 실제 저장 데이터에 반영됩니다.", false, 0
end

function Game:closeTestOptions()
    local target=self.testReturnMode or "lobby"
    self.mode=target
    if target=="playing" then
        if self.clearcut and self.clearcut.pending>0 then self.clearcut:openUpgradeChoices(self)
        elseif self.rush and self.rush.pending>0 then self.rush:rollChoices();self.mode="rush_upgrade"
        elseif self.pendingLevels>0 then self.upgrades:rollChoices(self);self.mode="upgrade" end
    end
end

function Game:useTestOption(index)
    local activeRun=self.testReturnMode=="playing" or self.testReturnMode=="upgrade" or self.testReturnMode=="rush_upgrade" or self.testReturnMode=="clearcut_upgrade"
    if index==1 then
        self.progression:addCurrency(1000000); self.testMessage="유산 부품 1,000,000개를 지급했습니다."
    elseif index==2 then
        if activeRun then self:grantTestRunResources(); self.testMessage="현재 런 자원을 각각 1,000,000개 지급했습니다."
        else self.testGrantNextRun=true; self.testMessage="다음 런 자원 1,000,000개 지급을 예약했습니다." end
    elseif index==3 then
        if activeRun then self:grantTestLevels(10); self.testMessage="현재 런 레벨 +10을 지급했습니다. 메뉴를 닫으면 3택이 시작됩니다."
        else self.testLevelsNextRun,self.testLevelsNextRunManual=20,false; self.testMessage="다음 런 시작 레벨 +20을 예약했습니다. 강화는 무작위로 자동 선택됩니다." end
    elseif index==4 then
        if self.testResetArmed and self.testResetTime>0 then self.progression:reset();self.characterTraits:reset();self.achievements:reset();self.testResetArmed=false;self.testMessage="영구 재화·특성·업적 기록을 초기화했습니다."
        else self.testResetArmed,self.testResetTime=true,4; self.testMessage="초기화하려면 4초 안에 버튼을 한 번 더 누르세요." end
    elseif index==5 then
        self.testLevelsNextRun,self.testLevelsNextRunManual=20,true
        self.testMessage="다음 런 시작 레벨 +20을 예약했습니다. 강화를 직접 3택으로 고릅니다."
    end
end

function Game:depositCargo(message)
    local total = self.player:totalCargo()
    if total <= 0 then return false end
    self.food, self.ore, self.wood, self.stone = self.food + self.player.food, self.ore + self.player.ore, self.wood + self.player.wood, self.stone + self.player.stone
    self.player.food, self.player.ore, self.player.wood, self.player.stone = 0, 0, 0, 0
    self:setNotice(message or "모든 자원을 거점에 납품했습니다", "core")
    return true
end

function Game:addRunXP(amount)
    if self.runType=="clearcut" then return end
    if self.runType=="rush" then return end
    amount = math.max(0, amount or 0)
    self.runXP = self.runXP + amount
    if amount > 0 then self.runXPPulse, self.lastXPGain = 1, amount end
    while self.runXP >= self.runXPNext do
        self.runXP = self.runXP - self.runXPNext
        self.runLevel, self.pendingLevels = self.runLevel + 1, self.pendingLevels + 1
        self.runXPNext = 18 + (self.runLevel - 1) * 10
    end
    if self.pendingLevels > 0 and self.mode == "playing" and not os.getenv("LAST_HAUL_SELF_TEST") then
        self.upgrades:rollChoices(self); self.mode = "upgrade"
    end
end

function Game:selectRunUpgrade(index)
    if self.mode ~= "upgrade" or not self.upgrades:choose(index, self) then return end
    self.pendingLevels = math.max(0, self.pendingLevels - 1)
    if self.pendingLevels > 0 then self.upgrades:rollChoices() else self.mode = "playing" end
end

function Game:finishRun(victory)
    if (self.mode ~= "playing" and self.mode ~= "upgrade") or self.result then return end
    self.ended, self.victory = true, victory == true
    local elapsed = math.floor(15 * 60 - self.time)
    local survival = math.floor(elapsed / 60)
    local waves = math.floor(self.world.wave / 5)
    local kills = math.floor(self.world.kills / 15)
    local harvest = math.floor((self.runStats.harvested or 0) / 25)
    local victoryBonus = self.victory and 12 or 0
    local base = math.max(2, survival + waves + kills + harvest + victoryBonus)
    local earned = math.floor(base * (self.rewardMultiplier or 1) + .5)
    self.progression:addCurrency(earned)
    self.result = {elapsed = elapsed, survival = survival, waves = waves, kills = kills, harvest = harvest, victory = victoryBonus, earned = earned}
    self.mode = "results"
end

function Game:prestigeRun()
    if self.mode ~= "playing" or self.ended or self.result then return end
    self.prestiged = true
    self:finishRun(false)
end

function Game:update(dt)
    self.achievements:update(dt)
    self.achievementBoard:update(dt)
    if self.paused then return end
    -- Camera presentation modes keep lerping even while an intro, boss reveal,
    -- or skill cut-in temporarily freezes ordinary world/camera tracking.
    self.camera:updateMode(dt)
    if self.mode == "lobby" then self.lobby:update(dt); return end
    if self.mode == "settings" then self.lobby:update(dt); return end
    if self.mode == "clearcut_map_select" then require("src.clearcut_map_select").update(self,dt);return end
    if self.mode == "clearcut_select" or self.mode == "clearcut_briefing" or self.mode == "character_story" or self.mode == "character_codex" or self.mode == "achievements" then return end
    if self.mode == "character_traits" then self.characterTraitBoard:update(dt); return end
    if self.mode == "test_options" then self.testResetTime=math.max(0,(self.testResetTime or 0)-dt); if self.testResetTime<=0 then self.testResetArmed=false end; return end
    if self.mode == "meta" then self.traitTree:update(dt); return end
    if self.mode == "results" or self.mode == "rush_results" or self.mode == "clearcut_results" then return end
    if self.mode == "build_select" then return end
    self.runXPVisual = self.runXPVisual + (self.runXP - self.runXPVisual) * (1 - math.exp(-dt * 9))
    self.runXPPulse = math.max(0, self.runXPPulse - dt * 1.35)
    if self.mode == "upgrade" or self.mode == "rush_upgrade" or self.mode == "clearcut_upgrade" then return end
    if self.mode == "turret_upgrade" then return end
    if ClearcutIntro.update(self,dt) then return end
    if self.clearcut and self.clearcut:updateBossEntrance(dt,self) then
        self.camera:update(dt,self.player,self.world)
        return
    end
    if self.clearcut and self.clearcut:updateWorldTreeEmergence(dt,self) then
        self.camera:update(dt,self.player,self.world)
        return
    end
    self.noticeTime = math.max(0, self.noticeTime - dt)
    local wx, wy = self.camera:screenToWorld(love.mouse.getPosition())
    self.hoverNode, self.hoverWall, self.hoverBuilding = self.world:findNodeAt(wx, wy), self.world:isWallAt(wx, wy), self.world:buildingAt(wx, wy)
    if self.ended then return end
    self.time = math.max(0, self.time - dt)
    if self.time <= 0 then
        if self.runType=="rush" then self.rush:finish(self,true)
        elseif self.runType~="clearcut" then self:finishRun(true) end
        return
    end
    self.player:update(dt, self.world, self)
    self.nearTurret = self:getNearbyTurret()
    self.upgrades:update(dt, self)
    if self.rush then self.rush:update(dt,self) end
    if self.clearcut then self.clearcut:update(dt,self) end
    self.world:update(dt, self); self.camera:update(dt, self.player, self.world)
    if self.clearcut and self.clearcut.readyToFinish and not self.ended then self.clearcut:finish(self, true) end
    if self.ended and not self.clearcut then
        if self.rush then self.rush:finish(self,self.victory) else self:finishRun(self.victory) end
    end
end

function Game:keypressed(key)
    if self.mode=="test_options" then if key=="escape" or key=="f10" then self:closeTestOptions() end; return end
    if key=="f10" then self:openTestOptions(self.mode); return end
    if self.paused then
        if key=="escape" then self.paused=false;self.pauseTiltDragging=false
        elseif key=="left" or key=="a" then self:setViewTilt(self:viewTiltAmount()-.04)
        elseif key=="right" or key=="d" then self:setViewTilt(self:viewTiltAmount()+.04)
        elseif key=="home" then self:setViewTilt(0)
        elseif key=="end" then self:setViewTilt(1) end
        return
    end
    if self.mode == "lobby" then
        if key == "escape" then love.event.quit(); return end
        local action=self.lobby:keypressed(key)
        if action=="clearcut" then
            self.mode="clearcut_select"
        elseif action=="character_traits" then
            self.characterTraitReturnMode="lobby"
            self.mode="character_traits"
        elseif action=="character_codex" then
            self.mode="character_codex"
        elseif action=="achievements" then
            self.mode="achievements"
        elseif action=="skill_sandbox" then
            self.sandboxMode=true
            self.mode="clearcut_select"
        end
        return
    end
    if self.mode == "achievements" then
        if self.achievementBoard:keypressed(key)=="back" then self.mode="lobby" end
        return
    end
    if self.mode == "character_codex" then
        if key=="escape" then self.mode="lobby" end
        return
    end
    if self.mode == "clearcut_map_select" then
        local select=require("src.clearcut_map_select")
        local mapCount=#require("src.clearcut_maps").catalog
        if key=="escape" then self.mode="clearcut_select"
        elseif key=="return" or key=="kpenter" or key=="space" then self:chooseClearcutMap(self.clearcutMapFocus or 1)
        elseif tonumber(key) and tonumber(key)>=1 and tonumber(key)<=mapCount then select.focus(self,tonumber(key),false)
        elseif key=="up" or key=="w" then select.setStage(self,(self.selectedClearcutStage or 1)+1)
        elseif key=="down" or key=="s" then select.setStage(self,(self.selectedClearcutStage or 1)-1)
        elseif key=="left" or key=="a" then select.focus(self,((self.clearcutMapFocus or 1)-2)%mapCount+1,false)
        elseif key=="right" or key=="d" then select.focus(self,(self.clearcutMapFocus or 1)%mapCount+1,false) end
        return
    end
    if self.mode == "clearcut_briefing" then
        if key=="escape" then self.mode="clearcut_map_select"
        elseif key=="return" or key=="kpenter" or key=="space" then self:startClearcut(self.pendingClearcutCharacter,self.selectedClearcutMap,self.selectedClearcutStage) end
        return
    end
    if self.mode == "clearcut_select" then
        if key=="t" then self.characterTraitReturnMode="clearcut_select"; self.mode="character_traits"
        elseif key=="1" or key=="2" or key=="3" or key=="4" or key=="5" or key=="6" then self:chooseClearcutCharacter(tonumber(key))
        elseif key=="escape" then self.mode="lobby" end
        return
    end
    if self.mode == "character_story" then
        if key=="right" or key=="return" or key=="kpenter" or key=="space" then self:advanceStory()
        elseif key=="left" then self:regressStory()
        elseif key=="escape" and not self.storyForced then self:finishCharacterStory() end
        return
    end
    if self.mode == "character_traits" then
        if self.characterTraitBoard:keypressed(key)=="back" then self.mode=self.characterTraitReturnMode or "clearcut_select" end
        return
    end
    if self.mode == "settings" then
        if key == "escape" then self.mode = "lobby"
        elseif key == "left" or key == "a" then self:setViewTilt(self:viewTiltAmount()-.05)
        elseif key == "right" or key == "d" then self:setViewTilt(self:viewTiltAmount()+.05)
        elseif key == "home" then self:setViewTilt(0)
        elseif key == "end" then self:setViewTilt(1) end
        return
    end
    if self.mode == "meta" then if self.traitTree:keypressed(key) == "back" then self.mode = "lobby" end; return end
    if self.mode == "upgrade" then if key == "1" or key == "2" or key == "3" then self:selectRunUpgrade(tonumber(key)) end; return end
    if self.mode == "rush_upgrade" then if key=="1" or key=="2" or key=="3" then self.rush:choose(tonumber(key),self) end; return end
    if self.mode == "clearcut_upgrade" then
        if self.clearcut:choicesLocked() then return end
        if self.clearcut.selectionKind=="fusion" and (key=="return" or key=="kpenter" or key=="space") then
            self.clearcut:choose(1,self)
        elseif key=="1" or key=="2" or key=="3" then self.clearcut:choose(tonumber(key),self) end
        return
    end
    if self.mode == "build_select" then if key == "escape" then self.mode = "playing" end; return end
    if self.mode == "turret_upgrade" then
        if key == "escape" then self:cancelTurretUpgrade()
        elseif key == "1" or key == "2" or key == "3" then self:chooseTurretMod(tonumber(key)) end
        return
    end
    if self.mode == "rush_results" then
        if key=="return" or key=="r" then self:startRush() elseif key=="escape" then self.mode="lobby" end
        return
    end
    if self.mode == "clearcut_results" then
        if key=="return" or key=="r" then self:startClearcut(self.clearcut and self.clearcut.job) elseif key=="escape" then self.mode="lobby" end
        return
    end
    if self.mode == "results" then
        if key == "t" then self.mode = "meta"
        elseif key == "return" or key == "escape" then self.mode = "lobby" end
        return
    end
    if ClearcutIntro.active(self) then
        if key=="space" or key=="return" or key=="kpenter" or key=="escape" then ClearcutIntro.skip(self) end
        return
    end
    if key == "escape" and self.placingBuilding then self.placingBuilding = nil; self:setNotice("건설을 취소했습니다", "core"); return end
    if key == "escape" and self.mode == "playing" then self.paused = true; return end
    if key == "escape" then self.mode = "lobby"; return end
    if self.clearcut and self.clearcut.worldTreeEmergence then return end
    if self.ended and (key == "r" or key == "return") then self:startRun(); return end
    if key == "p" and self.runType~="rush" and self.runType~="clearcut" then self:prestigeRun(); return end
    if self.runType=="clearcut" then
        if key=="space" and self.clearcut then
            self.clearcut:activateMinerBurrow(self)
            self.clearcut:beginSmokeRingCharge(self)
            self.clearcut:activateRevival(self)
        end
        return
    end
    if self.runType=="rush" then return end
    if key == "f" then
        local turret = self:getNearbyTurret()
        if turret then self:tryOpenTurretUpgrade(turret)
        else self:setNotice("강화할 포탑 가까이에서 F를 누르세요", "ore") end
        return
    end
    if key == "1" or key == "2" or key == "3" or key == "4" or key == "5" then self:useAbility(tonumber(key)) end
end

function Game:keyreleased(key)
    if ClearcutIntro.active(self) then return end
    if self.clearcut and self.clearcut.worldTreeEmergence then return end
    if key=="space" and self.runType=="clearcut" and self.clearcut then
        self.clearcut:releaseSmokeRingCharge(self)
    end
end

function Game:useAbility(index)
    if index == 1 and self.food >= 12 then self.food = self.food - 12; self.world:spawnDefender("bio", 1, self); self:setNotice("생체 수호자를 부화했습니다", "food") end
    if index == 2 then
        for _, def in ipairs(Buildings) do if def.id == "autocannon_turret" then self:beginBuildingPlacement(def); break end end
    end
    if index == 3 and self.food >= 8 and self.ore >= 8 then self.food, self.ore = self.food - 8, self.ore - 8; self.player.gather = self.player.gather * 1.15; self.player.capacity = self.player.capacity + 5; self:setNotice("작업 장비를 개조했습니다", "core") end
    if index == 4 then
        local wall = self.world.wall
        if wall.level < wall.maxLevel then
            local cost = self.wallCosts[wall.level + 1]
            if self.wood >= cost.wood and self.stone >= cost.stone then
                self.wood, self.stone = self.wood - cost.wood, self.stone - cost.stone
                self.world:upgradeWall(); self:setNotice("방어벽 " .. wall.level .. "단계 강화 완료", "core")
            else self:setNotice(string.format("방어벽 강화 필요: 목재 %d · 돌 %d", cost.wood, cost.stone), "core") end
        else self:setNotice("방어벽이 최고 단계입니다", "core") end
    end
    if index == 5 then self.mode = "build_select" end
end

function Game:mousepressed(x, y, button)
    if self.paused then
        if button==1 then
            local _, _, _, _, resumeBox, quitBox, tiltBox = self:pauseButtons()
            if Frontend.inside(tiltBox,x,y) then
                self.pauseTiltDragging=true
                self:setViewTilt(Frontend.sliderValueAt(tiltBox,x))
            elseif Frontend.inside(resumeBox,x,y) then self.paused=false;self.pauseTiltDragging=false
            elseif Frontend.inside(quitBox,x,y) then self.paused=false;self.pauseTiltDragging=false;self.mode="lobby" end
        end
        return
    end
    if self.mode=="test_options" then
        if button==1 then
            local w=love.graphics.getWidth(); local bx=w/2-290
            if x>=bx and x<=bx+580 then
                if y>=220 and y<=278 then self:useTestOption(1)
                elseif y>=300 and y<=358 then self:useTestOption(2)
                elseif y>=380 and y<=438 then self:useTestOption(3)
                elseif y>=460 and y<=518 then self:useTestOption(5)
                elseif y>=540 and y<=598 then self:useTestOption(4)
                elseif y>=640 and y<=686 then self:closeTestOptions() end
            end
        end
        return
    end
    if self.mode == "lobby" then
        local action = self.lobby:mousepressed(x, y, button)
        if action == "clearcut" then self.mode = "clearcut_select"
        elseif action == "character_traits" then self.characterTraitReturnMode="lobby"; self.mode = "character_traits"
        elseif action == "character_codex" then self.mode = "character_codex"
        elseif action == "achievements" then self.mode = "achievements"
        elseif action == "skill_sandbox" then self.sandboxMode = true; self.mode = "clearcut_select"
        elseif action == "settings" then self.mode = "settings" end
        return
    end
    if ClearcutIntro.active(self) then if button==1 then ClearcutIntro.skip(self) end;return end
    if self.mode == "achievements" then
        if self.achievementBoard:mousepressed(x,y,button)=="back" then self.mode="lobby" end
        return
    end
    if self.mode == "character_codex" then
        if button==1 then
            if self.codexBackBox and x>=self.codexBackBox.x and x<=self.codexBackBox.x+self.codexBackBox.w and y>=self.codexBackBox.y and y<=self.codexBackBox.y+self.codexBackBox.h then self.mode="lobby"; return end
            for _, box in ipairs(self.codexCharBoxes or {}) do
                local sb = box.storyBox
                if x>=sb.x and x<=sb.x+sb.w and y>=sb.y and y<=sb.y+sb.h then self:openCharacterStory(box.jobId, false, "character_codex"); return end
            end
        end
        return
    end
    if self.mode == "clearcut_select" then
        if button==1 then
            if self.clearcutTraitBox and x>=self.clearcutTraitBox.x and x<=self.clearcutTraitBox.x+self.clearcutTraitBox.w and y>=self.clearcutTraitBox.y and y<=self.clearcutTraitBox.y+self.clearcutTraitBox.h then self.characterTraitReturnMode="clearcut_select"; self.mode="character_traits"; return end
            for _, box in ipairs(self.clearcutCharBoxes or {}) do
                local rw = box.rewatch
                if rw and x>=rw.x and x<=rw.x+rw.w and y>=rw.y and y<=rw.y+rw.h then self:openCharacterStory(box.jobId, false, "clearcut_select"); return end
            end
            local index=self:clearcutCharAt(x,y); if index then self:chooseClearcutCharacter(index) end
        end
        return
    end
    if self.mode == "character_story" then
        if button==1 then
            if self.storyBackBox and not self.storyForced and x>=self.storyBackBox.x and x<=self.storyBackBox.x+self.storyBackBox.w and y>=self.storyBackBox.y and y<=self.storyBackBox.y+self.storyBackBox.h then
                self:finishCharacterStory(); return
            end
            self:advanceStory()
        end
        return
    end
    if self.mode == "character_traits" then
        if self.characterTraitBoard:mousepressed(x,y,button)=="back" then self.mode=self.characterTraitReturnMode or "clearcut_select" end
        return
    end
    if self.mode=="clearcut_map_select" then
        if button==1 then
            if Frontend.inside(self.clearcutMapConfirmBox,x,y) then self:chooseClearcutMap(self.clearcutMapFocus or 1);return
            elseif Frontend.inside(self.clearcutMapBackBox,x,y) then self.mode="clearcut_select";return end
            if require("src.clearcut_map_select").mousepressed(self,x,y,button)=="stage"then return end
        end
        return
    end
    if self.mode=="clearcut_briefing" then
        if button==1 then
            if Frontend.inside(self.clearcutBriefingStartBox,x,y) then self:startClearcut(self.pendingClearcutCharacter,self.selectedClearcutMap,self.selectedClearcutStage)
            elseif Frontend.inside(self.clearcutBriefingBackBox,x,y) then self.mode="clearcut_map_select" end
        end
        return
    end
    if self.mode == "settings" then
        if button == 1 then
            if Frontend.inside(self.settingsBackBox,x,y) then self.mode = "lobby"
            elseif Frontend.inside(self.settingsTiltBox,x,y) then
                self.settingsTiltDragging=true
                self:setViewTilt(Frontend.sliderValueAt(self.settingsTiltBox,x))
            elseif Frontend.inside(self.settingsShakeBox,x,y) then
                self.settings.screenShake = not self.settings.screenShake
                self.camera.shakeScale = self.settings.screenShake and 1 or 0
            elseif Frontend.inside(self.settingsFullscreenBox,x,y) then
                local nextValue = not self.settings.fullscreen
                local ok = love.window.setFullscreen(nextValue, "desktop")
                if ok ~= false then self.settings.fullscreen = nextValue end
            elseif Frontend.inside(self.settingsTestBox,x,y) then self:openTestOptions("settings")
            end
        end
        return
    end
    if self.mode == "meta" then if self.traitTree:mousepressed(x, y, button) == "back" then self.mode = "lobby" end; return end
    if self.mode == "upgrade" then if button == 1 then local index = self.upgrades:choiceAt(x, y); if index then self:selectRunUpgrade(index) end end; return end
    if self.mode == "rush_upgrade" then if button==1 then local index=self.rush:choiceAt(x,y); if index then self.rush:choose(index,self) end end; return end
    if self.mode == "clearcut_upgrade" then
        if button==1 and not self.clearcut:choicesLocked() then
            local index=self.clearcut:choiceAt(x,y); if index then self.clearcut:choose(index,self) end
        end
        return
    end
    if self.mode == "build_select" then
        if button == 1 then
            if x >= 28 and x <= 176 and y >= 25 and y <= 67 then self.mode = "playing"; return end
            local index = self:buildCardAt(x, y)
            if index then self:beginBuildingPlacement(Buildings[index]); self.mode = "playing" end
        end
        return
    end
    if self.mode == "turret_upgrade" then
        if button == 1 then
            local index = self:turretChoiceAt(x, y)
            if index then self:chooseTurretMod(index) end
        elseif button == 2 then
            self:cancelTurretUpgrade()
        end
        return
    end
    if self.mode == "rush_results" then
        if button==1 then local w,h=love.graphics.getDimensions(); if y>=h/2+196 and y<=h/2+244 then if x>=w/2-250 and x<=w/2-10 then self.mode="lobby" elseif x>=w/2+10 and x<=w/2+250 then self:startRush() end end end
        return
    end
    if self.mode == "clearcut_results" then
        if button==1 then local boxes=self.clearcutResultButtons or{};local function inside(b)return b and x>=b.x and x<=b.x+b.w and y>=b.y and y<=b.y+b.h end;if inside(boxes.lobby)then self.mode="lobby"elseif inside(boxes.retry)then self:startClearcut(self.clearcut and self.clearcut.job)end end
        return
    end
    if self.mode == "results" then
        if button == 1 then
            local w, h = love.graphics.getDimensions()
            if y >= h / 2 + 174 and y <= h / 2 + 224 then
                if x >= w / 2 - 240 and x <= w / 2 - 10 then self.mode = "lobby"
                elseif x >= w / 2 + 10 and x <= w / 2 + 240 then self.mode = "meta" end
            end
        end
        return
    end
    -- Practice controls are screen UI and must remain operable even if a
    -- sandbox scenario leaves gameplay ended or inside an emergence freeze.
    if self.clearcut and self.clearcut.sandbox and button==1 and self:sandboxPanelClick(x, y) then return end
    if self.ended then return end
    if self.clearcut and self.clearcut.worldTreeEmergence then return end
    if self.runType=="rush" or self.runType=="clearcut" then
        -- 벌목 러시/숲 전멸 모드는 개별 나무를 클릭하지 않는다. 버튼을 누르는 동안
        -- 해당 모드가 플레이어 주변의 나무를 자동 포착한다.
        if self.runType=="clearcut" and button==2 and self.clearcut then self.clearcut:activateMinerBurrow(self) end
        return
    end
    if self.placingBuilding then
        local wx, wy = self.camera:screenToWorld(x, y)
        local def = self.placingBuilding
        if button == 1 then
            local isTurret = self.world:isTurretBuilding(def.id)
            local turretSlot = isTurret and self.world:turretSlotAt(wx, wy, true) or nil
            local validPosition = isTurret and turretSlot ~= nil or (not isTurret and self.world:canPlaceBuilding(wx, wy, def.footprint))
            if validPosition then
                local cost = self:buildingCost(def)
                local canAfford = true
                for res, amt in pairs(cost) do if (self[res] or 0) < amt then canAfford = false end end
                if canAfford then
                    for res, amt in pairs(cost) do self[res] = self[res] - amt end
                    local placed = isTurret and self.world:addBuilding(def.id, turretSlot.x, turretSlot.y, turretSlot.index) or self.world:addBuilding(def.id, wx, wy)
                    if not placed then self:setNotice("포대 슬롯에 배치할 수 없습니다", "ore"); return end
                    self:setNotice(def.name .. " 건설 완료", "core")
                    self.placingBuilding = nil
                else
                    local parts = {}
                    for res, amt in pairs(cost) do parts[#parts + 1] = resourceLabels[res] .. " " .. amt end
                    self:setNotice("자원 부족 — 필요: " .. table.concat(parts, " · "), "core")
                end
            else
                self:setNotice(isTurret and "초록색 빈 포대 슬롯에만 설치할 수 있습니다" or "여기엔 지을 수 없습니다", isTurret and "ore" or "core")
            end
        elseif button == 2 then
            self.placingBuilding = nil; self:setNotice("건설을 취소했습니다", "core")
        end
        return
    end
    if button ~= 1 then return end
    local hw, hh = love.graphics.getDimensions()
    local nearbyTurret = self:getNearbyTurret()
    if nearbyTurret and x >= hw / 2 - 210 and x <= hw / 2 + 210 and y >= hh - 146 and y <= hh - 102 then
        self:tryOpenTurretUpgrade(nearbyTurret); return
    end
    if x >= hw / 2 - 105 and x <= hw / 2 + 105 and y >= 118 and y <= 150 then self:prestigeRun(); return end
    local slotW, gap, startX, barY = 132, 8, hw / 2 - 346, hh - 92
    for i = 1, 5 do
        local sx = startX + (i - 1) * (slotW + gap)
        if x >= sx and x <= sx + slotW and y >= barY and y <= barY + 70 then self:useAbility(i); return end
    end
    local wx, wy = self.camera:screenToWorld(x, y)
    local building = self.world:buildingAt(wx, wy)
    if building then self:tryOpenTurretUpgrade(building); return end
    if self.world:isWallAt(wx, wy) then self.player:beginWallRepair(self.world, self); return end
    local node = self.world:findNodeAt(wx, wy)
    if node then self.player:beginInteraction(node, self.world, self) else self.player:cancelInteraction() end
end

function Game:wheelmoved(x, y)
    if self.paused then
        local mx,my=love.mouse.getPosition();local _,_,_,_,_,_,tiltBox=self:pauseButtons()
        if Frontend.inside(tiltBox,mx,my) and y~=0 then self:setViewTilt(self:viewTiltAmount()+(y>0 and .04 or -.04)) end
        return
    end
    if self.mode=="settings" then
        local mx,my=love.mouse.getPosition()
        if Frontend.inside(self.settingsTiltBox,mx,my) and y~=0 then self:setViewTilt(self:viewTiltAmount()+(y>0 and .04 or -.04)) end
        return
    end
    if self.mode=="character_traits" then self.characterTraitBoard:wheelmoved(x,y); return end
    if self.mode=="achievements" then self.achievementBoard:wheelmoved(x,y); return end
    if self.mode=="clearcut_map_select" then local mx,my=love.mouse.getPosition();require("src.clearcut_map_select").wheelmoved(self,mx,my,y);return end
    if self.clearcut and self.clearcut.sandbox and self.sandboxPanelBox and y~=0 then
        local mx,my=love.mouse.getPosition();local b=self.sandboxPanelBox
        if mx>=b.x and mx<=b.x+b.w and my>=b.y and my<=b.y+b.h then
            self.sandboxPanelScroll=math.max(0,math.min(self.sandboxScrollMax or 0,(self.sandboxPanelScroll or 0)-y*72));return
        end
    end
    if self.clearcut and self.clearcut.worldTreeEmergence then return end
    if self.mode ~= "playing" or y == 0 then return end
    if not (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")) then return end
    local factor = y > 0 and 1.1 or 1 / 1.1
    if self.clearcut and self.camera.perspective then
        local userZoom=math.max(.52,math.min(1.6,(self.camera.userZoom or 1)*factor))
        self.camera.userZoom=userZoom
        local baseZoom=self.world.stageZoom or self.camera.zoom
        if self.world.overviewBounds then
            local w,h=love.graphics.getDimensions();local bounds=self.world.overviewBounds
            baseZoom=math.min(w/bounds.w,h/bounds.h)
        end
        self.camera.zoom=baseZoom*userZoom
        self.camera.renderZoom=self.camera.zoom
        return
    end
    if self.world.overviewBounds then return end
    self.camera.zoom = math.max(.6, math.min(1.8, self.camera.zoom * factor))
end

function Game:buildingCost(def)
    local mult = self.buildCostMultiplier or 1
    local cost = {}
    for res, amt in pairs(def.cost) do cost[res] = math.max(1, math.floor(amt * mult + .5)) end
    return cost
end

function Game:beginBuildingPlacement(def)
    if self.world:isTurretBuilding(def.id) and not self.world:firstAvailableTurretSlot() then
        self.placingBuilding = nil
        self:setNotice(string.format("포대 슬롯이 가득 찼습니다 (%d/%d) — 영구 특성에서 확장하세요", self.world:turretBuildingCount(), self.world.turretSlotLimit), "ore")
        return false
    end
    self.placingBuilding = def
    self:setNotice(self.world:isTurretBuilding(def.id) and "초록색 포대 슬롯을 클릭해 설치하세요" or (def.name .. " 배치 위치를 선택하세요"), "core")
    return true
end

function Game:buildCardAt(x, y)
    for i, box in ipairs(self.buildCardBoxes or {}) do
        if x >= box.x and x <= box.x + box.w and y >= box.y and y <= box.y + box.h then return i end
    end
end

function Game:getNearbyTurret()
    if not self.world or not self.player then return nil end
    return self.world:nearestTurretBuilding(self.player.x, self.player.y, 280)
end

function Game:tryOpenTurretUpgrade(building)
    if not self.world:isTurretBuilding(building.kind) then self:setNotice("이 건물은 강화할 수 없습니다", "core"); return end
    local dx, dy = building.x - self.player.x, building.y - self.player.y
    if dx * dx + dy * dy > 280 * 280 then self:setNotice("포탑에 더 가까이 가세요", "core"); return end
    if (building.level or 0) >= self.world:turretMaxLevel() then self:setNotice("이미 최고 단계입니다", "ore"); return end
    local cost = self.world:turretUpgradeCost(building)
    if (self.ore or 0) < cost then self:setNotice("광석 부족 — 필요: 광석 " .. cost, "ore"); return end
    self.turretUpgradeTarget = building
    self.turretUpgradeChoices = self.world:rollTurretMods()
    self.turretUpgradeCostValue = cost
    self.mode = "turret_upgrade"
end

function Game:chooseTurretMod(index)
    local building = self.turretUpgradeTarget
    local choice = self.turretUpgradeChoices and self.turretUpgradeChoices[index]
    if not building or not choice then return end
    local cost = self.turretUpgradeCostValue or 0
    if (self.ore or 0) < cost then self:cancelTurretUpgrade(); return end
    self.ore = self.ore - cost
    building.mods = building.mods or {}
    building.mods[choice.id] = (building.mods[choice.id] or 0) + 1
    building.level = (building.level or 0) + 1
    building.flash = .5
    self.world:turretUpgradeBurst(building, choice)
    if self.camera then self.camera.trauma = math.min(1, self.camera.trauma + .32) end
    local def = self.world:defFor(building.kind)
    self:setNotice((def and def.name or "포탑") .. " " .. choice.name .. " 적용! Lv." .. building.level, "ore")
    self.turretUpgradeTarget, self.turretUpgradeChoices = nil, nil
    self.mode = "playing"
end

function Game:cancelTurretUpgrade()
    self.turretUpgradeTarget, self.turretUpgradeChoices = nil, nil
    self.mode = "playing"
end

function Game:turretChoiceAt(x, y)
    for i, box in ipairs(self.turretChoiceBoxes or {}) do
        if x >= box.x and x <= box.x + box.w and y >= box.y and y <= box.y + box.h then return i end
    end
end

local turretModIcons = {
    multishot = function(cx, cy, r, color)
        love.graphics.setColor(color); love.graphics.setLineWidth(2.4)
        love.graphics.circle("line", cx, cy, r * .74)
        love.graphics.circle("line", cx, cy, r * .28)
        love.graphics.line(cx - r * .95, cy, cx - r * .5, cy); love.graphics.line(cx + r * .5, cy, cx + r * .95, cy)
        love.graphics.line(cx, cy - r * .95, cx, cy - r * .5); love.graphics.line(cx, cy + r * .5, cx, cy + r * .95)
        for _, a in ipairs({-math.pi / 2, math.pi / 6, math.pi * 5 / 6}) do
            love.graphics.circle("fill", cx + math.cos(a) * r * .74, cy + math.sin(a) * r * .74, r * .11)
        end
    end,
    double_tap = function(cx, cy, r, color)
        love.graphics.setColor(color); love.graphics.setLineWidth(3.4)
        for _, off in ipairs({-r * .42, r * .42}) do
            love.graphics.line(cx - r * .4, cy + off - r * .3, cx + r * .18, cy + off, cx - r * .4, cy + off + r * .3)
        end
    end,
    heavy_shell = function(cx, cy, r, color)
        love.graphics.setColor(color)
        love.graphics.polygon("fill", cx, cy - r * .85, cx + r * .38, cy - r * .1, cx + r * .38, cy + r * .7, cx - r * .38, cy + r * .7, cx - r * .38, cy - r * .1)
        love.graphics.setColor(0, 0, 0, .32); love.graphics.rectangle("fill", cx - r * .38, cy + r * .22, r * .76, r * .13)
        love.graphics.setColor(1, 1, 1, .4); love.graphics.polygon("fill", cx, cy - r * .78, cx + r * .1, cy - r * .3, cx - r * .1, cy - r * .3)
    end,
    rapid_coil = function(cx, cy, r, color)
        love.graphics.setColor(color); love.graphics.setLineWidth(2.6)
        for i = 0, 2 do
            love.graphics.arc("line", "open", cx, cy - r * .55 + i * r * .55, r * .42, math.pi * .15, math.pi * 1.85, 24)
        end
    end,
    long_barrel = function(cx, cy, r, color)
        love.graphics.setColor(color); love.graphics.setLineWidth(4)
        love.graphics.line(cx - r * .8, cy - r * .16, cx + r * .35, cy - r * .16)
        love.graphics.line(cx - r * .8, cy + r * .16, cx + r * .35, cy + r * .16)
        love.graphics.polygon("fill", cx + r * .3, cy - r * .38, cx + r * .85, cy, cx + r * .3, cy + r * .38)
    end
}

local function drawCardRivets(x, y, w, h)
    love.graphics.setColor(.5, .43, .32, 1)
    for _, corner in ipairs({{x + 15, y + 15}, {x + w - 15, y + 15}, {x + 15, y + h - 15}, {x + w - 15, y + h - 15}}) do
        love.graphics.circle("fill", corner[1], corner[2], 5)
        love.graphics.setColor(.85, .74, .5, .9); love.graphics.circle("fill", corner[1] - 1.2, corner[2] - 1.2, 1.8)
        love.graphics.setColor(.5, .43, .32, 1)
    end
end

function Game:drawTurretUpgrade()
    local w, h, f = love.graphics.getWidth(), love.graphics.getHeight(), self.fonts
    local building = self.turretUpgradeTarget
    if not building then return end
    local def = self.world:defFor(building.kind)
    local t = love.timer.getTime()
    love.graphics.setColor(.01, .015, .02, .86); love.graphics.rectangle("fill", 0, 0, w, h)
    love.graphics.setColor(.95, .78, .28, .07); love.graphics.circle("fill", w / 2, 170, math.max(w, h) * .42)
    love.graphics.setFont(f.small); love.graphics.setColor(.95, .8, .3); love.graphics.printf((def and def.name or "포탑") .. "  ·  Lv." .. (building.level or 0), 0, 88, w, "center")
    love.graphics.setFont(f.title); love.graphics.setColor(1, 1, 1); love.graphics.printf("포탑 강화 — 광석 " .. (self.turretUpgradeCostValue or 0), 0, 120, w, "center")
    local gap = 26
    local cardW = math.min(300, (w - 72 - gap * 2) / 3)
    local cardH, y = 360, 196
    local startX = w / 2 - (cardW * 3 + gap * 2) / 2
    local mx, my = love.mouse.getPosition()
    self.turretChoiceBoxes = {}
    for i, mod in ipairs(self.turretUpgradeChoices or {}) do
        local x = startX + (i - 1) * (cardW + gap)
        local hovered = mx >= x and mx <= x + cardW and my >= y and my <= y + cardH
        self.turretChoiceBoxes[i] = {x = x, y = y, w = cardW, h = cardH}
        local lift = hovered and (4 + math.sin(t * 6) * 1.5) or 0
        local cx, cy = x + cardW / 2, y - lift

        love.graphics.setColor(mod.color[1], mod.color[2], mod.color[3], hovered and (.28 + math.sin(t * 4) * .06) or .1)
        love.graphics.rectangle("fill", x - 10, cy - 10, cardW + 20, cardH + 20, 18, 18)

        love.graphics.setColor(0, 0, 0, .4); love.graphics.rectangle("fill", x + 6, cy + 10, cardW, cardH, 14, 14)

        UI.verticalGradient(x, cy, cardW, cardH, 14, {mod.color[1] * .16 + .05, mod.color[2] * .16 + .06, mod.color[3] * .16 + .08, 1}, {.03, .035, .045, 1})

        love.graphics.setLineWidth(1.5); love.graphics.setColor(.05, .05, .06, 1); love.graphics.rectangle("line", x - 2, cy - 2, cardW + 4, cardH + 4, 15, 15)
        love.graphics.setLineWidth(hovered and 3 or 1.8); love.graphics.setColor(mod.color[1], mod.color[2], mod.color[3], hovered and 1 or .65); love.graphics.rectangle("line", x, cy, cardW, cardH, 14, 14)
        drawCardRivets(x, cy, cardW, cardH)

        local badgeCx, badgeCy, badgeR = cx, cy + 92, 46
        love.graphics.setColor(mod.color[1], mod.color[2], mod.color[3], .22 + (hovered and math.sin(t * 5) * .08 or 0))
        love.graphics.circle("fill", badgeCx, badgeCy, badgeR + 14)
        love.graphics.setColor(.05, .06, .07, 1); love.graphics.circle("fill", badgeCx, badgeCy, badgeR)
        love.graphics.setLineWidth(3); love.graphics.setColor(mod.color); love.graphics.circle("line", badgeCx, badgeCy, badgeR)
        love.graphics.setLineWidth(1); love.graphics.setColor(1, 1, 1, .25); love.graphics.circle("line", badgeCx, badgeCy, badgeR - 6)
        local icon = turretModIcons[mod.id]
        if icon then icon(badgeCx, badgeCy, badgeR * .62, {1, 1, 1, .95}) end

        local plateY, plateH = cy + 160, 34
        love.graphics.setColor(0, 0, 0, .55); love.graphics.rectangle("fill", x + 16, plateY, cardW - 32, plateH, 8, 8)
        love.graphics.setLineWidth(1.4); love.graphics.setColor(mod.color[1], mod.color[2], mod.color[3], .7); love.graphics.rectangle("line", x + 16, plateY, cardW - 32, plateH, 8, 8)
        love.graphics.setFont(f.heading); love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(tostring(i) .. "   " .. mod.name, x + 16, plateY + plateH / 2 - f.heading:getHeight() / 2, cardW - 32, "center")

        love.graphics.setColor(mod.color[1], mod.color[2], mod.color[3], .8)
        love.graphics.polygon("fill", cx, plateY + plateH + 14, cx + 6, plateY + plateH + 20, cx, plateY + plateH + 26, cx - 6, plateY + plateH + 20)

        love.graphics.setFont(f.small); love.graphics.setColor(.72, .78, .84, 1)
        love.graphics.printf(mod.desc, x + 26, plateY + plateH + 38, cardW - 52, "center")

        local stacks = (building.mods and building.mods[mod.id]) or 0
        if stacks > 0 then
            local pillW = 110
            love.graphics.setColor(mod.color[1], mod.color[2], mod.color[3], .18)
            love.graphics.rectangle("fill", cx - pillW / 2, cy + cardH - 46, pillW, 28, 14, 14)
            love.graphics.setLineWidth(1.4); love.graphics.setColor(mod.color); love.graphics.rectangle("line", cx - pillW / 2, cy + cardH - 46, pillW, 28, 14, 14)
            love.graphics.setColor(1, 1, 1, 1); love.graphics.printf("현재 " .. stacks .. "중첩", cx - pillW / 2, cy + cardH - 39, pillW, "center")
        end
    end
    love.graphics.setFont(f.small); love.graphics.setColor(.7, .78, .72); love.graphics.printf("우클릭 또는 ESC로 취소", 0, y + cardH + 30, w, "center")
end

function Game:drawBuildSelect()
    local w, h, f = love.graphics.getWidth(), love.graphics.getHeight(), self.fonts
    self.lobby:drawBackground(w, h)
    love.graphics.setColor(.018, .042, .034, .88); love.graphics.rectangle("fill", 0, 0, w, h)
    UI.button(28, 25, 148, 42, "← 나가기", true, f.body)
    love.graphics.setFont(f.title); love.graphics.setColor(.98, .98, .92); love.graphics.printf("건설", 0, 66, w, "center")
    love.graphics.setFont(f.small); love.graphics.setColor(.75, .83, .75)
    love.graphics.printf("자원을 소모해 생산 시설을 짓습니다 — 카드를 고르면 거점 안 원하는 위치에 배치합니다", 0, 108, w, "center")
    local cols, gap = 5, 14
    local cardW = math.min(206, (w - 80 - gap * (cols - 1)) / cols)
    local cardH = 214
    local startX, startY = w / 2 - (cardW * cols + gap * (cols - 1)) / 2, 150
    local mx, my = love.mouse.getPosition()
    self.buildCardBoxes = {}
    for i, def in ipairs(Buildings) do
        local col, row = (i - 1) % cols, math.floor((i - 1) / cols)
        local x, y = startX + col * (cardW + gap), startY + row * (cardH + gap)
        self.buildCardBoxes[i] = {x = x, y = y, w = cardW, h = cardH}
        local hovered = mx >= x and mx <= x + cardW and my >= y and my <= y + cardH
        local cost = self:buildingCost(def)
        local canAfford = true
        for res, amt in pairs(cost) do if (self[res] or 0) < amt then canAfford = false end end
        local turretSlotAvailable = not self.world:isTurretBuilding(def.id) or self.world:firstAvailableTurretSlot() ~= nil
        canAfford = canAfford and turretSlotAvailable
        UI.panel(x, y, cardW, cardH, canAfford and {.92, .58, .16, 1} or {.4, .42, .44, 1}, hovered and .97 or .9)
        local icon = self.world.buildingIcons[def.id]
        if icon then
            local scale = math.min(90, cardW * .48) / math.max(icon:getWidth(), icon:getHeight())
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(icon, x + cardW / 2, y + 66, 0, scale, scale, icon:getWidth() / 2, icon:getHeight() / 2)
        end
        love.graphics.setFont(f.body); love.graphics.setColor(.95, .96, .9); love.graphics.printf(def.name, x + 8, y + 122, cardW - 16, "center")
        love.graphics.setFont(f.small); love.graphics.setColor(.68, .76, .7); love.graphics.printf(def.desc, x + 10, y + 148, cardW - 20, "center")
        local parts = {}
        for res, amt in pairs(cost) do parts[#parts + 1] = resourceLabels[res] .. " " .. amt end
        love.graphics.setColor(canAfford and {.95, .8, .3, 1} or {1, .5, .45, 1})
        local footer = turretSlotAvailable and table.concat(parts, " · ") or string.format("포대 슬롯 %d/%d", self.world:turretBuildingCount(), self.world.turretSlotLimit)
        love.graphics.printf(footer, x + 8, y + cardH - 24, cardW - 16, "center")
    end
end

function Game:drawClearcutSelect()
    local w,h,f=love.graphics.getWidth(),love.graphics.getHeight(),self.fonts
    local characters=ClearcutMode.characters
    local mx,my=love.mouse.getPosition()
    local compact=h<620; local rosterW=math.min(440,w*.37); local rx=w-rosterW-34; local top=126
    local availableRow=(h-194-10*(#characters-1))/#characters
    local rowH=compact and math.max(48,availableRow) or math.max(68,math.min(84,availableRow))
    local hovered=nil
    for i=1,#characters do local y=top+(i-1)*(rowH+10); if mx>=rx and mx<=rx+rosterW and my>=y and my<=y+rowH then hovered=i end end
    self.clearcutCharacterFocus=hovered or self.clearcutCharacterFocus or 1
    local focus=characters[self.clearcutCharacterFocus]; local accent=focus.color
    Frontend.backdrop(w,h,accent,1)
    love.graphics.setFont(f.micro); love.graphics.setColor(accent); love.graphics.print("작업자 명부",34,24)
    love.graphics.setFont(f.title); love.graphics.setColor(.97,.95,.85); love.graphics.print("작업자 편성",34,51)
    love.graphics.setFont(f.small); love.graphics.setColor(.53,.62,.56); love.graphics.print("이번 작업에 사용할 캐릭터를 선택합니다.",34,96)
    self.clearcutTraitBox={x=w-214,y=30,w=180,h=42}; Frontend.button(self.clearcutTraitBox,"특성 연구",f.small,{accent=Frontend.colors.teal,key="T"})

    local dx,dy,dw,dh=34,126,rx-62,h-194
    Frontend.frame(dx,dy,dw,dh,accent,{selected=true})
    Frontend.label("인사 기록  /  "..string.format("%02d",self.clearcutCharacterFocus),dx+22,dy+18,f.micro,accent)
    local sprite=self.clearcutSprites[focus.id] or self.clearcutSprites.physical
    if sprite then
        local fw,fh=sprite.image:getWidth()/6,sprite.image:getHeight()/2; local quad=love.graphics.newQuad(0,0,fw,fh,sprite.image:getDimensions())
        local scale=math.min(dw*(compact and .34 or .42)/fw,dh*(compact and .48 or .52)/fh); love.graphics.setColor(1,1,1,1); love.graphics.draw(sprite.image,quad,dx+dw*(compact and .23 or .28),dy+dh*.57,0,scale,scale,fw/2,sprite.walkFeet[1])
    end
    local tx=dx+dw*(compact and .46 or .50)
    love.graphics.setFont(compact and f.big or f.display); love.graphics.setColor(.98,.96,.86); love.graphics.printf(focus.name,tx,dy+(compact and 66 or 82),dw-(tx-dx)-28,"left")
    love.graphics.setFont(compact and f.body or f.heading); love.graphics.setColor(accent); love.graphics.printf(focus.tagline,tx,dy+(compact and 111 or 147),dw-(tx-dx)-28,"left")
    love.graphics.setColor(1,1,1,.09); love.graphics.line(tx,dy+(compact and 158 or 205),dx+dw-26,dy+(compact and 158 or 205))
    love.graphics.setFont(compact and f.small or f.body); love.graphics.setColor(.70,.77,.70); love.graphics.printf(focus.detail,tx,dy+(compact and 174 or 224),dw-(tx-dx)-30,"left")
    if not compact then Frontend.badge("고유 작업 방식",tx,dy+dh-105,132,f.small,accent); love.graphics.setColor(.53,.61,.55); love.graphics.print("첫 선택 이후에도 특성 연구망에서 영구 강화 가능",tx,dy+dh-68) end
    love.graphics.setFont(f.small); love.graphics.setColor(1,.78,.28); love.graphics.print("성과 포인트  "..self.characterTraits.data.currency.." P",tx,dy+dh-42)

    self.clearcutCharBoxes={}
    for i,c in ipairs(characters) do
        local y=top+(i-1)*(rowH+10); local selected=i==self.clearcutCharacterFocus; local b={x=rx,y=y,w=rosterW,h=rowH,jobId=c.id}; self.clearcutCharBoxes[i]=b
        Frontend.frame(b.x,b.y,b.w,b.h,c.color,{selected=selected,alpha=selected and .99 or .84,corner=false})
        love.graphics.setFont(f.heading); love.graphics.setColor(selected and {.98,.96,.86,1} or {.60,.67,.61,1}); love.graphics.print(string.format("%02d",i),b.x+17,b.y+14); love.graphics.print(c.name,b.x+60,b.y+14)
        if not compact then love.graphics.setFont(f.small); love.graphics.setColor(selected and c.color or {.42,.49,.44,1}); love.graphics.print(c.tagline,b.x+60,b.y+42) end
        if not compact and self.characterTraits:hasSeenStory(c.id) then b.rewatch={x=b.x+b.w-96,y=b.y+b.h-29,w=80,h=21}; love.graphics.setColor(1,1,1,.38); love.graphics.printf("기록 열람",b.rewatch.x,b.rewatch.y+3,b.rewatch.w,"center") end
    end
    Frontend.footer(w,h,"1–6  작업자 바로 선택    ·    클릭  배정    ·    T  특성 연구    ·    ESC  지휘실",f.small)
end

function Game:clearcutCharAt(x, y)
    for i, box in ipairs(self.clearcutCharBoxes or {}) do if x >= box.x and x <= box.x + box.w and y >= box.y and y <= box.y + box.h then return i end end
end

function Game:drawCharacterStory()
    local w, h, f = love.graphics.getWidth(), love.graphics.getHeight(), self.fonts
    love.graphics.setColor(.01, .015, .02, .97); love.graphics.rectangle("fill", 0, 0, w, h)
    local pages = CharacterStory.pagesFor(self.storyJob)
    local page = pages[math.min(self.storyPage, #pages)] or {text = ""}
    local boxW = math.min(760, w - 80)
    local boxX, boxY, boxH = (w - boxW) / 2, h * .22, h * .5
    UI.panel(boxX, boxY, boxW, boxH, {.9, .78, .4, 1}, .96)
    love.graphics.setFont(f.heading); love.graphics.setColor(1, .88, .5)
    love.graphics.printf(CharacterStory.titleFor(self.storyJob), boxX + 28, boxY + 24, boxW - 56, "center")
    love.graphics.setFont(f.body); love.graphics.setColor(.92, .93, .88)
    love.graphics.printf(page.text or "", boxX + 32, boxY + 76, boxW - 64, "left")
    love.graphics.setFont(f.small); love.graphics.setColor(.68, .74, .68)
    love.graphics.printf(self.storyPage .. " / " .. #pages, boxX, boxY + boxH - 34, boxW - 20, "right")
    local isLast = self.storyPage >= #pages
    local nextLabel = isLast and (self.storyForced and "시작하기" or "닫기") or "다음  →"
    local nextBox = {x = boxX + boxW - 190, y = boxY + boxH + 18, w = 170, h = 42}
    UI.button(nextBox.x, nextBox.y, nextBox.w, nextBox.h, nextLabel, true, f.body)
    if not self.storyForced then
        self.storyBackBox = {x = boxX + 20, y = boxY + boxH + 18, w = 130, h = 42}
        UI.button(self.storyBackBox.x, self.storyBackBox.y, self.storyBackBox.w, self.storyBackBox.h, "← 나가기", true, f.body)
    else
        self.storyBackBox = nil
    end
    love.graphics.setFont(f.small); love.graphics.setColor(.6, .66, .62)
    local hint = self.storyForced and "스페이스/엔터로 진행" or "스페이스/엔터로 진행 · ESC로 나가기"
    love.graphics.printf(hint, boxX, boxY + boxH + 70, boxW, "center")
end

-- 로비의 캐릭터 도감: 캐릭터 선택 화면(clearcut_select)의 진행 로직과는 완전히 분리된
-- 열람 전용 화면이다. 여기서 스토리를 미리 봐도 storySeen은 갱신되지 않는다.
function Game:drawCharacterCodex()
    local w, h, f = love.graphics.getWidth(), love.graphics.getHeight(), self.fonts
    love.graphics.setColor(.015, .035, .025, .92); love.graphics.rectangle("fill", 0, 0, w, h)
    love.graphics.setFont(f.title); love.graphics.setColor(1, .82, .3); love.graphics.printf("캐릭터 도감", 0, 50, w, "center")
    love.graphics.setFont(f.small); love.graphics.setColor(.72, .88, .76); love.graphics.printf("각 캐릭터의 도입부 스토리를 확인할 수 있습니다", 0, 92, w, "center")
    self.codexBackBox = {x = 30, y = 26, w = 110, h = 38}
    UI.button(self.codexBackBox.x, self.codexBackBox.y, self.codexBackBox.w, self.codexBackBox.h, "← 로비로", true, f.small)

    local characters = ClearcutMode.characters
    local count = #characters
    local gap = 20
    local cardW, cardH = math.min(300, (w - 64 - gap * (count - 1)) / count), 360
    local startX, cardY = w / 2 - (cardW * count + gap * (count - 1)) / 2, 140
    self.codexCharBoxes = {}
    for i, c in ipairs(characters) do
        local x, y = startX + (i - 1) * (cardW + gap), cardY
        UI.panel(x, y, cardW, cardH, {c.color[1], c.color[2], c.color[3], 1}, .92)
        local sprite = self.clearcutSprites[c.id] or self.clearcutSprites.physical
        if sprite then
            local fw, fh = sprite.image:getWidth() / 6, sprite.image:getHeight() / 2
            local quad = love.graphics.newQuad(0, 0, fw, fh, sprite.image:getDimensions())
            local previewScale = math.min(130 / fw, 145 / fh)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(sprite.image, quad, x + cardW / 2, y + 150, 0, previewScale, previewScale, fw / 2, sprite.walkFeet[1])
        end
        love.graphics.setFont(f.heading); love.graphics.setColor(1, 1, 1, 1); love.graphics.printf(c.name, x + 14, y + 168, cardW - 28, "center")
        love.graphics.setFont(f.small); love.graphics.setColor(.72, .82, .77); love.graphics.printf(c.tagline, x + 20, y + 204, cardW - 40, "center")
        local storyBox = {x = x + 16, y = y + cardH - 46, w = cardW - 32, h = 30}
        self.codexCharBoxes[i] = {jobId = c.id, storyBox = storyBox}
        UI.button(storyBox.x, storyBox.y, storyBox.w, storyBox.h, "스토리 보기", true, f.small)
    end
end

function Game:chooseClearcutCharacter(index)
    local c = ClearcutMode.characters[index]
    if not c then return end
    if self.sandboxMode then
        self.sandboxMode = false
        self:startClearcutSandbox(c.id)
        return
    end
    self.pendingClearcutCharacter=c.id
    if not self.characterTraits:hasSeenStory(c.id) then
        self:openCharacterStory(c.id, true)
    else
        self.mode="clearcut_map_select"
    end
end

-- 스킬 연습장: 자동 위협/스폰이 전부 꺼진 채로(ClearcutMode.sandbox=true) 그냥 나무만
-- 있는 맵에 들어가서, 화면 우측 패널로 스킬 레벨을 직접 조절하고 "몹 소환" 버튼으로만
-- 적을 부를 수 있다. 스토리/맵 선택 같은 정상 진행 절차는 전부 건너뛴다.
function Game:startClearcutSandbox(characterId)
    self:resetRun()
    self.sandboxPanelScroll=0
    self.clearcut = ClearcutMode.new()
    self.clearcut.job = characterId
    self.clearcut.sandbox = true
    self.clearcut.mapId = require("src.clearcut_maps").get(self.selectedClearcutMap or "forest").id
    self.selectedClearcutMap = self.clearcut.mapId
    self.player:setClearcutSprite(self.clearcutSprites[characterId] or self.clearcutSprites.physical, characterId)
    self.clearcut:setup(self)
    self:enableClearcutPerspective()
    self.mode = "playing"
end

function Game:sandboxCharacterName(jobId)
    for _, c in ipairs(ClearcutMode.characters) do if c.id == jobId then return c.name end end
    return jobId
end

function Game:drawSandboxPanel()
    local w, h, f = love.graphics.getWidth(), love.graphics.getHeight(), self.fonts
    local skills = self.clearcut:sandboxSkillList()
    local branches = self.clearcut:sandboxBranchList()
    local fusions = self.clearcut:sandboxFusionList()
    local jobSkills, sharedSkills = {}, {}
    for _, def in ipairs(skills) do
        if def.job then jobSkills[#jobSkills + 1] = def else sharedSkills[#sharedSkills + 1] = def end
    end
    local panelW, rowH, headerH = math.min(360,w-24), 26, 22
    local panelH = h - 24
    local x, y = w - panelW - 12, 12
    self.sandboxPanelBox={x=x,y=y,w=panelW,h=panelH}
    UI.panel(x, y, panelW, panelH, {.3, .82, .5, 1}, .94)
    love.graphics.setFont(f.small); love.graphics.setColor(1, .92, .55)
    love.graphics.print("스킬 연습장", x + 14, y + 10)
    love.graphics.setColor(.78, .87, .8)
    love.graphics.print(self:sandboxCharacterName(self.clearcut.job), x + 14, y + 28)
    self.sandboxSkyviewBox={x=x+panelW-146,y=y+11,w=132,h=24}
    local skyOn=(self.camera.skyviewTarget or 0)>.5
    UI.button(self.sandboxSkyviewBox.x,self.sandboxSkyviewBox.y,self.sandboxSkyviewBox.w,self.sandboxSkyviewBox.h,
        skyOn and "SKYVIEW 끄기" or "SKYVIEW 보기",true,f.small)

    self.sandboxMaxBox={x=x+14,y=y+49,w=(panelW-34)/2,h=25}
    self.sandboxResetBox={x=self.sandboxMaxBox.x+self.sandboxMaxBox.w+6,y=y+49,w=(panelW-34)/2,h=25}
    UI.button(self.sandboxMaxBox.x,self.sandboxMaxBox.y,self.sandboxMaxBox.w,self.sandboxMaxBox.h,"전부 만렙",true,f.small)
    UI.button(self.sandboxResetBox.x,self.sandboxResetBox.y,self.sandboxResetBox.w,self.sandboxResetBox.h,"전체 초기화",true,f.small)

    local contentTop,contentBottom=y+82,y+panelH-76
    self.sandboxContentBox={x=x+6,y=contentTop,w=panelW-12,h=contentBottom-contentTop}
    local contentHeight=(#jobSkills+#sharedSkills)*rowH+2*headerH
    contentHeight=contentHeight+(#branches>0 and 24+#branches*48 or 0)
    contentHeight=contentHeight+(#fusions>0 and 24+#fusions*rowH or 0)
    self.sandboxScrollMax=math.max(0,contentHeight-self.sandboxContentBox.h)
    self.sandboxPanelScroll=math.max(0,math.min(self.sandboxPanelScroll or 0,self.sandboxScrollMax))
    love.graphics.setScissor(self.sandboxContentBox.x,self.sandboxContentBox.y,self.sandboxContentBox.w,self.sandboxContentBox.h)
    self.sandboxSkillBoxes = {}
    local rowY = contentTop-(self.sandboxPanelScroll or 0)
    local function drawSkillGroup(label, list)
        if #list == 0 then return end
        love.graphics.setFont(f.small); love.graphics.setColor(1, .85, .5)
        love.graphics.print(label, x + 14, rowY + 2)
        rowY = rowY + headerH
        for _, def in ipairs(list) do
            local level = self.clearcut:levelOf(def.id)
            local minusBox={x=x+14,y=rowY,w=24,h=22}
            local plusBox={x=x+panelW-38,y=rowY,w=24,h=22}
            local infoBox={x=minusBox.x+28,y=rowY,w=panelW-84,h=22}
            UI.button(minusBox.x,minusBox.y,minusBox.w,minusBox.h,"−",level>0,f.small)
            love.graphics.setColor(.025,.045,.038,.96);love.graphics.rectangle("fill",infoBox.x,infoBox.y,infoBox.w,infoBox.h,3,3)
            love.graphics.setColor(def.color[1],def.color[2],def.color[3],.22);love.graphics.rectangle("fill",infoBox.x,infoBox.y,infoBox.w*(level/def.max),infoBox.h,3,3)
            love.graphics.setColor(def.color[1],def.color[2],def.color[3],level>0 and .75 or .28);love.graphics.rectangle("line",infoBox.x+.5,infoBox.y+.5,infoBox.w-1,infoBox.h-1,3,3)
            love.graphics.setFont(f.small);love.graphics.setColor(1,1,1,.92);love.graphics.print(def.name,infoBox.x+7,rowY+3)
            love.graphics.setColor(level==def.max and {1,.88,.42} or {.72,.82,.76});love.graphics.printf("Lv."..level.." / "..def.max,infoBox.x,rowY+3,infoBox.w-7,"right")
            UI.button(plusBox.x,plusBox.y,plusBox.w,plusBox.h,"+",level<def.max,f.small)
            self.sandboxSkillBoxes[#self.sandboxSkillBoxes + 1] = {id = def.id, minus = minusBox, plus = plusBox}
            rowY = rowY + rowH
        end
    end
    drawSkillGroup("직업 전용", jobSkills)
    drawSkillGroup("공용", sharedSkills)

    self.sandboxBranchBoxes={}
    if #branches>0 then
        love.graphics.setFont(f.small);love.graphics.setColor(1,.85,.5);love.graphics.print("무기 진화 / 전문화 · 조건 달성 후 택1",x+14,rowY+2);rowY=rowY+24
        for _,group in ipairs(branches)do
            local unlocked=self.clearcut:levelOf(group.skill)>=group.trigger
            love.graphics.setFont(f.micro or f.small);love.graphics.setColor(unlocked and {.88,.92,.82} or {.48,.54,.50})
            love.graphics.print((group.definition and group.definition.name or group.skill).."  Lv."..group.trigger,x+14,rowY+1)
            rowY=rowY+18
            local gap=4;local bw=(panelW-28-gap*(#group.choices-1))/#group.choices
            for i,branch in ipairs(group.choices)do
                local box={x=x+14+(i-1)*(bw+gap),y=rowY,w=bw,h=25}
                local selected=self.clearcut:skillBranch(group.skill)==branch.id
                love.graphics.setColor(selected and branch.color or (unlocked and {.10,.15,.13,.98} or {.055,.07,.065,.94}));love.graphics.rectangle("fill",box.x,box.y,box.w,box.h,3,3)
                love.graphics.setColor(branch.color[1],branch.color[2],branch.color[3],selected and 1 or (unlocked and .55 or .18));love.graphics.rectangle("line",box.x+.5,box.y+.5,box.w-1,box.h-1,3,3)
                love.graphics.setFont(f.micro or f.small);love.graphics.setColor(1,1,1,unlocked and 1 or .34);love.graphics.printf(branch.name,box.x,box.y+5,box.w,"center")
                self.sandboxBranchBoxes[#self.sandboxBranchBoxes+1]={skill=group.skill,id=branch.id,box=box,enabled=unlocked}
            end
            rowY=rowY+30
        end
    end

    self.sandboxFusionBoxes = {}
    if #fusions > 0 then
        love.graphics.setFont(f.small); love.graphics.setColor(1, .85, .5)
        love.graphics.print("융합 스킬 · 재료 무시하고 켜고 끄기", x + 14, rowY + 2)
        rowY = rowY + 20
        for _, def in ipairs(fusions) do
            local learned = self.clearcut.evolutions[def.id] == true
            local toggleBox = {x = x + 14, y = rowY, w = panelW - 28, h = 22}
            UI.button(toggleBox.x, toggleBox.y, toggleBox.w, toggleBox.h, def.name .. "  ·  " .. (learned and "배움" or "미보유"), true, f.small)
            self.sandboxFusionBoxes[#self.sandboxFusionBoxes + 1] = {id = def.id, box = toggleBox}
            rowY = rowY + rowH
        end
    end
    love.graphics.setScissor()

    if self.sandboxScrollMax>0 then
        local trackH=self.sandboxContentBox.h-8;local thumbH=math.max(28,trackH*self.sandboxContentBox.h/contentHeight)
        local thumbY=contentTop+4+(trackH-thumbH)*(self.sandboxPanelScroll/self.sandboxScrollMax)
        love.graphics.setColor(.24,.34,.29,.8);love.graphics.rectangle("fill",x+panelW-6,contentTop+4,2,trackH)
        love.graphics.setColor(.72,.84,.66,.9);love.graphics.rectangle("fill",x+panelW-7,thumbY,4,thumbH)
    end

    self.sandboxMobBox = {x = x + 14, y = y + panelH - 68, w = panelW - 28, h = 30}
    UI.button(self.sandboxMobBox.x, self.sandboxMobBox.y, self.sandboxMobBox.w, self.sandboxMobBox.h, "몹 소환", true, f.body)
    self.sandboxExitBox = {x = x + 14, y = y + panelH - 32, w = panelW - 28, h = 24}
    UI.button(self.sandboxExitBox.x, self.sandboxExitBox.y, self.sandboxExitBox.w, self.sandboxExitBox.h, "← 로비로 나가기", true, f.small)
end

function Game:sandboxPanelClick(x, y)
    local function inside(b)return b and x>=b.x and x<=b.x+b.w and y>=b.y and y<=b.y+b.h end
    if self.sandboxSkyviewBox and x>=self.sandboxSkyviewBox.x and x<=self.sandboxSkyviewBox.x+self.sandboxSkyviewBox.w and y>=self.sandboxSkyviewBox.y and y<=self.sandboxSkyviewBox.y+self.sandboxSkyviewBox.h then
        self.camera:setMode((self.camera.skyviewTarget or 0)>.5 and "default" or "skyview",.6)
        return true
    end
    if self.sandboxMobBox and x>=self.sandboxMobBox.x and x<=self.sandboxMobBox.x+self.sandboxMobBox.w and y>=self.sandboxMobBox.y and y<=self.sandboxMobBox.y+self.sandboxMobBox.h then
        self.clearcut:spawnWave({squirrel=3, boar=2}, self); return true
    end
    if self.sandboxExitBox and x>=self.sandboxExitBox.x and x<=self.sandboxExitBox.x+self.sandboxExitBox.w and y>=self.sandboxExitBox.y and y<=self.sandboxExitBox.y+self.sandboxExitBox.h then
        self:resetRun(); self.mode = "lobby"; return true
    end
    if inside(self.sandboxMaxBox)then self.clearcut:sandboxSetAllSkills(true);return true end
    if inside(self.sandboxResetBox)then self.clearcut:sandboxSetAllSkills(false);return true end
    if not inside(self.sandboxContentBox)then return inside(self.sandboxPanelBox) end
    for _, box in ipairs(self.sandboxSkillBoxes or {}) do
        local mb, pb = box.minus, box.plus
        if x>=mb.x and x<=mb.x+mb.w and y>=mb.y and y<=mb.y+mb.h then self.clearcut:sandboxSetLevel(box.id,-1,self);return true end
        if x>=pb.x and x<=pb.x+pb.w and y>=pb.y and y<=pb.y+pb.h then self.clearcut:sandboxSetLevel(box.id,1,self);return true end
    end
    for _,entry in ipairs(self.sandboxBranchBoxes or {})do if entry.enabled and inside(entry.box)then
        self.clearcut:sandboxSetBranch(entry.skill,entry.id);return true
    end end
    for _, box in ipairs(self.sandboxFusionBoxes or {}) do
        local b = box.box
        if x>=b.x and x<=b.x+b.w and y>=b.y and y<=b.y+b.h then self.clearcut:sandboxToggleFusion(box.id); return true end
    end
    return false
end

-- forced=true: 캐릭터를 처음 고른 직후 강제로 띄우는 도입부(끝까지 봐야 진행되고, 이때만
-- "이미 봤음"으로 기록된다). forced=false: 도감/다시보기처럼 그냥 열람하는 경우 — 아무 때나
-- 나갈 수 있고, 시청 기록에도 영향을 주지 않는다(아직 강제 노출 전인 캐릭터를 도감에서
-- 미리 봐도 나중에 실제로 고를 때 강제 노출이 그대로 뜬다).
-- returnMode: forced=false일 때 닫으면 돌아갈 화면(기본 "clearcut_select").
function Game:openCharacterStory(jobId, forced, returnMode)
    self.storyJob, self.storyPage, self.storyForced = jobId, 1, forced
    self.storyReturnMode = returnMode or "clearcut_select"
    self.mode = "character_story"
end

function Game:finishCharacterStory()
    local forced, job = self.storyForced, self.storyJob
    if job and forced then self.characterTraits:markStorySeen(job) end
    self.mode = forced and "clearcut_map_select" or (self.storyReturnMode or "clearcut_select")
    self.storyJob, self.storyForced, self.storyReturnMode = nil, false, nil
end

function Game:advanceStory()
    local pages = CharacterStory.pagesFor(self.storyJob)
    if self.storyPage < #pages then self.storyPage = self.storyPage + 1
    else self:finishCharacterStory() end
end

function Game:regressStory()
    if self.storyPage > 1 then self.storyPage = self.storyPage - 1 end
end

function Game:chooseClearcutMap(index)
    local def=require("src.clearcut_maps").catalog[index]
    if not def or not self.pendingClearcutCharacter then return end
    self.selectedClearcutMap=def.id
    self.selectedClearcutStage=math.max(1,math.min(require("src.biome_bosses").stageCap(def.id),self.selectedClearcutStage or 1))
    self.mode="clearcut_briefing"
end

function Game:drawClearcutBriefing()
    local Maps=require("src.clearcut_maps"); local def=Maps.get(self.selectedClearcutMap)
    local Bosses=require("src.biome_bosses");local cap=Bosses.stageCap(def.id)
    local w,h=love.graphics.getDimensions(); local f=self.fonts; local accent=def.color; local compact=h<620
    local character=ClearcutMode.characters[1]
    for _,c in ipairs(ClearcutMode.characters) do if c.id==self.pendingClearcutCharacter then character=c; break end end
    Frontend.backdrop(w,h,accent,1)
    love.graphics.setFont(f.micro); love.graphics.setColor(accent); love.graphics.print("작업 확인",34,24)
    love.graphics.setFont(f.title); love.graphics.setColor(.98,.96,.86); love.graphics.print("작업 내용 확인",34,51)
    love.graphics.setFont(f.small); love.graphics.setColor(.53,.62,.56); love.graphics.print("작업자와 구역을 확인합니다.",34,96)
    local x,y,pw,ph=34,132,w-68,h-210; Frontend.frame(x,y,pw,ph,accent,{selected=true})
    local leftW=pw*.42
    if not self.briefingPreview or self.briefingPreviewId~=(def.preview or def.id) then
        self.briefingPreviewId=def.preview or def.id; self.briefingPreview=love.graphics.newImage("assets/maps/"..self.briefingPreviewId.."-preview-v1.png"); self.briefingPreview:setFilter("nearest","nearest")
    end
    local img=self.briefingPreview; local iw,ih=img:getDimensions(); local bx,by,bw,bh=x+18,y+18,leftW-28,ph-36; local sc=math.max(bw/iw,bh/ih)
    love.graphics.setScissor(bx,by,bw,bh); love.graphics.setColor(1,1,1,1); love.graphics.draw(img,bx+bw/2,by+bh/2,0,sc,sc,iw/2,ih/2)
    for i=0,15 do local t=i/15; love.graphics.setColor(.008,.02,.016,t*.78); love.graphics.rectangle("fill",bx+bw-150+t*150,by,150/15+1,bh) end
    local selectedStage=math.max(1,math.min(cap,self.selectedClearcutStage or 1))
    local stageCode=Maps.stageCode(def.id,selectedStage)
    love.graphics.setScissor(); Frontend.badge(stageCode,bx+16,by+16,86,f.small,accent)
    local rx=x+leftW+18; Frontend.label("벌목 계약서  /  "..stageCode.."  /  총 "..cap.."구역",rx,y+24,f.micro,accent)
    love.graphics.setFont(f.big); love.graphics.setColor(.98,.96,.86); love.graphics.print(def.name,rx,y+57)
    love.graphics.setFont(f.body); love.graphics.setColor(.65,.73,.67); love.graphics.printf(def.subtitle.."\n"..def.desc.."\n최종 목표: "..Bosses.definitions[Bosses.forMap(def.id)].name.." 격파",rx,y+98,pw-leftW-50,"left")
    local dividerY=y+(compact and 150 or 176); love.graphics.setColor(1,1,1,.09); love.graphics.line(rx,dividerY,x+pw-24,dividerY)
    love.graphics.setFont(f.small); love.graphics.setColor(.47,.56,.50); love.graphics.print("배정 작업자",rx,dividerY+22); love.graphics.setFont(f.heading); love.graphics.setColor(character.color); love.graphics.print(character.name,rx,dividerY+46)
    love.graphics.setFont(f.small); love.graphics.setColor(.63,.70,.64); love.graphics.print(character.tagline,rx,dividerY+76)
    local steps={{"01","작업자 확인"},{"02","구역 확인"},{"03","시작 준비"}}
    local sy=y+ph-(compact and 62 or 112); for i,s in ipairs(steps) do local sx=rx+(i-1)*math.min(150,(pw-leftW-60)/3); love.graphics.setColor(accent[1],accent[2],accent[3],.18); love.graphics.circle("fill",sx+14,sy+14,14); love.graphics.setColor(accent); love.graphics.setFont(f.small); love.graphics.printf(s[1],sx,sy+7,28,"center"); love.graphics.setColor(.77,.79,.70); love.graphics.print(s[2],sx+36,sy+6) end
    self.clearcutBriefingBackBox={x=34,y=h-60,w=150,h=42}; self.clearcutBriefingStartBox={x=w-354,y=h-70,w=320,h=52}
    Frontend.button(self.clearcutBriefingBackBox,"← 구역 변경",f.small,{accent=Frontend.colors.teal}); Frontend.button(self.clearcutBriefingStartBox,"작업 시작",f.heading,{primary=true,key="ENT",align="left",accent=accent})
end

function Game:draw()
    if self.mode=="test_options" then self:drawTestOptions(); return end
    if self.mode == "lobby" then self.lobby:draw(); return end
    if self.mode == "achievements" then local w,h=love.graphics.getDimensions();self.lobby:drawBackground(w,h);self.achievementBoard:draw();return end
    if self.mode == "clearcut_select" then self:drawClearcutSelect(); return end
    if self.mode == "character_codex" then self:drawCharacterCodex(); return end
    if self.mode == "character_story" then self:drawCharacterStory(); return end
    if self.mode == "clearcut_map_select" then require("src.clearcut_map_select").draw(self); return end
    if self.mode == "clearcut_briefing" then self:drawClearcutBriefing(); return end
    if self.mode == "character_traits" then
        local w,h=love.graphics.getDimensions(); self.lobby:drawBackground(w,h); self.characterTraitBoard:draw(); return
    end
    if self.mode == "settings" then self:drawSettings(); return end
    if self.mode == "meta" then self.traitTree:draw(); return end
    if self.mode == "build_select" then self:drawBuildSelect(); return end
    local introActive=ClearcutIntro.active(self);local worldActors=self.clearcut;if introActive then worldActors=nil end
    love.graphics.clear(.08, .11, .12)
    local projected=self.clearcut and self.camera.perspective
    if projected then SkyView.draw(self.camera,self.world);NorthBackdrop.drawBack(self.camera,self.world) end
    local renderW,renderH
    if projected then renderW,renderH=WorldProjection.begin(self.camera) end
    self.world.deferBillboards=projected
    self.camera:attach(renderW,renderH,projected)
    if introActive then ClearcutIntro.drawWorldBack(self) end
    self.world:draw(self.player, worldActors)
    local left, top, right, bottom = self.camera:visibleBounds()
    if self.runType ~= "rush" and not self.clearcut then
        love.graphics.setBlendMode("screen", "alphamultiply"); love.graphics.setColor(.25, .34, .22, .13); love.graphics.rectangle("fill", left, top, right - left, bottom - top)
        local coreDx,coreDy=self.player.x-self.world.core.x,self.player.y-self.world.core.y
        local playerLight=coreDx*coreDx+coreDy*coreDy<400*400 and 1.45 or 2.2
        love.graphics.setBlendMode("add", "alphamultiply"); love.graphics.setColor(1, 1, 1, 1); love.graphics.draw(self.light, self.player.x, self.player.y, 0, playerLight, playerLight, 256, 256); love.graphics.draw(self.light, self.world.core.x, self.world.core.y, 0, 1.05, 1.05, 256, 256)
    end
    love.graphics.setBlendMode("alpha")
    local nearbyTurret = self:getNearbyTurret()
    self.nearTurret = nearbyTurret
    if nearbyTurret and self.mode == "playing" and self.runType~="rush" then
        local labelY = nearbyTurret.y - 116
        love.graphics.setColor(.02, .055, .06, .94); love.graphics.rectangle("fill", nearbyTurret.x - 54, labelY, 108, 30, 7, 7)
        love.graphics.setColor(1, .68, .18, 1); love.graphics.setLineWidth(2); love.graphics.rectangle("line", nearbyTurret.x - 54, labelY, 108, 30, 7, 7)
        love.graphics.setFont(self.fonts.small); love.graphics.setColor(1, 1, 1, 1); love.graphics.printf("[F] 강화", nearbyTurret.x - 54, labelY + 5, 108, "center")
    end
    if self.placingBuilding then
        local def = self.placingBuilding
        local wx, wy = self.camera:screenToWorld(love.mouse.getPosition())
        local isTurret = self.world:isTurretBuilding(def.id)
        local targetSlot = isTurret and self.world:turretSlotAt(wx, wy, true) or nil
        local valid = isTurret and targetSlot ~= nil or (not isTurret and self.world:canPlaceBuilding(wx, wy, def.footprint))
        if isTurret then
            for i = 1, self.world.turretSlotLimit do
                local slot = self.world.turretSlots[i]
                local available = not self.world:turretInSlot(i)
                love.graphics.setColor(available and {.2, 1, .38, .3} or {1, .18, .12, .3}); love.graphics.ellipse("fill", slot.x, slot.y, 63, 31)
                love.graphics.setColor(available and {.35, 1, .48, .95} or {1, .25, .18, .95}); love.graphics.setLineWidth(4); love.graphics.ellipse("line", slot.x, slot.y, 63, 31)
            end
        end
        local previewX, previewY = targetSlot and targetSlot.x or wx, targetSlot and targetSlot.y or wy
        love.graphics.setColor(valid and .4 or 1, valid and 1 or .3, valid and .5 or .3, .28)
        love.graphics.circle("fill", previewX, previewY, def.footprint / 2 + 8)
        love.graphics.setLineWidth(2); love.graphics.setColor(valid and .5 or 1, valid and 1 or .35, valid and .6 or .35, .8)
        love.graphics.circle("line", previewX, previewY, def.footprint / 2 + 8)
        local icon = self.world.buildingIcons[def.id]
        if icon then
            local scale = 78 / math.max(icon:getWidth(), icon:getHeight())
            love.graphics.setColor(1, 1, 1, valid and .9 or .5)
            love.graphics.draw(icon, previewX, previewY + 12, 0, scale, scale, icon:getWidth() / 2, icon:getHeight() * .91)
        end
    end
    if self.clearcut and not introActive then self.clearcut:drawWorldOverlay(self) end
    if introActive then ClearcutIntro.drawWorldFront(self) end
    self.camera:detach()
    if projected then
        WorldProjection.finish(self.camera)
        NorthBackdrop.drawRidge(self.camera,self.world)
        WorldProjection.drawBillboards(self.world.billboardQueue,self.camera)
        self.world.billboardQueue=nil
    end
    self.world.deferBillboards=false
    if introActive then ClearcutIntro.drawScreen(self) else self:drawUI() end
    if self.clearcut and self.clearcut.sandbox then self:drawSandboxPanel() end
    if self.mode == "upgrade" then self.upgrades:drawSelection(self, self.fonts) end
    if self.mode == "rush_upgrade" then self.rush:drawSelection(self,self.fonts) end
    if self.mode == "clearcut_upgrade" then self.clearcut:drawSelection(self,self.fonts) end
    if self.mode == "turret_upgrade" then self:drawTurretUpgrade() end
    if self.mode == "results" then self:drawResults() end
    if self.mode == "rush_results" then self.rush:drawResults(self,self.fonts) end
    if self.mode == "clearcut_results" then self.clearcut:drawResults(self,self.fonts) end
    if self.placingBuilding then
        local w = love.graphics.getWidth()
        local def, f = self.placingBuilding, self.fonts
        local cost = self:buildingCost(def)
        local parts = {}
        for res, amt in pairs(cost) do parts[#parts + 1] = resourceLabels[res] .. " " .. amt end
        UI.panel(w / 2 - 220, 16, 440, 40, {.35, 1, .62, 1}, .92)
        love.graphics.setFont(f.small); love.graphics.setColor(1, 1, 1)
        love.graphics.printf(def.name .. " 배치 중 · 비용 " .. table.concat(parts, " · ") .. " · 클릭 배치 / 우클릭·ESC 취소", w / 2 - 220, 27, 440, "center")
    end
    if self.paused then self:drawPauseOverlay() end
end

function Game:pauseButtons()
    local w, h = love.graphics.getDimensions()
    local pw, ph = math.min(560,w-40), math.min(390,h-40)
    local px, py = w / 2 - pw / 2, h / 2 - ph / 2
    local tiltBox={x=px+28,y=py+86,w=pw-56,h=92}
    return px, py, pw, ph,
        {x = px + 28, y = py + ph - 126, w = pw - 56, h = 48},
        {x = px + 28, y = py + ph - 66, w = pw - 56, h = 42},
        tiltBox
end

function Game:mousemoved(x,y,dx,dy)
    if self.paused and self.pauseTiltDragging then local _,_,_,_,_,_,tiltBox=self:pauseButtons();self:setViewTilt(Frontend.sliderValueAt(tiltBox,x));return end
    if self.mode=="settings" and self.settingsTiltDragging then self:setViewTilt(Frontend.sliderValueAt(self.settingsTiltBox,x));return end
    if self.mode=="clearcut_map_select" then require("src.clearcut_map_select").mousemoved(self,x,y,dx,dy) end
end

function Game:mousereleased(x,y,button)
    if button==1 then self.settingsTiltDragging=false;self.pauseTiltDragging=false end
    if self.mode=="clearcut_map_select" then
        local index=require("src.clearcut_map_select").mousereleased(self,x,y,button)
        if index then self.clearcutMapFocus=index;self:chooseClearcutMap(index) end
    end
end

function Game:drawAchievementOverlay()
    if ClearcutIntro.active(self) then return end
    self.achievementBoard:drawPopup()
end

function Game:drawPauseOverlay()
    local w, h, f = love.graphics.getWidth(), love.graphics.getHeight(), self.fonts
    love.graphics.setColor(0, 0, 0, .66); love.graphics.rectangle("fill", 0, 0, w, h)
    local px, py, pw, ph, resumeBox, quitBox, tiltBox = self:pauseButtons()
    Frontend.frame(px,py,pw,ph,Frontend.colors.amber,{selected=true})
    Frontend.label("일시정지 / 화면",px+28,py+20,f.micro,Frontend.colors.amber)
    love.graphics.setFont(f.heading); love.graphics.setColor(.98,.96,.86);love.graphics.print("작업 일시정지",px+28,py+44)
    Frontend.slider(tiltBox,self:viewTiltAmount(),f.body,"원근감", "평면  ↔  깊은 2.5D · 캐릭터와 스킬 비율은 유지",Frontend.colors.amber)
    love.graphics.setFont(f.small);love.graphics.setColor(.55,.64,.58)
    love.graphics.print("드래그 · 휠 · ← → 키로 즉시 조절",tiltBox.x,tiltBox.y+tiltBox.h+12)
    Frontend.button(resumeBox,"계속하기",f.body,{primary=true,key="ESC",accent=Frontend.colors.amber})
    Frontend.button(quitBox,"로비로 나가기",f.small,{accent=Frontend.colors.teal})
end

function Game:drawSettings()
    local w,h,f=love.graphics.getWidth(),love.graphics.getHeight(),self.fonts
    local compact=h<620
    self.lobby:drawBackground(w,h); love.graphics.setColor(.006,.018,.014,.89); love.graphics.rectangle("fill",0,0,w,h)
    love.graphics.setFont(f.micro); love.graphics.setColor(Frontend.colors.teal); love.graphics.print("설정",34,24)
    love.graphics.setFont(f.title); love.graphics.setColor(.98,.96,.87); love.graphics.print("환경 설정",34,51)
    love.graphics.setFont(f.small); love.graphics.setColor(.54,.62,.56); love.graphics.print("시각 피드백과 표시 환경을 현재 장비에 맞게 조정합니다",34,96)
    self.settingsBackBox={x=w-174,y=28,w=140,h=42}; Frontend.button(self.settingsBackBox,"지휘실로",f.small,{accent=Frontend.colors.teal,key="ESC"})
    local x,y,pw=math.max(34,w*.14),compact and 122 or 138,math.min(820,w*.72); local cx=x+(w-pw-2*x)/2
    x=cx; Frontend.frame(x,y,pw,h-198,Frontend.colors.teal,{selected=true})
    Frontend.label("화면",x+24,y+22,f.micro,Frontend.colors.teal)
    local rowH=compact and 54 or 66;local firstY=y+(compact and 48 or 54);local gap=compact and 10 or 12
    self.settingsShakeBox={x=x+24,y=firstY,w=pw-48,h=rowH}; Frontend.toggle(self.settingsShakeBox,self.settings.screenShake,f.body,"화면 흔들림",compact and nil or "타격·폭발·보스 등장 시 카메라 반동",Frontend.colors.amber)
    self.settingsFullscreenBox={x=x+24,y=firstY+rowH+gap,w=pw-48,h=rowH}; Frontend.toggle(self.settingsFullscreenBox,self.settings.fullscreen,f.body,"화면 모드",compact and nil or (self.settings.fullscreen and "전체 화면으로 실행 중" or "창 모드로 실행 중"),Frontend.colors.teal)
    local tiltY=firstY+(rowH+gap)*2;self.settingsTiltBox={x=x+24,y=tiltY,w=pw-48,h=compact and 70 or 82}
    Frontend.slider(self.settingsTiltBox,self:viewTiltAmount(),f.body,"시점 기울기",compact and "평면  ↔  깊은 원근" or "벌목 지역·연습장 지면의 깊이만 조절 · 캐릭터 비율 유지",Frontend.colors.amber)
    local devY=self.settingsTiltBox.y+self.settingsTiltBox.h+(compact and 12 or 20)
    Frontend.label("개발 도구",x+24,devY,f.micro,Frontend.colors.rust)
    self.settingsTestBox={x=x+24,y=devY+26,w=pw-48,h=compact and 42 or 54}; Frontend.button(self.settingsTestBox,"테스트 도구 열기  (F10)",f.body,{accent=Frontend.colors.rust,align="left"})
    Frontend.footer(w,h,"드래그 / 휠 / ← →  시점 조절    ·    F10  테스트 도구    ·    ESC  지휘실",f.small)
end

function Game:drawTestOptions()
    local w,h,f=love.graphics.getWidth(),love.graphics.getHeight(),self.fonts
    love.graphics.clear(.055,.11,.105)
    love.graphics.setColor(.12,.28,.23,.32); for x=0,w,48 do love.graphics.line(x,0,x,h) end; for y=0,h,48 do love.graphics.line(0,y,w,y) end
    UI.panel(w/2-360,84,720,640,{.42,1,.6,1},.98)
    love.graphics.setFont(f.title); love.graphics.setColor(1,1,1); love.graphics.printf("테스트 옵션",w/2-330,105,660,"center")
    love.graphics.setFont(f.small); love.graphics.setColor(.62,.78,.72); love.graphics.printf("개발 중인 특성·생산·방어 시스템을 빠르게 확인하는 메뉴",w/2-330,153,660,"center")
    love.graphics.setColor(1,.72,.25); love.graphics.printf("보유 유산 부품  "..self.progression.data.currency,w/2-330,181,660,"center")
    local bx=w/2-290
    UI.button(bx,220,580,58,"유산 부품 +1,000,000",true,f.heading)
    UI.button(bx,300,580,58,"런 자원 각 +1,000,000  (식량·광석·목재·돌)",true,f.body)
    local activeRun=self.testReturnMode=="playing" or self.testReturnMode=="upgrade" or self.testReturnMode=="rush_upgrade" or self.testReturnMode=="clearcut_upgrade"
    UI.button(bx,380,580,58,activeRun and "현재 런 레벨 +10  (강화 3택 테스트)" or "다음 런 시작 레벨 +20  (자동 선택)",true,f.body)
    UI.button(bx,460,580,58,"다음 런 시작 레벨 +20  (수동 선택 · 직접 3택)",true,f.body)
    UI.button(bx,540,580,58,self.testResetArmed and "정말 초기화 — 다시 클릭" or "영구 재화·특성 초기화",true,f.body)
    UI.button(bx,640,580,46,"돌아가기  [F10 / ESC]",true,f.body)
    love.graphics.setColor(self.testResetArmed and {1,.42,.25} or {.68,.82,.76}); love.graphics.printf(self.testMessage or "",w/2-315,615,630,"center")
end

function Game:drawResults()
    local w, h, f, r = love.graphics.getWidth(), love.graphics.getHeight(), self.fonts, self.result
    love.graphics.setColor(0, 0, 0, .84); love.graphics.rectangle("fill", 0, 0, w, h)
    local panelColor = (r and r.victory > 0) and {.35, .94, .55, 1} or (self.prestiged and {.95, .74, .22, 1} or {.95, .4, .24, 1})
    UI.panel(w / 2 - 310, h / 2 - 245, 620, 490, panelColor, .98)
    local title = self.victory and "작전 생존 성공" or (self.prestiged and "명예로운 철수" or "방어벽 붕괴")
    love.graphics.setFont(f.title); love.graphics.setColor(1, 1, 1); love.graphics.printf(title, w / 2 - 280, h / 2 - 214, 560, "center")
    love.graphics.setFont(f.small); love.graphics.setColor(.55, .67, .71); love.graphics.printf("회수 보고서 · 영구 재화 정산", w / 2 - 280, h / 2 - 166, 560, "center")
    local rows = {
        {"생존 시간", string.format("%02d:%02d", math.floor(r.elapsed / 60), r.elapsed % 60), r.survival},
        {"도달 웨이브", tostring(self.world.wave), r.waves}, {"처치", tostring(self.world.kills), r.kills},
        {"채집량", tostring(self.runStats.harvested), r.harvest}, {"15분 생존 보너스", self.victory and "달성" or "미달성", r.victory}
    }
    for i, row in ipairs(rows) do
        local y = h / 2 - 125 + (i - 1) * 42
        love.graphics.setColor(i % 2 == 0 and {.06, .085, .095, .8} or {.045, .065, .074, .8}); love.graphics.rectangle("fill", w / 2 - 260, y, 520, 35, 4, 4)
        love.graphics.setFont(f.small); love.graphics.setColor(.72, .8, .82); love.graphics.print(row[1], w / 2 - 242, y + 8)
        love.graphics.printf(row[2], w / 2 - 65, y + 8, 135, "right"); love.graphics.setColor(1, .7, .25); love.graphics.printf("+" .. row[3], w / 2 + 90, y + 8, 145, "right")
    end
    love.graphics.setFont(f.heading); love.graphics.setColor(1, .75, .25); love.graphics.printf("획득한 유산 부품  " .. r.earned, w / 2 - 260, h / 2 + 100, 520, "center")
    UI.button(w / 2 - 240, h / 2 + 174, 230, 50, "로비로  [ENTER]", true, f.body)
    UI.button(w / 2 + 10, h / 2 + 174, 230, 50, "특성 트리  [T]", true, f.body)
end

local function affordable(game, index)
    if index == 1 then return game.food >= 12 end
    if index == 2 then return game.ore >= 6 and game.world:firstAvailableTurretSlot() ~= nil end
    if index == 3 then return game.food >= 8 and game.ore >= 8 end
    if index == 5 then return true end
    local wall = game.world.wall
    if wall.level >= wall.maxLevel then return false end
    local cost = game.wallCosts[wall.level + 1]
    return game.wood >= cost.wood and game.stone >= cost.stone
end

function Game:drawMinimap(x, y, w, h)
    UI.panel(x, y, w, h, {.35, .74, .82, 1}, .9)
    love.graphics.setColor(.55, .24, .19); love.graphics.rectangle("fill", x + 12, y + 26, w - 24, 26)
    love.graphics.setColor(.94, .58, .14); love.graphics.rectangle("fill", x + 12, y + 53, w - 24, 3)
    love.graphics.setColor(.24, .5, .27); love.graphics.rectangle("fill", x + 12, y + 56, (w - 24) * .39, h - 68)
    love.graphics.setColor(.19, .39, .57); love.graphics.rectangle("fill", x + 12 + (w - 24) * .61, y + 56, (w - 24) * .39, h - 68)
    local function point(wx, wy, color, radius) love.graphics.setColor(color); love.graphics.circle("fill", x + 12 + wx / self.world.width * (w - 24), y + 26 + wy / self.world.height * (h - 38), radius) end
    point(self.world.core.x, self.world.core.y, {.98, .65, .18}, 4); point(self.player.x, self.player.y, {.35, .95, 1}, 4)
    for _, enemy in ipairs(self.world.enemies) do point(enemy.x, enemy.y, {.95, .2, .18}, 2) end
    love.graphics.setFont(self.fonts.small); love.graphics.setColor(.8, .86, .88); love.graphics.print("작전 지도", x + 12, y + 5)
end

function Game:drawToolBelt(x, y, w, h)
    UI.panel(x, y, w, h, {.92, .58, .16, 1}, .94)
    love.graphics.setFont(self.fonts.small); love.graphics.setColor(.57, .68, .71); love.graphics.print("기본 도구 · 대상 클릭 시 자동 사용", x + 14, y + 9)
    local order = {"axe", "hoe", "pickaxe", "hammer"}
    for i, key in ipairs(order) do
        local tool, rowY, active = self.tools[key], y + 35 + (i - 1) * 28, self.player.activeTool == key
        love.graphics.setColor(active and {.95, .62, .18, .95} or {.1, .14, .16, .9}); love.graphics.rectangle("fill", x + 12, rowY, w - 24, 23, 4, 4)
        love.graphics.setColor(active and {.08, .08, .07} or {.83, .88, .89}); love.graphics.print(tool.name, x + 22, rowY + 2)
        love.graphics.printf(string.format("속도 %.2fx", tool.speed * self.player.gather), x + 95, rowY + 2, w - 120, "right")
    end
end

function Game:drawUI()
    local w, h, f = love.graphics.getWidth(), love.graphics.getHeight(), self.fonts
    if self.runType=="rush" then self.rush:drawHUD(self,f); return end
    if self.runType=="clearcut" then self.clearcut:drawHUD(self,f); return end
    UI.panel(16, 16, 382, 142, {.25, .78, .88, 1})
    local m, s = math.floor(self.time / 60), math.floor(self.time % 60)
    love.graphics.setFont(f.big); love.graphics.setColor(1, 1, 1); love.graphics.print(string.format("%02d:%02d", m, s), 32, 27)
    love.graphics.setFont(f.body); love.graphics.setColor(.76, .84, .87); love.graphics.print(string.format("웨이브 %02d   처치 %03d", self.world.wave, self.world.kills), 152, 35)
    love.graphics.setFont(f.small); love.graphics.setColor(.4, .95, .62); love.graphics.print("보급 센터  가동 중", 32, 72)
    local wall = self.world.wall
    love.graphics.setColor(.76, .84, .87); love.graphics.print(string.format("방어벽 %d단계  %d / %d", wall.level, math.floor(wall.hp), wall.maxHp), 32, 98)
    UI.bar(32, 122, 348, 12, wall.hp / wall.maxHp, wall.level == 4 and {.18, .86, 1, 1} or {.94, .58, .14, 1})

    local hx, hy, hw = w - 334, 16, 318
    UI.panel(hx, hy, hw, 150, {.92, .58, .16, 1})
    love.graphics.setFont(f.small); love.graphics.setColor(.58, .68, .71); love.graphics.print("거점 창고", hx + 16, hy + 10)
    local resources = {
        {img = self.world.images.crop, label = "식량", color = {.45, .95, .48}, value = self.food},
        {img = self.world.images.ore, label = "광석", color = {.35, .78, 1}, value = self.ore},
        {img = self.world.images.lumber, label = "목재", color = {.9, .68, .35}, value = self.wood},
        {img = self.world.images.stone, label = "돌", color = {.75, .78, .8}, value = self.stone},
        {img = nil, label = "씨앗", color = {.95, .78, .25}, value = self.seeds}
    }
    local chipW, chipH, gap, chipX0, chipY = 53, 58, 6, hx + 14, hy + 32
    for i, res in ipairs(resources) do
        local cx = chipX0 + (i - 1) * (chipW + gap)
        love.graphics.setColor(.08, .11, .13, .9); love.graphics.rectangle("fill", cx, chipY, chipW, chipH, 6, 6)
        love.graphics.setColor(1, 1, 1, .1); love.graphics.setLineWidth(1); love.graphics.rectangle("line", cx, chipY, chipW, chipH, 6, 6)
        love.graphics.setColor(1, 1, 1, 1)
        if res.img then
            local scale = 30 / math.max(res.img:getWidth(), res.img:getHeight())
            love.graphics.draw(res.img, cx + chipW / 2, chipY + 21, 0, scale, scale, res.img:getWidth() / 2, res.img:getHeight() / 2)
        else
            love.graphics.setColor(res.color)
            for d = -1, 1 do love.graphics.circle("fill", cx + chipW / 2 + d * 7, chipY + 21, 3) end
        end
        love.graphics.setFont(f.small); love.graphics.setColor(res.color)
        love.graphics.printf(tostring(res.value), cx, chipY + chipH - 20, chipW, "center")
    end
    local barY = chipY + chipH + 12
    love.graphics.setFont(f.small); love.graphics.setColor(.78, .84, .86)
    love.graphics.print(string.format("가방  %d / %d", self.player:totalCargo(), self.player.capacity), hx + 14, barY)
    UI.bar(hx + 14, barY + 20, hw - 28, 10, self.player:totalCargo() / self.player.capacity, {.96, .64, .18, 1})

    UI.panel(w / 2 - 105, 16, 210, 44, {.78, .2, .18, 1}, .86)
    love.graphics.setFont(f.body); love.graphics.setColor(1, .82, .72); love.graphics.printf(self.world.spawnTimer > 0 and string.format("다음 웨이브 %.1f초", self.world.spawnTimer) or "웨이브 접근 중", w / 2 - 105, 27, 210, "center")
    love.graphics.setFont(f.small); love.graphics.setColor(.08, .12, .12, .9); love.graphics.rectangle("fill", w / 2 - 105, 64, 210, 50, 5, 5)
    love.graphics.setColor(.52, 1, .63); love.graphics.printf(string.format("생산 레벨 %d", self.runLevel), w / 2 - 105, 74, 210, "center")
    local droneCount=0; for _,defender in ipairs(self.world.defenders) do if defender.kind=="drone" then droneCount=droneCount+1 end end
    local turretCount = self.world:turretBuildingCount()
    love.graphics.setColor(.55,.82,.86); love.graphics.printf(string.format("포대 %d/%d   전투 드론 %d",turretCount,self.world.turretSlotLimit,droneCount),w/2-105,96,210,"center")
    UI.button(w / 2 - 105, 118, 210, 32, "[P] 조기 철수 — 재화 정산", true, f.small)

    self:drawMinimap(16, h - 158, 205, 142); self:drawToolBelt(w - 276, h - 158, 260, 142)
    local nextWall = wall.level < wall.maxLevel and self.wallCosts[wall.level + 1] or nil
    local wallCostText = nextWall and string.format("목%d 돌%d", nextWall.wood, nextWall.stone) or "최고 단계"
    local abilities = {{"1", "수호자", "식량 12"}, {"2", "포탑", "광석 6"}, {"3", "장비", "식8 광8"}, {"4", "방벽강화", wallCostText}, {"5", "건설", "건물 배치"}}
    local total, slotW, gap, startX, barY = 692, 132, 8, w / 2 - 346, h - 92
    for i, ability in ipairs(abilities) do
        local x, ready = startX + (i - 1) * (slotW + gap), affordable(self, i)
        UI.panel(x, barY, slotW, 70, ready and {.92, .58, .16, 1} or {.25, .3, .32, 1}, .94)
        love.graphics.setFont(f.heading); love.graphics.setColor(ready and 1 or .48, ready and .7 or .53, ready and .25 or .55); love.graphics.print("[" .. ability[1] .. "]", x + 10, barY + 9)
        love.graphics.setFont(f.body); love.graphics.setColor(ready and 1 or .5, ready and 1 or .54, ready and 1 or .56); love.graphics.print(ability[2], x + 48, barY + 11)
        love.graphics.setFont(f.small); love.graphics.setColor(.56, .68, .71); love.graphics.print(ability[3], x + 48, barY + 39)
    end

    local promptNode = self.player.interactionTarget or self.hoverNode
    local promptTurret = self:getNearbyTurret() or (self.hoverBuilding and self.world:isTurretBuilding(self.hoverBuilding.kind) and self.hoverBuilding or nil)
    if promptTurret then
        local level = promptTurret.level or 0
        local maxed = level >= self.world:turretMaxLevel()
        local cost = self.world:turretUpgradeCost(promptTurret)
        local inRange = promptTurret == self.nearTurret
        local text
        if not inRange then text = "포탑에 더 가까이 가세요"
        elseif maxed then text = string.format("[F] 포탑 최고 단계 · Lv.%d", level)
        else text = string.format("[F] 포탑 강화 · 광석 %d · Lv.%d", cost, level) end
        UI.button(w / 2 - 210, h - 146, 420, 44, text, inRange and not maxed and self.ore >= cost, f.body)
    elseif self.player.repairingWall or self.hoverWall then
        local distance = math.abs(self.player.y - self.world.wall.y)
        local text = self.player.repairingWall and "나무 수리 망치 사용 중 · 타격당 목재 1 + 돌 1" or (distance <= 185 and "클릭 — 방어벽 직접 수리" or "방어벽에 더 가까이 이동하세요")
        UI.panel(w / 2 - 200, h - 142, 400, 40, {.95, .62, .18, 1}, .9)
        love.graphics.setFont(f.small); love.graphics.setColor(1, 1, 1); love.graphics.printf(text, w / 2 - 200, h - 132, 400, "center")
    elseif promptNode then
        local tool, label = self.world:getInteraction(promptNode, self)
        local distance = math.sqrt((promptNode.x - self.player.x)^2 + (promptNode.y - self.player.y)^2)
        local text = self.player.interactionTarget and ((self.tools[self.player.activeTool] and self.tools[self.player.activeTool].name or "도구") .. " 사용 중") or (distance <= 180 and ("클릭 — " .. (label or "상호작용")) or "더 가까이 이동하세요")
        UI.panel(w / 2 - 170, h - 142, 340, 40, {.32, .83, .9, 1}, .9)
        love.graphics.setFont(f.small); love.graphics.setColor(1, 1, 1); love.graphics.printf(text, w / 2 - 170, h - 132, 340, "center")
    end

    if self.noticeTime > 0 then
        local color = self.noticeKind == "food" and {.36, .95, .44, 1} or self.noticeKind == "ore" and {.36, .78, 1, 1} or {1, .68, .2, 1}
        love.graphics.setFont(f.body); love.graphics.setColor(0, 0, 0, .7); love.graphics.printf(self.notice, 2, 177, w, "center"); love.graphics.setColor(color); love.graphics.printf(self.notice, 0, 175, w, "center")
    end

    local xpRatio = math.max(0, math.min(1, self.runXPVisual / self.runXPNext))
    love.graphics.setColor(.025, .07, .08, .96); love.graphics.rectangle("fill", 0, h - 7, w, 7)
    love.graphics.setColor(.3, .92, .58, 1); love.graphics.rectangle("fill", 0, h - 6, w * xpRatio, 6)
    love.graphics.setColor(.74, 1, .66, .8); love.graphics.rectangle("fill", 0, h - 6, w * xpRatio, 2)
    if self.runXPPulse > 0 then
        local headX = w * xpRatio
        love.graphics.setBlendMode("add", "alphamultiply")
        love.graphics.setColor(.45, 1, .67, self.runXPPulse); love.graphics.circle("fill", headX, h - 4, 10 + 8 * self.runXPPulse)
        love.graphics.setBlendMode("alpha")
        love.graphics.setFont(f.small); love.graphics.setColor(.78, 1, .72, self.runXPPulse)
        love.graphics.printf("+" .. math.floor(self.lastXPGain) .. " XP", math.max(4, math.min(w - 72, headX - 34)), h - 28, 68, "center")
    end
    love.graphics.setFont(f.small); love.graphics.setColor(.9, 1, .92, .88)
    love.graphics.printf(string.format("생산 Lv.%d   %d / %d", self.runLevel, math.floor(self.runXP), self.runXPNext), w / 2 - 100, h - 27, 200, "center")
end

return Game
