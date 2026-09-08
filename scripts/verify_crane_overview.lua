local game=dofile("scripts/verify_job_master.lua")
local Builder=require("src.construction_worker")
local mode=game.clearcut
assert(game.camera.craneOverview and game.camera.perspective)
for _,size in ipairs({{960,540},{1280,720},{1920,1080}})do
    local w,h=size[1],size[2]
    love.graphics.getDimensions=function()return w,h end
    love.graphics.getWidth=function()return w end;love.graphics.getHeight=function()return h end
    for _,scale in ipairs({1,2,4})do
        local world={width=3200*scale,height=2000*scale}
        game.camera:update(0,game.player,world)
        local x,y,z=game.camera.x,game.camera.y,game.camera.zoom
        for _,p in ipairs({{x-100,y-60},{x+100,y+60}})do
            local sx,sy=game.camera:worldToScreen(p[1],p[2])
            assert(game.camera.x==game.player.x and game.camera.y==game.player.y,"camera lost operator")
            local wx,wy=game.camera:screenToWorld(sx,sy)
            assert(math.abs(wx-p[1])<.01 and math.abs(wy-p[2])<.01,"overview aim inverse drift")
        end
        game.camera:update(.5,{x=world.width,y=0},world)
        assert(game.camera.x==world.width and game.camera.y==0 and game.camera.zoom==z,"camera must follow without map-fit zoom")
    end
end
love.graphics.getDimensions=function()return 1280,720 end
love.graphics.getWidth=function()return 1280 end;love.graphics.getHeight=function()return 720 end
game.camera:update(0,game.player,game.world)
mode.enemies={};game.world.nodes={}
game.player.x,game.player.y=game.world.width/2,game.world.height/2
mode.construction.stats=Builder.stats(game.characterTraits)
mode.construction.loads={};mode.construction.flyingTrees={};mode.construction.cooldown=0
local trees={}
for i=1,3 do
    local node={kind="tree",rushTree=true,active=true,x=game.player.x+300+i*90,y=game.player.y,rushHp=5,rushMaxHp=5,treeVariant=1}
    trees[i]=node;game.world.nodes[i]=node
end
local score=mode.treesFelled
Builder.update(mode,game,.8,true,game.player.x+1000,game.player.y)
assert(mode.treesFelled==score+3 and #mode.construction.flyingTrees==3,"rolling material did not launch three destroyed trees")
for _,n in ipairs(trees)do assert(not n.active and n.uprooted and not n.fallT,"duplicate standing/falling tree")end
local flying=mode.construction.flyingTrees[1]
local rootX,rootY=trees[1].x,trees[1].y
Builder.update(mode,game,.4,false)
assert(flying.x>flying.startX and flying.height>0 and flying.height<=110 and flying.angle>0,"tree lacks low, heavy directional flight")
assert(trees[1].x==rootX and trees[1].y==rootY,"visual flight moved respawn roots")
Builder.update(mode,game,2,false)
assert(#mode.construction.flyingTrees==0 and mode.treesFelled==score+3,"flight leaked or scored twice")
print("CRANE_OVERVIEW_OK three-resolutions map-expansion stationary-camera aim-inverse rolling-three-kills flight+arc+spin roots-preserved once-only cleanup")
return game
