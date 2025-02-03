rt.settings.contour =  {
    threshold = 0.05,
    padding = 6
}

rt.Contour = meta.new_type("Contour", function()
    return meta.new(rt.Contour, {
        _texture = nil, -- rt.RenderTexture
        _buffer = nil,  -- rt.GraphicsBuffer
        _readback_done = false,
        _segments = {},
        _n_segments = 0,
        _scale = 1,
        _line_width = 3
    })
end)

local _compute_segments_shader = nil
local _buffer_format = nil

--- @brief
function rt.Contour:create_from(drawable, width, height)
    local texture_w, texture_h = width, height
    local padding = rt.settings.contour.padding
    texture_w = texture_w + 2 * padding
    texture_h = texture_h + 2 * padding

    if _compute_segments_shader == nil then
        _compute_segments_shader = rt.ComputeShader("common/contour.glsl")
        _buffer_format = _compute_segments_shader:get_buffer_format("paths_buffer")
    end
    
    self._texture = rt.RenderTexture(texture_w, texture_h, 4, rt.TextureFormat.RGBA8, true)
    self._texture:bind()
    drawable:draw(padding, padding)
    self._texture:unbind()

    local buffer_n = texture_w * texture_h * 4
    local buffer = rt.GraphicsBuffer(_buffer_format, buffer_n)
    self._buffer = buffer
    self._centroid_x = texture_w / 2
    self._centroid_y = texture_h / 2

    _compute_segments_shader:send("paths_buffer", self._buffer)
    _compute_segments_shader:send("image", self._texture)
    _compute_segments_shader:dispatch(math.ceil(texture_w / 16), math.ceil(texture_h / 16))
    self._buffer:start_readback()
    self._readback_done = false

    self._segments = {}
    self._n_segments = 0

    self:_check_readback() -- could be done already
end

--- @brief
function rt.Contour:set_scale(scale)
    self._scale = scale
end

--- @brief
function rt.Contour:set_line_width(line_width)
    self._line_width = line_width
end

--- @brief
function rt.Contour:_check_readback()
    if self._readback_done == true then return end
    if not self._buffer:get_is_readback_ready() then return end

    self._segments = {}
    for i = 1, self._buffer:get_n_elements() do
        if self._buffer:at(i, 1) > 0 then -- is_valid
            table.insert(self._segments, {
                self._buffer:at(i, 2),
                self._buffer:at(i, 3),
                self._buffer:at(i, 4),
                self._buffer:at(i, 5)
            })

            self._n_segments = self._n_segments + 1
        end
    end

    self._readback_done = true
end

--- @brief
function rt.Contour:draw()
    if self._readback_done == false then
        self:_check_readback()
        if self._readback_done == false then return end
    end

    love.graphics.setColor(1, 1, 1, 1)
    local scale, centroid_x, centroid_y, line_width = self._scale, self._centroid_x, self._centroid_y, self._line_width
    love.graphics.setLineWidth(line_width)
    line_width = 0.5 * line_width
    for i = 1, self._n_segments do
        local a_x, a_y, b_x, b_y = table.unpack(self._segments[i])
        love.graphics.line(
            a_x * scale - centroid_x - line_width,
            a_y * scale - centroid_y - line_width,
            b_x * scale - centroid_x - line_width,
            b_y * scale - centroid_y - line_width
        )
    end
end