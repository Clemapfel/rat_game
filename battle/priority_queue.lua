--- @class bt.PriorityQueue
bt.PriorityQueue = meta.new_type("PriorityQueue", rt.Widget, rt.Animation, function(scene)
    return meta.new(bt.PriorityQueue, {
        _order = {}, -- Table<Entity>,
        _entity_to_item = {}, -- Table<Entity, cf. _new_element>
        _render_order = {}, -- Table<Pair<Item, Motion>>
    })
end)

--- @brief [internal]
function bt.PriorityQueue:_element_new(entity)
    local element = {
        motions = {},
        multiplicity = 0,
        sprite = rt.Sprite(entity:get_portrait_sprite_id()),
        frame = rt.Frame(),
        gradient = rt.VertexRectangle(0, 0, 1, 1),
        id_offset_label = rt.Label(entity:get_id_suffix()),
        snapshot = rt.RenderTexture(1, 1),
        padding = 0,
        width = 0,
        height = 0
    }

    element.frame:realize()
    element.sprite:realize()
    element.frame:set_child(element.sprite)
    element.frame._stencil_mask:set_color(rt.Palette.FOREGROUND_OUTLINE)

    local top_color = rt.RGBA(1, 1, 1, 1)
    local bottom_color = rt.RGBA(0.4, 0.4, 0.4, 1)
    element.gradient:set_vertex_color(1, top_color)
    element.gradient:set_vertex_color(2, top_color)
    element.gradient:set_vertex_color(3, bottom_color)
    element.gradient:set_vertex_color(4, bottom_color)

    local sprite_w, sprite_h = element.sprite:get_resolution()
    local sprite_scale = 2
    sprite_w = sprite_w * 2
    sprite_h = sprite_h * 2
    element.sprite:set_minimum_size(sprite_w, sprite_h)
    element.width = sprite_w
    element.height = sprite_h

    element.frame:fit_into(0, 0, sprite_w, sprite_h)
    element.sprite:fit_into(0, 0, sprite_w, sprite_h)
    element.gradient:reformat(
        0, 0,
        sprite_w, 0,
        sprite_w, sprite_h,
        0, sprite_h
    )

    local padding = element.frame:get_thickness() * 2
    element.padding = padding
    element.snapshot = rt.RenderTexture(sprite_w + 2 * padding, sprite_h + 2 * padding)
    element.snapshot:bind_as_render_target()
    love.graphics.translate(padding, padding)
    element.frame:draw()

    local value = meta.hash(self) % 254 + 1
    rt.graphics.stencil(value, element.frame._frame)
    rt.graphics.set_stencil_test(rt.StencilCompareMode.EQUAL, value)
    rt.graphics.set_blend_mode(rt.BlendMode.MULTIPLY, rt.BlendMode.NORMAL)
    element.gradient:draw()
    rt.graphics.set_stencil_test()
    rt.graphics.set_blend_mode()
    love.graphics.translate(-padding, -padding)
    element.snapshot:unbind_as_render_target()

    return element
end

--- @brief [internal]
function bt.PriorityQueue:_element_set_multiplicity(element, n)
    while element.multiplicity < n do
        table.insert(element.motions, rt.SmoothedMotion2D(0, 0))
        element.multiplicity = element.multiplicity + 1
    end

    while element.multiplicity > n do
        table.remove(element.motions, element.multiplicity)
        element.multiplicity = element.multiplicity - 1
    end
end

--- @brief [internal]
function bt.PriorityQueue:_element_draw(element, x, y)
    love.graphics.translate(-element.padding, -element.padding)
    element.snapshot:draw(x, y)
    love.graphics.translate(element.padding, element.padding)
end

--- @brief
function bt.PriorityQueue:reorder(new_order)
    self._order = new_order

    local to_remove = {}
    for entity in keys(self._entity_to_item) do
        to_remove[entity] = true
    end

    local entity_to_multiplicity = {}

    for entity in values(new_order) do
        to_remove[entity] = nil
        local item = self._entity_to_item[entity]
        if item == nil then
            item = self:_element_new(entity)
            self._entity_to_item[entity] = item
        end

        if entity_to_multiplicity[entity] == nil then
            entity_to_multiplicity[entity] = 1
        else
            entity_to_multiplicity[entity] = entity_to_multiplicity[entity] + 1
        end
    end

    for entity in keys(to_remove) do
        self._entity_to_item[entity] = nil
    end

    for entity, multiplicity in pairs(entity_to_multiplicity) do
        self:_element_set_multiplicity(self._entity_to_item[entity], multiplicity)
    end

    self:reformat()
end

--- @override
function bt.PriorityQueue:size_allocate(x, y, width, height)
    local start_x = x + 0.5 * width
    local entity_to_multiplicity_offset = {}

    self._render_order = {}
    local current_x, current_y = start_x, y
    for entity in values(self._order) do
        local multiplicity_offset = entity_to_multiplicity_offset[entity]
        if multiplicity_offset == nil then
            multiplicity_offset = 0
            entity_to_multiplicity_offset[entity] = multiplicity_offset
        end

        local item = self._entity_to_item[entity]
        local motion = item.motions[1 + multiplicity_offset]
        motion:set_target_position(current_x, current_y)
        current_y = current_y + item.height

        table.insert(self._render_order, {item, motion})
    end
end

--- @override
function bt.PriorityQueue:update(delta)
    for item in values(self._entity_to_item) do
        for motion in values(item.motions) do
            motion:update(delta)
        end
    end
end

--- @override
function bt.PriorityQueue:draw()
    for item_motion in values(self._render_order) do
        local item, motion = table.unpack(item_motion)
        self:_element_draw(item, motion:get_position())
    end
end
