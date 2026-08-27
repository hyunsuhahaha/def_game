local Art={image=nil,charge={},ring={}}
function Art.load()
    if Art.image then return Art end
    Art.image=love.graphics.newImage('assets/fx/smoke-ring/smoke-ring-charge-atlas-pixel-v1.png');Art.image:setFilter('nearest','nearest')
    for i=0,5 do
        Art.charge[i+1]=love.graphics.newQuad(i*192,0,192,192,Art.image:getDimensions())
        Art.ring[i+1]=love.graphics.newQuad(i*192,192,192,192,Art.image:getDimensions())
    end
    return Art
end
function Art.drawCharge(mode,game,t)
    local charge=mode.smokeRingCharge;if not charge then return end;Art.load()
    local progress=math.min(1,charge.t/mode.smokeRingChargeDuration);local frame=math.min(6,math.floor(progress*5)+1)
    local _,mouthY,facing,tipX=mode:smokerMouthPose(game);local pulse=.94+math.sin(t*18)*.06
    local scale=(.34+progress*.18)*pulse
    love.graphics.setColor(1,1,1,.62+progress*.38)
    love.graphics.draw(Art.image,Art.charge[frame],math.floor(tipX+.5),math.floor(mouthY+.5),-facing*math.pi*.5,scale,scale,96,176)
    if progress>.86 then
        love.graphics.setColor(1,.58,.22,.32+math.sin(t*24)*.16)
        love.graphics.draw(Art.image,Art.ring[6],math.floor(tipX+.5),math.floor(mouthY+.5),t*.9,.18+.03*math.sin(t*20),.18+.03*math.sin(t*20),96,96)
    end
    love.graphics.setColor(1,1,1,1)
end
function Art.drawRing(ring,t)
    if not ring then return end;Art.load()
    local progress=math.min(1,ring.traveled/ring.maxRange);local frame=math.min(6,math.floor((t*10+progress*4)%6)+1)
    local scale=ring.radius/78;local pulse=ring.charged and (1+.045*math.sin(t*16)) or 1
    love.graphics.setColor(1,ring.charged and .88 or 1,ring.charged and .72 or 1,ring.charged and 1 or .86)
    love.graphics.draw(Art.image,Art.ring[frame],math.floor(ring.x+.5),math.floor(ring.y+.5),t*(ring.charged and .75 or .38),scale*pulse,scale*pulse,96,96)
    love.graphics.setColor(1,1,1,1)
end
return Art
