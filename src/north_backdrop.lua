-- Decorative panorama beyond the northern movement boundary. It is a screen
-- presentation layer only: simulation, collision and targeting stay inside
-- clearcut_maps.playBounds.
local Backdrop={}
local assets={}
local valid={forest=true,mangrove=true,madagascar=true,island=true}

local function clamp(v,a,b)return math.max(a,math.min(b,v))end

local function load(id)
    id=valid[id] and id or "forest"
    if assets[id] then return assets[id] end
    local root="assets/scenery/north_backdrops/"
    local value={
        panorama=love.graphics.newImage(root..id.."-panorama-pixel-v2.png"),
        ridge=love.graphics.newImage(root..id.."-ridge-pixel-v1.png"),
    }
    value.panorama:setFilter("nearest","nearest")
    value.ridge:setFilter("nearest","nearest")
    assets[id]=value
    return value
end

function Backdrop.state(camera,world)
    if not camera or not world or not world.northBackdrop or not world.playBounds then return nil end
    if (camera.skyviewBlend or 0)>.001 then return nil end
    local width,height=love.graphics.getDimensions()
    local _,seamY=camera:worldToScreen(world.width*.5,world.playBounds.y)
    local alpha=clamp((seamY+96)/176,0,1)
    if alpha<=.001 or seamY>height+180 then return nil end
    return {width=width,height=height,seamY=seamY,alpha=alpha,id=world.clearcutMap or "forest"}
end

function Backdrop.drawBack(camera,world)
    local state=Backdrop.state(camera,world);if not state then return false end
    local art=load(state.id);local image=art.panorama
    local bottom=math.min(state.height,state.seamY+26)
    local scale=math.max(state.width/image:getWidth(),math.max(180,bottom+50)/image:getHeight())
    local imageW,imageH=image:getWidth()*scale,image:getHeight()*scale
    local drift=-(camera.renderX-world.width*.5)*.035
    local x=(state.width-imageW)*.5+drift
    local y=bottom-imageH
    love.graphics.push("all")
    love.graphics.setScissor(0,0,state.width,math.max(0,math.floor(bottom)))
    love.graphics.setColor(1,1,1,state.alpha)
    love.graphics.draw(image,math.floor(x),math.floor(y),0,scale,scale)
    love.graphics.setScissor();love.graphics.pop()
    return true
end

function Backdrop.drawRidge(camera,world)
    local state=Backdrop.state(camera,world);if not state then return false end
    local image=load(state.id).ridge
    local scale=math.max(state.width/image:getWidth(),.58)
    local imageW,imageH=image:getWidth()*scale,image:getHeight()*scale
    local drift=-(camera.renderX-world.width*.5)*.018
    local x=(state.width-imageW)*.5+drift
    local y=state.seamY+72-imageH
    love.graphics.push("all")
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(1,1,1,state.alpha)
    love.graphics.draw(image,math.floor(x),math.floor(y),0,scale,scale)
    love.graphics.pop()
    return true
end

return Backdrop
