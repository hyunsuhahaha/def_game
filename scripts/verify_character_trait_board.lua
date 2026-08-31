package.path = "./?.lua;./?/init.lua;" .. package.path

local Board = require("src.character_trait_board")

local store = {
    getScoreAttackNodes = function()
        return {{id="universal_mole_dual"}}
    end,
}

local board = Board.new(store, {}, {})
board.selectedJob = "universal"
board.viewport = {x=0,y=0,w=1440,h=560}
board.zoom = .80
board.panY = math.huge
board:clampCamera()

local _, nodeY = board:nodeWorld({id="universal_mole_dual"})
local screenY = board.viewport.y + board.viewport.h/2 + (nodeY-board.panY)*board.zoom
local nodeBottom = screenY + 68

assert(nodeBottom <= board.viewport.y + board.viewport.h,
    "최하단 연구 노드가 드래그 한계 아래에 남아 있음")

print("character trait board pan bounds OK")
