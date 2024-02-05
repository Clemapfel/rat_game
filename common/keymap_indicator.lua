rt.settings.keymap_indicator.input_button_to_sprite_id = {
    [rt.InputButton.A] = "A",
    [rt.InputButton.B] = "B",
    [rt.InputButton.X] = "X",
    [rt.InputButton.Y] = "Y",
    [rt.InputButton.L] = "L",
    [rt.InputButton.R] = "R",
    [rt.InputButton.START] = "plus",
    [rt.InputButton.SELECT] = "minus",
    [rt.InputButton.UP] = "up",
    [rt.InputButton.DOWN] = "down",
    [rt.InputButton.LEFT] = "left",
    [rt.InputButton.RIGHT] = "right"
}

--- @class rt.KeymapIndicator
--- @param button_to_label Table<rt.InputButton, String>
rt.KeymapIndicator = meta.new_type("KeymapIndicator", function(button_to_label)
    local out = meta.new(rt.KeymapIndicator, {
        _box = rt.ListLayout(rt.Orientation.HORIZONTAL),
        _sprites = {},  -- rt.InputButton -> rt.Sprite
        _labels = {},    -- rt.InputButton -> rt.Label
        _backdrop_sprite = {}
    }, rt.Widget, rt.Drawable)

    for button, text in pairs(button_to_label) do
        local sprite = rt.Sprite(out._spritesheet, rt.settings.keymap_indicator.input_button_to_sprite_id[button])
        local label = rt.Label(text)

        out._sprites[button] = sprite
        out._labels[button] = label
        out._box:push_back(sprite)
        out._box:push_back(label)

        sprite:set_expand(false)
        sprite:set_minimum_size(2 * sprite:get_resolution(), 2 * sprite:get_resolution())
        label:set_margin_right(rt.settings.margin_unit)
    end

    return out
end)

rt.KeymapIndicator._spritesheet = rt.Spritesheet("assets/sprites", "controller_buttons")

--- @overload
function rt.KeymapIndicator:get_top_level_widget()
    return self._box
end

--- @brief
function rt.KeymapIndicator:set_label(input_button, label)
    if meta.is_nil(self._sprites[input_button]) then
        self._sprites[input_button] = rt.Sprite(self._spritesheet, rt.settings.keymap_indicator.input_button_to_sprite_id[input_button])
    end

    if meta.is_nil(self._labels[input_button]) then
        self._labels[input_button] = rt.Label(label)
    else
        self._labels[input_button]:set_text(label)
    end

    self:reformat()
end