local game=dofile("scripts/verify_crane_full_scene.lua")
local Maps=require("src.clearcut_maps")
local Lake=require("src.lakeside")
local world,camera=game.world,game.camera
local w,h=world.width,world.height
local previous
for tier=1,5 do
    Maps.configureScoreTier(world,tier)
    local b=world.playBounds
    assert(world.width==w and world.height==h,"tier stretched background world")
    assert(math.abs(b.x+b.w-w*.93)<.001 and math.abs(b.y+b.h-h*.88)<.001,"shore-side bounds moved")
    if previous then assert(b.x<previous.x and b.y<previous.y and b.w>previous.w and b.h>previous.h,"inland expansion failed")end
    local x,y=Maps.constrain(world,-10000,-10000,75)
    assert(x==b.x+75 and y==b.y+75,"unopened ground allows movement")
    x,y=Maps.constrain(world,w*2,h*2,75)
    assert(x<=b.x+b.w-75 and y<=b.y+b.h-75,"lake allows movement")
    local q={};Lake.queue(world,q)
    for _,p in ipairs(q)do
        if not world.lakeOpening then assert(not Maps.insidePlayable(world,p.x,p.y,0),"closed grove in playable field")end
    end
    local oldZoom=camera.renderZoom
    camera:update(.016,game.player,world)
    if previous then assert(camera.renderZoom<=oldZoom+.0001,"expansion zoomed inward")end
    for _=1,100 do Lake.update(world,.016);camera:update(.016,game.player,world)end
    for _,point in ipairs({{b.x,b.y},{b.x+b.w,b.y+b.h},{game.player.x,game.player.y}})do
        local sx,sy=camera:worldToScreen(point[1],point[2])
        assert(sx>=0 and sx<=1280 and sy>=0 and sy<=720,"expanded field clipped")
        local rx,ry=camera:screenToWorld(sx,sy)
        assert(math.abs(rx-point[1])<.001 and math.abs(ry-point[2])<.001,"aim projection drift")
    end
    assert(not world.lakeOpening,"opening animation leaked")
    previous=b
end
Maps.configureScoreTier(world,20)
assert(world.playBounds.w>previous.w and world.playBounds.x>=0,"post-5 expansion escaped shoreline")
Maps.configure(world,"island")
assert(not world.lakeside and not world.lakeOpening,"lake leaked into legacy biome")
game:startClearcutScoreAttack(1,false)
local active=game.world
local node=active.nodes[1]
local px,py=game.player.x,game.player.y
assert(game.clearcut:advanceScoreRegenTier(game,false,"worldtree"),"actual promotion rejected")
assert(game.clearcut.scoreRegenTier==2 and active.lakeOpening,"promotion did not open the inland area")
assert(active.nodes[1]==node and game.player.x==px and game.player.y==py,"promotion regenerated combat or teleported operator")
print("LAKESIDE_OK five-inland-expansions fixed-shore movement aim camera fade legacy-isolation")
