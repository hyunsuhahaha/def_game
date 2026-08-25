local Game
local game
local captureFrames = os.getenv("LAST_HAUL_CAPTURE_TURRET_FIRE") and 3 or (os.getenv("LAST_HAUL_CAPTURE_DRILL") and 2 or ((os.getenv("LAST_HAUL_CAPTURE_RUSH") or os.getenv("LAST_HAUL_CAPTURE_LOBBY")) and 6 or (os.getenv("LAST_HAUL_CAPTURE_HARVEST") and 10 or ((os.getenv("LAST_HAUL_CAPTURE") or os.getenv("LAST_HAUL_CAPTURE_GAME") or os.getenv("LAST_HAUL_CAPTURE_FARM") or os.getenv("LAST_HAUL_CAPTURE_MINE") or os.getenv("LAST_HAUL_CAPTURE_WALL") or os.getenv("LAST_HAUL_CAPTURE_REPAIR") or os.getenv("LAST_HAUL_CAPTURE_META") or os.getenv("LAST_HAUL_CAPTURE_RESULTS") or os.getenv("LAST_HAUL_CAPTURE_UPGRADE") or os.getenv("LAST_HAUL_CAPTURE_UNITS") or os.getenv("LAST_HAUL_CAPTURE_TEST_OPTIONS") or os.getenv("LAST_HAUL_CAPTURE_TURRET_PROMPT") or os.getenv("LAST_HAUL_CAPTURE_TURRET_PLACEMENT") or os.getenv("LAST_HAUL_CAPTURE_TURRET_UPGRADE")) and 30 or nil))))

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
