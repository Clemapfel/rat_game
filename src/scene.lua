--- @class rt.Scene
--- @field env Table mutable environment, contains all variables, scene itself is immutable
--- @field input rt.InputController
rt.Scene = meta.new_type("Scene", function()
    local scene = meta.new(rt.Scene)

    scene.window = rt.WindowLayout()
    scene.skybox = rt.Palette.BACKGROUND --TRUE_MAGENTA
    scene.animation_handler = rt.AnimationHandler()
    scene.animation_timer_handler = rt.AnimationTimerHandler()
    scene.input = rt.add_input_controller(scene.window)
    scene.env = {}
    meta.set_is_mutable(scene, false)
    return scene
end)

rt.Scene.thread_pool = rt.ThreadPool() -- static, shared by all scenes

--- @brief set top-level child
function rt.Scene:set_child(child)
    meta.assert_isa(self, rt.Scene)
    meta.assert_widget(child)
    self.window:set_child(child)
end

--- @overload rt.Drawable.draw
function rt.Scene:draw()
    meta.assert_isa(self, rt.Scene)

    if meta.is_rgba(self.skybox) then
        local bg_color = self.skybox
        love.graphics.setBackgroundColor(bg_color.r, bg_color.g, bg_color.b, bg_color.a)
    end
    self.window:draw()
end

--- @overload rt.Widget.realize
function rt.Scene:realize()
    meta.assert_isa(self, rt.Scene)
    self.window:realize()
    self.window:fit_into(rt.AABB(0, 0, love.graphics.getWidth(), love.graphics.getHeight()))
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

function rt.Scene:_set_property(key, new_value)
    meta.assert_scene(self)
    meta.assert_string(key)
    local properties = getmetatable(self).properties
    if meta.is_nil(properties[key]) then
        rt.error("In Scene:_set_property: scene has no property with name `" .. key .. "`")
    end
    properties[key] = new_value
end

--- @brief
function rt.Scene:set_skybox(color)
    meta.assert_scene(self)

    if meta.is_hsva(color) then
        color = rt.hsva_to_rgba(color)
    end
    meta.assert_rgba(color)
    self:_set_property("skybox", color)
end

--- @brief add variable in scene scope
function rt.Scene:add(key, value)
    meta.assert_scene(self)
    self.env[key] = value
    return value
end

--- @brief list of available scenes
rt.scenes = {} -- string -> rt.Scene

--- @brief currently active scene
rt.current_scene = {}

--- @brief mutable environment of currently active scene
env = {}

--- @brief
function rt.add_scene(name, scene)
    if meta.is_nil(scene) then scene = rt.Scene() end
    meta.assert_scene(scene)
    meta.assert_string(name)

    if not meta.is_nil(rt.scenes[name]) then
        rt.error("In rt.add_scene: scene with ID `" .. name "` already exists")
    end
    rt.scenes[name] = scene

    if not meta.is_scene(rt.current_scene) then
        rt.set_current_scene(name)
    end
    return scene
end

--- @brief
function rt.set_current_scene(name)
    meta.assert_string(name)

    if meta.is_nil(rt.scenes[name]) then
        rt.error("In rt.set_current_scene: no scene with ID `" .. name "` available")
    end

    if meta.is_scene(rt.current_scene) then
        rt.current_scene.thread_pool:restart()
    end

    love.graphics.clear(0, 0, 0, 0)
    rt.current_scene = rt.scenes[name]
    env = rt.current_scene.env
end

