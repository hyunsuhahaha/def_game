local UI = require("src.ui")

local Lobby = {}
Lobby.__index = Lobby

function Lobby.new(images, fonts)
    local self = setmetatable({images = images, fonts = fonts, time = 0, selected = 2}, Lobby)
    self.plans = {
        {name = "생체 군락", tag = "농업 중심", color = {.34, .88, .38}, desc = "식량과 씨앗을 더 보유합니다.\n초반부터 생체 수호자를 키웁니다."},
        {name = "회수 기술", tag = "채광 중심", color = {.25, .76, 1}, desc = "광석을 더 보유합니다.\n포탑 연구를 빠르게 시작합니다."},
        {name = "현장 기술자", tag = "균형 성장", color = {1, .66, .2}, desc = "가방이 크고 채집이 빠릅니다.\n모든 자원을 고르게 다룹니다."}
    }
    local fw, fh = images.workerWalk:getWidth() / 8, images.workerWalk:getHeight()
    self.frameWidth, self.frames = fw, {}
    for i = 0, 7 do self.frames[i + 1] = love.graphics.newQuad(i * fw, 0, fw, fh, images.workerWalk:getDimensions()) end
    return self
end

function Lobby:update(dt) self.time = self.time + dt end

function Lobby:keypressed(key)
    if key == "left" or key == "a" then self.selected = math.max(1, self.selected - 1) end
    if key == "right" or key == "d" then self.selected = math.min(3, self.selected + 1) end
    if key == "return" or key == "space" then return self.selected end
end

function Lobby:mousepressed(x, y, button)
    if button ~= 1 then return end
    local w, h = love.graphics.getDimensions()
    local cardX, cardW, cardH, gap = w - 355, 315, 96, 12
    for i = 1, 3 do
        local cy = 190 + (i - 1) * (cardH + gap)
        if x >= cardX and x <= cardX + cardW and y >= cy and y <= cy + cardH then self.selected = i end
    end
    if x >= w / 2 - 150 and x <= w / 2 + 150 and y >= h - 88 and y <= h - 34 then return self.selected end
    if x >= 34 and x <= 344 and y >= 568 and y <= 620 then return "meta" end
end

local function tiled(img, w, h)
    love.graphics.setColor(1, 1, 1, 1)
    local size, sx, sy = 300, 300 / img:getWidth(), 300 / img:getHeight()
    for y = 0, h, size do for x = 0, w, size do love.graphics.draw(img, x, y, 0, sx, sy) end end
end

