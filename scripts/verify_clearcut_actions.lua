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
physical:updatePhysicalAttack(physical.physicalAction.dur * .67, physicalGame, true)
assert(impacts == 0, "physical impact fired before axe contact frame")
physical:updatePhysicalAttack(physical.physicalAction.dur * .02, physicalGame, true)
assert(impacts == 1 and physical.actionAudit.physicalImpact == 1, "physical impact did not fire once on contact")

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
local bites = 0
vegan.applyVeganBite = function() bites = bites + 1 end
vegan:updateToxicAttack(0, veganGame, true)
vegan:updateToxicAttack(vegan.veganAction.dur * .54, veganGame, true)
assert(bites == 0, "vegan damage fired before bite frame")
vegan:updateToxicAttack(vegan.veganAction.dur * .02, veganGame, true)
assert(bites == 1 and vegan.actionAudit.veganBite == 1, "vegan bite did not fire exactly once")

local developer, developerGame = ClearcutMode.new(), gameWithTree()
developer.job = "developer"
local remotePresses = 0
developer.startDash = function() remotePresses = remotePresses + 1 end
developer:updateDeveloperAttack(0, developerGame, true)
developer:updateDeveloperAttack(developer.developerAction.dur * .57, developerGame, true)
assert(remotePresses == 0, "developer dash fired before remote press frame")
developer:updateDeveloperAttack(developer.developerAction.dur * .02, developerGame, true)
assert(remotePresses == 1 and developer.actionAudit.developerRemote == 1, "developer remote did not trigger dash exactly once")

print("CLEARCUT_ACTION_TIMING_OK")
