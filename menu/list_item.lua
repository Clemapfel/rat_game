rt.settings.menu.list_item = {
    quantity_right_margin = 4 * rt.settings.margin_unit
}

--- @class
mn.ListItem = meta.new_type("MenuListItem", rt.Widget, function(object, quantity)
    return meta.new(mn.ListItem, {
        _object = object,
        _quantity = quantity,
        _sprite = {}, -- rt.Sprite
        _name_label = {}, -- rt.Label
        _label_stencil = rt.Rectangle(0, 0, 1, 1),
        _quantity_label = {}, -- rt.Label
        _base = rt.Rectangle(0, 0, 1, 1)
    })
end)

--[[
MoveListItem
[ ] Name        Quantity

EquipListItem
[ ] Name        Quantity
gray out based on type

ConsumableListItem
[ ] Name        Quantity
]]--

function mn.ListItem._new_label(text)
    return rt.Label(text, rt.settings.font.default_small, rt.settings.font.default_mono_small)
end

--- @override
function mn.ListItem:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    local new_label = mn.ListItem._new_label
    self._name_label = new_label("<o>" .. self._object:get_name() .. "</o>")

    local quantity = tostring(clamp(self._quantity, 0))
    quantity = string.rep(" ", 3 - #quantity) .. quantity
    self._quantity_label = new_label("<o><mono>" .. quantity .. "</o></mono>")
    self._sprite = rt.Sprite(self._object:get_sprite_id())

    for widget in range(self._sprite, self._name_label, self._quantity_label) do
        widget:realize()
    end

    self._base:set_corner_radius(rt.settings.frame.corner_radius)
    self._base:set_color(rt.Palette.BACKGROUND)
end

--- @override
function mn.ListItem:size_allocate(x, y, width, height)
    local m = rt.settings.margin_unit
    local sprite_w, sprite_h = self._sprite:get_resolution()
    local factor = 1.2
    sprite_w = sprite_w * factor
    sprite_h = sprite_h * factor

    local sprite_x = x
    self._sprite:fit_into(sprite_x, y + 0.5 * height - 0.5 * sprite_h, sprite_w, sprite_h)

    local quantity_w, quantity_h = self._quantity_label:measure()
    local quantity_x = x + width - quantity_w - rt.settings.menu.list_item.quantity_right_margin

    self._quantity_label:fit_into(
        quantity_x,
        y + 0.5 * height - 0.5 * quantity_h,
        POSITIVE_INFINITY,
        sprite_h
    )

    local label_x_left = sprite_x + sprite_w + m
    local label_x_right = quantity_x - m
    local label_max_w = label_x_right - label_x_left
    local label_w, label_h = self._name_label:measure()
    self._name_label:fit_into(
        label_x_left,
        y + 0.5 * height - 0.5 * label_h,
        POSITIVE_INFINITY,
        label_h
    )

    self._label_stencil:resize(label_x_left, y, label_max_w, height)

    local base_h = math.max(sprite_h, label_h, quantity_h)
    self._base:resize(x, y + 0.5 * height - 0.5 * base_h, width, base_h)
end

--- @override
function mn.ListItem:draw()
    self._base:draw()

    local stencil_value = meta.hash(self._name_label)
    rt.graphics.stencil(stencil_value, self._label_stencil)
    rt.graphics.set_stencil_test(rt.StencilCompareMode.EQUAL, stencil_value)
    self._name_label:draw()
    rt.graphics.set_stencil_test()
    rt.graphics.stencil()

    self._sprite:draw()
    self._quantity_label:draw()
end
