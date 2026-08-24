local UI = {}

function UI.panel(x, y, w, h, accent, alpha)
    love.graphics.setColor(.018, .026, .034, alpha or .92)
    love.graphics.rectangle("fill", x, y, w, h, 8, 8)
    love.graphics.setColor(.22, .29, .33, .9)
    love.graphics.rectangle("line", x, y, w, h, 8, 8)
    if accent then love.graphics.setColor(accent); love.graphics.rectangle("fill", x, y, 4, h, 8, 0) end
end

function UI.bar(x, y, w, h, value, color, background)
    value = math.max(0, math.min(1, value or 0))
    love.graphics.setColor(background or {.08, .11, .13, .95}); love.graphics.rectangle("fill", x, y, w, h, 3, 3)
    if value > 0 then love.graphics.setColor(color); love.graphics.rectangle("fill", x, y, w * value, h, 3, 3) end
    love.graphics.setColor(1, 1, 1, .14); love.graphics.rectangle("line", x, y, w, h, 3, 3)
end

function UI.button(x, y, w, h, label, active, font)
    local mx, my = love.mouse.getPosition()
    local hovered = mx >= x and mx <= x + w and my >= y and my <= y + h
    love.graphics.setColor(active and (hovered and {.98, .7, .2, 1} or {.88, .54, .12, 1}) or {.18, .21, .23, 1})
    love.graphics.rectangle("fill", x, y, w, h, 7, 7)
    love.graphics.setColor(1, 1, 1, active and 1 or .45); love.graphics.setFont(font)
    love.graphics.printf(label, x, y + h / 2 - font:getHeight() / 2, w, "center")
    return hovered
end

return UI
