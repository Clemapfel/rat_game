--- @class rt.Spritesheet
--- @param path String path prefix, not absolute path
--- @param id String spritsheet ID, expects <ID>.png and <ID>.lua to be in `path`
rt.Spritesheet = meta.new_type("Spritesheet", rt.Texture, function(path, id)
    local config_path = path .. "/" .. id .. ".lua"
    local image_path = path .. "/" .. id .. ".png"

    for path in range(config_path, image_path) do
        if meta.is_nil(love.filesystem.getInfo(path)) then
            rt.error("In Spritesheet:create_from_file: file `" .. path .. "` does not exist")
        end
    end

    local file = love.filesystem.read(config_path)
    local code, error_maybe = load(file)
    if not meta.is_nil(error_maybe) then
        rt.error("In Spritesheet:create_from_file: Unable to read file at `" .. config_path .. "`: " .. error_maybe)
    end

    local image = love.graphics.newImage(image_path)
    local config = code()

    local name = config.name
    local width, height = config.width, config.height

    local fps = config.fps
    if meta.is_nil(fps) then fps = 24 end

    local image_width = image:getWidth()
    local n_frames = math.floor(image_width / width)

    if (image_width % width) ~= 0 then
        rt.error("In Spritesheet:create_from_file: Spritesheet `" .. id .. "` has a width of `" .. tostring(image_width) .. "`, which is not evenly divisble by its frame width `" .. tostring(width) .. "`")
    end

    local animations = config.animations
    if meta.is_nil(animations) then
        animations = {}
        animations[name] = {1, n_frames}
    end

    -- expand shorthand
    for id, frames in pairs(animations) do
        if meta.is_number(frames) then
            animations[id] = {frames, frames}
        end
    end

    local frame_to_name = {}
    for id, frames in pairs(animations) do
        if not (#frames == 2 and meta.is_number(frames[1]) and meta.is_number(frames[1])) and frames[2] >= frames[1] then
            rt.error("In Spritesheet:create_from_file: Spritesheet `" .. id .. "`: frame range `{" .. tostring(frames[1]) .. ", " .. tostring(frames[2]) .. "} for animation `" .. id .. "` is malformed")
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
        rt.error("In Spritesheet:create_from_file: Spritesheet `" .. id .. "` does not have an animation name assigned for frames `" .. serialize(unnamed) .. "`")
    end

    local out = meta.new(rt.Spritesheet, {
        _name = id,
        _config_path = config_path,
        _image_path = image_path,
        _name_to_frame = animations,
        _frame_width = width,
        _frame_height = height,
        _n_frames = n_frames,
        _native = image,
        _fps = fps
    })

    out.name = name

    out:set_scale_mode(rt.TextureScaleMode.NEAREST)
    out:set_wrap_mode(rt.TextureWrapMode.REPEAT)
    return out
end)

rt.Spritesheet.name = ""

--- @brief [internal] check whether spritesheet has animation with given id
--- @param scope String scope for error message
--- @param animation_id String
function rt.Spritesheet:_assert_has_animation(scope, animation_id)
    if meta.is_nil(self._name_to_frame[animation_id]) then
        rt.error("in rt." .. scope .. ": Spritesheet `" .. self.name .. "` has no animation with id `" .. animation_id .. "`")
    end
end

--- @brief check if spritesheet has animation with given name
--- @param id String
--- @return Boolean
function rt.Spritesheet:has_animation(animation_id)
    return not meta.is_nil(self._name_to_frame[animation_id])
end

--- @brief get bounds of frame
--- @param animation_id String
--- @param index_maybe Number
--- @return rt.AxisAlignedRectangle
function rt.Spritesheet:get_frame(animation_id, index_maybe)
    self:_assert_has_animation("Spritesheet.get_frame", animation_id)
    local start_end = self._name_to_frame[animation_id]
    local i = (start_end[1] - 1) + (index_maybe - 1)
    return rt.AABB(i / self._n_frames, 0, 1 / self._n_frames, 1)
end

--- @brief get constant frame dimension for animation
--- @param animation_id String
--- @return (Number, Number)
function rt.Spritesheet:get_frame_size(animation_id)
    self:_assert_has_animation("Spritesheet.get_frame_size", animation_id)
    return self._frame_width, self._frame_height
end

--- @brief get constant frame height
--- @param animation_id String
--- @return Number
function rt.Spritesheet:get_frame_height(animation_id)
    self:_assert_has_animation("Spritesheet.get_frame_size", animation_id)
    return self._frame_height
end

--- @brief get constant frame width
--- @param animation_id String
--- @return Number
function rt.Spritesheet:get_frame_width(animation_id)
    self:_assert_has_animation("Spritesheet.get_frame_size", animation_id)
    return self._frame_width
end

--- @brief get number of frames for animation
--- @param animation_id String
--- @return Number
function rt.Spritesheet:get_n_frames(animation_id)
    self:_assert_has_animation("Spritesheet.get_n_frames", animation_id)
    local start_end = self._name_to_frame[animation_id]
    return start_end[2] - start_end[1] + 1
end

--- @brief list animation ids
--- @return Table<String>
function rt.Spritesheet:get_animation_ids()
    local out = {}
    for id, _ in pairs(self._name_to_frame) do
        table.insert(out, id)
    end
    return out
end

--- @brief get target fps
function rt.Spritesheet:get_fps()
    return self._fps
end

--- @brief test spritesheet
function rt.test.spritesheet()
    error("TODO")
end
