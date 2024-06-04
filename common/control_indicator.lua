rt.settings.control_indicator = {
    spritesheet_id = "controller_buttons",
    sprite_scale = 2
}

--- @class rt.ControlIndicator
--- @param layout Table<Pair<rt.ControlIndicatorButton, String>>
rt.ControlIndicator = meta.new_type("ControlIndicator", rt.Widget, function(layout)
    return meta.new(rt.ControlIndicator, {
        _layout = which(layout, {}),
        _sprites = {},
        _labels = {},
        _opacity = 1,
        _final_width = 1,
        _final_height = 1
    })
end)

rt.ControlIndicatorButton = meta.new_enum({
    A = "A",
    B = "B",
    X = "X",
    Y = "Y",
    UP = "UP",
    RIGHT = "RIGHT",
    DOWN = "DOWN",
    LEFT = "LEFT",
    START = "START",
    SELECT = "SELECT",
    L = "L",
    R = "R",
    ALL_DIRECTIONS = "ALL_DIRECTIONS",
    ALL_BUTTONS = "ALL_BUTTONS"
})

--- @override
function rt.ControlIndicator:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    self:create_from(self._layout)
end

--- @brief
function rt.ControlIndicator:create_from(layout)
    self._layout = layout
    local spritesheet_id = rt.settings.control_indicator.spritesheet_id
    self._sprites = {}
    self._labels = {}

    for pair in values(self._layout) do
        local button, text = pair[1], pair[2]
        local sprite = rt.Sprite(spritesheet_id)
        sprite:set_animation(button)
        sprite:realize()
        table.insert(self._sprites, sprite)

        local label = rt.Label(text, rt.settings.font.default_small, rt.settings.font.default_mono_small)
        label:realize()
        table.insert(self._labels, label)

        sprite:set_opacity(self._opacity)
        label:set_opacity(self._opacity)
    end

    self:reformat()
end

--- @override
function rt.ControlIndicator:size_allocate(x, y, width, height)
    local m = rt.settings.margin_unit * 0.5
    local sprite_scale = rt.settings.control_indicator.sprite_scale
    local current_x, current_y = x + m, y + m
    local max_x, max_y = NEGATIVE_INFINITY, NEGATIVE_INFINITY
    for i = 1, #self._labels do
        local sprite, label = self._sprites[i], self._labels[i]

        local sprite_w, sprite_h = sprite:measure()
        sprite_w = sprite_w * sprite_scale
        sprite_h = sprite_h * sprite_scale
        sprite:fit_into(current_x, current_y, sprite_w, sprite_h)

        local label_w, label_h = label:measure()
        label:fit_into(current_x + sprite_w + m, current_y + 0.5 * math.max(sprite_h, label_h) - 0.5 * math.min(sprite_h, label_h), POSITIVE_INFINITY, label_h)

        --current_y = current_y + math.max(sprite_h, label_h)
        current_x = current_x + sprite_w + m + label_w + 3 * m

        label_w, label_h = label:measure()
        max_x = math.max(max_x, current_x + sprite_w + m + label_w)
        max_y = math.max(max_y, current_y + math.max(sprite_h, label_h))
    end

    self._final_width = max_x - x
    self._final_height = max_y - y
end

--- @override
function rt.ControlIndicator:draw()
    for i = 1, #self._labels do
        local sprite, label = self._sprites[i], self._labels[i]
        sprite:draw()
        label:draw()
    end
end

--- @override
function rt.ControlIndicator:set_opacity(alpha)
    self._opacity = alpha
    for i = 1, #self._labels do
        local sprite, label = self._sprites[i], self._labels[i]
        sprite:set_opacity(alpha)
        label:set_opacity(alpha)
    end
end

--- @override
function rt.ControlIndicator:measure()
    return self._final_width, self._final_height
end