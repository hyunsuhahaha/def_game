package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local ClearcutMode=require("src.clearcut_mode")
local Art=require("src.forest_arcade_art")
local Siege=require("src.worldtree_siege")
local catalog=require("src.forest_arcade_catalog")

local mode=ClearcutMode.new()
mode.mapId="forest"
mode.mapWorld={width=3200,height=2200,playBounds={x=0,y=0,w=3200,h=2200},addParticle=function()end}
mode.mapPlayer={x=1600,y=1100}
local e=mode:spawnEnemy("worldtree",1600,850)
assert(e and e.def.immovable and e.def.speed==0 and e.def.radius==350,"worldtree is not a fixed large target")
assert(catalog.worldtree.siege and catalog.worldtree.cell==1024 and catalog.worldtree.width==820,"siege atlas catalog drift")
local x,y=e.x,e.y
e.knockTimer=1;e.knockVX=500;e.airborneT=.2;e.airborneDuration=1;e.airbornePeak=80
Siege.updateBoss(mode,e,.1,{world=mode.mapWorld})
assert(e.x==x and e.y==y and not e.knockTimer and not e.airborneT,"fixed worldtree moved")

local expected={{.9,1,3,0},{.7,4,6,12},{.45,7,9,33},{.2,10,12,64}}
for _,row in ipairs(expected) do
    e.hp=e.maxHp*row[1]
    local pose=Art.pose(e,0)
    assert(pose.frame>=row[2] and pose.frame<=row[3],"hp did not select damage-state frames")
    Siege.updateBoss(mode,e,.1,{world=mode.mapWorld})
    assert(#mode.worldTreeDebris>=row[4],"damage stage did not shed authored debris")
end
local branches=0
for _,d in ipairs(mode.worldTreeDebris) do if d.kind=="branch" then branches=branches+1 end end
assert(branches==2,"both large branch falls were not emitted")

local impactMode=ClearcutMode.new()
local damageTaken=0
function impactMode:damagePlayer(amount) damageTaken=damageTaken+amount end
impactMode.worldTreeDebris={{kind="branch",frame=6,x=200,y=200,h=1,vh=-50,vx=0,vy=0,
    angle=0,spin=0,life=2,scale=1,damage=24}}
local impactGame={player={x=220,y=200},camera={trauma=0}}
Siege.updateDebris(impactMode,.1,impactGame)
assert(damageTaken==24 and impactMode.worldTreeDebris[1].landed and impactMode.worldTreeDebris[1].hitPlayer,
    "falling branch impact did not damage player")
Siege.updateDebris(impactMode,.1,impactGame)
assert(damageTaken==24,"landed branch dealt repeated damage")

local missMode=ClearcutMode.new()
local missDamage=0
function missMode:damagePlayer(amount) missDamage=missDamage+amount end
missMode.worldTreeDebris={{kind="branch",frame=6,x=500,y=500,h=1,vh=-50,vx=0,vy=0,
    angle=0,spin=0,life=2,scale=1,damage=24}}
Siege.updateDebris(missMode,.1,{player={x=700,y=700},camera={trauma=0}})
assert(missDamage==0,"branch damaged player outside visible footprint")

fixture.reset();Art.drawBody(e,0)
local draw=fixture.commands[#fixture.commands]
assert(draw.file==catalog.worldtree.file and draw.filter=="nearest","runtime did not draw siege atlas with nearest")
local game={world=mode.mapWorld,player=mode.mapPlayer,setNotice=function()end}
local before=#mode.enemies
mode:spawnWorldTreeGuards(e,game)
assert(#mode.enemies==before+2,"worldtree did not summon plant guards")
for i=before+1,#mode.enemies do assert(mode.enemies[i].kind=="vineSprout" or mode.enemies[i].kind=="turret","worldtree summoned an animal") end
local cameraMode=ClearcutMode.new();cameraMode.mapId="forest";cameraMode.stage=1
local cameraWorld={width=3200,height=2200,stageZoom=.84,playBounds={x=0,y=0,w=3200,h=2200}}
cameraMode.mapWorld=cameraWorld;cameraMode.mapPlayer={x=1600,y=1100}
local camera={userZoom=1,zoom=.84,renderZoom=.84,trauma=0,focus=function(self,x,y,duration,zoom)self.focused={x=x,y=y,duration=duration,zoom=zoom}end}
local cameraGame={world=cameraWorld,player=cameraMode.mapPlayer,camera=camera,setNotice=function()end}
cameraMode:spawnWorldTree(cameraGame)
assert(cameraMode.worldTreeCamera and camera.focused,"worldtree did not start wide-view transition")
cameraMode:updateWorldTreeCamera(.8,cameraGame)
assert(math.abs(camera.userZoom-.68)<.0001 and math.abs(camera.zoom-.84*.68)<.0001,"worldtree did not use ctrl-wheel zoom path")
cameraMode:restoreWorldTreeCamera(cameraGame)
assert(camera.userZoom==1 and math.abs(camera.zoom-.84)<.0001,"worldtree view did not restore user zoom")
print("WORLDTREE_SIEGE_OK fixed=true atlas=1024 display=820 stages=4 leaves=62 branches=2 guards=plants zoom=.68_restore")
