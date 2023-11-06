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
    assert(#serialize(recursive) ~= 0)

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
            println("[rt][TEST_FAILED] In rt.test." .. name .. ": " .. err)
        end)
    end
end