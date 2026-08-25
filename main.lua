local Game
local game
local captureFrames = os.getenv("LAST_HAUL_CAPTURE_TURRET_FIRE") and 3 or (os.getenv("LAST_HAUL_CAPTURE_DRILL") and 2 or ((os.getenv("LAST_HAUL_CAPTURE_RUSH") or os.getenv("LAST_HAUL_CAPTURE_LOBBY") or os.getenv("LAST_HAUL_CAPTURE_CLEARCUT") or os.getenv("LAST_HAUL_CAPTURE_CLEARCUT_UPGRADE") or os.getenv("LAST_HAUL_CAPTURE_CLEARCUT_RESULTS") or os.getenv("LAST_HAUL_CAPTURE_CLEARCUT_THREATS") or os.getenv("LAST_HAUL_CAPTURE_CLEARCUT_BUILDS") or os.getenv("LAST_HAUL_CAPTURE_CLEARCUT_CHAR_SELECT") or os.getenv("LAST_HAUL_CAPTURE_CLEARCUT_FIREJOB") or os.getenv("LAST_HAUL_CAPTURE_CLEARCUT_DEVJOB") or os.getenv("LAST_HAUL_CAPTURE_CLEARCUT_COMBAT") or os.getenv("LAST_HAUL_CAPTURE_CLEARCUT_DEFEAT") or os.getenv("LAST_HAUL_CAPTURE_CLEARCUT_MILESTONE")) and 6 or (os.getenv("LAST_HAUL_CAPTURE_HARVEST") and 10 or ((os.getenv("LAST_HAUL_CAPTURE") or os.getenv("LAST_HAUL_CAPTURE_GAME") or os.getenv("LAST_HAUL_CAPTURE_FARM") or os.getenv("LAST_HAUL_CAPTURE_MINE") or os.getenv("LAST_HAUL_CAPTURE_WALL") or os.getenv("LAST_HAUL_CAPTURE_REPAIR") or os.getenv("LAST_HAUL_CAPTURE_META") or os.getenv("LAST_HAUL_CAPTURE_RESULTS") or os.getenv("LAST_HAUL_CAPTURE_UPGRADE") or os.getenv("LAST_HAUL_CAPTURE_UNITS") or os.getenv("LAST_HAUL_CAPTURE_TEST_OPTIONS") or os.getenv("LAST_HAUL_CAPTURE_TURRET_PROMPT") or os.getenv("LAST_HAUL_CAPTURE_TURRET_PLACEMENT") or os.getenv("LAST_HAUL_CAPTURE_TURRET_UPGRADE")) and 30 or nil))))

