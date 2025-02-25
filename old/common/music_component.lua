rt.settings.monitored_audio_playback = {
    default_window_size = 2^11
}

--- @class rt.MusicComponent
--- @signal fft (self) -> nil called anytime a fourier transform is ready
rt.MusicComponent = meta.new_type("MusicComponent", function()
    local out = meta.new(rt.MusicComponent, {

    })

    out:signal_add("fft")
    table.insert(rt.SoundAtlas._music_components, out)
    return out
end)

--- @brief
function rt.MusicComponent:_update(delta)

end