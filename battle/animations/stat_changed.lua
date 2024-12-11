rt.settings.battle.animation.stat_changed = {
    duration = 1
}

function bt.Animation.ATTACK_RAISED(scene, sprite)
    return bt.Animation.STAT_CHANGED(scene, sprite, bt.StatType.ATTACK, true)
end

function bt.Animation.ATTACK_LOWERED(scene, sprite)
    return bt.Animation.STAT_CHANGED(scene, sprite, bt.StatType.DEFENSE, false)
end

function bt.Animation.DEFENSE_RAISED(scene, sprite)
    return bt.Animation.STAT_CHANGED(scene, sprite, bt.StatType.DEFENSE, true)
end

function bt.Animation.DEFESE_LOWERED(scene, sprite)
    return bt.Animation.STAT_CHANGED(scene, sprite, bt.StatType.DEFENSE, false)
end

function bt.Animation.SPEED_RAISED(scene, sprite)
    return bt.Animation.STAT_CHANGED(scene, sprite, bt.StatType.SPEED, true)
end

function bt.Animation.SPEED_LOWERED(scene, sprite)
    return bt.Animation.STAT_CHANGED(scene, sprite, bt.StatType.SPEED, false)
end

function bt.Animation.PRIORITY_RAISED(scene, sprite)
    return bt.Animation.STAT_CHANGED(scene, sprite, bt.StatType.PRIORITY, true)
end

function bt.Animation.PRIORITY_LOWERED(scene, sprite)
    return bt.Animation.STAT_CHANGED(scene, sprite, bt.StatType.PRIORITY, false)
end

--- @class bt.Animation.STAT_CHANGED
bt.Animation.STAT_CHANGED = meta.new_type("STAT_CHANGED", rt.Animation, function(scene, sprite, stat, direction)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_isa(sprite, bt.EnemySprite)
    meta.assert_boolean(direction)
    meta.assert_enum_value(stat, bt.StatType)

    local settings = rt.settings.battle.animation.stat_changed
    return meta.new(bt.Animation.STAT_CHANGED, {
        _scene = scene,
        _target = sprite,
        _direction = direction, -- true = up, false = down
        _stat = stat,

        _shader = nil, -- rt.Shader
        _shader_animation = rt.TimedAnimation(settings.duration,
            0, 1, rt.InterpolationFunctions.GAUSSIAN
        ),
        _color = {1, 1, 1, 1},

        _label = nil, -- rt.Label
        _label_path = nil, -- rt.Path,
        _label_x = 0,
        _label_y = 0,
        _label_path_animation = rt.TimedAnimation(settings.duration, 0, 1),
        _label_opacity_animation = rt.TimedAnimation(settings.duration,
            0, 1, rt.InterpolationFunctions.SHELF
        ),

        _elapsed = 0
    })
end)

do
    local _shader = rt.Shader("battle/animations/stat_changed.glsl")

    --- @override
    function bt.Animation.STAT_CHANGED:start()
        self._shader = _shader

        local stat = ""
        if self._stat == bt.StatType.ATTACK and self._direction == true then
            stat = rt.Translation.battle.attack_up_label
        elseif self._stat == bt.StatType.ATTACK and self._direction == false then
            stat = rt.Translation.battle.attack_down_label
        elseif self._stat == bt.StatType.DEFENSE and self._direction == true then
            stat = rt.Translation.battle.defense_up_label
        elseif self._stat == bt.StatType.DEFENSE and self._direction == false then
            stat = rt.Translation.battle.defense_down_label
        elseif self._stat == bt.StatType.SPEED and self._direction == true then
            stat = rt.Translation.battle.speed_up_label
        elseif self._stat == bt.StatType.SPEED and self._direction == false then
            stat = rt.Translation.battle.speed_down_label
        elseif self._stat == bt.StatType.HP and self._direction == true then
            stat = rt.Translation.battle.hp_up_label
        elseif self._stat == bt.StatType.HP and self._direction == false then
            stat = rt.Translation.battle.hp_down_label
        elseif self._stat == bt.StatType.PRIORITY and self._direction == true then
            stat = rt.Translation.battle.priority_up_label
        elseif self._stat == bt.StatType.PRIORITY and self._direction == false then
            stat = rt.Translation.battle.priority_down_label
        end
        self._label = rt.Label("<b><o>" .. stat .. "</o></b>")
        local label_w, label_h = self._label:measure()
        self._label:fit_into(-0.5 * label_w, -0.5 * label_h, POSITIVE_INFINITY)

        local target_x, target_y = self._target:get_position()
        local target_w, target_h = self._target:get_size()
        self._label_path = rt.Path(
            target_x + 0.5 * target_w, target_y + 0.5 * target_h,
            target_x + 0.5 * target_w, target_y + 0.7 * target_h
        )

        local color
        if self._stat == bt.StatType.ATTACK then
            color = rt.Palette.ATTACK
        elseif self._stat == bt.StatType.DEFENSE then
            color = rt.Palette.DEFENSE
        elseif self._stat == bt.StatType.SPEED then
            color = rt.Palette.SPEED
        elseif self._stat == bt.StatType.PRIORITY then
            color = rt.Palette.SPEED
        elseif self._stat == bt.StatType.HP then
            color = rt.Palette.HP
        end
        assert(color ~= nil)
        self._color = {rt.color_unpack(color)}
        input = rt.InputController()
        input:signal_connect("pressed", function()
            self._shader:recompile()
            println("recompile")
        end)
        self._temp = input
    end
end




--- @override
function bt.Animation.STAT_CHANGED:update(delta)
    local is_done = false
    for animation in range(
        self._shader_animation,
        self._label_path_animation,
        self._label_opacity_animation
    ) do
        animation:update(delta)
        is_done = is_done and animation:get_is_done()
    end
    self._elapsed = self._elapsed + delta

    self._label_x, self._label_y = self._label_path:at(self._label_path_animation:get_value())
    self._label:set_opacity(self._label_opacity_animation:get_value())

    return is_done
end

--- @override
function bt.Animation.STAT_CHANGED:draw()
    love.graphics.push()
    love.graphics.translate(self._label_x, self._label_y)
    self._label:draw()
    love.graphics.pop()

    self._shader:bind()
    self._shader:send("elapsed", self._elapsed)
    self._shader:send("color", self._color)
    self._shader:send("direction", self._direction)
    self._target:draw_snapshot()
    self._shader:unbind()
end

