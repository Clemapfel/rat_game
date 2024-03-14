rt.settings.battle.log = {
    scroll_speed = 10, -- letters per second
    hold_duration = 3, -- seconds
    n_active_lines = 1,
    font = rt.Font(30, "assets/fonts/DejaVuSans/DejaVuSans-Regular.ttf")
}

--- @class bt.BattleLog
bt.BattleLog = meta.new_type("BattleLog", rt.Widget, rt.Animation, function()  
    return meta.new(bt.BattleLog, {
        _labels = {},       -- Table<rt.Label>
        _bounds = rt.AABB(0, 0, 1, 1),

        _waiting_labels = {}, -- Table<rt.Label>
        _active_labels = {}, -- Set<rt.Label>
        _n_active_labels = 0,
        _hold_labels = {},  -- Set<{rt.Label, Number}>

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

    for label in pairs(self._active_labels) do
        label:draw()
    end

    for label in pairs(self._hold_labels) do
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

    local move_to_hold = {}
    for label in pairs(self._active_labels) do
        local new_n = label:get_n_visible_characters() + n_letters
        label:set_n_visible_characters(new_n)
        if new_n >= label:get_n_characters() then
            table.insert(move_to_hold, label)
        end
    end

    local hold_duration = rt.settings.battle.log.hold_duration
    local move_to_remove = {}
    for label, elapsed in pairs(self._hold_labels) do
        self._hold_labels[label] = elapsed + delta
        if elapsed > hold_duration then
            table.insert(move_to_remove, label)
        end
    end

    for _, label in pairs(move_to_hold) do
        self._active_labels[label] = nil
        self._n_active_labels = self._n_active_labels - 1
        self._hold_labels[label] = 0
    end

    local should_reformat = false
    for _, label in pairs(move_to_remove) do
        self._hold_labels[label] = nil
        should_reformat = true
    end

    if should_reformat then
        self._label_height = 0
        for _, label in pairs(self._labels) do
            if self._active_labels[label] ~= nil or self._hold_labels[label] ~= nil then
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

    if self._n_active_labels < rt.settings.battle.log.n_active_lines then
        self._active_labels[label] = true
        self._n_active_labels = self._n_active_labels + 1
    else
        table.insert(self._waiting_labels, label)
    end
end