rt.settings.animation.protect = {
    shield_color = rt.Palette.GREY_4,
    shield_outline = rt.Palette.GREY_2,
    sheen_color = rt.Palette.WHITE
}
--- @class
bt.Animation.PROTECT = meta.new_type("ProtectAnimation", function(targets)
    local n_targets = sizeof(targets)
    local out = meta.new(bt.ProtectAnimation, {
        _targets = targets,
        _n_targets = n_targets,

        _rectangles = {},           -- Table<rt.Shape>
        _rectangle_outlines = {},   -- Table<rt.Shape>
        _sheen = {},                -- Table<rt.Shape>
        _sheen_paths = {},          -- Table<rt.Spline>

        _elapsed = 0
    })
    return out
end)

--- @overload
bt.ProtectAnimation