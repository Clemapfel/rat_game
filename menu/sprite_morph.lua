--[[
marchin squares to get mesh for both sprites
for each vertex in target sprite, get vertex closest in angle to target sprite
]]--

mn.SpriteMorph = meta.new_type("SpriteMorph", rt.Updatable, rt.Widget, function(sprite_texture)
    meta.assert_isa(sprite_texture, rt.Texture)
    return meta.new(mn.SpriteMorph, {
        _sprite_texture = sprite_texture,
        _elapsed = 0,
        _duration = 10
    })
end)

local _marching_squares_shader = nil

function mn.SpriteMorph:realize()
    if self:already_realized() then return end

    -- init question mark texture
    local destination_w, destination_h = self._sprite_texture:get_size()
    local padding = rt.settings.label.outline_offset_padding
    destination_w = destination_w + 2 * padding
    destination_h = destination_h + 2 * padding

    self._from_texture = rt.RenderTexture(destination_w, destination_h, 4, rt.TextureFormat.RGBA8, true)
    self._to_texture = rt.RenderTexture(destination_w, destination_h, 4, rt.TextureFormat.RGBA8, true)

    do
        local text = rt.Label("?", rt.Font(destination_h, "assets/fonts/DejaVuSans/DejaVuSans-Bold.ttf"))
        text:realize()
        text:fit_into(0, 0)
        local text_w, text_h = text:measure()

        love.graphics.push()
        love.graphics.origin()

        self._from_texture:bind()
        text:draw(0.5 * destination_w - 0.5 * text_w, 0.5 * destination_h - 0.5 * text_h)
        self._from_texture:unbind()

        local todo = rt.Label("ß", rt.Font(destination_h, "assets/fonts/DejaVuSans/DejaVuSans-Bold.ttf"))
        todo:realize()
        todo:fit_into(0, 0)
        local todo_w, todo_h = todo:measure()

        self._to_texture:bind()
        todo:draw(0.5 * destination_w - 0.5 * todo_w, 0.5 * destination_h - 0.5 * todo_h)
        self._to_texture:unbind()

        --[[
        self._to_texture:bind()
        self._sprite_texture:draw(padding, padding)
        self._to_texture:unbind()
        ]]--

        love.graphics.pop()
    end
    
    self._construct_paths_shader = rt.ComputeShader("menu/sprite_morph_compute_paths.glsl")
    self._draw_paths_shader = rt.Shader("menu/sprite_morph_draw_paths.glsl")
    
    local path_buffer_format = self._construct_paths_shader:get_buffer_format("path_buffer")
    self._path_buffer_size = destination_w * destination_h;
    self._path_buffer = rt.GraphicsBuffer(path_buffer_format, self._path_buffer_size)

    self._construct_paths_shader:send("from_texture", self._from_texture)
    self._construct_paths_shader:send("to_texture", self._to_texture)
    self._construct_paths_shader:send("path_buffer", self._path_buffer)
    self._construct_paths_shader:dispatch(destination_w / 16, destination_h / 16)
    
    self._draw_paths_shader:send("from_texture", self._from_texture)
    self._draw_paths_shader:send("to_texture", self._to_texture)
    self._draw_paths_shader:send("path_buffer", self._path_buffer)

    self._draw_paths_mesh = rt.VertexRectangle(0, 0, 1, 1)
end

function mn.SpriteMorph:size_allocate(x, y, width, height)
    self._bounds = rt.AABB(x, y, width, height)
end

local mesh_format = {
    { location = 0, name = "VertexPosition", format = "floatvec2" },
}

function mn.SpriteMorph:update(delta)
    self._elapsed = self._elapsed + delta
end

function mn.SpriteMorph:draw()
    love.graphics.translate(self._bounds.x, self._bounds.y)
    self._draw_paths_shader:bind()
    self._draw_paths_mesh:draw_instanced(self._path_buffer_size)
    self._draw_paths_shader:unbind()
end