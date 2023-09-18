--- @class rt.ImageDisplay
rt.ImageDisplay = meta.new_type("ImageDisplay", function(image)

    if meta.is_string(image) then
        image = rt.Image(image)
    end
    meta.assert_isa(image, rt.Image)

    local out = meta.new(rt.ImageDisplay, {
        _texture = rt.Texture(image),
        _shape = rt.VertexRectangle(0, 0, 1, 1)
    }, rt.Drawable, rt.Widget)
    out._shape:set_texture(out._texture)
    out._shape:set_texture_rectangle(rt.AABB(0, 0, 1, 1))

    local x, y = image:get_size()
    out:set_minimum_size(image:get_size().x, image:get_size().y)
    return out
end)

--- @overload rt.Drawable.draw
function rt.ImageDisplay:draw()
    meta.assert_isa(self, rt.ImageDisplay)
    if self:get_is_visible() then
        self._shape:draw()
    end
end

--- @overload rt.Widget.size_allocate
function rt.ImageDisplay:size_allocate(x, y, width, height)
    meta.assert_isa(self, rt.ImageDisplay)
    self._shape:set_vertex_position(1, x, y)
    self._shape:set_vertex_position(2, x + width, y)
    self._shape:set_vertex_position(3, x + width, y + height)
    self._shape:set_vertex_position(4, x, y + height)

    self._shape:set_vertex_order({1, 2, 4, 3})
    self._shape:set_texture_rectangle(rt.AABB(0, 0, 1, 1))
end

--- @brief update texture
function rt.ImageDisplay:create_from_image(image)
    meta.assert_isa(self, rt.ImageDisplay)
    meta.assert_isa(image, rt.Image)
    self._texture:create_from_image(image)

    local w, h = self:get_minimum_size()
    local new_w, new_h = image:get_size()

    w = math.min(w, new_w)
    w = math.max()
    self:set_minimum_size()
end