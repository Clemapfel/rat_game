--- @class bt.EnemySprite
bt.EnemySprite = meta.new_type("EnemySprite", rt.Widget, rt.Animation, function(scene, entity)
    return meta.new(bt.EnemySprite, {
        _entity = entity,
        _scene = scene,
        _is_realized = false,

        _sprite = rt.Sprite(entity.sprite_id),

        _debug_bounds = {}, -- rt.Rectangle
        _debug_sprite = {}, -- rt.Rectangle
    })
end)

--- @override
function bt.EnemySprite:realize()
    if self._is_realized then return end
    self._is_realized = true

    local sprite_w, sprite_h = self._sprite:get_resolution()
    self._sprite:set_minimum_size(sprite_w * 3, sprite_h * 3)
    self._sprite:realize()

    self:reformat()
end

--- @override
function bt.EnemySprite:size_allocate(x, y, width, height)
    self._sprite:fit_into(x, y, width, height)

    self._debug_bounds = rt.Rectangle(x, y, width, height)
    local sprite_x, sprite_y = self._sprite:get_position()
    local sprite_w, sprite_h = self._sprite:measure()

    self._debug_sprite = rt.Rectangle(sprite_x, sprite_y, sprite_w, sprite_h)

    for debug in range(self._debug_bounds, self._debug_sprite) do
        debug:set_is_outline(true)
    end
end

--- @override
function bt.EnemySprite:measure()
    return self._sprite:measure()
end

--- @override
function bt.EnemySprite:draw()
    if self._is_realized then
        self._sprite:draw()
        if self._scene:get_debug_draw_enabled() then
            self._debug_bounds:draw()
            self._debug_sprite:draw()
        end
    end
end