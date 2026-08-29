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
local camera={userZoom=1,zoom=.84,renderZoom=.84,trauma=0,mode="default",skyviewTarget=0,skyviewBlend=1,
    focus=function(self,x,y,duration,zoom)self.focused={x=x,y=y,duration=duration,zoom=zoom}end,
    setMode=function(self,mode,duration)self.mode=mode;self.skyviewTarget=mode=="skyview" and 1 or 0;self.skyDuration=duration end}
local cameraGame={world=cameraWorld,player=cameraMode.mapPlayer,camera=camera,setNotice=function()end}
cameraMode:spawnWorldTree(cameraGame)
assert(cameraMode.worldTreeCamera and camera.focused and not camera.scriptedWideView and not camera.allowWideUserZoom,"worldtree changed camera zoom fitting")
assert(camera.mode=="skyview" and camera.scriptedSkyviewBoss and camera.focused.y==920 and camera.focused.duration==7.2,
    "worldtree did not open and frame the skyview height reveal")
local rising=cameraMode.worldTree
assert(camera.focused.y==rising.y-80 and camera.focused.zoom==.96,"worldtree emergence camera moved back into the oversized near field")
assert(rising.x==1600 and rising.y==1000,"worldtree did not spawn at the playable-map center")
assert(cameraMode.worldTreeEmergence and rising.worldTreeEmerging and rising.entranceOffsetY==1720,"worldtree emergence did not start underground")
assert(cameraMode.worldTreeEmergence.duration==6.75 and cameraMode.worldTreeEmergence.phase=="skyLead" and rising.worldTreeEmergenceProgress==0,"cinematic sky-first timing drift")
rising.hp=rising.maxHp-100
Siege.updateBoss(cameraMode,rising,.4,cameraGame)
assert(rising.hp==rising.maxHp and rising.entranceOffsetY==1720 and rising.worldTreeEmergenceProgress==0,"tree became visible before sky hold")
Siege.updateBoss(cameraMode,rising,.8,cameraGame);Siege.updateBoss(cameraMode,rising,.5,cameraGame)
assert(rising.entranceOffsetY<1720 and rising.worldTreeEmergenceProgress>0,"slow rise did not start after sky hold")
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
assert(#emergenceQueue>=1,"worldtree authored emergence layer missing")
for _,entry in ipairs(emergenceQueue)do entry.draw()end
local fxDraw=false for _,command in ipairs(fixture.commands)do
    if command.file and command.file:find("worldtree%-emergence%-atlas%-v2")then fxDraw=true end
    assert(command.op~="rectangle","runtime rectangle leaked into worldtree emergence FX")
end
assert(fxDraw,"authored root-crack emergence FX was not drawn")
cameraMode:updateWorldTreeCamera(.8,cameraGame)
assert(camera.userZoom==1 and math.abs(camera.zoom-.84)<.0001,"worldtree changed the user's zoom")
local emergenceState=cameraMode.worldTreeEmergence
for _=1,22 do Siege.updateBoss(cameraMode,rising,.2,cameraGame);cameraMode:updateWorldTreeCamera(.2,cameraGame) end
assert(cameraMode.worldTreeEmergence and cameraMode.worldTreeEmergence.phase=="return" and camera.mode=="default","camera did not return after the full rise")
assert(rising.worldTreeEmerging,"combat unlocked before camera return")
camera.skyviewBlend=0;cameraMode:updateWorldTreeCamera(.1,cameraGame);Siege.updateBoss(cameraMode,rising,.1,cameraGame)
assert(not cameraMode.worldTreeEmergence and not rising.worldTreeEmerging and not rising.entranceOffsetY,"worldtree emergence did not settle")
assert(emergenceState.crownBreach and emergenceState.trunkImpact and emergenceState.canopyBurst and emergenceState.impact,
    "worldtree emergence beats did not all fire")
assert(#(cameraMode.worldTreeDebris or {})>22,"authored soil and leaf debris did not replace generic particles")
assert(camera.mode=="default" and not camera.scriptedSkyviewBoss and camera.skyDuration==.8,
    "worldtree skyview did not return after the root landing")
cameraMode:restoreWorldTreeCamera(cameraGame)
assert(camera.userZoom==1 and math.abs(camera.zoom-.84)<.0001,"worldtree restore changed user zoom")

local zeroMode=ClearcutMode.new();zeroMode.mapId="forest";zeroMode.stage=2;zeroMode.remainingTrees=0
zeroMode.mapWorld=cameraWorld;zeroMode.mapPlayer={x=1600,y=1000}
zeroMode.forestZones={{id=1,coreAlive=true,secured=false,active=0}}
zeroMode.enemies={{zoneCoreId=1,planterCasting=true,plantTimer=0}}
local zeroGame={world=cameraWorld,player=zeroMode.mapPlayer,setNotice=function()end}
assert(zeroMode:checkWorldTreeSpawn(zeroGame),"zero trees did not trigger the worldtree while a zone core survived")
assert(zeroMode.worldTree and zeroMode.worldTreeSpawned and not zeroMode.forestZones[1].coreAlive and zeroMode.forestZones[1].secured,
    "worldtree trigger still depended on secured zones")
assert(not zeroMode.enemies[1].planterCasting and zeroMode.enemies[1].plantTimer==math.huge,
    "surviving regrowth core was not made dormant during the boss transition")
print("WORLDTREE_SIEGE_OK fixed=true centered=playBounds trigger=zero_trees sequence=sky_hold+slow_quake_rise+camera_return+combat duration=6.75 no_forced_zoom=true invulnerable=true grounded=36 attacks=v2_root+vine+slam+targeted_branch rectangle_fx=false")
