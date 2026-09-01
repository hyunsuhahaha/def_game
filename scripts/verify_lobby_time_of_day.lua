package.path="./?.lua;./?/init.lua;"..package.path
local Time=require("src.lobby_time_of_day")

local noon=Time.state(12)
local sunset=Time.state(18)
local midnight=Time.state(0)
local predawn=Time.state(5.5)
assert(noon.celestial=="sun"and noon.celestialY<.2 and noon.light>.95,"local noon did not put a bright sun high in the lobby sky")
assert(midnight.celestial=="moon"and midnight.celestialY<.2 and midnight.stars>.95,"local midnight did not put a high moon and stars in the lobby sky")
assert(sunset.celestial=="moon"and sunset.celestialX<.1 and sunset.stars==0,"18:00 transition did not begin continuously at the horizon")
assert(predawn.light>midnight.light and predawn.warm>midnight.warm,"predawn did not brighten and warm ahead of sunrise")
local wrapped=Time.state(23.999)
for index=1,3 do assert(math.abs(wrapped.top[index]-midnight.top[index])<.002,"midnight palette has a date-boundary seam")end
assert(math.abs(Time.localHour({hour=14,min=30,sec=0})-14.5)<1e-9,"PC local civil time conversion drifted")
print("LOBBY_TIME_OF_DAY_OK source=pc-local sun=06-18 moon=18-06 palette=continuous")
