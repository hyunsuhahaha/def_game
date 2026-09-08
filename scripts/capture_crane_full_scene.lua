local game=dofile("scripts/verify_crane_full_scene.lua")
local fixture=require("scripts.forest_render_fixture")
local mode=game.clearcut
local sx,sy=game.camera:worldToScreen(game.player.x+1000,game.player.y)
love.mouse.getPosition=function()return sx,sy end
love.mouse.isDown=function(button)return button==1 end
for frame=0,15 do
    fixture.time=.24+frame*.08
    mode:update(.08,game);game.world:updateEffects(.08,game)
    game.camera:update(0,game.player,game.world)
    fixture.reset();game:draw()
    local flames=0
    for _,op in ipairs(fixture.commands)do
        if op.file=="assets/effects/smoker-flamethrower-stream-atlas-v5.png"then flames=flames+1 end
    end
    assert(flames==1,"automatic flame vanished during simultaneous crane attack")
    fixture.save("docs/previews/crane-full-scene-"..frame..".json")
end
assert(#mode.construction.loads>0,"full-scene capture omitted crane attacks")
print("CRANE_FULL_CAPTURE_OK simultaneous-crane+flamethrower all-automation real-Game.draw 16frames")
