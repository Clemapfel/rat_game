require "include"

local line_offset_increment = 100000

function _replace_includes(str, id_to_path, last_line_offset)
    local includes = {}
    local line_i = 1
    local n_includes = 0
    for line in string.gmatch(str, "([^\n]*)\n") do
        local match_maybe = string.match(line, "^%s*#include%s*\"(.+)\"") -- match #include "<match_maybe>"
        if match_maybe ~= nil then
            table.insert(includes, {
                line = line,
                path = match_maybe,
                line_i = line_i
            })
            n_includes = n_includes + 1
        end
        line_i = line_i + 1
    end

    for include in values(includes) do
        local file = love.filesystem.openFile(include.path, "r")
        last_line_offset = last_line_offset + 1
        id_to_path[last_line_offset] = include.path

        local sub = table.concat({
            "#line ",
            (last_line_offset * line_offset_increment) + 1,
            "\n",
            file:read()
        })
        str = string.gsub(str, include.line, sub)
    end

    if n_includes == 0 then
        return str
    else
        return _replace_includes(str, id_to_path, last_line_offset)
    end
end

function _parse_shader(path, ...)
    local str = love.filesystem.openFile(path, "r"):read()

    local id_to_path = {
        [1] = path
    }
    local last_line_offset = 1

    str = "#line " .. (1 * line_offset_increment + 1) .. "\n" .. str
    str = _replace_includes(str, id_to_path, last_line_offset)
    local success, shader = pcall(love.graphics.newShader, str, ...)
    if not success then
        local error_message = shader
        local line_numbers = {}
        local error_location
        for match in string.gmatch(error_message, "Line%s([0-9]*):") do
            local n = tonumber(match)
            local file_id = math.floor(n / line_offset_increment)
            error_location = id_to_path[file_id]
            error_message = string.gsub(error_message, match, n - file_id * line_offset_increment)
        end
        rt.error("In `" .. error_location .. "`:\n" .. error_message)
    end
    return shader
end

function love.load()
    local shader = _parse_shader("shader_include_main.glsl")
end