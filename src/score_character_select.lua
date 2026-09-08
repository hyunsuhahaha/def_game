local F=require("src.frontend_ui")
local Select={}
local ids={"fire","builder"}

function Select.current(game)
    if game.selectedScoreCharacter=="fire"then return "fire"end
    return game.characterTraits:activeScoreJob()
end

function Select.open(game)
    game.characterTraits:completeJobMaster()
    game.scoreCharacterFocus=Select.current(game)=="builder"and 2 or 1
    game.mode="score_character_select"
end

function Select.confirm(game)
    local id=ids[game.scoreCharacterFocus or 1]
    if id=="builder"and not game.characterTraits.data.jobMasterFire then return false end
    game.selectedScoreCharacter=id
    game.mode="lobby"
    return true
end

function Select.layout(w,h)
    local gap,margin=24,40
    local cw=(w-margin*2-gap)/2
    return {
        cards={{x=margin,y=112,w=cw,h=h-212},{x=margin+cw+gap,y=112,w=cw,h=h-212}},
        back={x=margin,y=h-76,w=160,h=44},
        confirm={x=w-margin-260,y=h-76,w=260,h=44},
    }
end

function Select.keypressed(game,key)
    if key=="escape"then game.mode="lobby"
    elseif key=="left"or key=="a"or key=="1"then game.scoreCharacterFocus=1
    elseif key=="right"or key=="d"or key=="2"then game.scoreCharacterFocus=2
    elseif key=="tab"then game.scoreCharacterFocus=3-(game.scoreCharacterFocus or 1)
    elseif key=="return"or key=="kpenter"or key=="space"then Select.confirm(game)end
end

function Select.mousepressed(game,x,y,button)
    if button~=1 then return end
    local layout=Select.layout(love.graphics.getDimensions())
    if F.inside(layout.back,x,y)then game.mode="lobby";return end
    for i,box in ipairs(layout.cards)do if F.inside(box,x,y)then game.scoreCharacterFocus=i;return end end
    if F.inside(layout.confirm,x,y)then Select.confirm(game)end
end

function Select.draw(game)
    local w,h=love.graphics.getDimensions()
    if not Select.fonts then
        local path="assets/font-korean-pixel.ttf"
        Select.fonts={small=love.graphics.newFont(path,14),heading=love.graphics.newFont(path,21),title=love.graphics.newFont(path,36)}
    end
    local f=Select.fonts;local layout=Select.layout(w,h)
    local unlocked=game.characterTraits.data.jobMasterFire
    local selected=Select.current(game)
    game.lobby:drawBackground(w,h)
    love.graphics.setColor(.006,.018,.014,.92);love.graphics.rectangle("fill",0,0,w,h)
    love.graphics.setFont(f.title);love.graphics.setColor(F.colors.ivory)
    love.graphics.print("캐릭터 선택",40,28)
    love.graphics.setFont(f.small);love.graphics.setColor(F.colors.muted)
    love.graphics.print("직접 조종할 캐릭터를 선택하세요. 연구와 재생 단계는 유지됩니다.",40,77)
    for i,box in ipairs(layout.cards)do
        local focused=i==(game.scoreCharacterFocus or 1)
        local available=i==1 or unlocked
        local accent=i==1 and F.colors.teal or F.colors.amber
        F.frame(box.x,box.y,box.w,box.h,accent,{selected=focused})
        love.graphics.setFont(f.heading);love.graphics.setColor(F.colors.ivory)
        love.graphics.print(i==1 and "흡연자"or "건설업자 · 타워크레인",box.x+20,box.y+18)
        love.graphics.setFont(f.small);love.graphics.setColor(available and accent or F.colors.muted)
        local status=not available and "잠김 · 흡연자 모든 노드 만렙 필요"or(selected==ids[i]and "현재 선택"or "선택 가능")
        love.graphics.print(status,box.x+20,box.y+52)
        local availableHeight=box.h-162
        local baseY=box.y+box.h-85
        love.graphics.setColor(1,1,1,available and 1 or .6)
        if i==1 then
            local sprite=game.clearcutSprites.fire
            local im=sprite.image;local fw,fh=im:getWidth()/6,im:getHeight()/2
            Select.smokerQuad=Select.smokerQuad or love.graphics.newQuad(0,0,fw,fh,im:getDimensions())
            local scale=math.min(1.15,availableHeight/fh)
            love.graphics.draw(im,Select.smokerQuad,box.x+box.w/2,baseY,0,scale,scale,fw/2,fh-2)
        else
            local scale=math.min(availableHeight/650,(box.w-50)/880)
            love.graphics.push();love.graphics.translate(box.x+box.w*.29,baseY);love.graphics.scale(scale,scale)
            require("src.construction_art").drawCrane({aimX=280,aimY=0,launchDistance=280,dropHeight=320,stats={radius=42}},
                {x=0,y=0,isMoving=false})
            love.graphics.pop()
        end
        love.graphics.setFont(f.small);love.graphics.setColor(F.colors.ivory)
        local detail=i==1 and "WASD 이동 · 담배와 도끼 등 기존 무기 직접 사용"
            or "WASD 크레인 이동 · 좌클릭 자재 투하"
        love.graphics.printf(detail,box.x+20,box.y+box.h-65,box.w-40,"left")
        love.graphics.setColor(F.colors.muted)
        love.graphics.printf(i==1 and "기존 연구의 능력과 수치를 그대로 사용합니다."
            or "해금 후 흡연자 잡 마스터가 자동으로 함께 싸웁니다.",box.x+20,box.y+box.h-39,box.w-40,"left")
    end
    local enabled=game.scoreCharacterFocus~=2 or unlocked
    F.button(layout.back,"돌아가기",f.small,{key="ESC"})
    F.button(layout.confirm,enabled and "선택 완료"or "잡 마스터 필요",f.small,{primary=enabled,enabled=enabled,key="ENT"})
end

return Select
