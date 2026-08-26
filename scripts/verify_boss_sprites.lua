package.path="./?.lua;./?/init.lua;"..package.path

local draws={}
love={math={random=math.random},graphics={
    setColor=function() end,setLineWidth=function() end,ellipse=function() end,circle=function() end,
    line=function() end,rectangle=function() end,push=function() end,pop=function() end,
    translate=function() end,rotate=function() end,
    draw=function(image,x,y,rotation,sx,sy,ox,oy) draws[#draws+1]={image=image,sx=sx,sy=sy,ox=ox,oy=oy} end
}}

local ClearcutMode=require("src.clearcut_mode")
local entImage={getWidth=function() return 1364 end,getHeight=function() return 1153 end}
local worldImage={getWidth=function() return 1361 end,getHeight=function() return 1156 end}
local bosses={ent=entImage,worldtree=worldImage}
local function enemy(kind,radius)
    return {kind=kind,x=100,y=200,hp=100,maxHp=100,seed=0,moving=kind=="ent",
        def={radius=radius,speed=kind=="ent" and 48 or 0,boss=true}}
end
ClearcutMode.drawEnemy(enemy("ent",42),.3,bosses)
ClearcutMode.drawEnemy(enemy("worldtree",92),.3,bosses)
assert(#draws==2,"boss images were not used by enemy renderer")
assert(math.floor(entImage:getHeight()*draws[1].sy+.5)==195,"Elder Treant render height is wrong")
assert(math.floor(worldImage:getHeight()*draws[2].sy+.5)==300,"World Tree render height is wrong")
assert(entImage:getWidth()*entImage:getHeight() >= (12*14)*16,"Elder Treant source is below 16x old pixel area")
assert(worldImage:getWidth()*worldImage:getHeight() >= (19*18)*16,"World Tree source is below 16x old pixel area")
print("BOSS_SPRITES_16X_OK")
