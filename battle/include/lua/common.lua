--- @brief print, arguments are concatenated
--- @param vararg any
--- @return void
function print(...)
    for _, v in pairs({...}) do
        io.write(tostring(v))
    end
end

--- @brief print, arguments are concatenade with a newline in between each
--- @param vararg any
--- @return void
function println(...)

    for _, v in pairs({...}) do
        io.write(tostring(v))
        io.write("\n")
    end
end

--- @brief get number of elements in arbitrary object
--- @param x any
--- @return number
function sizeof(x)
    if type(x) == "table" then
        local n = 0
        for _ in pairs(x) do
            n = n + 1
        end
        return n
    elseif type(x) == "string" then
        return #x
    else
        return 1
    end
end

--- @brief is table empty
--- @param x any
--- @return boolean
function is_empty(x)
    if type(x) ~= "table" then
        return true
    else
        return next(x) == nil
    end
end

--- @brief clamp
--- @param x number
--- @param lower_bound number
--- @param upper_bound number
--- @return number
function clamp(x, lower_bound, upper_bound)

    if x < lower_bound then
        x = lower_bound
    end

    if x > upper_bound then
        x = upper_bound
    end

    return x
end

--- @brief make first letter in word capitalized

--- @brief convert arbitrary object to string
--- @param id string
--- @param object any
--- @return string
function serialize(object_identifier, object, inject_sourcecode)

    if inject_sourcecode == nil then
        inject_sourcecode = false
    end

    get_indent = function (n_indent_tabs)

        local tabspace = "    "
        local buffer = {""}

        for i = 1, n_indent_tabs do
            table.insert(buffer, tabspace)
        end

        return table.concat(buffer)
    end

    insert = function (buffer, ...)

        for i, value in pairs({...}) do
            table.insert(buffer, value)
        end
    end

    get_source_code = function (func)

        local info = debug.getinfo(func);

        if string.sub(info.source, 1, 1) ~= "@" then
            return "[" .. tostring(func) .. "]"
        end

        local file = io.open(string.sub(info.source, 2), "r");

        if file == nil then return "" end

        local str_buffer = {}
        local i = 1
        local end_i = 1

        local first_line = true
        local single_line_comment_active = false
        local multi_line_comment_active = false

        for line in file:lines("L") do

            if end_i == 0 then break end

            if (i >= info.linedefined) then

                if not first_line then

                    local first_word = true;
                    for word in line:gmatch("%g+") do

                        if string.find(word, "%-%-%[%[") then
                            multi_line_comment_active = true
                        elseif string.find(word, "%-%-]]") then
                            multi_line_comment_active = false
                        elseif string.find(word, "%-%-") then
                            single_line_comment_active = true
                        end

                        if not (single_line_comment_active or multi_line_comment_active) then

                            if word == "if" or word == "for" or word == "while" or word == "function" then
                                end_i = end_i + 1
                            elseif word == "do" and first_word then     -- do ... end block
                                end_i = end_i + 1
                            elseif word == "end" or word == "end," then
                                end_i = end_i - 1
                            end
                        end

                        first_word = false
                    end
                end

                table.insert(str_buffer, line)
                first_line = false
            end

            single_line_comment_active = false;
            i = i + 1
        end

        file:close()

        -- remove last newline
        local n = #str_buffer
        str_buffer[n] = string.sub(str_buffer[n], 1, string.len(str_buffer[n]) - 1)

        return table.concat(str_buffer)
    end

    serialize_inner = function (buffer, object, n_indent_tabs)

        if type(object) == "number" then
            insert(buffer, object)

        elseif type(object) == "boolean" then
            if (object) then insert(buffer, "true") else insert(buffer, "false") end

        elseif type(object) == "string" then
            insert(buffer, string.format("%q", object))

        elseif type(object) == "table" then

            if sizeof(object) > 0 then
                insert(buffer, "{\n")
                n_indent_tabs = n_indent_tabs + 1

                local n_entries = sizeof(object)
                local index = 0
                for key, value in pairs(object) do

                    if type(key) == "string" then
                        insert(buffer, get_indent(n_indent_tabs), key, " = ")

                    elseif type(key) == "number" then

                        if key ~= index+1 then
                            insert(buffer, get_indent(n_indent_tabs), "[", key, "] = ")
                        else
                            insert(buffer, get_indent(n_indent_tabs))
                        end
                    end

                    serialize_inner(buffer, value, n_indent_tabs)
                    index = index +1

                    if index < n_entries then
                        insert(buffer, ",\n")
                    else
                        insert(buffer, "\n")
                    end
                end

                insert(buffer, get_indent(n_indent_tabs-1), "}")
            else
                insert(buffer, "{}")
            end

        elseif type(object) == "function" and inject_sourcecode then
            insert(buffer, get_source_code(object))
        elseif type(object) == "nil" then
            insert(buffer, "nil")
        else
            insert(buffer, "[" .. tostring(object) .. "]")
        end
    end

    if object == nil then
        return serialize("", object_identifier)
    end

    local buffer = {""}

    if object_identifier ~= "" then
        table.insert(buffer, object_identifier .. " = ")
    end

    serialize_inner(buffer, object, 0)
    return table.concat(buffer, "")
end

--- @brief positive infinity
INFINITY = 1/0

--- @brief negative infinity
NEGATIVE_INFINITY = -1/0

--- @brief make first letter capital
function string.capitalize(str)
    return string.upper(string.sub(str, 1, 1)) .. string.sub(str, 2, string.len(str))
end