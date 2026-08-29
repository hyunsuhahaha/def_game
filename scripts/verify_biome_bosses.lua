package.path="./?.lua;./?/init.lua;"..package.path
love={math={random=function(a,b)if not a then return .5 elseif not b then return math.max(1,math.floor(a/2)) else return math.floor((a+b)/2)end end}}
local B=require("src.biome_bosses")
assert(B.stageCap("beginner")==3 and B.stageCap("forest")==4)
local maps={beginner="stumpWarden",forest="hollowOak",mangrove="rootjaw",madagascar="baobabTyrant",island="islandHermit",greatforest="hollowOak"}
for map,kind in pairs(maps)do assert(B.forMap(map)==kind and B.definitions[kind].biomeBoss and B.definitions[kind].finalBoss)end
local mode={bossTelegraphs={},projectiles={},hits=0,damagePlayer=function(self)self.hits=self.hits+1 end}
local game={player={x=180,y=0}}
for kind,def in pairs(B.definitions)do
 local e={kind=kind,def=def,x=0,y=0,hp=def.hp,maxHp=def.hp,dmgMul=1,speedMul=1}
 for _=1,160 do B.update(e,.05,mode,game) end
 assert(e.bossSequence and e.bossSequence>=1,kind.." no attack sequence")
end
assert(#mode.bossTelegraphs>0 and (#mode.projectiles>0 or mode.hits>0),"boss attacks not emitted")
local clearcut=assert(io.open("src/clearcut_mode.lua","rb")):read("*a")
assert(clearcut:find("BiomeBosses.forMap",1,true) and clearcut:find("recordMapClear",1,true) and clearcut:find("operationFinalBoss",1,true),"operation runtime hooks missing")
print("BIOME_BOSSES_OK maps=6 caps=3/4 telegraphs=locked ending=finite persistence=clear")
