--- @class bt.EnemySprite
bt.EnemySprite = meta.new_type("EnemySprite", rt.Widget, rt.Animation, function(scene, entity)
    return meta.new(bt.EnemySprite, {
        _entity = entity,
        _scene = scene,
        _is_realized = false,

        _sprite = rt.Sprite(entity.sprite_id),
        _hp_bar = bt.HealthBar(entity),
        _show_hp_bar = true,

        _debug_bounds = {}, -- rt.Rectangle
        _debug_sprite = {}, -- rt.Rectangle

        _animations = {}, -- Table<Table<bt.Animation>>
    })
end)

--- @override
function bt.EnemySprite:realize()
    if self._is_realized then return end
    self._is_realized = true

    local sprite_w, sprite_h = self._sprite:get_resolution()
    self._sprite:set_minimum_size(sprite_w * 3, sprite_h * 3)
    self._sprite:realize()
    self._hp_bar:realize()

    self:reformat()
end

--- @override
function bt.EnemySprite:update(delta)
    self._sprite:update(delta)
    self._hp_bar:update(delta)

    do -- animation queue
        local current = self._animations[1]
        if current ~= nil then
            if current._is_started ~= true then
                current._is_started = true
                current:start()
            end

            local result = current:update(delta)
            if result == bt.AnimationResult.DISCONTINUE then
                current._is_finished = true
                current:finish()
                table.remove(self._animations, 1)
            elseif result == bt.AnimationResult.CONTINUE then
                -- noop
            else
                rt.error("In bt.EnemySprite:update: animation `" .. meta.typeof(current) .. "`s upate function does not return a value")
            end
        end
    end
end

--- @override
function bt.EnemySprite:size_allocate(x, y, width, height)
    self._sprite:fit_into(x, y, width, height)

    self._debug_bounds = rt.Rectangle(x, y, width, height)
    local sprite_x, sprite_y = self._sprite:get_position()
    local sprite_w, sprite_h = self._sprite:measure()

    self._debug_sprite = rt.Rectangle(sprite_x, sprite_y, sprite_w, sprite_h)

    local m = 0.5 * rt.settings.margin_unit
    self._hp_bar:fit_into(sprite_x, sprite_y + sprite_h + m, sprite_w, rt.settings.battle.health_bar.hp_font:get_size() + 2 * m)

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
        self._hp_bar:draw()
        if self._scene:get_debug_draw_enabled() then
            self._debug_bounds:draw()
            self._debug_sprite:draw()
        end

        for _, animation in pairs(self._animations) do
            if animation._is_started == true then
                animation:draw()
            end
        end
    end
end

--- @override
function bt.EnemySprite:set_is_visible(b)
    if self._is_realized then
        self._sprite:set_is_visible(b)
    end
end

--- @override
function bt.EnemySprite:get_is_visible()
    return self._sprite:get_is_visible()
end

--- @brief
function bt.EnemySprite:add_animation(animation)
    table.insert(self._animations, animation)
end