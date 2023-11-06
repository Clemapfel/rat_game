rt.settings.log = {}
rt.settings.log.rt_prefix = "[rt]"
rt.settings.log.log_prefix = "[LOG]"
rt.settings.log.warning_prefix = "[WARNING]"
rt.settings.log.error_prefix = "[ERROR]"

--- @brief
function rt.log(message)
    println(rt.settings.rt_prefix, rt.settings.log_prefix, " ", message)
end

--- @brief
function rt.warning(message)
    println(rt.settings.rt_prefix, rt.settings.warning_prefix, " ", message)
end

--- @brief
function rt.error(message)
    error(rt.settings.rt_prefix, rt.settings.error_prefix, " ", message)
end