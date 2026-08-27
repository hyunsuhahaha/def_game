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
    clearcutBox={x=0,y=0,w=100,h=50},
    traitsBox={x=110,y=0,w=100,h=50},
    settingsBox={x=220,y=0,w=100,h=50}
}, Lobby)
assert(lobby:keypressed("return") == "clearcut" and lobby:keypressed("r") == nil, "lobby still exposes a non-clearcut mode")
assert(lobby:mousepressed(20,20,1) == "clearcut" and lobby:mousepressed(130,20,1) == "character_traits", "clearcut lobby navigation is not wired")

local store = CharacterTraits.new(true)
store.data.currency = 300
local blocked = store:buy("physical_axe")
assert(not blocked, "dependent character trait unlocked before its prerequisite")
assert(store:buy("physical_quota"), "first character trait purchase failed")
assert(store:buy("physical_axe"), "dependent character trait purchase failed")
local physical = store:effects("physical")
local smoker = store:effects("fire")
assert(physical.attackSpeed > 1 and physical.range == 14, "logger traits did not produce runtime effects")
assert(smoker.attackSpeed == 1 and smoker.range == 0, "logger traits leaked into another character")
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
local visualLobby=setmetatable({fonts=fonts,labelFont=font,displayFont=font,background={getDimensions=function() return 1600,900 end},time=0,clearcutHover=0},Lobby)
assert(pcall(visualLobby.draw,visualLobby), "clearcut-only lobby draw contract failed")
local sprites={physical={image=image},fire={image=image},toxic={image=image},developer={image=image}}
local board=CharacterTraitBoard.new(store,fonts,sprites)
assert(pcall(board.draw,board), "character trait board draw contract failed")
store.data.currency=1000
local rootBox=board.nodeBoxes[1]
mouseX,mouseY,mouseDown=rootBox.cx,rootBox.cy,true
assert(board:mousepressed(mouseX,mouseY,1)=="dragging", "graph did not enter pointer interaction")
board:update(.016); mouseDown=false; board:update(.016)
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
