rt.settings.menu.entity_portraits = {
    frame_thickness = rt.settings.frame.thickness + 1
}

--- @class mn.EntityPortraits
mn.EntityPortraits = meta.new_type("EntityPortraits", rt.Widget, function(entities)
    meta.assert_table(entities)
    return meta.new(mn.EntityPortraits, {
        _entities = which(entities, {}),
        _selected_entity = nil,

        _settings_button = {},

        _items = {}
    })
end)

--- @override
function mn.EntityPortraits:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    local font = rt.Font(80,
        "assets/fonts/DejaVuSans/DejaVuSans-Regular.ttf",
        "assets/fonts/DejaVuSans/DejaVuSans-Bold.ttf",
        "assets/fonts/DejaVuSans/DejaVuSans-Italic.ttf",
        "assets/fonts/DejaVuSans/DejaVuSans-BoldItalic.ttf"
    )

    self._settings_button = {
        frame = rt.Frame(),
        label = rt.Label("<o>\u{2699}</o>", font) -- gear
    }

    self._settings_button.frame:realize()
    self._settings_button.label:realize()

    self:create_from(self._entities)
end

--- @override
function mn.EntityPortraits:size_allocate(x, y, width, height)
    local m = rt.settings.margin_unit
    local current_x, current_y = x, y
    local item_w = width
    local item_h = item_w
    local n_items = sizeof(self._items)
    local item_m = math.min(m, (height - 2 * m - item_h - n_items * item_h) / (n_items + 1))
    for item in values(self._items) do
        local sprite_w, sprite_h = item.sprite:get_resolution()
        sprite_w = sprite_w * 3
        sprite_h = sprite_h * 3

        local frame_thickness = item.frame:get_thickness() + 2
        item.stencil:resize(
            current_x + frame_thickness,
            current_y + frame_thickness,
            item_w - 2 * frame_thickness,
            item_h - 2 * frame_thickness
        )
        item.frame:fit_into(current_x, current_y, item_w, item_h)

        local sprite_align_x, sprite_align_y = item.sprite:get_origin()
        local origin_offset_x, origin_offset_y = (0.5 - sprite_align_x) * sprite_w, (0.5 - sprite_align_y) * sprite_h
        item.sprite:fit_into(
            math.floor(current_x + 0.5 * item_w - 0.5 * sprite_w + origin_offset_x),
            math.floor(current_y + 0.5 * item_h - 0.5 * sprite_h + origin_offset_y),
            sprite_w,
            sprite_h
        )

        current_y = current_y + item_h + item_m
    end

    self:set_selected(self._selected_entity)

    local item = self._settings_button
    local settings_x, settings_y = current_x, y + height - item_h
    item.frame:fit_into(settings_x, settings_y, item_w, item_h)
    local label_w, label_h = item.label:measure()
    item.label:fit_into(settings_x + 0.5 * item_w - 0.5 * label_w, settings_y + 0.5 * item_h - 0.5 * label_h, item_w, item_h)
end

--- @override
function mn.EntityPortraits:draw()
    local item_i = 1
    for item in values(self._items) do
        item.frame:draw()

        local stencil_value = (meta.hash(self) + item_i) % 255
        rt.graphics.stencil(stencil_value, item.stencil)
        rt.graphics.set_stencil_test(rt.StencilCompareMode.EQUAL, stencil_value)
        item.sprite:draw()
        rt.graphics.set_stencil_test()

        item_i = item_i + 1
    end

    self._settings_button.frame:draw()
    self._settings_button.label:draw()
end

--- @brief
function mn.EntityPortraits:create_from(entities)
    self._entities = entities
    self._items = {}
    for entity in values(self._entities) do
        local to_insert = {
            entity = entity,
            sprite = rt.Sprite(entity:get_sprite_id()),
            stencil = rt.Rectangle(),
            frame = rt.Frame()
        }

        to_insert.frame:set_thickness(rt.settings.menu.entity_portraits.frame_thickness)
        to_insert.stencil:set_corner_radius(rt.settings.frame.corner_radius)
        for element in range(to_insert.sprite, to_insert.frame) do
            element:realize()
        end

        table.insert(self._items, to_insert)
    end

    if self._is_realized then self:reformat() end
end

--- @brief
function mn.EntityPortraits:set_selected(entity)
    self._selected_entity = entity
    for item in values(self._items) do
        if item.entity == entity then
            item.frame:set_color(rt.Palette.SELECTION, rt.Palette.GRAY_5)
        else
            item.frame:set_color(rt.Palette.FOREGROUND)
        end
    end
end
