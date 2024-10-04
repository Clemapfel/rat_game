--- @brief
rt.Background.MIDI_TILING = rt.Background.new_shader_only_background("MIDI_TILING", "backgrounds/midi_tiling.glsl")

function rt.Background.MIDI_TILING:update(delta, speed, base, hi)
    self._elapsed = self._elapsed + delta

    self._shader:send("elapsed", self._elapsed)
    self._shader:send("speed", speed)
    self._shader:send("base", base)
    self._shader:send("hi", hi)
end
