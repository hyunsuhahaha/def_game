local Art={image=nil,quads=nil,cat=nil,catQuad=nil,drum=nil,popper=nil,popperQuad=nil}
local order={ember=1,filter=2,cigarette=2,wind=3,ash=4,clock=5,warning=6,pack=7,map=8,basket=9}

local function load()
    if Art.image then return end
    local ok,image=pcall(love.graphics.newImage,"assets/ui/trait-node-icons-pixel-v2.png")
    if not ok then return end
    image:setFilter("nearest","nearest");Art.image=image;Art.quads={}
    for i=0,8 do Art.quads[i+1]=love.graphics.newQuad((i%3)*96,math.floor(i/3)*96,96,96,image:getDimensions())end
end

function Art.has(icon)return order[icon]~=nil or icon=="oil_drum"or icon=="gray_cat"or icon=="popping_machine"end
function Art.draw(icon,cx,cy,size,alpha)
    if icon=="oil_drum"or icon=="gray_cat"or icon=="popping_machine"then
        if not Art.drum then
            local drumOk,drum=pcall(love.graphics.newImage,"assets/characters/companions/oil-drum-pixel-v1.png")
            local catOk,cat=pcall(love.graphics.newImage,"assets/characters/companions/gray-oil-cat-atlas-pixel-v1.png")
            if drumOk then drum:setFilter("nearest","nearest");Art.drum=drum end
            if catOk then
                cat:setFilter("nearest","nearest");Art.cat=cat
                Art.catQuad=love.graphics.newQuad(0,0,128,128,cat:getDimensions())
            end
            local popperOk,popper=pcall(love.graphics.newImage,"assets/automation/popping-machine-atlas-pixel-v2.png")
            if popperOk then
                popper:setFilter("nearest","nearest");Art.popper=popper
                Art.popperQuad=love.graphics.newQuad(0,0,256,192,popper:getDimensions())
            end
        end
        love.graphics.setColor(1,1,1,alpha or 1)
        if icon=="oil_drum"and Art.drum then
            love.graphics.draw(Art.drum,math.floor(cx+.5),math.floor(cy+.5),0,size/82,size/82,64,69)
            return true
        elseif icon=="gray_cat"and Art.cat and Art.catQuad then
            love.graphics.draw(Art.cat,Art.catQuad,math.floor(cx+.5),math.floor(cy+.5),0,size/92,size/92,64,67)
            return true
        elseif icon=="popping_machine"and Art.popper and Art.popperQuad then
            love.graphics.draw(Art.popper,Art.popperQuad,math.floor(cx+.5),math.floor(cy+.5),0,size/180,size/180,128,112)
            return true
        end
        return false
    end
    load();local index=order[icon];if not Art.image or not index then return false end
    love.graphics.setColor(1,1,1,alpha or 1)
    love.graphics.draw(Art.image,Art.quads[index],math.floor(cx+.5),math.floor(cy+.5),0,size/96,size/96,48,48)
    return true
end
return Art
