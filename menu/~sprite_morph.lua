--[[
marchin squares to get mesh for both sprites
for each vertex in target sprite, get vertex closest in angle to target sprite
]]--

mn.SpriteMorph = meta.new_type("SpriteMorph", rt.Updatable, rt.Widget, function(sprite_texture)
    meta.assert_isa(sprite_texture, rt.Texture)
    return meta.new(mn.SpriteMorph, {
        _sprite_texture = sprite_texture,
        _elapsed = 0,
        _duration = 2,
        _active = true,
        _direction = 1
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
    self._texture_w, self._texture_h = destination_w, destination_w
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

        local todo = rt.Label("X", rt.Font(destination_h, "assets/fonts/DejaVuSans/DejaVuSans-Bold.ttf"))
        todo:realize()
        todo:fit_into(0, 0)
        local todo_w, todo_h = todo:measure()

        self._destination:bind()
        todo:draw(0.5 * destination_w - 0.5 * todo_w, 0.5 * destination_h - 0.5 * todo_h)
        self._destination:unbind()

        --[[
        self._destination:bind()
        self._sprite_texture:draw(padding, padding)
        self._destination:unbind()
        ]]--

        love.graphics.pop()
    end

    if _marching_squares_shader == nil then _marching_squares_shader = rt.ComputeShader("menu/sprite_morph_get_segments.glsl") end

    local segments_buffer_format = _marching_squares_shader:get_buffer_format("segments_buffer")

    local origin_w, origin_h = self._origin:get_size()
    local origin_buffer_size = origin_w * origin_h * 4
    local origin_segments_buffer = rt.GraphicsBuffer(segments_buffer_format, origin_buffer_size)
    self._origin_dispatch_size_x, self._origin_dispatch_size_y = math.ceil(origin_w / 16), math.ceil(origin_h / 16)
    self._origin_segments_buffer = origin_segments_buffer
    self._origin_segments_buffer_size = origin_buffer_size

    _marching_squares_shader:send("input_texture", self._origin)
    _marching_squares_shader:send("segments_buffer", self._origin_segments_buffer)
    _marching_squares_shader:dispatch(self._origin_dispatch_size_x, self._origin_dispatch_size_y)
    self._origin_vertex_readback = origin_segments_buffer:readback_data_async()
    self._origin_segment_data = nil

    local destination_buffer_size = destination_w * destination_h * 4
    local destination_segments_buffer = rt.GraphicsBuffer(segments_buffer_format, destination_buffer_size)
    self._destination_dispatch_size_x, self._destination_dispatch_size_y = math.ceil(destination_w / 16), math.ceil(destination_h / 16)
    self._destination_segments_buffer = destination_segments_buffer
    self._destination_segments_buffer_size = destination_buffer_size

    _marching_squares_shader:send("input_texture", self._destination)
    _marching_squares_shader:send("segments_buffer", self._destination_segments_buffer)
    _marching_squares_shader:dispatch(self._destination_dispatch_size_x, self._destination_dispatch_size_y)
    self._destination_vertex_readback = destination_segments_buffer:readback_data_async()
    self._destination_segment_data = nil

    self._input = rt.InputController()
    self._input:signal_connect("pressed", function(_, which)
        if which == rt.InputButton.X then
        elseif which == rt.InputButton.Y then
            self._direction = self._direction * -1
        end
    end)
end

function mn.SpriteMorph:size_allocate(x, y, width, height)
    self._bounds = rt.AABB(x, y, width, height)
end

local mesh_format = {
    { location = 0, name = "VertexPosition", format = "floatvec2" },
}

function mn.SpriteMorph:update(delta)
    local angle = function(a, center_x, center_y)
        return (math.atan(a[2] - center_y, a[1] - center_y) + math.pi) / (2 * math.pi)
    end

    local scale = 4

    if self._origin_vertex_readback:is_ready() and self._origin_segment_data == nil then
        self._origin_segment_data = {}
        local data = self._origin_vertex_readback:get()
        local n = 0
        local centroid_x, centroid_y = 0, 0
        for i = 1, self._origin_segments_buffer_size * 4, 4 do
            local x1 = data:getFloat((i - 1 + 0) * 4) * scale
            local y1 = data:getFloat((i - 1 + 1) * 4) * scale
            local x2 = data:getFloat((i - 1 + 2) * 4) * scale
            local y2 = data:getFloat((i - 1 + 3) * 4) * scale

            if x1 > -1 and y1 > -1 and x2 > -1 and y2 > -1 then
                n = n + 1
                centroid_x = centroid_x + x1 + x2
                centroid_y = centroid_y + y1 + y2
                table.insert(self._origin_segment_data, {
                    start_x = x1,
                    start_y = y1,
                    end_x = x2,
                    end_y = y2,
                    center_x = (x1 + x2) / 2,
                    center_y = (x1 + x2) / 2,
                    angle = 0
                })
            end
        end

        centroid_x = centroid_x / n
        centroid_y = centroid_y / n

        for i = 1, n do
            local element = self._origin_segment_data[i]
            element.angle = math.atan(
                element.center_y - centroid_y,
                element.center_x - centroid_x
            )
        end

        self._origin_n = n
        self._origin_ready = true
    end

    if self._destination_vertex_readback:is_ready() and self._destination_segment_data == nil then
        self._destination_segment_data = {}
        local data = self._destination_vertex_readback:get()
        local n = 0
        local centroid_x, centroid_y = 0, 0
        for i = 1, self._destination_segments_buffer_size * 4, 4 do
            local x1 = data:getFloat((i - 1 + 0) * 4) * scale
            local y1 = data:getFloat((i - 1 + 1) * 4) * scale
            local x2 = data:getFloat((i - 1 + 2) * 4) * scale
            local y2 = data:getFloat((i - 1 + 3) * 4) * scale

            if x1 > -1 and y1 > -1 and x2 > -1 and y2 > -1 then
                n = n + 1
                centroid_x = centroid_x + x1 + x2
                centroid_y = centroid_y + y1 + y2
                table.insert(self._destination_segment_data, {
                    start_x = x1,
                    start_y = y1,
                    end_x = x2,
                    end_y = y2,
                    center_x = (x1 + x2) / 2,
                    center_y = (x1 + x2) / 2,
                    angle = 0
                })
            end
        end

        centroid_x = centroid_x / n
        centroid_y = centroid_y / n

        for i = 1, n do
            local element = self._destination_segment_data[i]
            element.angle = math.atan(
                element.center_y - centroid_y,
                element.center_x - centroid_x
            )
            assert(sizeof(element) > 0)

        end

        self._destination_n = n
        self._destination_ready = true
    end

    if self._origin_ready and self._destination_ready then
        if self._paths == nil then
            -- resize to same number of segments
            local origin_n = self._origin_n
            local destination_n = self._destination_n
            while (origin_n > destination_n) do
                local i = rt.random.integer(1, self._destination_n)
                local at = self._destination_segment_data[i]
                local copy = {}
                for k, v in pairs(at) do copy[k] = v end
                table.insert(self._destination_segment_data, copy)
                destination_n = destination_n + 1
            end
            self._destination_n = destination_n

            while (destination_n > origin_n) do
                local i = rt.random.integer(1, self._origin_n)
                local at = self._origin_segment_data[i]
                local copy = {}
                for k, v in pairs(at) do copy[k] = v end
                table.insert(self._origin_segment_data, copy)
                origin_n = origin_n + 1
            end
            self._origin_n = origin_n


            self._paths = {}
            self._to_draw = {}
            self._n_paths = origin_n
            local candidates = {}
            for i = 1, self._n_paths do
                candidates[self._origin_segment_data[i]] = true
            end

            function angle_distance(a, b)
                local diff = a.angle - b.angle
                return math.abs((diff + math.pi) % (2 * math.pi) - math.pi)
            end

            function space_distance(a, b)
                return math.sqrt((b.center_x - a.center_x)^2 + (b.center_y - a.center_y)^2)
            end

            for i = 1, self._n_paths do
                local to = self._destination_segment_data[i]

                -- find closest point in angle
                local min_angle_distance = POSITIVE_INFINITY
                local min_space_distance = POSITIVE_INFINITY
                local from = nil
                for other in keys(candidates) do
                    local angle_distance = angle_distance(to, other)
                    local space_distance = space_distance(to, other)

                    local distance = (angle_distance / (2 * math.pi)) + (space_distance / math.max(self._destination_w, self._destination_h))

                    local found = false
                    if angle_distance < min_angle_distance then
                       found = true
                    elseif angle_distance == min_angle_distance then
                        if space_distance <= min_space_distance then
                            found = true
                        end
                    end

                    if found then
                        min_angle_distance = angle_distance
                        min_space_distance = space_distance
                        from = other
                    end
                end

                candidates[from] = nil
                table.insert(self._paths, {
                    from = from,
                    to = to
                })

                table.insert(self._to_draw, {
                    from.start_x, from.start_y,
                    from.end_x, from.end_y
                })
            end
            self._paths_ready = true
        end
    end

    -- interpolate
    if self._paths_ready and self._active then
        self._elapsed = clamp(self._elapsed + self._direction * delta, 0, self._duration)
        local t = rt.InterpolationFunctions.SINUSOID_EASE_IN_OUT(math.min(self._elapsed / self._duration, 1))
        for i = 1, self._n_paths do
            local from = self._paths[i].from
            local to = self._paths[i].to

            local current = self._to_draw[i]
            current[1] = mix(from.start_x, to.start_x, t)
            current[2] = mix(from.start_y, to.start_y, t)
            current[3] = mix(from.end_x, to.end_x, t)
            current[4] = mix(from.end_y, to.end_y, t)
        end
    end
end

function mn.SpriteMorph:draw()
    love.graphics.clear() -- TODO

    love.graphics.push()
    love.graphics.translate(self._bounds.x, self._bounds.y)

    if self._paths_ready and self._active then
        love.graphics.setColor(1, 1, 1, 1)
        for i = 1, self._n_paths do
            love.graphics.line(self._to_draw[i])
        end
    end

    love.graphics.pop()
end