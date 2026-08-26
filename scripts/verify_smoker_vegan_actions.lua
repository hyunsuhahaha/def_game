package.path="./?.lua;./?/init.lua;"..package.path

local aimX=100
love={
    mouse={isDown=function() return false end,getPosition=function() return aimX,0 end},
    math={random=math.random},timer={getTime=function() return 0 end}
}

local ClearcutMode=require("src.clearcut_mode")

local function gameStub()
    local player={x=0,y=0,gather=1,facing=1,action=nil,
        setClearcutAction=function(self,p) self.action=p end,
        clearClearcutAction=function(self) self.action=nil end}
    return {player=player,tools={axe={speed=1}},camera={screenToWorld=function(_,x,y) return x,y end},world={nodes={}}}
end

local smoker,smokerGame=ClearcutMode.new(),gameStub()
smoker.job="fire"
local shots=0
smoker.hurlMolotovAt=function() shots=shots+1 end
smoker:startSmoking(smokerGame)
smoker:updateFireAttack(smoker.smoking.dur*.5,smokerGame,false)
assert(smokerGame.player.action and smokerGame.player.action>0 and smokerGame.player.action<.5,"smoking reload no longer drives the action row")
smoker:updateFireAttack(smoker.smoking.dur,smokerGame,false)
assert(smoker.smoking.phase=="loaded" and smokerGame.player.action==nil,"smoker did not return to always-lit walk pose")
smoker:updateFireAttack(0,smokerGame,true)
assert(smoker.smoking.phase=="flick" and smokerGame.player.action==.5,"click did not enter the cigarette flick poses")
smoker:updateFireAttack(smoker.smoking.dur*.59,smokerGame,true)
assert(shots==1 and smoker.actionAudit.cigaretteFlick==1,"cigarette release frame did not fire exactly once")

local vegan,veganGame=ClearcutMode.new(),gameStub()
vegan.job="toxic"
local bites=0
vegan.applyVeganBite=function() bites=bites+1 end
vegan:updateToxicAttack(0,veganGame,true)
assert(vegan.veganAction and veganGame.player.action==0,"vegan grab/eat animation did not start")
vegan:updateToxicAttack(vegan.veganAction.dur*.54,veganGame,true)
assert(bites==0 and veganGame.player.action>.5,"vegan dealt damage before the bite pose")
vegan:updateToxicAttack(vegan.veganAction.dur*.02,veganGame,true)
assert(bites==1 and vegan.actionAudit.veganBite==1,"vegan bite pose did not deal damage exactly once")

print("SMOKER_VEGAN_ACTIONS_OK")
