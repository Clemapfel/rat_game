--- @class rt.Drawable
rt.Drawable = meta.new_abstract_type("Drawable", {
    _is_visible = true
})

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
