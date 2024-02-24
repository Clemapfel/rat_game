--- @class ow.OveworldSprite
ow.OverworldSprite = meta.new_type("OverworldSprite", ow.OverworldEntity, rt.Animation, function(spritesheet, animation_id)
    return meta.new(ow.OverworldSprite, {
        _spritesheet = spritesheet,
        _animation_id = animation_id,
        _sprite = {} -- rt.Sprite
    })
end)

--- @override
function ow.OverworldSprite:set_position(x, y)
    ow.OverworldEntity.set_position(self, x, y)
    if self._is_realized then
        local w, h = self._sprite:get_size()
        self._sprite:fit_into(x + w / 2, y + h / 2, w, h)
    end
end

--- @override
function ow.OverworldSprite:realize()
    if not self._is_realized then
        self._sprite = rt.Sprite(self._spritesheet, self._animation_id)
        self._sprite:realize()
        local x, y = self:get_position()
        self._sprite:fit_into(x, y, 0, 0)
    end
    self._is_realized = true
end

--- @override
function ow.OverworldSprite:draw()
    if self._is_realized then
        self._sprite:draw()
    end
end

--- @override
function ow.OverworldSprite:update(delta)
    if self._is_realized then
        self._sprite:update(delta)
    end
end

