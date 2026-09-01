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

-- 노드 사각형은 drawNode 에서 반지름 (capstone and 38 or 32) 로 그려지고 외곽선이
-- 몇 픽셀 더 번진다. 두 노드가 양 축 모두에서 그 합보다 가까우면 화면에서 겹친다.
-- 실제로 `fire_score_rocket_radius` 가 `fire_score_axe_chain` 과 좌표가 완전히 같아
-- 한 노드가 통째로 가려지고 클릭도 되지 않던 적이 있어 상시 검사로 남긴다.
local CLEAR=10
local overlaps={}
for _,job in ipairs({"fire","universal"})do
    local placed={}
    for _,node in ipairs(store:getScoreAttackNodes(job))do
        local wx,wy=board:nodeWorld(node)
        placed[#placed+1]={id=node.id,x=wx,y=wy,r=node.capstone and 38 or 32}
    end
    for i=1,#placed do
        for j=i+1,#placed do
            local a,b=placed[i],placed[j]
            local need=a.r+b.r+CLEAR
            if math.abs(a.x-b.x)<need and math.abs(a.y-b.y)<need then
                overlaps[#overlaps+1]=a.id.." <-> "..b.id.." @ ("..a.x..","..a.y..")"
            end
        end
    end
end
assert(#overlaps==0,"research board nodes overlap on screen: "..table.concat(overlaps,"; "))

print("character trait board free pan OK, no node overlaps")
