rt.settings.inventory_menu = {
    max_n_evs = 15
}

bt.InventorySortMode = meta.new_enum({
    DEFAULT = "DEFAULT",
    TYPE = "TYPE",
    NAME_ASCENDING = "NAME_ASCENDING",
    NAME_DESCENDING = "NAME_DESCENDING"
})

--- @class bt.InventoryMenuState
bt.InventoryMenuState = meta.new_type("InventoyMenuState", function(entity)
    return meta.new(bt.InventoryMenuState, {
        entity = entity,
        equipment = {},     -- slot (1-based) -> equipment
        inherent = {},      -- 1-based -> bt.Action
        moves = {},         -- 1-based -> bt.Action
        consumables = {},   -- 1-based -> bt.Action
        hp_ev = 0,
        attack_ev = 0,
        defense_ev = 0,
        speed_ev = 0,
    })
end)

--- @class bt.InventoryControlDisplay
bt.InventoryMenu = meta.new_type("InventoryMenu", function(state)

    state = (function()
        local state = bt.InventoryMenuState("debug")
        state.entity = bt.Entity("TEST_ENTITY")
        state.hp_ev = 5
        state.attack_ev = 7
        state.defense_ev = 3
        state.speed_ev = 15
        return state
    end)()

    local font = rt.settings.party_info.spd_font
    local out = meta.new(bt.InventoryMenu, {
        _main = rt.ListLayout(rt.Orientation.VERTICAL),
        _current_state = state,

        _hp_notch_bar = rt.ListLayout(rt.Orientation.HORIZONTAL),
        _attack_notch_bar = rt.ListLayout(rt.Orientation.HORIZONTAL),
        _defense_notch_bar = rt.ListLayout(rt.Orientation.HORIZONTAL),
        _speed_notch_bar = rt.ListLayout(rt.Orientation.HORIZONTAL),

        _hp_base_label = rt.Label("", font),
        _attack_base_label = rt.Label("", font),
        _defense_base_label = rt.Label("", font),
        _speed_base_label = rt.Label("", font),

        _hp_final_label = rt.Label("", font),
        _attack_final_label = rt.Label("", font),
        _defense_final_label = rt.Label("", font),
        _speed_final_label = rt.Label("", font),

        _hp_row = rt.ListLayout(rt.Orientation.HORIZONTAL),
        _attack_row = rt.ListLayout(rt.Orientation.HORIZONTAL),
        _defense_row = rt.ListLayout(rt.Orientation.HORIZONTAL),
        _speed_row = rt.ListLayout(rt.Orientation.HORIZONTAL),

        _input = {}
    }, rt.Widget, rt.Drawable, rt.Animation)

    --- calculate absolute size for all labels
    local label_w, label_h = (function()
        local label = rt.Label("9999", font)
        label:realize()
        return label._default_width, label._default_height
    end)()

    function format_stat_label(label)
        label:set_margin_horizontal(rt.settings.margin_unit)
        label:set_minimum_size(label_w, label_h)
    end

    for _, label in pairs({out._hp_base_label, out._attack_base_label, out._defense_base_label, out._speed_base_label}) do
        label:set_expand_horizontally(false)
        label:set_horizontal_alignment(rt.Alignment.START)
        label:set_justify_mode(rt.JustifyMode.RIGHT)
        format_stat_label(label)
    end

    for _, label in pairs({out._hp_final_label, out._attack_final_label, out._defense_final_label, out._speed_final_label}) do
        label:set_expand_horizontally(false)
        label:set_horizontal_alignment(rt.Alignment.END)
        label:set_justify_mode(rt.JustifyMode.LEFT)
        format_stat_label(label)
    end


    local separator = function()
        local out = rt.Spacer()
        out:set_minimum_size(rt.settings.margin_unit / 2, 0)
        out:set_expand_horizontally(false)
        out:set_color(rt.Palette.FOREGROUND)
        out:set_show_outline(false, true, false, true)
        return out
    end

    local notch = function(column, row)
        local out = rt.Notch()
        meta.install_property(out, "ev_column", column)
        meta.install_property(out, "ev_row", row)
        meta.install_property(out, "input", rt.add_input_controller(out))

        out.input:signal_connect("pressed", function(_, which, self)
            if which == rt.InputButton.A then
                -- TODO update state
            end
        end, out)
        return out
    end

    local j = 1
    for _, bar in pairs({out._hp_notch_bar, out._attack_notch_bar, out._defense_notch_bar, out._speed_notch_bar}) do
        for i = 1, rt.settings.inventory_menu.max_n_evs do
            if i % 5 == 1 and i > 5 then
                bar:push_back(separator())
            end
            bar:push_back(notch(i, j))
        end
        bar:set_spacing(rt.settings.margin_unit / 2)
        j = j + 1
    end

    for _, which in pairs({"hp", "attack", "defense", "speed"}) do
        out["_" .. which .. "_row"]:set_children({
            separator(),
            out["_" .. which .. "_base_label"],
            separator(),
            out["_" .. which .. "_notch_bar"],
            separator(),
            out["_" .. which .. "_final_label"]
        })

        out["_" .. which .. "_notch_bar"]:set_margin_horizontal(rt.settings.margin_unit)
    end

    out._main:set_children({out._hp_row, out._attack_row, out._defense_row, out._speed_row})

    out._input = rt.add_input_controller(out)
    out._input:signal_connect("pressed", function(_, which, self)
        -- TODO
    end, out)


    out:_update_labels()
    out:_update_notches()
    return out
end)


--- @overload
function bt.InventoryMenu:get_top_level_widget()
    return self._main
end

--- @brief [internal]
function bt.InventoryMenu:_update_notches()

    local state = self._current_state
    function reset_notch(notch)
        notch:set_color(rt.Palette.GREY_5, rt.Palette.GREY_6)
    end

    local i = 1
    for _, child in pairs(self._hp_notch_bar:get_children()) do
        if meta.isa(child, rt.Notch) then
            if state.hp_ev >= i then
                child:set_color(rt.Palette.HP, rt.Palette.PURPLE_4)
            else
                reset_notch(child)
            end
            i = i + 1
        end
    end

    i = 1
    for _, child in pairs(self._attack_notch_bar:get_children()) do
        if meta.isa(child, rt.Notch) then
            if state.attack_ev >= i then
                child:set_color(rt.Palette.ATTACK, rt.Palette.RED_3)
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


--- @brief [internal]
function bt.InventoryMenu:_update_labels()
    local prefix = "<o><color="
    local postfix = "</color></o>"
    local state = self._current_state
    self._hp_base_label:set_text(prefix .. "PURPLE_1" .. ">" .. tostring(state.entity.hp_base) .. postfix)
    self._attack_base_label:set_text(prefix .. "ATTACK" .. ">" .. tostring(state.entity.attack_base) .. postfix)
    self._defense_base_label:set_text(prefix .. "DEFENSE" .. ">" .. tostring(state.entity.defense_base) .. postfix)
    self._speed_base_label:set_text(prefix .. "SPEED" .. ">" .. tostring(state.entity.speed_base) .. postfix)

    self._hp_final_label:set_text(prefix .. "HP" .. ">" .. tostring(state.entity:get_hp()) .. postfix)
    self._attack_final_label:set_text(prefix .. "ATTACK" .. ">" .. tostring(state.entity:get_attack()) .. postfix)
    self._defense_final_label:set_text(prefix .. "DEFENSE" .. ">" .. tostring(state.entity:get_defense()) .. postfix)
    self._speed_final_label:set_text(prefix .. "SPEED" .. ">" .. tostring(state.entity:get_speed()) .. postfix)
end