package.path="./?.lua;./?/init.lua;"..package.path

love={graphics={newImage=function()return{setFilter=function()end,getDimensions=function()return 960,224 end}end,
    newQuad=function()return{}end,setColor=function()end,draw=function()end},timer={getTime=function()return 1 end}}

local Vines=require("src.biome_vines")
local world={width=3200,height=2000,clearcutMap="forest",playBounds={x=400,y=300,w=2400,h=1400},nodes={}}
for y=430,1570,190 do for x=520,2680,210 do
    world.nodes[#world.nodes+1]={x=x,y=y,rushTree=true,active=true}
end end
local leaves=0;world.addLeafParticle=function()leaves=leaves+1 end
local data=Vines.generate(world,2)
assert(#data.attached>=8 and #data.attached<=14,"world vines are missing or over-dense")
assert(#data.ground>=5 and #data.ground<=9,"ground vine clusters are missing or over-dense")

local patch=data.ground[1]
local sounds=0
local player={x=patch.x-10,y=patch.y,isMoving=true}
local game={feedback={play=function(_,kind)if kind=="grass"then sounds=sounds+1 end end}}
Vines.update(world,player,.016,game);player.x=patch.x+5;Vines.update(world,player,.016,game)
assert(patch.rustle>0 and patch.bend==1 and sounds==1,"walking through world vines has no rustle response")
assert(Vines.cutRadius(world,patch.x,patch.y,12,game)==1 and patch.cut,"ground vine did not stay cut")
assert(leaves==4,"cut vine did not shed leaf pixels")

local queue={};Vines.queue(world,queue,player,1)
assert(#queue==#data.attached+#data.ground,"world vine actors were not depth queued")
assert(queue[1].anchorY==data.attached[1].node.y and queue[1].sortBias>0,"tree vine is not attached after its host")
for _,item in ipairs(queue)do assert(type(item.x)=="number"and type(item.y)=="number"and type(item.draw)=="function")end

local gameSource=assert(io.open("src/game.lua","rb")):read("*a")
assert(not gameSource:find("BiomeCanopy",1,true),"screen-space canopy is still connected")
local worldSource=assert(io.open("src/world.lua","rb")):read("*a")
assert(worldSource:find("BiomeVines.queue",1,true),"world-space vines are not in the actor pass")
print(string.format("BIOME_VINES_OK attached=%d ground=%d screen_overlay=removed rustle=cut",#data.attached,#data.ground))
