 --- @class rt.Scene
--- @field env Table mutable environment, contains all variables, scene itself is immutable
--- @field input rt.InputController
rt.Scene = meta.new_type("Scene", function()
    local scene = meta.new(rt.Scene, {
        env = {},
        window = rt.WindowLayout(),
        skybox = rt.Palette.BACKGROUND,
        elapsed = rt.seconds(0),
        input = {}
    })

    scene.input = rt.add_input_controller(scene.window)
    meta.set_is_mutable(scene, false)
    return scene
end)

--- @brief set top-level child
function rt.Scene:set_child(child)
    self.window:set_child(child)
end

--- @overload rt.Drawable.draw
function rt.Scene:draw()
    self.window:draw()
end

--- @overload rt.Widget.realize
function rt.Scene:realize()
    self.window:realize()
    self.window:fit_into(rt.AABB(0, 0, rt.graphics.get_width(), rt.graphics.get_height()))

    love.window.setMode(rt.graphics.get_width(), rt.graphics.get_height(), {
        resizable = true
    })
    love.window.setTitle("rat_game")
end

--- @brief update all regular handlers
function rt.Scene:update(delta)
    self.animation_handler:update(delta)
    self.animation_timer_handler:update(delta)
    self.thread_pool:update_futures()
end

function rt.Scene:_set_property(key, new_value)
    local properties = getmetatable(self).properties
    if meta.is_nil(properties[key]) then
        rt.error("In Scene:_set_property: scene has no property with name `" .. key .. "`")
    end
    properties[key] = new_value
end

--- @brief
function rt.Scene:set_skybox(color)
    if meta.is_hsva(color) then
        color = rt.hsva_to_rgba(color)
    end

    self:_set_property("skybox", color)
end

--- @brief add variable in scene scope
function rt.Scene:add(key, value)
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
    if meta.is_nil(rt.scenes[name]) then
        rt.error("In rt.set_current_scene: no scene with ID `" .. name "` available")
    end

    if meta.is_scene(rt.current_scene) then
        rt.current_scene.thread_pool:restart()
    end

    rt.graphics.clear(0, 0, 0, 0)
    rt.current_scene = rt.scenes[name]
    env = rt.current_scene.env
end

function rt.Scene:run()
    self.window:realize()
    self.window:fit_into(0, 0, rt.graphics.get_width(), rt.graphics.get_height())
end

