rt.settings.battle.log = {
    scroll_speed = 200, -- letters per second
    hold_duration = 3, -- seconds
    fade_duration = 0, -- seconds
    n_scrolling_labels = 3, -- number of labels displayed at the same time
    box_expansion_speed = 15, -- px per second
    hiding_speed = 50, -- px per second
    font = rt.Font(30, "assets/fonts/DejaVuSans/DejaVuSans-Regular.ttf")
}

--- @class bt.BattleLog
bt.BattleLog = meta.new_type("BattleLog", rt.Widget, rt.Animation, function(scene)
    return meta.new(bt.BattleLog, {
        _scene = scene,
        _labels = {},       -- Table<rt.Label>
        _bounds = rt.AABB(0, 0, 1, 1),

        _waiting_labels = {},       -- Fifo<rt.Label>
        _scrolling_labels = {},     -- Table<rt.Label, true>
        _holding_labels = {},       -- Table<rt.Label, elapsed>
        _fading_labels = {},        -- Table<rt.Label, elapsed>

        _bounds = rt.AABB(0, 0, 1, 1),
        _current_y = 0,
        _target_y = 0,      -- intended y coordinate for bottom

        _label_scroll_elapsed = 0,
        _box_expand_elapsed = 0,
        _box_fadeout_elapsed = 0,

        _label_height = 0,
        _should_reformat = true,    -- should labels be realigned next update cycle

        _backdrop = bt.Backdrop()
    })
end)

--- @override
function bt.BattleLog:realize()
    if self._is_realized == true then return end

    self._label_height = 0
    for _, label in pairs(self._labels) do
        label:realize()
        self._label_height = self._label_height + label:get_height()
    end
    self:set_is_animated(true)
    self._backdrop:realize()
    self._is_realized = true
end 

--- @override 
function bt.BattleLog:size_allocate(x, y, width, height)
    self._bounds = rt.AABB(x, y, width, height)
    self._backdrop:fit_into(self._bounds)

    self._label_height = 0
    for i, label in pairs(self._labels) do
        self:_format_label(label, self._label_height)
        self._label_height = self._label_height + select(2, label:get_size())
    end

    self._bounds = rt.AABB(x, y, width, height)
    self._should_reformat = true
end

--- @override
function bt.BattleLog:draw()
    self._backdrop:draw()

    for label in pairs(self._scrolling_labels) do
        label:draw()
    end

    for label in pairs(self._holding_labels) do
        label:draw()
    end

    for label in pairs(self._fading_labels) do
        label:draw()
    end
end

