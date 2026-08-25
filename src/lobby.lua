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
        displayFont = love.graphics.newFont("assets/font-korean.ttf", 48),
        labelFont = love.graphics.newFont("assets/font-korean.ttf", 13),
        time = 0,
        hover = 0,
        rushHover = 0
    }, Lobby)
end

function Lobby:update(dt)
    self.time = self.time + dt
    local mx, my = love.mouse.getPosition()
    local target = inside(self.startBox, mx, my) and 1 or 0
    local rushTarget = inside(self.rushBox, mx, my) and 1 or 0
    self.hover = self.hover + (target - self.hover) * math.min(1, dt * 11)
    self.rushHover = self.rushHover + (rushTarget - self.rushHover) * math.min(1, dt * 11)
end

function Lobby:keypressed(key)
    if key == "return" or key == "space" then return "start" end
    if key == "r" then return "rush" end
end

function Lobby:mousepressed(x, y, button)
    if button ~= 1 then return end
    if inside(self.startBox, x, y) then return "start" end
    if inside(self.rushBox, x, y) then return "rush" end
    if inside(self.traitsBox, x, y) then return "meta" end
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
    for _, item in ipairs({{box = self.traitsBox, label = "영구 특성"}, {box = self.settingsBox, label = "설정"}}) do
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
    love.graphics.setColor(.95, .7, .3, .95)
    love.graphics.print("LAST HAUL  ·  전진 보급대", left, titleY)

    love.graphics.setFont(self.displayFont)
    love.graphics.setColor(.98, .98, .92, 1)
    love.graphics.print("거점을 키우고", left - 2, titleY + 31)
    love.graphics.print("전선을 지키세요", left - 2, titleY + 82)

    love.graphics.setFont(fonts.body)
    love.graphics.setColor(.84, .89, .83, .78)
    love.graphics.printf("자원 생산과 설비 조합은\n작전 안에서 자유롭게 결정됩니다.", left, titleY + 152, math.min(390, w * .38), "left")

    local buttonW, buttonH = math.min(320, w * .34), 68
    self.startBox = {x = left, y = math.min(h - 220, titleY + 238), w = buttonW, h = buttonH}
    local lift = self.hover * 3
    local x, y = self.startBox.x, self.startBox.y - lift
    love.graphics.setColor(.08, .07, .035, .3)
    love.graphics.rectangle("fill", x + 3, y + 8, buttonW, buttonH, 11, 11)
    love.graphics.setColor(
        .91 + self.hover * .06,
        .59 + self.hover * .12,
        .2 + self.hover * .08,
        1
    )
    love.graphics.rectangle("fill", x, y, buttonW, buttonH, 10, 10)
    love.graphics.setColor(1, .9, .58, .32 + self.hover * .22)
    love.graphics.rectangle("line", x + .5, y + .5, buttonW - 1, buttonH - 1, 10, 10)

    love.graphics.setFont(fonts.heading)
    love.graphics.setColor(.075, .065, .035, 1)
    love.graphics.print("기존 15분 작전", x + 22, y + 19)
    love.graphics.setFont(self.labelFont)
    love.graphics.setColor(.14, .105, .05, .68)
    love.graphics.printf("ENTER", x, y + 25, buttonW - 22, "right")

    self.rushBox = {x=left,y=self.startBox.y+80,w=buttonW,h=64}
    local rushLift=self.rushHover*3
    local rx,ry=self.rushBox.x,self.rushBox.y-rushLift
    love.graphics.setColor(.025,.08,.045,.5); love.graphics.rectangle("fill",rx+3,ry+8,buttonW,64,11,11)
    love.graphics.setColor(.25+self.rushHover*.08,.82+self.rushHover*.12,.42+self.rushHover*.08,1); love.graphics.rectangle("fill",rx,ry,buttonW,64,10,10)
    love.graphics.setColor(.75,1,.72,.4+self.rushHover*.3); love.graphics.rectangle("line",rx+.5,ry+.5,buttonW-1,63,10,10)
    love.graphics.setFont(fonts.heading); love.graphics.setColor(.025,.11,.05,1); love.graphics.print("채집 러시 실험실",rx+22,ry+10)
    love.graphics.setFont(self.labelFont); love.graphics.setColor(.04,.16,.075,.78); love.graphics.print("3분 · 벌목 폭주 · 전용 3택",rx+22,ry+39); love.graphics.printf("R",rx,ry+22,buttonW-22,"right")

    love.graphics.setFont(self.labelFont)
    love.graphics.setColor(.9, .95, .9, .5)
    love.graphics.print("ESC  종료", left, h - 31)
end

return Lobby
