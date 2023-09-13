DEBUG_MODE = love == nil
MARGIN_UNIT = 10

if DEBUG_MODE then
    RESOURCE_PATH = "/home/clem/Workspace/rat_game/lua"
    love = {}
    love.graphics = {}
    love.graphics.getWidth = function() return 1 end
    love.graphics.getHeight = function() return 1 end
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
require "color"
require "drawable"
require "shape"
require "label"
require "signal_component"
require "keyboard_component"
require "gamepad_component"
require "mouse_component"
require "animation"
require "allocation_component"
require "layout_manager"

-- ### MAIN ###

if DEBUG_MODE then goto exit end

--- @brief startup
function love.load()
    love.window.setTitle("rat_game")
    rt.Font.DEFAULT = rt.load_font("Roboto", "assets/Roboto")
end

--- @brief update tick
function love.update()
    rt.AnimationHandler.update(love.timer.getDelta())
end

--- @brief draw step
function love.draw()

    local regular = rt.Glyph(rt.Font.DEFAULT, "regular", rt.FontStyle.REGULAR)
    local italic = rt.Glyph(rt.Font.DEFAULT, "italic", rt.FontStyle.ITALIC)
    local bold = rt.Glyph(rt.Font.DEFAULT, "bold", rt.FontStyle.BOLD)
    local bold_italic = rt.Glyph(rt.Font.DEFAULT, "bold_italic", rt.FontStyle.BOLD_ITALIC)

    bold:set_color(rt.RGBA(1, 0, 1, 1))

    regular:draw()
    italic:draw()
    bold:draw()
    bold_italic:draw()

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