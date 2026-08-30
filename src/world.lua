local World = {}
local ForestScenery = require("src.forest_scenery")
local ForestUnderstory = require("src.forest_understory")
local BiomeVines = require("src.biome_vines")
local ForestFloor = require("src.forest_floor")
local ForestLighting = require("src.forest_lighting")
local TreeDestruction = require("src.tree_destruction")
local RegrowthCastArt = require("src.regrowth_cast_art")
local ClearcutMaps = require("src.clearcut_maps")
World.__index = World

local buildingDefs = require("src.buildings")
local buildingById = {}
for _, def in ipairs(buildingDefs) do buildingById[def.id] = def end

local function isTurretDef(def)
    if not def or not def.tags then return false end
    for _, tag in ipairs(def.tags) do if tag == "포탑" then return true end end
    return false
end

local turretMods = {
    {id="multishot", name="다중 조준", desc="한 번에 공격하는 대상 수가 늘어납니다.", color={1,.55,.2,1}},
    {id="double_tap", name="이중 발사", desc="공격 사이클마다 한 번 더 발사합니다.", color={.35,.85,1,1}},
    {id="heavy_shell", name="폭발 탄두", desc="명중 지점이 폭발해 주변 적에게도 피해를 줍니다.", color={1,.3,.3,1}},
    {id="rapid_coil", name="연쇄 코일", desc="공격 속도가 빨라지고 전격이 가까운 적에게 연쇄됩니다.", color={.28,.78,1,1}},
    {id="long_barrel", name="확장 포신", desc="사거리가 늘어납니다.", color={.55,1,.6,1}}
}
local turretMaxLevel = 8

local function atan2(y, x)
    if math.atan2 then return math.atan2(y, x) end
    if x > 0 then return math.atan(y / x) end
    if x < 0 then return math.atan(y / x) + (y >= 0 and math.pi or -math.pi) end
    return y >= 0 and math.pi / 2 or -math.pi / 2
end

local function angleDelta(target, current)
    return (target - current + math.pi) % (math.pi * 2) - math.pi
end

local function image(path)
    local value = love.graphics.newImage(path)
    value:setFilter("linear", "linear", 4)
    return value
end

local function resource(kind, x, y, workTime)
    return {kind = kind, x = x, y = y, work = 0, workTime = workTime, active = true, respawn = 0}
end

local function plot(x, y)
    return {kind = "plot", x = x, y = y, state = "empty", grow = 0, growMax = 12, active = true}
end

local function cargoSpace(player) return player.capacity - player:totalCargo() end
local function activeChopper(game) return game.rush or game.clearcut end

function World.new()
    local self = setmetatable({}, World)
    self.width, self.height = 3200, 2000
    self.core = {x = 1600, y = 1325, hp = 500, maxHp = 500, damage = 18, fireRate = 1.25, range = 510, cooldown = 0}
    self.wall = {y = 1115, level = 1, maxLevel = 4, hp = 220, maxHp = 220, brokenNotified = false}
    self.turretSlotLimit = 1
    self.turretSlots = {
        {index = 1, x = self.core.x + 300, y = self.wall.y + 82},
        {index = 2, x = self.core.x - 300, y = self.wall.y + 82},
        {index = 3, x = self.core.x, y = self.wall.y + 82}
    }
    self.images = {
        industrial = image("assets/floor-industrial.png"), farm = image("assets/floor-biofarm.png"), quarry = image("assets/floor-quarry.png"),
        forestGround = image("assets/forest-ground-tile-v1.png"),
        core = image("assets/supply-core-v2.png"), turret = image("assets/turret-v1.png"), drone = image("assets/combat-drone-v1.png"), crop = image("assets/crop-pod.png"), ore = image("assets/ore-node.png"),
        tree = image("assets/tree-v1.png"), stone = image("assets/stone-v1.png"), lumber = image("assets/lumber-drop-v1.png"),
        workerWalk = image("assets/worker-walk-v3.png"), workerActions = image("assets/worker-actions-v1.png"), workerRepair = image("assets/worker-repair-v1.png"),
        turretBase = image("assets/turret-base-v1.png"), turretHead = image("assets/turret-head-v2.png"),
        muzzleFlash = image("assets/muzzle-flash-v1.png")
    }
    self.images.treeBreakBurst = image("assets/fx/tree-break-burst-v1.png")
    self.images.treeBreakBurst:setFilter("nearest","nearest")
    self.images.treeVariants = {
        image("assets/trees/broadleaf-tree-pixel-v2.png"),
        image("assets/trees/pine-tree-pixel-v2.png"),
        image("assets/trees/birch-tree-pixel-v2.png"),
        image("assets/trees/maple-tree-pixel-v2.png")
    }
    self.buildingIcons = {}
    for _, def in ipairs(buildingDefs) do self.buildingIcons[def.id] = image(def.icon or ("assets/upgrades/" .. def.id .. ".png")) end
    self.nodes, self.enemies, self.defenders, self.turrets, self.buildings, self.shots, self.drops, self.helpers = {}, {}, {}, {}, {}, {}, {}, {}
    self.bullets, self.muzzleFlashes, self.impactFlashes, self.chainArcs, self.explosions = {}, {}, {}, {}, {}
    self.particles, self.popups, self.treeBreakFx, self.harvestChain, self.harvestChainTime = {}, {}, {}, 0, 0
    self.effectFont = love.graphics.newFont("assets/font-korean-bold.ttf", 18)
    self.quarryVisual = {shadowX = 5, shadowY = 7, shadowRx = 104, shadowRy = 11, shadowAlpha = .22, frontBias = 130}
    self.treeVisual = {
        scale = .28, shadowX = 4, shadowY = 9, shadowRx = 92, shadowRy = 12, shadowAlpha = .22, frontBias = 120,
        variantScale = {1, .92, .88, .92},
        variantShadow = {1, .7, .78, 1}
    }
    self.spawnTimer, self.wave, self.kills = 3, 0, 0
    self:build()
    return self
end

local effectColors = {
    tree = {.86, .55, .2}, wood = {.76, .48, .2}, stone = {.78, .84, .88}, ore = {.25, .82, 1}, quarry = {.65, .78, .86}, plot = {.42, 1, .45}, food = {.45, .95, .48}
}

local function effectOrigin(node)
    if node.rushTree then return node.x, node.y - 92 end
    if node.kind == "tree" then return node.x, node.y - 145 end
    if node.kind == "quarry" then return node.x, node.y - 105 end
    if node.kind == "plot" then return node.x, node.y - 18 end
    return node.x, node.y - 28
end

function World:addParticle(x, y, color, strong, pickup)
    local angle = -math.pi * (.16 + love.math.random() * .68)
    local speed = (strong and 155 or 90) + love.math.random() * (strong and 145 or 75)
    self.particles[#self.particles + 1] = {
        x = x, y = y, vx = math.cos(angle) * speed, vy = math.sin(angle) * speed,
        life = pickup and .72 or (strong and .62 or .38), maxLife = pickup and .72 or (strong and .62 or .38),
        size = pickup and (5 + love.math.random() * 4) or (2 + love.math.random() * (strong and 5 or 3)),
        color = color, pickup = pickup
    }
end

function World:addLeafParticle(x, y)
    local angle = -math.pi * (.2 + love.math.random() * .6)
    local speed = 55 + love.math.random() * 85
    local mix = love.math.random()
    local life = .85 + love.math.random() * .55
    self.particles[#self.particles + 1] = {
        x = x, y = y, vx = math.cos(angle) * speed, vy = math.sin(angle) * speed,
        life = life, maxLife = life, size = 3.5 + love.math.random() * 3,
        color = {.32 + mix * .3, .58 + mix * .22, .16 + mix * .12},
        leaf = true, wobbleSeed = love.math.random() * 10, wobbleFreq = 2.6 + love.math.random() * 3
    }
end

