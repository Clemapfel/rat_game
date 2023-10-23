require "../include"

test = {}

test.active = ""
test.n_successful = 0
test.n_failed = 0
test.failed_test_are_fatal = false

--- @brief assert that condition evaluates to true
--- @param condition
function test.assert(condition, ...)
    local success = false
    if type(condition) == "boolean" then
        success = condition
    elseif type(condition) == "function" then
        success = condition(...)
    else
        error("[rt][ERROR] In test.assert_that: Argument #1 cannot be evaluated to boolean")
    end

    if success then
        test.n_successful = test.n_successful + 1
    else
        test.n_failed = test.n_failed + 1
        error("[rt][ERROR] test failed")
    end
end

--- @brief assert that function errors
--- @param function
function test.assert_that_errors(condition, ...)
    meta.assert_function(condition)
    local status, _ = pcall(condition, ...)

    if status == false then
        test.n_successful = test.n_successful + 1
    else
        test.n_failed = test.n_failed + 1
        error("[rt][ERROR] test failed")
    end
end

--- @brief testset
--- @param name
--- @param block
function test.testset(name, code)
    meta.assert_string(name)
    meta.assert_function(code)

    test.active = name
    test.n_successful = 0
    test.n_failed = 0
    println("Testing `" .. name .. "`:")
    local status, _ = pcall(code)

    println("  passed: " .. tostring(test.n_successful))
    println("  failed: " .. tostring(test.n_failed))
    println("")

    if test.failed_test_are_fatal and test.n_failed > 0 then
        error("[rt][ERROR] In test.testset(\"" .. name .. "\"): 1 or more tests failed.")
    end
end


-- ### MAIN ###

test.failed_test_are_fatal = true
println("Running tests...")

test.testset("meta", function()  
    test.assert(meta.Function == type(function() end))
    test.assert(meta.Nil == type(nil))
    test.assert(meta.String == type("string"))
    test.assert(meta.Table == type({x = 1}))
    test.assert(meta.Boolean == type(false))
    test.assert(meta.Number == type(1234))
    
    test.assert(is_string("signal"))
    test.assert(is_table({}))
    test.assert(is_number(1234))
    test.assert(is_boolean(true))
    test.assert(is_function(function() end))
    
    callable = {
        __call = function()
        end
    }
    setmetatable(callable, callable)
    test.assert(is_function(callable))
    
    local x = meta._new("Object")
    test.assert(meta.is_object(x))
    test.assert(meta.typeof(x) == "Object")
    test.assert(meta.isa(x, "Object"))

    meta.add_signal(x, "signal")
    x:add_signal("signal")
    
    local signal_called = false
    local id = x:connect_signal("signal", function(b)  
        signal_called = b
    end)
    test.assert(not x:get_signal_blocked("signal"))
    x:set_signal_bloced("signal", true)
    test.assert(x:get_signal_blocked("signal"))
    x:set_signal_blocked("signal", false)
    
    x:emit_signal("signal", true)
    test.assert(signal_called)
    x:disconnect_signal("signal")
    
    local ids = x:get_signal_handler_ids("signal")
    test.assert(#ids == 1)

    meta._initialize_notify(x)
    meta.add_property(x, "property", false)

    local notify_called = false
    local id = x:connect_notify("property", function(arg)
        notify_called = arg
    end)
    test.assert(x:get_notify_blocked("property") == false)
    x:set_notify_blocked("property", true)
    test.assert(x:get_notify_blocked("property") == true)
    x:set_notify_blocked("property", false)

    x.property = true
    test.assert(notify_called)
    x:disconnect_notify("property")
    local ids = x:get_notify_handler_ids("property")
    test.assert(#ids == 1)

    local enum = meta.new_enum({
        x = 1,
        y = "foo"
    })
    test.assert(meta.typeof(enum) == "Enum")
    test.assert(enum.x == 1)
    test.assert(enum.y == "foo")
    test.assert_that_errors(function()
        enum.x = 1234
    end)

    local type = meta.new_type("NewType")
    test.assert(type.name == "NewType")
    test.assert(meta.isa(type, "Type"))
end)

println("Done.")

