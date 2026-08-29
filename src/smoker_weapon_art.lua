-- Upright 2.5D-safe art for the two max-rank smoker weapon evolutions.
local Art={}
local equip,fx,equipQuads,fxQuads
local CELL=192

local function load()
    if equip then return end
    equip=love.graphics.newImage("assets/characters/ingame/smoker-weapon-evolution-equipment-v1.png")
    fx=love.graphics.newImage("assets/effects/smoker-weapon-evolution-fx-v1.png")
    equip:setFilter("nearest","nearest");fx:setFilter("nearest","nearest")
    equipQuads={
        vape=love.graphics.newQuad(0,0,128,96,256,96),
        fireworks=love.graphics.newQuad(128,0,128,96,256,96),
    }
    fxQuads={}
    for row=0,2 do fxQuads[row+1]={};for frame=0,5 do
        fxQuads[row+1][frame+1]=love.graphics.newQuad(frame*CELL,row*CELL,CELL,CELL,1152,576)
    end end
end

local function frame(age,life)
    return math.max(1,math.min(6,math.floor(math.max(0,age)/(life/6))+1))
end

function Art.drawHeld(mode,game,t)
    local branch=mode:skillBranch("molotov")
    if branch~="vape" and branch~="fireworks"then return false end
    load();local quad=equipQuads[branch]
    local player=game.player;local facing=player.facing or 1
    local x,y=player.x+facing*24,player.y-68
    love.graphics.setColor(0,0,0,.25);love.graphics.ellipse("fill",x,y+40,22,5)
    love.graphics.setColor(1,1,1,1)
    local scale=branch=="vape" and .55 or .62
    love.graphics.draw(equip,quad,x,y,0,scale*facing,scale,64,48)
    if branch=="vape" then
        love.graphics.setColor(.35,1,.9,.28+math.sin(t*9)*.08);love.graphics.circle("fill",x+facing*7,y-1,7)
    else
        love.graphics.setColor(1,.68,.2,.3+math.sin(t*13)*.12);love.graphics.circle("fill",x+facing*29,y-2,5)
    end
    return true
end

function Art.drawChoice(branch,cx,cy,scale)
    load();local quad=equipQuads[branch];if not quad then return false end
    love.graphics.setColor(0,0,0,.32);love.graphics.ellipse("fill",cx,cy+35,42,9)
    love.graphics.setColor(1,1,1,1);love.graphics.draw(equip,quad,cx,cy,0,scale or .9,scale or .9,64,48)
    return true
end

function Art.drawProjectile(projectile)
    load();local age=projectile.age or projectile.t or 0
    if projectile.kind=="vape" then
        local index=frame(age,projectile.maxLife or .72);local angle=projectile.angle or 0
        love.graphics.setColor(1,1,1,math.max(0,1-age/(projectile.maxLife or .72)))
        love.graphics.draw(fx,fxQuads[1][index],projectile.x,projectile.y,angle,.58,.58,96,96)
    elseif projectile.kind=="firework" then
        local index=frame(age,projectile.dur or .55);local angle=projectile.angle or 0
        love.graphics.setColor(1,1,1,1);love.graphics.draw(fx,fxQuads[2][index],projectile.x,projectile.y,angle,.62,.62,96,96)
    elseif projectile.kind=="firework_burst" then
        local index=frame(age,projectile.life or .82)
        love.graphics.setColor(1,1,1,math.max(0,1-age/(projectile.life or .82)))
        local scale=((projectile.radius or 180)*2)/CELL
        love.graphics.draw(fx,fxQuads[3][index],projectile.x,projectile.y,0,scale,scale,96,96)
    end
end

function Art.assets()load();return{equipment=equip,fx=fx}end
return Art
