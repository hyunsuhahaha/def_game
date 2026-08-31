local Art={}
local cache={}
local BIOMES={forest=true,mangrove=true,madagascar=true,island=true}

local function load(mapId)
    mapId=BIOMES[mapId]and mapId or"forest"
    if cache[mapId]then return cache[mapId]end
    local image=love.graphics.newImage("assets/scenery/canopy/"..mapId.."-foreground-canopy-atlas-pixel-v1.png")
    image:setFilter("nearest","nearest")
    local iw,ih=image:getDimensions()
    local value={image=image,parts={
        love.graphics.newQuad(0,0,320,256,iw,ih),
        love.graphics.newQuad(320,0,320,256,iw,ih),
        love.graphics.newQuad(640,0,128,256,iw,ih),
        love.graphics.newQuad(768,0,128,256,iw,ih),
        love.graphics.newQuad(896,0,128,256,iw,ih)
    }}
    cache[mapId]=value
    return value
end

function Art.draw(occupancy,mapId,w,h,t)
    if(occupancy or 0)<.80 then return false end
    local art=load(mapId)
    local severity=math.min(1,math.max(0,((occupancy or 0)-.80)/.20))
    local pulse=.5+.5*math.sin((t or 0)*(3.2+severity*3.8))
    local uiScale=math.max(.78,math.min(1.3,w/1280))
    local scale=uiScale*(.72+severity*.22)
    local reveal=18+severity*54+pulse*(4+severity*7)
    local alpha=.20+severity*.34+pulse*(.04+severity*.09)

    love.graphics.push("all")
    love.graphics.setColor(1,.72-severity*.27,.46-severity*.24,alpha)
    love.graphics.draw(art.image,art.parts[1],0,-256*scale+reveal,0,scale,scale)
    love.graphics.draw(art.image,art.parts[2],w-320*scale,-256*scale+reveal,0,scale,scale)

    if severity>.18 then
        local vineAlpha=alpha*math.min(1,(severity-.18)/.42)
        love.graphics.setColor(1,.60-severity*.18,.32-severity*.14,vineAlpha)
        local count=severity>.66 and 5 or 3
        for i=1,count do
            local x=w*(i/(count+1))
            local part=art.parts[3+(i-1)%3]
            local sway=math.floor(math.sin((t or 0)*2.1+i*1.7)*(2+severity*4))
            love.graphics.draw(art.image,part,math.floor(x+sway),-18,0,scale,scale,64,0)
        end
    end

    -- Crisp stepped edge pressure. It stays peripheral and contains no copy.
    love.graphics.setColor(.38+.38*severity,.08,.035,.13+severity*.16+pulse*.05)
    local step=math.max(18,math.floor(34-14*severity))
    local thickness=math.floor(3+severity*5)
    for x=0,w,step do
        local stagger=((math.floor(x/step)%2)==0)and thickness or math.max(2,thickness-2)
        love.graphics.rectangle("fill",x,0,math.max(8,step-7),stagger)
        love.graphics.rectangle("fill",x,h-stagger,math.max(8,step-7),stagger)
    end
    for y=step,h-step,step do
        love.graphics.rectangle("fill",0,y,thickness,math.max(8,step-7))
        love.graphics.rectangle("fill",w-thickness,y,thickness,math.max(8,step-7))
    end
    love.graphics.pop()
    return true
end

return Art
