-- Oil remains code-native: each spot builds a dense irregular black stain from
-- deterministic 2px scanlines. Only the separate flame object uses the existing
-- authored high-density fire frames.
local Art={}
local fireImage,fireQuads,smokeQuad
local CELL=128

local function noise(seed,index)
    local value=math.sin(seed*12.9898+index*78.233)*43758.5453
    return value-math.floor(value)
end

local function loadFire()
    if fireImage then return end
    fireImage=love.graphics.newImage("assets/fx/oil-trail/oil-trail-atlas-pixel-v2.png")
    fireImage:setFilter("nearest","nearest")
    fireQuads={}
    for frame=0,2 do fireQuads[frame+1]=love.graphics.newQuad(frame*CELL,CELL,CELL,CELL,fireImage:getDimensions())end
    smokeQuad=love.graphics.newQuad(4*CELL,CELL,CELL,CELL,fireImage:getDimensions())
end

local function fadeFor(spot,t)
    local age=math.max(0,(t or 0)-(spot.spawnedAt or 0))
    local lifetime=spot.lifetime or 6
    return math.min(1,age/.14)*math.min(1,math.max(0,(lifetime-age)/.7))
end

local function rotatePoint(spot,x,y)
    local angle=spot.angle or 0
    local ca,sa=math.cos(angle),math.sin(angle)
    return spot.x+x*ca-y*sa,spot.y+x*sa+y*ca
end

local function drawPixelLobe(spot,cx,cy,rx,ry,seed,color,alpha)
    love.graphics.setColor(color[1],color[2],color[3],alpha*(color[4]or 1))
    local row=0
    for y=-ry,ry,2 do
        local normalized=y/math.max(1,ry)
        local half=rx*math.sqrt(math.max(0,1-normalized*normalized))
        local edge=.82+noise(seed,row+13)*.32
        local wobble=(noise(seed,row+71)-.5)*rx*.20+math.sin(row*.91+seed)*rx*.07
        local left=math.floor((-half*edge+wobble)/2)*2
        local right=math.floor((half*(.88+noise(seed,row+31)*.24)+wobble)/2)*2
        local x1,y1=rotatePoint(spot,cx+left,cy+y)
        local x2,y2=rotatePoint(spot,cx+right,cy+y)
        -- Horizontal scanlines are rotated as slim polygons, retaining the 2px grid.
        local thickness=2
        local angle=spot.angle or 0
        local nx,ny=-math.sin(angle)*thickness,math.cos(angle)*thickness
        love.graphics.polygon("fill",math.floor(x1/2)*2,math.floor(y1/2)*2,
            math.floor(x2/2)*2,math.floor(y2/2)*2,
            math.floor((x2+nx)/2)*2,math.floor((y2+ny)/2)*2,
            math.floor((x1+nx)/2)*2,math.floor((y1+ny)/2)*2)
        row=row+1
    end
end

