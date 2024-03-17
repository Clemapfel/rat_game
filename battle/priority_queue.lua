rt.settings.battle.priority_queue = {
    font = rt.settings.font.default
}

--- @class bt.PriorityQueueElement
bt.PriorityQueueElement = meta.new_type("PriorityQueueElement", rt.Widget, function(scene, entity)
    return meta.new(bt.PriorityQueueElement, {
        _entity = entity,
        _scene = scene,

        _shape = {}, -- rt.Shape
        _spritesheet = {}, -- rt.SpriteAtlasEntry

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
    local frame = self._spritesheet:get_frame(1)
    self._shape:reformat_texture_coordinates(
        frame.x, frame.y,
        frame.x + frame.width, frame.y,
        frame.x + frame.width, frame.y + frame.height,
        frame.x, frame.y + frame.height
    )

    self._id_offset_label = rt.Glyph(
        rt.settings.battle.priority_queue.font,
        self._entity:get_id_offset_suffix(),
        {
            is_outlined = true,
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



        -- align texture
        -- choose smaller of each site, then align square in the middle of frame position
        local frame = self._spritesheet:get_frame(1)
        local frame_x, frame_y, frame_w, frame_h = frame.x, frame.y, frame.width, frame.height
        local frame_res_w, frame_res_h = self._spritesheet:get_frame_size()

        if frame_res_w > frame_res_h then
            local x_offset = ((1 - frame_res_h / frame_res_w) * frame_w) / 2
            self._shape:set_vertex_texture_coordinate(1, frame_x + x_offset, frame_y)
            self._shape:set_vertex_texture_coordinate(2, frame_x + frame_w - x_offset, frame_y)
            self._shape:set_vertex_texture_coordinate(3, frame_x + frame_w - x_offset, frame_y + frame_h)
            self._shape:set_vertex_texture_coordinate(4, frame_x + x_offset, frame_y + frame_h)
        elseif frame_res_h > frame_res_w then
            local y_offset = ((1 - frame_res_w / frame_res_h) * frame_h) / 2
            self._shape:set_vertex_texture_coordinate(1, frame_x, frame_y + y_offset)
            self._shape:set_vertex_texture_coordinate(2, frame_x + frame_w, frame_y + y_offset)
            self._shape:set_vertex_texture_coordinate(3, frame_x + frame_w, frame_y + frame_h - y_offset)
            self._shape:set_vertex_texture_coordinate(4, frame_x, frame_y + frame_h - y_offset)
        else
            self._shape:set_vertex_texture_coordinate(1, frame_x, frame_y)
            self._shape:set_vertex_texture_coordinate(2, frame_x + frame_w, frame_y)
            self._shape:set_vertex_texture_coordinate(3, frame_x + frame_w, frame_y + frame_h)
            self._shape:set_vertex_texture_coordinate(4, frame_x, frame_y + frame_h)
        end
        -- align label
        local label_w, label_h = self._id_offset_label:get_size()
        local label_offset = 0.75
        self._id_offset_label:set_position(
                x + width - label_offset * label_w,
                y + height - label_offset * label_h
        )
    end
end

--- @override
function bt.PriorityQueueElement:draw()
    if self._is_realized then
        self._shape:draw()
        self._id_offset_label:draw()
    end
end