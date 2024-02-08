rt.filesystem = {}

--- @brief get sha256 hash of file
---
--- @return Number or String if as_string is true
function rt.filesystem.hash(path, as_string)
    as_string = which(as_string, true)
    local data, file = love.filesystem.read(path)
    if meta.is_nil(data) then
        rt.error("In rt.filesystem.hash: file at `" .. path .. "` could not be read")
    end

    local hash = love.data.hash("sha256", data)
    if as_string then
        return love.data.encode("string", "hex", hash)
    else
        return love.data.encode("data", "hex", hash)
    end
end
