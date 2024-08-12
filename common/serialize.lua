_serialize_get_indent = function(n_indent_tabs)
    local tabspace = "    "
    local buffer = {""}

    for i = 1, n_indent_tabs do
        table.insert(buffer, tabspace)
    end

    return table.concat(buffer)
end

_serialize_insert = function(buffer, ...)
    for i, value in pairs({...}) do
        table.insert(buffer, value)
    end
end

_serialize_inner = function(buffer, object, n_indent_tabs, seen, comment_out)
    if type(object) == "number" then
        _serialize_insert(buffer, object)
    elseif type(object) == "string" then
        _serialize_insert(buffer, "\"", object, "\"")
    elseif type(object) == "boolean" then
        if object == true then
            _serialize_insert(buffer, "true")
        else
            _serialize_insert(buffer, "false")
        end
    elseif type(object) == "nil" then
        _serialize_insert(buffer, "nil")
    elseif type(object) == "table" then
        local n_entries = sizeof(object)
        if seen[object] then
            _serialize_insert(buffer, " { ...")
            return
        end

        if n_entries > 0 then
            _serialize_insert(buffer, "{\n")
            n_indent_tabs = n_indent_tabs + 1

            local index = 0
            for key, value in pairs(object) do
                if comment_out and type(value) == "function" or type(value) == "userdata" then
                    _serialize_insert(buffer, "--[[ ", key, " = ", tostring(value), ", ]]\n")
                    index = index + 1
                elseif comment_out and seen[object] then
                    _serialize_insert(buffer, "--[[ ", key, " = ..., ]]\n")
                    index = index + 1
                else
                    if type(key) == "string" then
                        -- check if string is valid variable name, if no, escape
                        local _, error_maybe = load(key .. " = 1")
                        if error_maybe == nil then
                            _serialize_insert(buffer, _serialize_get_indent(n_indent_tabs), tostring(key), " = ")
                        else
                            _serialize_insert(buffer, _serialize_get_indent(n_indent_tabs), "[\"", tostring(key), "\"]", " = ")
                        end
                    elseif type(key) == "number" then
                        _serialize_insert(buffer, _serialize_get_indent(n_indent_tabs), "[", tostring(key), "] = ")
                    else
                        _serialize_insert(buffer, _serialize_get_indent(n_indent_tabs), "[", serialize(key), "] = ")
                    end

                    _serialize_inner(buffer, value, n_indent_tabs, seen)

                    index = index + 1
                    if index < n_entries then
                        _serialize_insert(buffer, ",\n")
                    else
                        _serialize_insert(buffer, "\n")
                    end
                end
            end
            _serialize_insert(buffer, _serialize_get_indent(n_indent_tabs-1), "}")
        else
            _serialize_insert(buffer, "{}")
        end

        seen[object] = true
    else
        -- function, userdata, when not commented out
        _serialize_insert(buffer, "[", tostring(object), "]")
    end
end

--- @brief convert arbitrary object to string
--- @param object any
--- @param comment_out_unserializable Boolean false by default
--- @return string
function serialize(object, comment_out_unserializable)
    if comment_out_unserializable == nil then
        comment_out_unserializable = false
    end

    if object == nil then
        return nil
    end

    local buffer = {""}
    local seen = {}
    _serialize_inner(buffer, object, 0, seen, comment_out_unserializable)
    return table.concat(buffer, "")
end

--- @brief
function dbg(...)
    for _, x in pairs({...}) do
        io.write(serialize(x))
        io.write(" ")
    end

    io.write("\n")
    io.flush()
end