rt.SIGNED = "Signed"
rt.INTEGER = rt.SIGNED
rt.UNSIGNED = "Unsigned"

rt.FLOAT = "Float"
rt.POSITIVE_FLOAT = "Float >= 0"
rt.NEGATIVE_FLOAT = "Float <= 0"

rt.STRING = "String"
rt.BOOLEAN = "Boolean"
rt.FUNCTION = "Function"

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
    local chunk, error_maybe = love.filesystem.load(path)
    if error_maybe ~= nil then
        rt.error("In rt.load_config: error when loading config at `" .. path .. "`: " .. error_maybe)
    end

    local config = chunk()
    local throw_on_unexpected = function(key, expected, got)
        rt.error("In rt.load_config: error when loading config at `" .. path .. "` for key `" .. key .. "`: expected `" .. expected .. "`, got `" .. got .. "`")
    end

    local function is(value, type)
        if type == rt.SIGNED then
            return meta.is_number(value) and (meta.is_inf(value) or meta.is_signed(value))
        elseif type == rt.UNSIGNED then
            return meta.is_number(value) and (meta.is_inf(value) or value >= 0)
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
        else
            rt.error("In rt.load_config.is: error when loading config at `" .. path .. "`: unknown template type `" .. type .. "`")
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
