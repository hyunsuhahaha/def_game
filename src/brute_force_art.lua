-- Cartoon pixel presentation for the bitcoin-password brute-force attack.
local Art={}
local digits,wallet,digitQuads,walletQuads
local function load()
    if digits then return end
    digits=love.graphics.newImage("assets/fx/brute-force/brute-force-digits-cartoon-pixel-v2.png");digits:setFilter("nearest","nearest")
    wallet=love.graphics.newImage("assets/fx/brute-force/bitcoin-wallet-cartoon-pixel-v1.png");wallet:setFilter("nearest","nearest")
    digitQuads={}
    for row=0,1 do digitQuads[row+1]={};for col=0,9 do digitQuads[row+1][col+1]=love.graphics.newQuad(col*32,row*40,32,40,digits:getDimensions()) end end
    walletQuads={};for frame=0,2 do walletQuads[frame+1]=love.graphics.newQuad(frame*80,0,80,80,wallet:getDimensions()) end
end
local function drawDigit(d,x,y,alpha,scale,row)
    local value=math.max(0,math.min(9,tonumber(d) or 0))
    love.graphics.setColor(1,1,1,alpha or 1)
    love.graphics.draw(digits,digitQuads[row or 1][value+1],math.floor(x+.5),math.floor(y+.5),0,scale or 1,scale or 1,16,20)
end
function Art.draw(mode,game,t)
    local active=(mode.digits and #mode.digits>0) or (mode.bruteCastFx and #mode.bruteCastFx>0) or (mode.bruteImpactFx and #mode.bruteImpactFx>0)
    if not active then return end
    load();local previous={love.graphics.getColor()}
    for _,fx in ipairs(mode.bruteCastFx or {}) do
        local p=1-fx.life/fx.maxLife
        local frame=p<.55 and 1 or (p<.78 and 2 or 3)
        love.graphics.setColor(1,1,1,math.min(1,fx.life/.08))
        love.graphics.draw(wallet,walletQuads[frame],math.floor(fx.x+.5),math.floor(fx.y+.5),0,.82,.82,40,62)
    end
    for _,d in ipairs(mode.digits or {}) do
        if d.age>=(d.visibleAt or 0) then
            local row=(d.index or 0)%3==0 and 2 or 1
            if d.state=="charge" and d.age<d.arriveAt then
                local pulse=.58+.28*math.sin((t or 0)*60+(d.index or 0))
                love.graphics.setLineWidth(5);love.graphics.setColor(.015,.11,.04,pulse*.55);love.graphics.line(d.startX,d.startY,d.x,d.y)
                love.graphics.setLineWidth(2);love.graphics.setColor(.28,1,.38,pulse);love.graphics.line(d.startX,d.startY,d.x,d.y)
                drawDigit(d.glyph,d.x,d.y,1,.78,row)
            elseif d.state=="charge" then
                drawDigit(d.glyph,d.x,d.y,.72,.58,row)
            else
                local length=math.sqrt(d.vx*d.vx+d.vy*d.vy);local nx,ny=d.vx/length,d.vy/length;local alpha=math.min(1,d.life/.14)
                drawDigit(d.glyph,d.x-nx*22,d.y-ny*22,alpha*.16,.62,row)
                drawDigit(d.glyph,d.x-nx*11,d.y-ny*11,alpha*.36,.72,row)
                drawDigit(d.glyph,d.x,d.y,alpha,.88,row)
            end
        end
    end
    for _,fx in ipairs(mode.bruteImpactFx or {}) do
        local p=1-fx.life/fx.maxLife;local base=tonumber(fx.glyph) or 0
        for i=1,8 do
            local a=i/8*math.pi*2+base*.1;local r=7+p*36
            drawDigit(tostring((i+base)%10),fx.x+math.cos(a)*r,fx.y-10+math.sin(a)*r*.65,(1-p)*.85,.55,i%3==0 and 2 or 1)
        end
    end
    love.graphics.setLineWidth(1);love.graphics.setColor(unpack(previous))
end
return Art
