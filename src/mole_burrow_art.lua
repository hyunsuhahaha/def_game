local Art={}
local image,quads
local CELL=128
local function load()
    if image then return end
    image=love.graphics.newImage("assets/fx/mole-burrow/mole-burrow-trail-atlas-pixel-v1.png");image:setFilter("nearest","nearest")
    quads={}
    for row=0,1 do quads[row+1]={};for col=0,5 do quads[row+1][col+1]=love.graphics.newQuad(col*CELL,row*CELL,CELL,CELL,image:getDimensions()) end end
end
function Art.draw(mark)
    load();local previous={love.graphics.getColor()}
    local fade=math.min(1,(mark.life or 0)/3)
    local row,column=1,mark.variant or 1
    if mark.kind then row=2;column=({entry=1,exit=2,burst=3,root=4,settle=5,old=6})[mark.kind] or 5 end
    love.graphics.setColor(1,1,1,.92*fade)
    love.graphics.draw(image,quads[row][column],math.floor(mark.x+.5),math.floor(mark.y+.5),mark.angle or 0,.58,.58,CELL/2,116)
    love.graphics.setColor(unpack(previous))
end
return Art
