package.path = "./?.lua;./?/init.lua;" .. package.path

local smokeCircles = 0
local smokePixels = 0
local color = {}
love = {
    timer={getTime=function() return 1 end},
    math={random=math.random},
    graphics={
        setLineStyle=function() end, setColor=function(...) color={...} end, setLineWidth=function() end,
        push=function() end, pop=function() end, translate=function() end, rotate=function() end,
        line=function() end, ellipse=function() end, polygon=function() end, print=function() end,
        rectangle=function(mode,x,y,w,h)
            if color[1]==.78 and color[2]==.79 then
                assert(w==2 and h==2,"smoke does not match the enlarged cigarette")
                smokePixels=smokePixels+1
            end
        end,
        circle=function(mode, x, y, radius)
            if mode == "fill" and radius >= 2 then smokeCircles = smokeCircles + 1 end
        end
    }
}

local ClearcutMode = require("src.clearcut_mode")
local mode = ClearcutMode.new()
mode.job = "fire"
mode.smoking = {phase="reload", t=.45, dur=1, fired=false}
local game = {
    player={x=100, y=100, facing=1},
    world={nodes={}}
}
mode:drawWorldOverlay(game)

assert(smokeCircles == 0 and smokePixels >= 10, "smoking must use a fine wisp, not large smoke circles")
print("SMOKER_SMOKE_FX_OK")
