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
        local frame_w, frame_h = self._spritesheet:get_frame_size()
        local res = 25
        local res_w, res_h = (1 - res / frame_w) / 2, (1 - res / frame_h) / 2
        if frame_w > frame_h then
            local offset = (1 - (frame_h / frame_w)) / 2
            self._shape:set_vertex_texture_coordinate(1, offset, 0)
            self._shape:set_vertex_texture_coordinate(2, 1 - offset, 0)
            self._shape:set_vertex_texture_coordinate(3, 1 - offset, 1)
            self._shape:set_vertex_texture_coordinate(4, offset, 1)
        elseif frame_h > frame_w then
            local offset = (1 - (frame_w / frame_h)) / 2
            self._shape:set_vertex_texture_coordinate(1, 0, offset)
            self._shape:set_vertex_texture_coordinate(2, 1, offset)
            self._shape:set_vertex_texture_coordinate(3, 1, 1 - offset)
            self._shape:set_vertex_texture_coordinate(4, 0, 1 - offset)
        else
            self._shape:set_vertex_texture_coordinate(1, 0, 0)
            self._shape:set_vertex_texture_coordinate(2, 1, 0)
            self._shape:set_vertex_texture_coordinate(3, 1, 1)
            self._shape:set_vertex_texture_coordinate(4, 0, 1)
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