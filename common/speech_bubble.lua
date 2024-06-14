--- @class
rt.SpeechBubble = meta.new_type("SpeechBubble", rt.Widget, function(attachment_point_x, attachment_point_y)
    return meta.new(rt.SpeechBubble, {
        _bubble_base = {},
        _bubble_frame_outline = {},
        _bubble_frame = {},
        _tail_base = {},
        _tail_frame = {},
        _tail_frame_outline = {},

        _color = rt.Palette.FOREGROUND,
        _thickness = rt.settings.frame.thickness,
        _corner_radius = rt.settings.frame.corner_radius,

        _tail_visible = (attachment_point_x ~= nil and attachment_point_y ~= nil),
        _attachment_x = attachment_point_x,
        _attachment_y = attachment_point_y
    })
end)

--- @override
function rt.SpeechBubble:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    local thickness = rt.settings.frame.thickness

    self._bubble_base = rt.Rectangle(0, 0, 1, 1)
    self._bubble_frame = rt.Rectangle(0, 0, 1, 1)
    self._bubble_frame_outline = rt.Rectangle(0, 0, 1, 1)

    self._tail_base = rt.Triangle(0, 0, 1, 1, 0.5, 0.5)
    self._tail_frame = rt.LineStrip(0, 0, 1, 1)
    self._tail_frame_outline = rt.LineStrip(0, 0, 1, 1)

    for base in range(self._bubble_base, self._tail_base) do
        base:set_color(rt.Palette.BASE)
    end

    for frame in range(self._bubble_frame, self._tail_frame) do
        frame:set_is_outline(true)
        frame:set_line_width(self._thickness)
        frame:set_color(self._color)
        frame:set_line_join(rt.LineJoin.BEVEL)
    end

    for outline in range(self._bubble_frame_outline, self._tail_frame_outline) do
        outline:set_is_outline(true)
        outline:set_line_width(self._thickness + 2)
        outline:set_color(rt.Palette.BASE_OUTLINE)
        outline:set_line_join(rt.LineJoin.BEVEL)
    end

    for bubble in range(self._bubble_base, self._bubble_frame, self._bubble_frame_outline) do
        bubble:set_corner_radius(self._corner_radius)
    end
end

--- @override
function rt.SpeechBubble:size_allocate(x, y, width, height)

    local thickness = self._thickness
    local bubble_x, bubble_y = x + thickness, y + thickness
    local bubble_w, bubble_h = width - 2 * thickness, height - 2 * thickness

    self._bubble_base:resize(bubble_x, bubble_y, bubble_w, bubble_h)
    self._bubble_frame:resize(bubble_x, bubble_y, bubble_w, bubble_h)
    self._bubble_frame_outline:resize(bubble_x, bubble_y, bubble_w, bubble_h)

    local center_x, center_y = bubble_x + 0.5 * bubble_w, bubble_y + 0.5 * bubble_h
    local target_x, target_y = self._attachment_x, self._attachment_y
    local angle = rt.angle(target_x - center_x, target_y - center_y)

    local tail_width = 20
    local tail_length = rt.distance(center_x, center_y, target_x, target_y)

    local a_x, a_y = rt.translate_point_by_angle(center_x, center_y, tail_width, angle - rt.degrees_to_radians(90))
    local b_x, b_y = rt.translate_point_by_angle(center_x, center_y, tail_width, angle + rt.degrees_to_radians(90))
    local c_x, c_y = target_x, target_y

    local eps = 0
    local top = {bubble_x, bubble_y + eps, bubble_x + bubble_w, bubble_y + eps}
    local right = {bubble_x + bubble_w - eps, bubble_y, bubble_x + bubble_w - eps, bubble_y + bubble_h}
    local bottom = {bubble_x, bubble_y + bubble_h - eps, bubble_x + bubble_w, bubble_y + bubble_h - eps}
    local left = {bubble_x + eps, bubble_y, bubble_x + eps, bubble_y + bubble_h}

    local min_a_distance = POSITIVE_INFINITY
    local new_a_x, new_a_y = a_x, a_y
    local min_b_distance = POSITIVE_INFINITY
    local new_b_x, new_b_y = b_x, b_y

    for line in range(top, right, bottom, left) do
        local ia_x, ia_y = rt.intersection(a_x, a_y, c_x, c_y, line[1], line[2], line[3], line[4])
        if ia_x ~= nil and ia_y ~= nil then
            local a_distance = rt.distance(ia_x, ia_y, c_x, c_y)
            if a_distance < min_a_distance then
                min_a_distance = a_distance
                new_a_x, new_a_y = ia_x, ia_y
            end
        end

        local ib_x, ib_y = rt.intersection(b_x, b_y, c_x, c_y, line[1], line[2], line[3], line[4])
        if ib_x ~= nil and ib_y ~= nil then
            local b_distance = rt.distance(ib_x, ib_y, c_x, c_y)
            if b_distance < min_b_distance then
                min_b_distance = b_distance
                new_b_x, new_b_y = ib_x, ib_y
            end
        end
    end

    a_x, a_y = new_a_x, new_a_y
    b_x, b_y = new_b_x, new_b_y

    self._tail_base:resize(a_x, a_y, b_x, b_y, c_x, c_y)
    self._tail_frame:resize(a_x, a_y, c_x, c_y, b_x, b_y)

    c_x, c_y = rt.translate_point_by_angle(center_x, center_y, tail_length + 2, angle)
    self._tail_frame_outline:resize(a_x, a_y, c_x, c_y, b_x, b_y)
end

--- @override
function rt.SpeechBubble:draw()
    if self._is_realized ~= true then return end

    self._bubble_base:draw()
    self._bubble_frame_outline:draw()
    self._bubble_frame:draw()

    self._tail_base:draw()
    self._tail_frame_outline:draw()
    self._tail_frame:draw()

    love.graphics.points(self._attachment_x, self._attachment_y)
end

--- @brief
function rt.SpeechBubble:set_attachment_point(x, y)
    self._attachment_x = x
    self._attachment_y = y
    self._tail_visible = (x ~= nil and y ~= nil)
    self:reformat()
end