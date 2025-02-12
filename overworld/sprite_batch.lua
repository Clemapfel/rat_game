ow.SpriteBatch = meta.new_type("SpriteBatch", function(texture)
    meta.assert_isa(texture, rt.Texture)
    texture:set_wrap_mode(rt.TextureWrapMode.REPEAT)
    return meta.new(ow.SpriteBatch, {
        _texture = texture,
        _mesh = rt.VertexRectangle(0, 0, 1, 1),
        _draw_shader = rt.Shader("overworld/sprite_batch_draw.glsl"),
        _buffer = nil,
        _needs_update = true,
        _first_index_that_needs_update = 1,
        _last_index_that_needs_update = 0,
        _data = {},
        _current_i = 0
    })
end)

function ow.SpriteBatch._params_to_data(x, y, w, h, tx, ty, tw, th, flip_horizontally, flip_vertically, angle)
    local flip_v, flip_h
    if flip_horizontally == true then flip_h = 1 else flip_h = 0 end
    if flip_vertically == true then flip_v = 1 else flip_v = 0 end

    return {
        x + 0, y + 0, -- top_left
        x + w, y + 0, -- top_right
        x + w, y + h, -- bottom_left
        x + 0, y + h, -- bottom_right

        tx +  0, ty +  0, -- texture_top_left
        tx + tw, ty +  0, -- texture_top_right
        tx + tw, ty + th, -- texture_bottom_right
        tx +  0, ty + th, -- texture_bottom_left

        flip_h, flip_v,
        angle
    }
end

--- @brief
--- @return
function ow.SpriteBatch:add(x, y, w, h, tx, ty, tw, th, flip_horizontally, flip_vertically, angle)
    meta.assert_number(x, y, w, h, tx, ty, tw, th)
    if flip_horizontally == nil then flip_horizontally = false end
    if flip_vertically == nil then flip_vertically = false end
    if angle == nil then angle = 0 end
    
    table.insert(self._data, self._params_to_data(
        x, y, w, h, 
        tx, ty, tw, th, 
        flip_horizontally, flip_vertically, 
        angle
    ))

    self._current_i = self._current_i + 1
    self._needs_update = true
    self._first_index_that_needs_update = math.min(self._first_index_that_needs_update, 1)
    self._last_index_that_needs_update = math.max(self._last_index_that_needs_update, self._current_i)
    return self._current_i
end

--- @brief
function ow.SpriteBatch:set(i, x, y, w, h, tx, ty, tw, th, flip_horizontally, flip_vertically, angle)
    meta.assert_number(i, x, y, w, h, tx, ty, tw, h)
    if flip_horizontally == nil then flip_horizontally = false end
    if flip_vertically == nil then flip_vertically = false end
    if angle == nil then angle = 0 end
    
    if i > self._current_i then
        rt.error("In ow.SpriteBatch.set: index `" .. i .. "` is out of bounds for a batch with `" .. self._current_i .. "` sprites")
        return
    end

    self._data[i] = self._params_to_data(
        x, y, w, h,
        tx, ty, tw, th,
        flip_horizontally, flip_vertically,
        angle
    )

    self._needs_update = true
    self._first_index_that_needs_update = math.min(self._first_index_that_needs_update, i)
    self._last_index_that_needs_update = math.max(self._last_index_that_needs_update, i)
end

--- @brief
function ow.SpriteBatch:_upload()
    if self._buffer == nil then
        self._buffer_format = self._draw_shader:get_buffer_format("SpriteBuffer")
        self._buffer = rt.GraphicsBuffer(self._buffer_format, self._current_i)
    end

    if self._first_index_that_needs_update == POSITIVE_INFINITY or self._last_index_that_needs_update == NEGATIVE_INFINITY then return end
    self._buffer:replace_data(self._data,
        self._first_index_that_needs_update, -- data offset
        self._first_index_that_needs_update, -- buffer offset
        self._last_index_that_needs_update - self._first_index_that_needs_update + 1 -- count
    )
    self._draw_shader:send("SpriteBuffer", self._buffer)
    self._mesh:set_texture(self._texture)
    self._first_index_that_needs_update = POSITIVE_INFINITY
    self._last_index_that_needs_update = NEGATIVE_INFINITY
end

--- @brief
function ow.SpriteBatch:draw()
    if self._needs_update then
        self:_upload()
        self._needs_update = false
    end

    self._draw_shader:bind()
    self._mesh:draw_instanced(self._current_i)
    self._draw_shader:unbind()
end