rt.settings.battle.battle_ui = {
    log_n_lines_default = 3,
}

bt.Animation = {}

--- @class bt.BattleUI
bt.BattleUI = meta.new_type("BattleUI", rt.Widget, rt.Animation, function()
    return meta.new(bt.BattleUI, {
        _log = {}, -- rt.TextBox
        _animation_queue = {}, -- rt.AnimationQueue
    })
end)

--- @brief
function bt.BattleUI:get_log()
    return self._log
end

--- @brief
function bt.BattleUI:get_animation_queue()
    return self._animation_queue
end

--- @brief
function bt.BattleUI:realize()
    if self._is_realized then return end

    self._log = rt.TextBox()
    self._log:realize()

    self._animation_queue = rt.AnimationQueue()

    self._is_realized = true
end

--- @brief
function bt.BattleUI:size_allocate(x, y, width, height)
    local m = rt.settings.margin_unit
    self._log:set_n_visible_lines(rt.settings.battle.battle_ui.log_n_lines_default)

    local log_horizontal_margin = 2 * m
    local log_vertical_margin = m
    self._log:fit_into(
        log_horizontal_margin,
        log_vertical_margin,
        rt.graphics.get_width() - 2 * log_horizontal_margin,
        rt.graphics.get_height() * 1 / 4 - log_vertical_margin
    )
end

--- @brief
function bt.BattleUI:update(delta)
    if not self._is_realized then return end
    self._animation_queue:update(delta)
    self._log:update(delta)
end

--- @brief
function bt.BattleUI:draw()
    if not self._is_realized then return end
    self._log:draw()
end
