rt.settings.battle.priority_queue = {
    first_element_scale_factor = 1.2,
    scale_speed = 4, -- 1x per second
}

--- @class bt.PriorityQueue
bt.PriorityQueue = meta.new_type("PriorityQueue", rt.Widget, rt.Updatable, function(scene)
    return meta.new(bt.PriorityQueue, {
        _order = {}, -- Table<Entity>,
        _entity_to_item = {}, -- Table<Entity, cf. _new_element>
        _render_order = {}, -- Table<Pair<Item, Motion>>
        _scale_factor = 1,
        _n_consumed = 0,
        _consume_buffer = {},
        _consumed_y_offset = 0
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
        height = 0,
        selection_state = rt.SelectionState.INACTIVE,
        entity_state = bt.EntityState.ALIVE,
        r = 1,
        g = 1,
        b = 1,
        a = 1
    }

    element.frame:realize()
    element.sprite:realize()
    element.frame:set_child(element.sprite)

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

    self:_element_update_state(element)
    self:_element_snapshot(element)

    return element
end

--- @brief [internal]
function bt.PriorityQueue:_element_set_multiplicity(element, n)
    while element.multiplicity < n do
        table.insert(element.motions, rt.SmoothedMotion2D(0.5 * rt.graphics.get_width(), 0.5 * rt.graphics.get_height())) --rt.graphics.get_width() + element.width, 0.5 * rt.graphics.get_height()))
        element.multiplicity = element.multiplicity + 1
    end

    while element.multiplicity > n do
        table.remove(element.motions, element.multiplicity)
        element.multiplicity = element.multiplicity - 1
    end
end

--- @brief [internal]
function bt.PriorityQueue:_element_draw(element, x, y, scale, opacity, opacity_offset)
    love.graphics.push()
    love.graphics.setColor(element.r, element.g, element.b, math.min(element.a, opacity))
    love.graphics.translate(opacity_offset, self._consumed_y_offset)
    love.graphics.translate(-0.5 * (element.width + element.padding), 0)
    love.graphics.translate(x + 0.5 * element.width * scale, y)
    love.graphics.scale(scale, scale)
    love.graphics.translate(-(x + 0.5 * element.width * scale), -y)
    love.graphics.draw(element.snapshot._native, x, y)
    love.graphics.pop()
end

--- @brief [internal]
function bt.PriorityQueue:_element_snapshot(element)
    element.snapshot:bind()
    love.graphics.translate(element.padding, element.padding)
    element.frame:draw()

    if element.selection_state ~= rt.SelectionState.ACTIVE then
        local value = meta.hash(self) % 254 + 1
        rt.graphics.stencil(value, element.frame._frame)
        rt.graphics.set_stencil_test(rt.StencilCompareMode.EQUAL, value)
        rt.graphics.set_blend_mode(rt.BlendMode.MULTIPLY, rt.BlendMode.NORMAL)
        element.gradient:draw()
        rt.graphics.set_stencil_test()
        rt.graphics.set_blend_mode()
    end

    love.graphics.translate(-element.padding, -element.padding)
    element.snapshot:unbind()
end

--- @brief
function bt.PriorityQueue:reorder(new_order)
    self._order = new_order
    self._scale_elapsed = 1
    self._n_consumed = 0
    self._consumed_y_offset = 0

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

    local m = 2 * rt.settings.margin_unit
    local start_x = x + 0.5 * width
    local entity_to_multiplicity_offset = {}

    self._render_order = {}
    self._consume_buffer = {}
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
        table.insert(self._consume_buffer, {opacity_offset = 0, opacity = 1, y_offset_added = false})
        is_first = false
    end
end

--- @override
function bt.PriorityQueue:update(delta)
    for item in values(self._entity_to_item) do
        for motion in values(item.motions) do
            motion:update(delta)
        end
    end

    local opacity_speed = 1
    local opacity_offset_speed = 100
    local item_i = 1
    for i = #self._consume_buffer, math.max(#self._consume_buffer - self._n_consumed + 1, 1), -1 do
        -- render_order is backwards, so iterate backwards to update `self._n_consumed` first element
        local buffer = self._consume_buffer[i]
        buffer.opacity = buffer.opacity - opacity_speed * delta
        buffer.opacity_offset = buffer.opacity_offset - opacity_offset_speed * delta

        if buffer.y_offset_added == false and buffer.opacity <= 0 then
            local item = self._entity_to_item[self._order[item_i]]
            self._consumed_y_offset = self._consumed_y_offset - (1 - clamp(buffer.opacity, 0, 1))  * item.height
            buffer.y_offset_added = true
        end
        item_i = item_i + 1
    end

    if #self._order >= 1 then
        local first = self._entity_to_item[self._order[1]]
        if #first.motions > 1 then
            local x, y = first.motions[1]:get_position()
            self._scale_factor = 1 - (y - self._bounds.y) / self._bounds.height
            -- scale animation when moving item towards first
        end
    end
end

--- @override
function bt.PriorityQueue:draw()
    local target_scale = rt.settings.battle.priority_queue.first_element_scale_factor
    local first_scale = clamp(target_scale * self._scale_factor, 1, target_scale)

    for i, item_motion in ipairs(self._render_order) do
        local item, motion = table.unpack(item_motion)
        local x, y = motion:get_position()

        local scale = 1
        if i == #self._render_order then
            scale = first_scale
        end

        local consume_item = self._consume_buffer[i]
        self:_element_draw(item, x, y, scale, consume_item.opacity, consume_item.opacity_offset)
    end
end

--- @brief [internal]
function bt.PriorityQueue:_element_update_state(element)
    element.frame:set_selection_state(element.selection_state)
    element.frame._stencil_mask:set_color(rt.Palette.BACKGROUND)
    self:_element_snapshot(element)

    local r, g, b, a = 1, 1, 1, 1
    if element.selection_state == rt.SelectionState.UNSELECTED then
        a = 0.75
    end

    if element.entity_state == bt.EntityState.DEAD then
        r = 0.2
        g, b = r, r
    elseif element.entity_state == bt.EntityState.KNOCKED_OUT then
        r, g, b = 1, 0.5, 0.5
    end

    element.r, element.g, element.b, element.a = r, g, b, a
end

--- @override
function bt.PriorityQueue:set_selection(selected_entities, should_unselect_others)
    local is_selected = {}
    for entity in values(selected_entities) do is_selected[entity] = true end

    for entity, item in pairs(self._entity_to_item) do
        local before = item.selection_state
        if is_selected[entity] then
            item.selection_state = rt.SelectionState.ACTIVE
        elseif should_unselect_others then
            item.selection_state = rt.SelectionState.UNSELECTED
        else
            item.selection_state = rt.SelectionState.INACTIVE
        end
        if item.selection_state ~= before then
            self:_element_update_state(item)
        end
    end
end

--- @override
function bt.PriorityQueue:set_state(entity, state)
    local item = self._entity_to_item[entity]
    item.entity_state = state
    self:_element_update_state(item)
end

--- @brief
function bt.PriorityQueue:consume_first(n)
    self._n_consumed = self._n_consumed + 1
end