local Art={image=nil,quads={}}
function Art.load()
    if Art.image then return Art end
    Art.image=love.graphics.newImage('assets/fx/philosopher/revival-crowd-atlas-pixel-v1.png');Art.image:setFilter('nearest','nearest')
    for row=1,3 do Art.quads[row]={};for col=1,6 do Art.quads[row][col]=love.graphics.newQuad((col-1)*96,(row-1)*160,96,160,Art.image:getDimensions()) end end
    return Art
end
function Art.start(mode,game)
    mode.revivalCrowd={age=0,people={}}
    for i=1,9 do
        local a=(i/9)*math.pi*2;local r=72+(i%3)*19
        mode.revivalCrowd.people[i]={x=game.player.x+math.cos(a)*r,y=game.player.y+math.sin(a)*r*.52,variant=(i-1)%3+1,seed=i*1.73}
    end
end
function Art.update(mode,dt)
    if mode.revivalCrowd then
        mode.revivalCrowd.age=mode.revivalCrowd.age+dt
        for _,person in ipairs(mode.revivalCrowd.people) do person.chorusTimer=math.max(0,(person.chorusTimer or 0)-dt) end
        if (mode.revivalTimer or 0)<=0 then mode.revivalCrowd=nil end
    end
end
function Art.queue(mode,queue)
    Art.load();local crowd=mode.revivalCrowd;if not crowd then return end
    local alpha=math.min(1,crowd.age*5,math.max(0,mode.revivalTimer or 0)*3)
    for _,p in ipairs(crowd.people) do
        local person=p;queue[#queue+1]={x=person.x,y=person.y,draw=function()
            local frame=crowd.age<.22 and 1 or (math.floor(crowd.age*8+person.seed)%5+2)
            local centerX=(person.chorusTimer or 0)>0 and person.chorusTargetX or (mode.revivalCenterX or person.x);local flip=person.x<centerX and 1 or -1
            love.graphics.setColor(1,1,1,alpha);love.graphics.draw(Art.image,Art.quads[person.variant][frame],math.floor(person.x+.5),math.floor(person.y+.5),0,.47*flip,.47,48,157);love.graphics.setColor(1,1,1,1)
        end}
    end
end
return Art
