local Art={image=nil,quads=nil}
local order={ember=1,filter=2,cigarette=2,wind=3,ash=4,clock=5,warning=6,pack=7,map=8,basket=9}

local function load()
    if Art.image then return end
    local ok,image=pcall(love.graphics.newImage,"assets/ui/trait-node-icons-pixel-v2.png")
    if not ok then return end
    image:setFilter("nearest","nearest");Art.image=image;Art.quads={}
    for i=0,8 do Art.quads[i+1]=love.graphics.newQuad((i%3)*96,math.floor(i/3)*96,96,96,image:getDimensions())end
end

function Art.has(icon)return order[icon]~=nil end
function Art.draw(icon,cx,cy,size,alpha)
    load();local index=order[icon];if not Art.image or not index then return false end
    love.graphics.setColor(1,1,1,alpha or 1)
    love.graphics.draw(Art.image,Art.quads[index],math.floor(cx+.5),math.floor(cy+.5),0,size/96,size/96,48,48)
    return true
end
return Art
