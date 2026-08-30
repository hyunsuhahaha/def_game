local Art={image=nil,quads=nil,frameCount=12,frameW=768,frameH=384}

local function load()
    if Art.image then return end
    local ok,image=pcall(love.graphics.newImage,"assets/fx/score-tier-up-atlas-pixel-v1.png")
    if not ok then return end
    image:setFilter("nearest","nearest")
    Art.image=image;Art.quads={}
    for i=0,Art.frameCount-1 do
        Art.quads[i+1]=love.graphics.newQuad(i*Art.frameW,0,Art.frameW,Art.frameH,image:getDimensions())
    end
end

function Art.draw(fx,fonts,w,h)
    if not fx then return end
    load();if not Art.image then return end
    local p=math.min(1,math.max(0,fx.t/fx.duration))
    local index=math.min(Art.frameCount,math.floor(p*Art.frameCount)+1)
    local alpha=math.min(1,p*9,(1-p)*7)
    local pop=1+math.sin(math.min(1,p/.42)*math.pi)*.075
    local cx,cy=w*.5,math.min(h*.32,184)
    love.graphics.push()
    love.graphics.translate(math.floor(cx+.5),math.floor(cy+.5))
    love.graphics.scale(pop,pop)
    love.graphics.setColor(1,1,1,alpha)
    love.graphics.draw(Art.image,Art.quads[index],0,0,0,.3125,.3125,Art.frameW*.5,Art.frameH*.5)
    love.graphics.setFont(fonts.micro or fonts.small)
    love.graphics.setColor(.04,.09,.035,.92*alpha)
    love.graphics.printf("재생 단계",-119,-15+2,240,"center")
    love.graphics.setColor(.82,1,.48,alpha)
    love.graphics.printf("재생 단계",-120,-15,240,"center")
    love.graphics.setFont(fonts.display or fonts.big)
    love.graphics.setColor(.05,.07,.025,.92*alpha)
    love.graphics.printf(tostring(fx.toTier),-119,6,240,"center")
    love.graphics.setColor(1,.86,.30,alpha)
    love.graphics.printf(tostring(fx.toTier),-120,5,240,"center")
    love.graphics.pop()
    love.graphics.setColor(1,1,1,1)
end

return Art
