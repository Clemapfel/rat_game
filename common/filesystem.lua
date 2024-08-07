rt.filesystem = {}

--- @brief get sha256 hash of file
--- @return Number or String if as_string is true
function rt.filesystem.hash(path, as_string)
    as_string = which(as_string, true)
    local data, file = love.filesystem.read(path)
    if meta.is_nil(data) then
        rt.error("In rt.filesystem.hash: file at `" .. path .. "` could not be read")
    end

    if love.getVersion() >= 12 then
        return love.data.hash(ternary(as_string, "string", data), "sha256", data)
    else
        local hash
        hash = love.data.hash("sha256", data)
        if as_string then
            return love.data.encode("string", "hex", hash)
        else
            return love.data.encode("data", "hex", hash)
        end
    end
end

--- @brief
--- @return String, String filename, extension
function rt.filesystem.get_name_and_extension(path)
    return string.match(path, "^.+/(.+)%.(.+)$")
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
