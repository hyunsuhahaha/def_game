local TraitFx = {}
TraitFx.__index = TraitFx

local palettes = {
    axe={.96,.66,.26}, fire={1,.31,.10}, bite={.48,.86,.28},
    heal={.35,1,.54}, dash={.35,.70,.92}, blast={1,.62,.20}, refund={.35,.82,1},
    construction_dash={.88,.48,.12}, construction_blast={.96,.58,.16}, construction_refund={.92,.67,.24}
}

local function colorOf(kind, override)
    return override or palettes[kind] or {1,.8,.3}
end

function TraitFx.new()
    return setmetatable({events={}, particles={}, time=0},TraitFx)
end

function TraitFx:emit(kind,x,y,options)
    options=options or {}
    local duration=options.duration or ((kind=="dash" or kind=="construction_dash") and .28 or .62)
    local color=colorOf(kind,options.color)
    self.events[#self.events+1]={kind=kind,x=x,y=y,life=duration,maxLife=duration,color=color,angle=options.angle or 0,radius=options.radius or 72,power=options.power or 1}
    local count=options.particles or ((kind=="dash" or kind=="construction_dash") and 5 or 18)
    for i=1,count do
        local angle=(i/count)*math.pi*2 + math.random()*.35 + (options.angle or 0)
        local speed=(35+math.random()*125)*(options.power or 1)
        self.particles[#self.particles+1]={
            kind=kind,x=x,y=y-(kind=="heal" and 18 or 0),
            vx=math.cos(angle)*speed,vy=math.sin(angle)*speed-(kind=="heal" and 55 or 0),
            life=.28+math.random()*.42,maxLife=.7,color=color,size=2+math.random()*4
        }
    end
end

function TraitFx:update(dt)
    self.time=self.time+dt
    for i=#self.events,1,-1 do
        local event=self.events[i]; event.life=event.life-dt
        if event.life<=0 then table.remove(self.events,i) end
    end
    for i=#self.particles,1,-1 do
        local p=self.particles[i]
        p.life=p.life-dt; p.x=p.x+p.vx*dt; p.y=p.y+p.vy*dt
        p.vx=p.vx*(1-dt*2.2); p.vy=p.vy*(1-dt*2.2)+(p.kind=="fire" and -35 or 70)*dt
        if p.life<=0 then table.remove(self.particles,i) end
    end
end

local function drawArc(cx,cy,r,a1,a2,segments)
    local points={}
    for i=0,segments do
        local a=a1+(a2-a1)*i/segments
        points[#points+1],points[#points+1]=cx+math.cos(a)*r,cy+math.sin(a)*r*.58
    end
    love.graphics.line(points)
end

local function drawEvent(event,time)
    local p=1-event.life/event.maxLife
    local fade=(1-p)^1.4
    local r,g,b=event.color[1],event.color[2],event.color[3]
    if event.kind=="axe" then
        love.graphics.setLineWidth(12*(1-p)+2); love.graphics.setColor(r,g,b,.16*fade)
        drawArc(event.x,event.y-25,event.radius*(.7+p*.45),event.angle-1.1,event.angle+1.1,24)
        love.graphics.setLineWidth(3); love.graphics.setColor(1,.91,.66,.95*fade)
        drawArc(event.x,event.y-25,event.radius*(.72+p*.42),event.angle-1.1,event.angle+1.1,24)
    elseif event.kind=="fire" then
        local radius=event.radius*(.25+p*.9)
        love.graphics.setColor(r,g,b,.16*fade); love.graphics.circle("fill",event.x,event.y,radius)
        love.graphics.setLineWidth(5*(1-p)+1); love.graphics.setColor(1,.68,.18,.92*fade); love.graphics.circle("line",event.x,event.y,radius)
        love.graphics.setColor(1,.86,.35,.5*fade)
        for i=1,9 do
            local a=i/9*math.pi*2+time
            love.graphics.polygon("fill",event.x+math.cos(a)*radius,event.y+math.sin(a)*radius*.58-8,event.x+math.cos(a)*radius-4,event.y+math.sin(a)*radius*.58+5,event.x+math.cos(a)*radius+4,event.y+math.sin(a)*radius*.58+5)
        end
    elseif event.kind=="bite" then
        love.graphics.setLineWidth(6*(1-p)+2); love.graphics.setColor(r,g,b,.85*fade)
        drawArc(event.x,event.y,event.radius*(.55+p*.35),math.pi*.10,math.pi*.90,18)
        drawArc(event.x,event.y,event.radius*(.55+p*.35),math.pi*1.10,math.pi*1.90,18)
        for i=1,6 do
            local a=.2+i*.13
            love.graphics.polygon("fill",event.x+(a-.5)*event.radius,event.y-8,event.x+(a-.54)*event.radius,event.y-20,event.x+(a-.46)*event.radius,event.y-20)
        end
    elseif event.kind=="heal" then
        love.graphics.setColor(r,g,b,.22*fade); love.graphics.circle("fill",event.x,event.y-28,25+p*20)
        love.graphics.setColor(.8,1,.82,.95*fade)
        love.graphics.rectangle("fill",event.x-4,event.y-46-p*16,8,30,2,2)
        love.graphics.rectangle("fill",event.x-15,event.y-35-p*16,30,8,2,2)
    elseif event.kind=="dash" then
        love.graphics.push(); love.graphics.translate(event.x,event.y); love.graphics.rotate(event.angle)
        love.graphics.setColor(r,g,b,.14*fade); love.graphics.rectangle("fill",-event.radius*(1+p),-18,event.radius*(1+p),36)
        love.graphics.setColor(.76,.91,1,.75*fade)
        for i=0,2 do love.graphics.line(-event.radius*(.3+i*.24),-12+i*12,-event.radius*(.75+i*.12),-12+i*12) end
        love.graphics.pop()
    elseif event.kind=="construction_dash" then
        love.graphics.push(); love.graphics.translate(math.floor(event.x+.5),math.floor(event.y+.5)); love.graphics.rotate(event.angle)
        for i=0,4 do
            local x=-event.radius*(.25+i*.22)-p*event.radius*.5
            love.graphics.setColor(.16,.12,.08,.72*fade); love.graphics.rectangle("fill",math.floor(x)-9,-15+i%2*18,18,7)
            love.graphics.setColor(r,g,b,.8*fade); love.graphics.rectangle("fill",math.floor(x)-7,-13+i%2*18,14,3)
        end
        love.graphics.pop()
    elseif event.kind=="construction_blast" then
        local radius=event.radius*(.22+p*.82)
        for i=1,16 do
            local a=i/16*math.pi*2
            local px=math.floor(event.x+math.cos(a)*radius+.5)
            local py=math.floor(event.y+math.sin(a)*radius*.58+.5)
            local size=(i%2==0 and 8 or 5)
            love.graphics.setColor(.19,.14,.09,.55*fade); love.graphics.rectangle("fill",px-size-2,py-size-2,(size+2)*2,(size+2)*2)
            love.graphics.setColor(i%3==0 and 1 or r,i%3==0 and .78 or g,.18,.9*fade); love.graphics.rectangle("fill",px-size,py-size,size*2,size*2)
        end
    elseif event.kind=="construction_refund" then
        local rise=math.floor(p*26)
        love.graphics.setColor(.18,.14,.08,.65*fade); love.graphics.rectangle("fill",event.x-23,event.y-42-rise,46,26)
        love.graphics.setColor(r,g,b,.95*fade)
        love.graphics.rectangle("fill",event.x-19,event.y-38-rise,38,18)
        love.graphics.setColor(.10,.13,.14,.95*fade)
        love.graphics.rectangle("fill",event.x-12,event.y-33-rise,24,4)
        love.graphics.rectangle("fill",event.x-2,event.y-38-rise,4,14)
    elseif event.kind=="blast" then
        local radius=event.radius*(.18+p)
        love.graphics.setColor(r,g,b,.13*fade); love.graphics.circle("fill",event.x,event.y,radius)
        love.graphics.setLineWidth(7*(1-p)+1); love.graphics.setColor(1,.83,.42,.9*fade); love.graphics.circle("line",event.x,event.y,radius)
        love.graphics.setColor(.25,.20,.14,.7*fade)
        for i=1,12 do local a=i/12*math.pi*2; local rr=radius*.65; love.graphics.rectangle("fill",event.x+math.cos(a)*rr-3,event.y+math.sin(a)*rr*.58-3,6,6) end
    elseif event.kind=="refund" then
        local radius=24+p*55
        love.graphics.setLineWidth(4); love.graphics.setColor(r,g,b,.9*fade); love.graphics.circle("line",event.x,event.y,radius)
        for i=1,3 do
            local a=-math.pi/2+i*.18
            love.graphics.polygon("fill",event.x+math.cos(a)*radius,event.y+math.sin(a)*radius,event.x+math.cos(a-.18)*(radius-12),event.y+math.sin(a-.18)*(radius-12),event.x+math.cos(a+.18)*(radius-12),event.y+math.sin(a+.18)*(radius-12))
        end
    end
    love.graphics.setLineWidth(1)
end

function TraitFx:draw()
    for _,event in ipairs(self.events) do drawEvent(event,self.time) end
    for _,particle in ipairs(self.particles) do
        local fade=math.max(0,particle.life/particle.maxLife)
        local r,g,b=particle.color[1],particle.color[2],particle.color[3]
        local size=particle.size
        if particle.kind:match("^construction_") then
            local px,py=math.floor(particle.x+.5),math.floor(particle.y+.5)
            love.graphics.setColor(.17,.12,.08,.35*fade); love.graphics.rectangle("fill",px-size-2,py-size-2,(size+2)*2,(size+2)*2)
            love.graphics.setColor(math.min(1,r*1.12),math.min(1,g*1.08),b,fade); love.graphics.rectangle("fill",px-size,py-size,size*2,size*2)
        else
            love.graphics.setColor(r,g,b,.22*fade); love.graphics.circle("fill",particle.x,particle.y,particle.size*2.2)
            love.graphics.setColor(math.min(1,r*1.2),math.min(1,g*1.2),math.min(1,b*1.2),fade)
            love.graphics.polygon("fill",particle.x,particle.y-size,particle.x+size,particle.y,particle.x,particle.y+size,particle.x-size,particle.y)
        end
    end
end

return TraitFx
