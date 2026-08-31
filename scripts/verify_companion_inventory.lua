package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local Mode=require("src.clearcut_mode")
local mode=Mode.new();mode.scoreAttack=true;mode.permanentTraits.scoreRocketUnlock=1
mode.scoreEquippedWeapons={"cigarette","firework"};mode.scoreWeaponSlot=1
local monkey={kind="lumberjack",prop="axe"};mode.moleCompanions={monkey};mode:refreshCompanionInventory()
assert(#mode.inventoryBag==3,"owned weapon catalog does not expose all three unlocked items")
local saved
local game={characterTraits={saveEquipmentState=function(_,player,monkeys)saved={player=player,monkeys=monkeys}end}}
local layout=Mode.CompanionInventory.layout(1280,720,1);mode.companionInventoryLayout=layout
local function click(box)assert(mode:companionInventoryClick(box.x+box.w/2,box.y+box.h/2,game))end
click(layout.monkeys[1]);assert(mode.inventoryHeld=="axe"and monkey.prop==nil,"monkey weapon was not picked up")
click(layout.player[2]);assert(mode.inventoryHeld=="firework"and mode.scoreEquippedWeapons[2]=="axe","player slot did not swap")
click(layout.monkeys[1]);assert(mode.inventoryHeld==nil and monkey.prop=="firework","firework was not placed on monkey")
assert(saved and saved.player[1]==1 and saved.player[2]==2 and saved.monkeys[1]==3,"equipment layout was not persisted")
click(layout.bag[2]);assert(mode.inventoryHeld=="axe"and mode.scoreEquippedWeapons[2]==nil,"catalog did not pick the equipped axe up")
click(layout.bag[2]);assert(mode.inventoryHeld==nil,"carried axe did not return to its bag cell")
mode:configureGraduateMonkeyWeapon(monkey);assert(monkey.attackReach>=410 and monkey.damage>=3,"firework monkey stats were not applied")
monkey.prop="cigarette";mode:configureGraduateMonkeyWeapon(monkey);assert(monkey.attackReach>=300,"cigarette monkey stats were not applied")
local Traits=require("src.character_traits");local profile=Traits.new(true)
profile:saveEquipmentState({1,3},{2});local restored=Traits.decode(Traits.encode(profile.data));local state={configured=restored.equipmentConfigured,player=restored.playerWeapons,monkeys=restored.monkeyWeapons}
assert(state.configured and state.player[1]==1 and state.player[2]==3 and state.monkeys[1]==2,"saved equipment did not round-trip")
print("COMPANION_INVENTORY_OK player_slots=2 monkey_slots=1 swap=persisted weapons=3")
