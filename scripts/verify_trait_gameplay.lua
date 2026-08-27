package.path="./?.lua;./?/init.lua;"..package.path

love={
    math={random=function(a,b) if a and b then return a elseif a then return 1 end return .99 end},
    mouse={isDown=function() return false end,getPosition=function() return 0,0 end},
    timer={getTime=function() return 0 end},
    graphics={setColor=function() end,setLineWidth=function() end,line=function(points)
            if type(points)=="table" then assert(#points%2==0,"Number of vertex components must be a multiple of two.") end
        end,circle=function() end,
        rectangle=function() end,polygon=function() end,push=function() end,pop=function() end,
        translate=function() end,rotate=function() end}
}

local ClearcutMode=require("src.clearcut_mode")
local TraitFx=require("src.trait_fx")

local function world(nodes)
    return {nodes=nodes,impactNode=function() end,igniteFx=function() end,addParticle=function() end,
        spawnDrop=function() end,harvestBurst=function() end}
end

local game={player={x=0,y=0,gather=1,
    setClearcutAction=function(self,progress) self.action=progress end,
    clearClearcutAction=function(self) self.action=nil end},
    tools={axe={speed=1}},world=world({}),camera={trauma=0,screenToWorld=function() return 0,0 end},setNotice=function() end}

local physical=ClearcutMode.new()
physical.job="physical"
physical.permanentTraits.extraTargets=2
physical.permanentTraits.treeDamage=1
physical.damageEnemiesInRadius=function() end
physical.checkMilestones=function() end
game.world=world({
    {rushTree=true,active=true,x=30,y=0,rushHp=5,rushMaxHp=5},
    {rushTree=true,active=true,x=45,y=10,rushHp=5,rushMaxHp=5},
    {rushTree=true,active=true,x=60,y=-8,rushHp=5,rushMaxHp=5}
})
physical:hitTree(game.world.nodes[1],game)
assert(game.world.nodes[1].rushHp==3 and game.world.nodes[2].rushHp==3 and game.world.nodes[3].rushHp==3,"logger multi-target/damage traits are not live")

local fire=ClearcutMode.new()
fire.job="fire"; fire.elapsed=1; fire.permanentTraits.extraFires=2; fire.permanentTraits.area=15
game.world=world({})
fire:hurlMolotovAt(120,40,game,false)
assert(#fire.molotovs==3 and fire.molotovs[1].radius>=105,"smoker extra ember/area traits are not live")

local vegan=ClearcutMode.new()
vegan.job="toxic"; vegan.aimRadius=80; vegan.permanentTraits.extraTargets=2; vegan.permanentTraits.biteDamage=2; vegan.permanentTraits.range=30
vegan.damageEnemiesInRadius=function() end; vegan.checkMilestones=function() end
game.world=world({
    {rushTree=true,active=true,x=20,y=0,rushHp=8,rushMaxHp=8},
    {rushTree=true,active=true,x=100,y=0,rushHp=8,rushMaxHp=8},
    {rushTree=true,active=true,x=130,y=0,rushHp=8,rushMaxHp=8}
})
game.camera.screenToWorld=function() return 140,0 end
vegan:updateToxicAttack(0,game,true)
vegan:updateToxicAttack(vegan.veganAction.dur*.56,game,true)
for _,node in ipairs(game.world.nodes) do assert(node.rushHp==4,"vegan extra fork/damage traits are not live") end

local developer=ClearcutMode.new()
developer.job="developer"; developer.permanentTraits.aftershockRadius=30
developer.damageEnemiesInRadius=function() end; developer.checkMilestones=function() end
game.world=world({{rushTree=true,active=true,x=50,y=0,rushHp=3,rushMaxHp=3}})
developer:traitAftershock(0,0,game)
assert(game.world.nodes[1].rushHp==2 and #developer.traitFx.events>0,"developer aftershock trait is not live")

local fx=TraitFx.new()
for _,kind in ipairs({"axe","fire","bite","heal","dash","blast","refund"}) do fx:emit(kind,0,0,{particles=2}) end
local rendered,renderError=pcall(fx.draw,fx)
assert(rendered,"high-resolution trait effect renderer failed: "..tostring(renderError))
print("TRAIT_GAMEPLAY_OK")
