local Art={poolImage=nil,poolQuads={},chorusImage=nil,chorusQuads={}}

function Art.load()
    if Art.poolImage then return Art end
    Art.poolImage=love.graphics.newImage("assets/fx/philosopher/eternal-return-field-atlas-pixel-v1.png")
    Art.poolImage:setFilter("nearest","nearest")
    for i=0,5 do Art.poolQuads[i+1]=love.graphics.newQuad(i*384,0,384,256,Art.poolImage:getDimensions()) end
    Art.chorusImage=love.graphics.newImage("assets/fx/philosopher/revival-chorus-atlas-pixel-v1.png")
    Art.chorusImage:setFilter("nearest","nearest")
    for i=0,5 do Art.chorusQuads[i+1]=love.graphics.newQuad(i*256,0,256,256,Art.chorusImage:getDimensions()) end
    return Art
end

local function poolFrame(pool)
    if pool.age<.22 then return 1+math.min(1,math.floor(pool.age/.11)) end
    if pool.life<.5 then return 6 end
    return 3+(math.floor((pool.age-.22)*4)%3)
end

function Art.queue(mode,queue)
    if not mode.eternalFields or #mode.eternalFields==0 then return end
    Art.load()
    for _,value in ipairs(mode.eternalFields or {}) do
        local field=value
        queue[#queue+1]={y=-150000+field.y*.001,draw=function()
            local scale=(field.radius or 100)/132
            local alpha=math.min(1,field.age*5,field.life*2.4)
            love.graphics.setColor(1,1,1,alpha)
            love.graphics.draw(Art.poolImage,Art.poolQuads[poolFrame(field)],math.floor(field.x+.5),math.floor(field.y+5+.5),0,scale,scale,192,194)
            love.graphics.setColor(1,1,1,1)
        end}
    end
end

function Art.draw(mode)
    local shots,impacts=mode.revivalChorusShots or {},mode.revivalChorusImpacts or {}
    if #shots==0 and #impacts==0 then return end
    Art.load()
    for _,shot in ipairs(shots) do
        local p=math.min(1,shot.t/shot.dur)
        local ease=1-(1-p)*(1-p)
        local x=shot.sx+(shot.tx-shot.sx)*ease
        local y=shot.sy+(shot.ty-shot.sy)*ease-20*math.sin(p*math.pi)
        local angle=math.atan2 and math.atan2(shot.ty-shot.sy,shot.tx-shot.sx) or math.atan(shot.ty-shot.sy,shot.tx-shot.sx)
        local frame=1+math.min(2,math.floor(p*3))
        love.graphics.setColor(1,1,1,1)
        love.graphics.draw(Art.chorusImage,Art.chorusQuads[frame],math.floor(x+.5),math.floor(y+.5),angle,.34,.34,128,128)
    end
    for _,impact in ipairs(impacts) do
        local p=math.min(1,impact.age/impact.life)
        local frame=4+math.min(2,math.floor(p*3))
        local scale=(impact.radius or 56)/82
        love.graphics.setColor(1,1,1,math.min(1,(1-p)*2.5))
        love.graphics.draw(Art.chorusImage,Art.chorusQuads[frame],math.floor(impact.x+.5),math.floor(impact.y+.5),0,scale,scale,128,170)
    end
    love.graphics.setColor(1,1,1,1)
end

return Art
