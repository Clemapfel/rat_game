--- @brief easement functions, defined in [0, 1] with f(0) = 0, f(1) = 1

--- @brief linear, maps [0, 1] to [min, max]
rt.linear = function(x, min, max)
    min = which(min, 0)
    max = which(max, 1)
    return x * (max - min) + min
end

rt.sinusoid_ease_in = function(x)
    return -1.0 * math.cos(x * (math.pi / 2)) + 1.0;
end

rt.sinusoid_ease_out = function(x)
    return math.sin(x * (math.pi / 2));
end

rt.sinusoid_ease_in_out = function(x)
    return -0.5 * math.cos(math.pi * x) + 0.5;
end

rt.sinusoid_resonance_increase = function(x, n_periods)
    n_periods = which(n_periods, 3)
    return math.sin(math.pi * 2 * n_periods * x) * x
end

rt.sinusoid_resonance_decrease = function(x, n_periods)
    n_periods = which(n_periods, 3)
    return math.sin(math.pi * 2 * n_periods * (1 - x)) * (1 - x)
end

rt.symmetrical_sinusoid = function(x)
    -- \frac{-\cos\left(-2\pi x\right)}{2}+0.5
    return (-1 * math.cos(-2 * math.pi * x) + 1) / 2
end

rt.exponential_acceleration = function(x)
    -- a\ \cdot\exp\left(\ln\left(1+\frac{1}{a}\right)x\right)-a
    return 0.045 * math.exp(math.log(1 / 0.045 + 1) * x) - 0.045
end

rt.exponential_deceleration = function(x)
    return rt.exponential_acceleration(-1 * x + 1)
end

rt.exponential_plateau = function(x)
    return math.exp((10 / 13 * math.pi * x - 1 - math.pi / 6)^3) / 2
end

rt.fade_ramp = function(x, duration, target)
    duration = which(duration, 0.1)
    target = which(target, 1)
    if x < duration then
        return x / duration
    elseif x <= target - duration then
        return target
    else
        return (target - x) / duration
    end
end

rt.sigmoid = function(x, slope)
    slope = which(slope, 9)
    return 1 / (1 + math.exp(-1 * slope * (x - 0.5)))
end

rt.sigmoid_hold = function(x, hold)
    hold = which(hold, 0.7)
    return math.atan(hold * math.tan(4 * math.pi * (x - 0.5)^3)) / math.pi + 0.5
end


--- @brief maps [0, 0.5] to [0, peak], [0.5, 1] to [peak, 0], linear in both sections
rt.symmetrical_linear = function(x, peak)
    peak = which(peak, 1)
    if x < 0 or x > 1 then return 0 end
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
    -- e^{-\left(4\cdot\frac{\pi}{3}\right)\left(2x-1\right)^{2}}
    peak = which(peak, 1)
    return (math.exp(-1 * ((4 * math.pi / 3) * (2 * x - 1))^2))
end

--- @brief gaussian distribution with 0.99 percentile in [0, 1], peak at 1
rt.gaussian_increase = function(x, peak)
    peak = which(peak, 1)
    return (math.exp(-1 * ((2 * math.pi / 3) * (x - 1))^2))
end

--- @brief calculate skewed gaussian distribution probability
--- @param x Number
--- @param mean Number
--- @param variance Number sqrt(sigma^2), unsigned number
--- @param skewedness Number signed number
--- @return Number p(x) under this distribution
--- @see `https://www.desmos.com/calculator/olusu3ps3b`
function rt.skewed_gaussian(x, mean, variance, skewedness)
    x = (x - mean) / variance
    return 2 * ((1 / (variance * math.sqrt(2 * math.pi))) * math.exp(-0.5 * x * x)) * (0.5 * (1 + math.erf(skewedness * x) / math.sqrt(2)))
end

--- @brief heartbeat-like impulse, from [0, 1] to [-1, 1]
rt.heartbeat = function(x)
    -- https://www.desmos.com/calculator/m0xym3uknp
    function rt.heartbeat_aux_sine(x)
        return 0.5 * math.sin(12 * math.pi * (x / 2)) * math.sin(2 * math.pi * (x / 2))
    end

    function rt.heartbeat_aux_gaussian(x)
        return math.exp(-((4 * math.pi / 3) * (2 * x - 1)^2))
    end

    return rt.heartbeat_aux_sine(x + 1.9) * 2.3 * rt.heartbeat_aux_gaussian(x)
end

--- @brief squish function in [0, 1], still stays in [0, 1]
rt.squish = function(factor, f, x, ...)
    -- https://www.desmos.com/calculator/jiprt2qimb
    return f(x * factor - factor / 2 + 0.5, ...)
end

--- @brief sine wave with amptliude 1 and given frequency
rt.sine_wave = function(x, frequency)
    return (math.sin(2 * math.pi * x * frequency - math.pi / 2) + 1) * 0.5
end

--- @brief triangle wave with amplitude 1 and given frequency
rt.triangle_wave = function(x)
    return 4 * math.abs((x / math.pi) + 0.25 - math.floor((x / math.pi) + 0.75)) - 1
end

--- @brief
rt.butterworth_bandpass = function(x, order)
    order = which(order, 4)
    return 1 / (1 + (4 * (x - 0.5)) ^ (2 * order))
end

--- @brief
rt.butterworth_highpass = function(x, order)
    order = which(order, 4)
    if x > 1 then return 1 end
    return 1 / (1 + (2 * (x - 1)) ^ (2 * order))
end

--- @brief
rt.butterworth_lowpass = function(x, order)
    return 1 - rt.butterworth_highpass(1 - x, order)
end