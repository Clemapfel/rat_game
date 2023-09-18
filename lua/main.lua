-- entry point for JetBrains IDE debugger
function try_connect_emmy_lua_debugger()
    package.cpath = package.cpath .. ';/home/clem/.local/share/JetBrains/CLion2023.2/EmmyLua/debugger/emmy/linux/?.so'
    require('emmy_core').tcpConnect('localhost', 8172)
end
pcall(try_connect_emmy_lua_debugger)

DEBUG_MODE = love == nil
if DEBUG_MODE then
    RESOURCE_PATH = "/home/clem/Workspace/rat_game/lua"
    love = {}
    love.graphics = {}
    love.graphics.getWidth = function() return 1 end
    love.graphics.getHeight = function() return 1 end
    love.graphics.getFont = function() return {} end
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
require "vector"
require "geometry"
require "color"
require "signal_component"
require "drawable"
require "widget"
require "shape"
require "label"
require "keyboard_component"
require "gamepad_component"
require "mouse_component"
require "animation"
require "layout_manager"
require "image"
require "vertex_shape"

-- ### MAIN ###

if DEBUG_MODE then goto exit end

--- @class rt.ImageDisplay
rt.ImageDisplay = meta.new_type("ImageDisplay", function(image)
    local out = meta.new(rt.ImageDisplay, {
        _texture = rt.Texture(image),
        _shape = rt.VertexRectangle(0, 0, 1, 1)
    }, rt.Drawable, rt.Widget)
    --out._shape:set_texture(out._texture)
    out._texture:set_wrap_mode(rt.TextureWrapMode.CLAMP)
    return out
end)

function rt.ImageDisplay:draw()
    meta.assert_isa(self, rt.ImageDisplay)
    self._shape:draw()
end

function rt.ImageDisplay:size_allocate(x, y, width, height)
    meta.assert_isa(self, rt.ImageDisplay)
    self._shape:set_vertex_position(1, x, y)
    self._shape:set_vertex_color(1, rt.HSVA(0, 1, 1, 0.25))

    self._shape:set_vertex_position(2, x + width, y)
    self._shape:set_vertex_color(2, rt.HSVA(0.3, 1, 1, 0.25))

    self._shape:set_vertex_position(3, x + width, y + height)
    self._shape:set_vertex_color(3, rt.HSVA(0.6, 1, 1, 0.25))

    self._shape:set_vertex_position(4, x, y + height)
    self._shape:set_vertex_color(4, rt.HSVA(0.9, 1, 1, 0.25))

    self._shape:set_vertex_order({1, 2, 4, 3})
    self._shape:set_texture_rectangle(rt.AABB(0, 0, 1, 1))
end

display = rt.ImageDisplay(rt.Image("assets/favicon.png"))
display:set_margin_left(40)
display:set_margin_right(50)
display:set_expand_horizontally(false)
display:set_horizontal_alignment(rt.Alignment.START)
display:set_vertical_alignment(rt.Alignment.END)
display:set_minimum_size(50, 50)

--- @brief startup
function love.load()
    love.window.setTitle("rat_game")
    display:fit_into(rt.AABB(1, 1, love.graphics.getWidth()-2, love.graphics.getHeight()-2))
end

--- @brief update tick
function love.update()
    rt.AnimationHandler.update(love.timer.getDelta())
end

--- @brief draw step
function love.draw()

    love.graphics.setColor(1, 1, 1, 1)

    display:draw()
    display:draw_bounds()

    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local line = rt.Line(0.5 * w, 0, 0.5 * w, h)
    line:draw()
    line = rt.Line(0, 0.5 * h, w, 0.5 * h)
    line:draw()

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

if DEBUG_MODE then
    println("done.")
end