--- @class rt.Sprite
--- @param spritesheet rt.Spritesheet
--- @param animation_id String
rt.Sprite = meta.new_type("Sprite", function(spritesheet, animation_id)
    if meta.is_nil(animation_id) then
        animation_id = spritesheet.name
    end
    spritesheet:_assert_has_animation("Sprite:", animation_id)

    local w, h = spritesheet:get_frame_size(animation_id)
    local out = meta.new(rt.Sprite, {
        _spritesheet = spritesheet,
        _animation_id = animation_id,
        _shape = rt.VertexRectangle(0, 0, 0, 0),
        _current_frame = 1,
        _frame_width = w,
        _frame_height = h,
        _elapsed = 0,
        _should_loop = false
    }, rt.Drawable, rt.Widget, rt.Animation)

    out:set_minimum_size(w, h)
    out._shape:set_texture(out._spritesheet)
    return out
end)

--- @overload rt.Drawable.draw
function rt.Sprite:draw()
    if self:get_is_visible() then
        self._shape:draw()
    end
end

--- @overload rt.Widget.size_allocate
function rt.Sprite:size_allocate(x, y, width, height)
    self._shape:resize(x, y, width, height)
    self._shape:set_texture_rectangle(self._spritesheet:get_frame(self._animation_id, self._current_frame))
end

--- @overload rt.Animation.update
function rt.Sprite:update(delta)
    self._elapsed = self._elapsed + delta
    local frame_duration = 1 / self._spritesheet:get_fps()
    local frame_i = math.floor(self._elapsed / frame_duration)

    if self:get_should_loop() then
        self:set_frame((frame_i % self:get_n_frames()) + 1)
    else
        self:set_frame(clamp(frame_i, 1, self:get_n_frames()))
    end
end

--- @brief set which frame is currently displayed
--- @param i Number 1-based
function rt.Sprite:set_frame(i)
    local n_frames = self._spritesheet:get_n_frames(self._animation_id)
    if i < 1 or i > n_frames then
        rt.error("In Sprite:set_frame: frame index `" .. tostring(i) .. "` is out of range for animation `" .. self._animation_id .. "` of spritesheet `" .. self._spritesheet.name .. "` which has `" .. tostring(n_frames) .. "` frames")
    end

    self._current_frame = i
    self._shape:set_texture_rectangle(self._spritesheet:get_frame(self._animation_id, i))
end

--- @brief get which frame is currently displayed
--- @return Number
function rt.Sprite:get_frame()
    return self._current_frame
end

--- @brief get number of frames
--- @return Number
function rt.Sprite:get_n_frames()
    return self._spritesheet:get_n_frames(self._animation_id)
end

--- @brief set which animation is used, this resets the current frame to 1
--- @param id String
function rt.Sprite:set_animation(id)
    self._spritesheet:_assert_has_animation("Sprite:set_animation", id)
    local w, h = self._spritesheet:get_frame_size(id)

    self._animation_id = id
    self._current_frame = 1
    self._frame_width = w
    self._frame_height = h

    self:set_minimum_size(w, h)
    self:set_frame(1)
end

--- @brief get frame resolution
--- @return (Number, Number)
function rt.Sprite:get_resolution()
    return self._frame_width, self._frame_height
end

--- @brief set whether sprite should loop when animated
--- @param b Boolean
function rt.Sprite:set_should_loop(b)
    self._should_loop = b
end

--- @brief get whether sprite loops when animated
--- @return Boolean
function rt.Sprite:get_should_loop()
    return self._should_loop
end

--- @brief set color, multiplied with texture
--- @param color rt.RGBA (or rt.HSVA)
function rt.Sprite:set_color(color)
    self._shape:set_color(color)
end

--- @brief test sprite
function rt.test.sprite()
    error("TODO")
    --[[
    spritesheet = rt.Spritesheet("assets/sprites", "test_animation")
    sprite = rt.Sprite(spritesheet)
    sprite:set_should_loop(true)
    sprite:set_is_animated(true)
    sprite:set_expand(false)
    ]]
end
