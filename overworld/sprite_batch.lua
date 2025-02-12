ow.SpriteBatch = meta.new_type("SpriteBatch", function(texture)
    meta.assert_isa(texture, rt.Texture)
    return meta.new(ow.SpriteBatch, {
        _texture = texture,
        _mesh = rt.VertexRectangle(0, 0, 1, 1),
        _draw_shader = rt.Shader("overworld/sprite_batch_draw.glsl"),
        _buffer = nil,
        _needs_upload = true,
        _data = {},
        _current_i = 0
    })
end)

--- @brief
--- @return
function ow.SpriteBatch:add(x, y, w, h, tx, ty, tw, th)
    meta.assert_number(x, y, w, h, tx, ty, tw, h)
    table.insert(self._data, {
        x + 0, y + 0,
        x + w, y + 0,
        x + w, y + h,
        x + 0, y + h,

        tx +  0, ty +  0,
        tx + tw, ty +  0,
        tx + tw, ty + th,
        tx +  0, ty + th
    })

    self._current_i = self._current_i + 1
    return self._current_i
end

--- @brief
function ow.SpriteBatch:set(i, x, y, w, h, tx, ty, tw, th)
    meta.assert_number(i, x, y, w, h, tx, ty, tw, h)
    if i > self._current_i then
        rt.error("In ow.SpriteBatch.set: index `" .. i .. "` is out of bounds for a batch with `" .. self._current_i .. "` sprites")
        return
    end

    self._data[i] = {
        x + 0, y + 0,
        x + w, y + 0,
        x + w, y + h,
        x + 0, y + h,

        tx +  0, ty +  0,
        tx + tw, ty +  0,
        tx + tw, ty + th,
        tx +  0, ty + th
    }
end

--- @brief
function ow.SpriteBatch:_upload()
    if self._buffer == nil then
        self._buffer_format = self._draw_shader:get_buffer_format("SpriteBuffer")
        self._buffer = rt.GraphicsBuffer(self._buffer_format, self._current_i)
    end

    self._buffer:replace_data(self._data)
    self._draw_shader:send("SpriteBuffer", self._buffer)
    self._mesh:set_texture(self._texture)
end

--- @brief
function ow.SpriteBatch:draw()
    if self._needs_upload then
        self:_upload()
        self._buffer:readback_now()
        dbg(self._buffer:at(1))
        self._needs_upload = false
    end

    self._draw_shader:bind()
    self._mesh:draw_instanced(self._current_i)
    self._draw_shader:unbind()
end