--- @class bt.ActionSelectionThumbnail
bt.ActionSelectionThumbnail = meta.new_type("ActionSelectionThumbnail", function(action, n_uses)
    if meta.is_nil(n_uses) then n_uses = POSITIVE_INFINITY end
    local out = meta.new(bt.ActionSelectionThumbnail, {
        _use_count = POSITIVE_INFINITY,
        --_label =
    })
    return out
end)

--- @brief
function bt.ActionSelectionThumbnail:set_n_uses()

end

--- @class bt.ActionSelectionMenu
bt.ActionSelectionMenu = meta.new_type("ActionSelectionMenu", function(entity)
    local out = meta.new(bt.ActionSelectionMenu, {
        _input = {},
        _move_sprites = {},
        _intrinsic_sprites = {},
        _consumable_sprites = {}
    }, rt.Drawable, rt.Widget)

    out._input = rt.add_input_controller(out)

    out._input:signal_connect("pressed", function(_, which, self)
        if which == rt.InputButton.A then
        elseif which == rt.InputButton.B then
        elseif which == rt.InputButton.X then
        elseif which == rt.InputButton.Y then
        elseif which == rt.InputButton.UP then
        elseif which == rt.InputButton.DOWN then
        elseif which == rt.InputButton.RIGHT then
        elseif which == rt.InputButton.LEFT then
        elseif which == rt.InputButton.R then
        elseif which == rt.InputButton.L then
        end
    end, out)
    return out
end)
