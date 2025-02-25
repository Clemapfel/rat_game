rt.settings.battle.animations.swap = {
    duration = 4,
    n_swaps = 6
}

--- @class bt.Animation.SWAP
bt.Animation.SWAP = meta.new_type("SWAP", rt.Animation, function(scene, entity_a, entity_b, message)
    meta.assert_isa(entity_a, bt.Entity)
    meta.assert_isa(entity_b, bt.Entity)
    if message ~= nil then meta.assert_string(message) end

    local duration = rt.settings.battle.animations.swap.duration
    return meta.new(bt.Animation.SWAP, {
        _scene = scene,
        _entity_a = entity_a,
        _entity_b = entity_b,
        _target_a = nil, -- bt.EntitySprite
        _target_b = nil, -- "

        _a_x = 0,
        _a_y = 0,
        _a_scale = 1,

        _b_x = 0,
        _b_y = 0,
        _b_scale = 1,

        _center_line_y = 0,

        _draw_order = function() end,
        _path_animation = rt.TimedAnimation(duration, 0, 1, rt.InterpolationFunctions.EXPONENTIAL_ACCELERATION),

        _a_path = nil, -- rt.Path
        _b_path = nil, -- rt.Path

        _message = message,
        _message_done = false,
        _message_id = nil
    })
end)

--- @override
function rt.Animation.SWAP:start()
    local sprite_a, sprite_b = self._scene:get_sprite(self._entity_a), self._scene:get_sprite(self._entity_b)
    local a_x, _ = sprite_a:get_position()
    local b_x, _ = sprite_b:get_position()

    local a, b
    if a_x < b_x then
        a, b = sprite_a, sprite_b
    else
        a, b = sprite_b, sprite_a
    end

    self._target_a = sprite_a
    self._target_b = sprite_b

    local target_a_x, target_a_y = self._target_a:get_position()
    local target_b_x, target_b_y = self._target_b:get_position()

    local n_vertices = 16
    local step = 2 * math.pi / n_vertices / 2

    self._center_line_y = 0
    local x_radius = 0.5 * math.abs(target_b_x - target_a_x)
    local y_radius = 1 * rt.settings.margin_unit

    local a_vertices = {}
    local b_vertices = {}

    local n_swaps = rt.settings.battle.animations.swap.n_swaps
    for i = 1, n_swaps do
        for angle = 0, 2 * math.pi, step do
            table.insert(a_vertices, x_radius + math.cos(angle - math.pi) * x_radius)
            table.insert(a_vertices, 0 + math.sin(angle - math.pi) * y_radius)

            table.insert(b_vertices, -x_radius + math.cos(angle) * x_radius)
            table.insert(b_vertices, 0 + math.sin(angle) * y_radius)
        end
    end

    self._a_path = rt.Path(a_vertices)
    self._b_path = rt.Path(b_vertices)

    self._target_a:set_is_visible(false)
    self._target_b:set_is_visible(false)

    self._message_id = self._scene:send_message(self._message, function()
        self._message_done = true
    end)
end

--- @override
function bt.Animation.SWAP:finish()
    self._target_a:set_is_visible(true)
    self._target_b:set_is_visible(true)
    self._scene:skip_message(self._message_id)
end

do
    local _a_before_b_draw = function(self)
        love.graphics.push()
        love.graphics.translate(self._a_x, self._a_y)
        self._target_a:draw_snapshot()
        love.graphics.pop()

        love.graphics.push()
        love.graphics.translate(self._b_x, self._b_y)
        self._target_b:draw_snapshot()
        love.graphics.pop()
    end

    local _b_before_a_draw = function(self)
        love.graphics.push()
        love.graphics.translate(self._b_x, self._b_y)
        self._target_b:draw_snapshot()
        love.graphics.pop()

        love.graphics.push()
        love.graphics.translate(self._a_x, self._a_y)
        self._target_a:draw_snapshot()
        love.graphics.pop()
    end

    --- @override
    function bt.Animation.SWAP:update(delta)
        self._path_animation:update(delta)

        local n_swaps = rt.settings.battle.animations.swap.n_swaps
        local value =self._path_animation:get_value()

        self._a_x, self._a_y = self._a_path:at(value)
        self._b_x, self._b_y = self._b_path:at(value)

        if self._a_y <= 0 then
            self.draw = _a_before_b_draw
        else
            self.draw = _b_before_a_draw
        end

        return self._path_animation:get_is_done() and self._message_done
    end

    bt.Animation.SWAP.draw = _a_before_b_draw
end