local Art={}
local cat,drum,quads
local CELL,FRAMES=128,6
local CAT_SCALE=.72
local DRUM_SCALE=.78
-- The approved sheet has a fixed authored facing per pose. Normalize each
-- row before applying the runtime direction so the exact approved pixels are
-- preserved without making push face backwards.
local AUTHORED_FACING={run=1,push=-1,jump=1}

local function load()
    if cat then return end
    cat=love.graphics.newImage("assets/characters/companions/gray-oil-cat-atlas-pixel-v1.png")
    drum=love.graphics.newImage("assets/characters/companions/oil-drum-pixel-v1.png")
    cat:setFilter("nearest","nearest");drum:setFilter("nearest","nearest")
    quads={run={},push={},jump={}}
    for row,name in ipairs({"run","push","jump"})do
        for frame=0,FRAMES-1 do
            quads[name][frame+1]=love.graphics.newQuad(frame*CELL,(row-1)*CELL,CELL,CELL,cat:getDimensions())
        end
    end
end

function Art.load()load();return true end

function Art.drawDrum(value)
    load();local alpha=value.alpha or 1
    local z=value.z or 0;local squash=value.squash or 1
    local shadow=math.max(.25,1-z/300)
    love.graphics.setColor(0,0,0,.30*shadow)
    love.graphics.ellipse("fill",math.floor(value.x+.5),math.floor(value.y+5),34*shadow,10*shadow)
    love.graphics.setColor(1,value.hitFlash and .58 or 1,value.hitFlash and .38 or 1,alpha)
    love.graphics.draw(drum,math.floor(value.x+.5),math.floor(value.y-z+.5),value.angle or 0,
        DRUM_SCALE*(2-squash),DRUM_SCALE*squash,64,109)
    love.graphics.setColor(1,1,1,1)
end

function Art.drawCat(value)
    load();local state=value.state or"enter"
    local row=state=="push"and"push"or(state=="exit"and"jump"or"run")
    local frame=math.floor((value.animClock or 0)*10)%FRAMES+1
    if state=="push"then
        local p=math.min(1,(value.stateTime or 0)/(value.pushDuration or .8))
        frame=math.min(FRAMES,math.floor(p*FRAMES)+1)
    end
    local facing=value.facing or 1
    local z=value.jumpZ or 0
    local shadow=math.max(.25,1-z/80)
    love.graphics.setColor(0,0,0,.26*shadow)
    love.graphics.ellipse("fill",math.floor(value.x+.5),math.floor(value.y+3),23*shadow,6*shadow)
    love.graphics.setColor(1,1,1,value.alpha or 1)
    love.graphics.draw(cat,quads[row][frame],math.floor(value.x+.5),math.floor(value.y-z+.5),0,
        CAT_SCALE*facing*AUTHORED_FACING[row],CAT_SCALE,CELL/2,118)
    love.graphics.setColor(1,1,1,1)
end

return Art
