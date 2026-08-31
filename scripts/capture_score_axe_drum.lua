package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
love.graphics.rotate=love.graphics.rotate or function()end
local Player=require("src.player")
local AxeArt=require("src.score_axe_art")
local DrumArt=require("src.gray_oil_cat_art")

love.graphics.setColor(.31,.48,.16,1);love.graphics.rectangle("fill",0,0,960,360)
local walk=love.graphics.newImage("assets/characters/ingame/smoker-atlas-pixel-v2.png")
local dummy=love.graphics.newImage("assets/characters/ingame/smoker-atlas-pixel-v2.png")
local sprite={image=walk,scale=.61,nativeFacing=1,walkFeet={190,190,190,190,190,190},actionFeet={190,190,190,190,190,190},
    actionFacing={-1,-1,-1,-1,1,1}}
sprite.scoreAxeImage=love.graphics.newImage("assets/characters/ingame/smoker-score-axe-atlas-pixel-v1.png")
sprite.scoreAxeFeet={190,190,190,190,190,190}

local phases={{.27,8,"백스윙"},{.53,4,"접촉"},{.72,4,"반동"}}
for index,phase in ipairs(phases)do
    local x=150+(index-1)*320;local y=270
    local player=Player.new(x,y,dummy,dummy,dummy);player:setClearcutSprite(sprite,"fire")
    player.facing=1;player.axeHolding=true;player.scoreAxeEquipped=true;player.hideAxeRange=true;player.autoAxeDuration=.45;player.autoAxeClock=.45*phase[1]
    local action={elapsed=.45*phase[1],duration=.45,contactTime=.45*.52}
    local mode={scoreAxeAction=action}
    player:draw()
    local drum={x=x+70,y=y,state="settled",hp=phase[2],maxHp=8,angle=phase[2]<8 and .065 or 0,squash=1,hitFlash=phase[1]>.5 and phase[1]<.7 and .1 or 0,
        hitKickTime=phase[1]>.5 and phase[1]<.7 and .09 or 0,hitDirection=1}
    DrumArt.drawDrum(drum)
    if index==2 then AxeArt.drawImpact({x=drum.x,y=drum.y-48,facing=1,age=.055,life=.24})end
    love.graphics.setColor(1,.95,.75,1);love.graphics.print(phase[3],x-24,315)
end
fixture.save("docs/previews/score-axe-drum-v1-draws.json")
print("SCORE_AXE_DRUM_CAPTURE_OK phases=windup+contact+recovery window=none")
