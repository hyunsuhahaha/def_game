local Tutorial={}

local FINAL_DURATION=4.0

local function rangedCount(audit)
    audit=audit or{}
    return (audit.cigaretteFlick or 0)+(audit.fireworkShot or 0)+(audit.flameTick or 0)+(audit.vapeShot or 0)
end

local function begin(mode,persist)
    mode.scoreTutorial={step=1,elapsed=0,axe=(mode.actionAudit or{}).scoreAxe or 0,
        ranged=rangedCount(mode.actionAudit),persist=persist~=false}
    mode.scoreTutorialRun=true
    return true
end

function Tutorial.shouldStart(game)
    local traits=game and game.characterTraits
    return traits and traits.shouldStartScoreTutorial and traits:shouldStartScoreTutorial()or false
end

function Tutorial.start(mode,game)
    local traits=game and game.characterTraits
    if not mode or not mode.scoreAttack or mode.scorePractice or mode.defenseMode or
        not traits or not Tutorial.shouldStart(game)then
        return false
    end
    return begin(mode,true)
end

-- Developer-tool replay. It deliberately ignores permanent onboarding state and
-- never marks the real tutorial as seen.
function Tutorial.forceStart(mode)
    if not mode or not mode.scoreAttack or mode.scorePractice or mode.defenseMode then return false end
    return begin(mode,false)
end

local function placeLessonTree(mode,game,distance)
    local target
    for _,node in ipairs((game.world and game.world.nodes)or{})do
        if node.rushTree and node.active and not target then target=node
        elseif node.rushTree then node.active=false end
    end
    if not target then return false end
    target.active=true
    target.x,target.y=game.player.x+distance,game.player.y
    target.rushHp,target.rushMaxHp=math.max(12,target.rushMaxHp or 0),math.max(12,target.rushMaxHp or 0)
    target.burning,target.burnTimer,target.treeEmergence,target.fallT,target.uprooted=nil,nil,nil,nil,nil
    target.hitFlash,target.swayAngle,target.swayVel=0,0,0
    mode.scoreTutorialTarget=target
    mode.remainingTrees,mode.initialTrees,mode.totalTreesSpawned,mode.peakActiveTrees=1,1,1,1
    return true
end

function Tutorial.prepareWorld(mode,game)
    if not mode or not mode.scoreTutorialRun or not game or not game.player then return false end
    return placeLessonTree(mode,game,90)
end

function Tutorial.update(mode,game,dt)
    local state=mode and mode.scoreTutorial
    if not state then return end
    state.elapsed=state.elapsed+dt
    local audit=mode.actionAudit or{}
    if state.step==1 and(audit.scoreAxe or 0)>state.axe then
        state.step,state.elapsed,state.ranged=2,0,rangedCount(audit)
        placeLessonTree(mode,game,280)
    elseif state.step==2 and rangedCount(audit)>state.ranged then
        state.step,state.elapsed=3,0
    elseif state.step==3 and state.elapsed>=FINAL_DURATION then
        if state.persist and game.characterTraits and game.characterTraits.markScoreTutorialSeen then
            game.characterTraits:markScoreTutorialSeen()
        end
        mode.scoreTutorial=nil
        mode.scoreTutorialComplete=true
    end
end

function Tutorial.draw(mode,fonts,w,h)
    local state=mode and mode.scoreTutorial
    if not state then return end
    local compact=w<1100 or h<620
    local panelW=math.min(compact and 420 or 500,w-40)
    local panelH=compact and 62 or 70
    local x,y=math.floor((w-panelW)/2),compact and 18 or 24
    local accent=state.step==1 and{1,.62,.16,1}or(state.step==2 and{.38,.86,.68,1}or{1,.80,.30,1})
    local title,detail
    if state.step==1 then title,detail="가까운 나무 클릭","도끼로 벤다"
    elseif state.step==2 then title,detail="먼 나무 클릭","담배를 던진다"
    else title,detail="숲이 가득 차면 작업 종료","번 코인으로 강화하고 다시 도전"end

    love.graphics.setColor(.012,.030,.024,.94);love.graphics.rectangle("fill",x,y,panelW,panelH)
    love.graphics.setColor(accent);love.graphics.rectangle("fill",x,y,5,panelH)
    love.graphics.setLineWidth(2);love.graphics.rectangle("line",x+.5,y+.5,panelW-1,panelH-1)
    love.graphics.setFont(fonts.heading or fonts.body);love.graphics.setColor(.98,.96,.84,1)
    love.graphics.printf(title,x+18,y+(compact and 8 or 10),panelW-36,"center")
    love.graphics.setFont(fonts.micro or fonts.small);love.graphics.setColor(accent)
    love.graphics.printf(detail,x+18,y+(compact and 37 or 43),panelW-36,"center")
    love.graphics.setColor(1,1,1,1)
end

Tutorial.FINAL_DURATION=FINAL_DURATION
return Tutorial
