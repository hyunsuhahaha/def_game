local Art={}
local image,quads
local W,H=128,160
local function load()
    if image then return end
    image=love.graphics.newImage("assets/fx/brute-force/brute-force-atlas-pixel-v1.png");image:setFilter("nearest","nearest")
    quads={}
    for row=0,1 do quads[row+1]={};for col=0,5 do quads[row+1][col+1]=love.graphics.newQuad(col*W,row*H,W,H,image:getDimensions()) end end
end
local function frame(row,col,x,y,angle,scale,alpha,ox,oy)
    load();love.graphics.setColor(1,1,1,alpha or 1)
    love.graphics.draw(image,quads[row][col],math.floor(x+.5),math.floor(y+.5),angle or 0,scale or 1,scale or 1,ox or W/2,oy or 150)
end
function Art.draw(mode,t)
    local active=(mode.digits and #mode.digits>0) or (mode.bruteCastFx and #mode.bruteCastFx>0) or (mode.bruteImpactFx and #mode.bruteImpactFx>0)
    if not active then return end
    local previous={love.graphics.getColor()}
    for _,fx in ipairs(mode.bruteCastFx or {}) do
        local p=1-fx.life/fx.maxLife;local col=math.min(6,math.floor(p*6)+1)
        frame(1,col,fx.x,fx.y,0,.72,math.min(1,fx.life/.10))
    end
    for index,d in ipairs(mode.digits or {}) do
        local col=(index+math.floor((t or 0)*18))%3+1
        frame(2,col,d.x,d.y,math.atan2(d.vy,d.vx),.46,math.min(1,d.life/.12),W/2,H/2)
    end
    for _,fx in ipairs(mode.bruteImpactFx or {}) do
        local p=1-fx.life/fx.maxLife;local col=math.min(3,math.floor(p*3)+1)+3
        frame(2,col,fx.x,fx.y,0,.62,math.min(1,fx.life/.08))
    end
    love.graphics.setColor(unpack(previous))
end
return Art
