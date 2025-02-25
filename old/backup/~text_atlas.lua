rt.LocalizationLanguage = meta.new_enum("LocalizationLanguage", {
    ENGLISH = "english",
    JAPANESE = "japanese"
})

--- @class
rt.TextAtlas = meta.new_type("TextAtlas", function()
    return meta.new(rt.TextAtlas, {
        _language = rt.LocalizationLanguage.ENGLISH,
        _folder = "",
        _content = {}
    })
end)

--- @brief
function rt.TextAtlas:initialize(folder, language)
    meta.assert_enum_value(language, rt.LocalizationLanguage)
    self._content = {}
    self._folder = folder .. "/" .. language

    if not rt.filesystem.exists(self._folder) then
        rt.error("In rt.TextAtlas: invalid initialization folder `" .. folder .. "`")
    end

    local function parse(prefix, content)
        local items = love.filesystem.getDirectoryItems(prefix)
        for item in values(items) do
            local filename = prefix .. "/" .. item
            local type = love.filesystem.getInfo(filename).type
            local name, extension = rt.filesystem.get_name_and_extension(filename)
            if type == "directory" then
                local to_insert = {}
                content[name] = to_insert
                parse(filename, to_insert)
            elseif type == "file" then
                content[name] = love.filesystem.load(filename)()
            end
        end
    end

    self._content = {}
    parse(self._folder, self._content)
end

--- @brief
function rt.TextAtlas:get(id)
    meta.assert_string(id)

    -- split "id" by . or / then access content
    local names = {}
    for name in string.gmatch(id, "([^./]+)") do
        table.insert(names, name)
    end

    local name_i = 1
    local current = self._content
    local value
    while true do
        if name_i > #names then return value end
        value = current[names[name_i]]
        current = value
        if value == nil then
            rt.warning("In rt.TextAtlas.get: Trying to access `" .. id .. "`, but `" .. names[name_i] .. "` does not exist")
            break
        end
        name_i = name_i + 1
    end

    return "<" .. id .. ">"
end

-- global singleton
rt.TextAtlas = rt.TextAtlas()
rt.TextAtlas:initialize("assets/text", rt.LocalizationLanguage.ENGLISH)