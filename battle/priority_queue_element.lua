rt.settings.battle.priority_queue_element = {
    font = rt.settings.font.default,
    thumbnail_size = 32, -- resolution of subimage
    frame_thickness = 5,
    base_color = rt.Palette.GRAY_4,
    frame_color = rt.Palette.GRAY_3,
    corner_radius = 10
}

--- @class bt.PriorityQueueElement
bt.PriorityQueueElement = meta.new_type("PriorityQueueElement", rt.Widget, function(scene, entity)
    return meta.new(bt.PriorityQueueElement, {
        _entity = entity,
        _scene = scene,

        _shape = {}, -- rt.Shape
        _spritesheet = {}, -- rt.SpriteAtlasEntry
        _backdrop = rt.Rectangle(0, 0, 1, 1),
        _frame = rt.Rectangle(0, 0, 1, 1),
        _frame_outline = rt.Rectangle(0, 0, 1, 1),
        _debug_backdrop = rt.Rectangle(0, 0, 1, 1),

        _id_offset_label = {}, -- rt.Glyph
    })
end)

--- @override
function bt.PriorityQueueElement:realize()
    if self._is_realized then return end
    self._is_realized = true

    self._spritesheet = rt.SpriteAtlas:get(self._entity:get_sprite_id())
    self._shape = rt.VertexRectangle(0, 0, 1, 1)
    self._shape:set_texture(self._spritesheet:get_texture())
    self._spritesheet:get_texture():set_wrap_mode(rt.TextureWrapMode.ZERO)
    local frame = self._spritesheet:get_frame(1)
    self._shape:reformat_texture_coordinates(
            frame.x, frame.y,
            frame.x + frame.width, frame.y,
            frame.x + frame.width, frame.y + frame.height,
            frame.x, frame.y + frame.height
    )

    self._backdrop:set_is_outline(false)
    self._frame:set_is_outline(true)
    self._frame_outline:set_is_outline(true)

    self._backdrop:set_color(rt.settings.battle.priority_queue_element.base_color)
    self._frame:set_color(rt.settings.battle.priority_queue_element.frame_color)
    self._frame_outline:set_color(rt.Palette.BACKGROUND)

    for shape in range(self._backdrop, self._frame, self._frame_outline) do
        shape:set_corner_radius(rt.settings.battle.priority_queue_element.corner_radius)
    end

    self._id_offset_label = rt.Glyph(
        rt.settings.battle.priority_queue_element.font,
        self._entity:get_id_offset_suffix(),
        {
            is_outlined = true,
            outline_color = rt.Palette.BLACK,
            font_style = rt.FontStyle.BOLD
        }
    )
end

--- @override
function bt.PriorityQueueElement:size_allocate(x, y, width, height)
    if self._is_realized then
        -- make shape square
        local min = math.min(width, height)
        x = x + (width - min) / 2
        y = y + (height - min) / 2
        width, height = min, min

        self._shape:set_vertex_position(1, x, y)
        self._shape:set_vertex_position(2, x + width, y)
        self._shape:set_vertex_position(3, x + width, y + height)
        self._shape:set_vertex_position(4, x, y + height)

        self._backdrop:resize(x, y, width, height)

        local frame_thickness = rt.settings.battle.priority_queue_element.frame_thickness
        local frame_outline_thickness = math.max(frame_thickness * 1.1, frame_thickness + 2)
        self._frame:set_line_width(frame_thickness)
        self._frame_outline:set_line_width(frame_outline_thickness)

        self._frame:resize(x + frame_thickness / 2, y + frame_thickness / 2, width - frame_thickness , height - frame_thickness )
        self._frame_outline:resize(x + frame_thickness / 2, y + frame_thickness / 2, width - frame_thickness , height - frame_thickness )

        -- align texture

        local frame = self._spritesheet:get_frame(1)
        local frame_x, frame_y, frame_w, frame_h = frame.x, frame.y, frame.width, frame.height
        local frame_res_w, frame_res_h = self._spritesheet:get_frame_size()

        local target_size = rt.settings.battle.priority_queue_element.thumbnail_size
        local current_size = math.min(frame_res_w, frame_res_h)

        -- get n*n sized square in the middle of frame
        local zoom_factor = (target_size / current_size)
        local size_offset_x = (frame_w - (zoom_factor * frame_w)) / 2
        local size_offset_y = (frame_h - (zoom_factor * frame_h)) / 2

        -- translate aligned portion, useful for picking which part of a big sprite is shown
        local origin_x, origin_y = self._spritesheet.origin_x, self._spritesheet.origin_y
        local origin_offset_x, origin_offset_y = (0.5 - (1 - origin_x)) * frame_w, (0.5 - (1 - origin_y)) * frame_h

        if frame_res_w > frame_res_h then
            local x_offset = ((1 - frame_res_h / frame_res_w) * frame_w) / 2
            self._shape:set_vertex_texture_coordinate(1, frame_x + x_offset + size_offset_x + origin_offset_x, frame_y + size_offset_y + origin_offset_y)
            self._shape:set_vertex_texture_coordinate(2, frame_x + frame_w - x_offset - size_offset_x + origin_offset_x, frame_y + size_offset_y + origin_offset_y)
            self._shape:set_vertex_texture_coordinate(3, frame_x + frame_w - x_offset - size_offset_x + origin_offset_x, frame_y + frame_h - size_offset_y + origin_offset_y)
            self._shape:set_vertex_texture_coordinate(4, frame_x + x_offset + size_offset_x + origin_offset_x, frame_y + frame_h - size_offset_y + origin_offset_y)
        else
            local y_offset = ((1 - frame_res_w / frame_res_h) * frame_h) / 2
            self._shape:set_vertex_texture_coordinate(1, frame_x + size_offset_x+ origin_offset_x, frame_y + y_offset + size_offset_y + origin_offset_y)
            self._shape:set_vertex_texture_coordinate(2, frame_x + frame_w - size_offset_x+ origin_offset_x, frame_y + y_offset + size_offset_y + origin_offset_y)
            self._shape:set_vertex_texture_coordinate(3, frame_x + frame_w - size_offset_x+ origin_offset_x, frame_y + frame_h - y_offset - size_offset_y + origin_offset_y)
            self._shape:set_vertex_texture_coordinate(4, frame_x + size_offset_x+ origin_offset_x, frame_y + frame_h - y_offset - size_offset_y + origin_offset_y)
        end
        -- align label
        local label_w, label_h = self._id_offset_label:get_size()
        local label_offset = 0.75
        self._id_offset_label:set_position(
                x + width - label_offset * label_w,
                y + height - label_offset * label_h
        )

        self._debug_backdrop:resize(x, y, width, height)
        self._debug_backdrop:set_is_outline(true)
    end
end

--- @override
function bt.PriorityQueueElement:draw()
    if self._is_realized then
        self._backdrop:draw()
        self._shape:draw()
        self._frame_outline:draw()
        self._frame:draw()
        self._id_offset_label:draw()

        if self._scene:get_debug_draw_enabled() then
            self._debug_backdrop:draw()
        end
    end
end