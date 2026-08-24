local Game
local game
local captureFrames = os.getenv("LAST_HAUL_CAPTURE_HARVEST") and 10 or ((os.getenv("LAST_HAUL_CAPTURE") or os.getenv("LAST_HAUL_CAPTURE_GAME") or os.getenv("LAST_HAUL_CAPTURE_FARM") or os.getenv("LAST_HAUL_CAPTURE_MINE") or os.getenv("LAST_HAUL_CAPTURE_WALL") or os.getenv("LAST_HAUL_CAPTURE_REPAIR") or os.getenv("LAST_HAUL_CAPTURE_META") or os.getenv("LAST_HAUL_CAPTURE_RESULTS") or os.getenv("LAST_HAUL_CAPTURE_UPGRADE") or os.getenv("LAST_HAUL_CAPTURE_UNITS")) and 30 or nil)

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
    if os.getenv("LAST_HAUL_CAPTURE_RESULTS") then
        game:startRun(3)
        game.time, game.world.wave, game.world.kills, game.runStats.harvested = 214, 31, 86, 147
        game:finishRun(false)
    end
    if os.getenv("LAST_HAUL_CAPTURE_UPGRADE") then
        game:startRun(3); game.runLevel = 4
        game.upgrades.choices = {game.upgrades:get("auto_farm"), game.upgrades:get("rail_turret"), game.upgrades:get("production_clock")}
        game.mode = "upgrade"
    end
    if os.getenv("LAST_HAUL_CAPTURE_UNITS") then
        game:startRun(3); game.camera.x,game.camera.y=game.world.core.x,game.world.core.y-30
        game.world:addTurret("autocannon",1); game.world:addTurret("rail",2); game.world:addTurret("autocannon",1)
        game.world:spawnDefender("drone",2,game); game.world:spawnDefender("drone",3,game); game.world:spawnDefender("drone",1,game)
    end
    if os.getenv("LAST_HAUL_CAPTURE_GAME") then game:startRun(3) end
    if os.getenv("LAST_HAUL_CAPTURE_FARM") then
        game:startRun(1)
        game.player.x, game.player.y = 650, 1535
        game.camera.x, game.camera.y = game.player.x, game.player.y
        local target = game.world:findNodeAt(645, 1475)
        if target then game.player:beginInteraction(target, game.world, game) end
    end
    if os.getenv("LAST_HAUL_CAPTURE_MINE") then
        game:startRun(2)
        game.player.x, game.player.y = 2220, 1570
        game.camera.x, game.camera.y = game.player.x, game.player.y
        local target = game.world:findNodeAt(2140, 1510)
        if target then game.player:beginInteraction(target, game.world, game) end
    end
    if os.getenv("LAST_HAUL_CAPTURE_HARVEST") then
        game:startRun(3)
        game.player.x, game.player.y = 2210, 1600
        game.camera.x, game.camera.y = game.player.x, game.player.y
        local target = game.world:findNodeAt(2140, 1510)
        if target then target.work = target.workTime - .04; game.player:beginInteraction(target, game.world, game) end
    end
    if os.getenv("LAST_HAUL_CAPTURE_WALL") then
        game:startRun(3)
        local targetLevel = tonumber(os.getenv("LAST_HAUL_WALL_LEVEL")) or 3
        while game.world.wall.level < targetLevel do game.world:upgradeWall() end
        game.player.x, game.player.y = 1450, 1390
        game.camera.x, game.camera.y = 1600, 1325
    end
    if os.getenv("LAST_HAUL_CAPTURE_REPAIR") then
        game:startRun(3)
        game.world.wall.hp = 90
        game.wood, game.stone = 8, 8
        game.player.x, game.player.y = 1600, game.world.wall.y + 105
        game.camera.x, game.camera.y = game.player.x, game.player.y
        game.player:beginWallRepair(game.world, game)
    end
end

function love.update(dt)
    game:update(math.min(dt, 1 / 20))
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
