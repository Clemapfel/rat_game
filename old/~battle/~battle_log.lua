rt.settings.battle.log = {
    scrollbar_width = 3 * rt.settings.margin_unit,
    scroll_speed = 10, -- letters per second
    font = rt.Font(30, "assets/fonts/DejaVuSans/DejaVuSans-Regular.ttf")
}

--- @class bt.BattleLogTextLayout
bt.BattleLogTextLayout = meta.new_type("BattleLogTextLayout", rt.Widget, rt.Animation, function()
    return meta.new(bt.BattleLogTextLayout, {
        _children = {},                    -- Table<rt.Widget>
        _children_heights = {},            -- Table<Number>
        _cumulative_children_heights = {
            [0] = 0
        },
        _area = rt.AABB(0, 0, 1, 1),
        _index = 1,
        _n_children = 0,
        _active_label = {}, -- rt.Label
        _elapsed = 0
    })
end)

--- @override
function bt.BattleLogTextLayout:realize()
    for _, child in pairs(self._children) do
        child:realize()
    end
    self:set_is_animated(true)
    local _, min_size = rt.Glyph(rt.settings.battle.log.font, "_\n_\n!"):get_size()
    self:set_minimum_size(0, min_size)
    self._is_realized = true
end

--- @override
function bt.BattleLogTextLayout:draw()
    if not self:get_is_visible() or self._n_children == 0 then
        return
    end
    local i = self._index
    local offset = ternary(i > 1, -1 * self._cumulative_children_heights[i-1], 0)

    rt.graphics.push()
    rt.graphics.translate(0, offset)


    local h = 0
    while i <= self._n_children and h <= self._area.height do
        self._children[i]:draw()
        h = h + self._children_heights[i]
        i = i + 1
    end

    rt.graphics.pop()

    self:draw_selection_indicator()
end

--- @override
function bt.BattleLogTextLayout:size_allocate(x, y, width, height)
    local area = rt.AABB(x, y, width, height)
    self._children_heights = {}
    self._cumulative_children_heights = {
        [0] = 0
    }

    for i = 1, self._n_children do
        local child = self._children[i]
        child:fit_into(area.x, area.y, width, height)

        local h = select(2, child:measure())
        area.y = area.y + h
        self._children_heights[i] = h
        self._cumulative_children_heights[i] = self._cumulative_children_heights[i-1] + h
    end

    self._area = area
end

--- @brief
function bt.BattleLogTextLayout:push_back(str)
    local child = rt.Label(str)
    table.insert(self._children, child)
    child:set_parent(self)
    if self:get_is_realized() then child:realize() end

    if meta.is_label(self._active_label) then
        self._active_label:set_n_visible_characters(POSITIVE_INFINITY)
        self:scroll_up()
    end
    self._active_label = child
    self._active_label:set_alignment(rt.Alignment.START)
    self._active_label:set_n_visible_characters(0)

    local area = self._area
    child:fit_into(area.x, area.y, area.width, POSITIVE_INFINITY)

    local h = select(2, child:measure())
    area.y = area.y + h
    self._children_heights[self._n_children + 1] = h
    self._cumulative_children_heights[self._n_children + 1] = self._cumulative_children_heights[self._n_children] + h
    self._n_children = self._n_children + 1
end

--- @brief
function bt.BattleLogTextLayout:scroll_up()
    if self._index > 1 then
        self._index = self._index - 1
    end
end

--- @brief
function bt.BattleLogTextLayout:scroll_down()
    if self._index < self._n_children then
        self._index = self._index + 1
    end
end

--- @brief
function bt.BattleLogTextLayout:update(delta)
    self._elapsed = self._elapsed + delta
    local step = 1 / rt.settings.battle.log.scroll_speed

    local n_letters = 0
    while self._elapsed >= step do
        self._elapsed = self._elapsed - step
        n_letters = n_letters + 1
    end

    if meta.is_label(self._active_label) then
        self._active_label:set_n_visible_characters(self._active_label:get_n_visible_characters() + n_letters)
    end
end

bt.BattleLog = bt.BattleLogTextLayout