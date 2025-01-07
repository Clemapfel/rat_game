rt.SIGNED = "Signed"
rt.INTEGER = rt.SIGNED
rt.UNSIGNED = "Unsigned"

rt.FLOAT = "Float"
rt.POSITIVE_FLOAT = "Float >= 0"
rt.NEGATIVE_FLOAT = "Float <= 0"

rt.STRING = "String"
rt.BOOLEAN = "Boolean"
rt.FUNCTION = "Function"
rt.TABLE = "Table"

--[[
Template Syntax:
{
    id = Type,
    id = { UnionTypeA, UnionTypeB, ... }
}
where Type is one of the above
]]--

--- @brief
--- @param template Table<String, rt.ConfigTemplateType>
function rt.load_config(path, to_assign, template)
    local load_success, chunk_or_error, love_error = pcall(love.filesystem.load, path)
    if not load_success then
        rt.error("In rt.load_config: error when parsing config at `" .. path .. "`: " .. chunk_or_error)
        return
    end

    if love_error ~= nil then
        rt.error("In rt.load_config: error when loading config at `" .. path .. "`: " .. love_error)
        return
    end

    local chunk_success, config_or_error = pcall(chunk_or_error)
    if not chunk_success then
        rt.error("In rt.load_config: error when running config at `" .. path .. "`: " .. config_or_error)
        return
    end

    local config = config_or_error

    local throw_on_unexpected = function(key, expected, got)
        rt.error("In rt.load_config: error when loading config at `" .. path .. "` for key `" .. key .. "`: expected `" .. expected .. "`, got `" .. got .. "`")
        return
    end

    local function is(value, type)
        if type == rt.SIGNED then
            return meta.is_number(value)
        elseif type == rt.UNSIGNED then
            return meta.is_number(value) and value >= 0
        elseif type == rt.FLOAT then
            return meta.is_number(value)
        elseif type == rt.POSITIVE_FLOAT then
            return meta.is_number(value) and value >= 0
        elseif type == rt.NEGATIVE_FLOAT then
            return meta.is_number(value) and value <= 0
        elseif type == rt.STRING then
            return meta.is_string(value)
        elseif type == rt.BOOLEAN then
            return meta.is_boolean(value)
        elseif type == rt.FUNCTION then
            return meta.is_function(value)
        elseif type == rt.TABLE then
            return meta.is_table(value)
        else
            rt.error("In rt.load_config.is: error when loading config at `" .. path .. "`: unknown template type `" .. type .. "`")
            return
        end
    end

    for key, type in pairs(template) do
        if config[key] ~= nil then
            to_assign[key] = config[key]

            local value = to_assign[key]
            if meta.is_table(type) then
                for t in values(type) do
                    if is(value, t) then
                        goto no_error;
                    end
                end
                throw_on_unexpected(key, serialize(type), serialize(value))
                ::no_error::
            else
                if not is(value, type) then
                    throw_on_unexpected(key, type, serialize(value))
                end
            end
        end
    end

    return to_assign
end
