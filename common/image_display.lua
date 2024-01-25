--- @class rt.ImageDisplay
--- @param image rt.Image
rt.ImageDisplay = meta.new_type("ImageDisplay", function(image)

    if meta.is_string(image) then
        image = rt.Image(image)
    end

    local x, y = image:get_size()

    local out = meta.new(rt.ImageDisplay, {
        _resolution = rt.Vector2(x, y),
        _texture = rt.Texture(image),
        _shape = rt.VertexRectangle(0, 0, 1, 1)
    }, rt.Drawable, rt.Widget)
    out._shape:set_texture(out._texture)
    out._shape:set_texture_rectangle(rt.AABB(0, 0, 1, 1))
    return out
end)

--- @overload rt.Drawable.draw
function rt.ImageDisplay:draw()

    if self:get_is_visible() then
        love.graphics.setColor(1, 1, 1, 1)
        self._shape:draw()
    end
end

--- @overload rt.Widget.size_allocate
function rt.ImageDisplay:size_allocate(x, y, width, height)

    self._shape:set_vertex_position(1, x, y)
    self._shape:set_vertex_position(2, x + width, y)
    self._shape:set_vertex_position(3, x + width, y + height)
    self._shape:set_vertex_position(4, x, y + height)
    self._shape:set_texture_rectangle(rt.AABB(0, 0, 1, 1))
end

--- @brief update texture
--- @param image rt.Image
function rt.ImageDisplay:create_from_image(image)
    self._texture:create_from_image(image)
    local w, h = image:get_size()
    self._resolution = rt.Vector2(w, h)
end

--- @brief test `ImageDisplay`
function rt.test.image_display()
    error("TODO")
end
