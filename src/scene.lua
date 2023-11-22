--- @class rt.Scene
rt.Scene = meta.new_type("Scene", function()

    local scene = meta.new(rt.Scene, rt.Drawable, rt.Widget)

    -- use regular user setters, but retain type info
    local metatable = getmetatable(scene)
    scene.__index = nil
    scene.__newindex = nil

    scene._internal = {
        window = rt.WindowLayout(),
        skybox = rt.Palette.PURPLE
    }
    scene.animation_handler = rt.AnimationHandler()
    scene.animation_timer_handler = rt.AnimationTimerHandler()
    scene.input = rt.add_input_controller(scene)
    return scene
end)

rt.Scene.thread_pool = rt.ThreadPool() -- static, shared by all scenes

--- @brief set top-level child
function rt.Scene:set_child(child)
    meta.assert_isa(self, rt.Scene)
    meta.assert_widget(child)
    self._internal.window:set_child(child)
end

--- @overload rt.Drawable.draw
function rt.Scene:draw()
    meta.assert_isa(self, rt.Scene)

    if meta.is_rgba(self._internal.skybox) then
        local bg_color = self._internal.skybox
        love.graphics.setBackgroundColor(bg_color.r, bg_color.g, bg_color.b, bg_color.a)
    end
    self._internal.window:draw()
end

--- @overload rt.Widget.realize
function rt.Scene:realize()
    meta.assert_isa(self, rt.Scene)
    self._internal.window:realize()
    self._internal.window:fit_into(rt.AABB(0, 0, love.graphics.getWidth(), love.graphics.getHeight()))
end

--- @brief update all regular handlers
function rt.Scene:update(delta)
    meta.assert_scene(self)
    meta.assert_number(delta)

    meta.assert_scene(self)
    self.animation_handler:update(delta)
    self.animation_timer_handler:update(delta)
    self.thread_pool:update_futures()
end

rt.current_scene = rt.Scene()
sc = rt.current_scene


