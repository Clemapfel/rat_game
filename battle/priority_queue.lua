rt.settings.battle.priority_queue = {
    first_element_scale_factor = 1.2,
    scale_speed = 4, -- 1x per second
    element_speed = 500, -- px per second
    sprite_scale = 2
}

--- @class bt.PriorityQueue
bt.PriorityQueue = meta.new_type("PriorityQueue", rt.Widget, rt.Updatable, function(scene)
    return meta.new(bt.PriorityQueue, {
        _order = {}, -- Table<Entity>,
        _entity_id_to_item = {}, -- Table<String, cf. _new_element>
        _render_order = {}, -- Table<Pair<Item, Motion>>
        _selected_item_is = {},
        _unselected_item_is = {},

        _scale_factor = 1,
        _n_consumed = 0,
        _consume_buffer = {},
        _consumed_y_offset = 0
    })
end)

--- @brief [internal]
function bt.PriorityQueue:_element_new(entity)
    local suffix = entity:get_name_suffix()
    local element = {
        entity = entity,
        motions = {},
        multiplicity = 0,
        sprite = rt.Sprite(entity:get_config():get_portrait_sprite_id()),
        move_selection = nil, -- rt.Sprite
        frame = rt.Frame(),
        gradient = rt.VertexRectangle(0, 0, 1, 1),
        id_offset_label = nil,
        snapshot = rt.RenderTexture(),
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

    if entity:get_multiplicity() > 1 then
        element.id_offset_label = rt.Label("<b><o>" .. suffix .. "</o></b>")
    end

    element.frame:set_thickness(rt.settings.frame.thickness + 1)
    element.frame:realize()
    element.sprite:realize()

    if element.id_offset_label ~= nil then
        element.id_offset_label:realize()
    end

    local top_color = rt.RGBA(1, 1, 1, 1)
    local bottom_color = rt.RGBA(0.4, 0.4, 0.4, 1)
    element.gradient:set_vertex_color(1, top_color)
    element.gradient:set_vertex_color(2, top_color)
    element.gradient:set_vertex_color(3, bottom_color)
    element.gradient:set_vertex_color(4, bottom_color)

    local sprite_w, sprite_h = element.sprite:get_resolution()
    local scale = rt.settings.battle.priority_queue.sprite_scale
    sprite_w = sprite_w * scale
    sprite_h = sprite_h * scale
    element.sprite:set_minimum_size(sprite_w, sprite_h)

    element.frame:fit_into(0, 0, sprite_w, sprite_h)
    element.sprite:fit_into(0, 0, sprite_w, sprite_h)

    local frame_w, frame_h = sprite_w + 2 * element.frame:get_thickness(), sprite_h + 2 * element.frame:get_thickness()
    element.gradient:reformat(
        0, 0,
        frame_w, 0,
        frame_w, frame_h,
        0, frame_h
    )

    if element.id_offset_label ~= nil then
        local label_w, label_h = element.id_offset_label:measure()
        element.id_offset_label:fit_into(0, 0.9 * sprite_h)
    end

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
        table.insert(element.motions, rt.SmoothedMotion2D(
            self._bounds.x + 0.5 * self._bounds.width,
            self._bounds.y + 0.5 * self._bounds.height,
            rt.settings.battle.priority_queue.element_speed
        ))
        element.multiplicity = element.multiplicity + 1
    end

    while element.multiplicity > n do
        table.remove(element.motions, element.multiplicity)
        element.multiplicity = element.multiplicity - 1
    end
end

--- @brief [internal]
function bt.PriorityQueue:_element_set_move_selection(element, move)
    if move == nil then
        element.move_selection = nil
        return
    end

    element.move_selection = rt.Sprite(move:get_sprite_id())
    element.move_selection:realize()
    local bounds = element.frame:get_bounds()
    local sprite_w, sprite_h = element.move_selection:get_resolution()
    element.move_selection:set_minimum_size(sprite_w, sprite_h)
    element.move_selection:fit_into(
        1.0 * bounds.width - 0.25 * sprite_w,
        0.5 * bounds.height - 0.25 * sprite_h,
        sprite_w, sprite_h
    )
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

    love.graphics.translate(x, y)
    if element.id_offset_label ~= nil then
        element.id_offset_label:draw()
    end

    if element.move_selection ~= nil then
        element.move_selection:draw()
    end

    love.graphics.pop()
end

--- @brief [internal]
function bt.PriorityQueue:_element_snapshot(element)
    element.snapshot:bind()
    love.graphics.translate(element.padding, element.padding)

    element.frame:draw()
    element.frame:bind_stencil()
    element.sprite:draw()
    element.frame:unbind_stencil()

    if element.selection_state ~= rt.SelectionState.ACTIVE then
        local value = meta.hash(element.frame) % 254 + 1
        rt.graphics.stencil(value, function()
            element.frame:_draw_frame()
        end)
        rt.graphics.set_stencil_test(rt.StencilCompareMode.EQUAL, value)
        rt.graphics.set_blend_mode(rt.BlendMode.MULTIPLY, rt.BlendMode.NORMAL)
        element.gradient:draw()
        rt.graphics.set_stencil_test()
        rt.graphics.set_blend_mode()
        love.graphics.setStencilMode()
    end

    love.graphics.translate(-element.padding, -element.padding)
    element.snapshot:unbind()
end

--- @brief
function bt.PriorityQueue:reorder(new_order)
    if new_order == nil then new_order = {} end

    local old_size = sizeof(self._order)
    local new_size = sizeof(new_order)
    if old_size == new_size then
        local is_same = true
        for i, _ in ipairs(new_order) do
            if self._order[i] ~= new_order[i] then
                is_same = false
                break
            end
        end
        if is_same then return end
    end

    self._order = new_order
    self._scale_elapsed = 1
    self._n_consumed = 0
    self._consumed_y_offset = 0


    local to_remove_ids = {}
    for entity_id in keys(self._entity_id_to_item) do
        to_remove_ids[entity_id] = true
    end

    local entity_id_to_multiplicity = {}
    for entity in values(new_order) do
        local entity_id = entity:get_id()
        to_remove_ids[entity_id] = nil
        local item = self._entity_id_to_item[entity_id]
        if item == nil then
            item = self:_element_new(entity)
            self._entity_id_to_item[entity_id] = item
        end

        if entity_id_to_multiplicity[entity_id] == nil then
            entity_id_to_multiplicity[entity_id] = 1
        else
            entity_id_to_multiplicity[entity_id] = entity_id_to_multiplicity[entity_id] + 1
        end
    end

    for entity_id in keys(to_remove_ids) do
        self._entity_id_to_item[entity_id] = nil
    end

    for entity_id, multiplicity in pairs(entity_id_to_multiplicity) do
        self:_element_set_multiplicity(self._entity_id_to_item[entity_id], multiplicity)
    end

    self:reformat()
end

--- @override
function bt.PriorityQueue:size_allocate(x, y, width, height)
    local first_scale_width_delta, first_scale_height_delta = 0, 0
    if self._order ~= nil and sizeof(self._order) >= 1 then
        local first_scale_factor = rt.settings.battle.priority_queue.first_element_scale_factor
        local first = self._entity_id_to_item[self._order[1]:get_id()]
        first_scale_width_delta = (first.width * first_scale_factor - first.width)
        first_scale_height_delta = (first.height * first_scale_factor - first.height)
    end

    local m = 2 * rt.settings.margin_unit
    local start_x = x + 0.5 * width
    local entity_id_to_multiplicity_offset = {}

    self._render_order = {}
    self._consume_buffer = {}
    local current_x, current_y = start_x, y

    local total_height = 0
    local n_items = 0
    for entity in values(self._order) do
        local item = self._entity_id_to_item[entity:get_id()]
        total_height = total_height + item.height
        n_items = n_items + 1
    end

    local margin = clamp((height - total_height - first_scale_height_delta) / (n_items - 1), NEGATIVE_INFINITY, 0)
    local is_first = true
    for entity in values(self._order) do
        local entity_id = entity:get_id()
        local multiplicity_offset = entity_id_to_multiplicity_offset[entity_id]
        if multiplicity_offset == nil then
            multiplicity_offset = 0
        end

        entity_id_to_multiplicity_offset[entity_id] = multiplicity_offset + 1

        local item = self._entity_id_to_item[entity_id]
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

    self:_update_selection_render_order()
end

--- @override
function bt.PriorityQueue:update(delta)
    for item in values(self._entity_id_to_item) do
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
            local item = self._entity_id_to_item[self._order[item_i]:get_id()]
            self._consumed_y_offset = self._consumed_y_offset - (1 - clamp(buffer.opacity, 0, 1))  * item.height
            buffer.y_offset_added = true
        end
        item_i = item_i + 1
    end

    if sizeof(self._order) >= 1 then
        local first = self._entity_id_to_item[self._order[1]:get_id()]
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

    for which in range( -- draw selected on top of unselected
        self._unselected_item_is,
        self._selected_item_is
    ) do
        for i in values(which) do
            local item, motion = table.unpack(self._render_order[i])
            local x, y = motion:get_position()

            local scale = 1
            if i == #self._render_order then
                scale = first_scale
            end

            local consume_item = self._consume_buffer[i]
            self:_element_draw(item, x, y, scale, consume_item.opacity, consume_item.opacity_offset)
        end
    end
end

--- @brief [internal]
function bt.PriorityQueue:_element_update_state(element)
    element.frame:set_selection_state(element.selection_state)
    element.frame:set_base_color(rt.Palette.BACKGROUND)

    local r, g, b, a = 1, 1, 1, 1
    if element.selection_state == rt.SelectionState.UNSELECTED then
        a = 0.75
    else
        a = 1
    end

    if element.entity_state == bt.EntityState.DEAD then
        r = 0.2
        g, b = r, r
    elseif element.entity_state == bt.EntityState.KNOCKED_OUT then
        r, g, b = 1, 0.5, 0.5
    end

    element.r, element.g, element.b, element.a = r, g, b, a
    self:_element_snapshot(element)
end

--- @brief
function bt.PriorityQueue:_update_selection_render_order()
    self._selected_item_is = {}
    self._unselected_item_is = {}
    local i = 1
    for item_motion in values(self._render_order) do
        local item, motion = table.unpack(item_motion)
        if item.selection_state == rt.SelectionState.ACTIVE then
            table.insert(self._selected_item_is, i)
        else
            table.insert(self._unselected_item_is, i)
        end
        i = i + 1
    end
end

--- @brief
function bt.PriorityQueue:set_selection_state(entity, state)
    local item = self._entity_id_to_item[entity:get_id()]
    if item == nil then
        rt.warning("In bt.PriorityQueue:set_selection_state: entity `" .. entity:get_id() .. "` is not present in queue")
        return
    end

    if item.selection_state ~= state then
        item.selection_state = state
        self:_element_update_state(item)
        self:_update_selection_render_order()
    end
end

--- @brief
function bt.PriorityQueue:reset_selection_state(state)
    for item in values(self._entity_id_to_item) do
        item.selection_state = state
        self:_element_update_state(item)
    end
    self:_update_selection_render_order()
end

--- @override
function bt.PriorityQueue:set_state(entity, state)
    local item = self._entity_id_to_item[entity:get_id()]
    item.entity_state = state
    self:_element_update_state(item)
end

--- @brief
function bt.PriorityQueue:consume_first(n)
    self._n_consumed = self._n_consumed + 1
end

--- @brief
function bt.PriorityQueue:skip()
    for item in values(self._entity_id_to_item) do
        for motion in values(item.motions) do
            motion:skip()
        end
    end
end

--- @brief
function bt.PriorityQueue:get_selection_nodes()
    local nodes = {}
    local is_first = true
    local n = sizeof(self._render_order)
    for i = 1, n do
        local item, motion = table.unpack(self._render_order[i])

        local bounds = item.frame:get_bounds()
        local x, y = motion:get_target_position()
        local thickness = item.frame:get_thickness()
        bounds.x = bounds.x + x - 0.5 * bounds.width + 0.5 * item.padding - thickness
        bounds.y = bounds.y + y + item.padding

        if i == n then
            local factor = rt.settings.battle.priority_queue.first_element_scale_factor
            local before_w = bounds.width
            bounds.width = bounds.width * factor
            bounds.height = bounds.height * factor
            bounds.x = bounds.x - (bounds.width - before_w) + 2 * thickness
        end

        local to_add = rt.SelectionGraphNode(bounds)
        table.insert(nodes, 1, to_add)
    end

    for i = 1, sizeof(nodes) do
        nodes[i].object = self._order[i]
    end

    return nodes
end

--- @brief
function bt.PriorityQueue:set_move_selection(entity, move)
    local element = self._entity_id_to_item[entity:get_id()]
    if element ~= nil then
        self:_element_set_move_selection(element, move)
    end
end