--- @override
function bt.BattleLog:update(delta)
    self._label_scroll_elapsed = self._label_scroll_elapsed + delta
    self._box_expand_elapsed = self._box_expand_elapsed + delta

    local step = 1 / rt.settings.battle.log.scroll_speed
    local n_letters = math.floor(self._label_scroll_elapsed / step)
    self._label_scroll_elapsed = self._label_scroll_elapsed % step

    local n_total_before =  sizeof(self._scrolling_labels) + sizeof(self._holding_labels) + sizeof(self._fading_labels)

    -- move from queue to active if not enough messages are on screen
    local n = n_total_before - rt.settings.battle.log.n_scrolling_labels
    while n < 0 and sizeof(self._fading_labels) == 0 and not (#self._waiting_labels == 0) do
        self._scrolling_labels[self._waiting_labels[1]] = true
        table.remove(self._waiting_labels, 1)
        self._should_reformat = true
        n = n + 1
    end

    -- scroll active, if scrolling is done, move to holding
    local remove_from_active = {}
    for label, _ in pairs(self._scrolling_labels) do
        local new_n = label:get_n_visible_characters() + n_letters
        label:set_n_visible_characters(new_n)
        if new_n >= label:get_n_characters() then
            self._holding_labels[label] = 0
            table.insert(remove_from_active, label)
        end
    end

    for _, label in pairs(remove_from_active) do
        self._scrolling_labels[label] = nil
    end

    -- keep holding labels on screen, then move to fade out
    local remove_from_holding = {}
    for label, elapsed in pairs(self._holding_labels) do
        self._holding_labels[label] = elapsed + delta
        if elapsed + delta > rt.settings.battle.log.hold_duration then
            self._fading_labels[label] = 0
            table.insert(remove_from_holding, label)
        end
    end

    for _, label in pairs(remove_from_holding) do
        self._holding_labels[label] = nil
    end

    -- after fade is done, hide label
    local remove_from_fading = {}
    local fade_duration = rt.settings.battle.log.fade_duration
    for label, elapsed in pairs(self._fading_labels) do
        self._fading_labels[label] = elapsed + delta
        label:set_opacity(1 - (elapsed + delta) / fade_duration)
        if elapsed + delta > fade_duration then
            table.insert(remove_from_fading, label)
        end
    end

    for _, label in pairs(remove_from_fading) do
        self._should_reformat = true
        self._fading_labels[label] = nil
    end

    -- scroll all visible labels. if one dissapeared, resize box
    if self._should_reformat then
        local h = 0
        for _, label in pairs(self._labels) do
            self:_format_label(label, h)
            if self._scrolling_labels[label] ~= nil or self._holding_labels[label] ~= nil or self._fading_labels[label] ~= nil then
                h = h + select(2, label:measure())
            end
        end

        self._label_height = 0
        for _, label in pairs(self._labels) do
            if self._scrolling_labels[label] ~= nil or self._holding_labels[label] ~= nil or self._fading_labels[label] ~= nil then
                self._label_height = self._label_height + select(2, label:measure())
            end
        end

        self._target_y = self._label_height
        self._should_reformat = false
        self._should_reformat = false
    end

    local step = 1 / rt.settings.battle.log.box_expansion_speed
    local n_steps = math.floor(self._box_expand_elapsed / step)
    self._box_expand_elapsed = self._box_expand_elapsed % step
    local diff = clamp(n_steps * rt.settings.battle.log.box_expansion_speed, 0, math.abs(self._target_y - self._current_y))
    local reformat = false
    if self._current_y <= self._target_y then
        self._current_y = self._target_y -- jump to full when expanding
        reformat = true
    elseif self._current_y >= self._target_y then
        self._current_y = self._current_y - diff
        reformat = true
    end

    local margin = 3 * rt.settings.margin_unit
    if reformat then
        self._backdrop:fit_into(
            self._bounds.x, self._bounds.y,
            self._bounds.width,
            self._current_y - self._bounds.y + ternary(self._target_y > margin, margin, 0)
        )
    end

    -- if all labels are gone, fade out box in addition to shrinking
    local n_total_now = sizeof(self._scrolling_labels) + sizeof(self._holding_labels) + sizeof(self._fading_labels)
    if n_total_now == 0 then
        self._box_fadeout_elapsed = self._box_fadeout_elapsed + delta
        local fraction = (self._current_y) / (margin) - 0.4
        local v = clamp(fraction, 0, 1)
        self._backdrop:set_opacity(v)
    elseif self._box_fadeout_elapsed ~= 0 then
        self._box_fadeout_elapsed = 0
        self._backdrop:set_opacity(1)
    end
end

--- @brief [internal]
function bt.BattleLog:_format_label(label, h)
    local ym = rt.settings.margin_unit
    local xm = rt.settings.margin_unit * 2
    label:fit_into(
        self._bounds.x + xm,
        self._bounds.y + h + ym,
        self._bounds.width - 2 * xm,
        1
    )
end

--- @brief
function bt.BattleLog:push_back(str)
    local label = rt.Label(str)
    table.insert(self._labels, label)
    label:realize()
    label:set_alignment(rt.Alignment.START)
    self:_format_label(label, self._label_height)
    self._label_height = self._label_height + select(2, label:measure())
    label:set_n_visible_characters(0)
    table.insert(self._waiting_labels, label)
end