function Lobby:draw()
    local w, h = love.graphics.getDimensions()
    local fonts, plan = self.fonts, self.plans[self.selected]
    love.graphics.clear(.08, .12, .13); tiled(self.images.industrial, w, h)
    love.graphics.setBlendMode("screen", "alphamultiply"); love.graphics.setColor(.28, .42, .33, .17); love.graphics.rectangle("fill", 0, 0, w, h); love.graphics.setBlendMode("alpha")
    love.graphics.setColor(.045, .08, .085, .9); love.graphics.rectangle("fill", 0, 0, w, 104)
    love.graphics.setColor(.9, .56, .12, 1); love.graphics.rectangle("fill", 0, 101, w, 3)
    love.graphics.setFont(fonts.title); love.graphics.setColor(1, 1, 1); love.graphics.print("LAST HAUL", 38, 20)
    love.graphics.setFont(fonts.small); love.graphics.setColor(.57, .67, .7); love.graphics.print("전진 보급 사령부  /  로비 01", 40, 66)
    love.graphics.setColor(.35, 1, .58); love.graphics.circle("fill", w - 202, 39, 5)
    love.graphics.setColor(.8, .9, .84); love.graphics.print("대원 연결됨", w - 187, 30)

    UI.panel(34, 138, 310, 412, {.2, .75, .84, 1})
    love.graphics.setFont(fonts.heading); love.graphics.setColor(1, 1, 1); love.graphics.print("작전 브리핑", 58, 160)
    love.graphics.setFont(fonts.small); love.graphics.setColor(.48, .62, .67); love.graphics.print("작전 목표", 58, 207)
    love.graphics.setFont(fonts.body); love.graphics.setColor(.92, .95, .96); love.graphics.print("보급 거점을 방어하십시오", 58, 228)
    love.graphics.setFont(fonts.small); love.graphics.setColor(.48, .62, .67); love.graphics.print("생존 시간", 58, 274)
    love.graphics.setFont(fonts.heading); love.graphics.setColor(1, .68, .22); love.graphics.print("15:00", 58, 296)
    love.graphics.setFont(fonts.small); love.graphics.setColor(.48, .62, .67); love.graphics.print("작전 구역", 58, 350)
    love.graphics.setColor(.24, .31, .34); love.graphics.rectangle("fill", 58, 374, 260, 112, 5, 5)
    love.graphics.setColor(.72, .35, .2); love.graphics.rectangle("fill", 68, 384, 240, 29, 3, 3)
    love.graphics.setColor(.35, .72, .38); love.graphics.rectangle("fill", 68, 419, 112, 57, 3, 3)
    love.graphics.setColor(.28, .55, .78); love.graphics.rectangle("fill", 186, 419, 122, 57, 3, 3)
    love.graphics.setColor(.9, .62, .16); love.graphics.circle("fill", 188, 416, 7)
    love.graphics.setColor(.74, .81, .83); love.graphics.print("북쪽: 전투", 72, 389); love.graphics.print("서쪽: 농장·숲", 72, 435); love.graphics.print("동쪽: 채석·광산", 194, 435)
    love.graphics.setColor(.55, .64, .67); love.graphics.print("모든 구역은 하나의 월드로 연결됩니다.", 58, 507)
    UI.button(34, 568, 310, 52, "영구 특성 관제망  [T]", true, fonts.body)

    local cx, groundY = w / 2, h - 112
    love.graphics.setColor(0, 0, 0, .55); love.graphics.ellipse("fill", cx, groundY, 115, 32)
    love.graphics.setColor(plan.color); love.graphics.ellipse("line", cx, groundY, 124 + math.sin(self.time * 2) * 4, 38)
    local frame = math.floor(self.time * 5) % 8 + 1
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(self.images.workerWalk, self.frames[frame], cx, groundY + 8, 0, .38, .38, self.frameWidth / 2, self.images.workerWalk:getHeight() * .9)
    love.graphics.setFont(fonts.heading); love.graphics.setColor(1, 1, 1); love.graphics.printf("회수 기술자", cx - 180, 138, 360, "center")
    love.graphics.setFont(fonts.small); love.graphics.setColor(plan.color); love.graphics.printf("초기 보급: " .. plan.name, cx - 180, 169, 360, "center")

    local cardX, cardW, cardH, gap = w - 355, 315, 96, 12
    love.graphics.setFont(fonts.heading); love.graphics.setColor(1, 1, 1); love.graphics.print("초기 보급 선택", cardX, 143)
    for i, item in ipairs(self.plans) do
        local y = 190 + (i - 1) * (cardH + gap)
        UI.panel(cardX, y, cardW, cardH, i == self.selected and item.color or {.22, .27, .29, 1}, i == self.selected and .97 or .82)
        if i == self.selected then love.graphics.setColor(item.color); love.graphics.rectangle("fill", cardX + cardW - 8, y + 8, 3, cardH - 16) end
        love.graphics.setFont(fonts.body); love.graphics.setColor(i == self.selected and 1 or .72, i == self.selected and 1 or .76, i == self.selected and 1 or .78); love.graphics.print(item.name, cardX + 18, y + 11)
        love.graphics.setFont(fonts.small); love.graphics.setColor(item.color); love.graphics.print(item.tag, cardX + 18, y + 38)
        love.graphics.setColor(.62, .69, .71); love.graphics.print(item.desc, cardX + 18, y + 58)
    end
    UI.button(w / 2 - 150, h - 88, 300, 54, "작전 투입  [ENTER]", true, fonts.heading)
    love.graphics.setFont(fonts.small); love.graphics.setColor(.62, .69, .71); love.graphics.printf("초기 보급은 시작 자원만 바꿉니다 · 런 강화는 자유롭게 조합", 0, h - 27, w, "center")
end

return Lobby
