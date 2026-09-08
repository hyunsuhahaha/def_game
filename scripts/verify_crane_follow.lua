local game=dofile("scripts/verify_job_master.lua")
local camera,world=game.camera,game.world
camera.craneOverview=true
camera.userZoom=1
camera:update(0,game.player,world)
assert(math.abs((world.stageZoom or .84)/camera.zoom-1.4)<.001)
game.player.x=game.player.x+400;game.player.y=game.player.y+150
camera:update(.016,game.player,world)
assert(camera.x==game.player.x and camera.y==game.player.y,"crane camera must follow operator")
camera.userZoom=.1;camera:update(0,game.player,world);assert(camera.userZoom==.9)
camera.userZoom=4;camera:update(0,game.player,world);assert(camera.userZoom==1.1)
local mode=game.clearcut
mode.scoreRegenTier=10;mode.scoreTierFx=nil
local allowance=mode.scoreTreeAllowance
local timed,pressure=mode.scoreTimedTreeSpawnRate,mode.scoreTimePressureMultiplier
mode.scoreTimedTreeSpawnRate=function()return 100 end
mode.scoreTimePressureMultiplier=function()return 1 end
local rate=mode:scoreTreeSpawnRate()
assert(mode:advanceScoreRegenTier(game,false,"world_tree"))
assert(mode.scoreTreeAllowance==allowance+80)
assert(math.abs(mode:scoreTreeSpawnRate()/rate-.45)<.001)
assert(require("src.score_operations").overcrowdGrace(mode)>=8)
mode.scoreTierFx=nil
mode:advanceScoreRegenTier(game,false,"world_tree")
assert(mode.scoreTreeAllowance==allowance+80,"capacity bonus repeated")
mode.scoreTimedTreeSpawnRate,mode.scoreTimePressureMultiplier=timed,pressure
print("CRANE_FOLLOW_OK follow limited-zoom tier11-rate capacity grace once-only")
