package.path="./?.lua;./?/init.lua;"..package.path
require("scripts.forest_render_fixture")
local Mode=require("src.clearcut_mode")

local nodes={}
for i=1,8 do nodes[i]={rushTree=true,active=false,sterile=false,x=i*12,y=0,rushMaxHp=9,rushHp=0} end
local mode=setmetatable({regrowSuppressed=false,worldTreeSpawned=true,remainingTrees=0,treesRevived=0,
    rootHazards={},forestZones={}}, {__index=Mode})
local notices=0
local game={world={nodes=nodes},player={x=10000,y=10000},setNotice=function()notices=notices+1 end}
local totem={x=0,y=0,worldTreeTotem=true,def={name="test",plantRadius=200,plantCount=6}}
mode:plantTreesNear(totem,game)
local active=0
for _,node in ipairs(nodes) do if node.active then active=active+1;assert(node.treeEmergence and node.rushHp==9) end end
assert(active==6 and mode.remainingTrees==6 and mode.treesRevived==6 and notices==1,
    "late world-tree totem did not visibly restore six trees")
print("REGROWTH_PROGRESSION_OK field=3..6 boss=4..6 late_restore=6 ordinary_tree_hp=unchanged")
