rt.settings.action_selection_thumbnail.infinity = "∞"

--- @class bt.ActionSelectionThumbnail
bt.ActionSelectionThumbnail = meta.new_type("ActionSelectionThumbnail", rt.Widget, function(action, n_uses)
    if meta.is_nil(n_uses) then n_uses = POSITIVE_INFINITY end
    local out = meta.new(bt.ActionSelectionThumbnail, {
        _action = action,
        _n_uses = -1,
        _label = rt.Label(""),
        _sprite = action:create_sprite(),
        _sprite_aspect = rt.AspectLayout(1),
        _color_transform = rt.SnapshotLayout()
    })

    out._label:set_alignment(rt.Alignment.END)

    local sprite_w, sprite_h = out._sprite:get_resolution()
    out._sprite_aspect:set_minimum_size(2 * sprite_w, 2 * sprite_h)

    out._sprite_aspect:set_child(out._sprite)
    out._color_transform:set_child(out._sprite_aspect)
    out:set_n_uses(ternary(meta.is_nil(n_uses), POSITIVE_INFINITY, n_uses))

    return out
end)

--- @overload rt.Widget.get_top_level_widget
function bt.ActionSelectionThumbnail:size_allocate(x, y, width, height)
    self._color_transform:fit_into(x, y, width, height)
    local label_w, label_h = self._label:measure()
    local sprite_x, sprite_y = self._sprite:get_position()
    local sprite_w, sprite_h = self._sprite:get_size()

    self._label:fit_into(x + sprite_x + sprite_w - label_w, y + sprite_y + sprite_h - label_h, label_w, label_h)
end

--- @overload rt.Drawable.draw
function bt.ActionSelectionThumbnail:draw()
    self._color_transform:draw()
    self._label:draw()
end

--- @overload rt.Widget.realize
function bt.ActionSelectionThumbnail:realize()
    self._label:realize()
    self._color_transform:realize()
    rt.Widget.realize(self)
end

--- @brief
function bt.ActionSelectionThumbnail:set_n_uses(n_uses)
    if self._n_uses ~= n_uses then
        self._n_uses = n_uses
        if self._n_uses == POSITIVE_INFINITY then
            self._label:set_text("<o><mono>" .. rt.settings.action_selection_thumbnail.infinity .. "</mono></o>")
        else
            self._label:set_text("<o><mono>" .. tostring(self._n_uses) .. " / " .. tostring(self._action.max_n_uses) .. "</mono></o>")
        end
    end

    if n_uses == 0 then
        self._color_transform:set_offsets(nil, nil, nil, 0, -1, -0.3, -0.5)
    else
        self._color_transform:reset_offsets()
    end
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
