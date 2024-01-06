--- @class bt.ActionListItem
bt.ActionListItem = meta.new_type("ActionListItem", function(action, count)
    if meta.is_nil(env.action_spritesheet) then
        env.action_spritesheet = rt.Spritesheet("assets/sprites", "orbs")
    end

    local sprite_id = "default"
    local sprite_size_x, sprite_size_y = env.action_spritesheet:get_frame_size(sprite_id)
    sprite_size_x = sprite_size_x * 1
    sprite_size_y = sprite_size_y * 1

    if meta.is_nil(count) then count = 0 end

    local out = meta.new(bt.ActionListItem, {
        _action = action,
        _sprite = rt.Sprite(env.action_spritesheet, sprite_id),
        _sprite_aspect = rt.AspectLayout(sprite_size_x / sprite_size_y),
        _sprite_backdrop = rt.Spacer(),
        _sprite_overlay = rt.OverlayLayout(),

        _name_label = rt.Label(action.name),
        _effect_label = rt.Label(action.effect_text),

        _name_spacer = rt.Spacer(),
        _effect_spacer = rt.Spacer(),
        _n_uses_spacer = rt.Spacer(),

        _n_uses_label = rt.Label("? / ?"),

        _count_label = rt.Label("<mono>" .. ternary(count < 10, "0", "") .. tostring(count) .. "</mono>"),
        _end_spacer = rt.Spacer(),

        _hbox = rt.BoxLayout(rt.Orientation.HORIZONTAL),

        _tooltip = bt.ActionTooltip(action),
        _tooltip_layout = rt.TooltipLayout()
    }, rt.Widget, rt.Drawable)

    out._sprite_overlay:set_base_child(out._sprite_backdrop)
    out._sprite_aspect:set_child(out._sprite)
    out._sprite_overlay:push_overlay(out._sprite_aspect)

    for spacer in range(out._sprite_spacer, out._name_spacer, out._n_uses_spacer, out._effect_spacer, out._end_spacer) do
        spacer:set_expand_horizontally(false)
        spacer:set_expand_vertically(true)
        spacer:set_minimum_size(3, 0)
        spacer:set_color(rt.Palette.FOREGROUND)
        spacer:set_margin_horizontal(rt.settings.margin_unit)
    end

    out._sprite:set_minimum_size(sprite_size_x * 2, sprite_size_y * 2)
    out._sprite_overlay:set_margin_right(rt.settings.margin_unit)
    out._sprite_overlay:set_expand(false)
    out._name_label:set_expand_horizontally(true)
    out._name_label:set_horizontal_alignment(rt.Alignment.START)
    out._name_label:set_margin_left(rt.settings.margin_unit)
    out._effect_label:set_horizontal_alignment(rt.Alignment.START)

    out._count_label:set_expand_horizontally(false)

    out._hbox:push_back(out._sprite_overlay)
    out._hbox:push_back(out._name_label)
    out._hbox:push_back(out._name_spacer)
    out._hbox:push_back(out._effect_label)
    out._hbox:push_back(out._effect_spacer)
    out._hbox:push_back(out._n_uses_label)
    out._hbox:push_back(out._n_uses_spacer)
    out._hbox:push_back(out._count_label)
    --out._hbox:push_back(out._end_spacer)

    out:update_n_uses(action.max_n_uses)
    out._n_uses_label:set_expand_horizontally(false)
    out._n_uses_label:set_horizontal_alignment(rt.Alignment.START)

    out._hbox:set_expand_vertically(false)

    out._tooltip_layout:set_child(out._hbox)
    out._tooltip_layout:set_tooltip(out._tooltip)

    out:set_count(count)

    return out
end)

--- @brief [internal]
function bt.ActionListItem:get_top_level_widget()
    return self._tooltip_layout
end

--- @brief
function bt.ActionListItem:update_n_uses(n_uses)

    local max_n_uses = self._action.max_n_uses
    n_uses = clamp(n_uses, 0, max_n_uses)
    self._n_uses_label:set_text("<mono>" .. tostring(n_uses) .. "/" .. tostring(max_n_uses) .. "</mono>")
end


--- @brief
function bt.ActionListItem:set_count(n)
    self._count_label:set_text("<mono>" .. ternary(n < 10, "0", "") .. tostring(n) .. "</mono>")
end