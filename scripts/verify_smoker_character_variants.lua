package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local Game=require("src.game")
local Player=require("src.player")

local loader
for index=1,30 do
    local name,value=debug.getupvalue(Game.new,index)
    if name=="loadClearcutSprites"then loader=value break end
end
local sprites=assert(loader,"production sprite loader missing")()
assert(sprites.fire.file=="smoker-atlas-pixel-v3.png","old body-baked cigarette atlas still loads")
assert(sprites.fire.cigarette,"runtime cigarette object was removed")

local welder=assert(sprites.fire.avatarVariants.scrapyard_welder)
local shopkeeper=assert(sprites.fire.avatarVariants.night_shopkeeper)
for _,avatar in ipairs({welder,shopkeeper})do
    local bodyWidth,bodyHeight=avatar.image:getDimensions()
    local axeWidth,axeHeight=avatar.scoreAxeImage:getDimensions()
    assert(bodyWidth==576 and bodyHeight==384)
    assert(axeWidth==576 and axeHeight==192)
    assert(avatar.image.filter=="nearest"and avatar.scoreAxeImage.filter=="nearest")
    assert(avatar.cigarette==sprites.fire.cigarette,"avatar duplicated instead of reusing equipment")
    assert(#avatar.walkMouth==6 and #avatar.actionMouth==6)
end

local player=setmetatable({facing=1},Player)
local game=setmetatable({clearcutSprites=sprites,clearcut={scoreAttack=true},player=player},Game)
assert(game:setScoreAvatar("scrapyard_welder"))
assert(player.clearcutSprite==welder and #player.clearcutFrames.walk==6 and #player.scoreAxeFrames==6)
assert(game:setScoreAvatar("night_shopkeeper"))
assert(player.clearcutSprite==shopkeeper and #player.clearcutFrames.action==6 and #player.scoreAxeFrames==6)
assert(game:setScoreAvatar("original"))
assert(player.clearcutSprite==sprites.fire and #player.scoreAxeFrames==6)
assert(not game:setScoreAvatar("unknown"),"unknown avatar silently replaced the player")

print("SMOKER_CHARACTER_VARIANTS_RUNTIME_OK original+2 avatars body/action/axe runtime-cigarette")
