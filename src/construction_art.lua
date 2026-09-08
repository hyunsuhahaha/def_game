local Art={}
local tower,jib,pipes,frames
local function load()
    if tower then return end
    tower=love.graphics.newImage("assets/construction/tower-crane-pixel-v1.png")
    jib=love.graphics.newImage("assets/construction/tower-jib-pixel-v1.png")
    pipes=love.graphics.newImage("assets/construction/concrete-pipe-roll-atlas-v1.png")
    for _,im in ipairs({tower,jib,pipes})do im:setFilter("nearest","nearest")end
    frames={};for i=0,11 do frames[i+1]=love.graphics.newQuad(i*192,0,192,192,pipes:getDimensions())end
end

function Art.drawPipe(load)
    local scale=load.stats.radius/75
    local frame=math.floor((load.roll or 0)/(math.pi*2)*12)%12+1
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(pipes,frames[frame],load.x,load.y-(load.height or 0),0,scale,scale,90,170)
end

function Art.queue(c,queue)
    load()
    queue[#queue+1]={x=c.towerX,y=c.towerY,anchorY=c.towerY,draw=function()
        local latest=c.loads[#c.loads]
        if latest and latest.height<=0 then latest=nil end
        local tx=latest and latest.x or c.controlX or c.towerX+220
        local ty=latest and latest.y or c.controlY or c.towerY
        local dx,dy=tx-c.towerX,ty-c.towerY
        local length=math.sqrt(dx*dx+dy*dy)
        local angle=math.atan2(dy,dx)
        love.graphics.setColor(1,1,1,1)
        love.graphics.draw(tower,c.towerX,c.towerY,0,.75,.75,128,552)
        -- A separate steel jib pivots at the mast; the hoist follows the actual
        -- load, and lets go exactly when that load reaches ground contact.
        love.graphics.draw(jib,c.towerX,c.towerY-339,angle,math.max(.25,(length+60)/670),.5,100,48)
        if latest and latest.height>0 then
            love.graphics.setColor(.22,.26,.27,1);love.graphics.setLineWidth(2)
            love.graphics.line(tx,ty-339,tx,ty-latest.height-latest.stats.radius*2)
            love.graphics.setLineWidth(1)
        end
    end}
    for _,item in ipairs(c.loads)do local material=item
        queue[#queue+1]={x=material.x,y=material.y,anchorY=material.y,draw=function()Art.drawPipe(material)end}
    end
end
return Art
