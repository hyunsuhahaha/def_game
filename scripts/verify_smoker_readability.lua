package.path = "./?.lua;./?/init.lua;" .. package.path

local smokeCircles = 0
love = {
    timer={getTime=function() return 1 end},
    math={random=math.random},
    graphics={
        setLineStyle=function() end, setColor=function() end, setLineWidth=function() end,
        push=function() end, pop=function() end, translate=function() end, rotate=function() end,
        line=function() end, ellipse=function() end, polygon=function() end, print=function() end,
        rectangle=function() end,
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

assert(smokeCircles >= 4, "smoking action has no readable inhale/exhale smoke volume")
print("SMOKER_SMOKE_FX_OK")
