bt.InventorySortMode = meta.new_enum({
    DEFAULT = "DEFAULT",
    TYPE = "TYPE",
    NAME_ASCENDING = "NAME_ASCENDING",
    NAME_DESCENDING = "NAME_DESCENDING"
})

--- @class bt.InventoryMenuState
bt.InventoryMenuState = meta.new_type("InventoyMenuState", function(id)
    return meta.new(bt.InventoryMenuState, {
        entity_id = id,
        equipment = {},     -- slot (1-based) -> equipment
        inherent = {},      -- 1-based -> bt.Action
        moves = {},         -- 1-based -> bt.Action
        consumables = {},   -- 1-based -> bt.Action
        attack_ev = 0,
        defense_ev = 0,
        speed_ev = 0,
    })
end)

--- @class bt.InventoryControlDisplay
bt.InventoryMenu = meta.new_type("InventoryMenu", function()

    local out = meta.new(bt.InventoryMenu, {
        _main = rt.BinLayout(),
        _notch_vbar = rt.ListLayout(rt.Orientation.VERTICAL),
        _attack_notch_bar = rt.ListLayout(rt.Orientation.HORIZONTAL),
        _defense_notch_bar = rt.ListLayout(rt.Orientation.HORIZONTAL),
        _speed_notch_bar = rt.ListLayout(rt.Orientation.HORIZONTAL),
        _activate_state = bt.InventoryMenu._debug_state,
        _input = {}
    }, rt.Widget, rt.Drawable, rt.Animation)

    local notch_separator = function()
        local out = rt.Spacer()
        out:set_minimum_size(rt.settings.margin_unit / 2, 0)
        out:set_expand_horizontally(false)
        out:set_color(rt.Palette.FOREGROUND)
        out:set_show_outline(false, true, false, true)
        return out
    end

    local notch = function()
        return rt.Notch()
    end

    for _, bar in pairs({out._attack_notch_bar, out._defense_notch_bar, out._speed_notch_bar}) do
        for i = 1, 15 do
            if i % 5 == 1 and i > 5 then
                bar:push_back(notch_separator())
            end
            bar:push_back(rt.Notch())
        end
        bar:set_spacing(rt.settings.margin_unit / 2)
    end

    local bar_separator = function()
        local out = rt.Spacer()
        out:set_minimum_size(0, rt.settings.margin_unit )
        out:set_expand_vertically(false)
        out:set_color(rt.Palette.FOREGROUND)
        out:set_show_outline(true, false, true, false)
        return out
    end

    out._notch_vbar:push_back(out._attack_notch_bar)
    --out._notch_vbar:push_back(bar_separator())
    out._notch_vbar:push_back(out._defense_notch_bar)
    --out._notch_vbar:push_back(bar_separator())
    out._notch_vbar:push_back(out._speed_notch_bar)

    out._main:set_child(out._notch_vbar)

    out:_update_from_state(out._debug_state)

    out._input = rt.add_input_controller(out)
    out._input:connect_
    return out
end)

bt.InventoryMenu._debug_state = (function()
    local state = bt.InventoryMenuState("debug")
    state.attack_ev = 7
    state.defense_ev = 1
    state.speed_ev = 15
    return state
end)()


--- @overload
function bt.InventoryMenu:get_top_level_widget()
    return self._main
end

--- @brief [internal]
function bt.InventoryMenu:_update_from_state()

    local state = self._activate_state
    function reset_notch(notch)
        notch:set_color(rt.Palette.GREY_5, rt.Palette.GREY_6)
    end

    local i = 1
    for _, child in pairs(self._attack_notch_bar:get_children()) do
        if meta.isa(child, rt.Notch) then
            if state.attack_ev >= i then
                child:set_color(rt.Palette.ATTACK, rt.Palette.RED_4)
            else
                reset_notch(child)
            end
            i = i + 1
        end
    end

    i = 1
    for _, child in pairs(self._defense_notch_bar:get_children()) do
        if meta.isa(child, rt.Notch) then
            if state.defense_ev >= i then
                child:set_color(rt.Palette.DEFENSE, rt.Palette.BLUE_4)
            else
                reset_notch(child)
            end
            i = i + 1
        end
    end

    i = 1
    for _, child in pairs(self._speed_notch_bar:get_children()) do
        if meta.isa(child, rt.Notch) then
            if state.speed_ev >= i then
                child:set_color(rt.Palette.SPEED, rt.Palette.GREEN_4)
            else
                reset_notch(child)
            end
            i = i + 1
        end
    end

end
