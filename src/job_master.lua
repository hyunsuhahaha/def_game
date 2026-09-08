local Player=require("src.player")
local Maps=require("src.clearcut_maps")
local Builder=require("src.construction_worker")
local Master={}

function Master.setup(mode,game)
    if not game.characterTraits.data.jobMasterFire or mode.scoreTutorialRun then return end
    -- Keep the fully configured smoker, including its original player stats,
    -- weapon state, permanent traits and all existing automation in this mode.
    mode.jobMaster={actor=game.player}
    local world=game.world
    local actor=Player.new(game.player.x+140,game.player.y,world.images.workerWalk,world.images.workerActions,world.images.workerRepair)
    actor:setClearcutSprite(game.clearcutSprites.developer,"builder")
    game.player=actor;mode.controlledJob="builder"
    Builder.setup(mode,game)
    actor.speed=mode.construction.stats.moveSpeed
    game:setNotice("흡연자 잡 마스터 자동 전투 · 건설업자 WASD 이동 / 좌클릭 크레인 자재 투하","food")
end

function Master.prepare(mode,game,dt)
    local master=mode.jobMaster;if not master then return end
    Builder.update(mode,game,dt)
    local actor=master.actor;local target,distance
    for _,node in ipairs(game.world.nodes)do
        if node.rushTree and node.active then
            local d=(node.x-actor.x)^2+(node.y-actor.y)^2
            if not distance or d<distance then target,distance=node,d end
        end
    end
    if not target and mode.scoreWorldTree and mode.scoreWorldTree.hp>0 then target=mode.scoreWorldTree end
    master.target=target
    local dest=target or game.player
    local dx,dy=dest.x-actor.x,dest.y-actor.y;local length=math.sqrt(dx*dx+dy*dy)
    local reach=mode.rainSuppressFire and 85 or 260
    local step=math.min(math.max(0,length-reach),(actor.speed or mode.baseSpeed)*dt)
    actor.isMoving=step>0
    if step>0 and not mode.smokerDash then
        actor.x,actor.y=Maps.constrain(game.world,actor.x+dx/length*step,actor.y+dy/length*step,75)
        actor.walkClock=actor.walkClock+dt*9
    end
    if dx~=0 then actor.facing=dx<0 and-1 or 1 end
    if actor.autoAxeClock then
        actor.autoAxeClock=actor.autoAxeClock+dt
        if actor.autoAxeClock>=actor.autoAxeDuration then actor.autoAxeClock=nil end
    end
    master.operator=game.player
    game.player=actor
    if target and length>600 then mode:activateSmokerDash(game)end
end

function Master.restore(mode,game)
    if mode.jobMaster then game.player=mode.jobMaster.operator end
end

function Master.queue(mode,queue,t)
    local master=mode.jobMaster;if not master then return end
    local actor=master.actor
    queue[#queue+1]={x=actor.x,y=actor.y,anchorY=actor.y,draw=function()actor:draw()end}
    Builder.queue(mode,queue)
end
return Master
