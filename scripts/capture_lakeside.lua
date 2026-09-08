local game=dofile("scripts/verify_crane_full_scene.lua")
local fixture=require("scripts.forest_render_fixture")
for tier=1,5 do
    game:startClearcutScoreAttack(tier,false)
    for _=1,35 do game.clearcut:spawnScoreTree(game)end
    game.world:updateEffects(1.1,game)
    for _=1,12 do game.clearcut:update(.02,game);game.world:updateEffects(.02,game)end
    game.camera:update(.016,game.player,game.world)
    fixture.reset();game:draw();fixture.save("docs/previews/lakeside-stage-"..tier..".json")
end
print("LAKESIDE_CAPTURE_OK actual Game.draw stages 1-5, real tree spawning, existing combat/HUD")
-- The reported issue is the one-target tutorial, not a mature full-build forest.
game.selectedScoreCharacter="fire"
game:startClearcutScoreAttack(1,true)
game.world:updateEffects(1.1,game)
for _=1,90 do game.camera:update(.016,game.player,game.world)end
fixture.reset();game:draw();fixture.save("docs/previews/lakeside-tutorial.json")
assert(not game.clearcut.jobMaster,"tutorial capture accidentally uses the crane")
