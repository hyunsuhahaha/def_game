package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
love.graphics.getDimensions=function()return 1280,720 end
love.graphics.getWidth=function()return 1280 end
love.graphics.getHeight=function()return 720 end
love.mouse={getPosition=function()return 640,360 end}
local Mode=require("src.clearcut_mode")
local mode=Mode.new();mode.scoreAttack=true;mode.scoreWeaponSlot=1
mode.permanentTraits.scoreRocketUnlock=1
mode.scoreEquippedWeapons={"cigarette",nil}
mode.moleCompanions={{kind="lumberjack",prop="axe"}}
mode.companionInventoryOpen=true;mode:refreshCompanionInventory()
local fonts={small=love.graphics.newFont("assets/font-korean-regular.ttf",14),heading=love.graphics.newFont("assets/font-korean-bold.ttf",21)}
fixture.reset();Mode.CompanionInventory.draw(mode,fonts,1280,720)
fixture.save(os.getenv("COMPANION_INVENTORY_CAPTURE")or"docs/previews/companion-inventory-runtime.json")
print("COMPANION_INVENTORY_CAPTURE_OK player_slots=2 monkey_slots=1 weapons=3 window=none")
