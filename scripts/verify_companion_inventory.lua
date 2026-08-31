package.path="./?.lua;./?/init.lua;"..package.path
local Mode=require("src.clearcut_mode")
local mode=Mode.new();mode.scoreAttack=true
assert(Mode.CompanionInventory==nil and mode.toggleCompanionInventory==nil and mode.companionInventoryClick==nil,
    "removed weapon inventory is still reachable from score mode")
assert(mode.scoreEquippedWeapons==nil and mode.inventoryBag==nil and mode.inventoryHeld==nil,
    "manual equipment state is still created for a new score run")

-- Graduation now owns a fixed inherited prop; there is no player-managed swap.
local monkey={kind="lumberjack",prop="axe"}
mode.moleCompanions={monkey}
mode.permanentTraits.treeDamage=5
mode:configureGraduateMonkeyWeapon(monkey)
assert(monkey.prop=="axe"and monkey.damage>=3 and monkey.attackReach>=100,
    "graduated monkey did not keep the inherited axe build")
print("CONTEXT_WEAPON_INVENTORY_REMOVED player_slots=0 monkey_swap=off inherited=axe")
