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
board.panX,board.panY=9100,7200
board:clampCamera()

assert(board.panX==9100 and board.panY==7200,
    "research board still clamps dragging at the old canvas edge")

local nodeX,nodeY=board:nodeWorld({id="universal_mole_dual"})
local screenX=board.viewport.x+board.viewport.w/2+(nodeX-board.panX)*board.zoom
local screenY=board.viewport.y+board.viewport.h/2+(nodeY-board.panY)*board.zoom
assert(screenX<board.viewport.x and screenY<board.viewport.y,
    "free pan did not allow the entire research tree to leave the viewport")

print("character trait board free pan OK")
