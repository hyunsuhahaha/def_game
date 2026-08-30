package.path = "./?.lua;./?/init.lua;" .. package.path

local font = {getHeight=function() return 16 end}
local image = {getDimensions=function() return 1536,1024 end, getWidth=function() return 1536 end, getHeight=function() return 1024 end}
local mouseX,mouseY,mouseDown=-1,-1,false
love = {
    math={random=math.random}, filesystem={}, mouse={getPosition=function() return mouseX,mouseY end,isDown=function() return mouseDown end},
    graphics={
        getDimensions=function() return 1600,900 end, setColor=function() end, rectangle=function() end,
        setFont=function() end, print=function() end, printf=function() end, draw=function() end,
        line=function() end, circle=function() end, ellipse=function() end, polygon=function() end,
        setLineWidth=function() end, push=function() end, pop=function() end,
        translate=function() end, rotate=function() end, setScissor=function() end,
        newQuad=function() return {} end
    }
}

local CharacterTraits = require("src.character_traits")
local ClearcutMode = require("src.clearcut_mode")
local Lobby = require("src.lobby")
local CharacterTraitBoard = require("src.character_trait_board")

local lobby = setmetatable({
    scoreAttackBox={x=0,y=0,w=100,h=50},
    traitsBox={x=110,y=0,w=100,h=50},
    settingsBox={x=220,y=0,w=100,h=50}
}, Lobby)
assert(lobby:keypressed("return") == "score_attack" and lobby:keypressed("m")=="score_attack" and lobby:keypressed("c") == nil, "active lobby did not intentionally disable campaign shortcuts")
assert(lobby:mousepressed(20,20,1)=="score_attack" and lobby:mousepressed(130,20,1) == "character_traits", "score-attack lobby navigation is not wired")

local store = CharacterTraits.new(true)
assert(store:getRegenTier()==1 and store:unlockRegenTier(3) and store:getRegenTier()==3 and not store:unlockRegenTier(2),"persistent regeneration tier did not advance monotonically")
local roundTrip=CharacterTraits.decode(CharacterTraits.encode(store.data))
assert(roundTrip.regenTier==3,"persistent regeneration tier did not survive save encoding")
local migrated=CharacterTraits.decode("fire_score_filter=6\nfire_score_lighter=6\nfire_score_ash=6\nfire_score_drag=6\nfire_score_heat=6\n")
assert(migrated.levels.fire_score_filter==6 and migrated.levels.fire_score_heat==6 and migrated.levels.fire_score_spark==0 and migrated.levels.fire_score_stock==0,
    "legacy score research ranks were not preserved as granular traits")
