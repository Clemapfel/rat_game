rt.settings.text_atlas = {

}

rt.LocalizationLanguage = {
    ENGLISH = "english",
    JAPANESE = "japanese",
    GERMAN = "german"
}

--- @class
rt.TextAtlas = meta.new_type("TextAtlas", function()
    local out = meta.new(rt.TextAtlasEntry, {
        _language = rt.LocalizationLanguage.ENGLISH,
        _folder = "",
        _content = {}
    })
    out:initialize()
    return out
end)

--- @brief
function rt.TextAtlas:initialize(folder)
    self._content = {}
    self._folder = folder
    local prefix = self._folder .. "/" .. self._language
    local names = love.filesystem.getdirectoryitems(prefix)
    for _, name in pairs(names) do
        local filename = prefix .. "/" .. name
        local info = love.filesystem.getInfo(filename)
        if
    end
end

--- @brief
function rt.TextAtlas:get(id)
    local table = self._content[id]

end

-- global singleton
rt.TextAtlas = rt.TextAtlas()
rt.TextAtlas:initialize("assets/text")