rt.settings.menu.slot = {
    sprite_path = "menu_icons",
    sprite_ids = {
        [bt.EquipType.WEAPON] = "weapon",
        [bt.EquipType.CLOTHING] = "clothing",
        [bt.EquipType.TRINKET] = "trinket",
        [bt.EquipType.UNKNOWN] = "unknown",
        [bt.Consumable] = "consumable"
    },
    sprite_factor = 3
}

mn.Slot = meta.new_type("Slot", rt.Widget, function(type_sprite_name, type_sprite_index)
    return meta.new(mn.Slot, {
        _type_sprite = rt.Sprite(type_sprite_name, type_sprite_index),
        _type_sprite_opacity = 0.5;
        _item_sprite = {},
        _item = nil,

        _base = rt.Spacer(),
        _base_inlay = rt.Rectangle(0, 0, 1, 1),
        _frame = rt.Frame(),

        _selection_state = bt.SelectionState.INACTIVE
    })
end)

mn.EquipSlot = function(equip)
    local out = mn.Slot(rt.settings.menu.slot.sprite_path, rt.settings.menu.slot.sprite_ids[equip:get_type()])
    if equip ~= nil then out:set_item(equip) end
    return out
end

mn.ConsumableSlot = function(consumable)
    local out = mn.Slot(rt.settings.menu.slot.sprite_path, "consumable")
    if consumable ~= nil then out:set_item(consumable) end
    return out
end

function mn.Slot:set_item(item)
    if item == nil then
        self._item = nil
        self._item_sprite = {}
    else
        self._item = item
        self._item_sprite = rt.Sprite(item:get_sprite_id())

        if self._is_realized == true then
            self._item_sprite:realize()
            self:reformat()
        end
    end
end

--- @override
function mn.Slot:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    self._frame:realize()
    self._base:realize()
    self._frame:set_child(self._base)
    self._base_inlay:set_color(rt.color_darken(self._base:get_color(), 0.15))
    self._base_inlay:set_corner_radius(self._frame:get_corner_radius())
    s
    self._type_sprite:realize()
    self._type_sprite:set_opacity(self._type_sprite_opacity)

    if self._item ~= nil then
        self._item_sprite:realize()
    end

    self:set_selection_state(self._selection_state)
end

--- @override
function mn.Slot:size_allocate(x, y, width, height)
    local sprite_w, sprite_h = self._type_sprite:get_resolution()
    local factor = rt.settings.menu.slot.sprite_factor
    local thickness = self._frame:get_thickness()

    sprite_w = sprite_w * factor
    sprite_h = sprite_h * factor

    local sprite_bounds = rt.AABB(
        x + thickness + 0.5 * width - 0.5 * sprite_w,
        y + thickness + 0.5 * height - 0.5 * sprite_h,
        sprite_w, sprite_h
    )

    local spacing = 0.1 * sprite_w
    self._base_inlay:resize(x + spacing, y + spacing, sprite_w - 2 * spacing, sprite_h - 2 * spacing)

    self._type_sprite:fit_into(sprite_bounds)
    if self._item ~= nil then
        self._item_sprite:fit_into(sprite_bounds)
    end

    self._frame:fit_into(x, y, sprite_w, sprite_w)
end

--- @override
function mn.Slot:draw()
    if self._is_realized ~= true then return end
    self._frame:draw()
    self._base_inlay:draw()
    self._type_sprite:draw()

    if self._item ~= nil then
        self._item_sprite:draw()
    end
end

--- @brief
function mn.Slot:set_selection_state(state)
    if state == bt.SelectionState.SELECTED then
        self._frame:set_color(rt.Palette.SELECTION)
        self:set_opacity(1)
    elseif state == bt.SelectionState.INACTIVE then
        self._frame:set_color(rt.Palette.FOREGROUND)
        self:set_opacity(1)
    elseif state == bt.SelectionState.UNSELECTED then
        self._frame:set_color(rt.Palette.FOREGROUND)
        self:set_opacity(0.5)
    else
        rt.error("In mn.Slot:set_selectionsState: invalid state:`" .. state .. "`")
    end
end

--- @brief
function mn.Slot:set_opacity(alpha)
    self._opacity = alpha
    if self._is_realized then
        self._frame:set_opacity(alpha)
        self._type_sprite:set_opacity(alpha * self._type_sprite_opacity)
        if self._item ~= nil then
            self._item_sprite:set_opacity(alpha)
        end
    end
end