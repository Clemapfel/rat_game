bt.Background.OVERLAP_LINES = meta.new_type("OVERLAP_LINES", bt.Background, function()
    return meta.new(bt.Background.OVERLAP_LINES, {
        _shader = {},   -- rt.Shader
        _shape = {},    -- rt.VertexShape
        _canvas = {},   -- rt.RenderTexture
        _lines = {},    -- Table<rt.VertexLine>
        _elapsed = 0
    })
end)

--- @override
function bt.Background.OVERLAP_LINES:realize()
    if self._is_realized == true then return end
    self._is_realized = true
   
    self._shape = rt.VertexRectangle(0, 0, 1, 1)
    self._canvas = rt.RenderTexture()

    for i = 1, 10 do
        local to_insert = rt.VertexLine(20,
            rt.random.number(200, 600),
            rt.random.number(200, 600),
            rt.random.number(200, 600),
            rt.random.number(200, 600)
        )
        to_insert:set_color(rt.hsva_to_rgba(rt.HSVA(rt.random.number(0, 1), 1, 1, 1)))
        table.insert(self._lines, to_insert)
    end
end

--- @override
function bt.Background.OVERLAP_LINES:size_allocate(x, y, width, height)
    self._canvas = rt.RenderTexture(width, height, 8)
    self._shape:set_texture(self._canvas)

    self._shape:set_vertex_position(1, x, y)
    self._shape:set_vertex_position(2, x + width, y)
    self._shape:set_vertex_position(3, x + width, y + height)
    self._shape:set_vertex_position(4, x, y + height)
end

--- @override
function bt.Background.OVERLAP_LINES:update(delta)
    self._elapsed = self._elapsed + delta

    self._canvas:bind()
    -- do not clear
    self._canvas:unbind()
end

--- @override
function bt.Background.OVERLAP_LINES:draw()
    self._shape:draw()
end