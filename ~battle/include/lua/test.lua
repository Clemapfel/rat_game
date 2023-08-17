--- @module test unit testing
test = {}
test._tests = {}
test._current_name = ""

function test._add_result(test_name, condition_name, result)

    test._tests[test_name][#(test._tests[test_name]) + 1] = {
        name = condition_name,
        result = result
    }
end

--- @brief start testing suite
function test.start_test(name)

    if test._current_name ~= "" then
        error("[ERROR] In test.start_test: Another test `" .. test._current_name .. "` is already active")
    end

    test._tests[name] = {}
    test._current_name = name
end

--- @brief register individual test
function test.assert_that(name, condition)

    if test._current_name == "" then
        error("[ERROR] In test.assert_that: No test is active, call test.start_test first")
    end

    if type(name) ~= "string" then
        error("[ERROR] In test.assert_that: `name` argument is not a string")
    end

    local condition_result = false;
    local trigger_error = false

    if type(condition) == "boolean" then
        condition_result = condition
    elseif type(condition) == "function" then

        local status, temp = pcall(condition)
        if status == false then
            condition_result = false
        else
            if type(temp) ~= "boolean" then
                trigger_error = true
            end
            condition_result = temp
        end
    end

    if trigger_error then
        error("[ERROR] In test.assert_that: `condition` argument has to resolve to boolean")
    end

    test._add_result(test._current_name, name, condition_result)
end

--- @brief assert that function errors
function test.assert_that_errors(name, condition)

    if test._current_name == "" then
        error("[ERROR] In test.assert_that_errors: No test is active, call test.start_test first")
    end

    if type(name) ~= "string" then
        error("[ERROR] In test.assert_that_errors: `name` argument is not a string")
    end

    local status, _ = pcall(condition)
    test._add_result(test._current_name, name, not status)
end

--- @brief assert that function errors
function test.assert_that_not_errors(name, condition)

    if test._current_name == "" then
        io.write("[ERROR] In test.assert_that_not_errors: No test is active, call test.start_test first")
    end

    if type(name) ~= "string" then
        io.write("[ERROR] In test.assert_that_not_errors: `name` argument is not a string")
    end

    local status, _ = pcall(condition)
    test._add_result(test._current_name, name, status)
end

--- @brief end testing suite
function test.end_test()

    if test._current_name == "" then
        error("[ERROR] In test.end_test: No test is active, call test.start_test first")
    end

    local success = true;

    local n_failed = 0;
    local n = 0

    io.write("Test: \"" .. test._current_name .. "\"\n")
    for _, t in pairs(test._tests[test._current_name]) do

        local name = t.name
        local result = t.result
        n = n + 1

        io.write("  " .. name .. "\t\t\t\t")
        if result == true then
            io.write("[OK]")
        elseif result == false then
            io.write("[FAILED]")
            n_failed = n_failed + 1
            success = false
        end

        io.write("\n")
    end

    io.write(tostring(n_failed) .. " out of " .. tostring(n) .. " tests unsuccesfull\n")
    test._current_name = ""
    return n_failed
end
