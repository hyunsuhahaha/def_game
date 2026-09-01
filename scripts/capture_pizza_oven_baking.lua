package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local Oven=require("src.pizza_oven")

fixture.reset()
love.graphics.setColor(.24,.34,.13,1);love.graphics.rectangle("fill",0,0,760,360)
love.graphics.setColor(.16,.24,.09,.58)
for i=0,10 do love.graphics.ellipse("fill",35+i*70,282-(i%2)*5,48,10)end

local states={
    {label="0%",heat=0,fire=.42,slices=0},
    {label="25%",heat=18.75,fire=.58,slices=0},
    {label="55%",heat=41.25,fire=.72,slices=1},
    {label="88%",heat=66,fire=.9,slices=2},
    {label="FULL",heat=0,fire=.9,slices=6},
}
for index,state in ipairs(states)do
    local mode={permanentTraits={scoreOvenUnlock=1},pizzaOven={
        x=82+(index-1)*149,y=270,heat=state.heat,fire=state.fire,
        heatRate=index<5 and 4 or 0,slices=state.slices,
        life=1.18+index*.11,flare=index==4 and .2 or 0,
    }}
    local queue={};Oven.queue(mode,queue)
    for _,entry in ipairs(queue)do entry.draw()end
    love.graphics.setColor(.96,.91,.72,1)
    love.graphics.print(state.label,mode.pizzaOven.x-20,318)
end

local output=assert(os.getenv("PIZZA_OVEN_BAKING_CAPTURE"),"PIZZA_OVEN_BAKING_CAPTURE is required")
fixture.save(output)
print("PIZZA_OVEN_BAKING_CAPTURE_OK states=raw+melting+bubbling+browned+full")
