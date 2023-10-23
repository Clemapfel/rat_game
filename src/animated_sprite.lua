rt.DEFAULT_ANIMATION_FPS = 12

--- @class rt.AnimatedSprite
rt.AnimatedSprite = meta.new_type("AnimatedSprite", function(spritesheet, animation_id, should_loop)

    local fps = rt.DEFAULT_ANIMATION_FPS
    local n_frames = spritesheet:get_n_frames(animation_id)
    if meta.is_nil(should_loop) then should_loop = true end

    local out = meta.new(rt.AnimatedSprite, {
        _spritesheet = spritesheet,
        _animation_id = animation_id,
        _shape = rt.VertexRectangle(0, 0, 0, 0),
        _current_frame = 1,
        _fame_width = -1,
        _frame_height = -1,

        _is_active = false,
        _should_loop = false,
        _fps = fps,
        _n_frames = n_frames,
        _clock = rt.AnimationTimer(n_frames / fps)
    }, rt.Drawable, rt.Widget, rt.Sprite)

    out:set_animation(animation_id, should_loop)
    out:set_minimum_size(out._frame_width, out._frame_height)
    out._shape:set_texture(out._spritesheet)

    out._clock:signal_connect("tick", function(self, value, data)
        data:set_frame(clamp(math.floor(data._n_frames * value), 1, data._n_frames))
    end, out)
    out._clock:set_should_loop(should_loop)

    return out
end)

rt.AnimatedSprite.draw = rt.Sprite.draw
rt.AnimatedSprite.size_allocate = rt.Sprite.size_allocate
rt.AnimatedSprite.measure = rt.Sprite.measure

--- @brief set currently displayed sub animation
--- @param animation_id String
--- @param should_loop Boolean (or nil)
function rt.AnimatedSprite:set_animation(animation_id, should_loop)
    meta.assert_isa(self, rt.AnimatedSprite)
    if meta.is_nil(should_loop) then should_loop = true end

    self._spritesheet:_assert_has_animation("AnimatedSprite:", animation_id)
    local w, h = self._spritesheet:get_frame_size(animation_id)

    self._animation_id = animation_id
    self._current_frame = 1
    self._n_frames = self._spritesheet:get_n_frames(animation_id)
    self._frame_width = w
    self._frame_height = h
    self._clock:reset()
end

--- @brief
function rt.AnimatedSprite:play()
    meta.assert_isa(self, rt.AnimatedSprite)
    self._is_active = true
    self._clock:play()
end