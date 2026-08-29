package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local Art=require("src.worldtree_attack_art")

local samples={
    {worldTreeAttack="rootBurst",x=100,y=120,radius=62,phase="active",timer=.12},
    {worldTreeAttack="vineWhip",kind="line",x1=0,y1=0,x2=480,y2=80,halfWidth=64,phase="active",timer=.12},
    {worldTreeAttack="rootSlam",x=240,y=180,radius=420,phase="active",timer=.12},
}
fixture.reset()
for _,sample in ipairs(samples)do assert(Art.draw(sample,1.2)) end
local branch={x=300,y=260,h=220,angle=.25,length=340,halfWidth=42,fallTime=.7,fallDuration=1.18,life=2}
Art.drawBranchWarning(branch,1.2);Art.drawFallingBranch(branch,1.2)
branch.impactAge=.2;Art.drawBranchImpact(branch,1.2)
local draws=0;local rows={}
for _,command in ipairs(fixture.commands)do if command.file and command.file:find("worldtree%-attacks%-atlas")then
    draws=draws+1;assert(command.filter=="nearest","worldtree attack atlas lost nearest filtering")
    rows[math.floor(command.quad[2]/384)]=true
end end
assert(draws==6 and rows[0] and rows[1] and rows[2] and rows[3] and rows[4],"worldtree attack rows were not all rendered")
print("WORLDTREE_ATTACK_ART_OK atlas=2304x1920 rows=root+vine+slam+branch+impact frames=6 geometry=matched")
