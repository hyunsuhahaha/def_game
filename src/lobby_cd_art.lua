-- 로비 오디오 바 뒤에서 솟는, 곡마다 다른 소형 반원 CD.
-- 3개 행은 숲/강/밤 곡의 서로 다른 라벨과 재질이고, 32개 열은 좁고 은은한
-- 반사광이다. 런타임 임의 회전은 픽셀 격자를 흐리므로 쓰지 않는다.
local CdArt={}

local FRAMES,TRACKS=32,3
CdArt.FRAMES,CdArt.TRACKS=FRAMES,TRACKS

local SIZES={
    large={file="assets/ui/lobby-cd-tracks-half-pixel-v2.png",radius=76,w=160,h=84},
    small={file="assets/ui/lobby-cd-tracks-half-small-pixel-v2.png",radius=52,w=112,h=60},
}
CdArt.SIZES=SIZES

local loaded={}
local function load(key)
    local entry=loaded[key]
    if entry~=nil then return entry or nil end
    local size=SIZES[key]
    local made
    local ok=pcall(function()
        local image=love.graphics.newImage(size.file)
        image:setFilter("nearest","nearest")
        local quads={}
        for track=1,TRACKS do
            quads[track]={}
            for frame=0,FRAMES-1 do
                quads[track][frame+1]=love.graphics.newQuad(
                    frame*size.w,(track-1)*size.h,size.w,size.h,image:getDimensions())
            end
        end
        made={image=image,quads=quads,size=size}
    end)
    loaded[key]=(ok and made)or false
    return loaded[key]or nil
end

-- 기존 작업본의 초당 .62회전(대칭광 기준 초당 1.24회)은 시선이 너무 자주
-- 흔들렸다. 단일 반사광이 약 5.6초에 한 바퀴만 돌도록 낮춘다.
CdArt.SPIN_SPEED=.18
CdArt.SPIN_UP=1.45
CdArt.SPIN_DOWN=.72

function CdArt.newState()return{angle=0,speed=0}end

function CdArt.update(state,dt,spinning)
    if not state then return end
    local target=spinning and CdArt.SPIN_SPEED or 0
    local rate=spinning and CdArt.SPIN_UP or CdArt.SPIN_DOWN
    state.speed=state.speed+(target-state.speed)*math.min(1,dt*rate)
    if not spinning and state.speed<.002 then state.speed=0 end
    state.angle=(state.angle+state.speed*dt)%1
end

function CdArt.frame(state)
    return math.floor((state and state.angle or 0)*FRAMES)%FRAMES+1
end

function CdArt.track(index)
    return math.max(1,math.min(TRACKS,math.floor(index or 1)))
end

function CdArt.radius(key)return SIZES[key]and SIZES[key].radius or 0 end

function CdArt.draw(state,key,track,x,y)
    local entry=load(key)
    if not entry then return end
    local size=entry.size
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(entry.image,entry.quads[CdArt.track(track)][CdArt.frame(state)],
        math.floor(x-size.w/2),math.floor(y-size.radius-4))
end

return CdArt
