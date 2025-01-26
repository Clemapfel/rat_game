rt.settings.battle.animations.turn_start = {
    duration = 4
}

bt.Animation.TURN_START = function(scene, message)
    return bt.Animation.TURN_START_END(scene, true, message)
end

bt.Animation.TURN_END = function(scene, message)
    return bt.Animation.TURN_START_END(scene, false, message)
end

--- @class bt.Animation.TURN_START_END
bt.Animation.TURN_START_END = meta.new_type("TURN_START_END", rt.Animation, function(scene, start_or_end, message)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_boolean(start_or_end)

    local settings = rt.settings.battle.animations.turn_start
    return meta.new(bt.Animation.TURN_START_END, {
        _scene = scene,
        _start_or_end = start_or_end,

        _top = nil,     -- rt.VertexShape
        _center = nil,  -- "
        _bottom = nil,  -- "

        _top_vertex_data = {},
        _center_vertex_data = {},
        _bottom_vertex_data = {},

        _banner_height_animation = rt.TimedAnimation(
            settings.duration, 0, 1,
            rt.InterpolationFunctions.SHELF, 0.8
        ),
        _banner_opacity_animation = rt.TimedAnimation(
            settings.duration, 0, 1,
            rt.InterpolationFunctions.SHELF, 1.0, 20
        ),

        _banner_max_height = 0,
        _banner_aa_height = 0,
        _bounds = nil, -- rt.AABB

        _label = nil, -- rt.Label
        _label_path_animation = rt.TimedAnimation(
            settings.duration, 0, 1,
            rt.InterpolationFunctions.CONTINUOUS_STEP, 2
        ),
        _label_x = 0,
        _label_y = 0,
        _label_path = nil, -- rt.Path

        _screenshot = nil, -- rt.RenderTexture

        _screenshot_top_vertex_data = {},
        _screenshot_top = nil, -- rt.VertexShape

        _screenshot_bottom_vertex_data = {},
        _screenshot_bottom = nil, -- "

        _message = message,
        _message_done = false,
        _message_id = nil
    })
end)

do
    local _start_label = nil
    local _end_label = nil
    local _render_texture = nil

    --- @override
    function bt.Animation.TURN_START_END:start()
        if _start_label == nil or _end_label == nil then
            _start_label = rt.Label(
                "<b><o><wave><outline_color=WHITE><rainbow>" .. rt.Translation.battle.turn_start_label .. "</rainbow></outline_color></wave></o></b>",
                rt.settings.font.default_huge,
                rt.settings.font.default_mono_huge
            )

            _end_label = rt.Label(
                "<b><o><wave>" .. rt.Translation.battle.turn_end_label .. "</wave></o></b>",
                rt.settings.font.default_huge,
                rt.settings.font.default_mono_huge
            )

            for label in range(_start_label, _end_label) do
                label:realize()
                local label_w, label_h = label:measure()
                label:fit_into(-0.5 * label_w, -0.5 * label_h, POSITIVE_INFINITY)
            end
        end

        if self._start_or_end == true then
            self._label = _start_label
        else
            self._label = _end_label
        end
        local label_w, label_h = self._label:measure()

        self._bounds = self._scene:get_bounds()
        if _render_texture == nil or
            _render_texture:get_width() ~= self._bounds.width or
            _render_texture:get_height() ~= self._bounds.height
        then
            _render_texture = rt.RenderTexture(self._bounds.width, self._bounds.height)
        end
        self._screenshot = _render_texture

        local m = rt.settings.margin_unit
        self._banner_max_height = label_h + 2 * m
        self._banner_aa_height = m

        local r, g, b, a = rt.color_unpack(rt.Palette.BLACK)
        self._top_vertex_data = {
            {0, 0,  0, 0, r, g, b, 0},  -- top left
            {0, 0,  0, 0, r, g, b, 0},  -- top right
            {0, 0,  0, 0, r, g, b, 1},  -- bottom right
            {0, 0,  0, 0, r, g, b, 1},  -- bottom left
        }
        self._top = rt.VertexShape(self._top_vertex_data)

        self._center_vertex_data = {
            {0, 0,  0, 0, r, g, b, 1},
            {0, 0,  0, 0, r, g, b, 1},
            {0, 0,  0, 0, r, g, b, 1},
            {0, 0,  0, 0, r, g, b, 1},
        }
        self._center = rt.VertexShape(self._center_vertex_data)

        self._bottom_vertex_data = {
            {0, 0,  0, 0, r, g, b, 1},
            {0, 0,  0, 0, r, g, b, 1},
            {0, 0,  0, 0, r, g, b, 0},
            {0, 0,  0, 0, r, g, b, 0},
        }
        self._bottom = rt.VertexShape(self._bottom_vertex_data)

        self._screenshot_top_vertex_data = {
            {0, 0,  0, 0.0, 1, 1, 1, 1},
            {0, 0,  1, 0.0, 1, 1, 1, 1},
            {0, 0,  1, 0.5, 1, 1, 1, 1},
            {0, 0,  0, 0.5, 1, 1, 1, 1}
        }
        self._screenshot_top = rt.VertexShape(self._screenshot_top_vertex_data)

        self._screenshot_bottom_vertex_data = {
            {0, 0,  0, 0.5, 1, 1, 1, 1},
            {0, 0,  1, 0.5, 1, 1, 1, 1},
            {0, 0,  1, 1.0, 1, 1, 1, 1},
            {0, 0,  0, 1.0, 1, 1, 1, 1}
        }
        self._screenshot_bottom = rt.VertexShape(self._screenshot_bottom_vertex_data)

        for mesh in range(self._screenshot_top, self._screenshot_bottom) do
            mesh:set_texture(self._screenshot)
        end

        local padding = 20
        local label_left_x = self._bounds.x - 0.5 * label_w - padding
        local label_right_x = self._bounds.x + self._bounds.width + 0.5 * label_w + padding
        local label_y = self._bounds.x + 0.5 * self._bounds.height
        if self._start_or_end == true then
            self._label_path = rt.Path(label_left_x, label_y, label_right_x, label_y)
        else
            self._label_path = rt.Path(label_right_x, label_y, label_left_x, label_y)
        end

        self._message_id = self._scene:send_message(self._message, function()
            self._message_done = true
        end)
    end
