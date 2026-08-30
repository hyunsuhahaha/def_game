package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local Art=require("src.score_tier_up_art")
local function font(path,size)return{path=path,size=size,getHeight=function()return size end}end
local fonts={micro=font("assets/font-korean-regular.ttf",12),big=font("assets/font-korean-bold.ttf",28),display=font("assets/font-korean-bold.ttf",42)}
for _,t in ipairs({.08,.28,.48,.72})do
    fixture.reset()
    Art.draw({t=t,duration=.86,toTier=4},fonts,1280,720)
    assert(#fixture.commands>=3,"tier-up frame emitted too few authored layers")
    local image,text=false,0
    for _,command in ipairs(fixture.commands)do
        image=image or(command.op=="draw"and command.file=="assets/fx/score-tier-up-atlas-pixel-v1.png")
        if command.op=="text"then text=text+1 end
    end
    assert(image and text==4,"tier-up frame lost its atlas or minimal stage labels")
end
print("SCORE_TIER_UP_DRAW_OK frames=4 atlas+labels")
