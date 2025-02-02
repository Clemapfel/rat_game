mn.SpriteMorph = meta.new_type("SpriteMorph", rt.Updatable, rt.Widget, function(sprite_texture)
    meta.assert_isa(sprite_texture, rt.Texture)
    return meta.new(mn.SpriteMorph, {
        _sprite_texture = sprite_texture,
        _elapsed = 0,
        _duration = 2,
        _direction = 1,
        _draw_from_or_to = true,
        _scale = 5,
        _is_started = false,
        _should_emit_signal_done = false,
    })
end)
meta.add_signal(mn.SpriteMorph, "done")

function mn.SpriteMorph:realize()
    if self:already_realized() then return end

    local texture_w, texture_h = self._sprite_texture:get_size()
    local padding = rt.settings.label.outline_offset_padding
    texture_w = texture_w + 2 * padding
    texture_h = texture_h + 2 * padding

    self._from_texture = rt.RenderTexture(texture_w, texture_h, 4, rt.TextureFormat.RGBA8, true)
    self._to_texture = rt.RenderTexture(texture_w, texture_h, 4, rt.TextureFormat.RGBA8, true)
    self._texture_w, self._texture_h = texture_w, texture_h
    
    do
        local text = rt.Label("?", rt.Font(texture_h, "assets/fonts/DejaVuSans/DejaVuSans-Bold.ttf"))
        text:realize()
        text:fit_into(0, 0)
        local text_w, text_h = text:measure()

        love.graphics.push()
        love.graphics.origin()
        
        self._from_texture:bind()
        text:draw(0.5 * texture_w - 0.5 * text_w, 0.5 * texture_h - 0.5 * text_h)
        self._from_texture:unbind()

        self._to_texture:bind()
        self._sprite_texture:draw(padding, padding)
        self._to_texture:unbind()

        love.graphics.pop()
    end

    self._compute_paths_shader = rt.ComputeShader("menu/sprite_morph_compute_paths.glsl")
    
    local paths_buffer_format = self._compute_paths_shader:get_buffer_format("paths_buffer")
    local buffer_n = texture_w * texture_h * 4
    self._from_paths_buffer = rt.GraphicsBuffer(paths_buffer_format, buffer_n)
    self._to_paths_buffer = rt.GraphicsBuffer(paths_buffer_format, buffer_n)

    local circle_factor = 0.5
    
    self._compute_paths_shader:send("image_center", {0.5 * texture_w, 0.5 * texture_h})
    self._compute_paths_shader:send("circle_radius", math.min(circle_factor * texture_w, circle_factor * texture_h) / 2)
    
    self._compute_paths_shader:send("paths_buffer", self._from_paths_buffer)
    self._compute_paths_shader:send("image", self._from_texture)
    self._compute_paths_shader:dispatch(math.ceil(texture_w / 16), math.ceil(texture_h / 16))
    self._from_paths_buffer:start_readback()
    self._from_paths = {}
    self._from_paths_ready = false
    self._n_from_paths = 0

    self._compute_paths_shader:send("paths_buffer", self._to_paths_buffer)
    self._compute_paths_shader:send("image", self._to_texture)
    self._compute_paths_shader:dispatch(math.ceil(texture_w / 16), math.ceil(texture_h / 16))
    self._to_paths_buffer:start_readback()
    self._to_paths = {}
    self._to_paths_ready = false
    self._n_to_paths = 0
end

function mn.SpriteMorph:size_allocate(x, y, width, height)
    self._bounds = rt.AABB(x, y, width, height)
end

