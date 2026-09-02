local Rewards={}
local image

local function ensureImage()
    if image then return image end
    image=love.graphics.newImage("assets/pickups/boss-magnet-pickup-pixel-v1.png")
    image:setFilter("nearest","nearest")
    return image
end

function Rewards.spawn(mode,x,y,woodOnly,phase)
    local pickup={x=x,y=y,collected=false,phase=phase or 0,woodOnly=woodOnly==true}
    mode.bossMagnetPickups[#mode.bossMagnetPickups+1]=pickup
    return pickup
end

function Rewards.rollWoodMagnet(mode,x,y)
    if love.math.random()>=.01 then return false end
    Rewards.spawn(mode,x,y,true,love.math.random()*math.pi*2)
    return true
end

function Rewards.grant(mode,boss,game)
    if not boss or not boss.def or not boss.def.boss or boss.bossRewardGranted then return false end
    boss.bossRewardGranted=true
    local before=mode.hp
    mode.hp=math.min(mode.maxHp,mode.hp+20)
    local healed=mode.hp-before
    Rewards.spawn(mode,boss.x,boss.y,false,(boss.seed or 0)*.7)
    if mode.traitFx and healed>0 then mode.traitFx:emit("heal",game.player.x,game.player.y,{particles=10}) end
    if game.world and game.world.popups and healed>0 then
        game.world.popups[#game.world.popups+1]={x=game.player.x,y=game.player.y-48,life=1,maxLife=1,text="+"..healed.." HP",color={.35,1,.54},chain=0}
    end
    return true,healed
end

function Rewards.update(mode,game)
    if game.mode~="playing" then return end
    for index=#mode.bossMagnetPickups,1,-1 do
        local pickup=mode.bossMagnetPickups[index]
        local dx,dy=game.player.x-pickup.x,game.player.y-pickup.y
        if dx*dx+dy*dy<=52*52 then
            pickup.collected=true
            local drops=game.world.drops or{}
            local farthest=1
            for _,drop in ipairs(drops) do
                if not pickup.woodOnly or drop.kind=="wood" then
                    local ddx,ddy=game.player.x-drop.x,game.player.y-drop.y
                    farthest=math.max(farthest,math.sqrt(ddx*ddx+ddy*ddy))
                end
            end
            local order=0
            for _,drop in ipairs(drops) do
                if not pickup.woodOnly or drop.kind=="wood" then
                    order=order+1
                    local ddx,ddy=game.player.x-drop.x,game.player.y-drop.y
                    local distance=math.sqrt(ddx*ddx+ddy*ddy)
                    drop.magnet=true
                    drop.bossMagnet=true
                    drop.magnetPullAge=0
                    drop.magnetDelay=.18+(distance/farthest)*.30+((order-1)%4)*.018
                end
            end
            if mode.traitFx then mode.traitFx:emit("refund",game.player.x,game.player.y,{particles=14}) end
            game:setNotice(pickup.woodOnly and "목재 자석 — 떨어진 목재를 전부 회수한다!"or"자석 획득 — 떨어진 자원을 전부 회수한다!","ore")
            table.remove(mode.bossMagnetPickups,index)
        end
    end
end

function Rewards.draw(pickup,time)
    local sprite=ensureImage();local bob=math.sin(time*3.2+(pickup.phase or 0))*4
    local pulse=.78+math.sin(time*4.6+(pickup.phase or 0))*.12
    love.graphics.setColor(.22,.78,1,.10+pulse*.08)
    love.graphics.ellipse("fill",pickup.x,pickup.y+8,31+pulse*4,10+pulse*2)
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(sprite,math.floor(pickup.x+.5),math.floor(pickup.y-18+bob+.5),0,.39,.39,64,96)
end

return Rewards
