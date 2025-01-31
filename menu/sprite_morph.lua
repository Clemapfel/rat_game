--[[
marchin squares to get mesh for both sprites
for each vertex in target sprite, get vertex closest in angle to target sprite
]]--

mn.SpriteMorph = meta.new_type("SpriteMorph", rt.Updatable, rt.Widget, function(sprite_texture)
    meta.assert_isa(sprite_texture, rt.Texture)
    return meta.new(mn.SpriteMorph, {
        _sprite_texture = sprite_texture
    })
end)

local _marching_squares_shader = nil

function mn.SpriteMorph:realize()
    if self:already_realized() then return end

    -- init question mark texture
    local destination_w, destination_h = self._sprite_texture:get_size()
    local padding = rt.settings.label.outline_offset_padding
    destination_w = destination_w + 2 * padding
    destination_h = destination_h + 2 * padding

    self._origin = rt.RenderTexture(destination_w, destination_h, 4, rt.TextureFormat.RGBA8, true)
    self._destination = rt.RenderTexture(destination_w, destination_h, 4, rt.TextureFormat.RGBA8, true)

    do
        local text = rt.Label("?", rt.Font(destination_h, "assets/fonts/DejaVuSans/DejaVuSans-Bold.ttf"))
        text:realize()
        text:fit_into(0, 0)
        local text_w, text_h = text:measure()

        love.graphics.push()
        love.graphics.origin()

        self._origin:bind()
        text:draw(0.5 * destination_w - 0.5 * text_w, 0.5 * destination_h - 0.5 * text_h)
        self._origin:unbind()

        self._destination:bind()
        self._sprite_texture:draw(padding, padding)
        self._destination:unbind()

        love.graphics.pop()
    end

    if _marching_squares_shader == nil then _marching_squares_shader = rt.ComputeShader("menu/sprite_morph_marching_squares.glsl") end

    local vertex_buffer_format = _marching_squares_shader:get_buffer_format("vertex_buffer")

    local origin_w, origin_h = self._origin:get_size()
    local origin_buffer_size = (origin_w - 1) * (origin_h - 1)
    local origin_vertex_buffer = rt.GraphicsBuffer(vertex_buffer_format, origin_buffer_size)
    self._origin_dispatch_size_x, self._origin_dispatch_size_y = math.ceil(origin_w / 16), math.ceil(origin_h / 16)
    self._origin_vertex_buffer = origin_vertex_buffer
    self._origin_vertex_buffer_size = origin_buffer_size

    do
        local data = {}
        for i = 1, origin_buffer_size do
            table.insert(data, {-1, -1, -1, -1})
        end
        origin_vertex_buffer:replace_data(data)

        _marching_squares_shader:send("input_texture", self._origin)
        _marching_squares_shader:send("vertex_buffer", self._origin_vertex_buffer)
        _marching_squares_shader:dispatch(self._origin_dispatch_size_x, self._origin_dispatch_size_y)
        self._origin_vertex_readback = origin_vertex_buffer:readback_data_async()
        self._origin_vertex_data = nil
    end

    local destination_buffer_size = (destination_w - 1) * (destination_h - 1)
    local destination_vertex_buffer = rt.GraphicsBuffer(vertex_buffer_format, destination_buffer_size)
    self._destination_dispatch_size_x, self._destination_dispatch_size_y = math.ceil(destination_w / 16), math.ceil(destination_h / 16)
    self._destination_vertex_buffer = destination_vertex_buffer
    self._destination_vertex_buffer_size = destination_buffer_size

    do
        local data = {}
        for i = 1, destination_buffer_size do
            table.insert(data, {-1, -1, -1, -1})
        end
        destination_vertex_buffer:replace_data(data)

        _marching_squares_shader:send("input_texture", self._destination)
        _marching_squares_shader:send("vertex_buffer", self._destination_vertex_buffer)
        _marching_squares_shader:dispatch(self._destination_dispatch_size_x, self._destination_dispatch_size_y)
        self._destination_vertex_readback = destination_vertex_buffer:readback_data_async()
        self._destination_vertex_data = nil
    end
end

function mn.SpriteMorph:size_allocate(x, y, width, height)
    self._bounds = rt.AABB(x, y, width, height)
end

local mesh_format = {
    { location = 0, name = "VertexPosition", format = "floatvec2" },
}

function mn.SpriteMorph:update(_)
    local angle = function(a, center_x, center_y)
        return (math.atan(a[2] - center_y, a[1] - center_y) + math.pi) / (2 * math.pi)
    end

    -- Function to link line segments
    function link_segments(segments)
        local linked_lines = {}
        local used_segments = {}

        -- Helper function to find a segment starting with a given point
        local function find_segment(start_point)
            for i, segment in ipairs(segments) do
                if not used_segments[i] then
                    if segment[1] == start_point[1] and segment[2] == start_point[2] then
                        return i, segment
                    elseif segment[3] == start_point[1] and segment[4] == start_point[2] then
                        -- Reverse the segment if it matches in reverse
                        return i, {segment[3], segment[4], segment[1], segment[2]}
                    end
                end
            end
            return nil
        end

        -- Iterate over each segment
        for i, segment in ipairs(segments) do
            if not used_segments[i] then
                local line = {segment}
                used_segments[i] = true
                local current_end = {segment[3], segment[4]}

                -- Try to extend the line by finding connecting segments
                while true do
                    local next_index, next_segment = find_segment(current_end)
                    if next_index then
                        table.insert(line, next_segment)
                        used_segments[next_index] = true
                        current_end = {next_segment[3], next_segment[4]}
                    else
                        break
                    end
                end

                table.insert(linked_lines, line)
            end
        end

        return linked_lines
    end


    if self._origin_vertex_readback:is_ready() and self._origin_vertex_data == nil then
        self._origin_vertex_data = {}
        local data = self._origin_vertex_readback:get()
        local centroid_x, centroid_y, n = 0, 0, 0
        for i = 1, self._origin_vertex_buffer_size * 4, 4 do
            local x1 = data:getFloat((i - 1 + 0) * 4)
            local y1 = data:getFloat((i - 1 + 1) * 4)
            local x2 = data:getFloat((i - 1 + 2) * 4)
            local y2 = data:getFloat((i - 1 + 3) * 4)

            if (x1 > -1 and y1 > -1) or (x2 > -1 and y2 > -1) then
                centroid_x = centroid_x + x1
                centroid_y = centroid_y + y1
                centroid_x = centroid_x + x2
                centroid_y = centroid_y + y2
                n = n + 1
                table.insert(self._origin_vertex_data, {x1, y1, x2, y1})
            end
        end

        centroid_x = centroid_x / n
        centroid_y = centroid_y / n

        self._origin_n = n

        self._origin_line = link_segments(self._origin_vertex_data)
        self._origin_ready = true
    end
end

function mn.SpriteMorph:draw()
    love.graphics.clear() -- TODO

    love.graphics.push()
    love.graphics.translate(self._bounds.x, self._bounds.y)

    if self._origin_ready then
        for i = 1, sizeof(self._origin_line) do
            love.graphics.line(self._origin_line[i])
        end
    end

    love.graphics.translate(select(1, self._destination:get_size()), 0)

    if self._destination_ready then
        love.graphics.setColor(1, 0, 1, 1)
        love.graphics.line(self._destination_line)
        love.graphics.setColor(0, 1, 0, 1)
    end

    love.graphics.pop()
end