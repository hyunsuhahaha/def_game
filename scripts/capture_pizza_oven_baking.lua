package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local Oven=require("src.pizza_oven")

fixture.reset()
love.graphics.setColor(.24,.34,.13,1);love.graphics.rectangle("fill",0,0,760,360)
love.graphics.setColor(.16,.24,.09,.58)
for i=0,10 do love.graphics.ellipse("fill",35+i*70,282-(i%2)*5,48,10)end

local states={
    {label="COLD",heat=0,fire=0,rate=0,slices=0},
    {label="EMBERS",heat=35,fire=0,rate=0,slices=0},
    {label="ACTIVE",heat=18,fire=.52,rate=2,slices=0},
    {label="ROARING",heat=48,fire=1,rate=8,slices=0},
    {label="FULL + FIRE",heat=0,fire=1,rate=8,slices=6},
}
for index,state in ipairs(states)do
    local mode={permanentTraits={scoreOvenUnlock=1},pizzaOven={
        x=82+(index-1)*149,y=270,heat=state.heat,fire=state.fire,
        heatRate=state.rate,slices=state.slices,
        life=1.18+index*.11,flare=index==4 and .2 or 0,
    }}
    local queue={};Oven.queue(mode,queue)
    for _,entry in ipairs(queue)do entry.draw()end
    love.graphics.setColor(.96,.91,.72,1)
    love.graphics.print(state.label,mode.pizzaOven.x-20,318)
end

local output=assert(os.getenv("PIZZA_OVEN_BAKING_CAPTURE"),"PIZZA_OVEN_BAKING_CAPTURE is required")
fixture.save(output)
print("PIZZA_OVEN_HEARTH_CAPTURE_OK states=cold+embers+active+roaring+full_fire no_interior_pizza=true")
