--- @class rt.AnimatedSprite
rt.AnimatedSprite = meta.new_type("AnimatedSprite", function(spritesheet, animation_id)
    return meta.new(rt.AnimatedSprite, {
        _sprite = rt.Sprite(spritesheet, animation_id),
        _timer = rt.AnimationTimer()
    })
end)