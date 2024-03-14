rt.settings.battle.log = {
    scroll_speed = 10, -- letters per second
    hold_duration = 0, -- seconds
    fade_duration = 1, -- seconds
    n_scrolling_labels = 1,
    font = rt.Font(30, "assets/fonts/DejaVuSans/DejaVuSans-Regular.ttf")
}

--- @class bt.BattleLog
bt.BattleLog = meta.new_type("BattleLog", rt.Widget, rt.Animation, function()  
    return meta.new(bt.BattleLog, {
        _labels = {},       -- Table<rt.Label>
        _bounds = rt.AABB(0, 0, 1, 1),

        _waiting_labels = {},       -- Fifo<rt.Label>
        _scrolling_labels = {},     -- Table<rt.Label, true>
        _holding_labels = {},       -- Table<rt.Label, elapsed>
        _fading_labels = {},        -- Table<rt.Label, elapsed>
        _elapsed = 0,
        _label_height = 0,
        _backdrop = rt.Spacer()
    })
end)

--- @override
function bt.BattleLog:realize()
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
        self:_format_label(label)
        self._label_height = self._label_height + select(2, label:get_size())
    end
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
    self._elapsed = self._elapsed + delta
    local step = 1 / rt.settings.battle.log.scroll_speed

    local n_letters = 0
    while self._elapsed >= step do
        self._elapsed = self._elapsed - step
        n_letters = n_letters + 1
    end

    -- if label is fully scrolled, move to hold
    -- if label spend hold duration in hold, remove from drawing
    -- when remove, move all later labels up

    -- move from queue to active
    while #self._scrolling_labels < rt.settings.battle.log.n_scrolling_labels and not (#self._waiting_labels == 0) do
        self._scrolling_labels[self._waiting_labels[1]] = true
        table.remove(self._waiting_labels, 1)
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

    -- keep holding labels on screen, then move to fade out
    local remove_from_fading = {}
    local fade_duration = rt.settings.battle.log.fade_duration
    for label, elapsed in pairs(self._fading_labels) do
        self._fading_labels[label] = elapsed + delta
        label:set_opacity(1 - (elapsed + delta) / fade_duration)
        if elapsed + delta > fade_duration then
            table.insert(remove_from_fading, label)
        end
    end

    local should_reformat = false
    for _, label in pairs(remove_from_fading) do
        should_reformat = true
        self._fading_labels[label] = nil
    end

    -- scroll all visible labels if one dissapeared
    if should_reformat then
        self._label_height = 0
        for _, label in pairs(self._labels) do
            if self._scrolling_labels[label] ~= nil or self._holding_labels[label] ~= nil or self._fading_labels[label] ~= nil then
                self:_format_label(label)
                self._label_height = self._label_height + select(2, label:measure())
            end
        end
    end
end

--- @brief [internal]
function bt.BattleLog:_format_label(label)
    local m = rt.settings.margin_unit
    label:fit_into(
        self._bounds.x + m,
        self._bounds.y + self._label_height + m,
        self._bounds.width,
        1
    )
end

--- @brief
function bt.BattleLog:push_back(str)
    local label = rt.Label(str)
    table.insert(self._labels, label)
    label:realize()
    label:set_alignment(rt.Alignment.START)
    self:_format_label(label)
    self._label_height = self._label_height + select(2, label:measure())
    label:set_n_visible_characters(0)
    table.insert(self._waiting_labels, label)
end