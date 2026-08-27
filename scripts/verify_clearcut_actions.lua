package.path = "./?.lua;./?/init.lua;" .. package.path

love = {
    mouse = {isDown=function() return false end, getPosition=function() return 100, 0 end},
    math = {random=math.random},
    timer = {getTime=function() return 0 end}
}

local ClearcutMode = require("src.clearcut_mode")

local function gameWithTree()
    local player = {
        x=0, y=0, gather=1, facing=1,
        setClearcutAction=function(self, value) self.action=value end,
        clearClearcutAction=function(self) self.action=nil end,
        playAutoAxeSwing=function(self,targetX) self.autoAxeTarget=targetX end,
        cancelInteraction=function() end
    }
    return {
        player=player,
        tools={axe={speed=1}},
        camera={screenToWorld=function(_, x, y) return x, y end},
        world={nodes={{rushTree=true, active=true, x=50, y=0, rushHp=3, rushMaxHp=3}}}
    }
end

local physical, physicalGame = ClearcutMode.new(), gameWithTree()
physical.job = "physical"
local impacts = 0
physical.hitTree = function() impacts = impacts + 1 end
physical:updatePhysicalAttack(0, physicalGame, true)
assert(impacts==1 and physicalGame.player.autoAxeTarget==50,"held axe did not immediately hit/animate its target")
physical:updatePhysicalAttack(0,physicalGame,true)
assert(impacts==1,"held axe ignored its cooldown")
physical:updatePhysicalAttack(physical.axeCooldown+.01,physicalGame,true)
assert(impacts==2,"held axe did not repeat after cooldown")

local smoker, smokerGame = ClearcutMode.new(), gameWithTree()
smoker.job = "fire"
local flicks = 0
smoker.hurlMolotovAt = function() flicks = flicks + 1 end
smoker:startSmoking(smokerGame)
smoker:updateFireAttack(smoker.smoking.dur + .01, smokerGame, false)
smoker:updateFireAttack(0, smokerGame, true)
smoker:updateFireAttack(smoker.smoking.dur * .57, smokerGame, true)
assert(flicks == 0, "cigarette projectile fired before finger flick frame")
smoker:updateFireAttack(smoker.smoking.dur * .02, smokerGame, true)
assert(flicks == 1 and smoker.actionAudit.cigaretteFlick == 1, "cigarette did not fire exactly once on flick")

local vegan, veganGame = ClearcutMode.new(), gameWithTree()
vegan.job = "toxic"
local forkHits = 0
vegan.applyVeganFork = function() forkHits = forkHits + 1 end
vegan:updateToxicAttack(0, veganGame, true)
vegan:updateToxicAttack(vegan.veganAction.dur * .52, veganGame, true)
assert(forkHits == 0, "vegan fork damage fired before contact frame")
vegan:updateToxicAttack(vegan.veganAction.dur * .02, veganGame, true)
assert(forkHits == 1 and vegan.actionAudit.veganFork == 1, "vegan fork did not fire exactly once")

local developer, developerGame = ClearcutMode.new(), gameWithTree()
developer.job = "developer"
local remotePresses = 0
developer.startDash = function() remotePresses = remotePresses + 1 end
developer:updateDeveloperAttack(0, developerGame, true)
assert(remotePresses==1,"developer held attack did not immediately start its dash")
developer:updateDeveloperAttack(0,developerGame,false)
assert(remotePresses==1,"developer dash fired after input release")

print("CLEARCUT_ACTION_TIMING_OK")
