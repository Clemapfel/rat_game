--- @brief check if array textures are available on this device
function assert_array_textures_supported()
    local types = love.graphics.getTextureTypes()
    for _, type in pairs(types) do
        if type == "array" then
            return true
        end
    end

    println("[rt] In assert_array_textures_supported: Array textures for this device unsupported, using fallback")
    return false
end
rt.USE_ARRAY_TEXTURES = assert_array_textures_supported()

--- @class Spritesheet
rt.Spritesheet = meta.new_type("Spritesheet", function(table)
    return meta.new(rt.Spritesheet, table)
end)

rt.Spritesheet.name = ""
rt.Spritesheet.frame_width = -1
rt.Spritesheet.frame_height = -1
rt.Spritesheet.n_frames = 0

--- @brief
function rt.Spritesheet:create(path, id)
    meta.assert_isa(self, rt.Spritesheet)
    meta.assert_string(path, id)

    local config_path = path .. "/" .. id .. ".lua"
    local image_path = path .. "/" .. id .. ".png"
    local error_occurred = false

    local file = love.filesystem.read(config_path)
    local code, error_maybe = load(file)
    if not meta.is_nil(error_maybe) then
        println("[rt] In Spritesheet:create_from_file: Unable to read file at `" .. config_path .. "`: " .. error_maybe)
        error_occurred = true
    end

    local image = rt.Image(image_path)
    local config = code()

    local name = config.name
    meta.assert_string(name)

    local width, height = config.width, config.height
    meta.assert_number(width, height)

    local image_width = image:get_width()
    local n_frames = math.floor(image_width / width)

    if (image_width % width) ~= 0 then
        println("[rt] In Spritesheet:create_from_file: Spritesheet `" .. id .. "` has a width of `" .. tostring(image_width) .. "`, which is not evenly divisble by its frame width `" .. tostring(width) .. "`")
        error_occurred = true
    end

    local animations = config.animations
    if meta.is_nil(animations) then
        animations = {}
        animations[name] = {1, n_frames}
    end

    local frame_to_name = {}
    for id, frames in pairs(animations) do
        if #frames ~= 2 then
            println("[rt] In Spritesheet:create_from_file: Spritesheet `" .. id .. "` has a malformed frame range for animation `" .. id .. "`")
            error_occurred = true
        end
        for i = frames[1], frames[2] do
            frame_to_name[i] = id
        end
    end

    if #frame_to_name ~= n_frames then
        local unnamed = {}
        for i = 1, n_frames do
            if meta.is_nil(frame_to_name[i]) then
                table.insert(unnamed, i)
            end
        end
        println("[rt] In Spritesheet:create_from_file: Spritesheet `" .. id .. "` does not have an animation name assigned for frames `" .. serialize(unnamed) .. "`")
        error_occurred = true
    end

    local out = meta.new(rt.Spritesheet, {
        _config_path = config_path,
        _image_path = image_path,
        _name_to_frame = animations,
        _frame_to_name = frame_to_name,
        _valid = error_occurred,
        _data = image
    })

    out.name = name
    out.frame_width = width
    out.frame_height = height
    out.n_frames = n_frames

    return out
end

--- @brief
function rt.Spritesheet:get_frame(i)
    meta.assert_isa(self, rt.Spritesheet)
    meta.assert_number(i)

    local out = love.graphics.newImageData(self.frame_width, self.frame_height)
    local valid = false
    for x = 0, out:getWidth() do
        for y = 0, out:getHeight() do
            local r, g, b, a = self._data:getPixel(i * self._frame_width + x, y)
            out:setPixel(x, y, r, g, b, a)
        end
    end
    return out
end

--- @brief export spritesheet to folder
function rt.Spritesheet:export(path)
    if not self._valid then
        println("[rt] In Spritesheet:export: Spritesheet `" .. self.name .. "` has had a formatting error and cannot be exported")
    end
end