end

--- @override
function bt.Animation.TURN_START_END:finish()
    self._scene:skip_message(self._message_id)
end

--- @override
function bt.Animation.TURN_START_END:update(delta)
    local is_done = true
    for animation in range(
        self._label_path_animation,
        self._banner_height_animation,
        self._banner_opacity_animation
    ) do
        animation:update(delta)
        is_done = is_done and animation:get_is_done()
    end

    local center_y = self._bounds.y + 0.5 * self._bounds.height
    local left_x = self._bounds.x
    local right_x = self._bounds.x + self._bounds.width

    local banner_value = self._banner_height_animation:get_value()
    local radius = self._banner_max_height * banner_value
    local aa = self._banner_aa_height

    local eps = 0.05
    if banner_value < eps then -- smoothly vanish at start and end of animation
        aa = aa * banner_value
    end

    local data
    local function replace_xy(i, x, y)
        data[i][1] = x
        data[i][2] = y
    end

    data = self._center_vertex_data
    replace_xy(1, left_x, center_y - radius)
    replace_xy(2, right_x, center_y - radius)
    replace_xy(3, right_x, center_y + radius)
    replace_xy(4, left_x, center_y + radius)
    self._center:replace_data(data)

    data = self._top_vertex_data
    replace_xy(1, left_x, center_y - radius - aa)
    replace_xy(2, right_x, center_y - radius - aa)
    replace_xy(3, right_x, center_y - radius)
    replace_xy(4, left_x, center_y - radius)
    self._top:replace_data(data)

    data = self._bottom_vertex_data
    replace_xy(1, left_x, center_y + radius)
    replace_xy(2, right_x, center_y + radius)
    replace_xy(3, right_x, center_y + radius + aa)
    replace_xy(4, left_x, center_y + radius + aa)
    self._bottom:replace_data(data)

    data = self._screenshot_top_vertex_data
    replace_xy(1, left_x, 0)
    replace_xy(2, right_x, 0)
    replace_xy(3, right_x, center_y - radius)
    replace_xy(4, left_x, center_y - radius)
    self._screenshot_top:replace_data(data)

    data = self._screenshot_bottom_vertex_data
    replace_xy(1, left_x, center_y + radius)
    replace_xy(2, right_x, center_y + radius)
    replace_xy(3, right_x, self._bounds.height)
    replace_xy(4, left_x, self._bounds.height)
    self._screenshot_bottom:replace_data(data)

    local opacity = self._banner_opacity_animation:get_value()
    for mesh in range(self._top, self._center, self._bottom) do
        mesh:set_opacity(opacity)
    end

    self._is_visible = false
    self._scene:create_quicksave_screenshot(self._screenshot)
    self._is_visible = true

    self._label:update(delta)
    self._label:set_opacity(opacity)
    self._label_x, self._label_y = self._label_path:at(self._label_path_animation:get_value())
    return is_done and self._message_done
end

--- @override
function bt.Animation.TURN_START_END:draw()
    if self._is_visible ~= true then return end

    self._screenshot_top:draw()
    self._screenshot_bottom:draw()

    self._center:draw()
    self._top:draw()
    self._bottom:draw()

    love.graphics.push()
    love.graphics.translate(self._label_x, self._label_y)
    self._label:draw()
    love.graphics.pop()
end