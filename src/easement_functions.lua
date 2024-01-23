--- @brief easement functions, defined in [0, 1] with f(0) = 0, f(1) = 1

--- @brief linear, maps [0, 1] to [min, max]
rt.linear = function(x, min, max)
    return x * (max - min) + min
end

rt.sinoid_ease_in = function(x)
    return -1.0 * math.cos(x * (math.pi / 2)) + 1.0;
end

rt.sinoid_ease_out = function(x)
    return math.sin(x * (math.pi / 2));
end

rt.sinoid_ease_in_out = function(x)
    return -0.5 * math.cos(math.pi * x) + 0.5;
end

rt.exponential_acceleration = function(x)
    return math.exp((x - 1) * math.pi) - math.exp(-1 * math.pi)
end

rt.exponential_plateau = function(x)
    return math.exp((10 / 13 * math.pi * x - 1 - math.pi / 6)^3) / 2
end

--- @brief maps [0, 0.5] to [0, peak], [0.5, 1] to [peak, 0], linear in both sections
rt.symmetrical_linear = function(x, peak)
    peak = which(peak, 1)
    return (1 - math.abs(2 * (x - 0.5))) / (1 / peak)
end