function World:spawnFallImpact(node, game)
    local gx, gy = node.x, node.y + 6
    local giant=node.giantTree
    local dustCount=giant and 26 or 12
    local reach=giant and (node.fallReach or 238)*.82 or 0
    for i = 1, dustCount do
        local a = love.math.random() * math.pi * 2
        local speed = 14 + love.math.random() * 34
        local along=giant and ((i-1)/(dustCount-1))*reach or 0
        local life = (giant and .78 or .6) + love.math.random() * (giant and .58 or .4)
        self.particles[#self.particles + 1] = {
            x = gx+(node.fallDir or 1)*along+(love.math.random()*2-1)*(giant and 18 or 0),
            y = gy+(love.math.random()*2-1)*(giant and 8 or 0),
            vx = math.cos(a) * speed+(giant and (node.fallDir or 1)*12 or 0), vy = math.sin(a) * speed * .3 - 16,
            life = life, maxLife = life, size = (giant and 7 or 7) + love.math.random() * (giant and 10 or 9),
            color = giant and {.36,.31,.22} or {.42,.36,.26}, dust = true,
            dustStretch=giant and (1.25+love.math.random()*.65) or 1
        }
    end
    if giant then
        for i=1,18 do
            self:addLeafParticle(gx+(node.fallDir or 1)*(reach*.45+love.math.random()*reach*.55),gy-18-love.math.random()*36)
        end
    end
    if game.camera then game.camera.trauma = math.min(1, game.camera.trauma + (giant and .68 or .22)) end
    local profile=TreeDestruction.fallProfile(node.rushMaxHp,node.giantTree)
    self.treeBreakFx[#self.treeBreakFx+1]={x=node.x+(node.fallDir or 1)*(node.fallReach or profile.reach)*.58,y=node.y-18,life=.32,maxLife=.32,scale=profile.breakScale}
    if giant then
        for _,ratio in ipairs({.22,.48,.78}) do
            self.treeBreakFx[#self.treeBreakFx+1]={x=node.x+(node.fallDir or 1)*profile.reach*ratio,y=node.y-12,life=.46,maxLife=.46,scale=.32+ratio*.24}
        end
    end
    local chopper = activeChopper(game)
    if chopper and chopper.onTreeFallen then chopper:onTreeFallen(node, game) end
end

function World:igniteFx(x, y, big)
    self.impactFlashes[#self.impactFlashes + 1] = {x = x, y = y, life = big and .4 or .22, maxLife = big and .4 or .22}
    for _ = 1, big and 20 or 8 do
        local a = love.math.random() * math.pi * 2
        local speed = 40 + love.math.random() * (big and 160 or 90)
        local life = .4 + love.math.random() * .4
        self.particles[#self.particles + 1] = {
            x = x, y = y, vx = math.cos(a) * speed, vy = math.sin(a) * speed - 30,
            life = life, maxLife = life, size = 3 + love.math.random() * 4, color = {1, .5 + love.math.random() * .3, .1}, ember = true
        }
    end
    if big then self.explosions[#self.explosions + 1] = {x = x, y = y, life = .5, maxLife = .5, radius = 110} end
end

function World:toxicPulseFx(x, y, radius)
    self.particles[#self.particles + 1] = {x = x, y = y, life = .5, maxLife = .5, size = radius * .3, color = {.55, .85, .35}, ring = true}
    self.particles[#self.particles + 1] = {x = x, y = y, life = .65, maxLife = .65, size = radius * .55, color = {.4, .7, .28}, ring = true}
    for _ = 1, 16 do
        local a = love.math.random() * math.pi * 2
        local r = love.math.random() * radius
        local life = .6 + love.math.random() * .5
        self.particles[#self.particles + 1] = {
            x = x + math.cos(a) * r, y = y + math.sin(a) * r * .5,
            vx = math.cos(a) * 6, vy = -14 - love.math.random() * 14,
            life = life, maxLife = life, size = 3 + love.math.random() * 4,
            color = {.45 + love.math.random() * .2, .8, .3}, dust = true
        }
    end
end

function World:impactNode(node, game, strong)
    if not node or node.kind == "plot" or (not node.active and not strong) then return end
    local x, y = effectOrigin(node)
    local color = effectColors[node.kind]
    node.hitFlash, node.hitShake = strong and .2 or .12, strong and .24 or .14
    if node.rushTree and node.rushMaxHp and node.rushMaxHp>0 then
        node.damageStage=TreeDestruction.damageStage(node.rushHp,node.rushMaxHp)
        ForestUnderstory.cutRadius(self,node.x,node.y,strong and 92 or 64,game)
        BiomeVines.cutRadius(self,node.x,node.y,strong and 92 or 64,game)
    end
    for _ = 1, strong and 15 or 6 do self:addParticle(x, y, color, strong, false) end
    self.particles[#self.particles + 1] = {x = x, y = y, life = .2, maxLife = .2, size = 12, color = color, ring = true}
    if node.kind == "tree" and game.player then
        local dir = (node.x - game.player.x) >= 0 and 1 or -1
        node.swayVel = (node.swayVel or 0) + dir * (strong and 3.4 or 1.7)
        for _ = 1, strong and 10 or 4 do self:addLeafParticle(x, y) end
    end
    if game.camera then game.camera.trauma = math.min(1, game.camera.trauma + (strong and .36 or .12)) end
    if game.feedback then game.feedback:play(node.kind, strong) end
end

-- Electronic-cigarette pressure bends the billboard around its rooted base
-- without borrowing the ordinary hit shake, generic debris or camera trauma.
function World:windImpactNode(node,dirX,dirY,power)
    if not node or not node.rushTree or not node.active then return end
    power=math.max(.15,math.min(1,power or 0))
    node.hitFlash=math.max(node.hitFlash or 0,.055+.045*power)
    if node.rushMaxHp and node.rushMaxHp>0 then node.damageStage=TreeDestruction.damageStage(node.rushHp,node.rushMaxHp)end
    local visualDir=math.abs(dirX or 0)>.16 and (dirX<0 and -1 or 1)or ((dirY or 0)<0 and -1 or 1)
    node.swayAngle=math.max(-.5,math.min(.5,(node.swayAngle or 0)+visualDir*(.035+.19*power)))
    node.swayVel=(node.swayVel or 0)+visualDir*(2.6+7.4*power)
end

function World:harvestBurst(node, game, amount, label)
    local x, y = effectOrigin(node)
    local color = effectColors[node.kind] or effectColors.plot
    self:impactNode(node, game, true)
    if node.kind == "plot" then
        node.hitFlash, node.hitShake = .2, .2
        for _ = 1, 15 do self:addParticle(x, y, color, true, false) end
        if game.feedback then game.feedback:play("harvest", true) end
        if game.camera then game.camera.trauma = math.min(1, game.camera.trauma + .2) end
    end
    for _ = 1, math.min(12, amount + 3) do self:addParticle(x, y, color, true, true) end
    self.harvestChain = self.harvestChainTime > 0 and math.min(99, self.harvestChain + 1) or 1
    self.harvestChainTime = 2.4
    self.popups[#self.popups + 1] = {x = x, y = y - 78, life = 1.05, maxLife = 1.05, text = "+" .. amount .. " " .. label, color = color, chain = self.harvestChain}
    if node.rushTree then
        local sway = node.swayAngle or 0
        local profile=TreeDestruction.fallProfile(node.rushMaxHp,node.giantTree)
        node.fallT, node.fallDur, node.fallReach = 0, profile.duration, profile.reach
        node.fallDir = sway > 0 and 1 or sway < 0 and -1 or (love.math.random() < .5 and 1 or -1)
        for _ = 1, 10 do self:addLeafParticle(x, y) end
        if node.giantTree and game.feedback then game.feedback:play("creak",true) end
    end
end

function World:updateEffects(dt, game)
    self.harvestChainTime = math.max(0, self.harvestChainTime - dt)
    for _, node in ipairs(self.nodes) do
        if node.treeEmergence then
            node.treeEmergence.t=node.treeEmergence.t+dt
            if node.treeEmergence.t>=node.treeEmergence.duration then node.treeEmergence=nil end
        end
        node.hitFlash = math.max(0, (node.hitFlash or 0) - dt)
        node.hitShake = math.max(0, (node.hitShake or 0) - dt)
        if node.kind == "tree" then
            local vel = (node.swayVel or 0) + (-(node.swayAngle or 0) * 46 - (node.swayVel or 0) * 7.5) * dt
            node.swayVel = vel
            node.swayAngle = math.max(-.5, math.min(.5, (node.swayAngle or 0) + vel * dt))
            if node.burning and love.math.random() < dt * 7 then
                local life = .6 + love.math.random() * .4
                self.particles[#self.particles + 1] = {
                    x = node.x + (love.math.random() * 2 - 1) * 14, y = node.y - 30,
                    vx = (love.math.random() * 2 - 1) * 12, vy = -40 - love.math.random() * 30,
                    life = life, maxLife = life, size = 2.4 + love.math.random() * 2.4, color = {1, .55 + love.math.random() * .3, .1}, ember = true
                }
            end
        end
        if node.fallT and node.fallT < node.fallDur then
            local before = node.fallT
            node.fallT = math.min(node.fallDur, node.fallT + dt)
            if node.fallT >= node.fallDur and before < node.fallDur then self:spawnFallImpact(node, game) end
        end
    end
    for i = #self.particles, 1, -1 do
        local p = self.particles[i]
        p.life = p.life - dt
        if p.pickup and game.player then
            local dx, dy = game.player.x - p.x, game.player.y - 25 - p.y
            p.vx, p.vy = p.vx + dx * dt * 12, p.vy + dy * dt * 12
        elseif p.leaf then
            p.vy = p.vy + 70 * dt
            p.vx = p.vx * math.exp(-dt * 1.2)
        elseif p.dust then
            p.vx, p.vy = p.vx * math.exp(-dt * 2.4), p.vy * math.exp(-dt * 2.4) - 4 * dt
        elseif not p.ring then p.vy = p.vy + 390 * dt end
        if p.leaf then
            p.x = p.x + (p.vx + math.sin(love.timer.getTime() * p.wobbleFreq + p.wobbleSeed) * 46) * dt
            p.y = p.y + p.vy * dt
        elseif not p.ring then
            p.x, p.y = p.x + p.vx * dt, p.y + p.vy * dt
        end
        if p.life <= 0 then table.remove(self.particles, i) end
    end
    for i=#self.treeBreakFx,1,-1 do
        local fx=self.treeBreakFx[i];fx.life=fx.life-dt
        if fx.life<=0 then table.remove(self.treeBreakFx,i) end
    end
    for i = #self.popups, 1, -1 do
        local popup = self.popups[i]
        popup.life, popup.y = popup.life - dt, popup.y - 28 * dt
        if popup.life <= 0 then table.remove(self.popups, i) end
    end
end

function World:spawnDrop(kind, amount, x, y, spreadX, spreadY, power)
    spreadX, spreadY, power = spreadX or 24, spreadY or 0, math.min(power or 1, 2.4)
    for _ = 1, amount do
        local minVx, maxVx = kind == "wood" and 25 or -125, kind == "wood" and 125 or 35
        self.drops[#self.drops + 1] = {
            kind = kind, amount = 1,
            x = x + love.math.random(-spreadX, spreadX), y = y - 34 + love.math.random(-spreadY, spreadY),
            vx = love.math.random(minVx, maxVx) * power, vy = love.math.random(28, 82) * power,
            height = love.math.random(36, 58) * power, vz = love.math.random(85, 135) * power,
            magnet = false
        }
    end
end

function World:updateDrops(dt, game)
    local player = game.player
    local chopper = activeChopper(game)
    local pickupRadius = chopper and chopper:pickupRadius() or 80
    local pickupSpeed = chopper and chopper:pickupSpeed() or 12
    for i = #self.drops, 1, -1 do
        local drop = self.drops[i]
        local dx, dy = player.x - drop.x, player.y - drop.y
        local distance = math.sqrt(dx * dx + dy * dy)
        if drop.height <= (chopper and 18 or 0) and distance <= pickupRadius and cargoSpace(player) > 0 then drop.magnet = true end
        local pulling=drop.magnet
        if pulling and (drop.magnetDelay or 0)>0 then
            drop.magnetDelay=math.max(0,drop.magnetDelay-dt)
            pulling=false
        end
        if pulling then
            drop.magnetPullAge=(drop.magnetPullAge or 0)+dt
            local ramp=math.min(1,drop.magnetPullAge/.55)
            ramp=ramp*ramp*(3-2*ramp)
            local speed=drop.bossMagnet and pickupSpeed*(.16+ramp*1.05) or pickupSpeed
            local pull = 1-math.exp(-dt*speed)
            drop.x, drop.y = drop.x + dx * pull, drop.y + dy * pull
            drop.height = drop.height + (10 - drop.height) * pull
            if distance <= 26 then
                local amount = math.min(drop.amount, cargoSpace(player))
                if amount > 0 then
                    if game.upgrades then amount = math.min(game.upgrades:applyGain(drop.kind, amount), cargoSpace(player)) end
                    player[drop.kind] = player[drop.kind] + amount
                    game.runStats.harvested = game.runStats.harvested + amount
                    game.runStats[drop.kind] = (game.runStats[drop.kind] or 0) + amount
                    if chopper and drop.kind=="wood" then chopper:onWood(amount,game) else game:addRunXP(amount) end
                    local label = drop.kind == "stone" and "돌" or drop.kind == "wood" and "목재" or drop.kind == "food" and "식량" or "광석"
                    local color = effectColors[drop.kind]
                    self.popups[#self.popups + 1] = {x=drop.x,y=drop.y-32,life=.8,maxLife=.8,text="+"..amount.." "..label,color=color,chain=0}
                    table.remove(self.drops, i)
                else
                    drop.magnet = false
                end
            end
        else
            drop.x, drop.y = drop.x + drop.vx * dt, drop.y + drop.vy * dt
            drop.vx, drop.vy = drop.vx * math.exp(-dt * 4.5), drop.vy * math.exp(-dt * 4.5)
            drop.height, drop.vz = drop.height + drop.vz * dt, drop.vz - 360 * dt
            if drop.height <= 0 then
                drop.height = 0
                if drop.vz < -45 then drop.vz = -drop.vz * .22 else drop.vz = 0 end
            end
        end
    end
end

function World:harvestPower(game, kind)
    local pct = game.upgrades and game.upgrades.resourcePct and game.upgrades.resourcePct[kind] or 0
    return 1 + math.min(pct, 2.5)
end

function World:turretUpgradeBurst(building, mod)
    local x, y = building.x, building.y - 30
    local color = mod.color or {1, .9, .4, 1}
    for _, ring in ipairs({{size = 12, life = .26}, {size = 24, life = .4}, {size = 40, life = .56}}) do
        self.particles[#self.particles + 1] = {x = x, y = y, life = ring.life, maxLife = ring.life, size = ring.size, color = color, ring = true}
    end
    for _ = 1, 28 do
        local angle = love.math.random() * math.pi * 2
        local speed = 90 + love.math.random() * 190
        local life = .45 + love.math.random() * .3
        self.particles[#self.particles + 1] = {
            x = x, y = y, vx = math.cos(angle) * speed, vy = math.sin(angle) * speed * .6 - 60,
            life = life, maxLife = life, size = 2.5 + love.math.random() * 3.5, color = color
        }
    end
    self.impactFlashes[#self.impactFlashes + 1] = {x = x, y = y, life = .3, maxLife = .3}
    self.popups[#self.popups + 1] = {x = x, y = y - 46, life = .95, maxLife = .95, text = mod.name .. " 강화!", color = color, chain = 0}
end

function World:harvestChipBurst(x, y, kind, power, game, isCrit)
    local color = effectColors[kind] or {1, 1, 1}
    local count = math.floor(3 + (power - 1) * 10)
    for _ = 1, count do self:addParticle(x, y, color, power > 1.25, true) end
    if power > 1.15 then
        self.particles[#self.particles + 1] = {x = x, y = y, life = .22, maxLife = .22, size = 10 + power * 8, color = color, ring = true}
    end
    if isCrit then
        self.particles[#self.particles + 1] = {x = x, y = y, life = .32, maxLife = .32, size = 28, color = {1, .92, .4}, ring = true}
        for _ = 1, 10 do self:addParticle(x, y, {1, .9, .4}, true, true) end
        self.popups[#self.popups + 1] = {x = x, y = y - 44, life = .8, maxLife = .8, text = "치명타!", color = {1, .85, .25}, chain = 0}
    end
    if game.camera then game.camera.trauma = math.min(1, game.camera.trauma + .06 + power * .05 + (isCrit and .15 or 0)) end
end

function World:harvestHit(node, game, player)
    local chopper = activeChopper(game)
    if chopper and node.rushTree then chopper:hitTree(node,game); return end
    self:impactNode(node, game, false)
    local ex, ey = effectOrigin(node)
    local critChance = game.upgrades and game.upgrades.resourcePct.critChance or 0
    local isCrit = love.math.random() < math.min(critChance, 1)
    local critAmount = isCrit and 3 or 1
    if node.kind == "tree" then
        local power = self:harvestPower(game, "wood") + (isCrit and 1.2 or 0)
        self:harvestChipBurst(ex, ey, "wood", power, game, isCrit)
        self:spawnDrop("wood", critAmount, node.x + 160, node.y + 70, 130, 100, power)
    elseif node.kind == "quarry" then
        node.oreCounter = (node.oreCounter or 0) + 1
        local isOre = node.oreCounter % 5 == 0
        local kind = isOre and "ore" or "stone"
        local power = self:harvestPower(game, kind) + (isCrit and 1.2 or 0)
        self:harvestChipBurst(ex, ey, kind, power, game, isCrit)
        self:spawnDrop(kind, critAmount, node.x - 160, node.y + 70, 130, 100, power)
    end
end

function World:build()
    for row = 0, 2 do for col = 0, 3 do self.nodes[#self.nodes + 1] = plot(1320 + col * 160, 1580 + row * 175) end end
    self.nodes[#self.nodes + 1] = resource("tree", 1110, 1420, 4.5)
    self.nodes[#self.nodes + 1] = resource("quarry", 2070, 1420, 4.5)
end

function World:update(dt, game)
    self:updateEffects(dt, game)
    self:updateDrops(dt, game)
    self:updateBuildings(dt, game)
    self:updateProjectiles(dt, game)
    self:updateHelpers(dt, game)
    for _, turret in ipairs(self.turrets) do turret.flash = math.max(0, (turret.flash or 0) - dt) end
    for _, node in ipairs(self.nodes) do
        if node.kind == "plot" then
            if node.state == "growing" then node.grow = math.max(0, node.grow - dt * (game.upgrades and game.upgrades:cropGrowthMultiplier() or 1)); if node.grow <= 0 then node.state = "ready" end end
        elseif not node.active then
            node.respawn = node.respawn - dt
            if node.respawn <= 0 then
                node.active, node.work = true, 0
                if node.rushTree then node.rushHp,node.damageStage=node.rushMaxHp,nil end
            end
        end
    end
    self.spawnTimer = self.spawnTimer - dt
    if self.spawnTimer <= 0 and not game.ended then
        self.wave = self.wave + 1
        game:addRunXP(3 + math.floor(self.wave / 5))
        local isSurge = self.wave % 6 == 0
        local baseCount = 2 + math.floor(self.wave * .85)
        local count = math.min(90, isSurge and math.floor(baseCount * 1.7) or baseCount)
        local laneCount = math.min(7, 3 + math.floor(self.wave / 10))
        local xMin, xMax = 220, self.width - 220
        for i = 1, count do
            local laneIndex, row = (i - 1) % laneCount, math.floor((i - 1) / laneCount)
            local laneX = laneCount == 1 and (xMin + xMax) / 2 or xMin + (laneIndex / (laneCount - 1)) * (xMax - xMin)
            self.enemies[#self.enemies + 1] = {x = laneX + love.math.random(-45, 45), y = 90 - row * 34, hp = 22 + self.wave * 4, speed = 48 + self.wave * 1.4, hit = 5 + self.wave * .65}
        end
        self.spawnTimer = math.max(3.2, 11 - self.wave * .2)
        if isSurge then
            game:setNotice("적 대량 출현!", "wave")
            if game.camera then game.camera.trauma = math.min(1, game.camera.trauma + .45) end
        end
    end
    for i = #self.enemies, 1, -1 do
        local e = self.enemies[i]
        if self.wall.hp > 0 then
            local targetX, targetY = self.core.x, self.wall.y - 34
            local dx, dy = targetX - e.x, targetY - e.y; local d = math.sqrt(dx * dx + dy * dy)
            if d > 28 then e.x, e.y = e.x + dx / d * e.speed * dt, e.y + dy / d * e.speed * dt
            else
                self.wall.hp = math.max(0, self.wall.hp - e.hit * dt * (1 - (self.wall.damageReduction or 0)))
                if self.wall.hp <= 0 and not self.wall.brokenNotified then self.wall.brokenNotified = true; game:setNotice("방어벽이 무너졌습니다", "ore"); game.ended, game.victory = true, false end
            end
        else
            game.ended, game.victory = true, false
        end
        if e.hp <= 0 then table.remove(self.enemies, i); self.kills = self.kills + 1; game:addRunXP(1) end
    end
    for _, defender in ipairs(self.defenders) do
        defender.cooldown = (defender.cooldown or 0) - dt
        if defender.cooldown <= 0 then
            local target, best = nil, defender.kind == "drone" and 520 or 390
            for _, enemy in ipairs(self.enemies) do local dx, dy = enemy.x - defender.x, enemy.y - defender.y; local d = math.sqrt(dx*dx+dy*dy); if d < best then target, best = enemy, d end end
            if target then
                local damage = (defender.kind == "drone" and 10 or 7) + (defender.level or 1) * 3
                target.hp = target.hp - damage; self:applyCombatEffects(target, damage, game)
                self.shots[#self.shots + 1] = {x1=defender.x,y1=defender.y-20,x2=target.x,y2=target.y,life=.14,color=defender.kind=="drone" and {.3,.85,1} or {.45,1,.38}}
                defender.cooldown = (defender.kind == "drone" and .85 or 1.15) / (1 + (game.upgrades and game.upgrades:level("protein_feed") or 0) * .08)
            end
        end
    end
    self.core.cooldown = self.core.cooldown - dt
    if self.core.cooldown <= 0 then
        local sources = game.rush and #self.turrets > 0 and self.turrets or {self.turrets[1] or false}
        local fired = false
        for _, source in ipairs(sources) do
            local sx, sy = source and source.x or self.core.x, source and source.y - 35 or self.core.y - 70
            local target, best = nil, self.core.range or 510
            for _, e in ipairs(self.enemies) do local dx,dy=e.x-sx,e.y-sy; local d=math.sqrt(dx*dx+dy*dy); if e.hp>0 and d<best then target,best=e,d end end
            if target then
                if source then source.flash=.14 end
                target.hp=target.hp-self.core.damage; self:applyCombatEffects(target,self.core.damage,game)
                self.shots[#self.shots+1]={x1=sx,y1=sy,x2=target.x,y2=target.y,life=.12,color=game.rush and {.95,.64,.16} or nil}
                fired=true
            end
        end
        if fired then self.core.cooldown=1/self.core.fireRate end
    end
    for i = #self.shots, 1, -1 do self.shots[i].life = self.shots[i].life - dt; if self.shots[i].life <= 0 then table.remove(self.shots, i) end end
end

local turretSlots = {{x=-61,y=-66},{x=61,y=-66},{x=-61,y=28},{x=61,y=28}}

function World:canPlaceBuilding(x, y, footprint)
    footprint = footprint or 46
    if x < self.core.x - 680 or x > self.core.x + 680 then return false end
    if y < self.wall.y + 60 or y > self.height - 70 then return false end
    local coreDx, coreDy = x - self.core.x, y - self.core.y
    if coreDx * coreDx + coreDy * coreDy < 190 * 190 then return false end
    for _, building in ipairs(self.buildings) do
        local other = buildingById[building.kind]
        local minDist = footprint / 2 + (other and other.footprint or 46) / 2 + 6
        local dx, dy = x - building.x, y - building.y
        if dx * dx + dy * dy < minDist * minDist then return false end
    end
    for _, node in ipairs(self.nodes) do
        local nodeRadius = node.kind == "quarry" and 220 or node.kind == "tree" and 150 or 60
        local minDist = footprint / 2 + nodeRadius
        local dx, dy = x - node.x, y - node.y
        if dx * dx + dy * dy < minDist * minDist then return false end
    end
    for _, turret in ipairs(self.turrets) do
        local minDist = footprint / 2 + 40
        local dx, dy = x - turret.x, y - turret.y
        if dx * dx + dy * dy < minDist * minDist then return false end
    end
    for i = 1, self.turretSlotLimit do
        local slot = self.turretSlots[i]
        local minDist = footprint / 2 + 55
        local dx, dy = x - slot.x, y - slot.y
        if dx * dx + dy * dy < minDist * minDist then return false end
    end
    return true
end

function World:setTurretSlotLimit(limit)
    self.turretSlotLimit = math.max(1, math.min(#self.turretSlots, math.floor(limit or 1)))
end

function World:turretInSlot(index)
    for _, building in ipairs(self.buildings) do
        if building.turretSlotIndex == index then return building end
    end
end

function World:turretBuildingCount()
    local count = 0
    for _, building in ipairs(self.buildings) do if isTurretDef(buildingById[building.kind]) then count = count + 1 end end
    return count
end

function World:firstAvailableTurretSlot()
    for i = 1, self.turretSlotLimit do
        if not self:turretInSlot(i) then return self.turretSlots[i] end
    end
end

function World:turretSlotAt(x, y, availableOnly)
    for i = 1, self.turretSlotLimit do
        local slot = self.turretSlots[i]
        local dx, dy = x - slot.x, y - slot.y
        if dx * dx + dy * dy <= 72 * 72 and (not availableOnly or not self:turretInSlot(i)) then return slot end
    end
end

function World:addBuilding(kind, x, y, turretSlotIndex)
    local def = buildingById[kind]
    if not def then return nil end
    if isTurretDef(def) then
        local slot = turretSlotIndex and self.turretSlots[turretSlotIndex] or self:turretSlotAt(x, y, true)
        if not slot or slot.index > self.turretSlotLimit or self:turretInSlot(slot.index) then return nil end
        x, y, turretSlotIndex = slot.x, slot.y, slot.index
    elseif not self:canPlaceBuilding(x, y, def.footprint) then return nil end
    local building = {kind = kind, x = x, y = y, timer = def.interval, flash = .4, fuel = def.fuelRadius and 1 or nil, level = 0, mods = {}, turretSlotIndex = turretSlotIndex, aimAngle = -math.pi / 2, recoil = 0, barrelSide = 1}
    self.buildings[#self.buildings + 1] = building
    return building
end

function World:defFor(kind) return buildingById[kind] end

function World:isTurretBuilding(kind) return isTurretDef(buildingById[kind]) end

function World:turretMaxLevel() return turretMaxLevel end

function World:buildingAt(x, y)
    for _, b in ipairs(self.buildings) do
        local def = buildingById[b.kind]
        local r = (def.footprint or 46) / 2 + 16
        local dx, dy = x - b.x, y - b.y
        if dx * dx + dy * dy <= r * r then return b, def end
    end
end

function World:nearestTurretBuilding(x, y, maxDistance)
    local nearest, bestDistance2 = nil, (maxDistance or 200) ^ 2
    for _, building in ipairs(self.buildings) do
        if self:isTurretBuilding(building.kind) then
            local dx, dy = building.x - x, building.y - y
            local distance2 = dx * dx + dy * dy
            if distance2 <= bestDistance2 then
                nearest, bestDistance2 = building, distance2
            end
        end
    end
    return nearest
end

function World:turretUpgradeCost(building)
    local level = building.level or 0
    return math.floor(6 + level * level * 4 + .5)
end

function World:rollTurretMods()
    local pool = {}
    for i, mod in ipairs(turretMods) do pool[i] = mod end
    for i = #pool, 2, -1 do local j = love.math.random(i); pool[i], pool[j] = pool[j], pool[i] end
    return {pool[1], pool[2], pool[3]}
end

function World:updateBuildings(dt, game)
    for _, b in ipairs(self.buildings) do
        b.flash = math.max(0, (b.flash or 0) - dt)
        b.recoil = math.max(0, (b.recoil or 0) - dt * 5.5)
        b.drillBurst = math.max(0, (b.drillBurst or 0) - dt)
        local def = buildingById[b.kind]
        if b.kind == "mining_drone" then b.drillAngle = (b.drillAngle or 0) + dt * (8 + (b.drillBurst or 0) * 48) end
        if def.behavior == "turret" then self:updateTurretAim(b, def, dt) end
        if def.fuelRadius then
            local dx, dy = game.player.x - b.x, game.player.y - b.y
            local inRange = dx * dx + dy * dy <= def.fuelRadius * def.fuelRadius
            local efficiency = 1 + (game.upgrades and game.upgrades.resourcePct.fuelEfficiency or 0) + (game.metaFuelEfficiency or 0)
            local rate = inRange and (def.fuelRecharge * efficiency) or -(def.fuelDrain / efficiency)
            b.fuel = math.max(0, math.min(1, (b.fuel or 1) + dt * rate))
        end
        local mods = b.mods or {}
        b.timer = (b.timer or def.interval) - dt
        if b.timer <= 0 then
            b.timer = def.interval * (0.85 ^ (mods.rapid_coil or 0))
            if def.fuelRadius and (b.fuel or 1) <= 0 then
                -- out of fuel: skip this cycle's action entirely
            elseif def.behavior == "produce" then
                self:spawnDrop(def.resource, def.amount + (game.metaProduceBonus or 0), b.x, b.y + 44, 50, 40)
                b.flash = .3
                if b.kind == "mining_drone" then
                    b.drillBurst = .5
                    for _ = 1, 13 do
                        local p = {x=b.x+love.math.random(-14,14),y=b.y+20,vx=love.math.random(-105,105),vy=love.math.random(-90,-20),life=.42,maxLife=.42,size=love.math.random(2,5),color=love.math.random()<.35 and {.25,.82,1} or {.62,.68,.72}}
                        self.particles[#self.particles+1] = p
                    end
                end
            elseif def.behavior == "spawn" then
                local affordable = true
                for res, amt in pairs(def.spawnCost) do if (game[res] or 0) < amt then affordable = false end end
                if affordable and #self.defenders < 5 + #self.buildings * 2 then
                    for res, amt in pairs(def.spawnCost) do game[res] = game[res] - amt end
                    self:spawnDefender(def.spawnKind, 1, game)
                    b.flash = .35
                end
            elseif def.behavior == "rail" then
                local dmg = (def.damage + (game.upgrades and game.upgrades:level("super_magnet") or 0) * 7) * (1 + (mods.heavy_shell or 0) * .4)
                local targets = 1 + (mods.multishot or 0)
                for _ = 1, 1 + (mods.double_tap or 0) do
                    if (game.ore or 0) < (def.spawnCost.ore or 0) then break end
                    game.ore = game.ore - def.spawnCost.ore
                    if not self:fireRail(b, game, dmg, targets) then break end
                end
            elseif def.behavior == "blade" then
                local dmg = def.damage * (1 + (mods.heavy_shell or 0) * .4)
                local cap = 5 + (mods.multishot or 0) * 2
                for _ = 1, 1 + (mods.double_tap or 0) do
                    if not self:bladeBurst(b, game, dmg, cap) then break end
                end
            elseif def.behavior == "spore" then
                self:sporeBurst(b, game, def.damage)
            elseif def.behavior == "repair" then
                if self.wall.hp < self.wall.maxHp and (game.wood or 0) >= (def.spawnCost.wood or 0) and (game.stone or 0) >= (def.spawnCost.stone or 0) then
                    game.wood, game.stone = game.wood - def.spawnCost.wood, game.stone - def.spawnCost.stone
                    self.wall.hp = math.min(self.wall.maxHp, self.wall.hp + def.repairAmount)
                    self:resourcePulse(game, "plot", def.repairAmount, "자동 수리")
                    b.flash = .45
                end
            elseif def.behavior == "carrier" then
                if game.player:totalCargo() > 0 then game:depositCargo("운반 드론 자동 납품"); b.flash = .25 end
            elseif def.behavior == "turret" then
                local range = def.range * (1 + (mods.long_barrel or 0) * .18)
                local dmg = def.damage * (1 + (mods.heavy_shell or 0) * .4)
                local targets = 1 + (mods.multishot or 0)
                for _ = 1, 1 + (mods.double_tap or 0) do
                    if not self:turretFire(b, game, dmg, range, targets) then break end
                end
            end
        end
    end
end

local function dropStillListed(list, target)
    for _, drop in ipairs(list) do if drop == target then return true end end
    return false
end

function World:updateHelpers(dt, game)
    local chopper=game.clearcut
    local level=chopper and chopper:levelOf("baby_robot")or(game.upgrades and game.upgrades:level("baby_robot")or 0)
    local helperCount=chopper and(level>0 and 1+math.floor((level-1)/2)or 0)or level
    local operationScanner=chopper and chopper.scoreAttack and chopper:levelOf("robot_scanner")or 0
    local speed=(80+level*30)*(1+(chopper and chopper.permanentTraits and chopper.permanentTraits.scoreRobotSpeed or 0))*(1+operationScanner*.18)
    local home=chopper and game.player or self.core
    local scanRadius=chopper and(300+level*120)*(1+operationScanner*.35)or math.huge
    while #self.helpers < helperCount do
        self.helpers[#self.helpers + 1] = {x = home.x + love.math.random(-40, 40), y = home.y + love.math.random(-40, 40), bob = love.math.random() * 6.28}
    end
    while #self.helpers>helperCount do table.remove(self.helpers)end
    for _, h in ipairs(self.helpers) do
        h.bob = h.bob + dt * 5
        h.speed = speed
        if h.carrying then
            local dx, dy = home.x - h.x, home.y - h.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist > 40 then
                h.x, h.y = h.x + dx / dist * h.speed * dt, h.y + dy / dist * h.speed * dt
            else
                local kind, amount = h.carrying.kind, h.carrying.amount
                if game.upgrades and not chopper then amount = game.upgrades:applyGain(kind, amount) end
                if chopper then game.player[kind]=(game.player[kind]or 0)+amount else game[kind]=game[kind]+amount end
                if game.runStats then
                    game.runStats.harvested = (game.runStats.harvested or 0) + amount
                    game.runStats[kind] = (game.runStats[kind] or 0) + amount
                end
                if chopper and kind=="wood"then chopper:onWood(amount,game)else game:addRunXP(amount)end
                local pulseKind = kind == "food" and "plot" or kind == "wood" and "tree" or kind
                self:resourcePulse(game, pulseKind, amount, "로봇 납품")
                h.carrying = nil
            end
        else
            if h.target and not dropStillListed(self.drops, h.target) then h.target = nil end
            if not h.target then
                local best, bestDist = nil, nil
                for _, drop in ipairs(self.drops) do
                    local dx, dy = drop.x - h.x, drop.y - h.y
                    local d = dx * dx + dy * dy
                    local eligible=(not chopper or drop.kind=="wood")and(drop.height or 0)<=18 and d<=scanRadius*scanRadius
                    if eligible and(not bestDist or d<bestDist)then best,bestDist=drop,d end
                end
                h.target = best
            end
            if h.target then
                local dx, dy = h.target.x - h.x, h.target.y - h.y
                local dist = math.sqrt(dx * dx + dy * dy)
                if dist > 6 then
                    h.x, h.y = h.x + dx / dist * h.speed * dt, h.y + dy / dist * h.speed * dt
                else
                    local collected=h.target
                    for i, d in ipairs(self.drops) do if d == h.target then table.remove(self.drops, i); break end end
                    h.target = nil
                    if chopper then
                        local amount=collected.amount
                        if game.runStats then
                            game.runStats.harvested=(game.runStats.harvested or 0)+amount
                            game.runStats.wood=(game.runStats.wood or 0)+amount
                        end
                        chopper:onWood(amount,game)
                        self:resourcePulse(game,"tree",amount,"아기 로봇 회수")
                    else
                        h.carrying = {kind = collected.kind, amount = collected.amount}
                    end
                end
            else
                local dx, dy = home.x - h.x, home.y - h.y
                local dist = math.sqrt(dx * dx + dy * dy)
                if dist > 30 then h.x, h.y = h.x + dx / dist * h.speed * .5 * dt, h.y + dy / dist * h.speed * .5 * dt end
            end
        end
    end
end

function World:addTurret(kind, level)
    if #self.turrets < #turretSlots then
        local slot = turretSlots[#self.turrets + 1]
        self.turrets[#self.turrets + 1] = {kind=kind or "autocannon", level=level or 1, x=self.core.x+slot.x, y=self.core.y-50+slot.y, flash=.25}
        return self.turrets[#self.turrets]
    end
    local target = self.turrets[1]
    for _, turret in ipairs(self.turrets) do if turret.level < target.level then target = turret end end
    target.level, target.flash = math.min(5, target.level + 1), .3
    if kind == "rail" then target.kind = "rail" end
    return target
end

function World:applyCombatEffects(target, damage, game)
    if not game.upgrades then return end
    local explosion = game.upgrades:level("explosive_payload")
    if explosion > 0 then
        local radius = 55 + explosion * 12
        for _, enemy in ipairs(self.enemies) do
            if enemy ~= target then local dx,dy=enemy.x-target.x,enemy.y-target.y; if dx*dx+dy*dy <= radius*radius then enemy.hp = enemy.hp - damage * (.18 + explosion * .04) end end
        end
        self.particles[#self.particles+1] = {x=target.x,y=target.y-20,life=.22,maxLife=.22,size=18,color={1,.38,.14},ring=true}
    end
    local chain = game.upgrades:level("chain_coil")
    if chain > 0 then
        local chained = 0
        for _, enemy in ipairs(self.enemies) do
            if enemy ~= target and chained < math.min(3, chain) then
                local dx,dy=enemy.x-target.x,enemy.y-target.y
                if dx*dx+dy*dy <= (145+chain*15)^2 then
                    enemy.hp=enemy.hp-damage*(.2+chain*.03); chained=chained+1
                    self.shots[#self.shots+1]={x1=target.x,y1=target.y,x2=enemy.x,y2=enemy.y,life=.1,color={.48,.78,1}}
                end
            end
        end
    end
end

function World:spawnDefender(kind, level, game)
    kind = kind or "bio"
    local x,y
    if kind == "drone" then x,y=self.core.x+love.math.random(-245,245),self.core.y+85+love.math.random(0,65)
    else x,y=self.core.x+love.math.random(-145,145),self.core.y-120-love.math.random(0,70) end
    self.defenders[#self.defenders + 1] = {kind=kind, level=level or 1, x=x, y=y, cooldown=.2}
    if game and game.camera then game.camera.trauma = math.min(1, game.camera.trauma + .16) end
end

function World:fireRail(source, game, damage, count)
    count = count or 1
    local sorted = {}
    for _, enemy in ipairs(self.enemies) do sorted[#sorted + 1] = enemy end
    if #sorted == 0 then return false end
    table.sort(sorted, function(a, b) return a.y > b.y end)
    source.flash = .3
    for i = 1, math.min(count, #sorted) do
        local target = sorted[i]
        target.hp = target.hp - damage; self:applyCombatEffects(target, damage, game)
        self.shots[#self.shots+1]={x1=source.x,y1=source.y-38,x2=target.x,y2=target.y,life=.24,color={.25,.92,1}}
        self.particles[#self.particles+1]={x=target.x,y=target.y,life=.3,maxLife=.3,size=22,color={.25,.92,1},ring=true}
    end
    if game.camera then game.camera.trauma=math.min(1,game.camera.trauma+.24) end
    return true
end

function World:bladeBurst(source, game, damage, cap)
    cap = cap or 5
    local hits = 0
    for _, enemy in ipairs(self.enemies) do
        if hits < cap and enemy.y > self.wall.y - 520 then enemy.hp=enemy.hp-damage; hits=hits+1; self.shots[#self.shots+1]={x1=source.x,y1=source.y-25,x2=enemy.x,y2=enemy.y,life=.18,color={1,.62,.18}} end
    end
    if hits > 0 then source.flash = .3; if game.camera then game.camera.trauma=math.min(1,game.camera.trauma+.13) end end
    return hits > 0
end

function World:updateTurretAim(building, def, dt)
    local best, bestDistance2
    local range = def.range or 440
    for _, enemy in ipairs(self.enemies) do
        if enemy.hp > 0 then
            local dx, dy = enemy.x - building.x, enemy.y - (building.y - 64)
            local distance2 = dx * dx + dy * dy
            if distance2 <= range * range and (not bestDistance2 or distance2 < bestDistance2) then
                best, bestDistance2 = enemy, distance2
            end
        end
    end
    building.aimTarget = best
    if best then
        local desired = atan2(best.y - (building.y - 64), best.x - building.x)
        local speed = 1 - math.exp(-dt * 12)
        building.aimAngle = (building.aimAngle or -math.pi / 2) + angleDelta(desired, building.aimAngle or -math.pi / 2) * speed
    end
end

function World:spawnAutocannonRound(building, target, damage, game)
    local angle = atan2(target.y - (building.y - 64), target.x - building.x)
    building.aimAngle = angle
    building.barrelSide = -(building.barrelSide or 1)
    local side = building.barrelSide * 10
    local muzzleX = building.x + math.cos(angle) * 90 - math.sin(angle) * side
    local muzzleY = building.y - 64 + math.sin(angle) * 90 + math.cos(angle) * side
    self.bullets[#self.bullets + 1] = {
        x = muzzleX, y = muzzleY, previousX = muzzleX, previousY = muzzleY,
        target = target, damage = damage, speed = 820, life = 1.4, angle = angle,
        chainLevel = (building.mods and building.mods.rapid_coil) or 0,
        explosiveLevel = (building.mods and building.mods.heavy_shell) or 0
    }
    self.muzzleFlashes[#self.muzzleFlashes + 1] = {x = muzzleX, y = muzzleY, angle = angle, life = .13, maxLife = .13}
    for _ = 1, 5 do
        local sparkAngle = angle + (love.math.random() - .5) * .55
        local speed = love.math.random(160, 290)
        self.particles[#self.particles + 1] = {
            x = muzzleX, y = muzzleY, vx = math.cos(sparkAngle) * speed, vy = math.sin(sparkAngle) * speed,
            life = .18, maxLife = .18, size = love.math.random(2, 4), color = {1, .58, .14}
        }
    end
    building.flash, building.recoil = .16, .16
    if game.camera then game.camera.trauma = math.min(1, game.camera.trauma + .045) end
end

function World:createChainArc(from, to, damage, level, game)
    local points, segments = {}, 8
    local dx, dy = to.x - from.x, to.y - from.y
    local length = math.max(1, math.sqrt(dx * dx + dy * dy))
    local nx, ny = -dy / length, dx / length
    for i = 0, segments do
        local t = i / segments
        local jitter = (i == 0 or i == segments) and 0 or love.math.random(-11, 11)
        points[#points + 1] = from.x + dx * t + nx * jitter
        points[#points + 1] = from.y + dy * t + ny * jitter
    end
    self.chainArcs[#self.chainArcs + 1] = {points=points,life=.23,maxLife=.23}
    to.hp = to.hp - damage
    self:applyCombatEffects(to, damage, game)
    for _ = 1, 5 do self:addParticle(to.x, to.y, {.3,.82,1}, false, false) end
end

function World:triggerRoundEffects(bullet, primary, game)
    local explosiveLevel = bullet.explosiveLevel or 0
    if explosiveLevel > 0 then
        local radius = 72 + explosiveLevel * 12
        self.explosions[#self.explosions + 1] = {x=primary.x,y=primary.y,life=.48,maxLife=.48,radius=radius}
        for _, enemy in ipairs(self.enemies) do
            if enemy ~= primary and enemy.hp > 0 then
                local dx, dy = enemy.x - primary.x, enemy.y - primary.y
                if dx * dx + dy * dy <= radius * radius then
                    local splash = bullet.damage * (.38 + explosiveLevel * .12)
                    enemy.hp = enemy.hp - splash
                    self:applyCombatEffects(enemy, splash, game)
                end
            end
        end
        for _ = 1, 22 do self:addParticle(primary.x, primary.y, love.math.random()<.35 and {1,.88,.38} or {1,.3,.08}, true, false) end
        if game.camera then game.camera.trauma = math.min(1, game.camera.trauma + .22) end
    end
    local chainLevel = bullet.chainLevel or 0
    if chainLevel > 0 then
        local current, used = primary, {[primary]=true}
        for _ = 1, math.min(3, chainLevel) do
            local nextTarget, bestDistance2
            for _, enemy in ipairs(self.enemies) do
                if enemy.hp > 0 and not used[enemy] then
                    local dx, dy = enemy.x - current.x, enemy.y - current.y
                    local distance2 = dx * dx + dy * dy
                    if distance2 <= 185 * 185 and (not bestDistance2 or distance2 < bestDistance2) then nextTarget, bestDistance2 = enemy, distance2 end
                end
            end
            if not nextTarget then break end
            self:createChainArc(current, nextTarget, bullet.damage * (.42 + chainLevel * .08), chainLevel, game)
            used[nextTarget], current = true, nextTarget
        end
    end
end

function World:turretFire(building, game, damage, range, targetCount)
    local candidates = {}
    for _, enemy in ipairs(self.enemies) do
        local dx, dy = enemy.x - building.x, enemy.y - building.y
        local d2 = dx * dx + dy * dy
        if d2 <= range * range then candidates[#candidates + 1] = {enemy = enemy, d2 = d2} end
    end
    if #candidates == 0 then return false end
    table.sort(candidates, function(a, b) return a.d2 < b.d2 end)
    for i = 1, math.min(targetCount, #candidates) do
        self:spawnAutocannonRound(building, candidates[i].enemy, damage, game)
    end
    return true
end

function World:updateProjectiles(dt, game)
    for i = #self.muzzleFlashes, 1, -1 do
        local effect = self.muzzleFlashes[i]
        effect.life = effect.life - dt
        if effect.life <= 0 then table.remove(self.muzzleFlashes, i) end
    end
    for i = #self.impactFlashes, 1, -1 do
        local effect = self.impactFlashes[i]
        effect.life = effect.life - dt
        if effect.life <= 0 then table.remove(self.impactFlashes, i) end
    end
    for i = #self.chainArcs, 1, -1 do
        self.chainArcs[i].life = self.chainArcs[i].life - dt
        if self.chainArcs[i].life <= 0 then table.remove(self.chainArcs, i) end
    end
    for i = #self.explosions, 1, -1 do
        self.explosions[i].life = self.explosions[i].life - dt
        if self.explosions[i].life <= 0 then table.remove(self.explosions, i) end
    end
    for i = #self.bullets, 1, -1 do
        local bullet = self.bullets[i]
        bullet.life = bullet.life - dt
        local target = bullet.target
        if bullet.life <= 0 or not target or target.hp <= 0 then
            table.remove(self.bullets, i)
        else
            bullet.previousX, bullet.previousY = bullet.x, bullet.y
            local dx, dy = target.x - bullet.x, target.y - bullet.y
            local distance = math.sqrt(dx * dx + dy * dy)
            bullet.angle = atan2(dy, dx)
            if distance <= bullet.speed * dt + 12 then
                bullet.x, bullet.y = target.x, target.y
                target.hp = target.hp - bullet.damage
                self:applyCombatEffects(target, bullet.damage, game)
                self:triggerRoundEffects(bullet, target, game)
                self.impactFlashes[#self.impactFlashes + 1] = {x = target.x, y = target.y, life = .18, maxLife = .18}
                for _ = 1, 8 do self:addParticle(target.x, target.y, {1, .52, .12}, true, false) end
                if game.camera then game.camera.trauma = math.min(1, game.camera.trauma + .07) end
                table.remove(self.bullets, i)
            else
                bullet.x = bullet.x + dx / distance * bullet.speed * dt
                bullet.y = bullet.y + dy / distance * bullet.speed * dt
            end
        end
    end
end

function World:sporeBurst(source, game, damage)
    local crops = 0
    for _, node in ipairs(self.nodes) do if node.kind=="plot" and (node.state=="growing" or node.state=="ready") then crops=crops+1 end end
    if crops == 0 then return end
    local hits=0
    for _,enemy in ipairs(self.enemies) do if hits<math.min(6,crops) then enemy.hp=enemy.hp-damage*(1+crops*.04); hits=hits+1; self.shots[#self.shots+1]={x1=source.x,y1=source.y,x2=enemy.x,y2=enemy.y,life=.2,color={.45,1,.35}} end end
    if hits > 0 then source.flash = .3 end
end

function World:resourcePulse(game, kind, amount, label)
    local color=effectColors[kind] or effectColors.plot
    local x,y=self.core.x,self.core.y-105
    for _=1,math.min(10,amount+2) do self:addParticle(x,y,color,true,true) end
    self.popups[#self.popups+1]={x=x,y=y-55,life=1,maxLife=1,text="+"..amount.." "..label,color=color,chain=0}
    if game.feedback then game.feedback:play(kind=="plot" and "harvest" or kind, false) end
end

function World:upgradeWall()
    if self.wall.level >= self.wall.maxLevel then return false end
    local maxHpByLevel = {220, 400, 650, 950}
    self.wall.level = self.wall.level + 1
    self.wall.maxHp = math.floor(maxHpByLevel[self.wall.level] * (self.wall.hpMultiplier or 1) + .5)
    self.wall.hp = self.wall.maxHp
    self.wall.brokenNotified = false
    return true
end

function World:isWallAt(x, y)
    return x >= 55 and x <= self.width - 55 and math.abs(y - self.wall.y) <= 58
end

function World:repairWall(game)
    local wall = self.wall
    if wall.hp >= wall.maxHp then game:setNotice("방어벽이 이미 완전히 수리되었습니다", "core"); return false end
    if game.wood < 1 or game.stone < 1 then game:setNotice("수리 재료가 부족합니다 — 목재 1 · 돌 1", "core"); return false end
    game.wood, game.stone = game.wood - 1, game.stone - 1
    local amount = 28 + wall.level * 10 + (game.repairBonus or 0)
    wall.hp = math.min(wall.maxHp, wall.hp + amount)
    wall.brokenNotified = false
    game:setNotice(string.format("방어벽 수리 +%d", amount), "core")
    return wall.hp < wall.maxHp
end

function World:findNodeAt(x, y)
    local best, bestScore
    for _, node in ipairs(self.nodes) do
        if node.active or node.kind == "plot" then
            local rx, ry, centerY = 72, 52, node.y
            if node.rushTree then rx,ry,centerY=94,122,node.y-92
            elseif node.kind == "tree" then rx, ry, centerY = 188, 228, node.y - 150 end
            if node.kind == "plot" then rx, ry = 82, 42 end
            if node.kind == "stone" then rx, ry, centerY = 78, 62, node.y - 28 end
            if node.kind == "ore" then rx, ry, centerY = 68, 58, node.y - 24 end
            if node.kind == "quarry" then rx, ry, centerY = 190, 145, node.y - 92 end
            local dx, dy = (x - node.x) / rx, (y - centerY) / ry
            local score = dx * dx + dy * dy
            if score <= 1 and (not bestScore or score < bestScore) then best, bestScore = node, score end
        end
    end
    return best
end

function World:getInteraction(node, game)
    if not node or (node.kind ~= "plot" and not node.active) then return end
    if node.kind == "tree" then return "axe", "나무 베기" end
    if node.kind == "stone" then return "pickaxe", "돌 캐기" end
    if node.kind == "ore" then return "pickaxe", "광석 캐기" end
    if node.kind == "quarry" then return "pickaxe", "채석장 채굴" end
    if node.state == "empty" then return game.seeds > 0 and "hoe" or nil, game.seeds > 0 and "씨앗 심기" or "씨앗이 없습니다" end
    if node.state == "planted" then return "water", "물 주기" end
    if node.state == "growing" then return nil, string.format("성장 중 %.0f초", node.grow) end
    if node.state == "ready" then return "hoe", "작물 수확" end
end

function World:workNode(node, game, player, tool, dt)
    local speed = game.tools[tool] and game.tools[tool].speed or 1
    if node.kind == "plot" then
        node.work = (node.work or 0) + speed * dt
        if node.work < .75 then return true end
        node.work = 0
        if node.state == "empty" and game.seeds > 0 then game.seeds = game.seeds - 1; node.state = "planted"; game:setNotice("씨앗을 심었습니다", "food"); return false end
        if node.state == "planted" then node.state, node.grow = "growing", node.growMax; game:setNotice("물을 주었습니다 — 성장을 시작합니다", "core"); return false end
        if node.state == "ready" then
            if cargoSpace(player) < 6 then game:setNotice("가방이 가득 찼습니다", "core"); return false end
            local amount = game.upgrades and game.upgrades:duplicateAmount(6) or 6
            amount = amount + (game.harvestBonus or 0)
            if game.upgrades then amount = game.upgrades:applyGain("food", amount) end
            amount=math.min(amount,cargoSpace(player)); player.food, game.seeds, node.state = player.food + amount, game.seeds + 1, "empty"
            game.runStats.harvested = game.runStats.harvested + amount; game:addRunXP(amount)
            self:harvestBurst(node, game, amount, "식량")
            game:setNotice("작물 +"..amount.."  씨앗 +1", "food"); return false
        end
        return false
    end
    if cargoSpace(player) <= 0 then game:setNotice("가방이 가득 찼습니다", "core"); return false end
    if node.kind == "quarry" or node.kind == "tree" then return true end
    node.work = node.work + speed * dt
    if node.work < node.workTime then return true end
    local amount = node.kind == "stone" and 5 or 5
    if game.upgrades then amount = game.upgrades:duplicateAmount(amount) end
    if game.upgrades then amount = game.upgrades:applyGain(node.kind, amount) end
    amount = math.min(amount, cargoSpace(player))
    player[node.kind == "tree" and "wood" or node.kind] = player[node.kind == "tree" and "wood" or node.kind] + amount
    game.runStats.harvested = game.runStats.harvested + amount; game.runStats[node.kind] = (game.runStats[node.kind] or 0) + amount; game:addRunXP(amount)
    node.active, node.work, node.respawn = false, 0, node.kind == "tree" and 18 or node.kind == "stone" and 15 or 22
    local label = node.kind == "tree" and "목재" or node.kind == "stone" and "돌" or "광석"
    self:harvestBurst(node, game, amount, label)
    game:setNotice(label .. " +" .. amount, node.kind == "ore" and "ore" or "core")
    return false
end

local function drawTiled(img, x, y, w, h, tile)
    love.graphics.setColor(1, 1, 1, 1)
    local sx, sy = tile / img:getWidth(), tile / img:getHeight()
    for py = y, y + h, tile do for px = x, x + w, tile do love.graphics.draw(img, px, py, 0, sx, sy) end end
end

local function drawMirroredTiled(img, x, y, w, h, tile, alpha)
    love.graphics.setColor(1, 1, 1, alpha or 1)
    local baseX, baseY = tile / img:getWidth(), tile / img:getHeight()
    local row = 0
    for py = y, y + h, tile do
        local col = 0
        for px = x, x + w, tile do
            local flipX, flipY = col % 2 == 1, row % 2 == 1
            local sx, sy = flipX and -baseX or baseX, flipY and -baseY or baseY
            local ox, oy = flipX and img:getWidth() or 0, flipY and img:getHeight() or 0
            love.graphics.draw(img, px, py, 0, sx, sy, ox, oy)
            col = col + 1
        end
        row = row + 1
    end
end

local function shadow(x, y, rx, ry, alpha) love.graphics.setColor(0, 0, 0, alpha or .38); love.graphics.ellipse("fill", x + 8, y + 14, rx, ry) end
local function centered(img, x, y, scale) love.graphics.setColor(1, 1, 1, 1); love.graphics.draw(img, x, y, 0, scale, scale, img:getWidth() / 2, img:getHeight() / 2) end
local function grounded(img, x, y, scale) love.graphics.setColor(1, 1, 1, 1); love.graphics.draw(img, x, y, 0, scale, scale, img:getWidth() / 2, img:getHeight() * .91) end
local function groundedRotated(img, x, y, scale, angle) love.graphics.setColor(1, 1, 1, 1); love.graphics.draw(img, x, y, angle, scale, scale, img:getWidth() / 2, img:getHeight() * .91) end

local function treeRenderSpec(world, node)
    if node.giantTree and world.images.ancientBroadleaf then return world.images.ancientBroadleaf, 1, 1.3 end
    local index = math.max(1, math.min(#world.images.treeVariants, node.treeVariant or 1))
    local stage=math.max(0,math.min(3,node.damageStage or 0))
    local damaged=world.images.treeDamageVariants and world.images.treeDamageVariants[index]
    local sprite=stage>0 and damaged and damaged[stage] or world.images.treeVariants[index]
    return sprite, world.treeVisual.variantScale[index] or 1, world.treeVisual.variantShadow[index] or 1
end

function World:useArcadeForest()
    if not self.arcadeForest then
        self.arcadeForest = true
        self.images.treeVariants = {}
        for _, name in ipairs({"broadleaf", "pine", "birch", "maple"}) do
            local sprite = love.graphics.newImage("assets/trees/" .. name .. "-tree-cartoon-v3.png")
            sprite:setFilter("nearest", "nearest")
            self.images.treeVariants[#self.images.treeVariants+1] = sprite
        end
        self.images.ancientBroadleaf = love.graphics.newImage("assets/trees/ancient-broadleaf-tall-cartoon-v1.png")
        self.images.ancientBroadleaf:setFilter("nearest", "nearest")
        self.images.treeDamageVariants={}
        for _,name in ipairs({"broadleaf","pine","birch","maple"}) do
            local stages={}
            for stage=1,3 do
                local sprite=love.graphics.newImage(string.format("assets/trees/damage/%s-damage%d-v1.png",name,stage))
                sprite:setFilter("nearest","nearest");stages[stage]=sprite
            end
            self.images.treeDamageVariants[#self.images.treeDamageVariants+1]=stages
        end
        self.images.stumpAtlas=love.graphics.newImage("assets/trees/stump-atlas-pixel-v1.png")
        self.images.stumpAtlas:setFilter("nearest","nearest")
        self.images.stumpQuads={}
        for index=1,14 do
            local zero=index-1
            self.images.stumpQuads[index]=love.graphics.newQuad((zero%4)*128,math.floor(zero/4)*96,128,96,self.images.stumpAtlas:getDimensions())
        end
    end
    self.treeVisual.frontBias = 0 -- authored roots are at the .91-height anchor
    self.treeVisual.shadowX, self.treeVisual.shadowY = 0, 0
    self.treeVisual.shadowRx, self.treeVisual.shadowRy = 36, 6
end

function World:drawForestGround(player,actorSource)
    if self.arcadeForest then
        local clipped=self.northBackdrop and self.playBounds
        if clipped then
            love.graphics.stencil(function()
                love.graphics.rectangle("fill",0,self.playBounds.y,self.width,self.height-self.playBounds.y)
            end,"replace",1)
            love.graphics.setStencilTest("greater",0)
        end
        if require("src.clearcut_maps").drawGround(self) then
            ForestFloor.drawGround(self,player,actorSource)
            ForestScenery.drawGround(self)
            ForestLighting.drawGround(self)
            if clipped then love.graphics.setStencilTest() end
            return
        end
        love.graphics.setColor(.29,.35,.14,1)
        love.graphics.rectangle("fill",0,0,self.width,self.height)
        drawMirroredTiled(self.images.forestGround,0,0,self.width,self.height,768,.14)
        ForestFloor.drawGround(self,player,actorSource)
        ForestScenery.drawGround(self)
        ForestLighting.drawGround(self)
        if clipped then love.graphics.setStencilTest() end
        return
    end
    love.graphics.setColor(.36, .53, .13, 1)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    drawMirroredTiled(self.images.forestGround, 0, 0, self.width, self.height, 768, .3)
    drawMirroredTiled(self.images.forestGround, -384, -384, self.width + 768, self.height + 768, 768, .18)
    if self.hideBase then return end

    -- 방벽 앞은 적과 투사체가 읽히는 밝은 초원 전선으로 남긴다.
    love.graphics.setColor(.16, .31, .09, .14)
    love.graphics.rectangle("fill", 55, 55, self.width - 110, self.wall.y - 110)

    -- 전선, 중앙 작업장, 깊은 숲을 잇는 하나의 흙길이다.
    love.graphics.setColor(.42, .25, .09, .48)
    love.graphics.polygon("fill",
        self.core.x - 88, 55, self.core.x + 88, 55,
        self.core.x + 126, self.wall.y + 70, self.core.x + 218, self.core.y + 78,
        self.core.x + 165, self.height - 55, self.core.x - 150, self.height - 55,
        self.core.x - 205, self.core.y + 78, self.core.x - 120, self.wall.y + 70)
    love.graphics.setColor(.72, .51, .2, .22)
    love.graphics.setLineWidth(8)
    love.graphics.line(self.core.x, 55, self.core.x, self.wall.y + 20, self.core.x - 22, self.core.y + 115, self.core.x + 12, self.height - 55)

    -- 벌목물이 모이는 넓은 중앙 공터와 양쪽 작업 진입로.
    love.graphics.setColor(.39, .23, .08, .6)
    love.graphics.ellipse("fill", self.core.x, self.core.y + 92, 390, 225)
    love.graphics.polygon("fill", self.core.x - 220, self.core.y + 120, 130, 1650, 130, 1815, self.core.x - 135, self.core.y + 245)
    love.graphics.polygon("fill", self.core.x + 220, self.core.y + 120, self.width - 130, 1650, self.width - 130, 1815, self.core.x + 135, self.core.y + 245)
    love.graphics.setColor(.77, .58, .25, .22)
    love.graphics.setLineWidth(4)
    love.graphics.ellipse("line", self.core.x, self.core.y + 92, 390, 225)

    -- 반복 타일 위의 작은 풀·낙엽 디테일. 전부 비상호작용 장식이다.
    for i = 1, 96 do
        local x = 75 + ((i * 347) % (self.width - 150))
        local y = 75 + ((i * 613) % (self.height - 150))
        local nearYard = ((x - self.core.x) / 420) ^ 2 + ((y - self.core.y - 90) / 245) ^ 2 < 1
        if not nearYard then
            local size = 2 + i % 4
            if i % 3 == 0 then
                love.graphics.setColor(.86, .56, .16, .35)
                love.graphics.ellipse("fill", x, y, size + 2, size)
            else
                love.graphics.setColor(.18, .42, .1, .38)
                love.graphics.setLineWidth(2)
                love.graphics.line(x - size, y + size, x, y - size, x + size, y + size)
            end
        end
    end

    -- 월드 가장자리는 금속 프레임 대신 짙은 숲바닥으로 마감한다.
    love.graphics.setColor(.045, .12, .055, .88)
    love.graphics.rectangle("fill", 0, 0, self.width, 55)
    love.graphics.rectangle("fill", 0, self.height - 55, self.width, 55)
    love.graphics.rectangle("fill", 0, 0, 55, self.height)
    love.graphics.rectangle("fill", self.width - 55, 0, 55, self.height)
end

function World:drawRushStump(node)
    local regrow = math.max(0, math.min(1, 1 - (node.respawn or 0) / 10))
    local offsets={forest=0,beginner=0,mangrove=4,madagascar=7,island=10}
    local mapId=self.clearcutMap or "forest"
    local variants=(mapId=="forest" or mapId=="beginner") and 4 or 3
    local index=(offsets[mapId] or 0)+math.max(1,math.min(variants,node.treeVariant or 1))
    local atlas,quad=self.images.stumpAtlas,self.images.stumpQuads and self.images.stumpQuads[index]
    if not atlas or not quad then return end
    local scale=node.giantTree and .78 or .58
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(atlas,quad,node.x,node.y,0,scale,scale,64,86)
    if regrow>.7 then
        love.graphics.draw(atlas,self.images.stumpQuads[14],node.x,node.y-(node.giantTree and 12 or 0),0,scale,scale,64,86)
    end
end

function World:drawTurretSlot(slot)
    local occupied = self:turretInSlot(slot.index) ~= nil
    shadow(slot.x, slot.y + 4, 57, 14, .45)
    love.graphics.setColor(.12, .16, .17, 1)
    love.graphics.polygon("fill", slot.x - 58, slot.y, slot.x - 40, slot.y - 23, slot.x + 40, slot.y - 23, slot.x + 58, slot.y, slot.x + 40, slot.y + 23, slot.x - 40, slot.y + 23)
    love.graphics.setColor(.31, .38, .39, 1); love.graphics.setLineWidth(3)
    love.graphics.polygon("line", slot.x - 58, slot.y, slot.x - 40, slot.y - 23, slot.x + 40, slot.y - 23, slot.x + 58, slot.y, slot.x + 40, slot.y + 23, slot.x - 40, slot.y + 23)
    love.graphics.setColor(occupied and {.27, .31, .31, 1} or {.24, .27, .25, 1})
    love.graphics.ellipse("fill", slot.x, slot.y, 35, 15)
    love.graphics.setColor(occupied and {.55, .6, .6, .7} or {.9, .62, .2, .9}); love.graphics.setLineWidth(2)
    love.graphics.ellipse("line", slot.x, slot.y, 35, 15)
    for _, offset in ipairs({-42, 42}) do
        love.graphics.setColor(.72, .76, .72, .8); love.graphics.circle("fill", slot.x + offset, slot.y, 3)
    end
    if not occupied then
        love.graphics.setFont(self.effectFont); love.graphics.setColor(1, .72, .3, .9)
        love.graphics.printf("포대 " .. slot.index, slot.x - 50, slot.y + 29, 100, "center")
    end
end

function World:drawPlot(node)
    local wet = node.state == "growing" or node.state == "planted"
    love.graphics.setColor(wet and {.105, .065, .04, .96} or {.17, .095, .045, .94})
    love.graphics.polygon("fill", node.x - 70, node.y - 28, node.x + 42, node.y - 28, node.x + 70, node.y + 25, node.x - 42, node.y + 25)
    love.graphics.setLineWidth(1.5); love.graphics.setColor(.38, .2, .075, .9)
    for row = -2, 2 do love.graphics.line(node.x - 50 + row * 9, node.y - 19, node.x + 45 + row * 9, node.y + 17) end
    love.graphics.setColor(.62, .38, .12, .7); love.graphics.polygon("line", node.x - 70, node.y - 28, node.x + 42, node.y - 28, node.x + 70, node.y + 25, node.x - 42, node.y + 25)
    if node.state == "planted" then love.graphics.setColor(.72, .55, .18); for i = -1, 1 do love.graphics.circle("fill", node.x + i * 24, node.y, 3) end end
    if node.state == "growing" or node.state == "ready" then
        local progress = node.state == "ready" and 1 or 1 - node.grow / node.growMax
        centered(self.images.crop, node.x, node.y - 25, .035 + progress * .035)
        if node.state == "growing" then
            love.graphics.setColor(.02, .04, .03, .9); love.graphics.rectangle("fill", node.x - 35, node.y - 58, 70, 7, 3, 3)
            love.graphics.setColor(.35, .92, .4); love.graphics.rectangle("fill", node.x - 35, node.y - 58, 70 * progress, 7, 3, 3)
        end
    end
end

function World:drawWall(player)
    local wall, y, level = self.wall, self.wall.y, self.wall.level
    local integrity = wall.maxHp > 0 and wall.hp / wall.maxHp or 0
    local alpha = wall.hp > 0 and 1 or .34
    love.graphics.setColor(0, 0, 0, .48 * alpha); love.graphics.rectangle("fill", 55, y + 18, self.width - 110, 23)
    for x = 55, self.width - 55, 160 do
        local segmentW = math.min(156, self.width - 55 - x)
        if level == 1 then
            love.graphics.setColor(.19, .22, .22, alpha); love.graphics.rectangle("fill", x, y - 11, segmentW, 26, 3, 3)
            love.graphics.setColor(.55, .34, .13, alpha); love.graphics.rectangle("fill", x + 4, y - 7, segmentW - 8, 5); love.graphics.rectangle("fill", x + 4, y + 7, segmentW - 8, 5)
            love.graphics.setColor(.36, .4, .39, alpha); love.graphics.rectangle("fill", x, y - 22, 10, 45, 2, 2); love.graphics.rectangle("fill", x + segmentW - 10, y - 22, 10, 45, 2, 2)
        elseif level == 2 then
            love.graphics.setColor(.16, .2, .22, alpha); love.graphics.rectangle("fill", x, y - 25, segmentW, 51, 4, 4)
            love.graphics.setColor(.31, .37, .39, alpha); love.graphics.polygon("fill", x + 5, y - 20, x + segmentW - 14, y - 20, x + segmentW - 5, y, x + segmentW - 14, y + 20, x + 5, y + 20)
            love.graphics.setColor(.9, .52, .12, alpha); love.graphics.rectangle("fill", x + 10, y - 3, segmentW - 20, 6)
            love.graphics.setColor(.65, .7, .7, alpha); for r = 16, segmentW - 16, 42 do love.graphics.circle("fill", x + r, y - 15, 2); love.graphics.circle("fill", x + r, y + 15, 2) end
        else
            love.graphics.setColor(.09, .14, .17, alpha); love.graphics.rectangle("fill", x, y - 34, segmentW, 68, 5, 5)
            love.graphics.setColor(.27, .34, .38, alpha); love.graphics.polygon("fill", x + 7, y - 28, x + segmentW - 20, y - 28, x + segmentW - 7, y - 12, x + segmentW - 7, y + 28, x + 20, y + 28, x + 7, y + 12)
            love.graphics.setColor(.08, .1, .12, alpha); love.graphics.rectangle("fill", x + 17, y - 20, segmentW - 34, 40, 3, 3)
            love.graphics.setColor(level == 4 and {.15, .82, 1, alpha} or {1, .56, .12, alpha}); love.graphics.rectangle("fill", x + 20, y - 4, segmentW - 40, 8, 3, 3)
            love.graphics.circle("fill", x + 14, y, 5); love.graphics.circle("fill", x + segmentW - 14, y, 5)
        end
    end
    if level == 4 and wall.hp > 0 then
        local pulse = .25 + math.sin(love.timer.getTime() * 4) * .08
        love.graphics.setColor(.12, .78, 1, pulse); love.graphics.rectangle("fill", 55, y - 45, self.width - 110, 83, 8, 8)
        love.graphics.setColor(.38, .92, 1, .8); love.graphics.setLineWidth(3); love.graphics.line(55, y - 43, self.width - 55, y - 43)
    end
    love.graphics.setColor(0, 0, 0, .75); love.graphics.rectangle("fill", self.core.x - 90, y - 61, 180, 12, 4, 4)
    love.graphics.setColor(level == 4 and {.18, .86, 1, 1} or {.94, .58, .14, 1}); love.graphics.rectangle("fill", self.core.x - 90, y - 61, 180 * integrity, 12, 4, 4)
    if player.repairingWall then
        local pulse = 30 + math.sin(love.timer.getTime() * 8) * 5
        love.graphics.setColor(1, .78, .2, .95); love.graphics.setLineWidth(3); love.graphics.circle("line", player.x, y, pulse)
    end
end

function World:drawMiningDrill(building)
    local phase = building.drillAngle or 0
    local burst = math.min(1, (building.drillBurst or 0) * 3)
    local x, y = building.x, building.y + 1
    love.graphics.setColor(.08,.1,.12,.9); love.graphics.rectangle("fill",x-7,y-2,14,12,3,3)
    love.graphics.setColor(.72,.76,.78,1); love.graphics.polygon("fill",x-10,y+8,x+10,y+8,x+3,y+39,x,y+45,x-3,y+39)
    love.graphics.setColor(.22,.25,.27,1); love.graphics.polygon("line",x-10,y+8,x+10,y+8,x+3,y+39,x,y+45,x-3,y+39)
    for i = 0, 3 do
        local py = y + 12 + i * 8
        local offset = math.sin(phase + i * 1.65) * (8 - i * 1.4)
        love.graphics.setLineWidth(3.5)
        love.graphics.setColor(.12,.15,.17,.95); love.graphics.line(x-8+i*1.3,py,x+8-i*1.3,py+4)
        love.graphics.setLineWidth(2)
        love.graphics.setColor(.95,.66,.18,.85); love.graphics.line(x+offset-4,py+1,x+offset+4,py+3)
    end
    love.graphics.setColor(.25,.82,1,.38+burst*.35); love.graphics.ellipse("line",x,y+42,12+burst*10,4+burst*3)
end

function World:draw(player, actorSource)
    love.graphics.setLineStyle("rough")
    if self.theme == "forest" then
        self:drawForestGround(player,actorSource)
    else
        drawTiled(self.images.industrial, 0, 0, self.width, 1160, 320)
        drawTiled(self.images.farm, 0, 1160, 1260, 840, 320)
        drawTiled(self.images.industrial, 1260, 1160, 680, 840, 320)
        drawTiled(self.images.quarry, 1940, 1160, 1260, 840, 320)
        love.graphics.setColor(.06, .075, .085, 1); love.graphics.rectangle("fill", 0, 0, self.width, 55); love.graphics.rectangle("fill", 0, self.height - 55, self.width, 55); love.graphics.rectangle("fill", 0, 0, 55, self.height); love.graphics.rectangle("fill", self.width - 55, 0, 55, self.height)
    end
    local queue = {}
    if self.arcadeForest and self.theme=="forest" then
        ForestScenery.queue(self,queue,player)
        ForestUnderstory.queue(self,queue,player)
        BiomeVines.queue(self,queue,player,love.timer.getTime())
    end
    if self.arcadeForest and self.theme=="forest" then require("src.biome_life").queue(self,queue,player) end
    if not self.hideBase then
        for i = 1, self.turretSlotLimit do
            local slot = self.turretSlots[i]
            queue[#queue + 1] = {x=slot.x,y = slot.y - 1, anchorY=slot.y, draw = function() self:drawTurretSlot(slot) end}
        end
        queue[#queue + 1] = {x=self.core.x,y = self.core.y, draw = function() shadow(self.core.x, self.core.y, 145, 48, .5); centered(self.images.core, self.core.x, self.core.y - 50, .23) end}
        queue[#queue + 1] = {x=self.core.x,y = self.core.y + 1,anchorY=self.core.y, draw = function()
            for _, turret in ipairs(self.turrets) do
                local pulse = 1 + turret.level * .025 + (turret.flash or 0) * .45
                shadow(turret.x, turret.y + 25, 28, 9, .35)
                love.graphics.setColor(1,1,1,1); grounded(self.images.turret, turret.x, turret.y + 30, .058 * pulse)
                if turret.flash and turret.flash > 0 then love.graphics.setColor(turret.kind=="rail" and {.25,.92,1,turret.flash*4} or {1,.7,.2,turret.flash*4}); love.graphics.circle("fill",turret.x-30,turret.y-22,8+turret.flash*45) end
            end
        end}
    end
    for _, value in ipairs(self.buildings) do local building = value; queue[#queue + 1] = {x=building.x,y = building.y, draw = function()
        local flash, icon = building.flash or 0, self.buildingIcons[building.kind]
        local def = buildingById[building.kind]
        if def.fuelRadius then
            local fuel = building.fuel or 1
            love.graphics.setLineWidth(1.5)
            love.graphics.setColor(fuel > .01 and .35 or 1, fuel > .01 and .82 or .3, 1, .18)
            love.graphics.circle("line", building.x, building.y, def.fuelRadius)
        end
        shadow(building.x, building.y + 10, def.behavior == "turret" and 70 or 62, def.behavior == "turret" and 22 or 19, .42)
        if flash > 0 then love.graphics.setColor(1, .58, .16, flash * 2.8); love.graphics.circle("fill", building.x, building.y - 42, 34 + flash * 70) end
        if icon and def.behavior == "turret" then
            local angle = building.aimAngle or -math.pi / 2
            local recoil = (building.recoil or 0) * 68
            local base, head = self.images.turretBase, self.images.turretHead
            local baseScale, headScale = 142 / base:getWidth(), 145 / head:getWidth()
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(base, building.x, building.y - 37, 0, baseScale, baseScale, base:getWidth() / 2, base:getHeight() / 2)
            love.graphics.draw(head, building.x - math.cos(angle) * recoil, building.y - 64 - math.sin(angle) * recoil,
                angle - math.pi, headScale, headScale, 1012, 512)
        elseif icon then
            if building.kind == "mining_drone" then self:drawMiningDrill(building) end
            love.graphics.setColor(1, 1, 1, 1)
            local scale = 78 / math.max(icon:getWidth(), icon:getHeight())
            grounded(icon, building.x, building.y + 12, scale * (1 + flash * .08))
        end
        if def.fuelRadius then
            local fuel = building.fuel or 1
            local gaugeW, gaugeY = 44, building.y - 82
            love.graphics.setColor(.05, .07, .08, .9); love.graphics.rectangle("fill", building.x - gaugeW / 2, gaugeY, gaugeW, 6, 2, 2)
            local fuelColor = fuel > .5 and {.35, .9, .5, 1} or fuel > .2 and {1, .75, .2, 1} or {1, .3, .25, 1}
            love.graphics.setColor(fuelColor); love.graphics.rectangle("fill", building.x - gaugeW / 2, gaugeY, gaugeW * fuel, 6, 2, 2)
            love.graphics.setColor(1, 1, 1, .18); love.graphics.setLineWidth(1); love.graphics.rectangle("line", building.x - gaugeW / 2, gaugeY, gaugeW, 6, 2, 2)
        end
        if isTurretDef(def) and (building.level or 0) > 0 then
            local dotY, count = building.y - (def.fuelRadius and 96 or 46), math.min(building.level, turretMaxLevel)
            local dotStart = building.x - (count - 1) * 3
            for i = 1, count do
                love.graphics.setColor(1, .78, .25, .9); love.graphics.circle("fill", dotStart + (i - 1) * 6, dotY, 2.4)
            end
        end
    end} end
    for _, value in ipairs(self.helpers) do local helper = value; queue[#queue + 1] = {x=helper.x,y = helper.y, draw = function()
        local bob = math.sin(helper.bob) * 4
        local helperSize=actorSource and 60 or 34
        local helperLift=actorSource and 29 or 18
        shadow(helper.x,helper.y+(actorSource and 13 or 10),actorSource and 28 or 16,actorSource and 9 or 6,.38)
        local icon = self.buildingIcons.carrier_drone
        if icon then
            love.graphics.setColor(1, 1, 1, 1)
            local scale = helperSize / math.max(icon:getWidth(), icon:getHeight())
            centered(icon,helper.x,helper.y-helperLift+bob,scale)
        end
        if helper.carrying then
            local kind = helper.carrying.kind
            local cargoIcon = kind == "stone" and self.images.stone or kind == "wood" and self.images.lumber or kind == "food" and self.images.crop or self.images.ore
            if cargoIcon then
                love.graphics.setColor(1, 1, 1, 1)
                local cargoScale = 16 / math.max(cargoIcon:getWidth(), cargoIcon:getHeight())
                centered(cargoIcon, helper.x, helper.y - 38 + bob, cargoScale)
            end
        end
    end} end
    if not self.hideBase then queue[#queue + 1] = {x=self.wall.x or self.width*.5,y = self.wall.y, draw = function() self:drawWall(player) end} end
    for _, n in ipairs(self.nodes) do
        if (n.active or n.kind == "plot" or n.rushTree)
            and (not self.clearcutMap or ClearcutMaps.insideSpawnTerrain(self,n.x,n.y,0)) then
            local node = n
            local sortY = node.kind == "quarry" and (node.y - self.quarryVisual.frontBias) or node.kind == "tree" and (node.y - self.treeVisual.frontBias) or node.y
            queue[#queue + 1] = {x=node.x,y = sortY,anchorY=node.y, draw = function()
                local shake = (node.hitShake or 0) * 42
                local ox, oy = (love.math.random() * 2 - 1) * shake, (love.math.random() * 2 - 1) * shake * .35
                local bump = 1 + (node.hitFlash or 0) * .32
                if node.fallT and node.fallT < node.fallDur then
                    local visual = self.treeVisual
                    local treeImage, variantScale, shadowScale = treeRenderSpec(self, node)
                    local ft = node.fallT / node.fallDur
                    local ease
                    if node.giantTree then
                        local motion=math.max(0,(ft-.13)/.87)
                        ease=motion*motion*(3-2*motion)
                    else ease=1-(1-ft)*(1-ft) end
                    local maxAngle=node.giantTree and .48 or .42
                    local angle = ease * math.pi * maxAngle * node.fallDir
                    if node.giantTree and ft<.48 then angle=angle+math.sin(ft*math.pi*9)*.008*node.fallDir end
                    local small=(node.rushMaxHp or 5)<=4
                    local slide=ease*(node.fallReach or 110)*(node.giantTree and .055 or (small and .34 or .10))*node.fallDir
                    local lift=small and math.sin(ft*math.pi)*18 or 0
                    if ft > .82 then angle = angle + math.sin((ft - .82) / .18 * math.pi) * .05 * node.fallDir end
                    love.graphics.setColor(0, 0, 0, visual.shadowAlpha * (1 - ft * .4))
                    love.graphics.ellipse("fill", node.x + visual.shadowX + slide, node.y + visual.shadowY, visual.shadowRx * shadowScale * (1 + ease * .5), visual.shadowRy)
                    groundedRotated(treeImage, node.x+slide, node.y-lift, visual.scale * variantScale, angle)
                    return
                elseif not node.active and node.rushTree then
                    if not node.uprooted then self:drawRushStump(node) end
                    return
                elseif node.hitFlash and node.hitFlash > 0 then
                    local fx, fy = effectOrigin(node); love.graphics.setColor(1, .9, .42, node.hitFlash * 3.5); love.graphics.circle("fill", fx, fy, 36 + node.hitFlash * 70)
                end
                if node.kind == "plot" then love.graphics.push(); love.graphics.translate(ox, oy); self:drawPlot(node); love.graphics.pop()
                elseif node.kind == "tree" then
                    local visual = self.treeVisual
                    local treeImage, variantScale, shadowScale = treeRenderSpec(self, node)
                    local growScale,growAngle,growAlpha=1,node.swayAngle or 0,1
                    local emergence=node.treeEmergence
                    if emergence then
                        if emergence.t<0 then growScale,growAlpha=.56,0
                        else
                            local raw=math.max(0,math.min(1,emergence.t/emergence.duration))
                            RegrowthCastArt.drawTreeEmergence(node,raw)
                            local rise=math.max(0,math.min(1,(raw-.12)/.72))
                            local ease=rise*rise*(3-2*rise)
                            growScale=.56+ease*.44+math.sin(math.min(1,rise)*math.pi)*.065
                            growAngle=(node.swayAngle or 0)+math.sin(rise*math.pi*3)*(1-rise)*.035*(emergence.direction or 1)
                            growAlpha=math.max(0,math.min(1,raw/.16))
                        end
                    end
                    love.graphics.setColor(0, 0, 0, visual.shadowAlpha*growAlpha)
                    love.graphics.ellipse("fill", node.x + visual.shadowX, node.y + visual.shadowY,
                        visual.shadowRx * shadowScale * (.38+growScale*.62), visual.shadowRy*growScale)
                    if node.berserkFlash and node.berserkFlash > 0 then
                        local bft = love.timer.getTime()
                        local bpulse = .5 + math.sin(bft * 14) * .5
                        local bf = math.min(1, node.berserkFlash / 1.2)
                        local reach = 34 * bf * (visual.scale / .28)
                        love.graphics.setColor(1, .12, .05, .3 * bf * (.6 + bpulse * .4))
                        love.graphics.circle("fill", node.x, node.y - 60 * (visual.scale / .28), 70 * (visual.scale / .28))
                        for i = 1, 6 do
                            local ang = i / 6 * math.pi * 2 + bft * .3
                            love.graphics.setLineWidth(2.2); love.graphics.setColor(1, .18, .06, .75 * bf)
                            love.graphics.line(node.x, node.y + 6, node.x + math.cos(ang) * reach, node.y + 6 + math.sin(ang) * reach * .5)
                        end
                    end
                    love.graphics.setColor(1,1,1,growAlpha)
                    love.graphics.draw(treeImage,node.x+ox,node.y+oy,growAngle,
                        visual.scale*variantScale*bump*growScale,visual.scale*variantScale*bump*growScale,
                        treeImage:getWidth()/2,treeImage:getHeight()*.91)
                    if node.burning then
                        if actorSource and actorSource.drawCigaretteTreeFire then
                            actorSource:drawCigaretteTreeFire(node)
                        else
                            local ft = love.timer.getTime()
                            local flicker = .7 + math.sin(ft * 20 + node.x) * .3
                            love.graphics.setColor(1, .5, .15, .32 * flicker); love.graphics.circle("fill", node.x, node.y - 24, 50)
                            for i = 1, 3 do
                                local fx = node.x + math.sin(ft * 9 + node.x + i * 2.1) * 16
                                local fy = node.y - 20 - i * 20 + math.sin(ft * 7 + i) * 4
                                local size = (26 - i * 6) * flicker
                                love.graphics.setColor(1, .32 + i * .06, .04, .88)
                                love.graphics.polygon("fill", fx, fy - size, fx - size * .55, fy + size * .55, fx + size * .55, fy + size * .55)
                                love.graphics.setColor(.55, .12, .02, .8); love.graphics.setLineWidth(1.4)
                                love.graphics.polygon("line", fx, fy - size, fx - size * .55, fy + size * .55, fx + size * .55, fy + size * .55)
                                love.graphics.setColor(1, .8, .3, .75)
                                love.graphics.polygon("fill", fx, fy - size * .5, fx - size * .25, fy + size * .3, fx + size * .25, fy + size * .3)
                            end
                            love.graphics.setColor(1, 1, .8, .9 * flicker); love.graphics.circle("fill", node.x, node.y - 52, 6)
                        end
                    end
                elseif node.kind == "quarry" then
                    local visual = self.quarryVisual
                    love.graphics.setColor(0, 0, 0, visual.shadowAlpha)
                    love.graphics.ellipse("fill", node.x + visual.shadowX, node.y + visual.shadowY, visual.shadowRx, visual.shadowRy)
                    grounded(self.images.stone, node.x + ox, node.y + oy, .285 * bump)
                    love.graphics.setColor(.25, .82, 1, .82); centered(self.images.ore, node.x + 68 + ox, node.y - 112 + oy, .055 * bump)
                elseif node.kind == "stone" then shadow(node.x, node.y, 54, 16, .4); grounded(self.images.stone, node.x + ox, node.y + oy, .085 * bump)
                else shadow(node.x, node.y, 48, 15, .4); centered(self.images.ore, node.x + ox, node.y - 25 + oy, .075 * bump) end
                if player.interactionTarget == node then
                    love.graphics.setColor(1, .7, .18, .9); love.graphics.setLineWidth(3); love.graphics.ellipse("line", node.x, node.y + 8, node.kind == "quarry" and 175 or (node.kind == "tree" and 128 or 58), node.kind == "quarry" and 52 or (node.kind == "tree" and 36 or 19))
                    if node.kind ~= "plot" and node.kind ~= "tree" and node.kind ~= "quarry" then
                        local barWidth = 70
                        local barY = node.y - 70
                        love.graphics.setColor(.08, .1, .1, .9); love.graphics.rectangle("fill", node.x - barWidth / 2, barY, barWidth, 7)
                        love.graphics.setColor(.95, .62, .16); love.graphics.rectangle("fill", node.x - barWidth / 2, barY, barWidth * node.work / node.workTime, 7)
                    end
                end
            end}
        end
    end
    for _, d in ipairs(self.defenders) do local defender = d; queue[#queue + 1] = {x=defender.x,y = defender.y, draw = function()
        if defender.kind == "drone" then
            local bob=math.sin(love.timer.getTime()*4+defender.x*.01)*5; shadow(defender.x,defender.y+8,31,10,.38); love.graphics.setColor(1,1,1); centered(self.images.drone,defender.x,defender.y-34+bob,.052)
        else shadow(defender.x, defender.y, 20, 8, .42); love.graphics.setColor(.25, .9, .38); love.graphics.circle("fill", defender.x, defender.y - 20, 22) end
    end} end
    for _, value in ipairs(self.drops) do local drop = value; queue[#queue + 1] = {x=drop.x,y = drop.y, draw = function()
        local img = drop.kind == "stone" and self.images.stone or drop.kind == "wood" and self.images.lumber or drop.kind == "food" and self.images.crop or self.images.ore
        local width = drop.kind == "stone" and 38 or drop.kind == "wood" and 48 or drop.kind == "food" and 34 or 31
        local scale = width / img:getWidth()
        love.graphics.setColor(0, 0, 0, drop.magnet and .12 or .24)
        love.graphics.ellipse("fill", drop.x + 2, drop.y + 3, width * .38, width * .11)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(img, drop.x, drop.y - drop.height, 0, scale, scale, img:getWidth() / 2, img:getHeight() * .91)
    end} end
    for _, e in ipairs(self.enemies) do local enemy = e; queue[#queue + 1] = {x=enemy.x,y = enemy.y, draw = function() shadow(enemy.x, enemy.y, 20, 9, .5); love.graphics.setColor(.65, .12, .15); love.graphics.circle("fill", enemy.x, enemy.y - 22, 24); love.graphics.setColor(1, .35, .25); love.graphics.circle("line", enemy.x, enemy.y - 22, 24) end} end
    if actorSource then actorSource:queueWorldActors(queue, love.timer.getTime()) end
    if not player.introHidden then queue[#queue + 1] = {x=player.x,y = player.y, draw = function() player:draw() end} end
    table.sort(queue, function(a, b)
        if a.y==b.y then return (a.sortBias or 0)<(b.sortBias or 0) end
        return a.y < b.y
    end)
    if self.deferBillboards then
        self.billboardQueue={}
        for _,item in ipairs(queue) do
            if item.ground then item.draw() else self.billboardQueue[#self.billboardQueue+1]=item end
        end
    else for _,item in ipairs(queue) do item.draw() end end
    love.graphics.setBlendMode("alpha")
    for _, explosion in ipairs(self.explosions) do
        local alpha = math.max(0, explosion.life / explosion.maxLife)
        local progress = 1 - alpha
        for i = 1, 7 do
            local a = i * .897 + .35
            local spread = explosion.radius * (.12 + progress * .32)
            local size = explosion.radius * (.13 + (i % 3) * .025 + progress * .08)
            love.graphics.setColor(.1,.085,.075,alpha*.42)
            love.graphics.circle("fill",explosion.x+math.cos(a)*spread,explosion.y+math.sin(a)*spread*.7,size)
        end
    end
    love.graphics.setBlendMode("add", "alphamultiply")
    for _, explosion in ipairs(self.explosions) do
        local alpha = math.max(0, explosion.life / explosion.maxLife)
        local progress = 1 - alpha
        local radius = explosion.radius * (.25 + progress * .75)
        love.graphics.setColor(1,.16,.02,alpha*.22); love.graphics.circle("fill",explosion.x,explosion.y,radius)
        for i = 1, 8 do
            local a = i * .785 + .2
            local lobeRadius = radius * (.24 + (i % 2) * .08)
            love.graphics.setColor(1,i%2==0 and .28 or .58,.03,alpha*.46)
            love.graphics.circle("fill",explosion.x+math.cos(a)*radius*.34,explosion.y+math.sin(a)*radius*.26,lobeRadius)
        end
        love.graphics.setColor(1,.55,.08,alpha*.6); love.graphics.setLineWidth(12*(1-progress)+2); love.graphics.circle("line",explosion.x,explosion.y,radius)
        love.graphics.setColor(1,.95,.62,alpha); love.graphics.setLineWidth(3); love.graphics.circle("line",explosion.x,explosion.y,radius*.72)
        if progress < .45 then love.graphics.setColor(1,1,.9,(.45-progress)*1.8); love.graphics.circle("fill",explosion.x,explosion.y,26+progress*38) end
    end
    for _, arc in ipairs(self.chainArcs) do
        local alpha = math.max(0, arc.life / arc.maxLife)
        love.graphics.setLineWidth(11); love.graphics.setColor(.05,.28,1,alpha*.18); love.graphics.line(unpack(arc.points))
        love.graphics.setLineWidth(5); love.graphics.setColor(.15,.7,1,alpha*.75); love.graphics.line(unpack(arc.points))
        love.graphics.setLineWidth(1.8); love.graphics.setColor(.88,.98,1,alpha); love.graphics.line(unpack(arc.points))
        for i = 1, #arc.points, 4 do love.graphics.circle("fill",arc.points[i],arc.points[i+1],2.6) end
    end
    for _, bullet in ipairs(self.bullets) do
        local tail = 34
        local tx, ty = bullet.x - math.cos(bullet.angle) * tail, bullet.y - math.sin(bullet.angle) * tail
        love.graphics.setLineWidth(9); love.graphics.setColor(1, .25, .04, .16); love.graphics.line(tx, ty, bullet.x, bullet.y)
        love.graphics.setLineWidth(4); love.graphics.setColor(1, .65, .12, .8); love.graphics.line(tx, ty, bullet.x, bullet.y)
        love.graphics.setColor(1, .96, .72, 1); love.graphics.circle("fill", bullet.x, bullet.y, 3.2)
    end
    local muzzle = self.images.muzzleFlash
    for _, effect in ipairs(self.muzzleFlashes) do
        local alpha = math.max(0, effect.life / effect.maxLife)
        local scale = .068 * (.9 + (1 - alpha) * .14)
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.draw(muzzle, effect.x, effect.y, effect.angle - math.pi, scale, scale, muzzle:getWidth() * .91, muzzle:getHeight() * .5)
    end
    for _, effect in ipairs(self.impactFlashes) do
        local alpha = math.max(0, effect.life / effect.maxLife)
        love.graphics.setColor(1, .62, .18, alpha * .55); love.graphics.circle("fill", effect.x, effect.y, 10 + (1 - alpha) * 18)
        love.graphics.setColor(1, .95, .72, alpha); love.graphics.setLineWidth(3); love.graphics.circle("line", effect.x, effect.y, 6 + (1 - alpha) * 26)
    end
    for _,fx in ipairs(self.treeBreakFx) do
        local a=math.max(0,fx.life/fx.maxLife)
        local scale=fx.scale*(1+(1-a)*.16)
        love.graphics.setColor(1,1,1,a)
        love.graphics.draw(self.images.treeBreakBurst,fx.x,fx.y,0,scale,scale,80,80)
    end
    love.graphics.setBlendMode("alpha")
    for _, p in ipairs(self.particles) do
        local alpha = math.max(0, p.life / p.maxLife)
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
        if p.ring then
            love.graphics.setLineWidth(3); love.graphics.circle("line", p.x, p.y, p.size + (1 - alpha) * 42)
        elseif p.pickup then
            love.graphics.push(); love.graphics.translate(p.x, p.y); love.graphics.rotate((1 - alpha) * 7)
            love.graphics.rectangle("fill", -p.size, -p.size, p.size * 2, p.size * 2, 2, 2)
            love.graphics.setColor(p.color[1] * .5, p.color[2] * .5, p.color[3] * .5, alpha); love.graphics.setLineWidth(1)
            love.graphics.rectangle("line", -p.size, -p.size, p.size * 2, p.size * 2, 2, 2)
            love.graphics.pop()
        elseif p.leaf then
            love.graphics.push(); love.graphics.translate(p.x, p.y); love.graphics.rotate(love.timer.getTime() * p.wobbleFreq + p.wobbleSeed)
            love.graphics.ellipse("fill", 0, 0, p.size, p.size * .48)
            love.graphics.setColor(p.color[1] * .45, p.color[2] * .45, p.color[3] * .45, alpha); love.graphics.setLineWidth(1)
            love.graphics.ellipse("line", 0, 0, p.size, p.size * .48)
            love.graphics.pop()
        elseif p.dust then
            local grow = 1 + (1 - alpha) * 1.45
            local stretch=p.dustStretch or 1
            love.graphics.setColor(p.color[1],p.color[2],p.color[3],alpha*(stretch>1 and .24 or .4))
            love.graphics.ellipse("fill",p.x,p.y,p.size*grow*stretch,p.size*grow*.62)
            love.graphics.setColor(.62,.55,.38,alpha*(stretch>1 and .08 or .12))
            love.graphics.ellipse("fill",p.x-p.size*.18,p.y-p.size*.15,p.size*grow*stretch*.54,p.size*grow*.23)
        elseif p.ember then
            local flick = .75 + math.sin(love.timer.getTime() * 30 + p.x) * .25
            love.graphics.setColor(.7, .18, .02, alpha * .9); love.graphics.setLineWidth(1)
            love.graphics.circle("line", p.x, p.y, p.size * flick + 1)
            love.graphics.setColor(1, .5, .08, alpha); love.graphics.circle("fill", p.x, p.y, p.size * flick)
            love.graphics.setColor(1, .92, .58, alpha * .95); love.graphics.circle("fill", p.x, p.y, p.size * flick * .42)
        else
            love.graphics.circle("fill", p.x, p.y, p.size)
            love.graphics.setColor(p.color[1] * .5, p.color[2] * .5, p.color[3] * .5, alpha * .8); love.graphics.setLineWidth(1)
            love.graphics.circle("line", p.x, p.y, p.size)
        end
    end
    love.graphics.setFont(self.effectFont)
    for _, popup in ipairs(self.popups) do
        local alpha = math.min(1, popup.life * 2.5)
        love.graphics.setColor(0, 0, 0, alpha * .7); love.graphics.printf(popup.text, popup.x - 99, popup.y + 2, 200, "center")
        love.graphics.setColor(popup.color[1], popup.color[2], popup.color[3], alpha); love.graphics.printf(popup.text, popup.x - 100, popup.y, 200, "center")
        if popup.chain >= 2 then love.graphics.setColor(1, .78, .2, alpha); love.graphics.printf("연속 채집 x" .. popup.chain, popup.x - 100, popup.y + 22, 200, "center") end
    end
    love.graphics.setLineWidth(4); for _, s in ipairs(self.shots) do local c=s.color or {.2,.85,1}; love.graphics.setColor(c[1],c[2],c[3],math.min(1,s.life/.12)); love.graphics.line(s.x1,s.y1,s.x2,s.y2) end
    love.graphics.setLineStyle("smooth")
end

return World
