package.path="./?.lua;./?/init.lua;"..package.path
local fixture=require("scripts.forest_render_fixture")
local SkyView=require("src.skyview")

love.graphics.getDimensions=function()return 1280,720 end
local camera={skyviewBlend=1,renderX=1600}
for _,id in ipairs({"forest","mangrove","madagascar","island"})do
    fixture.reset()
    assert(SkyView.draw(camera,{clearcutMap=id,width=3200}),id.." sunny SKYVIEW did not draw")
    local draw
    for _,command in ipairs(fixture.commands)do
        if command.file and command.file:find("sun%-skyview%-pixel%-v2")then draw=command end
    end
    assert(draw and draw.file:find(id,1,true),id.." SKYVIEW used another biome")
    assert(draw.filter=="nearest",id.." SKYVIEW lost crisp pixel filtering")
end
camera.skyviewBlend=0;fixture.reset()
assert(not SkyView.draw(camera,{clearcutMap="forest",width=3200}) and #fixture.commands==0,
    "disabled SKYVIEW still drew its panorama")
print("SKYVIEW_SUN_OK maps=4 vivid_sun=true regional=true nearest=true simulation=untouched")
