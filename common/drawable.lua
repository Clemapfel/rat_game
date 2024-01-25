--- @class rt.Drawable
rt.Drawable = meta.new_abstract_type("Drawable")
rt.Drawable._is_visible = true

--- @class rt.Transform
rt.Transform = meta.new_type("Transform", function()
    local out = meta.new(rt.Transform, {
        _offset_x = 0,
        _offset_y = 0,
        _rotation = 0,
        _scale_x = 1,
        _scale_y = 1,
        _shear_x = 0,
        _shear_y = 0
    })
    return out
end)

--- @brief [internal] paste a love drawable
--- @param x Number
--- @param y Number
--- @param transform rt.Transform
function rt.Drawable:render(love_drawable, x, y, transform)

    if self._is_visible == false then
        return
    end

    if meta.is_nil(transform) then
        love.graphics.draw(love_drawable, x, y)
    else
        love.graphics.draw(love_drawable,
            x,
            y,
            transform._rotation,
            transform._scale_x,
            transform._scale_y,
            transform._offset_x,
            transform._offset_y,
            transform._shear_x,
            transform._shear_y
        )
    end
end

--- @brief abstract method, must be overriden
function rt.Drawable:draw()
    rt.error("In " .. meta.typeof(self) .. ":draw(): abstract method called")
end

--- @brief set whether drawable should be culled, this affects `render`
--- @param b Boolean
function rt.Drawable:set_is_visible(b)

    self._is_visible = b
end

--- @brief get whether drawable is visible
--- @return Boolean
function rt.Drawable:get_is_visible()
    return self._is_visible
end

--- @brief [internal] test drawable
function rt.test.drawable()

end
