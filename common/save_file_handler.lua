rt.settings.save_file_handler = {
    autosave_frequency = 30, -- seconds
    save_directory_name = "appdata/saves/",
}

--- @class rt.SaveFileHandler
rt.SaveFileHandler = meta.new_type("SaveFileHandler", function()
    local out = meta.new(rt.SaveFileHandler, {
        _elapsed = 0,
        _folders_initialized = false
    })

    if love.filesystem.mountFullPath(love.filesystem.getSource() .. "/appdata", "appdata", "readwrite", true) == false then
        rt.error("In rt.SaveFileHandler: unable to mount file at `" .. love.filesystem.getSource() .. "/appdata" .. "`, using `" .. love.filesystem.getAppdataDirectory() .. "` instead")
    end
    return out
end)

--- @brief
function rt.SaveFileHandler:update(delta)
    self._elapsed = self._elapsed + delta
    if self._elapsed > rt.settings.save_file_handler.autosave_frequency then
        self:save()
        self._elapsed = 0
    end
end

--- @brief
function rt.SaveFileHandler:_initialize_folders()
    local name = rt.settings.save_file_handler.save_directory_name
    local exists = love.filesystem.getInfo(name)
    if exists == nil then
        love.filesystem.createDirectory(name)
    end
end

--- @brief
function rt.SaveFileHandler._hash(data, id)
    local data_hash = love.data.encode("string", "hex", love.data.hash("data", "sha256", data))
    local id_hash = love.data.encode("string", "hex", love.data.hash("data", "sha256", id))

    local final_hash = {}
    for i = 1, 64 do
        table.insert(final_hash, string.sub(data_hash, i, i))
        table.insert(final_hash, string.sub(id_hash, i, i))
    end
    return table.concat(final_hash)
end

--- @brief
function rt.SaveFileHandler:_format_file_name()
    return os.time() .. "_" .. os.date("%y%m%d_%H%M%S")
end

-- @brief
function rt.SaveFileHandler:save(data)
    self:_initialize_folders()

    local prefix = rt.settings.save_file_handler.save_directory_name
    local file_name = self:_format_file_name()

    local data = "return " .. serialize(data)
    local save_file_path = prefix .. file_name .. ".save"
    local save_file = love.filesystem.openFile(save_file_path, "w")
    if save_file == nil then
        rt.warning("In rt.SaveFileHandler.save: error when trying to create file `" .. save_file_path .. "`")
        return
    end

    local save_success, save_error = save_file:write(data)
    if save_success ~= true then
        rt.warning("In rt.SaveFileHandler.save: error when trying to write to `" .. save_file_path .. "`: " .. save_error)
        return
    end

    save_file:flush()
    save_file:close()

    local hash = self._hash(data, file_name)
    local hash_file_path = prefix .. file_name .. ".hash"
    local hash_file = love.filesystem.openFile(hash_file_path, "w")
    if hash_file == nil then
        rt.warning("In rt.SaveFileHandler.save: error when trying to create file `" .. hash_file_path .. "`")
        return
    end

    local hash_success, hash_error = hash_file:write(hash)
    if hash_success ~= true then
        rt.warning("In save_file_thread: error when trying to write to `" .. hash_file_path .. "`: " .. hash_error)
        return
    end

    hash_file:flush()
    hash_file:close()

    rt.log("succesfully created save file `" .. save_file_path .. "`")
end

--- @brief
function rt.SaveFileHandler:load(id)
    local prefix = rt.settings.save_file_handler.save_directory_name
    if id == nil then
        id = ""
        for item in values(love.filesystem.getDirectoryItems(rt.settings.save_file_handler.save_directory_name)) do
            if item > id and string.match(item, "^[0-9_]+$") ~= nil then -- assert valid save file name
                id = item
            end
        end

        if id == "" then
            rt.warning("In rt.SaveFileHandler.load: `id` unspecified, and folder at `" .. prefix .. "` contains no save files")
            return
        end

        id = string.match(id, "^[^.]+")
    end

    local save_file_path = prefix .. id .. ".save"
    local hash_file_path = prefix .. id .. ".hash"

    if rt.filesystem.exists(save_file_path) ~= true then
        rt.warning("In rt.SaveFileHandler.load: unable to read file at `" .. save_file_path .. "`, does not exist")
        return
    end

    if rt.filesystem.exists(hash_file_path) ~= true then
        rt.warning("In rt.SaveFileHandler.load: unable to read file at `" .. hash_file_path .. "`, does not exist")
        return
    end

    local data = love.filesystem.read(save_file_path)
    local true_hash = love.filesystem.read(hash_file_path)
    local hash = self._hash(data, id)

    if #true_hash ~= 128 then
        rt.warning("In rt.SaveFileHandler.load: unable to read file at `" .. hash_file_path .. "`, hash malformed, has `" .. #true_hash .. "` characters")
        return
    end

    -- verify integrity
    if hash ~= true_hash then
        rt.warning("In rt.SaveFileHandler.load: unable to read file at `" .. save_file_path .. "`, mismatched hash, the file may have been edited or otherwise corrupted")
        return
    end

    local chunk, error_maybe = load(data)
    if error_maybe ~= nil then
        rt.warning("In rt.SaveFileHandler.load: unable to parse file at `" .. save_file_path "`: " .. error_maybe)
        return
    end

    rt.log("succesfully loaded file `" .. save_file_path .. "`")
end