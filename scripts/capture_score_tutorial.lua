package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local Tutorial=require("src.score_tutorial")
local background=love.graphics.newImage("docs/previews/forest-arcade-v3-runtime.png")
background:setFilter("nearest","nearest")
local fonts={heading=love.graphics.newFont("assets/font-korean-bold.ttf",24),micro=love.graphics.newFont("assets/font-korean-pixel.ttf",14)}

for step=1,3 do
    fixture.reset()
    local bw,bh=background:getDimensions()
    love.graphics.setColor(1,1,1,1);love.graphics.draw(background,0,0,0,1280/bw,720/bh)
    Tutorial.draw({scoreTutorial={step=step}},fonts,1280,720)
    fixture.save("docs/previews/score-tutorial-step"..step.."-draws.json")
end
fixture.reset()
local bw,bh=background:getDimensions()
love.graphics.setColor(1,1,1,1);love.graphics.draw(background,0,0,0,960/bw,540/bh)
Tutorial.draw({scoreTutorial={step=1}},fonts,960,540)
fixture.save("docs/previews/score-tutorial-step1-960-draws.json")
print("SCORE_TUTORIAL_CAPTURE_OK steps=3 size=1280x720 window=none")
