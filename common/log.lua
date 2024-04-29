rt.settings.log = {
    rt_prefix = {
        "[rt]",
        bold = true
    },

    log_prefix = {
        "[LOG]",
        color = "green",
        bold = true
    },

    warning_prefix = {
        "[WARNING]",
        color = "yellow",
        bold = true
    },

    error_prefix = {
        "[ERROR]",
        color = "red",
        bold = true
    }
}

--- @brief pretty print to the console, supports colors and boldness
function printstyled(message, config)
    if config == nil then
        print(message)
        return
    end

    local to_tag = {
        black         = "\027[30m",
        red           = "\027[31m",
        green         = "\027[32m",
        yellow        = "\027[33m",
        blue          = "\027[34m",
        magenta       = "\027[35m",
        cyan          = "\027[36m",
        white         = "\027[37m",
        gray          = "\027[90m",
        light_black   = "\027[90m", -- same as gray
        light_red     = "\027[91m",
        light_green   = "\027[92m",
        light_yellow  = "\027[93m",
        light_blue    = "\027[94m",
        light_magenta = "\027[95m",
        light_cyan    = "\027[96m",
        light_white   = "\027[97m",

        normal        = "\027[0m",
        default       = "\027[39m",
        bold          = "\027[1m",
        italic        = "\027[3m",
        underlined     = "\027[4m",
        reverse       = "\027[7m",
        nothing       = "",
    }

    local to_print = {}

    if config.color ~= nil then
        local tag = to_tag[config.color]
        if tag == nil then
            rt.error("In prinstyled: unsupported color `" .. config.color .. "`")
        end
        table.insert(to_print, tag)
    end

    for _, which in pairs({
        "normal", "bold", "italic", "underline", "reverse"
    }) do
        if config[which] == true then
            table.insert(to_print, to_tag[which])
        end
    end

    table.insert(to_print, message)
    table.insert(to_print, to_tag.normal)
    for _, word in pairs(to_print) do
        io.write(word)
    end
end

--- @brief
function rt.prettyprint(...)
    for word in values({...}) do
        if meta.is_string(word) then
            printstyled(word)
        else
            assert(meta.is_string(word[1]))
            printstyled(word[1], word)
        end
    end
end

--- @brief
function rt.log(message)
    rt.prettyprint(rt.settings.log.rt_prefix, rt.settings.log.log_prefix, " ", message)
end

--- @brief
function rt.warning(message)
    rt.prettyprint(rt.settings.log.rt_prefix, rt.settings.log.warning_prefix, " ", message)
end

--- @brief
function rt.error(message)
    error(rt.settings.log.rt_prefix[1] .. rt.settings.log.error_prefix[1] .. " " .. message)
end