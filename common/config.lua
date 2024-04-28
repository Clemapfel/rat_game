rt.ConfigTemplateType = meta.new_enum({
    SIGNED = "Signed",
    UNSIGNED = "Unsigned",
    FLOAT = "Float",
    STRING = "String",
    BOOLEAN = "Boolean",
    FUNCTION = "Function"
})

rt.SIGNED = rt.ConfigTemplateType.SIGNED
rt.UNSIGNED = rt.ConfigTemplateType.UNSIGNED
rt.FLOAT = rt.ConfigTemplateType.FLOAT
rt.STRING = rt.ConfigTemplateType.STRING
rt.BOOLEAN = rt.ConfigTemplateType.BOOLEAN
rt.FUNCTION = rt.ConfigTemplateType.FUNCTION

--- @brief
--- @param template Table<String, rt.ConfigTemplateType>
function rt.load_config(path, to_assign, template)
    local chunk, error_maybe = love.filesystem.load(path)
    if error_maybe ~= nil then
        rt.error("In rt.load_config: error when loading config at `" .. path .. "`: " .. error_maybe)
    end

    local config = chunk()
    local throw_on_unexpected = function(key, expected, got)
        rt.error("In rt.load_config: error when loading config at `" .. path .. "` for key `" .. key .. "`: expected `" .. expected .. "`, got `" .. got .. "`")
    end

    for key, type in pairs(template) do
        if config[key] ~= nil then
            to_assign[key] = config[key]

            local value = to_assign[key]
            if type == rt.ConfigTemplateType.SIGNED then
                if not meta.is_number(value) then
                    throw_on_unexpected(key, rt.ConfigTemplateType.SIGNED, meta.typeof(value))
                end
                if not meta.is_inf(value) and not meta.is_signed(value) then
                    throw_on_unexpected(key, rt.ConfigTemplateType.SIGNED, value)
                end
            elseif type == rt.ConfigTemplateType.UNSIGNED then
                if not meta.is_number(value) then
                    throw_on_unexpected(key, rt.ConfigTemplateType.UNSIGNED, meta.typeof(value))
                end
                if not meta.is_inf(value) and not meta.is_signed(value) or not (value >= 0) then
                    throw_on_unexpected(key, rt.ConfigTemplateType.UNSIGNED .. " >= 0", value)
                end
            elseif type == rt.ConfigTemplateType.FLOAT then
                if not meta.is_number(value) then
                    throw_on_unexpected(key, rt.ConfigTemplateType.FLOAT, meta.typeof(value))
                end
            elseif type == rt.ConfigTemplateType.STRING then
                if not meta.is_string(value) then
                    throw_on_unexpected(key, rt.ConfigTemplateType.STRING, meta.typeof(value))
                end
            elseif type == rt.ConfigTemplateType.BOOLEAN then
                if not meta.is_boolean(value) then
                    throw_on_unexpected(key, rt.ConfigTemplateType.BOOLEAN, meta.typeof(value))
                end
            elseif type == rt.ConfigTemplateType.FUNCTION then
                if not meta.is_function(value) then
                    throw_on_unexpected(key, rt.ConfigTemplateType.FUNCTION, meta.typeof(value))
                end
            else
                rt.error("In rt.load_config: error when loading config at `" .. path .. "` for key `" .. key .. "`: unknown template type `" .. type .. "`")
            end
        end
    end

    return to_assign
end