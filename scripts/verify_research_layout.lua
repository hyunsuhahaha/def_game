package.path="./?.lua;./?/init.lua;"..package.path
local Store=require("src.character_traits")
local Board=require("src.character_trait_board")
local store=Store.new(true)
local board=Board.new(store,{}, {})
local nodes=board:nodesFor("fire")
local Connections=require("src.research_connections")
local routes=Connections.new(nodes,function(n)return board:nodeWorld(n)end)
local edges,detours=0,0
for i,a in ipairs(nodes)do
    local x,y=board:nodeWorld(a)
    for j=i+1,#nodes do
        local b=nodes[j];local bx,by=board:nodeWorld(b)
        assert((x-bx)^2+(y-by)^2>=230^2,"Research spacing below 230: "..a.id.." / "..b.id)
    end
    for _,req in ipairs(store:getRequirements(a))do
        local path=routes:path(req[1],a.id);edges=edges+1
        if #path>2 then detours=detours+1 end
        assert(routes:path(req[1],a.id)==path,"Connection path is not cached")
        for k=1,#path-1 do for _,other in ipairs(nodes)do
            if other.id~=a.id and other.id~=req[1]then
                local ox,oy=board:nodeWorld(other)
                assert(not Connections.intersects(path[k],path[k+1],{ox,oy}),"Connection crosses node: "..req[1].." -> "..a.id.." / "..other.id)
            end
        end end
    end
end
local rx,ry=board:nodeWorld(store:getNode("fire_score_prewarm"))
for _,id in ipairs({"universal_robot_start","universal_mole_companion","universal_oil_drum"})do
    local x,y=board:nodeWorld(store:getNode(id))
    assert((x-rx)^2+(y-ry)^2<1400^2,"Early automation is too far from the root: "..id)
end
assert(#nodes==101,"Layout unexpectedly changed the active research count")
local Preview=require("src.research_preview")
local encoded=Store.encode(store.data)
local previews=0
for _,node in ipairs(nodes)do if node.rankEffects then
    for rank=0,node.max-1 do
        assert(Preview.describe(node,rank),"Missing compact rank preview: "..node.id.." / "..rank)
        previews=previews+1
    end
    assert(not Preview.describe(node,node.max),"Completed research promises another upgrade")
end end
assert(encoded==Store.encode(store.data),"Preview altered the saved profile")
assert(Preview.describe(store:getNode("fire_score_filter"),6):find("비행 속도 +7%",1,true),"Mixed rank preview reports the preceding effect")
assert(Preview.describe(store:getNode("fire_score_autothrow"),1):find("2.6 → 2.39초",1,true),"Automatic interval preview differs from gameplay")
assert(Preview.describe(store:getNode("universal_gray_cat_chance"),2):find("75 → 95%",1,true),"Cat preview ignores the runtime probability cap")
assert(Preview.describe(store:getNode("universal_mole_claw"),2):find("양손 공격 해금",1,true),"Milestone unlock is missing")
print("RESEARCH_LAYOUT_OK nodes="..#nodes.." min-spacing=230 edges="..edges.." detours="..detours)
print("RESEARCH_PREVIEW_OK ranks="..previews.." save=unchanged")
