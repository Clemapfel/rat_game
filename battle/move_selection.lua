rt.settings.battle.move_selection = {
}

bt.MoveSelection = meta.new_type("MoveSelection", rt.Widget, rt.Animation, function(n_slots)
    return meta.new(bt.MoveSelection, {
        _items = {}, -- cf. create_from
        _entries = {},
        _frame = rt.Frame(),
        _base = rt.Spacer(),

        _verbose_info = bt.VerboseInfo(),
        _current_tile_i = 1
    })
end)

--- @brief
function bt.MoveSelection:create_from(user, moveset)
    local to_show = {}
    for move in values(moveset) do
        local n_uses = user:get_move_n_uses_left(move)
        local to_insert = bt.MoveSelectionItem(move, n_uses)
        table.insert(to_show, {move, n_uses})
        if self._is_realized then to_insert:realize() end
        table.insert(self._items, to_insert)
    end

    self._verbose_info:add(table.unpack(to_show))
    if self._is_realized == true then
        self:reformat()
    end
end

--- @override
function bt.MoveSelection:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    self._frame:set_child(self._base)
    self._frame:realize()
    self._verbose_info:realize()

    for item in values(self._items) do
        item:realize()
    end

    self:reformat()
end

--- @override
function bt.MoveSelection:size_allocate(x, y, width, height)
    local m = rt.settings.margin_unit
    local tile_w, tile_h = 100, 100

    local max_w, max_h = NEGATIVE_INFINITY, NEGATIVE_INFINITY
    for item in values(self._items) do
        local item_w, item_h = item:measure()
        max_w = math.max(max_w, item_w)
        max_h = math.max(max_h, item_h)
    end

    tile_w = max_w + 2 * m
    tile_h = max_h + 2 * m

    local thickness = self._frame:get_thickness()
    local w = 5 * tile_w + 2 * m
    local h = 5 * tile_h + 2 * m

    local frame_w, frame_h = w + 2 * thickness + 2 * m, h + 2 * thickness + 2 * m
    self._frame:fit_into(x, y, frame_w, frame_h)
    self._verbose_info:fit_into(x + frame_w + m, y, width - w, h)

    local start_x, start_y = x + thickness + m, y + thickness + m

    local n_columns = math.floor(w / tile_w)
    local column_m = (w - (n_columns * tile_w)) / (n_columns - 1)

    local n_rows = math.floor(h / tile_h)
    local row_m = (h - (n_rows * tile_h)) / (n_rows - 1)

    local max_m = math.max(column_m, row_m)
    column_m, row_m = max_m, max_m

    local empty_indicator_radius = 0.2 * math.min(tile_w, tile_h)
    local tile_color = rt.color_darken(rt.Palette.BACKGROUND, 0.05)
    local current_x, current_y = start_x, start_y
    local tile_i = 1
    self._tiles = {}
    while true do
        local item = self._items[tile_i]
        local move, n_uses = nil, nil
        if item ~= nil then
            move = item:get_move()
            n_uses = item:get_n_uses()
        end

        local tile = {
            item = item,
            move = move,
            n_uses = n_uses,
            empty_indicator = rt.Circle(
                current_x + 0.5 * tile_w,-- - 0.5 * empty_indicator_radius,
                current_y + 0.5 * tile_h,-- - 0.5 * empty_indicator_radius,
                empty_indicator_radius,
                empty_indicator_radius
            ),
            base = rt.Rectangle(current_x, current_y, tile_w, tile_h),
            selection_indicator = rt.SelectionIndicator(),
            is_selected = false
        }

        if tile.item ~= nil then
            tile.item:fit_into(current_x, current_y, tile_w, tile_h)
        end

        tile.base:set_color(tile_color)
        tile.base:set_corner_radius(10)
        tile.empty_indicator:set_color(rt.color_darken(tile_color, 0.05))

        tile.selection_indicator:realize()
        tile.selection_indicator:set_thickness(3)
        tile.selection_indicator:fit_into(current_x, current_y, tile_w, tile_h)

        table.insert(self._tiles, tile)

        current_x = current_x + tile_w + column_m
        if current_x > w then
            current_x = start_x
            current_y = current_y + tile_h + row_m
        end

        if current_y > h then break end
        tile_i = tile_i + 1
    end

    for i = 1, #self._tiles do
        local tile = self._tiles[i]
        tile.up = i - n_columns
        tile.right = i + 1
        tile.down = i + n_columns
        tile.left = i - 1
    end

    self:_update_selection()
end

--- @override
function bt.MoveSelection:draw()
    if self._is_realized ~= true then return end
    self._frame:draw()

    for entry in values(self._tiles) do
        entry.base:draw()
        entry.empty_indicator:draw()

        if entry.item ~= nil then
            entry.item:draw()
        end

        if entry.is_selected == true then
            entry.selection_indicator:draw()
        end
    end

    self._verbose_info:draw()
end

--- @brief [internal]
function bt.MoveSelection:_update_selection()
    local selected_move, n_uses = nil
    for i = 1, #self._tiles do
        local tile = self._tiles[i]
        local is_selected = i == self._current_tile_i
        tile.is_selected = is_selected
        if is_selected then
            selected_move = tile.move
            n_uses = tile.n_uses
        end
    end

    if selected_move == nil then
        self._verbose_info:show()
    else
        self._verbose_info:show({selected_move, n_uses})
    end
end

for direction in range("up", "right", "down", "left") do
    bt.MoveSelection["move_" .. direction] = function(self)
        local next = self._tiles[self._current_tile_i][direction]
        if self._tiles[next] == nil then
            return false
        else
            self._current_tile_i = next
            self:_update_selection()
        end
    end
end

