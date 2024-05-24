rt.settings.battle.scene = {
    fourier_window_size = rt.settings.monitored_audio_playback.default_window_size,
    fourier_n_mel_frequencies = 32,
    fourier_transform_fps = 30,
}

--- @class bt.Scene
bt.Scene = meta.new_type("BattleScene", rt.Widget, function()
    return meta.new(bt.Scene, {
        _ui = {}, -- rt.BattleUI
        _state = {}, -- bt.Battle
        _background = nil, -- bt.Background

        _playback = nil, -- rt.MonitoredAudioPlayback
        _playback_spectrum = {},
        _playback_intensity = 0,
        _playback_elapsed = 0,

        _selection_handler = {}, -- bt.SelectionHandler
        _elapsed = 0,
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

    self._selection_handler = bt.SelectionHandler(self)
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
    self._elapsed = self._elapsed + delta
    self._ui:update(delta)

    if meta.isa(self._background, bt.Background) then
        self._background:update(delta, self._playback_intensity, self._playback_spectrum)
    end

    if self._playback ~= nil then
        self._playback:update(delta)
        self._playback_elapsed = self._playback_elapsed + delta

        if self._playback_elapsed > 1 / rt.settings.battle.scene.fourier_transform_fps then
            self._playback_elapsed = 0
            local spectrum, intensity = self._playback:get_current_spectrum(rt.settings.battle.scene.fourier_window_size, rt.settings.battle.scene.fourier_n_mel_frequencies)
            self._playback_spectrum = spectrum
            self._playback_intensity = intensity
        end
    end
end

--- @brief
function bt.Scene:send_message(text, jump_to_newest)
    self._ui:set_log_is_in_scroll_mode(false)
    self._ui:get_log():append(text, which(jump_to_newest, true))
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
function bt.Scene:play_animations(...)
    self._ui:get_animation_queue():push(...)
end

--- @brief
function bt.Scene:skip()
    self._ui:skip()
end

--- @brief
function bt.Scene:set_background(background_id)
    if bt.Background[background_id] == nil then
        rt.error("In bt.Scene:set_background: no background with id `" .. background_id .. "`")
    end

    local background = bt.Background[background_id]()
    self._background = background

    if self._is_realized then
        background:realize()
        self._background:fit_into(self._bounds)
    end
end

--- @brief
function bt.Scene:set_selected(entities, unselect_others)
    if meta.isa(entities, bt.Entity) then
        entities = {entities}
    end

    unselect_others = which(unselect_others, true)
    self._ui:get_priority_queue():set_selected(entities)

    local is_selected = {}
    for entity in values(entities) do
        is_selected[entity] = true
    end

    for entity in values(self._state:list_entities()) do
        local sprite = self._ui:get_sprite(entity)
        if is_selected[entity] == true then
            sprite:set_selection_state(bt.SelectionState.SELECTED)
        else
            if unselect_others == true then
                sprite:set_selection_state(bt.SelectionState.UNSELECTED)
            else
                sprite:set_selection_state(bt.SelectionState.INACTIVE)
            end
        end
    end
end

--- @brief
function bt.Scene:format_name(entity)
    local name
    if meta.isa(entity, bt.Entity) then
        name = entity:get_name()
        if entity.is_enemy == true then
            name = "<color=ENEMY><b>" .. name .. "</b></color> "
        end
    elseif meta.isa(entity, bt.Status) then
        name = "<b><i>" .. entity:get_name() .. "</b></i>"
    elseif meta.isa(entity, bt.GlobalStatus) then
        name = "<b><i>" .. entity:get_name() .. "</b></i>"
    elseif meta.isa(entity, bt.Equip) then
        name = "<b>" .. entity:get_name() .. "</b>"
    elseif meta.isa(entity, bt.Consumable) then
        name = "<b>" .. entity:get_name() .. "</b>"
    elseif meta.isa(entity, bt.Move) then
        name = "<b><u>" .. entity:get_name() .. "</u></b>"
    else
        rt.error("In bt.Scene:get_formatted_name: unhandled entity type `" .. meta.typeof(entity) .. "`")
    end
    return name
end

--- @brief
function bt.Scene:set_music(path, should_start)
    self._playback = rt.MonitoredAudioPlayback(path)
    self._playback_elapsed = 0
    if should_start == nil or should_start == true then
        self._playback:start()
    end
end

--- @brief
function bt.Scene:get_elapsed()
    return self._elapsed
end