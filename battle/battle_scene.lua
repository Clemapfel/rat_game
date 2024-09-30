--[[
Move Slots
Verbose Info
Party Sprite
Enemy Sprite
textbox


]]--

--- @class bt.BattleScene
bt.BattleScene = meta.new_type("BattleScene", rt.Scene, function(state)
    return meta.new(bt.BattleScene, {
        _state = state,

        _temp = bt.OrderedBox(),
        _temp_objects = {},
        _temp_object_to_widget = {},

        _health = bt.HealthBar(0, 100),
        _speed = bt.SpeedValue(55),

        _log = rt.TextBox(),
        _priority_queue = bt.PriorityQueue(),

        _verbose_info = mn.VerboseInfoPanel(),
        _input = rt.InputController()

    })
end)

--- @brief
function bt.BattleScene:_add_item(object)
    local widget = rt.LabeledSprite(object:get_sprite_id())
    self._temp_object_to_widget[object] = widget
    self._temp:add(widget, not meta.isa(object, bt.Consumable))

    table.insert(self._temp_objects, object)
end

--- @override
function bt.BattleScene:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    for object in range(
        bt.Status("DEBUG_STATUS"),
        bt.Consumable("DEBUG_CONSUMABLE"),
        bt.GlobalStatus("DEBUG_GLOBAL_STATUS")
    ) do
        self:_add_item(object)
    end

    self._temp:realize()
    self._health:realize()
    self._speed:realize()

    self._verbose_info:realize()
    self._verbose_info:set_frame_visible(false)

    self._log:realize()
    self._priority_queue:realize()

    self._input:signal_connect("pressed", function(_, which)
        self:_handle_button_pressed(which)
    end)
end

--- @override
function bt.BattleScene:create_from_state(state)
    self._log:clear()
end

--- @override
function bt.BattleScene:size_allocate(x, y, width, height)
    local m = rt.settings.margin_unit
    local temp_w, temp_h = 0.5 * width, 50
    self._temp:fit_into(x + 0.5 * width - 0.5 * temp_w, y + 0.5 * height - 0.5 * temp_h, temp_w, temp_h)
    self._health:fit_into(x + 0.5 * width - 0.5 * temp_w, y + 0.5 * height - 0.5 * temp_h + 2 * temp_h, temp_w, temp_h)
    self._speed:fit_into(x + 0.5 * width - 0.5 * temp_w, y + 0.5 * height - 0.5 * temp_h + 3 * temp_h, temp_w, temp_h)


    local outer_margin = 2 * m
    local log_margin = 10 * outer_margin
    self._log:fit_into(log_margin, outer_margin, width - 2 * log_margin, height - 2 * outer_margin)

    local verbose_w = 0.3 * width
    self._verbose_info:fit_into(x + width - verbose_w - outer_margin, outer_margin, verbose_w, height - 2 * outer_margin)

    -- TODO
    self._verbose_info:show(bt.Status("DEBUG_STATUS"))
    -- TODO

    local prio_w = 0.1 * width
    local prio_x = x + width - outer_margin - prio_w
    local prio_y = y + outer_margin
    local prio_h = height - 2 * outer_margin
    self._priority_queue:fit_into(prio_x, prio_y, prio_w, prio_h)
end

--- @override
function bt.BattleScene:draw()
    self._priority_queue:draw()
end

--- @override
function bt.BattleScene:update(delta)
    self._temp:update(delta)
    self._health:update(delta)
    self._speed:update(delta)
    self._verbose_info:update(delta)
    self._log:update(delta)
    self._priority_queue:update(delta)
end

--- @override
function bt.BattleScene:make_active()
    self._is_active = true
end

--- @override
function bt.BattleScene:make_inactive()
    self._is_active = false
end

--- @brief
function bt.BattleScene:_handle_button_pressed(which)
    local entities = {}
    local list = self._state:list_entities()
    for _ = 1, 4  do
        for entity in values(list) do
            table.insert(entities, entity)
        end
    end

    self._priority_queue:reorder(rt.random.shuffle(entities))
end