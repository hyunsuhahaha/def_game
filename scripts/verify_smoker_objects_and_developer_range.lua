package.path="./?.lua;./?/init.lua;"..package.path

local rectangles=0
love={
    mouse={isDown=function() return false end,getPosition=function() return 1000,0 end},
    math={random=math.random},timer={getTime=function() return 0 end},
    graphics={setColor=function() end,rectangle=function() rectangles=rectangles+1 end,circle=function() end,
        push=function() end,pop=function() end,translate=function() end,rotate=function() end,ellipse=function() end,
        line=function() end,polygon=function() end,setLineWidth=function() end,setLineStyle=function() end,print=function() end}
}

local ClearcutMode=require("src.clearcut_mode")
local player={x=0,y=0,gather=1,facing=1,setClearcutAction=function() end,clearClearcutAction=function() end}
local game={player=player,tools={axe={speed=1}},camera={trauma=0,screenToWorld=function(_,x,y) return x,y end},world={nodes={}},setNotice=function() end}
local failures={}

local smoker=ClearcutMode.new(); smoker.job="fire"; smoker:startSmoking(game)
smoker:updateFireAttack(smoker.smoking.dur+1,game,false)
if type(smoker.drawSmokerCigarette)~="function" or not smoker:drawSmokerCigarette(game) then failures[#failures+1]="lit cigarette object missing from mouth" end

smoker:hurlMolotovAt(320,0,game)
if #smoker.molotovs~=1 or smoker.molotovs[1].dur<.34 then failures[#failures+1]="flying cigarette lifetime is unreadably short" end
local before=rectangles
if type(smoker.drawCigaretteProjectiles)~="function" then failures[#failures+1]="flying cigarette object renderer missing"
else smoker.molotovs[1].t=smoker.molotovs[1].dur*.5; smoker:drawCigaretteProjectiles(0); if rectangles-before<20 then failures[#failures+1]="flying cigarette object is too small" end end

local developer=ClearcutMode.new(); developer.job="developer"
developer:updateDeveloperAttack(0,game,false)
if math.abs((developer.aimX or 0)-200)>.01 or developer.aimRadius~=55 then failures[#failures+1]="developer telegraph does not match level-0 dash geometry" end
developer:startDash(developer.aimX or 0,developer.aimY or 0,game)
if not developer.dashing or math.abs(developer.dashing.remaining-(developer.aimX or 0))>.01 then failures[#failures+1]="developer actual dash distance differs from telegraph" end
developer.dashing=nil; developer.levels.pile_driving=3; developer.levels.heavy_machinery=3
developer:updateDeveloperAttack(0,game,false)
if math.abs((developer.aimX or 0)-410)>.01 or developer.aimRadius~=115 then failures[#failures+1]="developer upgraded telegraph geometry is wrong" end

assert(#failures==0,table.concat(failures,"; "))
print("SMOKER_OBJECTS_AND_DEVELOPER_RANGE_OK")