store.data.currency = 300
local blocked = store:buy("physical_axe")
assert(not blocked, "dependent character trait unlocked before its prerequisite")
assert(store:buy("physical_quota"), "first character trait purchase failed")
assert(store:buy("physical_axe"), "dependent character trait purchase failed")
local physical = store:effects("physical")
local smoker = store:effects("fire")
assert(physical.attackSpeed > 1 and physical.range == 14, "logger traits did not produce runtime effects")
assert(smoker.attackSpeed == 1 and smoker.range == 0, "logger traits leaked into another character")
store.data.levels.universal_yard=7
store.data.levels.universal_robot_start=1
store.data.levels.universal_robot_motor=5
assert(store:effects("fire").scoreTreeAllowance==28,"permanent logging-yard capacity did not reach +28 trees at max rank")
for _,id in ipairs({"fire_score_prewarm","fire_score_filter","fire_score_lighter","fire_score_spark","fire_score_launch","fire_score_ash","fire_score_drag","fire_score_heat"})do store.data.levels[id]=5 end
store.data.levels.fire_score_stock=1
local scoreSmoker=store:effects("fire")
assert(scoreSmoker.scoreRange==80 and scoreSmoker.scoreArea==60,"score-mode permanent smoker geometry was not subdivided correctly")
assert(math.abs(scoreSmoker.scoreIgnitionChance-.06)<1e-9 and scoreSmoker.scoreSpreadChance==.15,"score-mode ignition traits were not separated")
assert(math.abs(scoreSmoker.scoreAttackSpeed-.20)<1e-9 and math.abs(scoreSmoker.scoreProjectileSpeed-.35)<1e-9 and math.abs(scoreSmoker.scoreBurnSpeed-.30)<1e-9 and scoreSmoker.scoreExtraFires==1,"score-mode permanent smoker pacing was not subdivided correctly")
local activeScore=store:scoreAttackEffects()
assert(activeScore.scoreInitialIgnitionReduction==.4,"score-mode opening ignition trait is not active")
assert(activeScore.scoreStartingBabyRobot==1 and activeScore.scoreRobotSpeed==.5,"score-mode baby robot permanent research is not active")
assert(activeScore.scoreStartingWood==nil and activeScore.scoreAutomationDiscount==nil,"removed score automation traits still affect runtime")
assert(#store:getScoreAttackNodes("fire")==9 and #store:getScoreAttackNodes("universal")==3,"active research board did not isolate score-mode traits")
for _, job in ipairs({"physical","fire","toxic","developer"}) do
    assert(#store:getNodes(job) >= 30, job .. " character graph has too few trait nodes")
end

local encoded = CharacterTraits.encode(store.data)
local decoded = CharacterTraits.decode(encoded)
assert(decoded.currency == store.data.currency and decoded.levels.physical_quota == 1 and decoded.levels.physical_axe == 1, "character trait save roundtrip failed")

local mode = ClearcutMode.new()
mode.job, mode.treesFelled, mode.kills, mode.level = "physical", 100, 4, 8
mode.permanentTraits = physical
local before = store.data.currency
local game = {characterTraits=store, result=nil}
mode:finish(game, true)
assert(game.mode == "clearcut_results" and game.result.traitEarned > 0, "run did not award character trait currency")
assert(store.data.currency == before + game.result.traitEarned, "awarded character trait currency was not stored")
local after = store.data.currency
mode:finish(game, true)
assert(store.data.currency == after, "character trait currency was awarded twice for one run")

local fonts={small=font,body=font,heading=font,big=font,title=font}
local visualLobby=setmetatable({fonts=fonts,labelFont=font,displayFont=font,background={getDimensions=function() return 1600,900 end},time=0,scoreAttackHover=0,traitsHover=0},Lobby)
assert(pcall(visualLobby.draw,visualLobby), "clearcut-only lobby draw contract failed")
local sprites={physical={image=image},fire={image=image},toxic={image=image},developer={image=image}}
store.data.levels.fire_score_prewarm=0
local board=CharacterTraitBoard.new(store,fonts,sprites)
assert(pcall(board.draw,board), "character trait board draw contract failed")
store.data.currency=1000
local rootBox
for _,box in ipairs(board.nodeBoxes)do
    local purchasable=store:status(box.id)
    if purchasable and box.cx>=board.viewport.x and box.cx<=board.viewport.x+board.viewport.w and box.cy>=board.viewport.y and box.cy<=board.viewport.y+board.viewport.h then rootBox=box;break end
end
rootBox=assert(rootBox,"no visible purchasable trait node found")
mouseX,mouseY,mouseDown=rootBox.cx,rootBox.cy,true
assert(board:mousepressed(mouseX,mouseY,1)=="dragging", "graph did not enter pointer interaction")
board:update(.016); mouseDown=false; board:update(.016)
assert(board.selectedNodeId==rootBox.id and board:buySelected()=="bought", "selected trait node was not purchased")
assert(board.unlockFx and #board.particles>=30, "graph unlock effect did not spawn")
local oldPan=board.panX
mouseX,mouseY,mouseDown=board.viewport.x+board.viewport.w/2,board.viewport.y+board.viewport.h/2,true
board:mousepressed(mouseX,mouseY,1)
mouseX=mouseX-100; board:update(.016)
assert(board.panX~=oldPan,"dragging did not pan the research canvas")
mouseDown=false; board:update(.016)
assert(math.abs(board.panVX)>0,"released research canvas has no inertial velocity")
local oldZoom=board.zoom
board:wheelmoved(0,1)
assert(board.zoom>oldZoom,"mouse wheel did not zoom the research canvas")
assert(board.zoom>=.36 and board.zoom<=1.60,"research canvas zoom escaped its supported range")

print("CHARACTER_TRAITS_OK")
