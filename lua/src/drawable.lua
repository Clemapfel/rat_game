--- @class SymbolicTransform
rt.SymbolicTransform = meta.new_type("SymbolicTransform", function()
    return meta.new(rt.SymbolicTransform, {
        rotation = 0, -- in rad
        scale_x = 1,
        scale_y = 1,
        shear_x = 0,
        shear_y = 0
    })
end)

--- @class rt.Drawable
rt.Drawable = meta.new_type("Drawable", function()
    local out = meta.new(rt.Drawable, {
        _transform = rt.SymbolicTransform(),
    })
    rt.add_signal_component(out)
    rt.add_allocation_component(out)
    return out
end)

--- @brief [internal] draw allocation component as wireframe
--- @param self rt.Drawable
function rt.Drawable.draw_hitbox(self)
    meta.assert_inherits(self, rt.Drawable)

    local allocation = rt.get_allocation_component(self)
    love.graphics.setLineWidth(1)
    love.graphics.setLineStyle("rough")
    love.graphics.setColor(1, 0, 1, 1)
    local bounds = allocation:get_bounds()
    love.graphics.line(
        bounds.x, bounds.y,
        bounds.x + bounds.width, bounds.y,
        bounds.x + bounds.width, bounds.y + bounds.height,
        bounds.x, bounds.y + bounds.height,
        bounds.x, bounds.y
    )

    love.graphics.setColor(0, 1, 1, 1)
    bounds = allocation._bounds
    love.graphics.line(
        bounds.x, bounds.y,
        bounds.x + bounds.width, bounds.y,
        bounds.x + bounds.width, bounds.y + bounds.height,
        bounds.x, bounds.y + bounds.height,
        bounds.x, bounds.y
    )

    love.graphics.setColor(0, 1, 0, 1)
    love.graphics.points(bounds.x + 0.5 * bounds.width, bounds.y + 0.5 * bounds.height)
end

function rt.Drawable.draw(self)

end