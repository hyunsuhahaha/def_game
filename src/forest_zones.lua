local Zones={COLS=3,ROWS=2}

local function clamp(v,a,b)return math.max(a,math.min(b,v))end
function Zones.zoneId(world,x,y)
    local col=clamp(math.floor(x/math.max(1,world.width/Zones.COLS)),0,Zones.COLS-1)
    local row=clamp(math.floor(y/math.max(1,world.height/Zones.ROWS)),0,Zones.ROWS-1)
    return row*Zones.COLS+col+1
end
function Zones.build(world,nodes)
    local zones={}
    for id=1,Zones.COLS*Zones.ROWS do
        local col=(id-1)%Zones.COLS;local row=math.floor((id-1)/Zones.COLS)
        zones[id]={id=id,name=string.format("%d구역",id),initial=0,active=0,secured=false,coreAlive=false,
            x=(col+.5)*world.width/Zones.COLS,y=(row+.5)*world.height/Zones.ROWS,sumX=0,sumY=0}
    end
    for _,node in ipairs(nodes) do
        if node.rushTree then
            local id=Zones.zoneId(world,node.x,node.y);node.forestZone=id
            local z=zones[id];z.initial=z.initial+1;z.active=z.active+1;z.sumX=z.sumX+node.x;z.sumY=z.sumY+node.y
        end
    end
    for _,z in ipairs(zones) do
        if z.initial>0 then z.x,z.y=z.sumX/z.initial,z.sumY/z.initial;z.coreAlive=true else z.secured=true end
        z.sumX,z.sumY=nil,nil
    end
    return zones
end
function Zones.corePosition(world,z,nodes,canPlant)
    local bestX,bestY,bestScore=nil,nil,-math.huge
    for ring=0,4 do
        local count=ring==0 and 1 or ring*8
        for step=1,count do
            local angle=count==1 and 0 or (step-1)/count*math.pi*2
            local radius=ring*46
            local x,y=z.x+math.cos(angle)*radius,z.y+math.sin(angle)*radius
            if Zones.zoneId(world,x,y)==z.id and (not canPlant or canPlant(world,x,y)) then
                local clearance=math.huge
                for _,node in ipairs(nodes) do
                    if node.rushTree and node.forestZone==z.id then clearance=math.min(clearance,(node.x-x)^2+(node.y-y)^2) end
                end
                local score=math.min(clearance,180^2)-((x-z.x)^2+(y-z.y)^2)*.08
                if score>bestScore then bestX,bestY,bestScore=x,y,score end
            end
        end
    end
    if bestX then return bestX,bestY end
    for _,node in ipairs(nodes) do if node.rushTree and node.forestZone==z.id then return node.x,node.y end end
    return z.x,z.y
end
function Zones.refresh(mode,id)
    local z=mode.forestZones and mode.forestZones[id];if not z then return nil end
    local active=0
    for _,node in ipairs(mode.mapWorld.nodes) do if node.rushTree and node.forestZone==id and node.active then active=active+1 end end
    z.active=active
    if not z.coreAlive and active==0 and not z.secured then z.secured=true;mode.zonesSecured=(mode.zonesSecured or 0)+1;return z end
end
function Zones.coreDestroyed(mode,id)
    local z=mode.forestZones and mode.forestZones[id];if not z or not z.coreAlive then return nil end
    z.coreAlive=false;z.coreEntity=nil
    return Zones.refresh(mode,id) or z
end
function Zones.canRegrow(mode,node)
    local z=mode.forestZones and mode.forestZones[node.forestZone or 0]
    return not z or (z.coreAlive and not z.secured)
end
function Zones.candidates(mode,z)
    local out={}
    for _,node in ipairs(mode.mapWorld.nodes) do
        if node.rushTree and node.forestZone==z.id and not node.active and not node.sterile then out[#out+1]=node end
    end
    return out
end
function Zones.status(mode)
    local secured,total=0,0
    for _,z in ipairs(mode.forestZones or {}) do if z.initial>0 then total=total+1;if z.secured then secured=secured+1 end end end
    return secured,total
end
function Zones.drawHUD(mode,fonts,w,y)
    local zones=mode.forestZones or {};if #zones==0 then return 0 end
    local cellW,cellH=30,25;local width=#zones*cellW;local x=math.floor(w/2-width/2)
    for i,z in ipairs(zones) do
        local cx=x+(i-1)*cellW
        local c=z.secured and {.25,.58,.68} or (z.coreAlive and {.42,.78,.28} or {.92,.58,.18})
        love.graphics.setFont(fonts.micro or fonts.small);love.graphics.setColor(z.secured and .55 or 1,z.secured and .62 or 1,z.secured and .58 or 1,.94);love.graphics.printf(tostring(z.id),cx,y,cellW,"center")
        love.graphics.setColor(c[1],c[2],c[3],1);love.graphics.rectangle("fill",cx+8,y+18,14,3)
    end
    return cellH
end
return Zones
