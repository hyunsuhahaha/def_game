package.path="./?.lua;./?/init.lua;"..package.path
love={graphics={getDimensions=function()return 1280,720 end},math={}}

local Camera=require("src.camera")
local cam=Camera.new(500,400);cam.zoom=.84;cam.renderZoom=.84
local world={width=3200,height=2200,playBounds={x=0,y=0,w=3200,h=2200}}
cam:impulse(90,-35,.04,.05)
cam:update(1/60,{x=560,y=420},world)
assert(math.abs(cam.roll)>0 and math.abs(cam.roll)<=.018,"camera roll is not bounded")
assert(cam.renderZoom>cam.zoom,"zoom impulse missing")
assert(math.abs(cam.renderX-cam.x)>0,"near-plane inertia missing")
local ix,iy=cam.inertiaX,cam.inertiaY
for _=1,180 do cam:update(1/60,{x=560,y=420},world) end
assert(math.abs(cam.roll)<.002 and math.abs(cam.inertiaX)<math.abs(ix) and math.abs(cam.inertiaY)<math.abs(iy),"camera impulse did not settle")
cam.renderX,cam.renderY,cam.renderZoom,cam.roll=500,400,1.2,.013
local sx,sy=811,259;local wx,wy=cam:screenToWorld(sx,sy)
local dx,dy=wx-cam.renderX,wy-cam.renderY;local c,s=math.cos(cam.roll),math.sin(cam.roll)
local rsx=640+(dx*c-dy*s)*cam.renderZoom;local rsy=360+(dx*s+dy*c)*cam.renderZoom
assert(math.abs(rsx-sx)<.001 and math.abs(rsy-sy)<.001,"screenToWorld no longer inverts camera roll")

local Entrance=require("src.boss_entrance")
local Bosses=require("src.biome_bosses")
local profiles=Entrance.profiles();local seen={}
local mapKinds={beginner="stumpWarden",forest="hollowOak",mangrove="rootjaw",madagascar="baobabTyrant",island="islandHermit",greatforest="hollowOak"}
for map,kind in pairs(mapKinds) do
  local mode={}
  local def=Bosses.definitions[kind]
  local boss={kind=kind,def=def,x=800,y=510,hp=def.hp,maxHp=def.hp}
  local focusCount,impactCount=0,0
  local fakeCam={trauma=0,focus=function()focusCount=focusCount+1 end,impulse=function()impactCount=impactCount+1 end}
  local game={player={x=500,y=500},camera=fakeCam}
  assert(Entrance.start(mode,boss,game),map.." entrance did not start")
  assert(boss.bossState=="entrance" and focusCount==1)
  local elapsed=0
  while Entrance.active(mode) and elapsed<4 do Entrance.update(mode,.05,game);elapsed=elapsed+.05 end
  assert(not Entrance.active(mode) and boss.bossState=="idle",map.." entrance did not finish")
  assert(impactCount==1,map.." landing impulse must fire exactly once")
  assert(not boss.entranceAlpha and not boss.entranceOffsetX and not boss.entranceOffsetY,"intro pose leaked")
  seen[profiles[kind].row]=true
end
local rows=0 for _ in pairs(seen) do rows=rows+1 end
assert(rows==5,"biomes do not have five distinct authored FX rows")

local clearcut=assert(io.open("src/clearcut_mode.lua","rb")):read("*a")
local gameSource=assert(io.open("src/game.lua","rb")):read("*a")
assert(clearcut:find("BossEntrance.start",1,true) and clearcut:find("BossEntrance.queue",1,true),"boss runtime hooks missing")
assert(gameSource:find("updateBossEntrance",1,true) and gameSource:find("WorldProjection.finish",1,true),"combat freeze or projected world pass missing")
assert(not clearcut:find("등장!",1,true),"generic boss entrance text returned")
print("CINEMATIC_CAMERA_BOSS_INTRO_OK maps=6 world=projected input_inverse=roll+zoom combat_freeze=yes text_banner=none")
