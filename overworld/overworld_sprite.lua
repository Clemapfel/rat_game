--- @class ow.OveworldSprite
ow.OverworldSprite = meta.new_type("OverworldSprite", ow.OverworldEntity, rt.Animation,
function(spritesheet, animation_id)
    local out = meta.new(ow.OverworldSprite, {
        _spritesheet = spritesheet,
        _animation_id = animation_id,
        _width = -1,    -- -1: use default size, else use override
        _height = -1,
        _shape = rt.VertexRectangle(0, 0, 1, 1),
        _current_frame = 1,
        _elapsed = 0,
        _should_loop = true
    })
    out:set_is_animated(true)
    return out
end)

--- @override
function ow.OverworldSprite:realize()
    if not self._is_realized then
        self._is_realized = true
        self._shape:set_texture(self._spritesheet)
        self:set_position(self:get_position())
        self:set_size(self._width, self._height)
        self:set_frame(self._current_frame)
    end
end

--- @override
function ow.OverworldSprite:set_position(x, y)
    ow.OverworldEntity.set_position(self, x, y)
    self:set_size(self._width, self._height) -- updates _shape vertices
end

--- @brief
function ow.OverworldSprite:set_size(width, height)
    width = which(width, -1)
    height = which(height, -1)
    self._width = width
    self._height = height

    if self._is_realized then
        local x, y = self:get_position()
        local res_x, res_y = self._spritesheet:get_frame_size(self._animation_id)
        local w = ternary(width == -1, res_x, width)
        local h = ternary(height == -1, res_y, height)
        self._shape:reformat(
            x, y,
            x + w, y,
            x + w, y + h,
            x, y + h
        )
    end
end

--- @brief
function ow.OverworldSprite:get_size()
    local res_x, res_y = self._spritesheet:get_frame_size(self._animation_id)
    return
        ternary(self._width == -1, res_x, self._width),
        ternary(self._height == -1, res_x, self._height)
end

--- @brief
function ow.OverworldSprite:set_should_loop(b)
    self._should_loop = b
end

--- @brief
function ow.OverworldSprite:get_should_loop()
    return self._should_loop
end

--- @brief
function ow.OverworldSprite:set_frame(i)
    self._current_frame = i % self:get_n_frames()
    if self._is_realized then
        local frame = self._spritesheet:get_frame(self._animation_id, self._current_frame, i)
        self._shape:set_texture_rectangle(frame)
    end
end

--- @brief
function ow.OverworldSprite:get_frame(i)
    return self._current_frame
end

--- @brief
function ow.OverworldSprite:get_n_frames()
    return self._spritesheet:get_n_frames(self._animation_id)
end

--- @override
function ow.OverworldSprite:draw()
    if self._is_realized then
        self._shape:draw()
    end
end

--- @override
function ow.OverworldSprite:update(delta)
    if self._is_realized then
        self._elapsed = self._elapsed + delta
        local frame_duration = 1 / self._spritesheet:get_fps()
        local frame_i = math.floor(self._elapsed / frame_duration)
        local n_frames = self._spritesheet:get_n_frames(self._animation_id)
        if self:get_should_loop() then
            self:set_frame((frame_i % n_frames) + 1)
        else
            self:set_frame(clamp(frame_i, 1, n_frames))
        end
    end
end

