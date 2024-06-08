--[[
Item:
    Icon
    n_uses / max_n_uses or inf
    name

    make see-through if depleted

List:
    Sort by:
        Name
        N Uses
        Frequently Used

    deplete items can still be selected, but
    confirmation dialog has to be clicked through
    always show attack / defend / intrinsic at top of list

Input:
    A: select
    B: go back to previous party member
    up / down: navigate list

    ?: jump to start

show consumable / equip of current user

inspect mode
select mode
    show move
]]--

--[[
Pro Items:
+ introduces macro decision making outside of battle
- consumables already do that
+ but you dont have control over when consumables activate
- introduce activatable consumable
+ only one consumable per battle per character
- have multiple consumable slots if you really want that

Contra Items:
+ redundant in in-battle function
]]--

rt.settings.battle.move_selection = {
    list_item_margin = rt.settings.margin_unit,
    vrule_thickness = rt.settings.frame.thickness * 1.5
}

rt.MoveSelectionSortMode = meta.new_enum({
    DEFAULT = 1,
    BY_NAME = 2,
    BY_N_USES = 3
})

--- @class
bt.MoveSelection = meta.new_type("MoveSelection", rt.Widget, function(entity)
    return meta.new(bt.MoveSelection, {
        _left_vrule = rt.Line(0, 0, 0, 1),
        _left_vrule_outline = rt.Line(0, 0, 0, 1),
        _base = rt.Rectangle(0, 0, 1, 1),
        _base_gradient = rt.LogGradient(),

        _heading = {}, -- rt.Label

        _items = {},
        _item_order = {},
        _item_bounds = rt.AABB(0, 0, 1, 1),

        _sort_mode = rt.MoveSelectionSortMode.BY_NAME,
        _sortings = {}, -- Table<rt.MoveSelectionSortMode, Table<MoveID>>
    })
end)

--- @brief
function bt.MoveSelection:_regenerate_sortings()
    -- by name
    local by_name_sorting = {}
    local by_n_uses_sorting = {}
    for id in keys(self._items) do
        table.insert(by_name_sorting, id)
        table.insert(by_n_uses_sorting, id)
    end

    table.sort(by_name_sorting, function(a_i, b_i)
        local a_name = self._items[a_i].move:get_name()
        local b_name = self._items[b_i].move:get_name()
        return a_name < b_name
    end)
    self._sortings[rt.MoveSelectionSortMode.BY_NAME] = by_name_sorting

    table.sort(by_n_uses_sorting, function(a_i, b_i)
        local a_n_uses = self._items[a_i].n_uses
        local b_n_uses = self._items[b_i].n_uses

        if a_n_uses == b_n_uses then
            return a_i < b_i
        else
            return a_n_uses < b_n_uses
        end
    end)
    self._sortings[rt.MoveSelectionSortMode.BY_N_USES] = by_n_uses_sorting
end

--- @brief
function bt.MoveSelection:add(move)
    local to_add = {
        move = move,
        item = bt.MoveSelectionItem(move),
        n_uses = move:get_max_n_uses()
    }

    to_add.item:realize()
    local x, y, w, h = rt.aabb_unpack(self._bounds)
    to_add.item:fit_into(0, 0, w, h)
    to_add.item:set_n_uses(move:get_max_n_uses(), move:get_max_n_uses())
    to_add.height = select(2, to_add.item:measure()) + rt.settings.battle.move_selection.list_item_margin

    local already_present = self._items[move:get_id()] ~= nil
    self._items[move:get_id()] = to_add

    if not already_present then
        table.insert(self._item_order, move:get_id())
        self:_regenerate_sortings()
    end
end

--- @override
function bt.MoveSelection:realize()
    if self._is_realized then return end
    self._is_realized = true

    local base_color = rt.Palette.BACKGROUND
    base_color.a = rt.settings.spacer.default_opacity
    self._base:set_color(base_color)
    self._base_gradient = rt.LogGradient(
        rt.RGBA(base_color.r, base_color.g, base_color.b, 0),
        rt.RGBA(base_color.r, base_color.g, base_color.b, base_color.a)
    )

    local line_width = rt.settings.frame.thickness
    self._left_vrule:set_line_width(line_width)
    self._left_vrule:set_color(rt.Palette.FOREGROUND)
    self._left_vrule_outline:set_line_width(line_width + 2)
    self._left_vrule_outline:set_color(rt.Palette.BASE_OUTLINE)

    self._heading = rt.Label("<b><u>Choose Action</u></b>")
    self._heading:realize()
end

--- @override
function bt.MoveSelection:size_allocate(x, y, width, height)
    if self._is_realized ~= true then return end

    local base_w = 400
    self._base:resize(x, y, base_w, height)
    self._base_gradient:resize(x + base_w, y, 100, height)

    local line_width = rt.settings.battle.move_selection.vrule_thickness * 0.5
    self._left_vrule:resize(x - line_width * 0.5, y, x, y + height)
    self._left_vrule_outline:resize(x - line_width * 0.5, y, x, y + height)

    local m = rt.settings.margin_unit
    local current_x, current_y = x + m, y + m
    self._heading:fit_into(current_x, current_y, width, height)
    current_y = current_y + select(2, self._heading:measure()) + m
    self._item_bounds = rt.AABB(current_x, current_y, width, height)
end

--- @override
function bt.MoveSelection:draw()
    if self._is_realized ~= true then return end

    self._base:draw()
    self._base_gradient:draw()
    self._left_vrule_outline:draw()
    self._left_vrule:draw()

    self._heading:draw()

    rt.graphics.push()
    local m = rt.settings.margin_unit
    rt.graphics.translate(self._item_bounds.x, self._item_bounds.y)
    local y_offset = 0
    local order = self._item_order
    if self._sort_mode ~= rt.MoveSelectionSortMode.DEFAULT then
        order = self._sortings[self._sort_mode]
    end

    for id in values(order) do
        local entry = self._items[id]
        entry.item:draw()
        rt.graphics.translate(0, entry.height)
    end
    rt.graphics.pop()
end