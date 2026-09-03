local Benchmark={FILE="stress_benchmark.txt",TARGET_TREES=100}
Benchmark.__index=Benchmark

local function count(list)return #(list or{})end
local function activeTrees(mode)
    local total=0
    for _,node in ipairs((mode.mapWorld and mode.mapWorld.nodes)or{})do
        if node.rushTree and node.active and not node.giantTree then total=total+1 end
    end
    return total
end

local function restoreTargets(mode)
    local total=0
    for _,node in ipairs((mode.mapWorld and mode.mapWorld.nodes)or{})do
        if node.rushTree and not node.giantTree then
            total=total+1
            if not node.active then
                node.active,node.respawn,node.fallT,node.treeEmergence=true,math.huge,nil,nil
                node.burning,node.burnTimer=nil,nil
            end
            node.rushHp,node.rushMaxHp=1000000,1000000
        end
    end
    mode.remainingTrees=total
end

function Benchmark.percentile(values,fraction)
    if #values==0 then return 0 end
    local copy={};for index,value in ipairs(values)do copy[index]=value end
    table.sort(copy)
    return copy[math.max(1,math.min(#copy,math.ceil(#copy*fraction)))]
end

function Benchmark.new(game)
    game.scorePracticeMaxed=true
    game.scorePracticeSpawnRate=8
    game:startClearcutSandbox("fire")
    local mode=game.clearcut
    mode.oilDrumTimer=0
    local attempts=0
    while activeTrees(mode)<Benchmark.TARGET_TREES and attempts<500 do
        attempts=attempts+1
        mode:spawnScoreTree(game)
    end
    assert(activeTrees(mode)>=Benchmark.TARGET_TREES,"stress benchmark could not place 100 active trees")
    game.scorePracticeSpawnRate,mode.scorePracticeSpawnRate=.25,.25
    mode.treeSpawnAccumulator=-1000000
    restoreTargets(mode)
    local burned=0
    for _,node in ipairs(game.world.nodes)do
        if node.rushTree and node.active and burned<25 then mode:beginTreeBurn(node,0);burned=burned+1 end
    end
    love.mouse.setPosition(love.graphics.getWidth()/2+300,love.graphics.getHeight()/2)
    local originalIsDown=love.mouse.isDown
    love.mouse.isDown=function(button)return button==1 or originalIsDown(button)end
    collectgarbage("collect")
    return setmetatable({mode=mode,elapsed=0,warmup=5,duration=math.max(10,tonumber(os.getenv("LAST_HAUL_STRESS_SECONDS"))or 20),
        frames={},updateTimes={},drawTimes={},originalIsDown=originalIsDown,
        memoryStart=collectgarbage("count"),memoryMax=0,maxima={}},Benchmark)
end

function Benchmark:recordUpdate(seconds)self.updateTimes[#self.updateTimes+1]=seconds end
function Benchmark:recordDraw(seconds)self.drawTimes[#self.drawTimes+1]=seconds end

function Benchmark:beforeUpdate(game)
    local mode=self.mode
    restoreTargets(mode)
    for _,bomb in ipairs(mode.monkeyBombs or{})do if bomb.state=="unlit"then bomb.state,bomb.fuse="lit",0 end end
    require("src.popping_machine").igniteInRadius(mode,game.player.x,game.player.y,10000)
    require("src.pizza_oven").igniteInRadius(mode,game.player.x,game.player.y,10000)
    for _,spot in ipairs(mode.oilTrail or{})do if not spot.ignited then mode:igniteOilTrail(spot,game)end end
end

function Benchmark:afterUpdate(dt,game)
    self.elapsed=self.elapsed+dt
    restoreTargets(self.mode)
    if self.elapsed>=self.warmup then
        self.frames[#self.frames+1]=dt
        self.memoryMax=math.max(self.memoryMax,collectgarbage("count"))
        local mode=self.mode
        local values={trees=activeTrees(mode),nodes=count(game.world.nodes),drops=count(game.world.drops),
            particles=count(game.world.particles),popups=count(game.world.popups),
            oil=count(mode.oilTrail),bombs=count(mode.monkeyBombs),explosions=count(mode.bombExplosions),
            projectiles=count(mode.smokerWeaponProjectiles),puffShots=count(mode.puffedRiceShots)}
        for key,value in pairs(values)do self.maxima[key]=math.max(self.maxima[key]or 0,value)end
    end
    if self.elapsed<self.warmup+self.duration then return false end
    love.mouse.isDown=self.originalIsDown
    collectgarbage("collect")
    local total=0;for _,dtValue in ipairs(self.frames)do total=total+dtValue end
    local average=#self.frames/math.max(.000001,total)
    local p95=Benchmark.percentile(self.frames,.95)*1000
    local p99=Benchmark.percentile(self.frames,.99)*1000
    local worst=Benchmark.percentile(self.frames,1)*1000
    local memoryEnd=collectgarbage("count")
    local audit=self.mode.actionAudit or{}
    local automation=(self.maxima.bombs or 0)>0 and(self.maxima.oil or 0)>0 and(self.mode.pizzaOven~=nil)
        and count(self.mode.poppingMachines)>0 and count(self.mode.moleCompanions)>0
    local passed=average>=50 and p95<=25 and(self.maxima.trees or 0)>=Benchmark.TARGET_TREES and automation
    local report=table.concat({
        "LAST HAUL 100-TREE FULL-BUILD STRESS BENCHMARK",
        string.format("status=%s",passed and"PASS"or"FAIL"),
        string.format("duration_sec=%.1f warmup_sec=%.1f measured_frames=%d",self.duration,self.warmup,#self.frames),
        string.format("avg_fps=%.1f p95_frame_ms=%.2f p99_frame_ms=%.2f worst_frame_ms=%.2f",average,p95,p99,worst),
        string.format("p95_update_ms=%.2f p95_draw_submit_ms=%.2f",Benchmark.percentile(self.updateTimes,.95)*1000,Benchmark.percentile(self.drawTimes,.95)*1000),
        string.format("memory_start_mb=%.2f memory_end_mb=%.2f memory_peak_mb=%.2f",self.memoryStart/1024,memoryEnd/1024,self.memoryMax/1024),
        string.format("max_active_trees=%d max_nodes=%d max_drops=%d max_particles=%d max_popups=%d",self.maxima.trees or 0,self.maxima.nodes or 0,self.maxima.drops or 0,self.maxima.particles or 0,self.maxima.popups or 0),
        string.format("max_oil=%d max_bombs=%d max_explosions=%d max_projectiles=%d max_puff_shots=%d",self.maxima.oil or 0,self.maxima.bombs or 0,self.maxima.explosions or 0,self.maxima.projectiles or 0,self.maxima.puffShots or 0),
        string.format("flame_hit_ticks=%d bomb_explosions=%d companions=%d poppers=%d oven=%s",audit.flameTick or 0,audit.bombExplosion or 0,count(self.mode.moleCompanions),count(self.mode.poppingMachines),tostring(self.mode.pizzaOven~=nil)),
        "threshold=avg_fps>=50 p95_frame_ms<=25 active_trees>=100 all_automation_active",
    },"\n").."\n"
    assert(love.filesystem.write(Benchmark.FILE,report),"could not write stress benchmark report")
    print(report)
    love.event.quit(passed and 0 or 1)
    return true
end

return Benchmark
