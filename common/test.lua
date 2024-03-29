if meta.is_nil(rt.test) then rt.test = {} end

--- @brief [internal] test common
function rt.test.common()
    assert(sizeof({}) == 0)
    assert(sizeof(nil) == 0)
    assert(sizeof(1) == 1)
    assert(sizeof({1, 2, 3}) == 3)
    assert(sizeof({{}, {}}) == 2)

    assert(not is_empty({1}))
    assert(is_empty({}))
    assert(is_empty(nil))

    for i = -10, 10 do
        local clamped = clamp(i, -5, 5)
        assert(clamped >= -5 and clamped <= 5)
    end

    assert(ternary(true, 1, 2) == 1)
    assert(ternary(false, 1, 2) == 2)

    assert(try_catch(function() return 1234 end) == 1234)
    assert(try_catch(function() assert(false) end, function() return 4567 end) == 4567)

    local recursive = {
        abc = 1234
    }
    recursive["recursive"] = recursive
    assert(string.len(serialize(recursive)) ~= 0)

    assert(INFINITY > 2^64)
    assert(INFINITY == INFINITY)
    assert(NEGATIVE_INFINITY < -2^64)
    assert(NEGATIVE_INFINITY == NEGATIVE_INFINITY)

    assert(string.capitalize("abc") == "Abc")
    assert(string.capitalize("1234") == "1234")

    local split = string.split("abc;def;hij", ";")
    assert(sizeof(split) == 3)
    assert(split[1] == "abc" and split[2] == "def" and split[3] == "hij")

    assert(string.contains("abcontainsef", "contains"))
    assert(not string.contains("not", "abc"))
    assert(string.contains("", ""))

    assert(string.hash("abc") == string.hash("abc"))
    assert(string.hash("Abc") ~= string.hash("abc"))

    assert(math.round(0.5) == 1)
    assert(math.round(0.5 - 1 / 2^32) == 0)
    assert(math.round(0.5 + 1 / 2^32) == 1)

    local camel = "CamelCaseTest"
    local snake = "camel_case_test"

    assert(string.to_snake_case(camel) == snake)

    -- step_range
    local t = {}
    for i in step_range(0, 5, 1) do
        table.insert(t, i)
    end
    assert(table.compare(t, {0, 1, 2, 3, 4, 5}))

    t = {}
    for i in step_range(5, 0, -1) do
        table.insert(t, i)
    end
    assert(table.compare(t, {5, 4, 3, 2, 1, 0}))

    t = {}
    for i in step_range(0, 3, 2) do
        table.insert(t, i)
    end
    assert(table.compare(t, {0, 2}))

    t = {}
    for i in step_range(3, 0, -2) do
        table.insert(t, i)
    end
    assert(table.compare(t, {3, 1}))

    t = {}
    for i in step_range(0, 0, 1) do
        table.insert(t, i)
    end
    assert(table.compare(t, {0}))

    t = {}
    for i in step_range(0, 0, -1) do
        table.insert(t, i)
    end
    assert(table.compare(t, {0}))

    t = {}
    for i in step_range(0, 0, 0) do
        table.insert(t, i)
    end
    assert(table.compare(t, {}))

    --- range
    local i = 1
    for x in range(nil, "test", nil, 1234, nil, {1}, nil) do
        if i == 1 then assert(x == "test")
        elseif i == 2 then assert(x == 1234)
        elseif i == 3 then assert(x[1] == 1)
        end
        i = i + 1
    end
    assert(i == 4)

    --- string.interpolate
    local env = {
        user = {
            attack = 1234
        }
    }
    assert(string.interpolate("$(user.attack * 2)", env) == "2468")
end


--- @brief [internal] test meta
function rt.test.meta()
    assert(meta.is_string("abc"))
    assert(meta.is_string(""))
    assert(not meta.is_string(nil))

    assert(meta.is_table({}))
    assert(meta.is_table({1, 2, 3}))
    assert(not meta.is_table(nil))

    assert(meta.is_number(1234))
    assert(meta.is_number(POSITIVE_INFINITY) and meta.is_number(NEGATIVE_INFINITY))
    assert(meta.is_number(POSITIVE_INFINITY - POSITIVE_INFINITY))
    assert(not meta.is_number(nil))

    assert(meta.is_boolean(true))
    assert(not meta.is_boolean(1) and not meta.is_boolean(0))
    assert(not meta.is_boolean(nil))

    assert(meta.is_function(function() end))
    assert(not meta.is_function(nil))

    -- TODO
end

-- run all tests
for name, f in pairs(rt.test) do
    if meta.is_function(f) then
        try_catch(f, function(err)
            println(rt.settings.rt_prefix, "[TEST_FAILED] In rt.test." .. name .. ": " .. err)
        end)
    end
end