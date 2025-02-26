function love.conf(settings)
    --settings.graphics.renderers = {"opengl"}
end

_G.DEBUG = false

io.stdout:setvbuf("no") -- makes it so love2d error message is printed to console immediately
if _G.DEBUG then
    pcall(function()
        if love.system.getOS() == "Linux" then
            package.cpath = package.cpath .. ';/home/clem/.local/share/JetBrains/CLion2023.3/EmmyLua/debugger/emmy/linux/?.so'
        else
            package.cpath = package.cpath .. ';C:/Users/cleme/AppData/Roaming/JetBrains/CLion2023.3/plugins/EmmyLua/debugger/emmy/windows/x64/?.dll'
        end
        local dbg = require('emmy_core')
        dbg.tcpConnect('localhost', 8172)

        love.errorhandler = function(msg)
            dbg.breakHere()
            return nil -- exit
        end
    end)
end

require "common.common"
meta = require "meta"
log = require "log"

rt.settings = {}
meta.make_auto_extend(rt.settings, true)



