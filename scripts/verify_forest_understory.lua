package.path="./?.lua;./?/init.lua;"..package.path

math.randomseed(20260829)
love={
    math={random=math.random},
    graphics={
        setColor=function()end,setLineWidth=function()end,ellipse=function()end,circle=function()end,
        line=function()end,rectangle=function()end,push=function()end,pop=function()end,
        translate=function()end,rotate=function()end,draw=function()end
    }
}

local Understory=require("src.forest_understory")
local leaves,sounds=0,0
local world={width=1400,height=900,clearcutMap="forest",nodes={},addLeafParticle=function()leaves=leaves+1 end}
local data=Understory.generate(world,2)
assert(#data.patches>20,"temperate forest has no walk-through grass")

local first=data.patches[1]
local game={feedback={play=function(_,kind)if kind=="grass" then sounds=sounds+1 end end}}
local player={x=first.x-8,y=first.y,isMoving=true}
Understory.update(world,player,.016,game)
player.x=first.x+2
Understory.update(world,player,.016,game)
assert(first.rustle>0 and first.bend==1,"walking did not bend the grass with travel direction")
assert(sounds==1,"rustle sound was not throttled")

local count=Understory.cutRadius(world,first.x,first.y,10,game)
assert(count==1 and first.cut,"one hit did not permanently cut the tuft")
assert(leaves==3,"cut impact did not shed authored leaf debris")
Understory.update(world,{x=0,y=0,isMoving=false},120,game)
assert(first.cut and first.rustle==0,"cut grass regrew after time elapsed")
assert(Understory.cutRadius(world,first.x,first.y,10,game)==0,"cut grass accepted a second hit")

local other={width=1400,height=900,clearcutMap="mangrove",nodes={}}
assert(#Understory.generate(other,1).patches==0,"temperate grass leaked into a biome map")

local ClearcutMode=require("src.clearcut_mode")
local TreeDestruction=require("src.tree_destruction")
local giantFall=TreeDestruction.fallProfile(7,true)
assert(giantFall.duration>=1.8 and giantFall.reach>=230,"giant tree still uses the quick ordinary fall")
local mode=ClearcutMode.new()
mode.permanentTraits.treeVariety=0
local generated={width=1800,height=1200,clearcutMap="forest",nodes={},images={treeVariants={{},{},{},{}}}}
mode:generateForest({world=generated},40)
local giants=0
for _,node in ipairs(generated.nodes)do if node.giantTree then giants=giants+1 end end
assert(giants>=2 and giants<=3,"tall landmark density is not sparse and deterministic: "..giants)
assert(#generated.nodes==40,"tall landmarks changed the objective tree count")

print(string.format("FOREST_UNDERSTORY_OK patches=%d giants=%d leaves=%d",#data.patches,giants,leaves))