function love.load()
    love.graphics.setDefaultFilter("linear", "linear", 4)
    love.graphics.setLineStyle("smooth")
    Game = require("src.game")
    game = Game.new()
    if os.getenv("LAST_HAUL_SELF_TEST") then
        local ok, err = pcall(require("src.selftest").run, game)
        if not ok then print("SELF_TEST_FAIL: " .. tostring(err)); love.event.quit(1); return end
        love.event.quit(0)
        return
    end
    if os.getenv("LAST_HAUL_CAPTURE_META") then game.progression.data.currency = 42; game.mode = "meta" end
    if os.getenv("LAST_HAUL_CAPTURE_TEST_OPTIONS") then
        game.progression.data.currency = 1234567
        game:openTestOptions("lobby")
    end
    if os.getenv("LAST_HAUL_CAPTURE_RESULTS") then
        game:startRun()
        game.time, game.world.wave, game.world.kills, game.runStats.harvested = 214, 31, 86, 147
        game:finishRun(false)
    end
    if os.getenv("LAST_HAUL_CAPTURE_UPGRADE") then
        game:startRun(); game.runLevel = 4
        game.upgrades.choices = {game.upgrades:get("protein_feed"), game.upgrades:get("explosive_payload"), game.upgrades:get("production_clock")}
        game.mode = "upgrade"
    end
    if os.getenv("LAST_HAUL_CAPTURE_UNITS") then
        game:startRun(); game.camera.x,game.camera.y=game.world.core.x,game.world.core.y-30
        game.world:addTurret("autocannon",1); game.world:addTurret("rail",2); game.world:addTurret("autocannon",1)
        game.world:spawnDefender("drone",2,game); game.world:spawnDefender("drone",3,game); game.world:spawnDefender("drone",1,game)
    end
    if os.getenv("LAST_HAUL_CAPTURE_TURRET_PROMPT") then
        game:startRun()
        local slot = game.world:firstAvailableTurretSlot()
        local turret = game.world:addBuilding("autocannon_turret", slot.x, slot.y, slot.index)
        game.ore = 100
        game.player.x, game.player.y = turret.x + 75, turret.y + 55
        game.camera.x, game.camera.y = game.world.core.x, game.world.core.y + 60
    end
    if os.getenv("LAST_HAUL_CAPTURE_TURRET_UPGRADE") then
        game:startRun()
        local slot = game.world:firstAvailableTurretSlot()
        local turret = slot and game.world:addBuilding("autocannon_turret", slot.x, slot.y, slot.index) or game.world.buildings[1]
        turret.mods, turret.level = {rapid_coil = 1}, 1
        game.ore = 100
        game.player.x, game.player.y = turret.x + 75, turret.y + 55
        game.camera.x, game.camera.y = game.world.core.x, game.world.core.y + 60
        game:tryOpenTurretUpgrade(turret)
    end
    if os.getenv("LAST_HAUL_CAPTURE_TURRET_FIRE") then
        game:startRun()
        local slot = game.world:firstAvailableTurretSlot()
        local turret = slot and game.world:addBuilding("autocannon_turret", slot.x, slot.y, slot.index) or game.world.buildings[1]
        game.player.x, game.player.y = turret.x + 80, turret.y + 80
        game.camera.x, game.camera.y = turret.x - 20, turret.y - 140
        game.world.enemies = {
            {x=turret.x,y=turret.y-155,hp=800,speed=0,hit=0},
            {x=turret.x-70,y=turret.y-175,hp=800,speed=0,hit=0},
            {x=turret.x+75,y=turret.y-190,hp=800,speed=0,hit=0}
        }
        turret.mods, turret.timer = {rapid_coil=2,heavy_shell=1}, 0
    end
    if os.getenv("LAST_HAUL_CAPTURE_DRILL") then
        game:startRun()
        local drone = game.world:addBuilding("mining_drone", 1780, 1450)
        drone.timer = 0
        game.player.x, game.player.y = 1680, 1520
        game.camera.x, game.camera.y = drone.x, drone.y
    end
    if os.getenv("LAST_HAUL_CAPTURE_RUSH") then
        game:startRush()
        game.rush.levels.twin_axe,game.rush.levels.wide_swing,game.rush.levels.chain_fell,game.rush.levels.magnet=2,2,1,2
        local target,best=game.world.nodes[1],math.huge
        for _,node in ipairs(game.world.nodes) do
            local dx,dy=node.x-game.world.core.x,node.y-game.world.core.y
            if dx*dx+dy*dy<best then target,best=node,dx*dx+dy*dy end
        end
        game.player.x,game.player.y=target.x+90,target.y+55
        game.camera.x,game.camera.y=target.x,target.y-30
        target.rushHp=1; game.rush:hitTree(target,game)
        game.rush:onWood(95,game); game.rush.pending=0; game.mode="playing"
        game.world.enemies={
            {x=560,y=game.world.wall.y-310,hp=120,speed=0,hit=0},
            {x=1180,y=game.world.wall.y-210,hp=120,speed=0,hit=0},
            {x=1980,y=game.world.wall.y-260,hp=120,speed=0,hit=0},
            {x=2640,y=game.world.wall.y-150,hp=120,speed=0,hit=0}
        }
    end
    if os.getenv("LAST_HAUL_CAPTURE_CLEARCUT") then
        game:startClearcut()
        game.clearcut.levels.wide_blade,game.clearcut.levels.shockwave,game.clearcut.levels.berserker=2,2,1
        local target,best=game.world.nodes[1],math.huge
        for _,node in ipairs(game.world.nodes) do
            local dx,dy=node.x-game.player.x,node.y-game.player.y
            if dx*dx+dy*dy<best then target,best=node,dx*dx+dy*dy end
        end
        game.player.x,game.player.y=target.x+90,target.y+55
        game.camera.x,game.camera.y=target.x,target.y-30
        target.rushHp=1; game.clearcut:hitTree(target,game)
        game.clearcut:onWood(95,game); game.clearcut.pending=0; game.mode="playing"
        if os.getenv("LAST_HAUL_CAPTURE_CLEARCUT_JUICE") then
            local second,best2=nil,math.huge
            for _,node in ipairs(game.world.nodes) do
                local dx,dy=node.x-game.player.x,node.y-game.player.y
                if node~=target and dx*dx+dy*dy<best2 then second,best2=node,dx*dx+dy*dy end
            end
            if second then second.rushHp=1; game.clearcut:hitTree(second,game); game.world:spawnFallImpact(second,game) end
        end
    end
    if os.getenv("LAST_HAUL_CAPTURE_CLEARCUT_FIREJOB") then
        game:startClearcut("fire")
        game.clearcut.levels.molotov = 2
        love.mouse.setPosition(love.graphics.getWidth() / 2 + 220, love.graphics.getHeight() / 2 - 60)
        game.clearcut:updateHeldAxe(0, game, true)
    end
    if os.getenv("LAST_HAUL_CAPTURE_CLEARCUT_DEVJOB") then
        game:startClearcut("developer")
        local c = game.clearcut
        c.levels = {pile_driving=3, heavy_machinery=3, demolition=3, site_clearance=3}
        c:checkEvolutions(game)
        -- exercise the dash attack path, all four Lv3 effects, and the newtown fusion once each
        for run = 1, 6 do
            local nearest, best = nil, math.huge
            for _, node in ipairs(game.world.nodes) do
                if node.rushTree and node.active then
                    local dx, dy = node.x - game.player.x, node.y - game.player.y
                    local d2 = dx*dx + dy*dy
                    if d2 < best then nearest, best = node, d2 end
                end
            end
            if not nearest then break end
            game.camera.x, game.camera.y = nearest.x, nearest.y
            love.mouse.setPosition(love.graphics.getWidth()/2, love.graphics.getHeight()/2)
            c.attackCooldown = 0
            c:updateDeveloperAttack(0, game, true)
            for step = 1, 40 do
                if not c.dashing then break end
                c:updateDash(1/30, game)
            end
        end
        c:damageEnemiesInRadius(game.player.x, game.player.y, 500, 999, game)
        c:spawnBoss("ent", game)
        c.activeBoss.hp = 0
        c:updateEnemies(0.02, game)
        c:updateChests(0, game)
        game.player.x, game.player.y = c.chests[1] and c.chests[1].x or game.player.x, c.chests[1] and c.chests[1].y or game.player.y
        c:updateChests(0, game)
        if c.chestPending then c:choose(1, game) end
        print("DEVJOB_SMOKE_TEST_OK job=" .. tostring(c.job) .. " destructionPct=" .. string.format("%.1f", c:destructionPct()) .. " newtown=" .. tostring(c.evolutions.newtown) .. " chests=" .. #c.chests .. " dashTrail=" .. #c.dashTrail)
        game.mode = "playing"
        if os.getenv("LAST_HAUL_CLEARCUT_DEVJOB_VIEW") then
            c.dashTrail = {}
            c.enemies, c.chests = {}, {}
            game.camera.x, game.camera.y, game.camera.zoom = game.player.x + 40, game.player.y - 10, 1.4
            love.mouse.setPosition(love.graphics.getWidth()/2 + 160, love.graphics.getHeight()/2 - 30)
            c.attackCooldown = 0
            c:updateDeveloperAttack(0, game, false)
        end
    end
    if os.getenv("LAST_HAUL_CAPTURE_CLEARCUT_MILESTONE") then
        game:startClearcut(os.getenv("LAST_HAUL_CLEARCUT_JOB") or "physical")
        local c = game.clearcut
        -- fell trees via the REAL per-job attack path (not direct function calls) until the 10% wave should fire
        local need = math.ceil(c.initialTrees * .1) + 1
        for i = 1, need do
            local nearest, best = nil, math.huge
            for _, node in ipairs(game.world.nodes) do
                if node.rushTree and node.active then
                    local dx, dy = node.x - game.player.x, node.y - game.player.y
                    local d2 = dx*dx + dy*dy
                    if d2 < best then nearest, best = node, d2 end
                end
            end
            if not nearest then break end
            game.player.x, game.player.y = nearest.x + 40, nearest.y
            nearest.rushHp = 1
            if c.job == "fire" then
                love.mouse.setPosition(love.graphics.getWidth()/2, love.graphics.getHeight()/2)
                c.attackCooldown = 0
                local tx, ty = nearest.x, nearest.y
                c:hurlMolotovAt(tx, ty, game)
                c:updateMolotovs(10, game)
                c:updateFire(10, game)
            elseif c.job == "toxic" then
                game.camera.x, game.camera.y = nearest.x, nearest.y
                love.mouse.setPosition(love.graphics.getWidth()/2, love.graphics.getHeight()/2)
                c.attackCooldown = 0
                c:updateToxicAttack(0, game, true)
                c.attackCooldown = 0
                c:updateToxicAttack(0, game, true)
            elseif c.job == "developer" then
                game.camera.x, game.camera.y = nearest.x, nearest.y
                love.mouse.setPosition(love.graphics.getWidth()/2, love.graphics.getHeight()/2)
                c.attackCooldown = 0
                c:updateDeveloperAttack(0, game, true)
                for step = 1, 40 do
                    if not c.dashing then break end
                    c:updateDash(1/30, game)
                end
            else
                c.axeCooldown = 0
                c:hitTree(nearest, game)
            end
        end
        print("MILESTONE_TEST job=" .. tostring(c.job) .. " destructionPct=" .. string.format("%.1f", c:destructionPct()) .. " enemies=" .. #c.enemies .. " milestoneFired10=" .. tostring(c.milestoneFired[10]))
    end
    if os.getenv("LAST_HAUL_CAPTURE_CLEARCUT_COMBAT") then
        game:startClearcut("physical")
        local c = game.clearcut
        -- exercise every enemy/boss/projectile/damage path once as a smoke test
        c:spawnWave({squirrel=2, boar=1, turret=1}, game)
        for _, e in ipairs(c.enemies) do e.x, e.y = game.player.x + 60, game.player.y - 40 end
        c:updateEnemies(2, game)
        c:updateProjectiles(0.3, game)
        c:damageEnemiesInRadius(game.player.x, game.player.y, 500, 999, game)
        c:updateEnemies(0.02, game)
        c:spawnBoss("ent", game)
        c:bossSlam(c.activeBoss, game)
        c:updateBossTelegraphs(1, game)
        c.remainingTrees = 0
        c:updateEnemies(0.02, game)
        c:damagePlayer(30, game)
        print("COMBAT_SMOKE_TEST_OK hp=" .. c.hp .. " enemies=" .. #c.enemies .. " boss=" .. tostring(c.activeBoss and c.activeBoss.def.name) .. " worldtree=" .. tostring(c.worldTreeSpawned))
        if os.getenv("LAST_HAUL_CLEARCUT_COMBAT_VIEW") then
            c.enemies, c.chests, c.worldTree, c.activeBoss, c.worldTreeSpawned, c.pending = {}, {}, nil, nil, false, 0
            local a1 = c:spawnEnemy("squirrel", game.player.x - 90, game.player.y - 40)
            local a2 = c:spawnEnemy("boar", game.player.x + 70, game.player.y - 60)
            local a3 = c:spawnEnemy("turret", game.player.x - 20, game.player.y - 140)
            local a4 = c:spawnEnemy("ent", game.player.x + 160, game.player.y - 20)
            local a5 = c:spawnEnemy("worldtree", game.player.x - 40, game.player.y - 320)
            game.camera.x, game.camera.y, game.camera.zoom = game.player.x + 20, game.player.y - 120, .55
            game.mode = "playing"
        end
    end
    if os.getenv("LAST_HAUL_CAPTURE_CLEARCUT_DEFEAT") then
        game:startClearcut("physical")
        game.clearcut:damagePlayer(200, game)
    end
    if os.getenv("LAST_HAUL_CAPTURE_CLEARCUT_BUILDS") then
        game:startClearcut()
        local c = game.clearcut
        c.levels = {wide_blade=3, berserker=3, shockwave=3, domino=2, molotov=3, dry_forest=3, oil_drum=3, embers=3, herbicide=3, root_cutting=3, toxic_rain=3, forced_growth=1}
        c:checkEvolutions(game)
        c.elapsed = 46
        c.streak = 12
        -- exercise every new subsystem once to smoke-test for errors
        local a, b = game.world.nodes[1], game.world.nodes[2]
        a.rushHp, a.fallDir = 1, 1
        c:hitTree(a, game)              -- exercises megaCleave chance, frenzy, shockwave double-ring
        c:megaCleave(a, game)
        b.burning, b.burnTimer = true, 5
        c:updateFire(0.02, game)        -- exercises oil_drum guaranteed burst, embers landing burst, dry_forest wildburst path
        c.wildburstTimer = 0; c:updateFire(0.02, game)
        c:updateToxicRain(10, game)
        c:updatePlague(0.7, game)
        c:regrowPulse(game)
        c.job = "fire"; c:updateHeldAxe(0.02, game, true)
        c:updateMolotovs(2, game)
        c:trackMolotovBarrage(game); c:trackMolotovBarrage(game); c:trackMolotovBarrage(game)
        c.job = "toxic"; c:updateHeldAxe(0.02, game, true)  -- exercises necrosis
        c:damagePlayer(50, game)        -- exercises berserker dodge (streak>=10, berserker>=3)
        c:spawnBoss("ent", game)
        c.enemies[1].hp = 0
        c:updateEnemies(0.02, game)     -- exercises chest drop
        c:updateChests(0, game)         -- won't collect (player not near), then force it
        game.player.x, game.player.y = c.chests[1].x, c.chests[1].y
        c:updateChests(0, game)         -- exercises openChest -> chestPending flow
        if c.chestPending then c:choose(1, game) end
        c.job = "physical"
        print("BUILD_SMOKE_TEST_OK dodges=" .. c.dodges .. " frenzy=" .. tostring(c.evolutions.frenzy) .. " necrosis=" .. tostring(c.evolutions.necrosis) .. " chests=" .. #c.chests)
        game.mode = "playing"
    end
    if os.getenv("LAST_HAUL_CAPTURE_CLEARCUT_THREATS") then
        game:startClearcut()
        game.clearcut.elapsed = 46
        game.clearcut:regrowPulse(game)
        game.clearcut.bees[#game.clearcut.bees+1] = {x=game.player.x+90,y=game.player.y-30,speed=150,life=7}
        game.clearcut.beeSlow = true
        game.clearcut.rootHazards[#game.clearcut.rootHazards+1] = {x=game.player.x-70,y=game.player.y+40,phase="warn",timer=.4,radius=95}
        game.camera.x,game.camera.y = game.player.x,game.player.y
    end
    if os.getenv("LAST_HAUL_CAPTURE_CLEARCUT_UPGRADE") then
        game:startClearcut(os.getenv("LAST_HAUL_CLEARCUT_JOB")); game.clearcut.level = 5
        game.clearcut:rollChoices()
        game.mode = "clearcut_upgrade"
    end
    if os.getenv("LAST_HAUL_CAPTURE_CLEARCUT_RESULTS") then
        game:startClearcut()
        game.clearcut.elapsed, game.clearcut.totalWood, game.clearcut.treesFelled = 247, 3820, game.clearcut.initialTrees
        game.clearcut.maxMulti, game.clearcut.maxChain, game.clearcut.level, game.clearcut.remainingTrees = 9, 14, 12, 0
        game.clearcut.regrowPulses, game.clearcut.treesRevived, game.clearcut.rootedCount, game.clearcut.beeSwarmsTriggered = 6, 41, 3, 4
        game.clearcut:finish(game)
    end
    if os.getenv("LAST_HAUL_CAPTURE_CLEARCUT_CHAR_SELECT") then
        game.mode = "clearcut_select"
    end
    if os.getenv("LAST_HAUL_CAPTURE_TURRET_PLACEMENT") then
        game.progression.data.levels.turret_slots = tonumber(os.getenv("LAST_HAUL_TURRET_SLOT_LEVEL")) or 0
        game:startRun(); game.ore = 100
        game.player.x, game.player.y = game.world.core.x, game.world.core.y
        game.camera.x, game.camera.y = game.player.x, game.player.y
        game:useAbility(2)
        love.mouse.setPosition(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)
    end
    if os.getenv("LAST_HAUL_CAPTURE_GAME") then game:startRun() end
    if os.getenv("LAST_HAUL_CAPTURE_FARM") then
        game:startRun()
        game.player.x, game.player.y = 1420, 1580
        game.camera.x, game.camera.y = game.player.x, game.player.y
        local target = game.world:findNodeAt(1320, 1580)
        if target then game.player:beginInteraction(target, game.world, game) end
    end
    if os.getenv("LAST_HAUL_CAPTURE_MINE") then
        game:startRun()
        game.player.x, game.player.y = 1935, 1420
        game.camera.x, game.camera.y = game.player.x, game.player.y
        local target = game.world:findNodeAt(2070, 1420)
        if target then game.player:beginInteraction(target, game.world, game) end
    end
    if os.getenv("LAST_HAUL_CAPTURE_HARVEST") then
        game:startRun()
        game.player.x, game.player.y = 1935, 1420
        game.camera.x, game.camera.y = game.player.x, game.player.y
        local target = game.world:findNodeAt(2070, 1420)
        if target then target.work = target.workTime - .04; game.player:beginInteraction(target, game.world, game) end
    end
    if os.getenv("LAST_HAUL_CAPTURE_WALL") then
        game:startRun()
        local targetLevel = tonumber(os.getenv("LAST_HAUL_WALL_LEVEL")) or 3
        while game.world.wall.level < targetLevel do game.world:upgradeWall() end
        game.player.x, game.player.y = 1450, 1390
        game.camera.x, game.camera.y = 1600, 1325
    end
    if os.getenv("LAST_HAUL_CAPTURE_REPAIR") then
        game:startRun()
        game.world.wall.hp = 90
        game.wood, game.stone = 8, 8
        game.player.x, game.player.y = 1600, game.world.wall.y + 105
        game.camera.x, game.camera.y = game.player.x, game.player.y
        game.player:beginWallRepair(game.world, game)
    end
end

function love.update(dt)
    game:update(math.min(dt, 1 / 20))
    if os.getenv("LAST_HAUL_CAPTURE_RUSH") and game.rush and game.mode=="playing" then game.rush:updateHeldAxe(0,game,true) end
    if os.getenv("LAST_HAUL_CAPTURE_CLEARCUT") and game.clearcut and game.mode=="playing" then game.clearcut:updateHeldAxe(0,game,true) end
    if captureFrames then captureFrames = captureFrames - 1 end
end
function love.draw()
    game:draw()
    if captureFrames and captureFrames <= 0 then
        captureFrames = nil
        love.graphics.captureScreenshot(function(data)
            data:encode("png", "capture.png")
            love.event.quit()
        end)
    end
end
function love.keypressed(key)
    game:keypressed(key)
end
function love.mousepressed(x, y, button)
    game:mousepressed(x, y, button)
end
function love.wheelmoved(x, y)
    game:wheelmoved(x, y)
end
