local UI = {}

function UI.panel(x, y, w, h, accent, alpha)
    love.graphics.setColor(.035, .055, .063, alpha or .9)
    love.graphics.rectangle("fill", x, y, w, h, 8, 8)
    love.graphics.setColor(.3, .4, .42, .82)
    love.graphics.rectangle("line", x, y, w, h, 8, 8)
    if accent then love.graphics.setColor(accent); love.graphics.rectangle("fill", x, y, 4, h, 8, 0) end
end

function UI.bar(x, y, w, h, value, color, background)
    value = math.max(0, math.min(1, value or 0))
    love.graphics.setColor(background or {.08, .11, .13, .95}); love.graphics.rectangle("fill", x, y, w, h, 3, 3)
    if value > 0 then love.graphics.setColor(color); love.graphics.rectangle("fill", x, y, w * value, h, 3, 3) end
    love.graphics.setColor(1, 1, 1, .14); love.graphics.rectangle("line", x, y, w, h, 3, 3)
end

function UI.verticalGradient(x, y, w, h, r, topColor, bottomColor, bands)
    bands = bands or 24
    love.graphics.stencil(function() love.graphics.rectangle("fill", x, y, w, h, r, r) end, "replace", 1)
    love.graphics.setStencilTest("greater", 0)
    local bandH = h / bands
    for i = 0, bands - 1 do
        local t = i / (bands - 1)
        love.graphics.setColor(
            topColor[1] + (bottomColor[1] - topColor[1]) * t,
            topColor[2] + (bottomColor[2] - topColor[2]) * t,
            topColor[3] + (bottomColor[3] - topColor[3]) * t,
            (topColor[4] or 1) + ((bottomColor[4] or 1) - (topColor[4] or 1)) * t
        )
        love.graphics.rectangle("fill", x, y + i * bandH - 1, w, bandH + 2)
    end
    love.graphics.setStencilTest()
end

function UI.button(x, y, w, h, label, active, font, pointerX, pointerY)
    local mx, my = love.mouse.getPosition()
    mx, my = pointerX or mx, pointerY or my
    local hovered = mx >= x and mx <= x + w and my >= y and my <= y + h
    love.graphics.setColor(active and (hovered and {.98, .7, .2, 1} or {.88, .54, .12, 1}) or {.18, .21, .23, 1})
    love.graphics.rectangle("fill", x, y, w, h, 7, 7)
    love.graphics.setColor(1, 1, 1, active and 1 or .45); love.graphics.setFont(font)
    love.graphics.printf(label, x, y + h / 2 - font:getHeight() / 2, w, "center")
    return hovered
end

return UI
