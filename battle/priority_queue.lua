rt.settings.battle.priority_queue = {
    first_element_scale_factor = 1.5,
    scale_speed = 4, -- 1x per second
}

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

    element.frame:fit_into(0, 0, sprite_w, sprite_h)
    element.sprite:fit_into(0, 0, sprite_w, sprite_h)
    element.gradient:reformat(
        0, 0,
        sprite_w, 0,
        sprite_w, sprite_h,
        0, sprite_h
    )

    local thickness = element.frame:get_thickness()
    element.width = sprite_w + 2 * thickness
    element.height = sprite_h + 2 * thickness

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
function bt.PriorityQueue:_element_draw(element, x, y, scale)
    love.graphics.push()
    love.graphics.translate(-1 * element.width * scale + element.width, 0)
    love.graphics.translate(-0.5 * element.width, 0)
    love.graphics.translate(x, y)
    love.graphics.scale(scale, scale)
    love.graphics.translate(-x, -y)
    element.snapshot:draw(x, y)
    love.graphics.pop()
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
    local first_scale_width_delta, first_scale_height_delta = 0, 0
    if #self._order >= 1 then
        local first_scale_factor = rt.settings.battle.priority_queue.first_element_scale_factor
        local first = self._entity_to_item[self._order[1]]
        first_scale_width_delta = (first.width * first_scale_factor - first.width)
        first_scale_height_delta = (first.height * first_scale_factor - first.height)
    end

    local start_x = x + 0.5 * width + 0.5 * first_scale_width_delta
    local entity_to_multiplicity_offset = {}

    self._render_order = {}
    local current_x, current_y = start_x, y

    local total_height = 0
    local n_items = 0
    for entity in values(self._order) do
        local item = self._entity_to_item[entity]
        total_height = total_height + item.height
        n_items = n_items + 1
    end

    local margin = clamp((height - total_height - first_scale_height_delta) / (n_items - 1), NEGATIVE_INFINITY, 0)

    local is_first = true
    for entity in values(self._order) do
        local multiplicity_offset = entity_to_multiplicity_offset[entity]
        if multiplicity_offset == nil then
            multiplicity_offset = 0
        end

        entity_to_multiplicity_offset[entity] = multiplicity_offset + 1

        local item = self._entity_to_item[entity]
        local motion = item.motions[1 + multiplicity_offset]
        if is_first then
            motion:set_target_position(current_x, current_y)
        else
            motion:set_target_position(current_x, current_y + first_scale_height_delta)
        end

        current_y = current_y + item.height + margin

        table.insert(self._render_order, 1, {item, motion, ternary(is_first, 2, 1)})
        is_first = false
    end
end

--- @override
function bt.PriorityQueue:update(delta)
    for item in values(self._entity_to_item) do
        for motion in values(item.motions) do
            motion:update(delta)
        end

        --[[
        local first_scale = rt.settings.battle.priority_queue.first_element_scale_factor
        local scale_speed = rt.settings.battle.priority_queue.scale_speed
        local target_scale = ternary(item.is_first, first_scale, 1)
        if item.current_scale < target_scale then
            item.current_scale = item.current_scale + scale_speed * delta
            if item.current_scale > target_scale then
                item.current_scale = target_scale
            end
        elseif item.current_scale < target_scale then
            item.current_scale = item.current_scale - scale_speed * delta
            if item.current_scale < target_scale then
                item.current_scale = target_scale
            end
        end
        ]]--
    end
end

--- @override
function bt.PriorityQueue:draw()
    for i, item_motion in ipairs(self._render_order) do
        local item, motion = table.unpack(item_motion)
        local x, y = motion:get_position()

        local scale = 1
        if i == #self._render_order then
            scale = rt.settings.battle.priority_queue.first_element_scale_factor
        end
        self:_element_draw(item, x, y, scale)
    end
end
