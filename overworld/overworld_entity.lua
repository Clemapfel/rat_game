
--- @class ow.OverworldEntity
ow.OverworldEntity = meta.new_abstract_type("OverworldEntity", rt.Drawable, {
    _position_x = 0,
    _position_y = 0,
    _is_realized = false,
})

--- @brief
function ow.OverworldEntity:get_position()
    return self._position_x, self._position_y
end

--- @brief
function ow.OverworldEntity:set_position(x, y)
    self._position_x, self._position_y = x, y
end

--- @overload
function ow.OverworldEntity:realize()
    rt.error("In ow.OverworldEntity:realize: abstract method called")
end
