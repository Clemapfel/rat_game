rt.SymbolicTransform = meta.new_type("SymbolicTransform", function()
    local out = meta.new(rt.SymbolicTransform, {
        _offset_x = 0,
        _offset_y = 0,
        _rotation = 0,
        _scale_x = 1,
        _scale_y = 1,
        _shear_x = 1,
        _shear_y = 1
    })
end)

--- @class rt.Drawable
rt.Drawable = meta.new_type("Drawable", function()
    local out = meta.new(rt.Drawable)
    rt.add_signal_component(out)
    rt.add_allocation_component(out)
    return out
end)

rt.Drawable._transform = rt.SymbolicTransform()
rt.Drawable._is_visible = true

meta.declare_abstract_method(rt.Drawable, "draw")
meta.declare_abstract_method(rt.Drawable, "reformat")

--- @brief get whether drawable should be culled
--- @param self rt.Drawable
--- @param b Boolean
function rt.Drawable:set_is_visible(b)
    meta.assert_isa(self, rt.Drawable)
    self._is_visible= b
end

--- @brief get whether drawable should be culled
--- @param self rt.Drawable
--- @return Boolean
function rt.Drawable:get_is_visible()
    meta.assert_isa(self, rt.Drawable)
    return self._is_visible()
end

--- @brief [internal] draw allocation component as wireframe
--- @param self rt.Drawable
function rt.Drawable:draw_hitbox()
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