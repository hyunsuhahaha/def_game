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
assert(e and e.def.immovable and e.def.speed==0 and e.def.radius==420,"worldtree is not a fixed extra-large target")
assert(catalog.worldtree.siege and catalog.worldtree.cell==1024 and catalog.worldtree.width==1050,"siege atlas catalog drift")
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
    Siege.updateBoss(mode,e,.1,{world=mode.mapWorld,player=mode.mapPlayer})
    assert(#mode.worldTreeDebris>=row[4],"damage stage did not shed authored debris")
end
local branches=0
for _,d in ipairs(mode.worldTreeDebris) do if d.kind=="branch" then
    branches=branches+1
    assert(d.length>=310 and d.halfWidth>=36 and d.x==mode.mapPlayer.x and d.y==mode.mapPlayer.y,
        "damage branch did not target the player with a long visible footprint")
end end
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
    if command.op=="ellipse" then shadows=shadows+1;assert(command.args[3]<=185,"worldtree shadow expanded beyond root contact")end
    if command.op=="rectangle" then soilLip=soilLip+1 end
end
assert(shadows==3 and soilLip>=7,"worldtree grounding shadow/soil lip missing")
local game={world=mode.mapWorld,player=mode.mapPlayer,setNotice=function()end}
local before=#mode.enemies
mode:spawnWorldTreeGuards(e,game)
assert(#mode.enemies==before+2,"worldtree did not summon plant guards")
for i=before+1,#mode.enemies do
    local guard=mode.enemies[i];local dx,dy=guard.x-e.x,guard.y-e.y
    assert(guard.kind=="vineSprout" or guard.kind=="turret","worldtree summoned an animal")
    assert(dx*dx+dy*dy>e.def.radius*e.def.radius,"larger worldtree hid a summoned guard inside its trunk")
end
local attackMode=ClearcutMode.new();local attackGame={player={x=520,y=200},setNotice=function()end}
attackMode:worldTreeRootSpikes(e,attackGame)
assert(#attackMode.bossTelegraphs==4 and attackMode.bossTelegraphs[1].worldTreeAttack=="rootBurst" and attackMode.bossTelegraphs[1].radius==62,
    "worldtree root burst did not use its dedicated footprint")
attackMode.bossTelegraphs={};attackMode:worldTreeVineWhip(e,attackGame)
local whip=attackMode.bossTelegraphs[1]
assert(whip and whip.worldTreeAttack=="vineWhip" and whip.halfWidth==64 and whip.x1~=e.x,"worldtree vine whip art/geometry drift")
attackMode.bossTelegraphs={};attackMode:bossSlam(e,attackGame)
assert(attackMode.bossTelegraphs[1].worldTreeAttack=="rootSlam" and attackMode.bossTelegraphs[1].radius==420,
    "worldtree slam did not use its dedicated root shockwave")
local cameraMode=ClearcutMode.new();cameraMode.mapId="forest";cameraMode.stage=1
local cameraWorld={width=3200,height=2200,stageZoom=.84,playBounds={x=400,y=300,w=2400,h=1400}}
cameraMode.mapWorld=cameraWorld;cameraMode.mapPlayer={x=720,y=520}
local camera={userZoom=1,zoom=.84,renderZoom=.84,trauma=0,mode="default",skyviewTarget=0,
    focus=function(self,x,y,duration,zoom)self.focused={x=x,y=y,duration=duration,zoom=zoom}end,
    setMode=function(self,mode,duration)self.mode=mode;self.skyviewTarget=mode=="skyview" and 1 or 0;self.skyDuration=duration end}
local cameraGame={world=cameraWorld,player=cameraMode.mapPlayer,camera=camera,setNotice=function()end}
cameraMode:spawnWorldTree(cameraGame)
assert(cameraMode.worldTreeCamera and camera.focused and camera.scriptedWideView and camera.allowWideUserZoom,"worldtree did not start zoom-out transition")
assert(camera.mode=="skyview" and camera.scriptedSkyviewBoss and camera.focused.y==720 and camera.focused.duration==3.35,
    "worldtree did not open and frame the skyview height reveal")
local rising=cameraMode.worldTree
assert(rising.x==1600 and rising.y==1000,"worldtree did not spawn at the playable-map center")
assert(cameraMode.worldTreeEmergence and rising.worldTreeEmerging and rising.entranceOffsetY==1720,"worldtree emergence did not start underground")
assert(cameraMode.worldTreeEmergence.duration==3.35 and rising.worldTreeEmergenceProgress==0,"cinematic emergence timing drift")
rising.hp=rising.maxHp-100
Siege.updateBoss(cameraMode,rising,.4,cameraGame)
assert(rising.hp==rising.maxHp and rising.entranceOffsetY<1720 and rising.worldTreeEmergenceProgress>0,"emergence rise or invulnerability regressed")
fixture.reset();Art.drawBody(rising,0)
local intact,warped=0,false
for _,command in ipairs(fixture.commands)do
    if command.file==catalog.worldtree.file then
        intact=intact+1
        warped=command.uniforms and (command.uniforms.emergenceWarp or 0)>0
    end
end
assert(intact==1 and warped,"worldtree emergence did not preserve and continuously bend one intact sprite")
fixture.reset();local emergenceQueue={};Siege.queue(cameraMode,emergenceQueue)
assert(#emergenceQueue==2,"worldtree crack and foreground dirt layers missing")
for _,entry in ipairs(emergenceQueue)do entry.draw()end
local fxDraw=false for _,command in ipairs(fixture.commands)do if command.file and command.file:find("boss%-entrance%-fx")then fxDraw=true end end
assert(fxDraw,"authored root-crack emergence FX was not drawn")
cameraMode:updateWorldTreeCamera(.8,cameraGame)
assert(math.abs(camera.userZoom-.52)<.0001 and math.abs(camera.zoom-.84*.52)<.0001,"worldtree did not use the normal Ctrl+wheel zoom floor")
camera.userZoom=.8;camera.zoom=.84*.8;cameraMode:updateWorldTreeCamera(.1,cameraGame)
assert(camera.userZoom==.8 and math.abs(camera.zoom-.84*.8)<.0001,"worldtree camera locked out user zoom control")
local Camera=require("src.camera")
love.graphics.getDimensions=function()return 1280,720 end
local stageWorld={width=3200,height=2000,playBounds={x=400,y=300,w=2400,h=1400}}
local narrow=Camera.new(1600,1000);narrow.perspective=true;narrow.pitch=.86;narrow.zoom=.84*.52;narrow.userZoom=.52
local wide=Camera.new(1600,1000);wide.perspective=true;wide.pitch=.86;wide.zoom=.84*.52;wide.userZoom=.52;wide.scriptedWideView=true;wide.allowWideUserZoom=true
narrow:update(.1,{x=1600,y=1000},stageWorld);wide:update(.1,{x=1600,y=1000},stageWorld)
assert(wide.renderZoom<narrow.renderZoom,"stage fit still cancelled the worldtree view expansion")
assert(math.abs(wide.renderZoom-.84*.52)<.0001,"worldtree camera fitting cancelled the user-style zoom-out")
local emergenceState=cameraMode.worldTreeEmergence
for _=1,12 do Siege.updateBoss(cameraMode,rising,.25,cameraGame) end
assert(not cameraMode.worldTreeEmergence and not rising.worldTreeEmerging and not rising.entranceOffsetY,"worldtree emergence did not settle")
assert(emergenceState.crownBreach and emergenceState.trunkImpact and emergenceState.canopyBurst and emergenceState.impact,
    "worldtree emergence beats did not all fire")
assert(#(cameraMode.worldTreeDebris or {})==22,"canopy opening did not shed authored leaves")
cameraMode:updateWorldTreeCamera(.1,cameraGame)
assert(camera.mode=="default" and not camera.scriptedSkyviewBoss and camera.skyDuration==.7,
    "worldtree skyview did not return after the root landing")
cameraMode:restoreWorldTreeCamera(cameraGame)
assert(camera.userZoom==1 and math.abs(camera.zoom-.84)<.0001 and not camera.scriptedWideView and not camera.allowWideUserZoom,"worldtree view did not restore user zoom")
print("WORLDTREE_SIEGE_OK fixed=true centered=playBounds emergence=intact_warp+crown+root_impact duration=3.35 no_cut_section=true invulnerable=true grounded=36 contact_shadow=root_lobes atlas=1024 display=1050 radius=420 attacks=root+vine+slam+targeted_branch stages=4 leaves=62 branches=2 guards=plants zoom=.52_user_control_restore")
