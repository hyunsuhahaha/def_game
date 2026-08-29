local Rewards={}
local image

local function ensureImage()
    if image then return image end
    image=love.graphics.newImage("assets/pickups/boss-magnet-pickup-pixel-v1.png")
    image:setFilter("nearest","nearest")
    return image
end

function Rewards.grant(mode,boss,game)
    if not boss or not boss.def or not boss.def.boss or boss.bossRewardGranted then return false end
    boss.bossRewardGranted=true
    local before=mode.hp
    mode.hp=math.min(mode.maxHp,mode.hp+20)
    local healed=mode.hp-before
    mode.bossMagnetPickups[#mode.bossMagnetPickups+1]={x=boss.x,y=boss.y,collected=false,phase=(boss.seed or 0)*.7}
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
            for _,drop in ipairs(game.world.drops or{}) do drop.magnet=true end
            if mode.traitFx then mode.traitFx:emit("refund",game.player.x,game.player.y,{particles=14}) end
            game:setNotice("자석 획득 — 떨어진 자원을 전부 회수한다!","ore")
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
