local Art={}
local tower,jib,tracks,pipes,frames,trackFrames
local function load()
    if tower then return end
    tower=love.graphics.newImage("assets/construction/tower-crane-pixel-v2.png")
    jib=love.graphics.newImage("assets/construction/tower-jib-pixel-v2.png")
    tracks=love.graphics.newImage("assets/construction/crane-tracks-atlas-v1.png")
    pipes=love.graphics.newImage("assets/construction/concrete-long-pipe-roll-atlas-v2.png")
    for _,im in ipairs({tower,jib,tracks,pipes})do im:setFilter("nearest","nearest")end
    frames={};for i=0,11 do frames[i+1]=love.graphics.newQuad(i*640,0,640,192,pipes:getDimensions())end
    trackFrames={};for i=0,5 do trackFrames[i+1]=love.graphics.newQuad(i*448,0,448,128,tracks:getDimensions())end
end

function Art.drawPipe(load)
    local scale=load.stats.radius/75
    local frame=math.floor((load.roll or 0)/(math.pi*2)*12)%12+1
    local angle=math.atan2(load.ny,load.nx)+math.pi/2
    local lengthScale=(load.halfLength or load.stats.radius*3)/257
    love.graphics.setColor(0,0,0,.24)
    love.graphics.push();love.graphics.translate(load.x,load.y);love.graphics.rotate(angle)
    love.graphics.ellipse("fill",0,0,(load.halfLength or 126)+load.stats.radius,load.stats.radius*.45)
    love.graphics.pop()
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(pipes,frames[frame],load.x,load.y-(load.height or 0)-load.stats.radius,
        angle,lengthScale,scale,312,94)
end

function Art.drawCrane(c,actor)
    load()
    local x,y=actor.x,actor.y
    local dx,dy=(c.aimX or x+280)-x,(c.aimY or y)-y
    local length=math.sqrt(dx*dx+dy*dy)
    if length<1 then dx,dy,length=1,0,1 end
    local nx,ny=dx/length,dy/length
    local frame=actor.isMoving and math.floor(actor.walkClock*2)%6+1 or 1
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(tracks,trackFrames[frame],x,y,0,.75,.75,224,114)
    love.graphics.draw(tower,x,y,0,.75,.75,224,864)
    -- Rigid long jib foreshortens into the ground plane, never stretches
    -- to the mouse. Its hoist works over the material release point.
    local foreshorten=math.sqrt(nx*nx+ny*ny*.16)
    local angle=math.atan2(ny*.4,nx)
    love.graphics.draw(jib,x,y-509.25,angle,.75*foreshorten,.75,260,72)
    local hx,hy=x+nx*c.launchDistance,y+ny*c.launchDistance
    local top=y-509.25+ny*c.launchDistance*.4
    local bottom=hy-c.dropHeight-c.stats.radius*2
    love.graphics.setColor(.22,.26,.27,1);love.graphics.setLineWidth(3)
    love.graphics.line(hx,top,hx,bottom)
    love.graphics.setLineWidth(1);love.graphics.setColor(1,1,1,1)
end

function Art.queue(c,queue)
    load()
    -- The crane is the actual Player draw entry, with no second human body.
    for _,item in ipairs(c.loads)do local material=item
        queue[#queue+1]={x=material.x,y=material.y,anchorY=material.y,draw=function()Art.drawPipe(material)end}
    end
    for _,item in ipairs(c.flyingTrees or {})do local tree=item
        queue[#queue+1]={x=tree.x,y=tree.y,anchorY=tree.y,draw=function()
            love.graphics.setColor(0,0,0,.26)
            love.graphics.ellipse("fill",tree.x,tree.y,48,16)
            love.graphics.setColor(1,1,1,1)
            love.graphics.draw(tree.image,tree.x,tree.y-tree.height,tree.angle,tree.scale,tree.scale,
                tree.image:getWidth()/2,tree.image:getHeight()*.91)
        end}
    end
end
return Art
