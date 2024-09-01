rt.settings.menu.keybinding_scene = {

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
end

--- @override
function mn.Keybindingscene:create_from_state(state)

end