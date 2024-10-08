rt.settings.selection_state = {
    unselected_opacity = 0.3,
}

--- @class rt.SelectionState
rt.SelectionState = meta.new_enum("SelectionState", {
    SELECTED = 1,
    ACTIVE = 1,
    INACTIVE = 0,
    UNSELECTED = -1
})