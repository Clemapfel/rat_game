rt.settings.battle.animation.equip_applied = {
    move_duration = 1,
    fade_duration = 1,
    hold_duration = 0.5,
}

--- @class bt.Animation.EQUIP_APPLIED
bt.Animation.EQUIP_APPLIED = meta.class("EQUIP_APPLIED", rt.Animation)

function bt.Animation.EQUIP_APPLIED:instantiate(scene, equip, entity, message)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_isa(equip, bt.EquipConfig)
    meta.assert_isa(entity, bt.Entity)
    if message ~= nil then meta.assert_string(message) end
    local move_duration = rt.settings.battle.animation.equip_applied.move_duration
    local hold_duration = rt.settings.battle.animation.equip_applied.hold_duration
    local fade_duration = rt.settings.battle.animation.equip_applied.fade_duration
    return meta.new(bt.Animation.EQUIP_APPLIED, {
        _scene = scene,
        _equip = equip,
        _entity = entity,
        _target = nil,

        _sprite = nil, -- rt.Sprite
        _sprite_x = 0,
        _sprite_y = 0,
        _sprite_scale = 1,
        _sprite_opacity = 0,

        _fade_in_animation = rt.TimedAnimation(move_duration, 0, 1, rt.InterpolationFunctions.SINUSOID_EASE_IN),
        _position_animation = rt.TimedAnimation(move_duration, 0, 1, rt.InterpolationFunctions.SINUSOID_EASE_IN),
        _position_path = nil, -- rt.Path
        _hold_animation = rt.TimedAnimation(hold_duration, 1, 1, rt.InterpolationFunctions.CONSTANT),
        _opacity_animation = rt.TimedAnimation(fade_duration, 1, 0, rt.InterpolationFunctions.LINEAR),
        _scale_animation = rt.TimedAnimation(fade_duration, 1, 3, rt.InterpolationFunctions.LINEAR),

        _message = message,
        _message_done = false,
        _message_id = nil
    })
end

bt.Animation.EQUIP_APPLIED._equip_to_sprite = {}

--- @override
function bt.Animation.EQUIP_APPLIED:start()
    self._target = self._scene:get_sprite(self._entity)

    self._message_id = self._scene:send_message(self._message, function()
        self._message_done = true
    end)

    local sprite = bt.Animation.EQUIP_APPLIED._equip_to_sprite[self._equip]
    local sprite_w, sprite_h
    if sprite == nil then
        sprite = rt.Sprite(self._equip:get_sprite_id())
        sprite:realize()
        sprite_w, sprite_h = sprite:measure()
        sprite:fit_into(-0.5 * sprite_w, -0.5 * sprite_h)
        bt.Animation.EQUIP_APPLIED._equip_to_sprite[self._equip] = sprite
    else
        sprite_w, sprite_h = sprite:measure()
    end

    self._sprite = sprite

    local x, y = self._target:get_position()
    local w, h = self._target:measure()
    self._position_path = rt.Path(
        x + 0.5 * w, y + 0.5 * h + 0.25 * h,
        x + 0.5 * w, y + 0.5 * h
    )

    self:update(0)
end

--- @override
function bt.Animation.EQUIP_APPLIED:update(delta)
    self._fade_in_animation:update(delta)
    if self._position_animation:update(delta) then
        if self._hold_animation:update(delta) then
            self._scale_animation:update(delta)
            self._opacity_animation:update(delta)
        end
    end -- fade in, hold, then fade out

    self._sprite_x, self._sprite_y = self._position_path:at(self._position_animation:get_value())
    self._sprite_scale = self._scale_animation:get_value()

    if self._position_animation:get_is_done() then
        self._sprite_opacity = self._opacity_animation:get_value()
    else
        self._sprite_opacity = self._fade_in_animation:get_value()
    end

    return self._position_animation:get_is_done() and
        self._scale_animation:get_is_done() and
        self._opacity_animation:get_is_done() and
        self._message_done
end

--- @override
function bt.Animation.EQUIP_APPLIED:finish()
    self._scene:skip_message(self._message_id)
end

--- @override
function bt.Animation.EQUIP_APPLIED:draw()
    self._sprite:set_opacity(self._sprite_opacity)

    love.graphics.push()
    love.graphics.translate(self._sprite_x, self._sprite_y)
    love.graphics.scale(self._sprite_scale)
    self._sprite:draw()
    love.graphics.pop()
end