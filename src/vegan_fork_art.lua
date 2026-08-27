local VeganForkArt = {}

local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function lerp(a,b,t) return a+(b-a)*t end
local function ease(t) t=clamp(t,0,1); return t*t*(3-2*t) end

function VeganForkArt.load()
    local art={}
    art.fork=love.graphics.newImage("assets/characters/ingame/vegan-fork-pixel-v1.png")
    art.impact=love.graphics.newImage("assets/fx/vegan-fork-impact-atlas-v1.png")
    art.chomp=love.graphics.newImage("assets/fx/vegan-chomp-atlas-v1.png")
    art.fork:setFilter("nearest","nearest"); art.impact:setFilter("nearest","nearest"); art.chomp:setFilter("nearest","nearest")
    art.impactQuads={}; art.chompQuads={}
    for i=0,5 do art.impactQuads[i+1]=love.graphics.newQuad(i*96,0,96,96,576,96) end
    for i=0,7 do art.chompQuads[i+1]=love.graphics.newQuad(i*160,0,160,160,1280,160) end
    return art
end

function VeganForkArt.update(mode,dt)
    for _,list in ipairs({mode.veganForkImpacts,mode.veganConsumeFx}) do
        for i=#list,1,-1 do
            local fx=list[i]; fx.t=fx.t+dt
            if fx.t>=fx.dur then table.remove(list,i) end
        end
    end
    mode.veganHaste=math.max(0,(mode.veganHaste or 0)-dt)
end

function VeganForkArt.impact(mode,x,y)
    mode.veganForkImpacts[#mode.veganForkImpacts+1]={x=x,y=y,t=0,dur=.34}
end

function VeganForkArt.consume(mode,node,game)
    mode.veganConsumeFx[#mode.veganConsumeFx+1]={
        x=node.x,y=node.y,variant=node.treeVariant or 1,t=0,dur=.92,
        player=game.player,seed=(node.x*.017+node.y*.013)%6.28
    }
end

local handAnchors={
    walk={{70,92},{70,92},{70,91},{70,92},{70,91},{70,92}},
    action={{69,91},{67,82},{68,87},{68,98},{69,78},{70,86}},
}

local function forkPose(mode,game)
    local player=game.player
    local row,frame,flip,foot=player:clearcutPose()
    local anchor=handAnchors[row][frame]
    local bodyScale=(player.clearcutSprite.scale or .75)
    local handX=player.x+(anchor[1]-player.clearcutFrameWidth/2)*bodyScale*flip
    local handY=player.y+(anchor[2]-foot)*bodyScale
    local action=mode.veganAction
    if not action then
        local facing=player.facing or 1
        return handX,handY,facing>0 and .13 or math.pi-.13,.39
    end
    local target=math.atan2(action.ty-handY,action.tx-handX)
    local p=clamp(action.t/action.dur,0,1)
    local facing=action.facing or player.facing or 1
    local windup=target-facing*1.30
    local angle
    if p<.32 then angle=lerp(target,windup,ease(p/.32))
    elseif p<.55 then angle=lerp(windup,target,ease((p-.32)/.23))
    elseif p<.73 then angle=target+math.sin((p-.55)/.18*math.pi)*facing*.12
    else angle=lerp(target,facing>0 and -.18 or math.pi+.18,ease((p-.73)/.27)) end
    return handX,handY,angle,.42
end

function VeganForkArt.drawFork(mode,game)
    local art=game.player.clearcutSprite and game.player.clearcutSprite.veganArt
    if not art then return end
    local x,y,angle,scale=forkPose(mode,game)
    love.graphics.push(); love.graphics.translate(math.floor(x+.5),math.floor(y+.5)); love.graphics.rotate(angle)
    love.graphics.setColor(0,0,0,.30); love.graphics.draw(art.fork,3,4,0,scale,scale,10,48)
    love.graphics.setColor(1,1,1,1); love.graphics.draw(art.fork,0,0,0,scale,scale,10,48)
    if mode:levelOf("buffet_fork")>=6 and mode.veganAction then
        local p=mode.veganAction.t/mode.veganAction.dur
        if p>=.46 and p<=.72 then
            love.graphics.setColor(.66,1,.42,.30*(1-math.abs(p-.59)/.13))
            love.graphics.draw(art.fork,3,-5,0,scale*1.06,scale*1.06,10,48)
        end
    end
    love.graphics.pop()
end

function VeganForkArt.drawFx(mode,game)
    local art=game.player.clearcutSprite and game.player.clearcutSprite.veganArt
    if not art then return end
    for _,fx in ipairs(mode.veganForkImpacts) do
        local p=clamp(fx.t/fx.dur,0,.999)
        local frame=math.floor(p*6)+1
        love.graphics.setColor(1,1,1,1)
        love.graphics.draw(art.impact,art.impactQuads[frame],fx.x,fx.y-32,0,.82,.82,48,48)
    end
    local variants=(game.world.images and game.world.images.treeVariants) or {}
    for _,fx in ipairs(mode.veganConsumeFx) do
        local p=clamp(fx.t/fx.dur,0,.999)
        local image=variants[math.max(1,math.min(#variants,fx.variant))]
        local pull=ease(clamp((p-.30)/.70,0,1))
        local mouthX=fx.player.x+12*(fx.player.facing or 1)
        local mouthY=fx.player.y-82
        local x=lerp(fx.x,mouthX,pull)
        local y=lerp(fx.y,mouthY,pull)-math.sin(pull*math.pi)*74
        local scale=(1-p*.86)*(1+math.sin(p*math.pi*5)*.025)
        if image then
            love.graphics.setColor(1,1,1,1-p*.28)
            love.graphics.draw(image,x,y,math.sin(p*math.pi*3+fx.seed)*.06,scale,scale,image:getWidth()/2,image:getHeight()*.91)
        end
        local frame=math.floor(p*8)+1
        love.graphics.setColor(1,1,1,1)
        love.graphics.draw(art.chomp,art.chompQuads[frame],x,y-48,0,.78,.78,80,80)
    end
end

return VeganForkArt
