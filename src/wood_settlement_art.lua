local Art={}
local logImage,coinImage,coinQuads

local function load()
    if logImage then return end
    logImage=love.graphics.newImage("assets/scenery/forest/log-pixel-v1.png")
    coinImage=love.graphics.newImage("assets/ui/research-coin-spin-pixel-v1.png")
    logImage:setFilter("nearest","nearest");coinImage:setFilter("nearest","nearest")
    coinQuads={}
    for i=0,5 do coinQuads[#coinQuads+1]=love.graphics.newQuad(i*64,0,64,64,384,64)end
end

function Art.drawLog(x,y,scale,color,alpha)
    load();local iw,ih=logImage:getDimensions();color=color or{1,1,1};alpha=alpha or 1
    love.graphics.setColor(color[1],color[2],color[3],alpha)
    love.graphics.draw(logImage,x,y,0,scale,scale,iw/2,ih/2)
end
function Art.drawCoin(x,y,time,scale,alpha)
    load();local frame=math.floor((time or 0)*14)%6+1
    love.graphics.setColor(1,1,1,alpha or 1)
    love.graphics.draw(coinImage,coinQuads[frame],x,y,0,scale or 1,scale or 1,32,32)
end
return Art
