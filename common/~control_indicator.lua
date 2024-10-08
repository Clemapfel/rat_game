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
        _frame = rt.Frame(),
        _opacity = 1,
        _final_width = 1,
        _final_height = 1,

        _snapshot = rt.RenderTexture(1, 1),
        _position_x = 0,
        _position_y = 0,
        _snapshot_offset_x = 0,
        _snapshot_offset_y = 0,
    })
end)

rt.ControlIndicatorButton = meta.new_enum("ControlIndicatorButton", {
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
    L_R = "L_R",
    LEFT_RIGHT = "LEFT_RIGHT",
    UP_DOWN = "UP_DOWN",
    ALL_DIRECTIONS = "ALL_DIRECTIONS",
    ALL_BUTTONS = "ALL_BUTTONS"
})

--- @override
function rt.ControlIndicator:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    self._frame:realize()
    self:create_from(self._layout)
end

--- @brief
function rt.ControlIndicator:create_from(layout)
    rt.savepoint_maybe()

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

        rt.savepoint_maybe()
    end

    self:reformat()
end

--- @override
function rt.ControlIndicator:size_allocate(x, y, width, height)
    self._position_x, self._position_y = x, y
    x, y = 0, 0

    local m = rt.settings.margin_unit * 0.5

    local sprite_scale = rt.settings.control_indicator.sprite_scale
    local current_x, current_y = x + 2 * m, y + m
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
        label_w, label_h = label:measure()
        max_x = math.max(max_x, current_x + sprite_w + label_w + 3 * m)
        max_y = math.max(max_y, current_y + math.max(sprite_h, label_h))

        current_x = current_x + sprite_w + m + label_w + 3 * m
    end

    max_x = clamp(max_x, 0)
    max_y = clamp(max_y, 0)

    local thickness = self._frame:get_thickness()
    self._final_width = max_x - x + 2 * thickness + m
    self._final_height = max_y - y + 2 * thickness

    self._frame:fit_into(x, y, self._final_width, self._final_height)

    self:_update_snapshot()
end

--- @brief
function rt.ControlIndicator:_update_snapshot()
    local offset = 2;
    self._snapshot_offset_x, self._snapshot_offset_y = offset, offset
    self._snapshot = rt.RenderTexture(self._final_width + 2 * offset, self._final_height + 2 * offset)
    self._snapshot:bind_as_render_target()
    rt.graphics.translate(offset, offset)
    self._frame:draw()
    for i = 1, #self._labels do
        local sprite, label = self._sprites[i], self._labels[i]
        sprite:draw()
        label:draw()
    end
    rt.graphics.translate(-offset, -offset)
    self._snapshot:unbind_as_render_target()
end

--- @override
function rt.ControlIndicator:draw()
    local x_offset, y_offset = self._position_x - self._snapshot_offset_x, self._position_y - self._snapshot_offset_y
    rt.graphics.translate(x_offset, y_offset)
    self._snapshot:draw()
    rt.graphics.translate(-x_offset, -y_offset)
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

--- @brief
function rt.ControlIndicator:set_selection_state(state)
    local current = self._frame:get_selection_state()
    if state ~= current then
        self._frame:set_selection_state(state)
        self:_update_snapshot()
    end
end