function mn.SpriteMorph:update(delta)
    local before = love.timer.getTime()
    local scale_x = function(x)  
        return x * self._scale
    end
    
    local scale_y = function(y)  
        return y * self._scale
    end
    
    if self._from_paths_buffer:get_is_readback_ready() and self._from_paths_ready == false then
        local n_paths = 0
        for i = 1, self._from_paths_buffer:get_n_elements() do
            if self._from_paths_buffer:at(i, 1) > 0 then -- is_valid
                local element = self._from_paths_buffer:at(i)
                local path = {
                    a_from_x = scale_x(element[2]),
                    a_from_y = scale_y(element[3]),
                    b_from_x = scale_x(element[4]),
                    b_from_y = scale_y(element[5]),
                    a_to_x = scale_x(element[6]),
                    a_to_y = scale_y(element[7]),
                    b_to_x = scale_x(element[8]),
                    b_to_y = scale_y(element[9])
                }

                path.a_current_x = path.a_from_x
                path.a_current_y = path.a_from_y
                path.b_current_x = path.b_from_x
                path.b_current_y = path.b_from_y

                table.insert(self._from_paths, path)
                n_paths = n_paths + 1
            end
        end

        self._n_from_paths = n_paths
        self._from_paths_ready = true
    end

    if self._to_paths_buffer:get_is_readback_ready() and self._to_paths_ready == false then
        local n_paths = 0
        for i = 1, self._to_paths_buffer:get_n_elements() do
            if self._to_paths_buffer:at(i, 1) > 0 then -- is_valid
                local element = self._to_paths_buffer:at(i)
                local path = {
                    a_to_x = scale_x(element[2]),
                    a_to_y = scale_y(element[3]),
                    b_to_x = scale_x(element[4]),
                    b_to_y = scale_y(element[5]),
                    a_from_x = scale_x(element[6]),
                    a_from_y = scale_y(element[7]),
                    b_from_x = scale_x(element[8]),
                    b_from_y = scale_y(element[9])
                }

                path.a_current_x = path.a_from_x
                path.a_current_y = path.a_from_y
                path.b_current_x = path.b_from_x
                path.b_current_y = path.b_from_y

                table.insert(self._to_paths, path)
                n_paths = n_paths + 1
            end
        end

        self._n_to_paths = n_paths
        self._to_paths_ready = true
    end

    if self._is_started and self._from_paths_ready and self._to_paths_ready then
        self._elapsed = clamp(self._elapsed + self._direction * delta, 0, self._duration)
        local fraction = rt.InterpolationFunctions.EXPONENTIAL_ACCELERATION(self._elapsed / self._duration)

        local paths, n_paths, t = nil
        if fraction < 0.5 then
            self._draw_from_or_to = true
            t = fraction / 0.5
            paths = self._from_paths
            n_paths = self._n_from_paths
        else
            self._draw_from_or_to = false
            t = (fraction - 0.5) / 0.5
            paths = self._to_paths
            n_paths = self._n_to_paths
        end

        for i = 1, n_paths do
            local path = paths[i]
            path.a_current_x = mix(path.a_from_x, path.a_to_x, t)
            path.a_current_y = mix(path.a_from_y, path.a_to_y, t)
            path.b_current_x = mix(path.b_from_x, path.b_to_x, t)
            path.b_current_y = mix(path.b_from_y, path.b_to_y, t)
        end

        if self._should_emit_signal_done and ((self._direction == 1 and self._elapsed >= self._duration) or (self._direction == -1 and self._elapsed <= 0)) then
            self:signal_emit("done")
            self._should_emit_signal_done = false
        end
    end
end

function mn.SpriteMorph:draw()
    love.graphics.push()

    love.graphics.translate(
        0.5 * self._bounds.width - 0.5 * self._texture_w * self._scale,
        0.5 * self._bounds.height - 0.5 * self._texture_h * self._scale
    )

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(self._scale * 2)
    if self._from_paths_ready and self._draw_from_or_to == true then
        for i = 1, self._n_from_paths do
            local path = self._from_paths[i]
            love.graphics.line(path.a_current_x, path.a_current_y, path.b_current_x, path.b_current_y)
        end
    elseif self._to_paths_ready and self._draw_from_or_to == false then
        for i = 1, self._n_to_paths do
            local path = self._to_paths[i]
            love.graphics.line(path.a_current_x, path.a_current_y, path.b_current_x, path.b_current_y)
        end
    end
    love.graphics.pop()
end

function mn.SpriteMorph:start()
    self._is_started = true
    self._should_emit_signal_done = true
    self._elapsed = 0
end