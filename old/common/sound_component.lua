--- @class rt.SoundComponent
--- @signal finished (self) -> nil
rt.SoundComponent = meta.new_type("SoundComponent", function()
    local out = meta.new(rt.SoundComponent, {
        _position_x = 0,
        _position_y = 0,
        _last_id = nil,
        _native = nil,
        _is_active = false,
        _last_tell = 0
    })
    rt.SoundAtlas:add_sound_component(out)
    return out
end)

meta.add_signal(rt.SoundComponent, "finished")

--- @brief
function rt.SoundComponent:play(id)
    meta.assert_string(id)
    if self._last_id ~= id then
        self._native = rt.SoundAtlas:get_source(id)
        self._last_id = id
    end

    if self._native:isPlaying() then
        self._native:stop()
    end

    self._native:play()
    self._is_active = true
end

--- @brief
function rt.SoundComponent:pause()
    if self._native ~= nil then
        self._native:pause()
        self._is_active = false
    end
end

--- @brief
function rt.SoundComponent:stop()
    if self._native ~= nil then
        self._native:stop()
        self._is_active = false
    end
end

--- @brief
function rt.SoundComponent:rewind()
    if self._native ~= nil then
        self._native:seek(0)
    end
end

--- @brief
function rt.SoundComponent:set_position(x, y)
    self._position_x = x
    self._position_y = y
end
