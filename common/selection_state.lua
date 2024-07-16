rt.settings.selection_state = {
    unselected_opacity = 0.3,
}

--- @class rt.SelectionState
rt.SelectionState = meta.new_enum({
    SELECTED = 1,
    INACTIVE = 0,
    UNSELECTED = -1
})