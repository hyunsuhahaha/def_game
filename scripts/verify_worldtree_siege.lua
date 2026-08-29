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
local groundedPose=Art.pose(e,0)
assert(groundedPose.groundSink==36 and groundedPose.y==groundedPose.footY+36,"worldtree roots were not sunk into the ground")
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
local draw
for i=#fixture.commands,1,-1 do if fixture.commands[i].file then draw=fixture.commands[i];break end end
assert(draw.file==catalog.worldtree.file and draw.filter=="nearest","runtime did not draw siege atlas with nearest")
local shadows,soilLip=0,0
for _,command in ipairs(fixture.commands)do
    if command.op=="ellipse" then shadows=shadows+1;assert(command.args[3]<=142,"worldtree shadow expanded beyond root contact")end
    if command.op=="rectangle" then soilLip=soilLip+1 end
end
assert(shadows==3 and soilLip>=7,"worldtree grounding shadow/soil lip missing")
local game={world=mode.mapWorld,player=mode.mapPlayer,setNotice=function()end}
local before=#mode.enemies
mode:spawnWorldTreeGuards(e,game)
assert(#mode.enemies==before+2,"worldtree did not summon plant guards")
for i=before+1,#mode.enemies do assert(mode.enemies[i].kind=="vineSprout" or mode.enemies[i].kind=="turret","worldtree summoned an animal") end
local cameraMode=ClearcutMode.new();cameraMode.mapId="forest";cameraMode.stage=1
local cameraWorld={width=3200,height=2200,stageZoom=.84,playBounds={x=400,y=300,w=2400,h=1400}}
cameraMode.mapWorld=cameraWorld;cameraMode.mapPlayer={x=720,y=520}
local camera={userZoom=1,zoom=.84,renderZoom=.84,trauma=0,focus=function(self,x,y,duration,zoom)self.focused={x=x,y=y,duration=duration,zoom=zoom}end}
local cameraGame={world=cameraWorld,player=cameraMode.mapPlayer,camera=camera,setNotice=function()end}
cameraMode:spawnWorldTree(cameraGame)
assert(cameraMode.worldTreeCamera and camera.focused and camera.scriptedWideView,"worldtree did not start wide-view transition")
local rising=cameraMode.worldTree
assert(rising.x==1600 and rising.y==1000,"worldtree did not spawn at the playable-map center")
assert(cameraMode.worldTreeEmergence and rising.worldTreeEmerging and rising.entranceOffsetY==1320,"worldtree emergence did not start underground")
assert(cameraMode.worldTreeEmergence.duration==3.35 and rising.worldTreeEmergenceProgress==0,"cinematic emergence timing drift")
rising.hp=rising.maxHp-100
Siege.updateBoss(cameraMode,rising,.4,cameraGame)
assert(rising.hp==rising.maxHp and rising.entranceOffsetY<1320 and rising.worldTreeEmergenceProgress>0,"emergence rise or invulnerability regressed")
fixture.reset();Art.drawBody(rising,0)
local segmented=0
for _,command in ipairs(fixture.commands)do if command.file==catalog.worldtree.file then segmented=segmented+1 end end
assert(segmented==5,"worldtree emergence was not split into staggered full-height ribbons")
fixture.reset();local emergenceQueue={};Siege.queue(cameraMode,emergenceQueue)
assert(#emergenceQueue==2,"worldtree crack and foreground dirt layers missing")
for _,entry in ipairs(emergenceQueue)do entry.draw()end
local fxDraw=false for _,command in ipairs(fixture.commands)do if command.file and command.file:find("boss%-entrance%-fx")then fxDraw=true end end
assert(fxDraw,"authored root-crack emergence FX was not drawn")
cameraMode:updateWorldTreeCamera(.8,cameraGame)
assert(math.abs(camera.userZoom-.52)<.0001 and math.abs(camera.zoom-.84*.52)<.0001,"worldtree did not use ctrl-wheel zoom path")
local Camera=require("src.camera")
love.graphics.getDimensions=function()return 1280,720 end
local stageWorld={width=3200,height=2000,playBounds={x=400,y=300,w=2400,h=1400}}
local narrow=Camera.new(1600,1000);narrow.perspective=true;narrow.pitch=.86;narrow.zoom=.84*.52;narrow.userZoom=.52
local wide=Camera.new(1600,1000);wide.perspective=true;wide.pitch=.86;wide.zoom=.84*.52;wide.userZoom=.52;wide.scriptedWideView=true
narrow:update(.1,{x=1600,y=1000},stageWorld);wide:update(.1,{x=1600,y=1000},stageWorld)
assert(wide.renderZoom<narrow.renderZoom,"stage fit still cancelled the worldtree view expansion")
local emergenceState=cameraMode.worldTreeEmergence
for _=1,12 do Siege.updateBoss(cameraMode,rising,.25,cameraGame) end
assert(not cameraMode.worldTreeEmergence and not rising.worldTreeEmerging and not rising.entranceOffsetY,"worldtree emergence did not settle")
assert(emergenceState.crownBreach and emergenceState.trunkImpact and emergenceState.canopyBurst and emergenceState.impact,
    "worldtree emergence beats did not all fire")
assert(#(cameraMode.worldTreeDebris or {})==22,"canopy opening did not shed authored leaves")
cameraMode:restoreWorldTreeCamera(cameraGame)
assert(camera.userZoom==1 and math.abs(camera.zoom-.84)<.0001 and not camera.scriptedWideView,"worldtree view did not restore user zoom")
print("WORLDTREE_SIEGE_OK fixed=true centered=playBounds emergence=crown+ribbons+root_impact duration=3.35 no_cut_section=true invulnerable=true grounded=36 contact_shadow=root_lobes atlas=1024 display=820 stages=4 leaves=62 branches=2 guards=plants zoom=.52_restore")
