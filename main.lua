local Game
local game
local captureFrames = (os.getenv("LAST_HAUL_CAPTURE") or os.getenv("LAST_HAUL_CAPTURE_GAME") or os.getenv("LAST_HAUL_CAPTURE_FARM") or os.getenv("LAST_HAUL_CAPTURE_MINE")) and 30 or nil

function love.load()
    love.graphics.setDefaultFilter("linear", "linear", 4)
    love.graphics.setLineStyle("smooth")
    Game = require("src.game")
    game = Game.new()
    if os.getenv("LAST_HAUL_SELF_TEST") then
        require("src.selftest").run(game)
        love.event.quit()
        return
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
