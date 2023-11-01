--- @class rt.AnimatedSprite
--- @param spritesheet rt.Spritesheet
--- @param animation_id String (or nil)
--- @param should_loop Boolean (or nil)
rt.AnimatedSprite = meta.new_type("AnimatedSprite", function(spritesheet, animation_id, should_loop)

    meta.assert_isa(spritesheet, rt.Spritesheet)
    if meta.is_nil(should_loop) then should_loop = true end

    local out = meta.new(rt.AnimatedSprite, {
        _spritesheet = spritesheet,
        _animation_id = animation_id,
        _shape = rt.VertexRectangle(0, 0, 0, 0),
        _current_frame = 1,
        _fame_width = -1,
        _frame_height = -1,
        _should_loop = should_loop,
        _n_frames = spritesheet:get_n_frames(animation_id)
    }, rt.Drawable, rt.Animation, rt.Widget, rt.Sprite)

    out:set_animation(animation_id, should_loop)
    out:set_minimum_size(out._frame_width, out._frame_height)
    out._shape:set_texture(out._spritesheet)
    return out
end)

--- @overload rt.Drawable.draw
rt.AnimatedSprite.draw = rt.Sprite.draw

--- @overload rt.Widget.size_allocate
rt.AnimatedSprite.size_allocate = rt.Sprite.size_allocate

--- @overload rt.Widget.measure
rt.AnimatedSprite.measure = rt.Sprite.measure

--- @overload rt.Animation.update
function update(delta)

end
