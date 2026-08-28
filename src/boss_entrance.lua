local Entrance={}
local image,quads

local profiles={
    stumpWarden={row=0,duration=2.55,style="rise",zoom=1.10},
    hollowOak={row=1,duration=2.75,style="rise",zoom=1.11},
    rootjaw={row=2,duration=2.55,style="slide",zoom=1.10},
    baobabTyrant={row=3,duration=2.65,style="drop",zoom=1.12},
    islandHermit={row=4,duration=2.7,style="slide",zoom=1.10},
}

local function smooth(p) p=math.max(0,math.min(1,p));return p*p*(3-2*p) end
local function load()
    if image then return end
    image=love.graphics.newImage("assets/fx/boss-entrance/boss-entrance-fx-atlas-pixel-v1.png")
    image:setFilter("nearest","nearest")
    quads={}
    for row=0,4 do
        quads[row]={}
        for frame=0,5 do quads[row][frame+1]=love.graphics.newQuad(frame*256,row*256,256,256,image:getDimensions()) end
    end
end

function Entrance.start(mode,boss,game)
    if not boss or not profiles[boss.kind] then return false end
    local spec=profiles[boss.kind]
    mode.bossEntrance={boss=boss,t=0,duration=spec.duration,spec=spec,impact=false}
    boss.bossState="entrance";boss.entranceAlpha=0;boss.entranceScaleX=.72;boss.entranceScaleY=.38
    local midX=(boss.x+game.player.x)*.5
    local midY=(boss.y+game.player.y)*.5-25
    if game.camera then game.camera:focus(midX,midY,spec.duration+.18,spec.zoom) end
    return true
end

function Entrance.update(mode,dt,game)
    local state=mode.bossEntrance
    if not state then return false end
    local e,spec=state.boss,state.spec
    if not e or e.hp<=0 then mode.bossEntrance=nil;return false end
    state.t=math.min(state.duration,state.t+dt)
    local p=state.t/state.duration
    local reveal=smooth((p-.16)/.43)
    e.entranceAlpha=reveal
    e.entranceScaleX=.76+reveal*.24
    e.entranceScaleY=.38+reveal*.62
    e.moving=p>.16 and p<.68
    if spec.style=="drop" then
        e.entranceOffsetY=-(1-reveal)*320
        e.entranceScaleX=.82+reveal*.18
        e.entranceScaleY=.82+reveal*.18
    elseif spec.style=="slide" then
        local side=e.x<game.player.x and -1 or 1
        e.entranceOffsetX=side*(1-reveal)*190
        e.entranceOffsetY=(1-reveal)*34
    else
        e.entranceOffsetY=(1-reveal)*118
    end
    if p>=.58 and not state.impact then
        state.impact=true
        if game.camera then
            local side=e.x<game.player.x and -1 or 1
            game.camera:impulse(side*95,55,-side*.055,.065)
            game.camera.trauma=math.min(1,(game.camera.trauma or 0)+.46)
        end
    end
    if state.t>=state.duration then
        e.bossState="idle";e.bossTimer=1.15;e.bossActionFrame=0;e.moving=false
        e.entranceAlpha,e.entranceScaleX,e.entranceScaleY=nil,nil,nil
        e.entranceOffsetX,e.entranceOffsetY=nil,nil
        mode.bossEntrance=nil
        return false
    end
    return true
end

local function drawGround(state)
    load()
    local p=state.t/state.duration
    local fxp=math.max(0,math.min(1,(p-.28)/.54))
    if fxp<=0 then return end
    local frame=math.min(6,math.floor(fxp*6)+1)
    local alpha=math.min(1,fxp*3,(1-fxp)*5+.12)
    love.graphics.setColor(1,1,1,alpha)
    love.graphics.draw(image,quads[state.spec.row][frame],state.boss.x,state.boss.y+18,0,1.28,1.28,128,190)
end

local function drawFront(state)
    local p=state.t/state.duration
    local burst=math.max(0,1-math.abs(p-.58)/.32)
    if burst<=0 then return end
    local e=state.boss
    love.graphics.setLineStyle("rough")
    for i=1,12 do
        local a=i*2.399+state.spec.row*.47
        local r=(34+i*8)*burst
        local x=e.x+math.cos(a)*r
        local y=e.y+8+math.sin(a)*r*.48
        local size=2+(i%3)*2
        love.graphics.setColor(.12,.09,.04,.75*burst)
        love.graphics.rectangle("fill",math.floor(x-size-1),math.floor(y-size-1),size*2+2,size*2+2)
        love.graphics.setColor(state.spec.row==2 and {.32,.72,.64,.92*burst} or state.spec.row==4 and {.78,.91,.79,.92*burst} or {.82,.51,.18,.92*burst})
        love.graphics.rectangle("fill",math.floor(x-size+1),math.floor(y-size),size*2-1,size*2-1)
    end
end

function Entrance.queue(mode,queue)
    local state=mode.bossEntrance
    if not state then return end
    queue[#queue+1]={y=state.boss.y-.2,draw=function() drawGround(state) end}
    queue[#queue+1]={y=state.boss.y+.2,draw=function() drawFront(state) end}
end

function Entrance.active(mode) return mode and mode.bossEntrance~=nil end
function Entrance.profiles() return profiles end
return Entrance
