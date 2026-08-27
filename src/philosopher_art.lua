local Art={image=nil,quads={}}
function Art.load()
    if Art.image then return Art end
    Art.image=love.graphics.newImage("assets/fx/philosopher/philosopher-sermon-fx-pixel-v1.png")
    Art.image:setFilter("nearest","nearest")
    for i=0,5 do Art.quads[i+1]=love.graphics.newQuad(i*192,0,192,192,Art.image:getDimensions()) end
    return Art
end
function Art.channel(mode,game,active,tx,ty,power,revival)
    if not active then mode.philosopherChannel=nil;return end
    local facing=game.player.facing or 1
    local stream=mode.philosopherChannel or {t=0}
    stream.x=game.player.x+facing*23
    stream.y=game.player.y-48
    stream.tx,stream.ty,stream.power,stream.revival=tx,ty,power or 0,revival or false
    mode.philosopherChannel=stream
end
function Art.update(mode,dt)
    if mode.philosopherChannel then mode.philosopherChannel.t=mode.philosopherChannel.t+dt end
end
function Art.draw(mode)
    local v=mode.philosopherChannel;if not v then return end
    local dx,dy=v.tx-v.x,v.ty-v.y;local dist=math.sqrt(dx*dx+dy*dy);if dist<2 then return end
    Art.load()
    local nx,ny=dx/dist,dy/dist;local angle=math.atan2 and math.atan2(dy,dx) or math.atan(dy,dx)
    local gap=math.max(18,28-(v.power or 0)*7);local count=math.max(4,math.floor(dist/gap)+2);local travel=(v.t*390)%gap
    love.graphics.setColor(1,1,1,1)
    local firstLane=v.revival and -1 or 0;local lastLane=v.revival and 1 or 0
    for lane=firstLane,lastLane do
        for i=0,count do
            local along=(i*gap+travel+lane*gap*.34)%dist;local p=along/dist
            local spread=lane*p*(18+dist*.055)
            local wobble=math.sin(v.t*24+i*1.9+lane)*math.min(7,2+dist*.012)
            local x=v.x+nx*along-ny*(wobble+spread);local y=v.y+ny*along+nx*(wobble+spread)
            local frame=(i+lane+math.floor(v.t*18))%6+1;local scale=.20+(v.power or 0)*.055+(i%3)*.018
            love.graphics.draw(Art.image,Art.quads[frame],math.floor(x+.5),math.floor(y+.5),angle,scale,scale,96,96)
        end
    end
end
return Art
