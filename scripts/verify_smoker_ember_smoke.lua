package.path = "./?.lua;./?/init.lua;" .. package.path

local currentColor = {1, 1, 1, 1}
local emberCoreFound = false
local smokePuffs = 0
local largestSmokePuff = 0
local smokePixels = 0

love = {
    timer={getTime=function() return 1 end},
    math={random=math.random},
    graphics={
        setLineStyle=function() end, setLineWidth=function() end,
        push=function() end, pop=function() end, translate=function() end, rotate=function() end,
        line=function() end, ellipse=function() end, polygon=function() end, print=function() end,
        setColor=function(r, g, b, a)
            if type(r) == "table" then currentColor={r[1] or 0,r[2] or 0,r[3] or 0,r[4] or 1}
            else currentColor={r or 0,g or 0,b or 0,a or 1} end
        end,
        rectangle=function(mode, x, y, w, h)
            if mode == "fill" and currentColor[1] >= .9 and currentColor[2] >= .25
                and currentColor[2] <= .75 and currentColor[3] <= .2
                and currentColor[4] >= .4 then
                assert(w==2 and h==2,"ember must match the enlarged cigarette without hiding the face")
                emberCoreFound = true
            end
            if currentColor[1]==.78 and currentColor[2]==.79 then
                assert(w==2 and h==2,"smoke must use enlarged pixel fragments")
                assert(y>=59 and y<=98,"smoke plume does not match the doubled height")
                smokePixels=smokePixels+1
            end
        end,
        circle=function(mode, x, y, radius)
            if mode == "fill" and currentColor[1] >= .65 and currentColor[1] <= .95
                and currentColor[2] >= .65 and currentColor[3] >= .65 then
                smokePuffs = smokePuffs + 1
                largestSmokePuff = math.max(largestSmokePuff, radius)
            end
        end,
    },
}

local ClearcutMode = require("src.clearcut_mode")
local mode = ClearcutMode.new()
mode.job = "fire"
mode.smoking = {phase="reload", t=.5, dur=1, fired=false}
local game = {player={x=100,y=191,facing=1,clearcutSprite={walkMouth={}}},world={nodes={}}}

mode:drawWorldOverlay(game)

assert(emberCoreFound, "smoking cigarette has no readable high-contrast ember core")
assert(smokePuffs == 0 and largestSmokePuff == 0,"billowing circular smoke returned")
assert(smokePixels >= 10,"cigarette has no rising wisp")
print("SMOKER_EMBER_SMOKE_OK")
