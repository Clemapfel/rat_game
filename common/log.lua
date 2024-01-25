rt.settings.log = {
    rt_prefix = "[rt]",
    log_prefix = "[LOG]",
    warning_prefix = "[WARNING]",
    error_prefix = "[ERROR]"
}

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