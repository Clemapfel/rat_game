rt.settings.overworld.sprite = {
    debug_color = rt.Palette.LIGHT_GREEN_2
}

--- @class ow.OveworldSprite
ow.OverworldSprite = meta.new_type("OverworldSprite", ow.OverworldEntity, rt.Animation,
function(scene, spritesheet, animation_id)
    local out = meta.new(ow.OverworldSprite, {
        _scene = scene,
        _spritesheet = spritesheet,
        _animation_id = animation_id,
        _width = 0, -- 0 -> use frame resolution
        _height = 0,
        _shape = rt.VertexRectangle(0, 0, 1, 1),
        _debug_shape = {}, -- rt.Rectangle
        _debug_shape_outline = {}, -- rt.Rectangle
        _current_frame = 1,
        _elapsed = 0,
        _should_loop = true,
        _frame_duration = 1 / spritesheet:get_fps(),
        _n_frames = spritesheet:get_n_frames(animation_id)
    })

    out:set_is_animated(true)
    return out
end)

--- @override
function ow.OverworldSprite:realize()
    if not self._is_realized then
        self._is_realized = true
        self._shape:set_texture(self._spritesheet)

        self._debug_shape = rt.Rectangle(0, 0, 1, 1)
        self._debug_shape_outline = rt.Rectangle(0, 0, 1, 1)
        self._debug_shape_outline:set_is_outline(true)

        local color = rt.settings.overworld.sprite.debug_color
        self._debug_shape:set_color(rt.RGBA(color.r, color.g, color.b, 0.5))
        self._debug_shape_outline:set_color(rt.RGBA(color.r, color.g, color.b, 0.9))

        self:set_position(self:get_position())
        self:set_size(self._width, self._height)
        self:set_frame(self._current_frame)
    end
end

--- @override
function ow.OverworldSprite:set_position(x, y)
    ow.OverworldEntity.set_position(self, x, y)

    if self._is_realized then
        self:set_size(self._width, self._height) -- updates _shape vertices
        self._debug_shape:set_top_left(x, y)
        self._debug_shape_outline:set_top_left(x, y)
    end
end

--- @brief
function ow.OverworldSprite:set_size(width, height)
    width = which(width, 0)
    height = which(height, 0)
    self._width = width
    self._height = height

    if self._is_realized then
        local x, y = self:get_position()
        local res_x, res_y = self._spritesheet:get_frame_size(self._animation_id)
        local w = ternary(width == 0, res_x, width)
        local h = ternary(height == 0, res_y, height)
        self._shape:reformat(
            x, y,
            x + w, y,
            x + w, y + h,
            x, y + h
        )
        self._debug_shape:set_size(w, h)
        self._debug_shape_outline:set_size(w, h)
    end
end

--- @brief
function ow.OverworldSprite:get_size()
    local res_x, res_y = self._spritesheet:get_frame_size(self._animation_id)
    return
        ternary(self._width == 0, res_x, self._width),
        ternary(self._height == 0, res_x, self._height)
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
    self._current_frame = i % self._n_frames
    if self._is_realized then
        local frame = self._spritesheet:get_frame(self._animation_id, self._current_frame, i)
        self._shape:reformat_texture_coordinates(
            frame.x, frame.y,
            frame.x + frame.width, frame.y,
            frame.x + frame.width, frame.y + frame.height,
            frame.x, frame.y + frame.height
        )
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
        if self._scene:get_debug_draw_enabled() then
            self._debug_shape:draw()
            self._debug_shape_outline:draw()
        end
        self._shape:draw()
    end
end

--- @override
function ow.OverworldSprite:update(delta)
    if self._is_realized then
        self._elapsed = self._elapsed + delta
        local frame_i = math.floor(self._elapsed / self._frame_duration)

        if self._should_loop then
            frame_i = (frame_i % self._n_frames) + 1
        else
            frame_i = clamp(frame_i, 1, self._n_frames)
        end

        if frame_i ~= self._current_frame then
            self:set_frame(frame_i)
        end
    end
end

