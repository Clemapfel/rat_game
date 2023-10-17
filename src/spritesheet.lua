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

--- @brief
rt.Spritesheet = meta.new_type("Spritesheet", function(path, id)
    meta.assert_string(path, id)

    local config_path = path .. "/" .. id .. ".lua"
    local image_path = path .. "/" .. id .. ".png"

    for _, path in ipairs({config_path, image_path}) do
        if meta.is_nil(love.filesystem.getInfo(path)) then
            error("[rt] In Spritesheet:create_from_file: file `" .. path .. "` does not exist")
        end
    end

    local file = love.filesystem.read(config_path)
    local code, error_maybe = load(file)
    if not meta.is_nil(error_maybe) then
        error("[rt] In Spritesheet:create_from_file: Unable to read file at `" .. config_path .. "`: " .. error_maybe)
    end

    local image = love.graphics.newImage(image_path)
    local config = code()

    local name = config.name
    meta.assert_string(name)

    local width, height = config.width, config.height
    meta.assert_number(width, height)

    local image_width = image:getWidth()
    local n_frames = math.floor(image_width / width)

    if (image_width % width) ~= 0 then
        error("[rt] In Spritesheet:create_from_file: Spritesheet `" .. id .. "` has a width of `" .. tostring(image_width) .. "`, which is not evenly divisble by its frame width `" .. tostring(width) .. "`")
    end

    local animations = config.animations
    if meta.is_nil(animations) then
        animations = {}
        animations[name] = {1, n_frames}
    end

    local frame_to_name = {}
    for id, frames in pairs(animations) do
        if not (#frames == 2 and meta.is_number(frames[1]) and meta.is_number(frames[1])) then
            error("[rt] In Spritesheet:create_from_file: Spritesheet `" .. id .. "` has a malformed frame range for animation `" .. id .. "`")
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
        error("[rt] In Spritesheet:create_from_file: Spritesheet `" .. id .. "` does not have an animation name assigned for frames `" .. serialize(unnamed) .. "`")
    end

    local out = meta.new(rt.Spritesheet, {
        _config_path = config_path,
        _image_path = image_path,
        _name_to_frame = animations,
        _frame_to_name = frame_to_name,
        _valid = error_occurred,
        _native = image
    }, rt.Texture)

    out.name = name
    out.frame_width = width
    out.frame_height = height
    out.n_frames = n_frames

    out:set_scale_mode(rt.TextureScaleMode.NEAREST)
    out:set_wrap_mode(rt.TextureWrapMode.REPEAT)

    return out
end)

rt.Spritesheet.name = ""
rt.Spritesheet.frame_width = -1
rt.Spritesheet.frame_height = -1
rt.Spritesheet.n_frames = 0

--- @brief index 1-basaed
--- @return rt.AABB
function rt.Spritesheet:get_frame(animation_id_or_index, index_maybe)
    meta.assert_isa(self, rt.Spritesheet)

    local i = 0
    if meta.is_number(animation_id_or_index) then
        meta.assert_nil(index_maybe)
        i = animation_id_or_index

        if i < 1 or i > self.n_frames then
            error("[rt] In rt.Spritesheet:get_frame: index `" .. tostring(i) .. "` is out of range for spritesheet with `" .. tostring(self.n_frames) .. "` frames")
        end
        return rt.AABB((i - 1) / self.n_frames, 0, 1 / self.n_frames, 1)
    else
        meta.assert_string(animation_id_or_index)
        meta.assert_number(index_maybe)

        local id = animation_id_or_index

        local start_end = self._name_to_frame[id]
        if meta.is_nil(start_end) then
            error("[rt] in Spritesheet:get_frame: Spritesheet `" .. self.name .. "` has no animation with id `" .. id .. "`")
        end

        local i = (start_end[1] - 1) + (index_maybe - 1)
        return rt.AABB(i / self.n_frames, 0, 1 / self.n_frames, 1)
    end
end
