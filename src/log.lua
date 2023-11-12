if type(rt.settings) == "nil" then rt.settings = {} end
rt.settings.log = {}
rt.settings.log.rt_prefix = "[rt]"
rt.settings.log.log_prefix = "[LOG]"
rt.settings.log.warning_prefix = "[WARNING]"
rt.settings.log.error_prefix = "[ERROR]"

--- @brief
function rt.log(message)
    println(rt.settings.log.rt_prefix, rt.settings.log.log_prefix, " ", message)
end

--- @brief
function rt.warning(message)
    println(rt.settings.log.rt_prefix, rt.settings.log.warning_prefix, " ", message)
end

--- @brief
function rt.error(message)
    error(rt.settings.log.rt_prefix .. rt.settings.log.error_prefix .. " " .. message)
end