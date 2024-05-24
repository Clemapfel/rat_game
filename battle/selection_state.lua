rt.settings.battle.selection = {
    frame_color = rt.Palette.SELECTION_OUTLINE,
    unselected_opacity = 0.3,
}

--- @class bt.SelectionState
bt.SelectionState = meta.new_enum({
    SELECTED = 1,
    INACTIVE = 0,
    UNSELECTED = -1
})