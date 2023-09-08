DEBUG_MODE = love == nil
MARGIN_UNIT = 10

if DEBUG_MODE then
    RESOURCE_PATH = "/home/clem/Workspace/rat_game/lua"
    love = {}
else
    RESOURCE_PATH = love.filesystem.getSource()
end

package.path = package.path .. ";" .. RESOURCE_PATH .. "/src/?.lua"
package.path = package.path .. ";" .. RESOURCE_PATH .. "/battle/?.lua"
package.path = package.path .. ";" .. RESOURCE_PATH .. "/?.lua"

rt = {}
rt.test = {}

require "common"
require "meta"
require "queue"
require "geometry"
require "signal_component"
require "allocation_component"
require "keyboard_component"
require "gamepad_component"
require "mouse_component"
require "animation"

rt.Super = meta.new_type("Super", function()
    return meta.new(rt.Super)
end)

function rt.Super.super_method(self)
    println("super")
end

rt.Child = meta.new_type("Child", function()
    local out = meta.new(rt.Child)
    return out
end)

function rt.Child.child_method(self)
    println("child")
end

local instance = rt.Child()
println(meta.isa(instance, "Child"))
println(meta.isa(instance, rt.Child))


-- ### MAIN ###

if DEBUG_MODE then goto exit end

--- @brief startup
function love.load()
    love.window.setTitle("rat_game")
    love.graphics.setFont(love.graphics.newFont(12))
end

--- @brief update tick
function love.update()
    rt.AnimationHandler.update(love.timer.getDelta())
end

--- @brief draw step
function love.draw()

    local text = love.graphics.newText(love.graphics.getFont(), "EEEEEEEE\nEEEEEEE")
    local text_w = text:getWidth()
    local text_h = text:getHeight()

    local x, y, orientation_rad, scale_x, scale_y, origin_offset_x, origin_offset_y, shear_x, shear_y
    x = love.graphics.getWidth() * 0.5 - 0.5 * text_w
    y = love.graphics.getHeight() * 0.5 - 0.5 * text_h

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(text, x, y, orientation_rad, scale_x, scale_y, origin_offset_x, origin_offset_y, shear_x, shear_y)

    love.graphics.line(x, y, x + text_w, y, x + text_w, y + text_h, x, y + text_h)

    local screen_w = love.graphics.getWidth()
    local screen_h = love.graphics.getHeight()

    love.graphics.setColor(1, 0, 1, 1)
    love.graphics.line(0.5 * screen_w, 0, 0.5 * screen_w, screen_h)
    love.graphics.setColor(0, 1, 1, 1)
    love.graphics.line(0, 0.5 * screen_h, screen_w, 0.5 * screen_h)

    function show_fps()
        local text = love.graphics.newText(love.graphics.getFont(), tostring(math.round(love.timer.getFPS())))
        local w, h = text:getWidth(), text:getHeight()
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.draw(text, love.graphics.getWidth() - w, 0)
    end
    show_fps()
end

--- @brief shutdown
function love.quit()
end

::exit::