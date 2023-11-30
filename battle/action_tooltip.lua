rt.settings.action_tooltip = {
    effect_prefix = "<b><u>Effect</u></b>: ",
    possible_targets_prefix = "<b>Can Target</b>: ",
    consumable_prefix = "<b>Amount: </b>"
}

function bt.Action:_possible_targets_as_label()
    meta.assert_isa(self, bt.Action)
    local me, enemy, ally = self.can_target_self, self.can_target_enemy, self.can_target_ally

    local function _ally(str)  
        return "<color=ALLY><b>" .. str .. "</b></color>"
    end
    
    local function _enemy(str)  
        return "<color=ENEMY><b>" .. str .. "</b></color>"
    end
    
    local function _me(str)
        return "<color=SELF><b>" .. str .. "</b></color>"
    end
    
    local function _field()
        return "<color=GREY_2><b>" .. " ――― " .. "</b></color>"
    end

    local function _everyone(str)
        return "<color=FIELD><b>" .. str .. "</b></color>"
    end

    if self.targeting_mode == bt.TargetingMode.SINGLE then
        if         me and not ally and not enemy then
            return _me("self")
        elseif     me and     ally and     enemy then
            return _me("self") .. " or " .. _ally("single ally") .. " or " .. _enemy("single enemy")
        elseif     me and     ally and not enemy then
            return _me("self") .. " or " .. _ally("single ally")
        elseif     me and not ally and     enemy then
            return _me("self") .. " or " .. _enemy("single enemy")
        elseif not me and     ally and not enemy then
            return _ally("single ally")
        elseif not me and not ally and     enemy then
            return _enemy("single enemy")
        elseif not me and     ally and     enemy then
            return _ally("single ally") .. " or " .. _enemy("single enemey")
        elseif not me and not ally and not enemy then
            return _field()
        end
    elseif self.targeting_mode == bt.TargetingMode.MULTIPLE then
        if         me and not ally and not enemy then
            return _me("self")
        elseif     me and     ally and     enemy then
            return _everyone("everyone")
        elseif     me and     ally and not enemy then
            return _ally("self and all allies")
        elseif     me and not ally and     enemy then
            return _me("self") .. " and " .. _enemy("all enemies")
        elseif not me and     ally and not enemy then
            return _ally("entire party") .. " except " .. _me("self")
        elseif not me and not ally and     enemy then
            return _enemy("all enemies")
        elseif not me and     ally and     enemy then
            return _everyone("everyone") .. " except " .. _me("self")
        elseif not me and not ally and not enemy then
            return _field()
        end
    end
end

--- @class bt.ActionTooltip
bt.ActionTooltip = meta.new_type("ActionTooltip", function(action)
    meta.assert_isa(action, bt.Action)

    if meta.is_nil(env.action_spritesheet) then
        env.action_spritesheet = rt.Spritesheet("assets/sprites", "orbs")
    end

    local sprite_id = "dusk"
    local sprite_size_x, sprite_size_y = env.action_spritesheet:get_frame_size(sprite_id)
    local out = meta.new(bt.ActionTooltip, {
        _action = action,

        _name_label = rt.Label("<b>" .. action.name .. "</b>"),
        _n_uses_label = {}, -- rt.Label
        _possible_target_label = rt.Label(rt.settings.action_tooltip.possible_targets_prefix .. action:_possible_targets_as_label()),
        _effect_label = rt.Label(rt.settings.action_tooltip.effect_prefix .. action.effect_text .. ""),

        _flavor_text_label = rt.Label(ternary(#action.flavor_text == 0, "", "<color=GREY_2>(" .. action.flavor_text .. ")</color>")),
        _flavor_text_hrule = rt.Spacer(),

        _sprite = rt.Sprite(env.action_spritesheet, sprite_id),
        _sprite_aspect = rt.AspectLayout(sprite_size_x / sprite_size_y),
        _sprite_backdrop = rt.Spacer(),
        _sprite_overlay = rt.OverlayLayout(),
        _sprite_frame = rt.Frame(rt.FrameType.CIRCULAR),

        _name_and_sprite_box = rt.BoxLayout(rt.Orientation.HORIZONTAL),
        _effect_box = rt.BoxLayout(rt.Orientation.VERTICAL),

        _vbox = rt.BoxLayout(rt.Orientation.VERTICAL),
    }, rt.Widget, rt.Drawable)

    out._sprite_overlay:set_base_child(out._sprite_backdrop)

    out._sprite_aspect:set_child(out._sprite)
    out._sprite_overlay:push_overlay(out._sprite_aspect)
    out._sprite_overlay:set_margin(3)
    out._sprite_frame:set_child(out._sprite_overlay)
    out._sprite_frame:set_color(rt.Palette.GREY_4)
    out._sprite_frame:set_thickness(2)

    out._sprite_backdrop:set_color(rt.Palette.GREY_5)

    local consumable_text = ""
    if action.max_n_uses == POSITIVE_INFINITY then
        consumable_text = "infinite"
    else
        if action.is_consumable then
            consumable_text = tostring(action.max_n_uses) .. " left"
        else
            consumable_text = consumable_text .."? / " .. tostring(action.max_n_uses) .. ""
        end
    end

    out._n_uses_label = rt.Label(rt.settings.action_tooltip.consumable_prefix .. consumable_text, rt.settings.font.default_mono)
    
    out._name_label = rt.Label("<b>" .. action.name .. "</b>")
    out._name_label:set_horizontal_alignment(rt.Alignment.START)
    out._name_label:set_margin_horizontal(rt.settings.margin_unit)
    out._name_label:set_expand_horizontally(true)

    out._n_uses_label:set_margin_horizontal(rt.settings.margin_unit)
    out._n_uses_label:set_expand_horizontally(true)

    out._name_and_sprite_box:push_back(out._sprite_frame)
    out._name_and_sprite_box:push_back(out._name_label)
    out._name_and_sprite_box:set_alignment(rt.Alignment.START)
    out._sprite_frame:set_expand_horizontally(false)
    out._name_label:set_expand_horizontally(true)
    out._name_and_sprite_box:set_expand_vertically(false)
    out._name_and_sprite_box:set_expand_horizontally(true)

    out._sprite_frame:set_expand(false)
    out._sprite_frame:set_minimum_size(sprite_size_x * 2, sprite_size_y * 2)

    for _, label in pairs({out._name_label, out._effect_label, out._possible_target_label, out._n_uses_label}) do
        label:set_horizontal_alignment(rt.Alignment.START)
        label:set_margin_left(rt.settings.margin_unit)
    end
    out._effect_label:set_margin_vertical(rt.settings.margin_unit)

    out._effect_label:set_alignment(rt.Alignment.START)
    out._effect_label:set_margin(rt.settings.margin_unit)
    out._effect_label:set_expand_vertically(false)


    out._flavor_text_label:set_margin(rt.settings.margin_unit)
    out._flavor_text_label:set_expand_vertically(false)
    out._flavor_text_label:set_margin_bottom(rt.settings.margin_unit)

    out._flavor_text_hrule:set_color(rt.Palette.FOREGROUND)
    out._flavor_text_hrule:set_expand_vertically(false)
    out._flavor_text_hrule:set_minimum_size(0, 3)

    out._vbox:push_back(out._name_and_sprite_box)
    out._vbox:push_back(out._n_uses_label)
    out._vbox:push_back(out._possible_target_label)
    out._vbox:push_back(out._effect_label)

    return out
end)

--- @brief [internal]
function bt.ActionTooltip:get_top_level_widget()
    return self._vbox
end