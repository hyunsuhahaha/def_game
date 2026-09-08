local game=dofile("scripts/verify_crane_full_scene.lua")
local fixture=require("scripts.forest_render_fixture")
game.characterTraits:unlockRegenTier(11)
game:startClearcutScoreAttack(10,false)
game.clearcut.scoreTierFx=nil
assert(game.clearcut:advanceScoreRegenTier(game,false,"capture"),"capture could not enter tier 11")
for _=1,84 do game.clearcut:spawnScoreTree(game)end
game.world:updateEffects(1.1,game)
for _=1,12 do game.clearcut:update(.02,game);game.world:updateEffects(.02,game)end
game.camera:update(.016,game.player,game.world)
fixture.reset();game:draw();fixture.save("docs/previews/upland-stage-11.json")
assert(game.world.upland and not game.world.lakeside and game.clearcut.construction,"stage 11 capture lost its upland crane field")
print("UPLAND_CAPTURE_OK actual Game.draw stage11 full-field growth crane HUD")
