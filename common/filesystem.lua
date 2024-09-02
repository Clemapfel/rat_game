rt.filesystem = {}

--- @brief
--- @return String, String filename, extension
function rt.filesystem.get_name_and_extension(path)
    local file_pattern = "([^/\\]+)%.([^/\\]+)$"
    local dir_pattern = "([^/\\]+)/?$"

    local file_name, extension = path:match(file_pattern)
    if file_name and extension then
        return file_name, extension
    else
        local dir_name = path:match(dir_pattern)
        return dir_name, nil
    end
end

--- @brief
function rt.filesystem.get_name(path)
    local name, extension = rt.filesystem.get_name_and_extension(path)
    return name
end

--- @brief
function rt.filesystem.get_extension(path)
    local name, extension = rt.filesystem.get_name_and_extension(path)
    return extension
end

--- @brief
function rt.filesystem.exists(path)
    return love.filesystem.getInfo(path) ~= nil
end

--- @brief
function rt.filesystem.is_file(path)
    local info = love.filesystem.getInfo(path)
    if info == nil then return false end
    return info.type == "file"
end

--- @brief
function rt.filesystem.is_directory(path)
    local info = love.filesystem.getInfo(path)
    if info == nil then return false end
    return info.type == "directory"
end
