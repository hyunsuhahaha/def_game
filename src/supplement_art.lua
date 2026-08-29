-- Rendering and short-lived visual events only. No damage, targeting or RNG here.
local Art={}
local assets,shader
local function load()
    if assets then return end
    assets={}
    for id,spec in pairs(require("src.supplement_sprite_catalog")) do
        local image=love.graphics.newImage(spec.file);image:setFilter("nearest","nearest")
        local frames={}
        for i=0,spec.frames-1 do frames[i+1]=love.graphics.newQuad(i*spec.w,0,spec.w,spec.h,image:getDimensions()) end
        assets[id]={image=image,frames=frames,spec=spec}
    end
    shader=love.graphics.newShader("assets/shaders/supplement-fx.glsl")
end
local function sprite(id,x,y,angle,clock,alpha,scale)
    local a=assets[id];local s=a.spec;local k=s.width/s.bodyWidth*(scale or 1)
    local frame=math.floor((clock or 0)*14)%s.frames+1
    love.graphics.setShader(nil);love.graphics.setColor(1,1,1,alpha or 1)
    love.graphics.draw(a.image,a.frames[frame],math.floor(x+.5),math.floor(y+.5),angle or 0,k,k,s.w/2,s.h/2)
end
local function patch(kind,x,y,w,h,p,t,angle,variant,strength,boundary,alpha)
    shader:send("gridSize",{math.ceil(w*3.2),math.ceil(h*3.2)})
    shader:send("effectKind",kind);shader:send("clock",t or 0);shader:send("progress",p or 0)
    shader:send("variant",variant or 0);shader:send("strength",strength or 1);shader:send("boundary",boundary or .95)
    love.graphics.setShader(shader);love.graphics.setColor(1,1,1,alpha or 1)
    -- Full single-frame seed texture supplies 0..1 UVs; procedural shader ignores texels.
    local image=assets.seed.image;local iw,ih=image:getDimensions()
    love.graphics.draw(image,math.floor(x+.5),math.floor(y+.5),angle or 0,w/iw,h/ih,iw/2,ih/2)
end
function Art.update(mode,dt)
    mode.supplementTime=(mode.supplementTime or 0)+dt
    for i=#(mode.supplementImpacts or {}),1,-1 do
        local e=mode.supplementImpacts[i];e.life=e.life-dt
        if e.life<=0 then table.remove(mode.supplementImpacts,i) end
    end
