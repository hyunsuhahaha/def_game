-- Icon-led trait UI shared by the in-run board, draft cards and tooltips.
-- The atlas is authored on a native 64 px grid; all sampling stays nearest.
local SynergyUI={}

local iconOrder={momentum=1,field=2,ignition=3,growth=4,impact=5,wild=6,harvest=7}
local images,icons,chrome

local function load()
    if images then return end
    images={
        emblem=love.graphics.newImage("assets/ui/synergy-emblems-pixel-v1.png"),
        chrome=love.graphics.newImage("assets/ui/synergy-chrome-pixel-v1.png"),
    }
    images.emblem:setFilter("nearest","nearest")
    images.chrome:setFilter("nearest","nearest")
    icons={}
    for id,index in pairs(iconOrder)do icons[id]=love.graphics.newQuad((index-1)*64,0,64,64,448,64)end
    chrome={}
    for i=1,4 do chrome[i]=love.graphics.newQuad((i-1)*64,0,64,64,256,64)end
end

function SynergyUI.drawPanel(x,y,w,h,color,alpha)
    load();alpha=alpha or .97
    love.graphics.setScissor(x,y,w,h)
    love.graphics.setColor(1,1,1,alpha)
    for yy=y,y+h-1,32 do for xx=x,x+w-1,32 do
        love.graphics.draw(images.chrome,chrome[1],xx,yy,0,.5,.5)
    end end
    love.graphics.setScissor()
    color=color or {.55,.72,.58}
    love.graphics.setColor(.015,.025,.022,alpha);love.graphics.rectangle("line",x+.5,y+.5,w-1,h-1)
    love.graphics.setColor(color[1],color[2],color[3],.62*alpha);love.graphics.setLineWidth(2)
    love.graphics.line(x+7,y+.5,x+w-8,y+.5);love.graphics.line(x+7,y+h-.5,x+w-8,y+h-.5)
    love.graphics.setColor(color[1],color[2],color[3],.95*alpha)
    for _,p in ipairs{{x+2,y+2},{x+w-5,y+2},{x+2,y+h-5},{x+w-5,y+h-5}}do love.graphics.rectangle("fill",p[1],p[2],3,3)end
end

function SynergyUI.drawEmblem(id,cx,cy,size,active,alpha)
    load();local quad=icons[id];if not quad then return end
    alpha=alpha or 1
    love.graphics.setColor(active==false and .52 or 1,active==false and .57 or 1,active==false and .54 or 1,alpha)
    local s=size/64
    love.graphics.draw(images.emblem,quad,math.floor(cx),math.floor(cy),0,s,s,32,32)
end

function SynergyUI.drawSocket(id,cx,cy,size,active,alpha)
    load();alpha=alpha or 1
    local cell=active==false and 3 or 2;local s=size/64
    love.graphics.setColor(1,1,1,alpha)
    love.graphics.draw(images.chrome,chrome[cell],math.floor(cx),math.floor(cy),0,s,s,32,32)
    SynergyUI.drawEmblem(id,cx,cy,size*.78,active,alpha)
end

function SynergyUI.drawBreakpoint(cx,cy,size,threshold,active,font,color)
    load();local cell=active and 4 or 3;local s=size/64
    love.graphics.setColor(active and 1 or .66,active and 1 or .7,active and 1 or .67,1)
    love.graphics.draw(images.chrome,chrome[cell],math.floor(cx),math.floor(cy),0,s,s,32,32)
    love.graphics.setFont(font);love.graphics.setColor(active and {1,.97,.72} or {.64,.68,.64})
    love.graphics.printf(tostring(threshold),cx-size/2,cy-font:getHeight()/2,size,"center")
end

function SynergyUI.drawBadge(def,x,y,w,h,countText,active,font)
    SynergyUI.drawPanel(x,y,w,h,def.color,.92)
    local iconSize=math.min(h+10,42)
    SynergyUI.drawEmblem(def.id,x+iconSize*.47,y+h/2,iconSize,active)
    love.graphics.setFont(font);love.graphics.setColor(1,.96,.84)
    love.graphics.print(def.name,x+iconSize*.9,y+(h-font:getHeight())/2)
    love.graphics.setColor(active and def.color or {.68,.72,.68})
    love.graphics.printf(countText,x+w-54,y+(h-font:getHeight())/2,46,"right")
end

function SynergyUI.assets() load();return images end
return SynergyUI
