function rt.snapshot_widget(widget)
    local x, y = widget:get_position()
    local w, h = widget:measure()
    local out = {}
    out.canvas = love.graphics.newCanvas(w, h)

    out.draw = function(self)
        love.graphics.draw(self.canvas)
    end

    love.graphics.setCanvas({
        canvas,
        stencil = true
    })
    love.graphics.stencil(function()
    end, "replace", 0, false)
    love.graphics.clear(1, 1, 0, 0)
    love.graphics.line(0, 0, 500, 500)
    widget:draw()
    love.graphics.setCanvas()

    return out
end