end
function Art.impact(mode,kind,x,y,radius)
    mode.supplementImpacts=mode.supplementImpacts or {}
    if #mode.supplementImpacts>=64 then table.remove(mode.supplementImpacts,1) end
    local life=kind=="seed" and .55 or .20
    mode.supplementImpacts[#mode.supplementImpacts+1]={kind=kind,x=x,y=y,radius=radius,life=life,maxLife=life}
end
local function isActive(mode)
    local active=mode.auraRadius and mode:levelOf("thorn_aura")>0
    for _,key in ipairs({"bats","crowFx","whipFx","boomerangs","seeds","sproutFields","friendlyGrowthBursts","lightningFx","supplementImpacts"}) do
        if mode[key] and #mode[key]>0 then active=true;break end
    end
    return active
end
local function beginDraw(mode,t)
    if not isActive(mode) then return end
    load();return love.graphics.getShader(),{love.graphics.getColor()},mode.supplementTime or t or 0
end
local function finishDraw(previous,color)
    love.graphics.setShader(previous);love.graphics.setColor(unpack(color))
end

-- Every patch in this pass describes a gameplay footprint. Drawing it into the
-- projected ground canvas makes its visible boundary use the same world-space
-- circle/cone/radius as collision, at every camera tilt.
function Art.drawGround(mode,game,t)
    local previous,color,clock=beginDraw(mode,t);if not previous and not color then return end
    t=clock;local px,py=game.player.x,game.player.y
    if mode.auraRadius and mode:levelOf("thorn_aura")>0 then
        local radius=mode.auraRadius;local pulse=mode.auraPulse or 0
        patch(1,px,py,(radius+10)*2,(radius+10)*2,1-pulse,t,0,0,pulse,radius/(radius+10))
    end
    for _,s in ipairs(mode.seeds or {}) do
        local p=1-s.fuse/s.maxFuse
        patch(7,s.x,s.y+5,72,46,p,t,0,1)
    end
    for _,field in ipairs(mode.sproutFields or {})do
        local p=1-field.life/field.maxLife;local fade=math.min(1,field.life/.55)
        patch(1,field.x,field.y,field.radius*2.08,field.radius*2.08,p,t,0,5,.78,.96,fade*.78)
    end
    for _,field in ipairs(mode.friendlyGrowthBursts or {})do
        local p=1-field.life/field.maxLife
        patch(1,field.x,field.y,field.radius*2.08,field.radius*2.08,p,t,0,6,1,.96,1-p)
    end
    for _,fx in ipairs(mode.whipFx or {}) do
        patch(2,fx.x or px,fx.y or py,fx.range*2.1,fx.range*2.1,1-fx.life/fx.maxLife,t,fx.angle,0,1,1/1.05)
    end
    for _,b in ipairs(mode.boomerangs or {}) do
        local hitRadius=b.radius or 64
        patch(6,b.x,b.y,hitRadius*2.08,hitRadius*2.08,.45,t,t*17,b.phase=="back" and 4 or 0,1,.96,.65)
    end
    for _,fx in ipairs(mode.crowFx or {}) do
        local p=1-fx.life/fx.maxLife;local angle=fx.angle or -math.pi/2
        local radius=fx.radius or 54;patch(6,fx.x,fx.y,radius*2.08,radius*2.08,p,t,angle,0)
    end
    for _,fx in ipairs(mode.lightningFx or {}) do
        local p=1-fx.life/fx.maxLife
        for i=2,#fx.points do
            local from,to=fx.points[i-1],fx.points[i];local dx,dy=to.x-from.x,to.y-from.y
            local distance=math.sqrt(dx*dx+dy*dy)
            if distance>.001 then patch(4,(from.x+to.x)/2,(from.y+to.y)/2,distance,46,p,t,math.atan2(dy,dx),i) end
            patch(6,to.x,to.y,68,68,p,t,0,0)
        end
    end
    for _,fx in ipairs(mode.supplementImpacts or {}) do
        local p=1-fx.life/fx.maxLife
        if fx.kind=="seed" then patch(3,fx.x,fx.y,fx.radius*2.15,fx.radius*2.15,p,t,0,3)
        end
    end
    finishDraw(previous,color)
end

function Art.drawUpright(mode,game,t)
    local previous,color,clock=beginDraw(mode,t);if not previous and not color then return end
    t=clock
    for _,s in ipairs(mode.seeds or {}) do
        local p=1-s.fuse/s.maxFuse;sprite("seed",s.x,s.y-9,math.sin(t*(5+p*12))*.035,t,1,1+p*.13)
        if p>.70 then patch(6,s.x,s.y-12,35,35,1-(math.sin(t*24)+1)*.5,t,0,4) end
    end
    for _,b in ipairs(mode.boomerangs or {}) do
        for i=#(b.trail or {}),1,-1 do local q=b.trail[i];sprite("axe",q.x,q.y,q.angle,t,.10+(1-i/#b.trail)*.15) end
        sprite("axe",b.x,b.y,t*17,t)
    end
    for _,bat in ipairs(mode.bats or {}) do if bat.x then
        local direction=bat.flightAngle or math.atan2(math.cos(bat.angle)*.6,-math.sin(bat.angle))
        sprite("bat",bat.x,bat.y,direction+math.pi/2,t+bat.angle)
    end end
    for _,fx in ipairs(mode.crowFx or {}) do
        local p=1-fx.life/fx.maxLife;local angle=fx.angle or -math.pi/2
        for i=1,3 do local spread=(i-2)*.28;local a=angle+spread;local travel=p*(75+i*13)
            sprite("crow",fx.x+math.cos(a)*travel,fx.y+math.sin(a)*travel,a+math.pi/2,t+i*.1,1-p*.65,i==2 and 1 or .68)
        end
    end
    for _,fx in ipairs(mode.supplementImpacts or {}) do
        local p=1-fx.life/fx.maxLife
        if fx.kind=="bat" then patch(6,fx.x,fx.y,64,64,p,t,0,2,1,.92,1-p*.35)
        elseif fx.kind=="infection" then patch(5,fx.x,fx.y-12,45,50,p,t,0,3,1,.95,1-p)
        elseif fx.kind~="seed" then patch(6,fx.x,fx.y,48,48,p,t,0,fx.kind=="axe" and 4 or 0) end
    end
    finishDraw(previous,color)
end

function Art.draw(mode,game,t)
    Art.drawGround(mode,game,t);Art.drawUpright(mode,game,t)
end
return Art
