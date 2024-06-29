rt.settings.menu.slot = {
    sprite_path = "menu_icons",
    sprite_ids = {
        [bt.EquipType.WEAPON] = "weapon",
        [bt.EquipType.UNISEX_CLOTHING] = "clothing",
        [bt.EquipType.MALE_CLOTHING] = "clothing",
        [bt.EquipType.FEMALE_CLOTHING] = "clothing",
        [bt.EquipType.TRINKET] = "trinket",
        [bt.EquipType.UNKNOWN] = "unknown",
        [bt.Consumable] = "consumable"
    },
    sprite_factor = 3
}

mn.Slot = meta.new_type("Slot", rt.Widget, function(type_label, frame_type)
    return meta.new(mn.Slot, {
        _type_label = rt.Label(type_label, rt.settings.font.default_tiny, rt.settings.font.default_mono_tiny),
        _type_label_stencil = rt.Rectangle(0, 0, 1, 1),

        _item_sprite = {},
        _item = nil,

        _base_inlay = {},
        _frame = rt.Frame(frame_type),

        _selection_state = bt.SelectionState.INACTIVE
    })
end)

mn.EquipSlot = function(type, equip)
    meta.assert_enum(type, bt.EquipType)
    local label = ""
    if type == bt.EquipType.TRINKET then
        label = "Trinket"
    elseif type == bt.EquipType.CONSUMABLE then
        label = "Consumable"
    elseif type == bt.EquipType.WEAPON then
        label = "Weapon"
    else
        label = "Unknown"
    end

    label = "<o>" .. label .. "</o>"

    local out = mn.Slot(label, rt.FrameType.RECTANGULAR)
    if equip ~= nil then out:set_item(equip) end
    return out
end

mn.ConsumableSlot = function(consumable)
    local out = mn.Slot("<o>Consumable</o>", rt.FrameType.CIRCULAR)
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

    if self._frame:get_type() == rt.FrameType.RECTANGULAR then
        self._base_inlay = rt.Rectangle(0, 0, 1, 1)
        self._base_inlay:set_corner_radius(self._frame:get_corner_radius())
    else
        self._base_inlay = rt.Circle(0, 0, 1)
    end
    self._base_inlay:set_color(rt.color_darken(rt.Palette.BACKGROUND, 0.05))

    self._type_label:realize()

    if self._item ~= nil then
        self._item_sprite:realize()
    end

    self:set_selection_state(self._selection_state)
end

--- @override
function mn.Slot:size_allocate(x, y, width, height)
    local sprite_w, sprite_h = 32, 32
    local factor = rt.settings.menu.slot.sprite_factor
    local thickness = 0--

    sprite_w = sprite_w * factor
    sprite_h = sprite_h * factor

    local sprite_bounds = rt.AABB(
        x + thickness,
        y + thickness,
        sprite_w, sprite_h
    )

    local spacing = 0.1 * sprite_w
    if self._frame:get_type() == rt.FrameType.RECTANGULAR then
        self._base_inlay:resize(x + spacing, y + spacing, sprite_w - 2 * spacing, sprite_h - 2 * spacing)
    else
        self._base_inlay:resize(x + 0.5 * sprite_w, y + 0.5 * sprite_h, (sprite_w - 2 * spacing) / 2)
    end

    if self._item ~= nil then
        self._item_sprite:fit_into(sprite_bounds.x + 0.5 * sprite_bounds.width - 0.5 * sprite_w, sprite_bounds.y + 0.5 * sprite_bounds.height - 0.5 * sprite_h, sprite_w, sprite_h)
    end

    self._frame:fit_into(x, y, sprite_w, sprite_w)

    local label_w, label_h = self._type_label:measure()
    local label_x, label_y = x + 0.5 * sprite_w - 0.5 * label_w, y + sprite_h - self._frame:get_thickness() - label_h - 2
    self._type_label:fit_into(label_x, label_y, sprite_w, sprite_h)
    local padding = 50
    self._type_label_stencil:resize(label_x - padding, label_y - padding, label_w + 2 * padding, label_h + 2 * padding)
end

--- @override
function mn.Slot:draw()
    if self._is_realized ~= true then return end
    self._frame:draw()
    self._base_inlay:draw()
    self._type_label:draw()

    if self._item ~= nil then
        self._item_sprite:draw()
        self._item_sprite:draw_bounds()
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
        if self._item ~= nil then
            self._item_sprite:set_opacity(alpha)
        end
    end
end

--- @override
function mn.Slot:measure()
    local sprite_w, sprite_h = 32, 32
    local factor = rt.settings.menu.slot.sprite_factor
    return sprite_w * factor, sprite_h * factor
end