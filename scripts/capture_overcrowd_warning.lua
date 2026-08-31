package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local Art=require("src.overcrowd_warning_art")

fixture.reset();fixture.time=1.35
assert(Art.draw(.80,"forest",1280,720,fixture.time))
fixture.save("docs/previews/overcrowd-warning-80-draws.json")

fixture.reset();fixture.time=1.35
assert(Art.draw(.95,"forest",1280,720,fixture.time))
fixture.save("docs/previews/overcrowd-warning-95-draws.json")
print("OVERCROWD_WARNING_CAPTURE_OK threshold=80,95 text=none window=none")
