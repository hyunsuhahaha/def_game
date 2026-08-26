local Lobby = {}
Lobby.__index = Lobby

local function inside(box, x, y)
    return box and x >= box.x and x <= box.x + box.w and y >= box.y and y <= box.y + box.h
end

function Lobby.new(images, fonts)
    local background = love.graphics.newImage("assets/lobby-command-overlook-v1.png")
    background:setFilter("linear", "linear", 8)
    return setmetatable({
        images = images,
        fonts = fonts,
        background = background,
        displayFont = love.graphics.newFont("assets/font-korean-bold.ttf", 48),
        labelFont = love.graphics.newFont("assets/font-korean-regular.ttf", 13),
        time = 0,
        clearcutHover = 0
    }, Lobby)
end

function Lobby:update(dt)
    self.time = self.time + dt
    local mx, my = love.mouse.getPosition()
    local clearcutTarget = inside(self.clearcutBox, mx, my) and 1 or 0
    self.clearcutHover = self.clearcutHover + (clearcutTarget - self.clearcutHover) * math.min(1, dt * 11)
end

function Lobby:keypressed(key)
    if key == "return" or key == "space" or key == "c" then return "clearcut" end
    if key == "t" then return "character_traits" end
end

function Lobby:mousepressed(x, y, button)
    if button ~= 1 then return end
    if inside(self.clearcutBox, x, y) then return "clearcut" end
    if inside(self.traitsBox, x, y) then return "character_traits" end
    if inside(self.settingsBox, x, y) then return "settings" end
end

function Lobby:drawBackground(w, h)
    local iw, ih = self.background:getDimensions()
    local scale = math.max(w / iw, h / ih) * 1.015
    local dw, dh = iw * scale, ih * scale
    local drift = math.sin(self.time * .12) * 4
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.background, (w - dw) / 2 + drift, (h - dh) / 2, 0, scale, scale)

    love.graphics.setColor(.02, .045, .035, .12)
    love.graphics.rectangle("fill", 0, 0, w, h)
    local shadeWidth = math.min(w * .64, 760)
    for i = 0, 20 do
        local t = i / 20
        love.graphics.setColor(.012, .032, .026, .78 * (1 - t) * (1 - t))
        love.graphics.rectangle("fill", shadeWidth * t, 0, shadeWidth / 20 + 2, h)
    end
    for i = 0, 9 do
        local t = i / 9
        love.graphics.setColor(.012, .028, .023, .42 * (1 - t))
        love.graphics.rectangle("fill", 0, h - 130 + t * 130, w, 130 / 9 + 1)
    end
end

function Lobby:draw()
    local w, h = love.graphics.getDimensions()
    local fonts = self.fonts
    self:drawBackground(w, h)

    local navY, navGap, navW = 24, 10, 116
    self.settingsBox = {x = w - 30 - navW, y = navY, w = navW, h = 38}
    self.traitsBox = {x = self.settingsBox.x - navGap - navW, y = navY, w = navW, h = 38}
    for _, item in ipairs({{box = self.traitsBox, label = "캐릭터 특성"}, {box = self.settingsBox, label = "설정"}}) do
        local hovered = inside(item.box, love.mouse.getPosition())
        love.graphics.setColor(.025, .055, .045, hovered and .84 or .66)
        love.graphics.rectangle("fill", item.box.x, item.box.y, item.box.w, item.box.h, 7, 7)
        love.graphics.setColor(.9, .95, .87, hovered and .95 or .72)
        love.graphics.rectangle("line", item.box.x + .5, item.box.y + .5, item.box.w - 1, item.box.h - 1, 7, 7)
        love.graphics.setFont(self.labelFont)
        love.graphics.printf(item.label, item.box.x, item.box.y + 10, item.box.w, "center")
    end

    local left = math.max(42, w * .052)
    local titleY = math.max(74, h * .14)
    love.graphics.setFont(self.labelFont)
    love.graphics.setColor(.82, .68, .32, .95)
    love.graphics.print("인간 문명 최후의 벌목 사업", left, titleY)

    love.graphics.setFont(self.displayFont)
    love.graphics.setColor(.98, .98, .92, 1)
    love.graphics.print("숲이 다시 자라기 전에", left - 2, titleY + 31)
    love.graphics.print("전부 없애세요", left - 2, titleY + 82)

    love.graphics.setFont(fonts.body)
    love.graphics.setColor(.84, .89, .83, .78)
    love.graphics.printf("숲의 재생력은 계속 강해집니다.\n캐릭터의 방식으로 파괴율 100%를 달성하세요.", left, titleY + 152, math.min(430, w * .4), "left")

    local buttonW, buttonH = math.min(390, w * .38), 82
    self.clearcutBox = {x=left,y=math.min(h-150,titleY+255),w=buttonW,h=buttonH}
    local ccLift=self.clearcutHover*3
    local cx,cy=self.clearcutBox.x,self.clearcutBox.y-ccLift
    love.graphics.setColor(.055,.07,.025,.38); love.graphics.rectangle("fill",cx+4,cy+9,buttonW,buttonH,13,13)
    love.graphics.setColor(.82+self.clearcutHover*.08,.68+self.clearcutHover*.1,.3+self.clearcutHover*.06,1); love.graphics.rectangle("fill",cx,cy,buttonW,buttonH,11,11)
    love.graphics.setColor(1,.93,.66,.42+self.clearcutHover*.3); love.graphics.rectangle("line",cx+.5,cy+.5,buttonW-1,buttonH-1,11,11)
    love.graphics.setFont(fonts.heading); love.graphics.setColor(.09,.085,.035,1); love.graphics.print("숲 전멸 시작",cx+24,cy+16)
    love.graphics.setFont(self.labelFont); love.graphics.setColor(.18,.15,.06,.78); love.graphics.print("캐릭터 선택 후 즉시 투입",cx+24,cy+50); love.graphics.printf("ENTER",cx,cy+33,buttonW-24,"right")

    love.graphics.setFont(self.labelFont)
    love.graphics.setColor(.9, .95, .9, .5)
    love.graphics.print("ESC  종료", left, h - 31)
end

return Lobby
