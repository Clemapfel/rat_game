--- @brief easement functions, defined in [0, 1] with f(0) = 0, f(1) = 1

--- @brief linear, maps [0, 1] to [min, max]
rt.linear = function(x, min, max)
    min = which(min, 0)
    max = which(max, 1)
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

rt.sinoid_resonance_increase = function(x, n_periods)
    n_periods = which(n_periods, 3)
    return math.sin(math.pi * 2 * n_periods * x) * x
end

rt.sinoid_resonance_decrease = function(x, n_periods)
    n_periods = which(n_periods, 3)
    return math.sin(math.pi * 2 * n_periods * (1 - x)) * (1 - x)
end

rt.exponential_acceleration = function(x)
    return math.exp((x - 1) * math.pi) - math.exp(-1 * math.pi)
end

rt.exponential_deceleration = function(x)
    return (1 - 1.5 * math.exp(-x * math.pi) - 0.5 * math.exp(-1 * math.pi) + 0.5) / (math.pi / 2 - 0.1)
end

rt.exponential_plateau = function(x)
    return math.exp((10 / 13 * math.pi * x - 1 - math.pi / 6)^3) / 2
end

--- @brief maps [0, 0.5] to [0, peak], [0.5, 1] to [peak, 0], linear in both sections
rt.symmetrical_linear = function(x, peak)
    peak = which(peak, 1)
    return (1 - math.abs(2 * (x - 0.5))) / (1 / peak)
end

--- @brief 1 to 0 strictly decreasing, x² parabolic
rt.parabolic_drop = function(x)
    return -(x^2) + 1
end

--- @brief 0 to 1 strictly increasing x² parabolic
rt.parabolic_increase = function(x)
    return x^2
end

--- @brief gaussian distribution with 0.99 percentile in [0, 1], peak at 0.5
rt.symmetrical_gaussian = function(x, peak)
    peak = which(peak, 1)
    return (math.exp(-1 * ((4 * math.pi / 3) * (x - 0.5))^2))
end

--- @brief gaussian distribution with 0.99 percentile in [0, 1], peak at 1
rt.gaussian_increase = function(x, peak)
    peak = which(peak, 1)
    return (math.exp(-1 * ((2 * math.pi / 3) * (x - 1))^2))
end