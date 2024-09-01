rt.settings.text_atlas = {

}

rt.LocalizationLanguage = {
    ENGLISH = "english",
    JAPANESE = "japanese",
    GERMAN = "german"
}

--- @class
rt.TextAtlas = meta.new_type("TextAtlas", function()
    return meta.new(rt.TextAtlasEntry, {
        _language = rt.LocalizationLanguage.ENGLISH,
        _content = {

        }
    })
end)

--- @brief
function rt.TextAtlas:get()

end