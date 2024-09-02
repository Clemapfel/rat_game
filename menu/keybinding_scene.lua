rt.settings.menu.keybinding_scene = {
    text_atlas_id = "menu/keybindings_scene"
}

--- @class rt.KeybindingScene
mn.KeybindingScene = meta.new_type("KeybindingsScene", rt.Scene, function(state)
    return meta.new(mn.KeybindingScene, {
        _state = state,
        _items = {},                   -- Table<rt.InputButton, mn.KeybindingScene.Item>
        _restore_default_item = nil,   -- mn.KeybindingScene.Item
        _accept_label = nil,            -- mn.KeybindingScene.Item
        _accept_frame = rt.Frame(),
        _go_back_label = nil,           -- mn.KeybindingScene.Item
        _go_back_frame = rt.Frame(),
        _heading_label = nil,
        _heading_frame = rt.Frame(),

        _dialog_shadow = rt.Rectangle(0, 0, 1, 1),
        _invalid_binding_dialog = nil, -- mn.MessageDialog
        _selection_graph = rt.SelectionGraph()
    })
end, {
    button_layout = {
        {rt.InputButton.A, rt.InputButton.B, rt.InputButton.X, rt.InputButton.Y},
        {rt.InputButton.UP, rt.InputButton.RIGHT, rt.InputButton.DOWN, rt.InputButton.LEFT},
        {rt.InputButton.L, rt.InputButton.R, rt.InputButton.START, rt.InputButton.SELECT}
    }
})

--- @override
function mn.KeybindingScene:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    local labels = rt.TextAtlas:get("menu/keybindings_scene")
    self._accept_label = rt.Label(labels.accepts)
    self._go_back_label = rt.Label(labels.go_back)
    self._heading_label = rt.Label(labels.heading)

    for label in range(self._accept_label, self._go_back_label, self._heading_label) do
        label:realize()
    end

    for frame in range(self._accept_frame, self._go_back_frame, self._heading_frame) do
        frame:realize()
    end

    self._items = {}
    for button_row in values(self.button_layout) do
        local row = {}
        for button in values(button_row) do
            local to_insert = {
                button = button,
                label = rt.Label(labels[button]),
                frame = rt.Frame(),
                indicator = rt.KeybindingIndicator()
            }

            to_insert.label:realize()
            to_insert.frame:realize()
            to_insert.indicator:realize()
            table.insert(row, to_insert)
        end
        table.insert(self._items, row)
    end
end

--- @override
function mn.KeybindingScene:create_from_state(state)
    for item_row in values(self._items) do
        for item in values(item_row) do
            local binding = self._state:
        end
    end
end

--- @override
function mn.KeybindingsScene:size_allocate(x, y, width, height)

end

--- @override
function mn.KeybindingsScene:draw()
    if self._is_realized ~= true then return end
    self._heading_frame:draw()
    self._heading_label:draw()

    for item_row in values(self._items) do
        for item in values(item_row) do
            item.frame:draw()
            item.label:draw()
            item.indicator:draw()
        end
    end

    self._go_back_frame:draw()
    self._go_back_label:draw()

    self._accept_frame:draw()
    self._accept_label:draw()
end