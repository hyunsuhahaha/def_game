-- 로비 오디오 플레이어 위에서 도는 CD.
--
-- 원반은 원이라 실루엣을 돌려 봐야 화면에서 아무 일도 일어나지 않는다. 그래서
-- 스프라이트를 런타임에 회전시키지 않고, 광택이 돌아간 16프레임을 미리 구운
-- 아틀라스를 넘긴다. 픽셀 자산을 임의 각도로 돌리면 격자가 어긋나 뭉개지는데
-- 그건 이 저장소의 픽셀 규칙에 어긋난다.
--
-- 자산: assets/ui/lobby-cd-spin-pixel-v1.png  (scripts/build_lobby_cd_art.py)
local CdArt={}

local CELL,FRAMES=48,16
CdArt.CELL,CdArt.FRAMES=CELL,FRAMES

local image,quads

local function load()
    if quads then return image end
    local ok=pcall(function()
        image=love.graphics.newImage("assets/ui/lobby-cd-spin-pixel-v1.png")
        image:setFilter("nearest","nearest")
        quads={}
        for i=0,FRAMES-1 do
            quads[i+1]=love.graphics.newQuad(i*CELL,0,CELL,CELL,image:getDimensions())
        end
    end)
    if not ok then image,quads=nil,{} end
    return image
end

-- 회전 상태. 재생을 누르면 서서히 속도가 붙고, 멈추면 관성으로 천천히 선다.
-- 즉시 켜지고 꺼지면 기계가 아니라 아이콘으로 보인다.
CdArt.SPIN_SPEED=2.35      -- 최고 속도(초당 회전)
CdArt.SPIN_UP=2.6          -- 가속
CdArt.SPIN_DOWN=1.15       -- 감속. 가속보다 느려야 "돌던 것이 선다"로 읽힌다

function CdArt.newState()
    return {angle=0,speed=0}
end

function CdArt.update(state,dt,spinning)
    if not state then return end
    local target=spinning and CdArt.SPIN_SPEED or 0
    local rate=spinning and CdArt.SPIN_UP or CdArt.SPIN_DOWN
    state.speed=state.speed+(target-state.speed)*math.min(1,dt*rate)
    if not spinning and state.speed<.02 then state.speed=0 end
    state.angle=(state.angle+state.speed*dt)%1
end

-- x,y 는 원반의 중심. 정수 좌표로 그려야 픽셀 격자가 흐트러지지 않는다.
function CdArt.draw(state,x,y)
    if not load() or not quads[1] then return end
    local frame=math.floor((state and state.angle or 0)*FRAMES)%FRAMES+1
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(image,quads[frame],math.floor(x-CELL/2),math.floor(y-CELL/2))
end

return CdArt
