rt.settings.battle.scene = {

}

--- @class bt.Scene
bt.Scene = meta.new_type("BattleScene", rt.Widget, function()
    return meta.new(bt.Scene, {
        _ui = {}, -- rt.BattleUI
    })
end)

--- @override
function bt.Scene:realize()
    if self._is_realized then return end

    self._ui = bt.BattleUI(self)
    self._ui:realize()

    self._is_realized = true
end

--- @override
function bt.Scene:draw()
    self._ui:draw()
end

--- @override
function bt.Scene:size_allocate(x, y, width, height)
    if not self._is_realized then return end
    self._ui:fit_into(x, y, width, height)
end

--- @brief
function bt.Scene:update(delta)
    if not self._is_realized then return end
    self._ui:update(delta)
end

--- @brief
function bt.Scene:send_message(text)
    self._ui:get_log():advance()
    self._ui:get_log():append(text, true)
end

--- @brief
function bt.Scene:get_are_messages_done()
    return self._ui:get_log():get_is_scrolling_done()
end

--- @brief
function bt.Scene:show_log()
    self._ui:get_log():set_is_closed(false)
end

--- @brief
function bt.Scene:hide_log()
    self._ui:get_log():set_is_closed(true)
end

--- @brief
function bt.Scene:play_animation(entity, animation_id, ...)
    if bt.Animation[animation_id] == nil then
        rt.error("In bt.BattleScene:play_animation: no animation with id `" .. animation_id .. "`")
    end

    local sprite = self._ui:get_sprite(entity)
    if sprite == nil then
        rt.error("In bt.BattleScene:play_animation: unhandled animation target `" .. meta.typeof(entity) .. "`")
    end

    local animation = bt.Animation[animation_id](self, sprite, ...)
    self._ui:get_animation_queue():append(animation)
    return animation
end