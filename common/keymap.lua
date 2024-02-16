--- @brief TODO
rt.KeyMap = {
    activate = { -- trigger buttons or actions
        rt.KeyboardKey.RETURN,
        rt.KeyboardKey.SPACE,
        rt.GamepadButton.A
    }
}

--- @brief TODO
function rt.KeyMap.should_trigger(keymap_id, event)
    if rt.KEYMAP[keymap_id] == nil then return false end
    for _, value in pairs(rt.KEYMAP) do
        if event == value then return true end
    end
    return false
end