local function drawOilPixels(spot,t,scaleMultiplier)
    local seed=spot.pixelSeed or spot.sequence or 1
    local scale=(spot.visualScale or 1)*(scaleMultiplier or 1)
    local stretchX=(spot.stretchX or 1)*scale
    local stretchY=(spot.stretchY or 1)*scale
    local alpha=.96*fadeFor(spot,t)
    local outer={.012,.014,.019,1}
    local body={.026,.030,.038,1}
    local inner={.052,.057,.070,1}
    -- Overlapping lobes create one substantial stain, not scattered rectangles.
    drawPixelLobe(spot,0,0,34*stretchX,19*stretchY,seed,outer,alpha)
    drawPixelLobe(spot,-17*stretchX,3*stretchY,20*stretchX,13*stretchY,seed+19,body,alpha)
    drawPixelLobe(spot,18*stretchX,-2*stretchY,22*stretchX,12*stretchY,seed+37,body,alpha)
    drawPixelLobe(spot,1*stretchX,-2*stretchY,25*stretchX,10*stretchY,seed+53,inner,alpha*.92)

    -- Material-following stepped glints and warm/blue oil sheen.
    local glints=14+math.floor(8*scale)
    for index=1,glints do
        local theta=noise(seed,index+101)*math.pi*2
        local radial=math.sqrt(noise(seed,index+151))
        local lx=math.cos(theta)*radial*27*stretchX
        local ly=math.sin(theta)*radial*11*stretchY-2*stretchY
        local x,y=rotatePoint(spot,lx,ly)
        local warm=index%5==0
        love.graphics.setColor(warm and .25 or .13,warm and .15 or .17,warm and .09 or .23,alpha*(warm and .54 or .68))
        local width=(index%3==0 and 6 or 4)*math.max(.75,scale)
        love.graphics.rectangle("fill",math.floor(x/2)*2,math.floor(y/2)*2,math.floor(width/2)*2,2)
    end

    -- Detached droplets and thin forward fingers keep the barrel direction legible.
    for index=1,6 do
        local distance=(37+noise(seed,index+201)*24)*stretchX
        local lateral=(noise(seed,index+241)-.5)*30*stretchY
        if index%3==0 then distance=-distance*.42 end
        local x,y=rotatePoint(spot,distance,lateral)
        local size=index%2==0 and 4 or 3
        love.graphics.setColor(.015,.018,.024,alpha*.92)
        love.graphics.rectangle("fill",math.floor(x/2)*2,math.floor(y/2)*2,size*2,size)
        if index%2==0 then
            love.graphics.setColor(.12,.15,.20,alpha*.58)
            love.graphics.rectangle("fill",math.floor(x/2)*2+2,math.floor(y/2)*2,2,2)
        end
    end
end

function Art.drawGround(spot,t)
    if (t or 0)<(spot.spawnedAt or 0)then return end
    drawOilPixels(spot,t)
    love.graphics.setColor(1,1,1,1)
end

function Art.drawFlame(spot,t)
    if not spot.ignited or (t or 0)<(spot.spawnedAt or 0)then return end
    loadFire()
    local now=t or 0
    local age=math.max(0,now-(spot.ignitedAt or now))
    local burnDuration=spot.burnDuration or 5
    local alpha=math.min(1,age/.12)*math.min(1,math.max(0,(burnDuration-age)/.58))
    local seed=spot.pixelSeed or spot.sequence or 1
    local frame=(math.floor(now*9+seed)%3)+1
    local scale=.34*math.max(.72,math.min(1.38,spot.visualScale or 1))
    local flicker=math.floor(math.sin(now*13+seed)*2)
    love.graphics.setColor(1,1,1,alpha)
    love.graphics.draw(fireImage,fireQuads[frame],math.floor(spot.x/2)*2+flicker,
        math.floor(spot.y/2)*2,0,scale,scale,CELL/2,116)
    if (spot.sequence or 0)%5==0 then
        love.graphics.setColor(.72,.66,.62,alpha*.44)
        love.graphics.draw(fireImage,smokeQuad,math.floor(spot.x/2)*2-flicker,
            math.floor(spot.y/2)*2-5,0,scale*.72,scale*.72,CELL/2,116)
    end
    love.graphics.setColor(1,1,1,1)
end

-- Only the player oil-road uses connectors. Drum spills stay as detached stains.
local function bridge(from,to,draw)
    if from.source=="drum"or to.source=="drum"then return end
    local dx,dy=to.x-from.x,to.y-from.y
    local distance=math.sqrt(dx*dx+dy*dy)
    if distance<18 or distance>85 then return end
    local count=math.max(1,math.ceil(distance/20)-1)
    for index=1,count do
        local p=index/(count+1)
        draw({x=from.x+dx*p,y=from.y+dy*p,angle=math.atan2(dy,dx),pixelSeed=(from.sequence or 1)+index,
            sequence=(from.sequence or 0)+index,spawnedAt=from.spawnedAt,visualScale=.54,stretchX=.72,stretchY=.62,
            lifetime=math.min(from.lifetime or 6,to.lifetime or 6),ignited=from.ignited and to.ignited,
            ignitedAt=from.ignitedAt,burnDuration=from.burnDuration})
    end
end

function Art.drawGroundBridge(from,to,t)bridge(from,to,function(spot)Art.drawGround(spot,t)end)end
function Art.drawFlameBridge(from,to,t)bridge(from,to,function(spot)Art.drawFlame(spot,t)end)end
return Art
