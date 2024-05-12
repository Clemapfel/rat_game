rt.settings.battle.scene = {

}

--- @class bt.Scene
bt.Scene = meta.new_type("BattleScene", rt.Widget, function()
    return meta.new(bt.Scene, {
        _ui = {}, -- rt.BattleUI
        _background = nil, -- bt.Background
    })
end)

--- @override
function bt.Scene:realize()
    if self._is_realized then return end

    self._ui = bt.BattleUI(self)
    self._ui:realize()

    if meta.isa(self._background, bt.Background) then
        self._background:realize()
    end

    self._is_realized = true
end

--- @override
function bt.Scene:draw()
    if self._background ~= nil then
        self._background:draw()
    end
    self._ui:draw()
end

--- @override
function bt.Scene:size_allocate(x, y, width, height)
    if not self._is_realized then return end
    self._ui:fit_into(x, y, width, height)

    if meta.isa(self._background, bt.Background) then
        self._background:fit_into(x, y, width, height)
    end
end

--- @brief
function bt.Scene:update(delta)
    if not self._is_realized then return end
    self._ui:update(delta)

    if meta.isa(self._background, bt.Background) then
        self._background:update(delta)
    end
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
    self._ui:get_animation_queue():push(animation)
    return animation
end

--- @brief
function bt.Scene:set_background(background_id)
    if bt.Background[background_id] == nil then
        rt.error("In bt.BattleScene:set_background: no background with id `" .. background_id .. "`")
    end

    local background = bt.Background[background_id]()
    self._background = background

    if self._is_realized then
        background:realize()
        self._background:fit_into(self._bounds)
    end
end