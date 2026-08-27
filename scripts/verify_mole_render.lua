package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
love.keyboard={isDown=function() return false end}
local Player=require("src.player")
local image=love.graphics.newImage("assets/characters/ingame/coin-miner-mole-atlas-pixel-v3.png")
local player=Player.new(100,100,image,image,image)
local sprite={image=image,scale=.48,nativeFacing=-1,
    walkFeet={380,380,380,380,380,380},actionFeet={380,380,380,380,380,380},
    actionFacing={1,-1,-1,1,1,1},actionScale={1.28,1.48,1.52,1,1,1}}
player:setClearcutSprite(sprite,"miner")

player.facing=1; player.isMoving=true; player.walkClock=0
fixture.reset(); player:draw()
local right=fixture.commands[#fixture.commands]
assert(right.op=="draw" and right.args[4]<0,"left-authored mole was not mirrored when walking right")

player.facing=-1
fixture.reset(); player:draw()
local left=fixture.commands[#fixture.commands]
assert(left.args[4]>0,"mole was not restored to its native pose when walking left")

player.facing=1; player:setClearcutAction(.2)
fixture.reset(); player:draw()
local attack=fixture.commands[#fixture.commands]
assert(math.abs(attack.args[4])>=.70 and math.abs(attack.args[5])>=.70,"claw pose still shrinks the mole")
assert(attack.args[4]>0,"right-side claw frame is facing away from the attack point")

player.facing=-1; player:setClearcutAction(.2)
fixture.reset(); player:draw()
local attackLeft=fixture.commands[#fixture.commands]
assert(attackLeft.args[4]<0,"left-side claw frame is facing away from the attack point")

local Art=require("src.mole_claw_art")
local mode={
    minerClawFx={{x=220,y=80,angle=0,level=5,curveFlip=-1,halfWidth=52,life=.18,maxLife=.22}},
    minerClawMarks={{x=220,y=80,angle=0,level=5,curveFlip=-1,halfWidth=52,life=5,maxLife=6}}
}
fixture.reset(); Art.draw(mode,{},0)
local atlasDraws=0
for _,op in ipairs(fixture.commands) do
    if op.op=="draw" and op.file=="assets/fx/mole-claw/mole-claw-swipe-cartoon-pixel-v1.png" then
        atlasDraws=atlasDraws+1
        assert(op.quad[2]==256,"level-five claw did not use the strongest visual tier")
        assert(op.args[5]<0,"right-facing claw was not vertically mirrored")
        assert(math.abs(math.abs(op.args[5])*39-52)<.001,"claw visual width does not match its gameplay half-width")
    end
end
assert(atlasDraws==2,"claw should draw one local contact and one persistent gouge, not a beam stack")

mode.minerClawFx[1].curveFlip=1; mode.minerClawMarks[1].curveFlip=1
fixture.reset(); Art.draw(mode,{},0)
for _,op in ipairs(fixture.commands) do
    if op.op=="draw" and op.file=="assets/fx/mole-claw/mole-claw-swipe-cartoon-pixel-v1.png" then
        assert(op.args[5]>0,"accepted left-facing claw curve must remain unchanged")
    end
end
print("MOLE_RENDER_OK facing=movement attack_scale=stable claw_target=local mark=persistent tiers=3 hitbox=matched level6=two_hands")
