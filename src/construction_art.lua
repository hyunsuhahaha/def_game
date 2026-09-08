local Art={}
local tower,jib,tracks,pipes,frames,trackFrames,dust,dustFrames
local function load()
    if tower then return end
    tower=love.graphics.newImage("assets/construction/tower-crane-pixel-v2.png")
    jib=love.graphics.newImage("assets/construction/tower-jib-pixel-v2.png")
    tracks=love.graphics.newImage("assets/construction/crane-tracks-atlas-v1.png")
    pipes={}
    for i=1,3 do pipes[i]=love.graphics.newImage("assets/construction/grounded-concrete-pipe-"..i.."-atlas-v3.png");pipes[i]:setFilter("nearest","nearest")end
    dust=love.graphics.newImage("assets/construction/concrete-contact-dust-atlas-v1.png")
    for _,im in ipairs({tower,jib,tracks,dust})do im:setFilter("nearest","nearest")end
    frames={};for dir=0,15 do for i=0,7 do frames[dir*8+i+1]=love.graphics.newQuad(i*640,dir*544,640,544,pipes[1]:getDimensions())end end
    dustFrames={};for i=0,7 do dustFrames[i+1]=love.graphics.newQuad(i*192,0,192,128,dust:getDimensions())end
    trackFrames={};for i=0,5 do trackFrames[i+1]=love.graphics.newQuad(i*448,0,448,128,tracks:getDimensions())end
end

function Art.drawPipe(load)
    local scale=load.stats.radius/50
    local direction=math.floor(math.atan2(load.ny,load.nx)/(math.pi*2)*16+.5)%16
    local frame=direction*8+math.floor((load.roll or 0)/(math.pi*2)*8)%8+1
    -- The end caps and surface were projected in 3D; the sprite never rotates.
    -- Contact shadows follow the ground axis, not the barrel's screen rectangle.
    local half=load.halfLength or load.stats.radius*3
    love.graphics.setColor(0,0,0,.20)
    for i=-6,6 do
        local s=half*i/6
        love.graphics.ellipse("fill",load.x-load.ny*s,load.y+load.nx*s*.76,load.stats.radius*.7,load.stats.radius*.3)
    end
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(pipes[math.min(3,load.stats.payload)],frames[frame],load.x,load.y-(load.height or 0),0,scale,scale,320,300)
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
    for _,item in ipairs(c.contactDust or {})do local puff=item
        queue[#queue+1]={x=puff.x,y=puff.y,anchorY=puff.y,draw=function()
            love.graphics.setColor(1,1,1,1)
            local frame=math.min(8,math.floor(puff.age/.65*8)+1)
            love.graphics.draw(dust,dustFrames[frame],puff.x,puff.y,0,puff.scale,puff.scale,96,110)
        end}
    end
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
